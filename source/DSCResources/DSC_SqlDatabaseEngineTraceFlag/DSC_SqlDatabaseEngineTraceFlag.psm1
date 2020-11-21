$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets the actual sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

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
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.GetConfiguration -f $Name
    )

    $SQLManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $ServerName

    $ServiceNames = Get-SqlServiceName -InstanceName $InstanceName

    $SQLManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $ServerName

    if($SQLManagement)
    {
        $WMIService = $SQLManagement.Services |
            Where-Object -FilterScript { $PSItem.Name -eq $ServiceNames.SQLEngineName  }

        if($WMIService)
        {
            $ActualTraceFlags = $WMIService.StartupParameters.Split(';') |
                Where-Object -FilterScript { $PSItem -like '-T*' } |
                ForEach-Object {
                    $PSItem.TrimStart('-T')
            }
            Write-Verbose -Message ("Actual TraceFlags $ActualTraceFlags")
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
        ServerName         = $ServerName
        InstanceName       = $InstanceName
        ActualTraceFlags   = $ActualTraceFlags
    }
}

<#
    .SYNOPSIS
        This function sets the sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER TraceFlags
        The TraceFlags the SQL server engine startup parameters should contain.
        This parameter can not be used together with TraceFlagsToInclude and TraceFlagsToExclude.

    .PARAMETER TraceFlagsToInclude
        The TraceFlags the SQL server engine startup parameters should include.
        This parameter can not be used together with TraceFlags.

    .PARAMETER TraceFlagsToExclude
        The TraceFlags the SQL server engine startup parameters should exclude.
        This parameter can not be used together with TraceFlags.

    .PARAMETER Ensure
        When set to 'Present', the TraceFlags will be created/added.
        When set to 'Absent', all the TraceFlags will be removed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

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
        $RestartInstance = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.SetConfiguration -f $Name, $RetryCount, ($RetryIntervalSec * $RetryCount)
    )

    $assertBoundParameterParameters = @{
        BoundParameterList = $PSBoundParameters
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

    if ($Ensure -eq 'Present')
    {
        if ($TraceFlags)
        {
            $WishTraceFlags = $TraceFlags.Clone()
        }
        else
        {
            $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
            $WishTraceFlags = $getTargetResourceResult.ActualTraceFlags.Clone()

            if ($TraceFlagsToInclude)
            {
                foreach ($traceFlagToInclude in $TraceFlagsToInclude)
                {
                    if ($getTargetResourceResult.ActualTraceFlags -notcontains $traceFlagToInclude)
                    {
                        $WishTraceFlags.Add($traceFlagToInclude)
                    }
                }
            }

            if ($TraceFlagsToExclude)
            {
                foreach ($traceFlagToExclude in $TraceFlagsToExclude)
                {
                    if ($getTargetResourceResult.ActualTraceFlag -contains $traceFlagToExclude)
                    {
                        $WishTraceFlags.Remove($traceFlagToExclude)
                    }
                }
            }
        }

        # Add '-T' dash to flag
        $traceFlagList = $wishTraceFlags | ForEach-Object {
            "-T$PSItem"
        }
    }
    else
    {
        #when ensure <> present, TraceFlagList should be empty,
        #this wil remove all traceFlags from the startupParameters
        $traceFlagList = $null
    }

    $ServiceNames = Get-SqlServiceName -InstanceName $InstanceName

    $SQLManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $ServerName

    if($SQLManagement)
    {
        $WMIService = $SQLManagement.Services |
            Where-Object -FilterScript { $PSItem.Name -eq $ServiceNames.SQLEngineName }

        if($WMIService)
        {
            # Extract startup parameters
            [System.Collections.ArrayList]$parameterList = $wmiService.StartupParameters.Split(';')

            # Removing flags that are not wanted
            foreach ($parameter in $wmiService.StartupParameters.Split(';')) {
                if ($parameter -like '-T*' -and $parameter -notin $traceFlagList) {
                    $parameterList.Remove($parameter) | Out-Null
                }
            }

            # Add missing flags
            foreach ($Flag in $traceFlagList) {
                if ($Flag -notin $parameterList) {
                    $parameterList.Add($Flag) | Out-Null
                }
            }

            # Merge flags back into startup parameters
            $wmiService.StartupParameters = $parameterList -join ';'
            $wmiService.Alter()

            if ($RestartSQLService)
            {
                $AgentServiceStatus = ($sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq $ServiceNames.SQLAgentName }).ServiceState

                $wmiService.Stop()
                Start-Sleep -Seconds 10
                $wmiService.Start()

                if($AgentServiceStatus -ne 'Stopped')
                {
                    ($sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq $ServiceNames.SQLAgentName }).Start()
                }
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
}

<#
    .SYNOPSIS
        This function tests the sql server TraceFlags.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER TraceFlags
        The TraceFlags the SQL server engine startup parameters should contain.
        This parameter can not be used together with TraceFlagsToInclude and TraceFlagsToExclude.

    .PARAMETER TraceFlagsToInclude
        The TraceFlags the SQL server engine startup parameters should include.
        This parameter can not be used together with TraceFlags.

    .PARAMETER TraceFlagsToExclude
        The TraceFlags the SQL server engine startup parameters should exclude.
        This parameter can not be used together with TraceFlags.

    .PARAMETER Ensure
        When set to 'Present', the TraceFlags will be created/added.
        When set to 'Absent', all TraceFlags will be removed.
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
        $ServerName = $env:COMPUTERNAME,

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
        $RestartInstance = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.TestConfiguration -f $Name
    )

    $assertBoundParameterParameters = @{
        BoundParameterList = $PSBoundParameters
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
    if ($Ensure -eq 'Present')
    {
        if ($TraceFlags)
        {
            if ( $null -ne (Compare-Object -ReferenceObject $getTargetResourceResult.ActualTraceFlags -DifferenceObject $TraceFlags))
            {
                Write-Verbose -Message (
                    $script:localizedData.DesiredTraceFlagNotPresent `
                        -f $ServerRoleName
                )

                $isInDesiredState = $false
            }
        }
        else
        {
            if ($TraceFlagsToInclude)
            {
                foreach ($traceFlagToInclude in $TraceFlagsToInclude)
                {
                    if ($getTargetResourceResult.ActualTraceFlags -notcontains $traceFlagToInclude)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.TraceFlagNotPresent `
                                -f $traceFlagToInclude
                        )

                        $isInDesiredState = $false
                    }
                }
            }

            if ($TraceFlagsToExclude)
            {
                foreach ($traceFlagToExclude in $TraceFlagsToExclude)
                {
                    if ($getTargetResourceResult.ActualTraceFlags -contains $traceFlagToExclude)
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
    }
    else
    {
        if($getTargetResourceResult.ActualTraceFlags.Count -eq 0)
        {
            Write-Verbose -Message ("No traceflags found.")
        }
        else
        {
            Write-Verbose -Message ("End of TestResource: $($getTargetResourceResult.ActualTraceFlags.Count) traceflags found.")
            $isInDesiredState = $false
        }
    }
    return $isInDesiredState
}

Export-ModuleMember -Function *-TargetResource


<#
    .SYNOPSIS
        This function returns the serviceNames of an sql instance.
#>
Function Get-SqlServiceName
{
    Param
    (
        [Parameter(Position = 1)]
        [System.String]
        $InstanceName = 'MSSQLServer'
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $SQLEngineName = 'MSSQLSERVER'
        $SQLAgentName = 'SQLSERVERAGENT'
    }
    else
    {
        $SQLEngineName = 'MSSQL${0}' -f $InstanceName
        $SQLAgentName = 'SQLAgent${0}' -f $InstanceName
    }

    return @{
        SQLEngineName     = $SQLEngineName
        SQLAgentName      = $SQLAgentName
    }
}