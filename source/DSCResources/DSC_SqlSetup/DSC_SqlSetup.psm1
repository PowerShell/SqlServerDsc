$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the SQL Server features.

    .PARAMETER Action
        The action to be performed. Default value is 'Install'.
        Possible values are 'Install', 'Upgrade', 'InstallFailoverCluster', 'AddNode', 'PrepareFailoverCluster', and 'CompleteFailoverCluster'.

    .PARAMETER SourcePath
        The path to the root of the source files for installation. I.e and UNC path to a shared resource.  Environment variables can be used in the path.

    .PARAMETER SourceCredential
        Credentials used to access the path set in the parameter `SourcePath`. Using this parameter will trigger a copy
        of the installation media to a temp folder on the target node. Setup will then be started from the temp folder on the target node.
        For any subsequent calls to the resource, the parameter `SourceCredential` is used to evaluate what major version the file 'setup.exe'
        has in the path set, again, by the parameter `SourcePath`.
        If the path, that is assigned to parameter `SourcePath`, contains a leaf folder, for example '\\server\share\folder', then that leaf
        folder will be used as the name of the temporary folder. If the path, that is assigned to parameter `SourcePath`, does not have a
        leaf folder, for example '\\server\share', then a unique guid will be used as the name of the temporary folder.

    .PARAMETER InstanceName
        Name of the SQL instance to be installed.

    .PARAMETER RSInstallMode
        Install mode for Reporting Services. The value of this parameter cannot be determined post-install,
        so the function will simply return the value of this parameter.

    .PARAMETER FailoverClusterNetworkName
        Host name to be assigned to the clustered SQL Server instance.

    .PARAMETER FeatureFlag
        Feature flags are used to toggle functionality on or off. See the
        documentation for what additional functionality exist through a feature
        flag.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateSet('Install','Upgrade','InstallFailoverCluster','AddNode','PrepareFailoverCluster','CompleteFailoverCluster')]
        [System.String]
        $Action = 'Install',

        [Parameter()]
        [System.String]
        $SourcePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.String]
        $RSInstallMode,

        [Parameter()]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter()]
        [System.String[]]
        $FeatureFlag
    )

    if ($FeatureFlag)
    {
        Write-Verbose -Message ($script:localizedData.FeatureFlag -f ($FeatureFlag -join ''','''))
    }

    $InstanceName = $InstanceName.ToUpper()

    $getTargetResourceReturnValue = @{
        Action = $Action
        SourcePath = $SourcePath
        SourceCredential = $SourceCredential
        InstanceName = $InstanceName
        RSInstallMode = $RSInstallMode
        FeatureFlag = $FeatureFlag
        FailoverClusterNetworkName = $null
        Features = $null
        InstanceID = $null
        InstallSharedDir = $null
        InstallSharedWOWDir = $null
        InstanceDir = $null
        SQLSvcAccountUsername = $null
        SqlSvcStartupType = $null
        AgtSvcAccountUsername = $null
        AgtSvcStartupType = $null
        SQLCollation = $null
        SQLSysAdminAccounts = $null
        SecurityMode = $null
        InstallSQLDataDir = $null
        SQLUserDBDir = $null
        SQLUserDBLogDir = $null
        SQLTempDBDir = $null
        SQLTempDBLogDir = $null
        SqlTempdbFileCount = $null
        SqlTempdbFileSize = $null
        SqlTempdbFileGrowth = $null
        SqlTempdbLogFileSize = $null
        SqlTempdbLogFileGrowth = $null
        SQLBackupDir = $null
        FTSvcAccountUsername = $null
        RSSvcAccountUsername = $null
        RsSvcStartupType = $null
        ASSvcAccountUsername = $null
        AsSvcStartupType = $null
        ASCollation = $null
        ASSysAdminAccounts = $null
        ASDataDir = $null
        ASLogDir = $null
        ASBackupDir = $null
        ASTempDir = $null
        ASConfigDir = $null
        ASServerMode = $null
        ISSvcAccountUsername = $null
        IsSvcStartupType = $null
        FailoverClusterGroupName = $null
        FailoverClusterIPAddress = $null
    }

    <#
        $sqlHostName is later used by helper function to connect to the instance
        for the Database Engine or the Analysis Services.
    #>
    if ($Action -in @('CompleteFailoverCluster','InstallFailoverCluster','Addnode'))
    {
        $sqlHostName = $FailoverClusterNetworkName
    }
    else
    {
        $sqlHostName = $env:COMPUTERNAME
    }

    # Force drive list update, to pick up any newly mounted volumes
    $null = Get-PSDrive

    $SourcePath = [Environment]::ExpandEnvironmentVariables($SourcePath)

    if ($SourceCredential)
    {
        Connect-UncPath -RemotePath $SourcePath -SourceCredential $SourceCredential
    }

    $pathToSetupExecutable = Join-Path -Path $SourcePath -ChildPath 'setup.exe'

    Write-Verbose -Message ($script:localizedData.UsingPath -f $pathToSetupExecutable)

    $sqlVersion = Get-SqlMajorVersion -Path $pathToSetupExecutable

    if ($SourceCredential)
    {
        Disconnect-UncPath -RemotePath $SourcePath
    }

    $serviceNames = Get-ServiceNamesForInstance -InstanceName $InstanceName -SqlServerMajorVersion $sqlVersion

    $features = ''

    # Get the name of the relevant services that are actually installed.
    $currentServiceNames = (Get-Service -Name @(
        $serviceNames.DatabaseService
        $serviceNames.AgentService
        $serviceNames.FullTextService
        $serviceNames.ReportService
        $serviceNames.AnalysisService
        $serviceNames.IntegrationService
    ) -ErrorAction 'SilentlyContinue').Name

    Write-Verbose -Message $script:localizedData.EvaluateDatabaseEngineFeature

    if ($serviceNames.DatabaseService -in $currentServiceNames)
    {
        Write-Verbose -Message $script:localizedData.DatabaseEngineFeatureFound

        $features += 'SQLENGINE,'

        # Get current properties for the feature SQLENGINE.
        $currentSqlEngineProperties = Get-SqlEngineProperties -ServerName $sqlHostName -InstanceName $InstanceName

        $getTargetResourceReturnValue.SQLSvcAccountUsername = $currentSqlEngineProperties.SQLSvcAccountUsername
        $getTargetResourceReturnValue.AgtSvcAccountUsername = $currentSqlEngineProperties.AgtSvcAccountUsername
        $getTargetResourceReturnValue.SqlSvcStartupType = $currentSqlEngineProperties.SqlSvcStartupType
        $getTargetResourceReturnValue.AgtSvcStartupType = $currentSqlEngineProperties.AgtSvcStartupType
        $getTargetResourceReturnValue.SQLCollation = $currentSqlEngineProperties.SQLCollation
        $getTargetResourceReturnValue.InstallSQLDataDir = $currentSqlEngineProperties.InstallSQLDataDir
        $getTargetResourceReturnValue.SQLUserDBDir = $currentSqlEngineProperties.SQLUserDBDir
        $getTargetResourceReturnValue.SQLUserDBLogDir = $currentSqlEngineProperties.SQLUserDBLogDir
        $getTargetResourceReturnValue.SQLBackupDir = $currentSqlEngineProperties.SQLBackupDir
        $getTargetResourceReturnValue.IsClustered = $currentSqlEngineProperties.IsClustered
        $getTargetResourceReturnValue.SecurityMode = $currentSqlEngineProperties.SecurityMode

        Write-Verbose -Message ($script:localizedData.EvaluateReplicationFeature -f $replicationRegistryPath)

        # Check if Replication sub component is configured for this instance
        $isReplicationInstalled = Test-IsReplicationFeatureInstalled -InstanceName $InstanceName

        if ($isReplicationInstalled)
        {
            Write-Verbose -Message $script:localizedData.ReplicationFeatureFound

            $features += 'REPLICATION,'
        }
        else
        {
            Write-Verbose -Message $script:localizedData.ReplicationFeatureNotFound
        }

        Write-Verbose -Message ($script:localizedData.EvaluateDataQualityServicesFeature -f $dataQualityServicesRegistryPath)

        # Check if the Data Quality Services sub component is configured.
        $isDQInstalled = Test-IsDQComponentInstalled -InstanceName $InstanceName -SqlServerMajorVersion $sqlVersion

        if ($isDQInstalled)
        {
            Write-Verbose -Message $script:localizedData.DataQualityServicesFeatureFound

            $features += 'DQ,'
        }
        else
        {
            Write-Verbose -Message $script:localizedData.DataQualityServicesFeatureNotFound
        }

        # Get the instance ID
        $fullInstanceId = Get-FullInstanceId -InstanceName $InstanceName
        $getTargetResourceReturnValue.InstanceID = $fullInstanceId.Split('.')[1]

        # Get the instance program path.
        $getTargetResourceReturnValue.InstanceDir = `
            Get-InstanceProgramPath -InstanceName $InstanceName

        if ($sqlVersion -ge 13)
        {
            # Retrieve information about Tempdb database and its files.
            $currentTempDbProperties = Get-TempDbProperties -ServerName $sqlHostName -InstanceName $InstanceName

            $getTargetResourceReturnValue.SQLTempDBDir = $currentTempDbProperties.SQLTempDBDir
            $getTargetResourceReturnValue.SqlTempdbFileCount = $currentTempDbProperties.SqlTempdbFileCount
            $getTargetResourceReturnValue.SqlTempdbFileSize = $currentTempDbProperties.SqlTempdbFileSize
            $getTargetResourceReturnValue.SqlTempdbFileGrowth = $currentTempDbProperties.SqlTempdbFileGrowth
            $getTargetResourceReturnValue.SqlTempdbLogFileSize = $currentTempDbProperties.SqlTempdbLogFileSize
            $getTargetResourceReturnValue.SqlTempdbLogFileGrowth = $currentTempDbProperties.SqlTempdbLogFileGrowth
        }

        # Get all members of the sysadmin role.
        $sqlSystemAdminAccounts = Get-SqlRoleMembers -RoleName 'sysadmin' -ServerName $sqlHostName -InstanceName $InstanceName
        $getTargetResourceReturnValue.SQLSysAdminAccounts = $sqlSystemAdminAccounts

        if ($getTargetResourceReturnValue.IsClustered)
        {
            Write-Verbose -Message $script:localizedData.ClusterInstanceFound

            $currentClusterProperties = Get-SqlClusterProperties -InstanceName $InstanceName

            $getTargetResourceReturnValue.FailoverClusterNetworkName = $currentClusterProperties.FailoverClusterNetworkName
            $getTargetResourceReturnValue.FailoverClusterGroupName = $currentClusterProperties.FailoverClusterGroupName
            $getTargetResourceReturnValue.FailoverClusterIPAddress = $currentClusterProperties.FailoverClusterIPAddress
        }
        else
        {
            Write-Verbose -Message $script:localizedData.ClusterInstanceNotFound
        }
    }
    else
    {
        Write-Verbose -Message $script:localizedData.DatabaseEngineFeatureNotFound
    }

    Write-Verbose -Message $script:localizedData.EvaluateFullTextFeature

    if ($serviceNames.FullTextService -in $currentServiceNames)
    {
        Write-Verbose -Message $script:localizedData.FullTextFeatureFound

        $features += 'FULLTEXT,'

        $getTargetResourceReturnValue.FTSvcAccountUsername = (
            Get-ServiceProperties -ServiceName $serviceNames.FullTextService
        ).UserName
    }
    else
    {
        Write-Verbose -Message $script:localizedData.FullTextFeatureNotFound
    }

    Write-Verbose -Message $script:localizedData.EvaluateReportingServicesFeature

    if ($serviceNames.ReportService -in $currentServiceNames)
    {
        Write-Verbose -Message $script:localizedData.ReportingServicesFeatureFound

        $features += 'RS,'

        $serviceReportingService = Get-ServiceProperties -ServiceName $serviceNames.ReportService

        $getTargetResourceReturnValue.RSSvcAccountUsername = $serviceReportingService.UserName
        $getTargetResourceReturnValue.RsSvcStartupType = $serviceReportingService.StartupType
    }
    else
    {
        Write-Verbose -Message $script:localizedData.ReportingServicesFeatureNotFound
    }

    Write-Verbose -Message $script:localizedData.EvaluateAnalysisServicesFeature

    if ($serviceNames.AnalysisService -in $currentServiceNames)
    {
        Write-Verbose -Message $script:localizedData.AnalysisServicesFeatureFound

        $features += 'AS,'

        $serviceAnalysisService = Get-ServiceProperties -ServiceName $serviceNames.AnalysisService

        $getTargetResourceReturnValue.ASSvcAccountUsername = $serviceAnalysisService.UserName
        $getTargetResourceReturnValue.AsSvcStartupType = $serviceAnalysisService.StartupType

        $analysisServer = Connect-SQLAnalysis -ServerName $sqlHostName -InstanceName $InstanceName

        $getTargetResourceReturnValue.ASCollation = $analysisServer.ServerProperties['CollationName'].Value
        $getTargetResourceReturnValue.ASDataDir = $analysisServer.ServerProperties['DataDir'].Value
        $getTargetResourceReturnValue.ASTempDir = $analysisServer.ServerProperties['TempDir'].Value
        $getTargetResourceReturnValue.ASLogDir = $analysisServer.ServerProperties['LogDir'].Value
        $getTargetResourceReturnValue.ASBackupDir = $analysisServer.ServerProperties['BackupDir'].Value

        <#
            The property $analysisServer.ServerMode.value__ contains the
            server mode (aka deployment mode) value 0, 1 or 2. See DeploymentMode
            here https://docs.microsoft.com/en-us/sql/analysis-services/server-properties/general-properties.

            The property $analysisServer.ServerMode contains the display name of
            the property value__. See more information here
            https://msdn.microsoft.com/en-us/library/microsoft.analysisservices.core.server.servermode.aspx.
        #>
        $getTargetResourceReturnValue.ASServerMode = $analysisServer.ServerMode.ToString().ToUpper()

        $getTargetResourceReturnValue.ASSysAdminAccounts = [System.String[]] $analysisServer.Roles['Administrators'].Members.Name

        $serviceAnalysisServiceImagePath = Get-RegistryPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($serviceNames.AnalysisService)" -Name 'ImagePath'
        $foundAnalysisServiceConfigPath = $serviceAnalysisServiceImagePath -match '-s\s*"(.*)"'

        if ($foundAnalysisServiceConfigPath)
        {
            $getTargetResourceReturnValue.ASConfigDir = $matches[1]
        }
    }
    else
    {
        Write-Verbose -Message $script:localizedData.AnalysisServicesFeatureNotFound
    }

    Write-Verbose -Message $script:localizedData.EvaluateIntegrationServicesFeature

    if ($serviceNames.IntegrationService -in $currentServiceNames)
    {
        Write-Verbose -Message $script:localizedData.IntegrationServicesFeatureFound

        $features += 'IS,'

        $serviceIntegrationService = Get-ServiceProperties -ServiceName $serviceNames.IntegrationService

        $getTargetResourceReturnValue.ISSvcAccountUsername = $serviceIntegrationService.UserName
        $getTargetResourceReturnValue.IsSvcStartupType = $serviceIntegrationService.StartupType
    }
    else
    {
        Write-Verbose -Message $script:localizedData.IntegrationServicesFeatureNotFound
    }

    $installedSharedFeatures = Get-InstalledSharedFeatures -SqlServerMajorVersion $sqlVersion
    $features += '{0},' -f ($installedSharedFeatures -join ',')

    if ((Test-IsSsmsInstalled -SqlServerMajorVersion $sqlVersion))
    {
        $features += 'SSMS,'
    }

    if ((Test-IsSsmsAdvancedInstalled -SqlServerMajorVersion $sqlVersion))
    {
        $features += 'ADV_SSMS,'
    }

    $features = $features.Trim(',')

    if ($features)
    {
        $currentSqlSharedPaths = Get-SqlSharedPaths -SqlServerMajorVersion $sqlVersion

        $getTargetResourceReturnValue.InstallSharedDir = $currentSqlSharedPaths.InstallSharedDir
        $getTargetResourceReturnValue.InstallSharedWOWDir = $currentSqlSharedPaths.InstallSharedWOWDir
    }

    <#
        If no features was found, this will be set to en empty string. The variable
        $features is initially set to an empty string.
    #>
    $getTargetResourceReturnValue.Features = $features

    return $getTargetResourceReturnValue
}

<#
    .SYNOPSIS
        Installs the SQL Server features to the node.

    .PARAMETER Action
        The action to be performed. Default value is 'Install'.
        Possible values are 'Install', 'Upgrade', 'InstallFailoverCluster', 'AddNode',
        'PrepareFailoverCluster', and 'CompleteFailoverCluster'.

    .PARAMETER SourcePath
        The path to the root of the source files for installation. I.e and UNC path
        to a shared resource. Environment variables can be used in the path.

    .PARAMETER SourceCredential
        Credentials used to access the path set in the parameter `SourcePath`.
        Using this parameter will trigger a copy of the installation media to a temp
        folder on the target node. Setup will then be started from the temp folder
        on the target node. For any subsequent calls to the resource, the parameter
        `SourceCredential` is used to evaluate what major version the file 'setup.exe'
        has in the path set, again, by the parameter `SourcePath`. If the path, that
        is assigned to parameter `SourcePath`, contains a leaf folder, for example
        '\\server\share\folder', then that leaf folder will be used as the name of
        the temporary folder. If the path, that is assigned to parameter `SourcePath`,
        does not have a leaf folder, for example '\\server\share', then a unique guid
        will be used as the name of the temporary folder.

    .PARAMETER SuppressReboot
        Suppressed reboot.

    .PARAMETER ForceReboot
        Forces reboot.

    .PARAMETER Features
        SQL features to be installed.

    .PARAMETER InstanceName
        Name of the SQL instance to be installed.

    .PARAMETER InstanceID
        SQL instance ID, if different from InstanceName.

    .PARAMETER ProductKey
        Product key for licensed installations.

    .PARAMETER UpdateEnabled
        Enabled updates during installation.

    .PARAMETER UpdateSource
        Path to the source of updates to be applied during installation.

    .PARAMETER SQMReporting
        Enable customer experience reporting.

    .PARAMETER ErrorReporting
        Enable error reporting.

    .PARAMETER InstallSharedDir
        Installation path for shared SQL files.

    .PARAMETER InstallSharedWOWDir
        Installation path for x86 shared SQL files.

    .PARAMETER InstanceDir
        Installation path for SQL instance files.

    .PARAMETER SQLSvcAccount
        Service account for the SQL service.

    .PARAMETER AgtSvcAccount
        Service account for the SQL Agent service.

    .PARAMETER SQLCollation
        Collation for SQL.

    .PARAMETER SQLSysAdminAccounts
        Array of accounts to be made SQL administrators.

    .PARAMETER SecurityMode
        Security mode to apply to the
        SQL Server instance. 'SQL' indicates mixed-mode authentication while
        'Windows' indicates Windows authentication.
        Default is Windows. { *Windows* | SQL }

    .PARAMETER SAPwd
        SA password, if SecurityMode is set to 'SQL'.

    .PARAMETER InstallSQLDataDir
        Root path for SQL database files.

    .PARAMETER SQLUserDBDir
        Path for SQL database files.

    .PARAMETER SQLUserDBLogDir
        Path for SQL log files.

    .PARAMETER SQLTempDBDir
        Path for SQL TempDB files.

    .PARAMETER SQLTempDBLogDir
        Path for SQL TempDB log files.

    .PARAMETER SQLBackupDir
        Path for SQL backup files.

    .PARAMETER FTSvcAccount
        Service account for the Full Text service.

    .PARAMETER RSSvcAccount
        Service account for Reporting Services service.

    .PARAMETER RSInstallMode
        Install mode for Reporting Services.

    .PARAMETER ASSvcAccount
       Service account for Analysis Services service.

    .PARAMETER ASCollation
        Collation for Analysis Services.

    .PARAMETER ASSysAdminAccounts
        Array of accounts to be made Analysis Services admins.

    .PARAMETER ASDataDir
        Path for Analysis Services data files.

    .PARAMETER ASLogDir
        Path for Analysis Services log files.

    .PARAMETER ASBackupDir
        Path for Analysis Services backup files.

    .PARAMETER ASTempDir
        Path for Analysis Services temp files.

    .PARAMETER ASConfigDir
        Path for Analysis Services config.

    .PARAMETER ASServerMode
        The server mode for SQL Server Analysis Services instance. The default is
        to install in Multidimensional mode. Valid values in a cluster scenario
        are MULTIDIMENSIONAL or TABULAR. Parameter ASServerMode is case-sensitive.
        All values must be expressed in upper case.
        { MULTIDIMENSIONAL | TABULAR | POWERPIVOT }.

    .PARAMETER ISSvcAccount
       Service account for Integration Services service.

    .PARAMETER SqlSvcStartupType
       Specifies the startup mode for SQL Server Engine service.

    .PARAMETER AgtSvcStartupType
       Specifies the startup mode for SQL Server Agent service.

    .PARAMETER AsSvcStartupType
       Specifies the startup mode for SQL Server Analysis service.

    .PARAMETER IsSvcStartupType
       Specifies the startup mode for SQL Server Integration service.

    .PARAMETER RsSvcStartupType
       Specifies the startup mode for SQL Server Report service.

    .PARAMETER BrowserSvcStartupType
       Specifies the startup mode for SQL Server Browser service.

    .PARAMETER FailoverClusterGroupName
        The name of the resource group to create for the clustered SQL Server instance.
        Default is 'SQL Server (InstanceName)'.

    .PARAMETER FailoverClusterIPAddress
        Array of IP Addresses to be assigned to the clustered SQL Server instance.

    .PARAMETER FailoverClusterNetworkName
        Host name to be assigned to the clustered SQL Server instance.

    .PARAMETER SqlTempdbFileCount
        Specifies the number of tempdb data files to be added by setup.

    .PARAMETER SqlTempdbFileSize
        Specifies the initial size of each tempdb data file in MB.

    .PARAMETER SqlTempdbFileGrowth
        Specifies the file growth increment of each tempdb data file in MB.

    .PARAMETER SqlTempdbLogFileSize
        Specifies the initial size of each tempdb log file in MB.

    .PARAMETER SqlTempdbLogFileGrowth
        Specifies the file growth increment of each tempdb data file in MB.

    .PARAMETER NpEnabled
        Specifies the state of the Named Pipes protocol for the SQL Server service.
        The value $true will enable the Named Pipes protocol and $false will disabled
        it.

    .PARAMETER TcpEnabled
        Specifies the state of the TCP protocol for the SQL Server service. The
        value $true will enable the TCP protocol and $false will disabled it.

    .PARAMETER SetupProcessTimeout
        The timeout, in seconds, to wait for the setup process to finish. Default
        value is 7200 seconds (2 hours). If the setup process does not finish before
        this time, and error will be thrown.

    .PARAMETER FeatureFlag
        Feature flags are used to toggle functionality on or off. See the
        documentation for what additional functionality exist through a feature
        flag.
#>
function Set-TargetResource
{
    <#
        Suppressing this rule because $global:DSCMachineStatus is used to trigger
        a reboot, either by force or when there are pending changes.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    <#
        Suppressing this rule because $global:DSCMachineStatus is only set,
        never used (by design of Desired State Configuration).
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments','')]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Install','Upgrade','InstallFailoverCluster','AddNode','PrepareFailoverCluster','CompleteFailoverCluster')]
        [System.String]
        $Action = 'Install',

        [Parameter()]
        [System.String]
        $SourcePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Boolean]
        $SuppressReboot,

        [Parameter()]
        [System.Boolean]
        $ForceReboot,

        [Parameter()]
        [System.String]
        $Features,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $InstanceID,

        [Parameter()]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.String]
        $UpdateEnabled,

        [Parameter()]
        [System.String]
        $UpdateSource,

        [Parameter()]
        [System.String]
        $SQMReporting,

        [Parameter()]
        [System.String]
        $ErrorReporting,

        [Parameter()]
        [System.String]
        $InstallSharedDir,

        [Parameter()]
        [System.String]
        $InstallSharedWOWDir,

        [Parameter()]
        [System.String]
        $InstanceDir,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SQLSvcAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $AgtSvcAccount,

        [Parameter()]
        [System.String]
        $SQLCollation,

        [Parameter()]
        [System.String[]]
        $SQLSysAdminAccounts,

        [Parameter()]
        [ValidateSet('SQL', 'Windows')]
        [System.String]
        $SecurityMode,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SAPwd,

        [Parameter()]
        [System.String]
        $InstallSQLDataDir,

        [Parameter()]
        [System.String]
        $SQLUserDBDir,

        [Parameter()]
        [System.String]
        $SQLUserDBLogDir,

        [Parameter()]
        [System.String]
        $SQLTempDBDir,

        [Parameter()]
        [System.String]
        $SQLTempDBLogDir,

        [Parameter()]
        [System.String]
        $SQLBackupDir,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $FTSvcAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $RSSvcAccount,

        [Parameter()]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.String]
        $RSInstallMode,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ASSvcAccount,

        [Parameter()]
        [System.String]
        $ASCollation,

        [Parameter()]
        [System.String[]]
        $ASSysAdminAccounts,

        [Parameter()]
        [System.String]
        $ASDataDir,

        [Parameter()]
        [System.String]
        $ASLogDir,

        [Parameter()]
        [System.String]
        $ASBackupDir,

        [Parameter()]
        [System.String]
        $ASTempDir,

        [Parameter()]
        [System.String]
        $ASConfigDir,

        [Parameter()]
        [ValidateSet('MULTIDIMENSIONAL','TABULAR','POWERPIVOT', IgnoreCase = $false)]
        [System.String]
        $ASServerMode,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ISSvcAccount,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $SqlSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $AgtSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $IsSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $AsSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $RsSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $BrowserSvcStartupType,

        [Parameter()]
        [System.String]
        $FailoverClusterGroupName,

        [Parameter()]
        [System.String[]]
        $FailoverClusterIPAddress,

        [Parameter()]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbFileCount,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbFileSize,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbFileGrowth,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbLogFileSize,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbLogFileGrowth,

        [Parameter()]
        [System.Boolean]
        $NpEnabled,

        [Parameter()]
        [System.Boolean]
        $TcpEnabled,

        [Parameter()]
        [System.UInt32]
        $SetupProcessTimeout = 7200,

        [Parameter()]
        [System.String[]]
        $FeatureFlag
    )

    <#
        Fixing issue 448, setting FailoverClusterGroupName to default value
        if not specified in configuration.
    #>
    if (-not $PSBoundParameters.ContainsKey('FailoverClusterGroupName'))
    {
        $FailoverClusterGroupName = 'SQL Server ({0})' -f $InstanceName
    }

    # Force drive list update, to pick up any newly mounted volumes
    $null = Get-PSDrive

    $getTargetResourceParameters = @{
        Action = $Action
        SourcePath = $SourcePath
        SourceCredential = $SourceCredential
        InstanceName = $InstanceName
        FailoverClusterNetworkName = $FailoverClusterNetworkName
        FeatureFlag = $FeatureFlag
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $InstanceName = $InstanceName.ToUpper()

    $parametersToEvaluateTrailingSlash = @(
        'InstanceDir',
        'InstallSharedDir',
        'InstallSharedWOWDir',
        'InstallSQLDataDir',
        'SQLUserDBDir',
        'SQLUserDBLogDir',
        'SQLTempDBDir',
        'SQLTempDBLogDir',
        'SQLBackupDir',
        'ASDataDir',
        'ASLogDir',
        'ASBackupDir',
        'ASTempDir',
        'ASConfigDir',
        'UpdateSource'
    )

    # Making sure paths are correct.
    foreach ($parameterName in $parametersToEvaluateTrailingSlash)
    {
        if ($PSBoundParameters.ContainsKey($parameterName))
        {
            $parameterValue = Get-Variable -Name $parameterName -ValueOnly
            $formattedPath = Format-Path -Path $parameterValue -TrailingSlash
            Set-Variable -Name $parameterName -Value $formattedPath
        }
    }

    $SourcePath = [Environment]::ExpandEnvironmentVariables($SourcePath)

    if ($SourceCredential)
    {
        $invokeInstallationMediaCopyParameters = @{
            SourcePath = $SourcePath
            SourceCredential = $SourceCredential
            PassThru = $true
        }

        $SourcePath = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
    }

    $pathToSetupExecutable = Join-Path -Path $SourcePath -ChildPath 'setup.exe'

    Write-Verbose -Message ($script:localizedData.UsingPath -f $pathToSetupExecutable)

    $sqlVersion = Get-SqlMajorVersion -Path $pathToSetupExecutable

    # Determine features to install
    $featuresToInstall = ''

    $featuresArray = $Features -split ','

    foreach ($feature in $featuresArray)
    {
        if (($sqlVersion -in ('13','14')) -and ($feature -in ('ADV_SSMS','SSMS')))
        {
            $errorMessage = $script:localizedData.FeatureNotSupported -f $feature
            New-InvalidOperationException -Message $errorMessage
        }

        $foundFeaturesArray = $getTargetResourceResult.Features -split ','

        if ($feature -notin $foundFeaturesArray)
        {
            # Must make sure the feature names are provided in upper-case.
            $featuresToInstall += '{0},' -f $feature.ToUpper()
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.FeatureAlreadyInstalled -f $feature)
        }
    }

    $Features = $featuresToInstall.Trim(',')

    # If SQL shared components already installed, clear InstallShared*Dir variables
    switch ($sqlVersion)
    {
        { $_ -in ('10','11','12','13','14') }
        {
            if ((Get-Variable -Name 'InstallSharedDir' -ErrorAction SilentlyContinue) -and (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69' -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name 'InstallSharedDir' -Value ''
            }

            if ((Get-Variable -Name 'InstallSharedWOWDir' -ErrorAction SilentlyContinue) -and (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4' -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name 'InstallSharedWOWDir' -Value ''
            }
        }
    }

    $setupArguments = @{}

    if ($Action -in @('PrepareFailoverCluster','CompleteFailoverCluster','InstallFailoverCluster','Addnode'))
    {
        # This was brought over from the old module. Should be removed (breaking change).
        $setupArguments['SkipRules'] = 'Cluster_VerifyForErrors'
    }

    <#
        Set the failover cluster group name and failover cluster network name for this clustered instance
        if the action is either installing (InstallFailoverCluster) or completing (CompleteFailoverCluster) a cluster.
    #>
    if ($Action -in @('CompleteFailoverCluster','InstallFailoverCluster'))
    {
        $setupArguments['FailoverClusterNetworkName'] = $FailoverClusterNetworkName
        $setupArguments['FailoverClusterGroup'] = $FailoverClusterGroupName
    }

    # Perform disk mapping for specific cluster installation types
    if ($Action -in @('CompleteFailoverCluster','InstallFailoverCluster'))
    {
        $requiredDrive = @()

        # This is also used to evaluate which cluster shard disks should be used.
        $parametersToEvaluateShareDisk = @(
            'InstallSQLDataDir',
            'SQLUserDBDir',
            'SQLUserDBLogDir',
            'SQLTempDBDir',
            'SQLTempDBLogDir',
            'SQLBackupDir',
            'ASDataDir',
            'ASLogDir',
            'ASBackupDir',
            'ASTempDir',
            'ASConfigDir'
        )

        # Get a required listing of drives based on parameters assigned by user.
        foreach ($parameterName in $parametersToEvaluateShareDisk)
        {
            if ($PSBoundParameters.ContainsKey($parameterName))
            {
                $parameterValue = Get-Variable -Name $parameterName -ValueOnly
                if ($parameterValue)
                {
                    Write-Verbose -Message ($script:localizedData.PathRequireClusterDriveFound -f $parameterName, $parameterValue)
                    $requiredDrive += $parameterValue
                }
            }
        }

        # Only keep unique paths and add a member to keep track if the path is mapped to a disk.
        $requiredDrive = $requiredDrive | Sort-Object -Unique | Add-Member -MemberType NoteProperty -Name IsMapped -Value $false -PassThru

        # Get the disk resources that are available (not assigned to a cluster role)
        $availableStorage = Get-CimInstance -Namespace 'root/MSCluster' -ClassName 'MSCluster_ResourceGroup' -Filter "Name = 'Available Storage'" |
                                Get-CimAssociatedInstance -Association MSCluster_ResourceGroupToResource -ResultClassName MSCluster_Resource | `
                                    Add-Member -MemberType NoteProperty -Name 'IsPossibleOwner' -Value $false -PassThru

        # First map regular cluster volumes
        foreach ($diskResource in $availableStorage)
        {
            # Determine whether the current node is a possible owner of the disk resource
            $possibleOwners = $diskResource | Get-CimAssociatedInstance -Association 'MSCluster_ResourceToPossibleOwner' -KeyOnly | Select-Object -ExpandProperty Name

            if ($possibleOwners -icontains $env:COMPUTERNAME)
            {
                $diskResource.IsPossibleOwner = $true
            }
        }

        $failoverClusterDisks = @()

        foreach ($currentRequiredDrive in $requiredDrive)
        {
            foreach ($diskResource in ($availableStorage | Where-Object {$_.IsPossibleOwner -eq $true}))
            {
                $partitions = $diskResource | Get-CimAssociatedInstance -ResultClassName 'MSCluster_DiskPartition' | Select-Object -ExpandProperty Path
                foreach ($partition in $partitions)
                {
                    if ($currentRequiredDrive -imatch $partition.Replace('\','\\'))
                    {
                        $currentRequiredDrive.IsMapped = $true
                        $failoverClusterDisks += $diskResource.Name
                        break
                    }

                    if ($currentRequiredDrive.IsMapped)
                    {
                        break
                    }
                }

                if ($currentRequiredDrive.IsMapped)
                {
                    break
                }
            }
        }

        # Now we handle cluster shared volumes
        $clusterSharedVolumes = Get-CimInstance -ClassName 'MSCluster_ClusterSharedVolume' -Namespace 'root/MSCluster'

        foreach ($clusterSharedVolume in $clusterSharedVolumes)
        {
            foreach ($currentRequiredDrive in ($requiredDrive | Where-Object {$_.IsMapped -eq $false}))
            {
                if ($currentRequiredDrive -imatch $clusterSharedVolume.Name.Replace('\','\\'))
                {
                    $diskName = Get-CimInstance -ClassName 'MSCluster_ClusterSharedVolumeToResource' -Namespace 'root/MSCluster' | `
                        Where-Object {$_.GroupComponent.Name -eq $clusterSharedVolume.Name} | `
                        Select-Object -ExpandProperty PartComponent | `
                        Select-Object -ExpandProperty Name
                    $failoverClusterDisks += $diskName
                    $currentRequiredDrive.IsMapped = $true
                }
            }
        }

        # Ensure we have a unique listing of disks
        $failoverClusterDisks = $failoverClusterDisks | Sort-Object -Unique

        # Ensure we mapped all required drives
        $unMappedRequiredDrives = $requiredDrive | Where-Object {$_.IsMapped -eq $false} | Measure-Object
        if ($unMappedRequiredDrives.Count -gt 0)
        {
            $errorMessage = $script:localizedData.FailoverClusterDiskMappingError -f ($failoverClusterDisks -join '; ')
            New-InvalidResultException -Message $errorMessage
        }

        # Add the cluster disks as a setup argument
        $setupArguments['FailoverClusterDisks'] = ($failoverClusterDisks | Sort-Object)
    }

    # Determine network mapping for specific cluster installation types
    if ($Action -in @('CompleteFailoverCluster','InstallFailoverCluster'))
    {
        $clusterIPAddresses = @()

        # If no IP Address has been specified, use "DEFAULT"
        if ($FailoverClusterIPAddress.Count -eq 0)
        {
            $clusterIPAddresses += "DEFAULT"
        }
        else
        {
            # Get the available client networks
            $availableNetworks = @(Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Network -Filter 'Role >= 2')

            # Add supplied IP Addresses that are valid for available cluster networks
            foreach ($address in $FailoverClusterIPAddress)
            {
                foreach ($network in $availableNetworks)
                {
                    # Determine whether the IP address is valid for this network
                    if (Test-IPAddress -IPAddress $address -NetworkID $network.Address -SubnetMask $network.AddressMask)
                    {
                        # Add the formatted string to our array
                        $clusterIPAddresses += "IPv4;$address;$($network.Name);$($network.AddressMask)"
                    }
                }
            }
        }

        # Ensure we mapped all required networks
        $suppliedNetworkCount = $FailoverClusterIPAddress.Count
        $mappedNetworkCount = $clusterIPAddresses.Count

        # Determine whether we have mapping issues for the IP Address(es)
        if ($mappedNetworkCount -lt $suppliedNetworkCount)
        {
            $errorMessage = $script:localizedData.FailoverClusterIPAddressNotValid
            New-InvalidResultException -Message $errorMessage
        }

        # Add the networks to the installation arguments
        $setupArguments['FailoverClusterIPAddresses'] = $clusterIPAddresses
    }

    # Add standard install arguments
    $setupArguments += @{
        Quiet = $true
        IAcceptSQLServerLicenseTerms = $true
        Action = $Action
    }

    $argumentVars = @(
        'InstanceName',
        'InstanceID',
        'UpdateEnabled',
        'UpdateSource',
        'ProductKey',
        'SQMReporting',
        'ErrorReporting'
    )

    if ($Action -in @('Install','Upgrade','InstallFailoverCluster','PrepareFailoverCluster','CompleteFailoverCluster'))
    {
        $argumentVars += @(
            'Features',
            'InstallSharedDir',
            'InstallSharedWOWDir',
            'InstanceDir'
        )
    }

    if ($null -ne $BrowserSvcStartupType)
    {
        $argumentVars += 'BrowserSvcStartupType'
    }

    if ($Features.Contains('SQLENGINE'))
    {
        if ($PSBoundParameters.ContainsKey('SQLSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $SQLSvcAccount -ServiceType 'SQL')
        }

        if ($PSBoundParameters.ContainsKey('AgtSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $AgtSvcAccount -ServiceType 'AGT')
        }

        if ($SecurityMode -eq 'SQL')
        {
            $setupArguments['SAPwd'] = $SAPwd.GetNetworkCredential().Password
        }

        # Should not be passed when PrepareFailoverCluster is specified
        if ($Action -in @('Install','Upgrade','InstallFailoverCluster','CompleteFailoverCluster'))
        {
            if ($null -ne $PsDscContext.RunAsUser)
            {
                <#
                    Add the credentials from the parameter PsDscRunAsCredential, as the first
                    system administrator. The username is stored in $PsDscContext.RunAsUser.
                #>
                Write-Verbose -Message ($script:localizedData.AddingFirstSystemAdministratorSqlServer -f $($PsDscContext.RunAsUser))

                $setupArguments['SQLSysAdminAccounts'] = @($PsDscContext.RunAsUser)
            }

            if ($PSBoundParameters.ContainsKey('SQLSysAdminAccounts'))
            {
                $setupArguments['SQLSysAdminAccounts'] += $SQLSysAdminAccounts
            }

            if ($PSBoundParameters.ContainsKey('NpEnabled'))
            {
                if ($NpEnabled)
                {
                    $setupArguments['NPENABLED'] = 1
                }
                else
                {
                    $setupArguments['NPENABLED'] = 0
                }
            }

            if ($PSBoundParameters.ContainsKey('TcpEnabled'))
            {
                if ($TcpEnabled)
                {
                    $setupArguments['TCPENABLED'] = 1
                }
                else
                {
                    $setupArguments['TCPENABLED'] = 0
                }
            }

            $argumentVars += @(
                'SecurityMode',
                'SQLCollation',
                'InstallSQLDataDir',
                'SQLUserDBDir',
                'SQLUserDBLogDir',
                'SQLTempDBDir',
                'SQLTempDBLogDir',
                'SQLBackupDir'
            )
        }

        # tempdb : define SqlTempdbFileCount
        if ($PSBoundParameters.ContainsKey('SqlTempdbFileCount'))
        {
            $setupArguments['SqlTempdbFileCount'] = $SqlTempdbFileCount
        }

        # tempdb : define SqlTempdbFileSize
        if ($PSBoundParameters.ContainsKey('SqlTempdbFileSize'))
        {
            $setupArguments['SqlTempdbFileSize'] = $SqlTempdbFileSize
        }

        # tempdb : define SqlTempdbFileGrowth
        if ($PSBoundParameters.ContainsKey('SqlTempdbFileGrowth'))
        {
            $setupArguments['SqlTempdbFileGrowth'] = $SqlTempdbFileGrowth
        }

        # tempdb : define SqlTempdbLogFileSize
        if ($PSBoundParameters.ContainsKey('SqlTempdbLogFileSize'))
        {
            $setupArguments['SqlTempdbLogFileSize'] = $SqlTempdbLogFileSize
        }

        # tempdb : define SqlTempdbLogFileGrowth
        if ($PSBoundParameters.ContainsKey('SqlTempdbLogFileGrowth'))
        {
            $setupArguments['SqlTempdbLogFileGrowth'] = $SqlTempdbLogFileGrowth
        }

        if ($Action -in @('Install','Upgrade'))
        {
            if ($PSBoundParameters.ContainsKey('AgtSvcStartupType'))
            {
                $setupArguments['AgtSvcStartupType'] = $AgtSvcStartupType
            }

            if ($PSBoundParameters.ContainsKey('SqlSvcStartupType'))
            {
                $setupArguments['SqlSvcStartupType'] = $SqlSvcStartupType
            }
        }
    }

    if ($Features.Contains('FULLTEXT'))
    {
        if ($PSBoundParameters.ContainsKey('FTSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $FTSvcAccount -ServiceType 'FT')
        }
    }

    if ($Features.Contains('RS'))
    {
        if ($PSBoundParameters.ContainsKey('RSSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $RSSvcAccount -ServiceType 'RS')
        }

        if ($PSBoundParameters.ContainsKey('RsSvcStartupType'))
        {
            $setupArguments['RsSvcStartupType'] = $RsSvcStartupType
        }

        if ($PSBoundParameters.ContainsKey('RSInstallMode'))
        {
            $setupArguments['RSINSTALLMODE'] = $RSInstallMode
        }
    }

    if ($Features.Contains('AS'))
    {
        $argumentVars += @(
            'ASCollation',
            'ASDataDir',
            'ASLogDir',
            'ASBackupDir',
            'ASTempDir',
            'ASConfigDir'
        )


        if ($PSBoundParameters.ContainsKey('ASServerMode'))
        {
            $setupArguments['ASServerMode'] = $ASServerMode
        }

        if ($PSBoundParameters.ContainsKey('ASSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $ASSvcAccount -ServiceType 'AS')
        }

        if ($Action -in ('Install','Upgrade','InstallFailoverCluster','CompleteFailoverCluster'))
        {
            if ($null -ne $PsDscContext.RunAsUser)
            {
                <#
                    Add the credentials from the parameter PsDscRunAsCredential, as the first
                    system administrator. The username is stored in $PsDscContext.RunAsUser.
                #>
                Write-Verbose -Message ($script:localizedData.AddingFirstSystemAdministratorAnalysisServices -f $($PsDscContext.RunAsUser))

                $setupArguments['ASSysAdminAccounts'] = @($PsDscContext.RunAsUser)
            }

            if ($PSBoundParameters.ContainsKey("ASSysAdminAccounts"))
            {
                $setupArguments['ASSysAdminAccounts'] += $ASSysAdminAccounts
            }
        }

        if ($PSBoundParameters.ContainsKey('AsSvcStartupType'))
        {
            $setupArguments['AsSvcStartupType'] = $AsSvcStartupType
        }
    }

    if ($Features.Contains('IS'))
    {
        if ($PSBoundParameters.ContainsKey('ISSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $ISSvcAccount -ServiceType 'IS')
        }

        if ($PSBoundParameters.ContainsKey('IsSvcStartupType'))
        {
            $setupArguments['IsSvcStartupType'] = $IsSvcStartupType
        }
    }

    # Automatically include any additional arguments
    foreach ($argument in $argumentVars)
    {
        if ($argument -eq 'ProductKey')
        {
            $setupArguments['PID'] = Get-Variable -Name $argument -ValueOnly
        }
        else
        {
            # If the argument contains a value, then add the argument to the setup argument list
            if (Get-Variable -Name $argument -ValueOnly)
            {
                $setupArguments[$argument] = Get-Variable -Name $argument -ValueOnly
            }
        }
    }

    # Build the argument string to be passed to setup
    $arguments = ''
    foreach ($currentSetupArgument in $setupArguments.GetEnumerator())
    {
        <#
            Using [System.String]::IsNullOrEmpty() instead if comparing against
            an empty string ('') because the numeric value zero (0) equals to an
            empty string. This is evaluated to $true: 0 -eq ''
        #>
        if (-not [System.String]::IsNullOrEmpty($currentSetupArgument.Value))
        {
            # Arrays are handled specially
            if ($currentSetupArgument.Value -is [System.Array])
            {
                # Sort and format the array
                $setupArgumentValue = ($currentSetupArgument.Value | Sort-Object | ForEach-Object { '"{0}"' -f $_ }) -join ' '
            }
            elseif ($currentSetupArgument.Value -is [System.Boolean])
            {
                $setupArgumentValue = @{
                    $true = 'True'
                    $false = 'False'
                }[$currentSetupArgument.Value]

                $setupArgumentValue = '"{0}"' -f $setupArgumentValue
            }
            else
            {
                # Features are comma-separated, no quotes
                if ($currentSetupArgument.Key -eq 'Features')
                {
                    $setupArgumentValue = $currentSetupArgument.Value
                }
                else
                {
                    # Logic added as a fix for Issue#1254 SqlSetup:Fails when a root directory is specified
                    if ($currentSetupArgument.Value -match '^[a-zA-Z]:\\$')
                    {
                        $setupArgumentValue = $currentSetupArgument.Value
                    }
                    else
                    {
                        $setupArgumentValue = '"{0}"' -f $currentSetupArgument.Value
                    }

                }
            }

            $arguments += "/$($currentSetupArgument.Key.ToUpper())=$($setupArgumentValue) "
        }
    }

    # Replace sensitive values for verbose output
    $log = $arguments
    if ($SecurityMode -eq 'SQL')
    {
        $log = $log.Replace($SAPwd.GetNetworkCredential().Password,"********")
    }

    if ($ProductKey -ne "")
    {
        $log = $log.Replace($ProductKey,"*****-*****-*****-*****-*****")
    }

    $logVars = @('AgtSvcAccount', 'SQLSvcAccount', 'FTSvcAccount', 'RSSvcAccount', 'ASSvcAccount','ISSvcAccount')
    foreach ($logVar in $logVars)
    {
        if ($PSBoundParameters.ContainsKey($logVar))
        {
            $log = $log.Replace((Get-Variable -Name $logVar).Value.GetNetworkCredential().Password,"********")
        }
    }

    $arguments = $arguments.Trim()

    try
    {
        Write-Verbose -Message ($script:localizedData.SetupArguments -f $log)

        <#
            This handles when PsDscRunAsCredential is set, or running as the SYSTEM account (when
            PsDscRunAsCredential is not set).
        #>

        $startProcessParameters = @{
            FilePath = $pathToSetupExecutable
            ArgumentList = $arguments
            Timeout = $SetupProcessTimeout
        }

        $processExitCode = Start-SqlSetupProcess @startProcessParameters

        $setupExitMessage = ($script:localizedData.SetupExitMessage -f $processExitCode)

        if ($processExitCode -eq 3010 -and -not $SuppressReboot)
        {
            $setupExitMessageRebootRequired = ('{0} {1}' -f $setupExitMessage, ($script:localizedData.SetupSuccessfulRebootRequired))

            Write-Warning -Message $setupExitMessageRebootRequired
        }
        elseif ($processExitCode -ne 0)
        {
            $setupExitMessageError = ('{0} {1}' -f $setupExitMessage, ($script:localizedData.SetupFailed))
            Write-Warning $setupExitMessageError

            $setupEndedInError = $true
        }
        else
        {
            $setupExitMessageSuccessful = ('{0} {1}' -f $setupExitMessage, ($script:localizedData.SetupSuccessful))

            Write-Verbose -Message $setupExitMessageSuccessful
        }

        if ($ForceReboot -or (Test-PendingRestart))
        {
            if (-not ($SuppressReboot))
            {
                Write-Verbose -Message $script:localizedData.Reboot

                # Rebooting, so no point in refreshing the session.
                $forceReloadPowerShellModule = $false

                $global:DSCMachineStatus = 1
            }
            else
            {
                Write-Verbose -Message $script:localizedData.SuppressReboot
                $forceReloadPowerShellModule = $true
            }
        }
        else
        {
            $forceReloadPowerShellModule = $true
        }

        if ((-not $setupEndedInError) -and $forceReloadPowerShellModule)
        {
            <#
                Force reload of SQLPS module in case a newer version of
                SQL Server was installed that contains a newer version
                of the SQLPS module, although if SqlServer module exist
                on the target node, that will be used regardless.
                This is to make sure we use the latest SQLPS module that
                matches the latest assemblies in GAC, mitigating for example
                issue #1151.
            #>
            Import-SQLPSModule -Force
        }

        if (-not (Test-TargetResource @PSBoundParameters))
        {
            $errorMessage = $script:localizedData.TestFailedAfterSet
            New-InvalidResultException -Message $errorMessage
        }
    }
    catch
    {
        throw $_
    }
}

<#
    .SYNOPSIS
        Tests if the SQL Server features are installed on the node.

    .PARAMETER Action
        The action to be performed. Default value is 'Install'.
        Possible values are 'Install', 'Upgrade', 'InstallFailoverCluster', 'AddNode',
        'PrepareFailoverCluster', and 'CompleteFailoverCluster'.

    .PARAMETER SourcePath
        The path to the root of the source files for installation. I.e and UNC path
        to a shared resource. Environment variables can be used in the path.

    .PARAMETER SourceCredential
        Credentials used to access the path set in the parameter `SourcePath`.
        Using this parameter will trigger a copy of the installation media to a temp
        folder on the target node. Setup will then be started from the temp folder
        on the target node. For any subsequent calls to the resource, the parameter
        `SourceCredential` is used to evaluate what major version the file 'setup.exe'
        has in the path set, again, by the parameter `SourcePath`. If the path, that
        is assigned to parameter `SourcePath`, contains a leaf folder, for example
        '\\server\share\folder', then that leaf folder will be used as the name of
        the temporary folder. If the path, that is assigned to parameter `SourcePath`,
        does not have a leaf folder, for example '\\server\share', then a unique guid
        will be used as the name of the temporary folder.

    .PARAMETER SuppressReboot
        Suppresses reboot.

    .PARAMETER ForceReboot
        Forces reboot.

    .PARAMETER Features
        SQL features to be installed.

    .PARAMETER InstanceName
        Name of the SQL instance to be installed.

    .PARAMETER InstanceID
        SQL instance ID, if different from InstanceName.

    .PARAMETER ProductKey
        Product key for licensed installations.

    .PARAMETER UpdateEnabled
        Enabled updates during installation.

    .PARAMETER UpdateSource
        Path to the source of updates to be applied during installation.

    .PARAMETER SQMReporting
        Enable customer experience reporting.

    .PARAMETER ErrorReporting
        Enable error reporting.

    .PARAMETER InstallSharedDir
        Installation path for shared SQL files.

    .PARAMETER InstallSharedWOWDir
        Installation path for x86 shared SQL files.

    .PARAMETER InstanceDir
        Installation path for SQL instance files.

    .PARAMETER SQLSvcAccount
        Service account for the SQL service.

    .PARAMETER AgtSvcAccount
        Service account for the SQL Agent service.

    .PARAMETER SQLCollation
        Collation for SQL.

    .PARAMETER SQLSysAdminAccounts
        Array of accounts to be made SQL administrators.

    .PARAMETER SecurityMode
        Security mode to apply to the
        SQL Server instance. 'SQL' indicates mixed-mode authentication while
        'Windows' indicates Windows authentication.
        Default is Windows. { *Windows* | SQL }

    .PARAMETER SAPwd
        SA password, if SecurityMode is set to 'SQL'.

    .PARAMETER InstallSQLDataDir
        Root path for SQL database files.

    .PARAMETER SQLUserDBDir
        Path for SQL database files.

    .PARAMETER SQLUserDBLogDir
        Path for SQL log files.

    .PARAMETER SQLTempDBDir
        Path for SQL TempDB files.

    .PARAMETER SQLTempDBLogDir
        Path for SQL TempDB log files.

    .PARAMETER SQLBackupDir
        Path for SQL backup files.

    .PARAMETER FTSvcAccount
        Service account for the Full Text service.

    .PARAMETER RSSvcAccount
        Service account for Reporting Services service.

    .PARAMETER RSInstallMode
        Install mode for Reporting Services.

    .PARAMETER ASSvcAccount
       Service account for Analysis Services service.

    .PARAMETER ASCollation
        Collation for Analysis Services.

    .PARAMETER ASSysAdminAccounts
        Array of accounts to be made Analysis Services admins.

    .PARAMETER ASDataDir
        Path for Analysis Services data files.

    .PARAMETER ASLogDir
        Path for Analysis Services log files.

    .PARAMETER ASBackupDir
        Path for Analysis Services backup files.

    .PARAMETER ASTempDir
        Path for Analysis Services temp files.

    .PARAMETER ASConfigDir
        Path for Analysis Services config.

    .PARAMETER ASServerMode
        The server mode for SQL Server Analysis Services instance. The default is
        to install in Multidimensional mode. Valid values in a cluster scenario
        are MULTIDIMENSIONAL or TABULAR. Parameter ASServerMode is case-sensitive.
        All values must be expressed in upper case.
        { MULTIDIMENSIONAL | TABULAR | POWERPIVOT }.

    .PARAMETER ISSvcAccount
       Service account for Integration Services service.

    .PARAMETER SqlSvcStartupType
       Specifies the startup mode for SQL Server Engine service.

    .PARAMETER AgtSvcStartupType
       Specifies the startup mode for SQL Server Agent service.

    .PARAMETER IsSvcStartupType
       Specifies the startup mode for SQL Server Integration service.

    .PARAMETER AsSvcStartupType
       Specifies the startup mode for SQL Server Analysis service.

    .PARAMETER RsSvcStartupType
       Specifies the startup mode for SQL Server Report service.

    .PARAMETER BrowserSvcStartupType
       Specifies the startup mode for SQL Server Browser service.

    .PARAMETER FailoverClusterGroupName
        The name of the resource group to create for the clustered SQL Server instance.
        Default is 'SQL Server (InstanceName)'.

    .PARAMETER FailoverClusterIPAddress
        Array of IP Addresses to be assigned to the clustered SQL Server instance.

    .PARAMETER FailoverClusterNetworkName
        Host name to be assigned to the clustered SQL Server instance.

    .PARAMETER SqlTempdbFileCount
        Specifies the number of tempdb data files to be added by setup.

    .PARAMETER SqlTempdbFileSize
        Specifies the initial size of each tempdb data file in MB.

    .PARAMETER SqlTempdbFileGrowth
        Specifies the file growth increment of each tempdb data file in MB.

    .PARAMETER SqlTempdbLogFileSize
        Specifies the initial size of each tempdb log file in MB.

    .PARAMETER SqlTempdbLogFileGrowth
        Specifies the file growth increment of each tempdb data file in MB.

    .PARAMETER NpEnabled
        Specifies the state of the Named Pipes protocol for the SQL Server service.
        The value $true will enable the Named Pipes protocol and $false will disabled
        it.

        Not used in Test-TargetResource.

    .PARAMETER TcpEnabled
        Specifies the state of the TCP protocol for the SQL Server service. The
        value $true will enable the TCP protocol and $false will disabled it.

        Not used in Test-TargetResource.

    .PARAMETER SetupProcessTimeout
        The timeout, in seconds, to wait for the setup process to finish. Default
        value is 7200 seconds (2 hours). If the setup process does not finish before
        this time, and error will be thrown.

    .PARAMETER FeatureFlag
        Feature flags are used to toggle functionality on or off. See the
        documentation for what additional functionality exist through a feature
        flag.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Install', 'Upgrade', 'InstallFailoverCluster','AddNode','PrepareFailoverCluster','CompleteFailoverCluster')]
        [System.String]
        $Action = 'Install',

        [Parameter()]
        [System.String]
        $SourcePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Boolean]
        $SuppressReboot,

        [Parameter()]
        [System.Boolean]
        $ForceReboot,

        [Parameter()]
        [System.String]
        $Features,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $InstanceID,

        [Parameter()]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.String]
        $UpdateEnabled,

        [Parameter()]
        [System.String]
        $UpdateSource,

        [Parameter()]
        [System.String]
        $SQMReporting,

        [Parameter()]
        [System.String]
        $ErrorReporting,

        [Parameter()]
        [System.String]
        $InstallSharedDir,

        [Parameter()]
        [System.String]
        $InstallSharedWOWDir,

        [Parameter()]
        [System.String]
        $InstanceDir,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SQLSvcAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $AgtSvcAccount,

        [Parameter()]
        [System.String]
        $SQLCollation,

        [Parameter()]
        [System.String[]]
        $SQLSysAdminAccounts,

        [Parameter()]
        [ValidateSet('SQL', 'Windows')]
        [System.String]
        $SecurityMode,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SAPwd,

        [Parameter()]
        [System.String]
        $InstallSQLDataDir,

        [Parameter()]
        [System.String]
        $SQLUserDBDir,

        [Parameter()]
        [System.String]
        $SQLUserDBLogDir,

        [Parameter()]
        [System.String]
        $SQLTempDBDir,

        [Parameter()]
        [System.String]
        $SQLTempDBLogDir,

        [Parameter()]
        [System.String]
        $SQLBackupDir,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $FTSvcAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $RSSvcAccount,

        [Parameter()]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.String]
        $RSInstallMode,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ASSvcAccount,

        [Parameter()]
        [System.String]
        $ASCollation,

        [Parameter()]
        [System.String[]]
        $ASSysAdminAccounts,

        [Parameter()]
        [System.String]
        $ASDataDir,

        [Parameter()]
        [System.String]
        $ASLogDir,

        [Parameter()]
        [System.String]
        $ASBackupDir,

        [Parameter()]
        [System.String]
        $ASTempDir,

        [Parameter()]
        [System.String]
        $ASConfigDir,

        [Parameter()]
        [ValidateSet('MULTIDIMENSIONAL','TABULAR','POWERPIVOT', IgnoreCase = $false)]
        [System.String]
        $ASServerMode,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ISSvcAccount,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $SqlSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $AgtSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $IsSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $AsSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $RsSvcStartupType,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $BrowserSvcStartupType,

        [Parameter(ParameterSetName = 'ClusterInstall')]
        [System.String]
        $FailoverClusterGroupName,

        [Parameter(ParameterSetName = 'ClusterInstall')]
        [System.String[]]
        $FailoverClusterIPAddress,

        [Parameter(ParameterSetName = 'ClusterInstall')]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbFileCount,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbFileSize,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbFileGrowth,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbLogFileSize,

        [Parameter()]
        [System.UInt32]
        $SqlTempdbLogFileGrowth,

        [Parameter()]
        [System.Boolean]
        $NpEnabled,

        [Parameter()]
        [System.Boolean]
        $TcpEnabled,

        [Parameter()]
        [System.UInt32]
        $SetupProcessTimeout = 7200,

        [Parameter()]
        [System.String[]]
        $FeatureFlag
    )

    <#
        Fixing issue 448, setting FailoverClusterGroupName to default value
        if not specified in configuration.
    #>
    if (-not $PSBoundParameters.ContainsKey('FailoverClusterGroupName'))
    {
        $FailoverClusterGroupName = 'SQL Server ({0})' -f $InstanceName
    }

    $getTargetResourceParameters = @{
        Action = $Action
        SourcePath = $SourcePath
        SourceCredential = $SourceCredential
        InstanceName = $InstanceName
        FailoverClusterNetworkName = $FailoverClusterNetworkName
        FeatureFlag = $FeatureFlag
    }

    $boundParameters = $PSBoundParameters

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    if ($null -eq $getTargetResourceResult.Features -or $getTargetResourceResult.Features -eq '')
    {
        Write-Verbose -Message $script:localizedData.NoFeaturesFound
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.FeaturesFound -f $getTargetResourceResult.Features)
    }

    $result = $true

    if ($getTargetResourceResult.Features)
    {
        $featuresArray = $Features -split ','
        $foundFeaturesArray = $getTargetResourceResult.Features -split ','

        foreach ($feature in $featuresArray)
        {
            if ($feature -notin $foundFeaturesArray)
            {
                Write-Verbose -Message ($script:localizedData.UnableToFindFeature -f $feature, $($getTargetResourceResult.Features))
                $result = $false
            }
        }
    }
    else
    {
        $result = $false
    }

    if ($PSCmdlet.ParameterSetName -eq 'ClusterInstall')
    {
        Write-Verbose -Message $script:localizedData.EvaluatingClusterParameters

        $boundParameters.Keys | Where-Object {$_ -imatch "^FailoverCluster"} | ForEach-Object {
            $variableName = $_

            if ($getTargetResourceResult.$variableName -ne $boundParameters[$variableName])
            {
                Write-Verbose -Message ($script:localizedData.ClusterParameterIsNotInDesiredState -f $variableName, $($boundParameters[$variableName]))
                $result = $false
            }
        }
    }

    return $result
}

<#
    .SYNOPSIS
        Returns the SQL Server major version from the setup.exe executable provided in the Path parameter.

    .PARAMETER Path
        String containing the path to the SQL Server setup.exe executable.
#>
function Get-SqlMajorVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    (Get-Item -Path $Path).VersionInfo.ProductVersion.Split('.')[0]
}

<#
    .SYNOPSIS
        Returns the first item value in the registry location provided in the Path parameter.

    .PARAMETER Path
        String containing the path to the registry.

    .NOTES
        The property values that is returned from Get-Item can for example look like this:

        Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'

        Name                           Property
        ----                           --------
        FEE2E540D20152D4597229B6CFBC0A DCB13571726C2A64F9E1C79C020E9EA4 : C:\Program Files\Microsoft SQL Server\
        69                             52A7B04BB8030564B8245E7101DC4D9D : C:\Program Files\Microsoft SQL Server\
                                       17195C960C1F3104DB7F109DB81562E3 : C:\Program Files\Microsoft SQL Server\
                                       F07EA859E694B45439E22B819F70A40F : C:\Program Files\Microsoft SQL Server\
                                       3F9A28055EEA9364B97A1C6916AB3713 : C:\Program Files\Microsoft SQL Server\
#>
function Get-FirstPathValueFromRegistryPath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $registryProperty = Get-Item -Path $Path -ErrorAction 'SilentlyContinue'

    if ($registryProperty)
    {
        $registryProperty = $registryProperty | Select-Object -ExpandProperty Property | Select-Object -First 1

        if ($registryProperty)
        {
            $registryPropertyValue = (Get-ItemProperty -Path $Path -Name $registryProperty).$registryProperty.TrimEnd('\')
        }
    }

    return $registryPropertyValue
}

<#
    .SYNOPSIS
        Returns the decimal representation of an IP Addresses.

    .PARAMETER IPAddress
        The IP Address to be converted.
#>
function ConvertTo-Decimal
{
    [CmdletBinding()]
    [OutputType([System.UInt32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Net.IPAddress]
        $IPAddress
    )

    $i = 3
    $decimalIpAddress = 0
    $IPAddress.GetAddressBytes() | ForEach-Object {
        $decimalIpAddress += $_ * [Math]::Pow(256,$i)
        $i--
    }

    return [System.UInt32] $decimalIpAddress
}

<#
    .SYNOPSIS
        Determines whether an IP Address is valid for a given network / subnet.

    .PARAMETER IPAddress
        IP Address to be checked.

    .PARAMETER NetworkID
        IP Address of the network identifier.

    .PARAMETER SubnetMask
        Subnet mask of the network to be checked.
#>
function Test-IPAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Net.IPAddress]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.Net.IPAddress]
        $NetworkID,

        [Parameter(Mandatory = $true)]
        [System.Net.IPAddress]
        $SubnetMask
    )

    # Convert all values to decimal
    $IPAddressDecimal = ConvertTo-Decimal -IPAddress $IPAddress
    $NetworkDecimal = ConvertTo-Decimal -IPAddress $NetworkID
    $SubnetDecimal = ConvertTo-Decimal -IPAddress $SubnetMask

    # Determine whether the IP Address is valid for this network / subnet
    return (($IPAddressDecimal -band $SubnetDecimal) -eq ($NetworkDecimal -band $SubnetDecimal))
}

<#
    .SYNOPSIS
        Builds service account parameters for setup.

    .PARAMETER ServiceAccount
        Credential for the service account.

    .PARAMETER ServiceType
        Type of service account.
#>
function Get-ServiceAccountParameters
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter(Mandatory = $true)]
        [ValidateSet('SQL','AGT','IS','RS','AS','FT')]
        [System.String]
        $ServiceType
    )

    # Get the service account properties
    $accountParameters = Get-ServiceAccount -ServiceAccount $ServiceAccount
    $parameters = @{}

    # Assign the service type the account
    $parameters = @{
        "$($ServiceType)SVCACCOUNT" = $accountParameters.UserName
    }

    # Check to see if password is null
    if (![string]::IsNullOrEmpty($accountParameters.Password))
    {
        # Add the password to the hashtable
        $parameters.Add("$($ServiceType)SVCPASSWORD", $accountParameters.Password)
    }


    return $parameters
}

<#
    .SYNOPSIS
        Converts the start mode property returned by a Win32_Service CIM object to the resource properties *StartupType equivalent

    .PARAMETER StartMode
        The StartMode to convert.
#>
function ConvertTo-StartupType
{
    param
    (
        [Parameter()]
        [System.String]
        $StartMode
    )

    if ($StartMode -eq 'Auto')
    {
        $StartMode = 'Automatic'
    }

    return $StartMode
}

<#
    .SYNOPSIS
        Returns an array of installed shared features.

    .PARAMETER SqlServerMajorVersion
        Specifies the major version of SQL Server, e.g. 14 for SQL Server 2017.

#>
function Get-InstalledSharedFeatures
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $SqlServerMajorVersion
    )

    $sharedFeatures = @()

    $configurationStateRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($SqlServerMajorVersion)0\ConfigurationState"

    # Check if Data Quality Client sub component is configured
    Write-Verbose -Message ($script:localizedData.EvaluateDataQualityClientFeature -f $configurationStateRegistryPath)

    $isDQCInstalled = (Get-ItemProperty -Path $configurationStateRegistryPath -ErrorAction SilentlyContinue).SQL_DQ_CLIENT_Full
    if ($isDQCInstalled -eq 1)
    {
        Write-Verbose -Message $script:localizedData.DataQualityClientFeatureFound
        $sharedFeatures += 'DQC'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.DataQualityClientFeatureNotFound
    }

    # Check if Documentation Components "BOL" is configured
    Write-Verbose -Message ($script:localizedData.EvaluateDocumentationComponentsFeature -f $configurationStateRegistryPath)

    $isBOLInstalled = (Get-ItemProperty -Path $configurationStateRegistryPath -ErrorAction SilentlyContinue).SQL_BOL_Components
    if ($isBOLInstalled -eq 1)
    {
        Write-Verbose -Message $script:localizedData.DocumentationComponentsFeatureFound
        $sharedFeatures += 'BOL'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.DocumentationComponentsFeatureNotFound
    }

    # Check if Client Tools Connectivity (and SQL Client Connectivity SDK) "CONN" is configured
    Write-Verbose -Message ($script:localizedData.EvaluateDocumentationComponentsFeature -f $configurationStateRegistryPath)

    $isConnInstalled = (Get-ItemProperty -Path $configurationStateRegistryPath -ErrorAction SilentlyContinue).Connectivity_Full
    if ($isConnInstalled -eq 1)
    {
        Write-Verbose -Message $script:localizedData.ClientConnectivityToolsFeatureFound
        $sharedFeatures += 'CONN'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.ClientConnectivityToolsFeatureNotFound
    }

    # Check if Client Tools Backwards Compatibility "BC" is configured
    Write-Verbose -Message ($script:localizedData.EvaluateDocumentationComponentsFeature -f $configurationStateRegistryPath)

    $isBcInstalled = (Get-ItemProperty -Path $configurationStateRegistryPath -ErrorAction SilentlyContinue).Tools_Legacy_Full
    if ($isBcInstalled -eq 1)
    {
        Write-Verbose -Message $script:localizedData.ClientConnectivityBackwardsCompatibilityToolsFeatureFound
        $sharedFeatures += 'BC'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.ClientConnectivityBackwardsCompatibilityToolsFeatureNotFound
    }

    # Check if Client Tools SDK "SDK" is configured
    Write-Verbose -Message ($script:localizedData.EvaluateDocumentationComponentsFeature -f $configurationStateRegistryPath)

    $isSdkInstalled = (Get-ItemProperty -Path $configurationStateRegistryPath -ErrorAction SilentlyContinue).SDK_Full
    if ($isSdkInstalled -eq 1)
    {
        Write-Verbose -Message $script:localizedData.ClientToolsSdkFeatureFound
        $sharedFeatures += 'SDK'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.ClientToolsSdkFeatureNotFound
    }

    # Check if MDS sub component is configured for this server
    Write-Verbose -Message ($script:localizedData.EvaluateMasterDataServicesFeature -f $configurationStateRegistryPath)

    $isMDSInstalled = (Get-ItemProperty -Path $configurationStateRegistryPath -ErrorAction SilentlyContinue).MDSCoreFeature
    if ($isMDSInstalled -eq 1)
    {
        Write-Verbose -Message $script:localizedData.MasterDataServicesFeatureFound
        $sharedFeatures += 'MDS'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.MasterDataServicesFeatureNotFound
    }

    return $sharedFeatures
}

<#
    .SYNOPSIS
        Test if the specific feature flag should be enabled.

    .PARAMETER FeatureFlag
        An array of feature flags that should be compared against.

    .PARAMETER TestFlag
        The feature flag that is being check if it should be enabled.
#>
function Test-FeatureFlag
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String[]]
        $FeatureFlag,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFlag
    )

    $flagEnabled = $FeatureFlag -and ($FeatureFlag -and $FeatureFlag.Contains($TestFlag))

    return $flagEnabled
}

<#
    .SYNOPSIS
        Get current properties for the feature SQLENGINE.

    .PARAMETER ServerName
        Specifies the server name where the database engine instance is located.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .PARAMETER DatabaseServiceName
        Specifies the name of the SQL Server Database Engine service.

    .PARAMETER AgentServiceName
        Specifies the name of the  SQL Server Agent service.

    .OUTPUTS
        An hashtable with properties.
#>
function Get-SqlEngineProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $serviceNames = Get-ServiceNamesForInstance -InstanceName $InstanceName

    #$sqlServiceCimInstance = Get-CimInstance -ClassName 'Win32_Service' -Filter ("Name = '{0}'" -f $serviceNames.DatabaseService)
    $databaseEngineService = Get-ServiceProperties -ServiceName $serviceNames.DatabaseService
    #$agentServiceCimInstance = Get-CimInstance -ClassName 'Win32_Service' -Filter ("Name = '{0}'" -f $serviceNames.AgentService)
    $sqlAgentService = Get-ServiceProperties -ServiceName $serviceNames.AgentService

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    $sqlCollation = $sqlServerObject.Collation
    $isClustered = $sqlServerObject.IsClustered
    $installSQLDataDirectory = $sqlServerObject.InstallDataDirectory
    $sqlUserDatabaseDirectory = $sqlServerObject.DefaultFile
    $sqlUserDatabaseLogDirectory = $sqlServerObject.DefaultLog
    $sqlBackupDirectory = $sqlServerObject.BackupDirectory

    if ($sqlServerObject.LoginMode -eq 'Mixed')
    {
        $securityMode = 'SQL'
    }
    else
    {
        $securityMode = 'Windows'
    }

    return @{
        SQLSvcAccountUsername = $databaseEngineService.UserName
        AgtSvcAccountUsername = $sqlAgentService.UserName
        SqlSvcStartupType = $databaseEngineService.StartupType
        AgtSvcStartupType = $sqlAgentService.StartupType
        SQLCollation = $sqlCollation
        IsClustered = $isClustered
        InstallSQLDataDir = $installSQLDataDirectory
        SQLUserDBDir = $sqlUserDatabaseDirectory
        SQLUserDBLogDir = $sqlUserDatabaseLogDirectory
        SQLBackupDir = $sqlBackupDirectory
        SecurityMode = $securityMode
    }
}

<#
    .SYNOPSIS
        Returns the SQL Server full instance ID.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .OUTPUTS
        A string containing the full instance ID, e.g. 'MSSQL12.INSTANCE'.
#>
function Get-FullInstanceId
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $getRegistryPropertyValueParameters = @{
        Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
        Name = $InstanceName
    }

    return (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
}

<#
    .SYNOPSIS
        Evaluates if the feature Replication is installed.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .OUTPUTS
        A boolean value. $true if it is installed, $false if is it not.
#>
function Test-IsReplicationFeatureInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $isReplicationInstalled = $false

    $fullInstanceId = Get-FullInstanceId -InstanceName $InstanceName

    # Check if Replication sub component is configured for this instance
    $replicationRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$fullInstanceId\ConfigurationState"

    $replicationInstallValue = Get-RegistryPropertyValue -Path $replicationRegistryPath -Name 'SQL_Replication_Core_Inst'

    if ($replicationInstallValue -eq 1)
    {
        $isReplicationInstalled = $true
    }

    return $isReplicationInstalled
}

<#
    .SYNOPSIS
        Evaluates if the Data Quality Services sub component is installed.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .PARAMETER SqlServerMajorVersion
        Specifies the major version of SQL Server, e.g. 14 for SQL Server 2017.

    .OUTPUTS
        A boolean value. $true if it is installed, $false if is it not.
#>
function Test-IsDQComponentInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $SqlServerMajorVersion
    )

    $isDQInstalled = $false

    $dataQualityServicesRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($SqlServerMajorVersion)0\DQ\*"

    # If the path exist then we assume the feature is installed.
    $dataQualityServiceRegistryValues = Get-ItemProperty -Path $dataQualityServicesRegistryPath -ErrorAction 'SilentlyContinue'

    if ($dataQualityServiceRegistryValues)
    {
        $isDQInstalled = $true
    }

    return $isDQInstalled
}

<#
    .SYNOPSIS
        Returns the SQL Server instance program path.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .OUTPUTS
        A string containing the path to the instance program folder, e.g.
        'C:\Program Files\Microsoft SQL Server'.
#>
function Get-InstanceProgramPath
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $fullInstanceId = Get-FullInstanceId -InstanceName $InstanceName

    # Check if Replication sub component is configured for this instance
    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\Setup' -f $fullInstanceId

    $instanceDirectory = Get-RegistryPropertyValue -Path $registryPath -Name 'SqlProgramDir'

    return $instanceDirectory.Trim('\')
}

<#
    .SYNOPSIS
       Get current properties for the TempDB in the database engine.

    .PARAMETER ServerName
        Specifies the server name where the database engine instance is located.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .OUTPUTS
        An hashtable with properties.
#>
function Get-TempDbProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    $databaseTempDb = $sqlServerObject.Databases['tempdb']

    # Tempdb data primary path.
    $sqlTempDBPrimaryFilePath = $databaseTempDb.PrimaryFilePath

    $primaryFileGroup = $databaseTempDb.FileGroups['PRIMARY']

    # Tempdb data files count.
    $sqlTempdbFileCount = $primaryFileGroup.Files.Count

    # Tempdb data files size.
    $sqlTempdbFileSize = (
        $primaryFileGroup.Files.Size |
        Measure-Object -Average
    ).Average / 1KB

    # Tempdb data files average growth in KB.
    $sqlTempdbAverageFileGrowthKB = (
        $primaryFileGroup.Files |
            Where-Object -FilterScript {
                $_.GrowthType -eq 'KB'
            } |
            Select-Object -ExpandProperty 'Growth' |
            Measure-Object -Average
    ).Average

    # Tempdb data files average growth in Percent.
    $sqlTempdbFileGrowthPercent = (
        $primaryFileGroup.Files |
            Where-Object -FilterScript {
                $_.GrowthType -eq 'Percent'
            } |
            Select-Object -ExpandProperty 'Growth' |
            Measure-Object -Average
    ).Average

    $sqlTempdbFileGrowthMB = 0

    # Convert the KB value into MB.
    if ($sqlTempdbAverageFileGrowthKB)
    {
        $sqlTempdbFileGrowthMB = $sqlTempdbAverageFileGrowthKB / 1KB
    }

    $sqlTempdbFileGrowth = $sqlTempdbFileGrowthMB + $sqlTempdbFileGrowthPercent

    $tempdbLogFiles = $databaseTempDb.LogFiles

    # Tempdb log file size.
    $sqlTempdbLogFileSize = ($tempdbLogFiles.Size | Measure-Object -Average).Average / 1KB

    # Tempdb log file average growth in KB.
    $sqlTempdbAverageLogFileGrowthKB = (
        $tempdbLogFiles |
            Where-Object -FilterScript {
                $_.GrowthType -eq 'KB'
            } |
            Select-Object -ExpandProperty 'Growth' |
            Measure-Object -Average
    ).Average

    # Tempdb log file average growth in Percent.
    $sqlTempdbLogFileGrowthPercent = (
        $tempdbLogFiles |
            Where-Object -FilterScript {
                $_.GrowthType -eq 'Percent'
            } |
            Select-Object -ExpandProperty 'Growth' |
            Measure-Object -Average
    ).Average

    # Convert the KB value into MB.
    if ($sqlTempdbAverageLogFileGrowthKB)
    {
        $sqlTempdbLogFileGrowthMB = $sqlTempdbAverageLogFileGrowthKB / 1KB
    }
    else
    {
        $sqlTempdbLogFileGrowthMB = 0
    }

    # The sum of the average growth in KB and average growth in Percent.
    $sqlTempdbLogFileGrowth = $sqlTempdbLogFileGrowthMB + $sqlTempdbLogFileGrowthPercent

    return @{
        SQLTempDBDir = $sqlTempDBPrimaryFilePath
        SqlTempdbFileCount = $sqlTempdbFileCount
        SqlTempdbFileSize = $sqlTempdbFileSize
        SqlTempdbFileGrowth = $sqlTempdbFileGrowth
        SqlTempdbLogFileSize = $sqlTempdbLogFileSize
        SqlTempdbLogFileGrowth = $sqlTempdbLogFileGrowth
    }
}

<#
    .SYNOPSIS
       Get the correct service named based on the instance name.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .PARAMETER SqlServerMajorVersion
        Specifies the major version of SQL Server, e.g. 14 for SQL Server 2017.
        If this is not passed the service name for Integration Services cannot
        be determined and will return $null.

    .OUTPUTS
        An hashtable with the service names.
#>
function Get-ServiceNamesForInstance
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Int32]
        $SqlServerMajorVersion
    )

    $serviceNames = @{}

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $serviceNames.DatabaseService = 'MSSQLSERVER'
        $serviceNames.AgentService = 'SQLSERVERAGENT'
        $serviceNames.FullTextService = 'MSSQLFDLauncher'
        $serviceNames.ReportService = 'ReportServer'
        $serviceNames.AnalysisService = 'MSSQLServerOLAPService'
    }
    else
    {
        $serviceNames.DatabaseService = 'MSSQL${0}' -f $InstanceName
        $serviceNames.AgentService = 'SQLAgent${0}' -f $InstanceName
        $serviceNames.FullTextService = 'MSSQLFDLauncher${0}' -f $InstanceName
        $serviceNames.ReportService = 'ReportServer${0}' -f $InstanceName
        $serviceNames.AnalysisService = 'MSOLAP${0}' -f $InstanceName
    }

    if ($PSBoundParameters.ContainsKey('SqlServerMajorVersion'))
    {
        $serviceNames.IntegrationService = 'MsDtsServer{0}0' -f $SqlServerMajorVersion
    }
    else
    {
        $serviceNames.IntegrationService = $null
    }

    return $serviceNames
}

<#
    .SYNOPSIS
       Get members that are part of a SQL system role.

    .PARAMETER ServerName
        Specifies the server name where the database engine instance is located.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .PARAMETER RoleName
        Specifies the name of the role to get the members for.

    .OUTPUTS
        An hashtable with properties containing the current cluster values.
#>
function Get-SqlRoleMembers
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RoleName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    $membersOfSysAdminRole = @($sqlServerObject.Roles[$RoleName].EnumMemberNames())

    # Make sure to alway return an array of object even if there is only one value.
    return , $membersOfSysAdminRole
}

<#
    .SYNOPSIS
       Get current SQL Server cluster properties.

    .PARAMETER InstanceName
        Specifies the instance name. Use 'MSSQLSERVER' for the default instance.

    .OUTPUTS
        An hashtable with properties.
#>
function Get-SqlClusterProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $getCimInstanceParameters = @{
        Namespace = 'root/MSCluster'
        ClassName = 'MSCluster_Resource'
        Filter = "Type = 'SQL Server'"
    }

    $clusteredSqlInstance = Get-CimInstance @getCimInstanceParameters |
        Where-Object -FilterScript {
            $_.PrivateProperties.InstanceName -eq $InstanceName
        }

    if (-not $clusteredSqlInstance)
    {
        $errorMessage = $script:localizedData.FailoverClusterResourceNotFound -f $InstanceName
        New-ObjectNotFoundException -Message $errorMessage
    }

    Write-Verbose -Message $script:localizedData.FailoverClusterResourceFound

    $clusteredSqlGroup = $clusteredSqlInstance |
        Get-CimAssociatedInstance -ResultClassName 'MSCluster_ResourceGroup'

    $clusteredSqlNetworkName = $clusteredSqlGroup |
        Get-CimAssociatedInstance -ResultClassName 'MSCluster_Resource' |
        Where-Object -FilterScript {
            $_.Type -eq 'Network Name'
        }

    $clusteredSqlIPAddress = $clusteredSqlNetworkName |
        Get-CimAssociatedInstance -ResultClassName 'MSCluster_Resource' |
        Where-Object -FilterScript {
            $_.Type -eq 'IP Address'
        }

    return @{
        FailoverClusterNetworkName = $clusteredSqlNetworkName.PrivateProperties.DnsName
        FailoverClusterGroupName   = $clusteredSqlGroup.Name
        FailoverClusterIPAddress   = $clusteredSqlIPAddress.PrivateProperties.Address
    }
}

<#
    .SYNOPSIS
        Get current properties for a service. Returns the user name that starts
        the service, and the startup type.

    .PARAMETER ServiceName
        Specifies the service name.

    .OUTPUTS
        An hashtable with properties.
#>
function Get-ServiceProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceName
    )

    $cimInstance = Get-CimInstance -ClassName 'Win32_Service' -Filter ("Name = '{0}'" -f $ServiceName)

    return @{
        UserName    = $cimInstance.StartName
        StartupType = ConvertTo-StartupType -StartMode $cimInstance.StartMode
    }
}

<#
    .SYNOPSIS
        Evaluates if the SQL Server Management Studio for the specified SQL Server
        major version is installed.

    .PARAMETER SqlServerMajorVersion
        Specifies the major version of SQL Server, e.g. 14 for SQL Server 2017.

    .OUTPUTS
        A boolean value. $true if it is installed, $false if is it not.
#>
function Test-IsSsmsInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $SqlServerMajorVersion
    )

    $isInstalled = $false

    switch ($SqlServerMajorVersion)
    {
        10
        {
            <#
                Verify if SQL Server Management Studio 2008 or SQL Server Management
                Studio 2008 R2 (major version 10) is installed.
            #>
            $productIdentifyingNumber = '{72AB7E6F-BC24-481E-8C45-1AB5B3DD795D}'
        }

        11
        {
            # Verify if SQL Server Management Studio 2012 (major version 11) is installed.
            $productIdentifyingNumber = '{A7037EB2-F953-4B12-B843-195F4D988DA1}'
        }

        12
        {
            # Verify if SQL Server Management Studio 2012 (major version 11) is installed.
            $productIdentifyingNumber = '{75A54138-3B98-4705-92E4-F619825B121F}'
        }

        default
        {
            # If an unsupported version was passed, make sure the function returns $false.
            $productIdentifyingNumber = $null
        }
    }

    if ($productIdentifyingNumber)
    {
        $registryUninstallPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

        $registryObject = Get-ItemProperty -Path (
            Join-Path -Path $registryUninstallPath -ChildPath $productIdentifyingNumber
        ) -ErrorAction 'SilentlyContinue'

        if ($registryObject)
        {
            $isInstalled = $true
        }
    }

    return $isInstalled
}

<#
    .SYNOPSIS
        Evaluates if the SQL Server Management Studio Advanced for the specified
        SQL Server major version is installed.

    .PARAMETER SqlServerMajorVersion
        Specifies the major version of SQL Server, e.g. 14 for SQL Server 2017.

    .OUTPUTS
        A boolean value. $true if it is installed, $false if is it not.
#>
function Test-IsSsmsAdvancedInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $SqlServerMajorVersion
    )

    $isInstalled = $false

    switch ($SqlServerMajorVersion)
    {
        10
        {
            <#
                Evaluating if SQL Server Management Studio Advanced 2008 or
                SQL Server Management Studio Advanced 2008 R2 (major version 10)
                is installed.
            #>
            $productIdentifyingNumber = '{B5FE23CC-0151-4595-84C3-F1DE6F44FE9B}'
        }

        11
        {
            <#
                Evaluating if SQL Server Management Studio Advanced 2012 (major
                version 11) is installed.
            #>
            $productIdentifyingNumber = '{7842C220-6E9A-4D5A-AE70-0E138271F883}'
        }

        12
        {
            <#
                Evaluating if SQL Server Management Studio Advanced 2014 (major
                version 12) is installed.
            #>
            $productIdentifyingNumber = '{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}'
        }

        default
        {
            <#
                If an unsupported version was passed, make sure the function
                returns $false.
            #>
            $productIdentifyingNumber = $null
        }
    }

    if ($productIdentifyingNumber)
    {
        $registryUninstallPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

        $registryObject = Get-ItemProperty -Path (
            Join-Path -Path $registryUninstallPath -ChildPath $productIdentifyingNumber
        ) -ErrorAction 'SilentlyContinue'

        if ($registryObject)
        {
            $isInstalled = $true
        }
    }

    return $isInstalled
}

<#
    .SYNOPSIS
       Get current SQL Server shared paths for the instances.

    .OUTPUTS
        An hashtable with properties.
#>
function Get-SqlSharedPaths
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $SqlServerMajorVersion
    )

    $installSharedDir = $null
    $installSharedWOWDir = $null

    $registryInstallerComponentsPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components'

    switch ($SqlServerMajorVersion)
    {
        { $_ -in ('10','11','12','13','14') }
        {
            $registryKeySharedDir = 'FEE2E540D20152D4597229B6CFBC0A69'
            $registryKeySharedWOWDir = 'A79497A344129F64CA7D69C56F5DD8B4'
        }
    }

    if ($registryKeySharedDir)
    {
        $installSharedDir = Get-FirstPathValueFromRegistryPath -Path (Join-Path -Path $registryInstallerComponentsPath -ChildPath $registryKeySharedDir)
    }

    if ($registryKeySharedWOWDir)
    {
        $installSharedWOWDir = Get-FirstPathValueFromRegistryPath -Path (Join-Path -Path $registryInstallerComponentsPath -ChildPath $registryKeySharedWOWDir)
    }

    return @{
        InstallSharedDir = $installSharedDir
        InstallSharedWOWDir = $installSharedWOWDir
    }
}
