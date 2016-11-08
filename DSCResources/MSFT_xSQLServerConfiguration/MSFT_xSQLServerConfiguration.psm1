# Load Common Code
Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force
<#
    .SYNOPSIS
    Gets the current value of a SQL configuration option

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER OptionName
    The name of the SQL configuration option to be checked
    
    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    *** Not used in this function ***
    Determines whether the instance should be restarted after updating the configuration option.

    .PARAMETER RestartTimeout
    *** Not used in this function ***
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [Int32]
        $OptionValue,

        [Boolean]
        $RestartService = $false,

        [Int32]
        $RestartTimeout = 120
    )

    if (!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    ## get the configuration option
    $option = $sql.Configuration.Properties | Where-Object { $_.DisplayName -eq $OptionName }
    
    if(!$option)
    {
        throw New-TerminatingError -ErrorType "ConfigurationOptionNotFound" -FormatArgs $OptionName -ErrorCategory InvalidArgument
    }

     return @{
        SqlServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
        OptionName = $option.DisplayName
        OptionValue = $option.ConfigValue
        RestartService = $RestartService
        RestartTimeout = $RestartTimeout
    }
}

<#
    .SYNOPSIS
    Sets the value of a SQL configuration option

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER OptionName
    The name of the SQL configuration option to be set
    
    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    Determines whether the instance should be restarted after updating the configuration option

    .PARAMETER RestartTimeout
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [Int32]
        $OptionValue,

        [Boolean]
        $RestartService = $false,

        [Int32]
        $RestartTimeout = 120
    )

    if (!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    ## get the configuration option
    $option = $sql.Configuration.Properties | Where-Object { $_.DisplayName -eq $OptionName }

    if(!$option)
    {
        throw New-TerminatingError -ErrorType "ConfigurationOptionNotFound" -FormatArgs $OptionName -ErrorCategory InvalidArgument
    }

    $option.ConfigValue = $OptionValue
    $sql.Configuration.Alter()
    
    if ($option.IsDynamic -eq $true)
    {  
        New-VerboseMessage -Message 'Configuration option has been updated.'
    }
    elseif (($option.IsDynamic -eq $false) -and ($RestartService -eq $true))
    {
        New-VerboseMessage -Message 'Configuration option has been updated, restarting instance...'
        Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -Timeout $RestartTimeout
    }
    else
    {
        New-WarningMessage -WarningType 'ConfigurationRestartRequired' -FormatArgs $OptionName
    }
}

<#
    .SYNOPSIS
    Determines whether a SQL configuration option value is properly set

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER OptionName
    The name of the SQL configuration option to be tested
    
    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    *** Not used in this function ***
    Determines whether the instance should be restarted after updating the configuration option

    .PARAMETER RestartTimeout
    *** Not used in this function ***
    The length of time, in seconds, to wait for the service to restart.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [Int32]
        $OptionValue,

        [Boolean]
        $RestartService = $false,

        [Int32]
        $RestartTimeout = 120
    )

    ## Get the current state of the configuration item
    $state = Get-TargetResource @PSBoundParameters

    ## return whether the value matches the desired state
    return ($state.OptionValue -eq $OptionValue)
}

#region helper functions
<#
    .SYNOPSIS
    Restarts a SQL Server instance and associated services

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER Timeout
    Timeout value for restarting the SQL services

    .EXAMPLE
    Restart-SqlService -SQLServer localhost

    .EXAMPLE
    Restart-SqlService -SQLServer localhost -SQLInstanceName 'NamedInstance'

    .EXAMPLE
    Restart-SqlService -SQLServer CLU01 -Timeout 300
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Int32]
        $Timeout = 120
    )

    ## Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($serverObject.IsClustered)
    {
        ## Get the cluster resources
        New-VerboseMessage -Message 'Getting cluster resource for SQL Server' 
        $sqlService = Get-WmiObject -Namespace root/MSCluster -Class MSCluster_Resource -Filter "Type = 'SQL Server'" | 
                        Where-Object { $_.PrivateProperties.InstanceName -eq $serverObject.ServiceName }

        New-VerboseMessage -Message 'Getting active cluster resource SQL Server Agent'
        $agentService = Get-WmiObject -Namespace root/MSCluster -Query "ASSOCIATORS OF {$sqlService} WHERE ResultClass = MSCluster_Resource" | 
                            Where-Object { ($_.Type -eq "SQL Server Agent") -and ($_.State -eq 2) }

        ## Build a listing of resources being acted upon
        $resourceNames = @($sqlService.Name, ($agentService | Select -ExpandProperty Name)) -join ","

        ## Stop the SQL Server and dependent resources
        New-VerboseMessage -Message 'Bringing the SQL Server resources $resourceNames offline.'
        $sqlService.TakeOffline($Timeout)

        ## Start the SQL server resource
        New-VerboseMessage -Message 'Bringing the SQL Server resource back online.'
        $sqlService.BringOnline($Timeout)

        ## Start the SQL Agent resource
        if ($agentService)
        {
            New-VerboseMessage -Message 'Bringing the SQL Server Agent resource online.'
            $agentService.BringOnline($Timeout)
        }
    }
    else
    {
        New-VerboseMessage -Message 'Getting SQL Service information'
        $sqlService = Get-Service -DisplayName "SQL Server ($($serverObject.ServiceName))"

        ## Get all dependent services that are running.
        ## There are scenarios where an automatic service is stopped and should not be restarted automatically.
        $agentService = $sqlService.DependentServices | Where-Object { $_.Status -eq "Running" }

        ## Restart the SQL Server service
        New-VerboseMessage -Message 'SQL Server service restarting'
        $sqlService | Restart-Service -Force

        ## Start dependent services
        $agentService | ForEach-Object {
            New-VerboseMessage -Message "Starting $($_.DisplayName)"
            $_ | Start-Service
        }
    }
#>
}
#endregion

Export-ModuleMember -Function *-TargetResource
