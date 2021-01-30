$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets the actual sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    # Import SqlServer module.
    Import-SQLPSModule

    Write-Verbose -Message (
        $script:localizedData.GetConfiguration -f $InstanceName
    )

    $sqlManagement = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' -ArgumentList $ServerName

    $serviceNames = Get-SqlServiceName -InstanceName $InstanceName

    if ($sqlManagement)
    {
        $databaseEngineService = $sqlManagement.Services |
            Where-Object -FilterScript { $PSItem.Name -eq $serviceNames.SQLEngineName }

        if ($databaseEngineService)
        {
            $traceFlags = $databaseEngineService.StartupParameters.Split(';') |
                Where-Object -FilterScript { $PSItem -like '-T*' } |
                ForEach-Object {
                    $PSItem.TrimStart('-T')
                }
        }
        else
        {
            $errorMessage = $script:localizedData.NotConnectedToWMI -f $InstanceName, $ServerName
            New-InvalidOperationException -Message $errorMessage
        }
    }
    else
    {
        $errorMessage = $script:localizedData.NotConnectedToComputerManagement -f $ServerName
        New-InvalidOperationException -Message $errorMessage
    }

    return @{
        ServerName          = $ServerName
        InstanceName        = $InstanceName
        TraceFlags          = $traceFlags
        TraceFlagsToInclude = $null
        TraceFlagsToExclude = $null
        RestartService      = $null
        RestartTimeout      = $null
    }
}

