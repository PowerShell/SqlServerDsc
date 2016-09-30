$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
New-VerboseMessage -Message -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        # Hostname of the SQL Server to be configured
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        # Name of the SQL instance to be configured
        [parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        # Name of the SQL Configuation option to be checked
        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        # Value of the SQL Configuration option
        [parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        # Determines whether the instance should be restarted
        [System.Boolean]
        $RestartService = $false
    )

    if (! $sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstance $SQLInstance
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

Function Set-TargetResource
{
    [CmdletBinding()]
    param(
        # Hostname of the SQL Server to be configured
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        # Name of the SQL instance to be configured
        [parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        # Name of the SQL Configuation option to be checked
        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        # Value of the SQL Configuration option
        [parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        # Determines whether the instance should be restarted
        [System.Boolean]
        $RestartService = $false
    )

    if (! $sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstance $SQLInstance
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
        New-VerboseMessage -Message "Configuration option has been updated."
    }
    elseif (($option.IsDynamic -eq $false) -and ($RestartService -eq $true))
    {
        New-VerboseMessage -Message "Configuration option has been updated, restarting instance..."
        Restart-SqlService -ServerObject $sql
    }
    else
    {
        Write-Warning "Configuration option has been updated. SQL Server restart is required!"
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        # Hostname of the SQL Server to be configured
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        # Name of the SQL instance to be configured
        [parameter(Mandatory = $false)]
        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        # Name of the SQL Configuation option to be checked
        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        # Value of the SQL Configuration option
        [parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        # Determines whether the instance should be restarted
        [System.Boolean]
        $RestartService = $false
    )

    $state = Get-TargetResource -InstanceName $InstanceName -OptionName $OptionName -OptionValue $OptionValue

    return ($state.OptionValue -eq $OptionValue)
}

#region helper functions
Function Restart-SqlService
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
        New-VerboseMessage -Message "Getting cluster resource for SQL Server" 
        $SqlService = Get-WmiObject -Namespace root/MSCluster -Class MSCluster_Resource -Filter "Type = 'SQL Server' AND Name LIKE '%$($ServerObject.ServiceName)%'"

        New-VerboseMessage -Message "Getting cluster resource for SQL Server Agent"
        $AgentService = Get-WmiObject -Namespace root/MSCLuster -Class MSCluster_Resource -Filter "Type = 'SQL Server Agent' AND Name LIKE '%$($ServerObject.ServiceName)%'"

        ## Stop the SQL Server resource
        New-VerboseMessage -Message "SQL Server resource --> Offline"
        $SqlService.TakeOffline(120)

        ## Start the SQL Agent resource
        New-VerboseMessage -Message "SQL Server Agent --> Online"
        $AgentService.BringOnline(120)
    }
    else
    {
        New-VerboseMessage -Message "Getting SQL Service information"
        $SqlService = Get-Service -DisplayName "SQL Server ($($ServerObject.ServiceName))"
        $AgentService = $SqlService.DependentServices | Where-Object { $_.StartType -ne ""}

        ## Restart the SQL Server service
        New-VerboseMessage -Message "SQL Server service restarting"
        $SqlService | Restart-Service -Force

        ## Start the SQL Server Agent service
        if ($AgentService)
        {
            New-VerboseMessage -Message "Starting SQL Server Agent"
            $AgentService | Start-Service 
        }
    }
}
#endregion

Export-ModuleMember -Function *-TargetResource
