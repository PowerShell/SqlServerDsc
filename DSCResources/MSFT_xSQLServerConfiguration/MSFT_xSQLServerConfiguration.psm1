$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

<#
    .SYNOPSIS
    Gets the current value of a SQL configuration option

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLServer'

    .PARAMETER OptionName
    The name of the SQL configuration option to be checked
    
    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    Determines whether the instance should be restarted after updating the configuration option
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        [System.Boolean]
        $RestartService = $false
    )

    if (! $sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstance
    }

    ## get the configuration option
    $option = $sql.Configuration.Properties | where { $_.DisplayName -eq $optionName }
    
    if(!$option)
    {
        New-TerminatingError -Message "Specified option '$OptionName' was not found!"
    }

     return @{
        SqlServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
        OptionName = $option.DisplayName
        OptionValue = $option.ConfigValue
        RestartService = $RestartService
    }
}

<#
    .SYNOPSIS
    Sets the value of a SQL configuration option

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLServer'

    .PARAMETER OptionName
    The name of the SQL configuration option to be set
    
    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    Determines whether the instance should be restarted after updating the configuration option
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        [System.Boolean]
        $RestartService = $false
    )

    if (! $sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstance
    }

    ## get the configuration option
    $option = $sql.Configuration.Properties | where {$_.DisplayName -eq $optionName}

    if(!$option)
    {
        New-TerminatingError -Message "Specified option '$OptionName' was not found!"
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
        Restart-SqlService -ServerObject $sql
    }
    else
    {
        Write-Warning 'Configuration option has been updated, but a manual restart of SQL Server is required for it to take effect.'
    }
}

<#
    .SYNOPSIS
    Determines whether a SQL configuration option value is properly set

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLServer'

    .PARAMETER OptionName
    The name of the SQL configuration option to be tested
    
    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    Determines whether the instance should be restarted after updating the configuration option
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        [System.Boolean]
        $RestartService = $false
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

    .PARAMETER ServerObject
    SMO Server object for the SQL Server instance to be restarted

    .PARAMETER Timeout
    Timeout value for restarting the SQL services

    .EXAMPLE
    $server = Connect-SQL -SQLServer $env:ComputerName
    Restart-SqlService -ServerObject $server
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatry = $false)]
        [int]
        $Timeout = 120
    )

    ## get the instance name from the Server object
    $instanceName = $ServerObject.ServiceName
    if (! $instanceName)
    {
        ## sometimes default instances do not return a value
        ## specify the default instance name
        $instanceName = "MSSQLSERVER"
    }

    if ($ServerObject.IsClustered)
    {
        ## Get the cluster resources
        New-VerboseMessage -Message 'Getting cluster resource for SQL Server' 
        $sqlService = Get-WmiObject -Namespace root/MSCluster -Class MSCluster_Resource -Filter "Type = 'SQL Server' AND Name LIKE '%($instanceName)%'"

        New-VerboseMessage -Message 'Getting cluster resource for SQL Server Agent'
        $agentService = Get-WmiObject -Namespace root/MSCLuster -Class MSCluster_Resource -Filter "Type = 'SQL Server Agent' AND Name LIKE '%$($instanceName)%'"

        ## Stop the SQL Server resource
        New-VerboseMessage -Message 'SQL Server resource --> Offline'
        $sqlService.TakeOffline($Timeout)

        ## Start the SQL Agent resource
        New-VerboseMessage -Message 'SQL Server Agent --> Online'
        $agentService.BringOnline($Timeout)
    }
    else
    {
        New-VerboseMessage -Message 'Getting SQL Service information'
        $sqlService = Get-Service -DisplayName "SQL Server ($($instanceName))"
        $agentService = $sqlService.DependentServices | Where-Object { $_.StartType -ne ''}

        ## Restart the SQL Server service
        New-VerboseMessage -Message 'SQL Server service restarting'
        $sqlService | Restart-Service -Force

        ## Start the SQL Server Agent service
        if ($agentService)
        {
            New-VerboseMessage -Message 'Starting SQL Server Agent'
            $agentService | Start-Service 
        }
    }
#>
}
#endregion

Export-ModuleMember -Function *-TargetResource