<#
    .SYNOPSIS
        This function sets the sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER TraceFlags
        The TraceFlags the SQL server engine startup parameters should contain.
        This parameter can not be used together with TraceFlagsToInclude and TraceFlagsToExclude.
        This parameter will replace all the current trace flags with the specified trace flags.

    .PARAMETER TraceFlagsToInclude
        The TraceFlags the SQL server engine startup parameters should include.
        This parameter can not be used together with TraceFlags.

    .PARAMETER TraceFlagsToExclude
        The TraceFlags the SQL server engine startup parameters should exclude.
        This parameter can not be used together with TraceFlags.

    .PARAMETER RestartService
        If set, the sql server instance gets a reset after setting parameters.
        after restart the sql server agent is in the original state as before restart.

    .PARAMETER RestartTimeout
        The time the resource waits while the sql server services are restarted.
        Defaults to 120 seconds.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.UInt32[]]
        $TraceFlags,

        [Parameter()]
        [System.UInt32[]]
        $TraceFlagsToInclude,

        [Parameter()]
        [System.UInt32[]]
        $TraceFlagsToExclude,

        [Parameter()]
        [System.Boolean]
        $RestartService = $false,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout = 120
    )

    # Import SqlServer module.
    Import-SQLPSModule

    Write-Verbose -Message (
        $script:localizedData.SetConfiguration -f $InstanceName
    )

    $assertBoundParameterParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'TraceFlags'
        )
        MutuallyExclusiveList2 = @(
            'TraceFlagsToInclude', 'TraceFlagsToExclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $wishTraceFlags = [System.Collections.ArrayList]::new()

    if ($PSBoundParameters.ContainsKey('TraceFlags'))
    {
        $wishTraceFlags.AddRange($TraceFlags)
    }
    else
    {
        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

        $wishTraceFlags.AddRange($getTargetResourceResult.TraceFlags)

        if ($PSBoundParameters.ContainsKey('TraceFlagsToInclude'))
        {
            foreach ($traceFlagToInclude in $TraceFlagsToInclude)
            {
                if ($getTargetResourceResult.TraceFlags -notcontains $traceFlagToInclude)
                {
                    $wishTraceFlags.Add($traceFlagToInclude)
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('TraceFlagsToExclude'))
        {
            foreach ($traceFlagToExclude in $TraceFlagsToExclude)
            {
                if ($getTargetResourceResult.TraceFlags -contains $traceFlagToExclude)
                {
                    $wishTraceFlags.Remove([string]$traceFlagToExclude)
                }
            }
        }
    }

    # Add '-T' dash to flag.
    $traceFlagList = $wishTraceFlags |
        ForEach-Object {
            "-T$PSItem"
        }

    if ($traceFlagList -eq '')
    {
        $traceFlagList = $null
    }

    $serviceNames = Get-SqlServiceName -InstanceName $InstanceName

    $sqlManagement = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' -ArgumentList $ServerName

    if ($sqlManagement)
    {
        $databaseEngineService = $sqlManagement.Services |
            Where-Object -FilterScript { $PSItem.Name -eq $serviceNames.SQLEngineName }

        if ($databaseEngineService)
        {
            # Extract startup parameters.
            [System.Collections.ArrayList] $parameterList = $databaseEngineService.StartupParameters.Split(';')

            # Removing flags that are not wanted
            foreach ($parameter in $databaseEngineService.StartupParameters.Split(';'))
            {
                if ($parameter -like '-T*' -and $parameter -notin $traceFlagList)
                {
                    $parameterList.Remove($parameter) | Out-Null
                }
            }

            # Add missing flags.
            foreach ($flag in $traceFlagList)
            {
                if ($flag -notin $parameterList)
                {
                    $parameterList.Add($flag) | Out-Null
                }
            }

            # Merge flags back into startup parameters.
            $databaseEngineService.StartupParameters = $parameterList -join ';'
            $databaseEngineService.Alter()

            if ($PSBoundParameters.ContainsKey('RestartService'))
            {
                if ($RestartService -eq $true)
                {
                    Restart-SqlService -ServerName $ServerName -InstanceName $InstanceName -Timeout $RestartTimeout
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        This function tests the sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER TraceFlags
        The TraceFlags the SQL server engine startup parameters should contain.
        This parameter can not be used together with TraceFlagsToInclude and TraceFlagsToExclude.
        This parameter will replace all the current trace flags with the specified trace flags.

    .PARAMETER TraceFlagsToInclude
        The TraceFlags the SQL server engine startup parameters should include.
        This parameter can not be used together with TraceFlags.

    .PARAMETER TraceFlagsToExclude
        The TraceFlags the SQL server engine startup parameters should exclude.
        This parameter can not be used together with TraceFlags.

    .PARAMETER RestartService
        If set, the sql server instance gets a reset after setting parameters.
        after restart the sql server agent is in the original state as before restart.

    .PARAMETER RestartTimeout
        The time the resource waits while the sql server services are restarted.
        Defaults to 120 seconds.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Uint32[]]
        $TraceFlags,

        [Parameter()]
        [System.Uint32[]]
        $TraceFlagsToInclude,

        [Parameter()]
        [System.Uint32[]]
        $TraceFlagsToExclude,

        [Parameter()]
        [System.Boolean]
        $RestartService = $false,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout = 120
    )

    Write-Verbose -Message (
        $script:localizedData.TestConfiguration -f $InstanceName
    )

    $assertBoundParameterParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'TraceFlags'
        )
        MutuallyExclusiveList2 = @(
            'TraceFlagsToInclude', 'TraceFlagsToExclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $isInDesiredState = $true

    if ($PSBoundParameters.ContainsKey('TraceFlags'))
    {
        if ($TraceFlags.Length -eq 0)
        {
            if ($getTargetResourceResult.TraceFlags.Count -gt 0)
            {
                $isInDesiredState = $false
            }
        }
        else
        {
            # Compare $TraceFlags to the Actual TraceFlags ($getTargetResourceResult.TraceFlags) to see if they contain the same values.
            $nullIfTheSame = Compare-Object -ReferenceObject $getTargetResourceResult.TraceFlags -DifferenceObject $TraceFlags
            if ($null -ne $nullIfTheSame)
            {
                Write-Verbose -Message (
                    $script:localizedData.DesiredTraceFlagNotPresent `
                        -f $($TraceFlags -join ','), $($getTargetResourceResult.TraceFlags -join ',')
                )

                $isInDesiredState = $false
            }
        }
    }
    else
    {
        if ($PSBoundParameters.ContainsKey('TraceFlagsToInclude'))
        {
            foreach ($traceFlagToInclude in $TraceFlagsToInclude)
            {
                if ($getTargetResourceResult.TraceFlags -notcontains $traceFlagToInclude)
                {
                    Write-Verbose -Message (
                        $script:localizedData.TraceFlagNotPresent `
                            -f $traceFlagToInclude
                    )

                    $isInDesiredState = $false
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('TraceFlagsToExclude'))
        {
            foreach ($traceFlagToExclude in $TraceFlagsToExclude)
            {
                if ($getTargetResourceResult.TraceFlags -contains $traceFlagToExclude)
                {
                    Write-Verbose -Message (
                        $script:localizedData.TraceFlagPresent `
                            -f $traceFlagToExclude
                    )

                    $isInDesiredState = $false
                }
            }
        }
    }

    return $isInDesiredState
}

<#
    .SYNOPSIS
        This function returns the serviceNames of an sql instance.

    .PARAMETER InstanceName
        The name of the SQL instance of whoose service names are beeing returned.
#>
function Get-SqlServiceName
{
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLServer'
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $sqlEngineName = 'MSSQLSERVER'
        $sqlAgentName = 'SQLSERVERAGENT'
    }
    else
    {
        $sqlEngineName = 'MSSQL${0}' -f $InstanceName
        $sqlAgentName = 'SQLAgent${0}' -f $InstanceName
    }

    return @{
        SQLEngineName = $sqlEngineName
        SQLAgentName  = $sqlAgentName
    }
}
