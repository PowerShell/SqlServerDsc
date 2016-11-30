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
    Hostname of the SQL Server to be configured. Default is the current computer.
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER RestartTimeout
    *** Not used in this function ***
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    return @{ IsHadrEnabled = $sql.IsHadrEnabled }
}

<#
    .SYNOPSIS
    Sets the current value of the SQL Server HADR property.

    .PARAMETER Ensure
    HADR is Present (enabled) or Absent (disabled)

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured. Default is the current computer.
    
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

        [Parameter()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

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
    Determines whether the current value of the SQL Server HADR property is properly set

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER RestartTimeout
    *** Not used in this function ***
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

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

    # return whether the value matches the desired state
    return ( $state.IsHadrEnabled -eq $hadrDesiredState )
}

Export-ModuleMember -Function *-TargetResource