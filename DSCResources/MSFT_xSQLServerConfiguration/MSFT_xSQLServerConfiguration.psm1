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

        [parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [parameter(Mandatory = $true)]
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
        throw "Specified option '$OptionName' was not found!"
    }

    $returnValue = @{
        SqlServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
        OptionName = $option.DisplayName
        OptionValue = $option.ConfigValue
        RestartService = $RestartService
    }

    return $returnValue
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

        [parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [parameter(Mandatory = $true)]
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
        throw "Specified option '$OptionName' was not found!"
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
        Write-Warning 'Configuration option has been updated. SQL Server restart is required!'
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

        [parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        [System.Boolean]
        $RestartService = $false
    )

    $state = Get-TargetResource -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -OptionName $OptionName -OptionValue $OptionValue -RestartService $RestartService

    return ($state.OptionValue -eq $OptionValue)
}

#region helper functions
<#
    .SYNOPSIS
    Restarts a SQL Server instance and associated services

    .PARAMETER ServerObject
    SMO Server object for the SQL Server instance to be restarted

    .EXAMPLE
    $server = Connect-SQL -SQLServer $env:ComputerName
    Restart-SqlService -ServerObject $server
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        # SMO Server object for instance to restart
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )

    if ($ServerObject.IsClustered)
    {
        ## Get the cluster resources
        New-VerboseMessage -Message 'Getting cluster resource for SQL Server' 
        $SqlService = Get-WmiObject -Namespace root/MSCluster -Class MSCluster_Resource -Filter "Type = 'SQL Server' AND Name LIKE '%$($ServerObject.ServiceName)%'"

        New-VerboseMessage -Message 'Getting cluster resource for SQL Server Agent'
        $AgentService = Get-WmiObject -Namespace root/MSCLuster -Class MSCluster_Resource -Filter "Type = 'SQL Server Agent' AND Name LIKE '%$($ServerObject.ServiceName)%'"

        ## Stop the SQL Server resource
        New-VerboseMessage -Message 'SQL Server resource --> Offline'
        $SqlService.TakeOffline(120)

        ## Start the SQL Agent resource
        New-VerboseMessage -Message 'SQL Server Agent --> Online'
        $AgentService.BringOnline(120)
    }
    else
    {
        New-VerboseMessage -Message 'Getting SQL Service information'
        $SqlService = Get-Service -DisplayName "SQL Server ($($ServerObject.ServiceName))"
        $AgentService = $SqlService.DependentServices | Where-Object { $_.StartType -ne ''}

        ## Restart the SQL Server service
        New-VerboseMessage -Message 'SQL Server service restarting'
        $SqlService | Restart-Service -Force

        ## Start the SQL Server Agent service
        if ($AgentService)
        {
            New-VerboseMessage -Message 'Starting SQL Server Agent'
            $AgentService | Start-Service 
        }
    }
}
#endregion

Export-ModuleMember -Function *-TargetResource
