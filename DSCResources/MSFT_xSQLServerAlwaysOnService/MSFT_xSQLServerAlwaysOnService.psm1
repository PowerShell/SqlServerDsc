Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

<#
    .SYNOPSIS
    Gets the current value of the SQL Server HADR property.

    .PARAMETER Ensure
    *** Not used in this function ***
    HADR is Present (enabled) or Absent (disabled)
    
    .PARAMETER SQLServer
<<<<<<< 57341405f526e03f5fd795576a35a9fd73810408
    Hostname of the SQL Server to be configured. Default is the current $env:COMPUTERNAME.
=======
    Hostname of the SQL Server to be configured.
>>>>>>> Changed the SQLServer parameter to required in order to align with the schema.mof
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER RestartTimeout
    *** Not used in this function ***
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    New-VerboseMessage -Message ( 'SQL Always On is {0} on "{1}\{2}".' -f @{$false='disabled'; $true='enabled'}[$sql.IsHadrEnabled],$SQLServer,$SQLInstanceName )

    return @{ IsHadrEnabled = $sql.IsHadrEnabled }
}

<#
    .SYNOPSIS
    Sets the current value of the SQL Server HADR property.

    .PARAMETER Ensure
    HADR is Present (enabled) or Absent (disabled)

    .PARAMETER SQLServer
<<<<<<< 57341405f526e03f5fd795576a35a9fd73810408
    Hostname of the SQL Server to be configured. Default is the current $env:COMPUTERNAME.
=======
    Hostname of the SQL Server to be configured.
>>>>>>> Changed the SQLServer parameter to required in order to align with the schema.mof
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER RestartTimeout
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [Int32]
        $RestartTimeout = 120
    )

    # Build the instance name to allow the Enable/Disable-AlwaysOn to connect to the instance
    if($SQLInstanceName -eq "MSSQLSERVER")
    {
        $serverInstance = $SQLServer
    }
    else
    {
        $serverInstance = "$SQLServer\$SQLInstanceName"
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

    New-VerboseMessage -Message ( 'SQL Always On has been {0} on "{1}\{2}". Restarting the service.' -f @{Absent='disabled'; Present='enabled'}[$Ensure],$SQLServer,$SQLInstanceName )

    # Now restart the SQL service so that all dependent services are also returned to their previous state
    Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -Timeout $RestartTimeout

    # Verify always on was set
    if( -not ( Test-TargetResource @PSBoundParameters ) )
    {
        throw New-TerminatingError -ErrorType AlterAlwaysOnServiceFailed -FormatArgs $Ensure,$serverInstance -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    Determines whether the current value of the SQL Server HADR property is properly set.

    .PARAMETER Ensure
    *** Not used in this function ***
    HADR is Present (enabled) or Absent (disabled)
    
    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured. Default is the current $env:COMPUTERNAME.
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER RestartTimeout
    *** Not used in this function ***
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [Int32]
        $RestartTimeout = 120
    )
    
    # Determine the current state of Alway On
    $params = @{
        Ensure = $Ensure
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $state = Get-TargetResource @params
    
    # Determine what the desired state of Always On is
    $hadrDesiredState = @{ 'Present' = $true; 'Absent' = $false }[$Ensure]

    # Determine whether the value matches the desired state
    $desiredStateMet = $state.IsHadrEnabled -eq $hadrDesiredState

    New-VerboseMessage -Message ( 'SQL Always On is in the desired state for "{0}\{1}": {2}.' -f $SQLServer,$SQLInstanceName,$desiredStateMet )

    return $desiredStateMet
}

Export-ModuleMember -Function *-TargetResource
