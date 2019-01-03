Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force

<#
    .SYNOPSIS
    Gets the current value of the SQL Server Always On high availability and
    disaster recovery (HADR) property.

    .PARAMETER Ensure
    An enumerated value that describes if the SQL Server should have Always On high
    availability and disaster recovery (HADR) property enabled ('Present') or
    disabled ('Absent').

    *** Not used in this function ***

    .PARAMETER ServerName
    The hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    $isAlwaysOnEnabled = [System.Boolean] $sqlServerObject.IsHadrEnabled
    if ($isAlwaysOnEnabled -eq $true)
    {
        $statusString = 'enabled'
    }
    elseif ($isAlwaysOnEnabled -eq $false)
    {
        $statusString = 'disabled'
    }

    New-VerboseMessage -Message ( 'SQL Always On is {0} on "{1}\{2}".' -f $statusString, $ServerName, $InstanceName )

    return @{
        IsHadrEnabled = $isAlwaysOnEnabled
    }
}

<#
    .SYNOPSIS
    Sets the current value of the SQL Server Always On high availability and disaster recovery (HADR) property.

    .PARAMETER Ensure
    An enumerated value that describes if the SQL Server should have Always On high
    availability and disaster recovery (HADR) property enabled ('Present') or
    disabled ('Absent').

    .PARAMETER ServerName
    The hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER RestartTimeout
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout = 120
    )

    # Build the instance name to allow the Enable/Disable-Always On to connect to the instance
    if ($InstanceName -eq "MSSQLSERVER")
    {
        $serverInstance = $ServerName
    }
    else
    {
        $serverInstance = "$ServerName\$InstanceName"
    }

    Import-SQLPSModule

    switch ($Ensure)
    {
        'Absent'
        {
            # Disable Always On without restarting the services.
            New-VerboseMessage -Message "Disabling Always On for the instance $serverInstance"
            Disable-SqlAlwaysOn -ServerInstance $serverInstance -NoServiceRestart
        }
        'Present'
        {
            # Enable Always On without restarting the services.
            New-VerboseMessage -Message "Enabling Always On for the instance $serverInstance"
            Enable-SqlAlwaysOn -ServerInstance $serverInstance -NoServiceRestart
        }
    }

    New-VerboseMessage -Message ( 'SQL Always On has been {0} on "{1}\{2}". Restarting the service.' -f @{Absent = 'disabled'; Present = 'enabled'}[$Ensure], $ServerName, $InstanceName )

    # Now restart the SQL service so that all dependent services are also returned to their previous state
    Restart-SqlService -SQLServer $ServerName -SQLInstanceName $InstanceName -Timeout $RestartTimeout

    # Verify always on was set
    if ( -not ( Test-TargetResource @PSBoundParameters ) )
    {
        throw New-TerminatingError -ErrorType AlterAlwaysOnServiceFailed -FormatArgs $Ensure, $serverInstance -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    Determines whether the current value of the SQL Server Always On high
    availability and disaster recovery (HADR) property is properly set.

    .PARAMETER Ensure
    An enumerated value that describes if the SQL Server should have Always On high
    availability and disaster recovery (HADR) property enabled ('Present') or
    disabled ('Absent').

    .PARAMETER ServerName
    The hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER RestartTimeout
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.

    *** Not used in this function ***
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout = 120
    )

    # Determine the current state of Always On
    $getTargetResourceParameters = @{
        Ensure       = $Ensure
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $state = Get-TargetResource @getTargetResourceParameters

    # Determine what the desired state of Always On is
    $hadrDesiredState = @{ 'Present' = $true; 'Absent' = $false }[$Ensure]

    # Determine whether the value matches the desired state
    $desiredStateMet = $state.IsHadrEnabled -eq $hadrDesiredState

    New-VerboseMessage -Message ( 'SQL Always On is in the desired state for "{0}\{1}": {2}.' -f $ServerName, $InstanceName, $desiredStateMet )

    return $desiredStateMet
}

Export-ModuleMember -Function *-TargetResource
