Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

function Get-TargetResource
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

    if( -not $sql )
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    return @{ IsHadrEnabled = $sql.IsHadrEnabled }
}


function Set-TargetResource
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
            try
            {
                # Disable Always On without restarting the services.
                New-VerboseMessage -Message "Disabling Always On for the instance $serverInstance"
                Disable-SqlAlwaysOn -ServerInstance $serverInstance -NoServiceRestart -ErrorAction Stop
            }
            catch 
            {
                throw New-TerminatingError -ErrorType "AlterAlwaysOnServiceFailed" -FormatArgs 'disable',$serverInstance -ErrorCategory OperationStopped
            }
            
        }
        'Present'
        {
            try 
            {
                # Enable Always On without restarting the services.
                New-VerboseMessage -Message "Enabling Always On for the instance $serverInstance"
                Enable-SqlAlwaysOn -ServerInstance $serverInstance -NoServiceRestart -ErrorAction Stop
            }
            catch 
            {
                throw New-TerminatingError -ErrorType "AlterAlwaysOnServiceFailed" -FormatArgs 'enable',$serverInstance -ErrorCategory OperationStopped
            }
        }
    }

    # Now restart the SQL service so that all dependent services are also returned to their previous state
    Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -Timeout $RestartTimeout
}


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
    $state = Get-TargetResource @PSBoundParameters
    
    # Determine what the desired state of Always On is
    $hadrDesiredState = @{ 'Present' = $true; 'Absent' = $false }[$Ensure]

    # return whether the value matches the desired state
    return ( $state.IsHadrEnabled -eq $hadrDesiredState )
}

Export-ModuleMember -Function *-TargetResource