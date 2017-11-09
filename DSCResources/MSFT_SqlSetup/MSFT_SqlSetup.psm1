Import-Module -Name (Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'SqlServerDscHelper.psm1')

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlSetup'

<#
    .SYNOPSIS
        Returns the current state of the SQL Server features.

    .PARAMETER Action
        The action to be performed. Default value is 'Install'.
        Possible values are 'Install', 'InstallFailoverCluster', 'AddNode', 'PrepareFailoverCluster', and 'CompleteFailoverCluster'

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

    .PARAMETER FailoverClusterNetworkName
        Host name to be assigned to the clustered SQL Server instance
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateSet('Install','InstallFailoverCluster','AddNode','PrepareFailoverCluster','CompleteFailoverCluster')]
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
        [System.String]
        $FailoverClusterNetworkName
    )

    if ($Action -in @('CompleteFailoverCluster','InstallFailoverCluster','Addnode'))
    {
        $sqlHostName = $FailoverClusterNetworkName
    }
    else
    {
        $sqlHostName = $env:COMPUTERNAME
    }

    $InstanceName = $InstanceName.ToUpper()

    $SourcePath = [Environment]::ExpandEnvironmentVariables($SourcePath)

    if ($SourceCredential)
    {
        $newSmbMappingParameters = @{
            RemotePath = $SourcePath
            UserName = "$($SourceCredential.GetNetworkCredential().Domain)\$($SourceCredential.GetNetworkCredential().UserName)"
            Password = $($SourceCredential.GetNetworkCredential().Password)
        }

        $null = New-SmbMapping @newSmbMappingParameters
    }

    $pathToSetupExecutable = Join-Path -Path $SourcePath -ChildPath 'setup.exe'

    Write-Verbose -Message ($script:localizedData.UsingPath -f $pathToSetupExecutable)

    $sqlVersion = Get-SqlMajorVersion -Path $pathToSetupExecutable

    if ($SourceCredential)
    {
        Remove-SmbMapping -RemotePath $SourcePath -Force
    }

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $databaseServiceName = 'MSSQLSERVER'
        $agentServiceName = 'SQLSERVERAGENT'
        $fullTextServiceName = 'MSSQLFDLauncher'
        $reportServiceName = 'ReportServer'
        $analysisServiceName = 'MSSQLServerOLAPService'
    }
    else
    {
        $databaseServiceName = "MSSQL`$$InstanceName"
        $agentServiceName = "SQLAgent`$$InstanceName"
        $fullTextServiceName = "MSSQLFDLauncher`$$InstanceName"
        $reportServiceName = "ReportServer`$$InstanceName"
        $analysisServiceName = "MSOLAP`$$InstanceName"
    }

    $integrationServiceName = "MsDtsServer$($sqlVersion)0"

    $features = ''

    $services = Get-Service

    Write-Verbose -Message $script:localizedData.EvaluateDatabaseEngineFeature

    if ($services | Where-Object {$_.Name -eq $databaseServiceName})
    {
        Write-Verbose -Message $script:localizedData.DatabaseEngineFeatureFound

        $features += 'SQLENGINE,'

        $sqlServiceAccountUsername = (Get-CimInstance -ClassName Win32_Service -Filter "Name = '$databaseServiceName'").StartName
        $agentServiceAccountUsername = (Get-CimInstance -ClassName Win32_Service -Filter "Name = '$agentServiceName'").StartName

        $fullInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -Name $InstanceName).$InstanceName

        # Check if Replication sub component is configured for this instance
        $replicationRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$fullInstanceId\ConfigurationState"

        Write-Verbose -Message ($script:localizedData.EvaluateReplicationFeature -f $replicationRegistryPath)

        $isReplicationInstalled = (Get-ItemProperty -Path $replicationRegistryPath).SQL_Replication_Core_Inst
        if ($isReplicationInstalled -eq 1)
        {
            Write-Verbose -Message $script:localizedData.ReplicationFeatureFound
            $features += 'REPLICATION,'
        }
        else
        {
            Write-Verbose -Message $script:localizedData.ReplicationFeatureNotFound
        }

        # Check if Data Quality Client sub component is configured
        $dataQualityClientRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($sqlVersion)0\ConfigurationState"

        Write-Verbose -Message ($script:localizedData.EvaluateDataQualityClientFeature -f $dataQualityClientRegistryPath)

        $isDQCInstalled = (Get-ItemProperty -Path $dataQualityClientRegistryPath).SQL_DQ_CLIENT_Full
        if ($isDQCInstalled -eq 1)
        {
            Write-Verbose -Message $script:localizedData.DataQualityClientFeatureFound
            $features += 'DQC,'
        }
        else
        {
            Write-Verbose -Message $script:localizedData.DataQualityClientFeatureNotFound
        }

        # Check if Data Quality Services sub component is configured
        $dataQualityServicesRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($sqlVersion)0\DQ\*"

        Write-Verbose -Message ($script:localizedData.EvaluateDataQualityServicesFeature -f $dataQualityServicesRegistryPath)

        $isDQInstalled = (Get-ItemProperty -Path $dataQualityServicesRegistryPath -ErrorAction SilentlyContinue)
        if ($isDQInstalled)
        {
            Write-Verbose -Message $script:localizedData.DataQualityServicesFeatureFound
            $features += 'DQ,'
        }
        else
        {
            Write-Verbose -Message $script:localizedData.DataQualityServicesFeatureNotFound
        }

        $instanceId = $fullInstanceId.Split('.')[1]
        $instanceDirectory = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$fullInstanceId\Setup" -Name 'SqlProgramDir').SqlProgramDir.Trim("\")

        $databaseServer = Connect-SQL -SQLServer $sqlHostName -SQLInstanceName $InstanceName

        $sqlCollation = $databaseServer.Collation

        $sqlSystemAdminAccounts = @()
        foreach ($sqlUser in $databaseServer.Logins)
        {
            foreach ($sqlRole in $sqlUser.ListMembers())
            {
                if ($sqlRole -like 'sysadmin')
                {
                    $sqlSystemAdminAccounts += $sqlUser.Name
                }
            }
        }

        if ($databaseServer.LoginMode -eq 'Mixed')
        {
            $securityMode = 'SQL'
        }
        else
        {
            $securityMode = 'Windows'
        }

        $installSQLDataDirectory = $databaseServer.InstallDataDirectory
        $sqlUserDatabaseDirectory = $databaseServer.DefaultFile
        $sqlUserDatabaseLogDirectory = $databaseServer.DefaultLog
        $sqlBackupDirectory = $databaseServer.BackupDirectory

        if ($databaseServer.IsClustered)
        {
            Write-Verbose -Message $script:localizedData.ClusterInstanceFound

            $clusteredSqlInstance = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Resource -Filter "Type = 'SQL Server'" |
                Where-Object { $_.PrivateProperties.InstanceName -eq $InstanceName }

            if (!$clusteredSqlInstance)
            {
                $errorMessage = $script:localizedData.FailoverClusterResourceNotFound -f $InstanceName
                New-ObjectNotFoundException -Message $errorMessage
            }

            Write-Verbose -Message $script:localizedData.FailoverClusterResourceFound

            $clusteredSqlGroup = $clusteredSqlInstance | Get-CimAssociatedInstance -ResultClassName MSCluster_ResourceGroup
            $clusteredSqlNetworkName = $clusteredSqlGroup | Get-CimAssociatedInstance -ResultClassName MSCluster_Resource |
                Where-Object { $_.Type -eq "Network Name" }

            $clusteredSqlIPAddress = ($clusteredSqlNetworkName | Get-CimAssociatedInstance -ResultClassName MSCluster_Resource |
                Where-Object { $_.Type -eq "IP Address" }).PrivateProperties.Address

            # Extract the required values
            $clusteredSqlGroupName = $clusteredSqlGroup.Name
            $clusteredSqlHostname = $clusteredSqlNetworkName.PrivateProperties.DnsName
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

    if ($services | Where-Object {$_.Name -eq $fullTextServiceName})
    {
        Write-Verbose -Message $script:localizedData.FullTextFeatureFound

        $features += 'FULLTEXT,'
        $fullTextServiceAccountUsername = (Get-CimInstance -ClassName Win32_Service -Filter "Name = '$fullTextServiceName'").StartName
    }
    else
    {
        Write-Verbose -Message $script:localizedData.FullTextFeatureNotFound
    }

    Write-Verbose -Message $script:localizedData.EvaluateReportingServicesFeature

    if ($services | Where-Object {$_.Name -eq $reportServiceName})
    {
        Write-Verbose -Message $script:localizedData.ReportingServicesFeatureFound

        $features += 'RS,'
        $reportingServiceAccountUsername = (Get-CimInstance -ClassName Win32_Service -Filter "Name = '$reportServiceName'").StartName
    }
    else
    {
        Write-Verbose -Message $script:localizedData.ReportingServicesFeatureNotFound
    }

    Write-Verbose -Message $script:localizedData.EvaluateAnalysisServicesFeature

    if ($services | Where-Object {$_.Name -eq $analysisServiceName})
    {
        Write-Verbose -Message $script:localizedData.AnalysisServicesFeatureFound

        $features += 'AS,'
        $analysisServiceAccountUsername = (Get-CimInstance -ClassName Win32_Service -Filter "Name = '$analysisServiceName'").StartName

        $analysisServer = Connect-SQLAnalysis -SQLServer $sqlHostName -SQLInstanceName $InstanceName

        $analysisCollation = $analysisServer.ServerProperties['CollationName'].Value
        $analysisDataDirectory = $analysisServer.ServerProperties['DataDir'].Value
        $analysisTempDirectory = $analysisServer.ServerProperties['TempDir'].Value
        $analysisLogDirectory = $analysisServer.ServerProperties['LogDir'].Value
        $analysisBackupDirectory = $analysisServer.ServerProperties['BackupDir'].Value

        $analysisSystemAdminAccounts = [System.String[]] $analysisServer.Roles['Administrators'].Members.Name

        $analysisConfigDirectory = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$analysisServiceName" -Name 'ImagePath').ImagePath.Replace(' -s ',',').Split(',')[1].Trim('"')
    }
    else
    {
        Write-Verbose -Message $script:localizedData.AnalysisServicesFeatureNotFound
    }

    Write-Verbose -Message $script:localizedData.EvaluateIntegrationServicesFeature

    if ($services | Where-Object {$_.Name -eq $integrationServiceName})
    {
        Write-Verbose -Message $script:localizedData.IntegrationServicesFeatureFound

        $features += 'IS,'
        $integrationServiceAccountUsername = (Get-CimInstance -ClassName Win32_Service -Filter "Name = '$integrationServiceName'").StartName
    }
    else
    {
        Write-Verbose -Message $script:localizedData.IntegrationServicesFeatureNotFound
    }

    # Check if Documentation Components "BOL" is configured
    $documentationComponentsRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($sqlVersion)0\ConfigurationState"

    Write-Verbose -Message ($script:localizedData.EvaluateDocumentationComponentsFeature -f $documentationComponentsRegistryPath)

    $isBOLInstalled = (Get-ItemProperty -Path $documentationComponentsRegistryPath -ErrorAction SilentlyContinue).SQL_BOL_Components
    if ($isBOLInstalled -eq 1)
    {
        Write-Verbose -Message $script:localizedData.DocumentationComponentsFeatureFound
        $features += 'BOL,'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.DocumentationComponentsFeatureNotFound
    }

    $clientComponentsFullRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($sqlVersion)0\Tools\Setup\Client_Components_Full"
    $registryClientComponentsFullFeatureList = (Get-ItemProperty -Path $clientComponentsFullRegistryPath -ErrorAction SilentlyContinue).FeatureList

    Write-Verbose -Message ($script:localizedData.EvaluateClientConnectivityToolsFeature -f $clientComponentsFullRegistryPath)

    if ($registryClientComponentsFullFeatureList -like '*Connectivity_FNS=3*')
    {
        Write-Verbose -Message $script:localizedData.ClientConnectivityToolsFeatureFound
        $features += 'CONN,'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.ClientConnectivityToolsFeatureNotFound
    }

    Write-Verbose -Message ($script:localizedData.EvaluateClientConnectivityBackwardsCompatibilityToolsFeature -f $clientComponentsFullRegistryPath)
    if ($registryClientComponentsFullFeatureList -like '*Tools_Legacy_FNS=3*')
    {
        Write-Verbose -Message $script:localizedData.ClientConnectivityBackwardsCompatibilityToolsFeatureFound
        $features += 'BC,'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.ClientConnectivityBackwardsCompatibilityToolsFeatureNotFound
    }

    Write-Verbose -Message ($script:localizedData.EvaluateClientToolsSdkFeature -f $clientComponentsFullRegistryPath)
    if (($registryClientComponentsFullFeatureList -like '*SDK_Full=3*') -and ($registryClientComponentsFullFeatureList -like '*SDK_FNS=3*'))
    {
        Write-Verbose -Message $script:localizedData.ClientToolsSdkFeatureFound
        $features += 'SDK,'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.ClientToolsSdkFeatureNotFound
    }

    # Check if MDS sub component is configured for this server
    $masterDataServicesFullRegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($sqlVersion)0\ConfigurationState"
    Write-Verbose -Message ($script:localizedData.EvaluateMasterDataServicesFeature -f $masterDataServicesFullRegistryPath)
    $isMDSInstalled = (Get-ItemProperty -Path $masterDataServicesFullRegistryPath -ErrorAction SilentlyContinue).MDSCoreFeature
    if ($isMDSInstalled -eq 1)
    {
        Write-Verbose -Message $script:localizedData.MasterDataServicesFeatureFound
        $features += 'MDS,'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.MasterDataServicesFeatureNotFound
    }

    $registryUninstallPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

    # Verify if SQL Server Management Studio 2008 or SQL Server Management Studio 2008 R2 (major version 10) is installed
    $installedProductSqlServerManagementStudio2008R2 = Get-ItemProperty -Path (
        Join-Path -Path $registryUninstallPath -ChildPath '{72AB7E6F-BC24-481E-8C45-1AB5B3DD795D}'
    ) -ErrorAction SilentlyContinue

    # Verify if SQL Server Management Studio 2012 (major version 11) is installed
    $installedProductSqlServerManagementStudio2012 = Get-ItemProperty -Path (
        Join-Path -Path $registryUninstallPath -ChildPath '{A7037EB2-F953-4B12-B843-195F4D988DA1}'
    ) -ErrorAction SilentlyContinue

    # Verify if SQL Server Management Studio 2014 (major version 12) is installed
    $installedProductSqlServerManagementStudio2014 = Get-ItemProperty -Path (
        Join-Path -Path $registryUninstallPath -ChildPath '{75A54138-3B98-4705-92E4-F619825B121F}'
    ) -ErrorAction SilentlyContinue

    if (
        ($sqlVersion -eq 10 -and $installedProductSqlServerManagementStudio2008R2) -or
        ($sqlVersion -eq 11 -and $installedProductSqlServerManagementStudio2012) -or
        ($sqlVersion -eq 12 -and $installedProductSqlServerManagementStudio2014)
        )
    {
        $features += 'SSMS,'
    }

    # Evaluating if SQL Server Management Studio Advanced 2008  or SQL Server Management Studio Advanced 2008 R2 (major version 10) is installed
    $installedProductSqlServerManagementStudioAdvanced2008R2 = Get-ItemProperty -Path (
        Join-Path -Path $registryUninstallPath -ChildPath '{B5FE23CC-0151-4595-84C3-F1DE6F44FE9B}'
    ) -ErrorAction SilentlyContinue

    # Evaluating if SQL Server Management Studio Advanced 2012 (major version 11) is installed
    $installedProductSqlServerManagementStudioAdvanced2012 = Get-ItemProperty -Path (
        Join-Path -Path $registryUninstallPath -ChildPath '{7842C220-6E9A-4D5A-AE70-0E138271F883}'
    ) -ErrorAction SilentlyContinue

    # Evaluating if SQL Server Management Studio Advanced 2014 (major version 12) is installed
    $installedProductSqlServerManagementStudioAdvanced2014 = Get-ItemProperty -Path (
        Join-Path -Path $registryUninstallPath -ChildPath '{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}'
    ) -ErrorAction SilentlyContinue

    if (
        ($sqlVersion -eq 10 -and $installedProductSqlServerManagementStudioAdvanced2008R2) -or
        ($sqlVersion -eq 11 -and $installedProductSqlServerManagementStudioAdvanced2012) -or
        ($sqlVersion -eq 12 -and $installedProductSqlServerManagementStudioAdvanced2014)
        )
    {
        $features += 'ADV_SSMS,'
    }

    $features = $features.Trim(',')
    if ($features)
    {
        $registryInstallerComponentsPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components'

        switch ($sqlVersion)
        {
            { $_ -in ('10','11','12','13','14') }
            {
                $registryKeySharedDir = 'FEE2E540D20152D4597229B6CFBC0A69'
                $registryKeySharedWOWDir = 'A79497A344129F64CA7D69C56F5DD8B4'
            }
        }

        if ($registryKeySharedDir)
        {
            $installSharedDir = Get-FirstItemPropertyValue -Path (Join-Path -Path $registryInstallerComponentsPath -ChildPath $registryKeySharedDir)
        }

        if ($registryKeySharedWOWDir)
        {
            $installSharedWOWDir = Get-FirstItemPropertyValue -Path (Join-Path -Path $registryInstallerComponentsPath -ChildPath $registryKeySharedWOWDir)
        }
    }

    return @{
        SourcePath = $SourcePath
        Features = $features
        InstanceName = $InstanceName
        InstanceID = $instanceID
        InstallSharedDir = $installSharedDir
        InstallSharedWOWDir = $installSharedWOWDir
        InstanceDir = $instanceDirectory
        SQLSvcAccountUsername = $sqlServiceAccountUsername
        AgtSvcAccountUsername = $agentServiceAccountUsername
        SQLCollation = $sqlCollation
        SQLSysAdminAccounts = $sqlSystemAdminAccounts
        SecurityMode = $securityMode
        InstallSQLDataDir = $installSQLDataDirectory
        SQLUserDBDir = $sqlUserDatabaseDirectory
        SQLUserDBLogDir = $sqlUserDatabaseLogDirectory
        SQLTempDBDir = $null
        SQLTempDBLogDir = $null
        SQLBackupDir = $sqlBackupDirectory
        FTSvcAccountUsername = $fullTextServiceAccountUsername
        RSSvcAccountUsername = $reportingServiceAccountUsername
        ASSvcAccountUsername = $analysisServiceAccountUsername
        ASCollation = $analysisCollation
        ASSysAdminAccounts = $analysisSystemAdminAccounts
        ASDataDir = $analysisDataDirectory
        ASLogDir = $analysisLogDirectory
        ASBackupDir = $analysisBackupDirectory
        ASTempDir = $analysisTempDirectory
        ASConfigDir = $analysisConfigDirectory
        ISSvcAccountUsername = $integrationServiceAccountUsername
        FailoverClusterGroupName = $clusteredSqlGroupName
        FailoverClusterNetworkName = $clusteredSqlHostname
        FailoverClusterIPAddress = $clusteredSqlIPAddress
    }
}

<#
    .SYNOPSIS
        Installs the SQL Server features to the node.

    .PARAMETER Action
        The action to be performed. Default value is 'Install'.
        Possible values are 'Install', 'InstallFailoverCluster', 'AddNode', 'PrepareFailoverCluster', and 'CompleteFailoverCluster'

    .PARAMETER SourcePath
        The path to the root of the source files for installation. I.e and UNC path to a shared resource. Environment variables can be used in the path.

    .PARAMETER SourceCredential
        Credentials used to access the path set in the parameter `SourcePath`. Using this parameter will trigger a copy
        of the installation media to a temp folder on the target node. Setup will then be started from the temp folder on the target node.
        For any subsequent calls to the resource, the parameter `SourceCredential` is used to evaluate what major version the file 'setup.exe'
        has in the path set, again, by the parameter `SourcePath`.
        If the path, that is assigned to parameter `SourcePath`, contains a leaf folder, for example '\\server\share\folder', then that leaf
        folder will be used as the name of the temporary folder. If the path, that is assigned to parameter `SourcePath`, does not have a
        leaf folder, for example '\\server\share', then a unique guid will be used as the name of the temporary folder.

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
        Security mode to apply to the SQL Server instance.

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

    .PARAMETER ISSvcAccount
       Service account for Integration Services service.

    .PARAMETER BrowserSvcStartupType
       Specifies the startup mode for SQL Server Browser service

    .PARAMETER FailoverClusterGroupName
        The name of the resource group to create for the clustered SQL Server instance. Default is 'SQL Server (InstanceName)'.

    .PARAMETER FailoverClusterIPAddress
        Array of IP Addresses to be assigned to the clustered SQL Server instance

    .PARAMETER FailoverClusterNetworkName
        Host name to be assigned to the clustered SQL Server instance

    .PARAMETER SetupProcessTimeout
        The timeout, in seconds, to wait for the setup process to finish. Default value is 7200 seconds (2 hours). If the setup process does not finish before this time, and error will be thrown.
#>
function Set-TargetResource
{
    # Suppressing this rule because $global:DSCMachineStatus is used to trigger a reboot, either by force or when there are pending changes.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Install','InstallFailoverCluster','AddNode','PrepareFailoverCluster','CompleteFailoverCluster')]
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
        [System.Management.Automation.PSCredential]
        $ISSvcAccount,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $BrowserSvcStartupType,

        [Parameter()]
        [System.String]
        $FailoverClusterGroupName = "SQL Server ($InstanceName)",

        [Parameter()]
        [System.String[]]
        $FailoverClusterIPAddress,

        [Parameter()]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter()]
        [System.UInt32]
        $SetupProcessTimeout = 7200
    )

    $getTargetResourceParameters = @{
        Action = $Action
        SourcePath = $SourcePath
        SourceCredential = $SourceCredential
        InstanceName = $InstanceName
        FailoverClusterNetworkName = $FailoverClusterNetworkName
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

    # Remove trailing slash ('\') from paths
    foreach ($parameterName in $parametersToEvaluateTrailingSlash)
    {
        if ($PSBoundParameters.ContainsKey($parameterName))
        {
            $parameterValue = Get-Variable -Name $parameterName -ValueOnly

            # Trim backslash, but only if the path contains a full path and not just a qualifier.
            if ($parameterValue -and $parameterValue -notmatch '^[a-zA-Z]:\\$')
            {
                Set-Variable -Name $parameterName -Value $parameterValue.TrimEnd('\')
            }

            # If the path only contains a qualifier but no backslash ('M:'), then a backslash is added ('M:\').
            if ($parameterValue -match '^[a-zA-Z]:$')
            {
                Set-Variable -Name $parameterName -Value "$parameterValue\"
            }
        }
    }

    $SourcePath = [Environment]::ExpandEnvironmentVariables($SourcePath)

    if ($SourceCredential)
    {
        $newSmbMappingParameters = @{
            RemotePath = $SourcePath
            UserName = "$($SourceCredential.GetNetworkCredential().Domain)\$($SourceCredential.GetNetworkCredential().UserName)"
            Password = $($SourceCredential.GetNetworkCredential().Password)
        }

        $null = New-SmbMapping @newSmbMappingParameters

        # Create a destination folder so the media files aren't written to the root of the Temp folder.
        $mediaDestinationFolder = Split-Path -Path $SourcePath -Leaf
        if (-not $mediaDestinationFolder )
        {
            $mediaDestinationFolder = New-Guid | Select-Object -ExpandProperty Guid
        }

        $mediaDestinationPath = Join-Path -Path (Get-TemporaryFolder) -ChildPath $mediaDestinationFolder

        Write-Verbose -Message ($script:localizedData.RobocopyIsCopying -f $SourcePath, $mediaDestinationPath)
        Copy-ItemWithRobocopy -Path $SourcePath -DestinationPath $mediaDestinationPath

        Remove-SmbMapping -RemotePath $SourcePath -Force

        $SourcePath = $mediaDestinationPath
    }

    $pathToSetupExecutable = Join-Path -Path $SourcePath -ChildPath 'setup.exe'

    Write-Verbose -Message ($script:localizedData.UsingPath -f $pathToSetupExecutable)

    $sqlVersion = Get-SqlMajorVersion -Path $pathToSetupExecutable

    # Determine features to install
    $featuresToInstall = ''
    foreach ($feature in $Features.Split(','))
    {
        # Given that all the returned features are uppercase, make sure that the feature to search for is also uppercase
        $feature = $feature.ToUpper();

        if (($sqlVersion -in ('13','14')) -and ($feature -in ('ADV_SSMS','SSMS')))
        {
            $errorMessage = $script:localizedData.FeatureNotSupported -f $feature
            New-InvalidOperationException -Message $errorMessage
        }

        if (-not ($getTargetResourceResult.Features.Contains($feature)))
        {
            $featuresToInstall += "$feature,"
        }
    }

    $Features = $featuresToInstall.Trim(',')

    # If SQL shared components already installed, clear InstallShared*Dir variables
    switch ($sqlVersion)
    {
        { $_ -in ('10','11','12','13','14') }
        {
            if((Get-Variable -Name 'InstallSharedDir' -ErrorAction SilentlyContinue) -and (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69' -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name 'InstallSharedDir' -Value ''
            }

            if((Get-Variable -Name 'InstallSharedWOWDir' -ErrorAction SilentlyContinue) -and (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4' -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name 'InstallSharedWOWDir' -Value ''
            }
        }
    }

    $setupArguments = @{}

    if ($Action -in @('PrepareFailoverCluster','CompleteFailoverCluster','InstallFailoverCluster','Addnode'))
    {
        # This was brought over from the old module. Should be removed (breaking change).
        $setupArguments += @{
            SkipRules = 'Cluster_VerifyForErrors'
        }
    }

    <#
        Set the failover cluster group name and failover cluster network name for this clustered instance
        if the action is either installing (InstallFailoverCluster) or completing (CompleteFailoverCluster) a cluster.
    #>
    if ($Action -in @('CompleteFailoverCluster','InstallFailoverCluster'))
    {
        $setupArguments += @{
            FailoverClusterNetworkName = $FailoverClusterNetworkName
            FailoverClusterGroup = $FailoverClusterGroupName
        }
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
        $setupArguments += @{ FailoverClusterDisks = ($failoverClusterDisks | Sort-Object) }
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
        $setupArguments += @{ FailoverClusterIPAddresses = $clusterIPAddresses }
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

    if ($Action -in @('Install','InstallFailoverCluster','PrepareFailoverCluster','CompleteFailoverCluster'))
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

        if($PSBoundParameters.ContainsKey('AgtSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $AgtSvcAccount -ServiceType 'AGT')
        }

        if ($SecurityMode -eq 'SQL')
        {
            $setupArguments += @{ SAPwd = $SAPwd.GetNetworkCredential().Password }
        }

        # Should not be passed when PrepareFailoverCluster is specified
        if ($Action -in @('Install','InstallFailoverCluster','CompleteFailoverCluster'))
        {
            if ($null -ne $PsDscContext.RunAsUser)
            {
                <#
                    Add the credentials from the parameter PsDscRunAsCredential, as the first
                    system administrator. The username is stored in $PsDscContext.RunAsUser.
                #>
                Write-Verbose -Message ($script:localizedData.AddingFirstSystemAdministratorSqlServer -f $($PsDscContext.RunAsUser))
                $setupArguments += @{ SQLSysAdminAccounts =  @($PsDscContext.RunAsUser) }
            }

            if ($PSBoundParameters.ContainsKey('SQLSysAdminAccounts'))
            {
                $setupArguments['SQLSysAdminAccounts'] += $SQLSysAdminAccounts
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

        if ($Action -in @('Install'))
        {
            $setupArguments += @{ AgtSvcStartupType = 'Automatic' }
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

        if ($PSBoundParameters.ContainsKey('ASSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $ASSvcAccount -ServiceType 'AS')
        }

        if ($Action -in ('Install','InstallFailoverCluster','CompleteFailoverCluster'))
        {
            if ($null -ne $PsDscContext.RunAsUser)
            {
                <#
                    Add the credentials from the parameter PsDscRunAsCredential, as the first
                    system administrator. The username is stored in $PsDscContext.RunAsUser.
                #>
                Write-Verbose -Message ($script:localizedData.AddingFirstSystemAdministratorAnalysisServices -f $($PsDscContext.RunAsUser))
                $setupArguments += @{ ASSysAdminAccounts =  @($PsDscContext.RunAsUser) }
            }

            if($PSBoundParameters.ContainsKey("ASSysAdminAccounts"))
            {
                $setupArguments['ASSysAdminAccounts'] += $ASSysAdminAccounts
            }
        }
    }

    if ($Features.Contains('IS'))
    {
        if ($PSBoundParameters.ContainsKey('ISSvcAccount'))
        {
            $setupArguments += (Get-ServiceAccountParameters -ServiceAccount $ISSvcAccount -ServiceType 'IS')
        }
    }

    # Automatically include any additional arguments
    foreach ($argument in $argumentVars)
    {
        if($argument -eq 'ProductKey')
        {
            $setupArguments += @{ 'PID' = (Get-Variable -Name $argument -ValueOnly) }
        }
        else
        {
            # If the argument contains a value, then add the argument to the setup argument list
            if (Get-Variable -Name $argument -ValueOnly)
            {
                $setupArguments += @{ $argument = (Get-Variable -Name $argument -ValueOnly) }
            }
        }
    }

    # Build the argument string to be passed to setup
    $arguments = ''
    foreach ($currentSetupArgument in $setupArguments.GetEnumerator())
    {
        if ($currentSetupArgument.Value -ne '')
        {
            # Arrays are handled specially
            if ($currentSetupArgument.Value -is [array])
            {
                # Sort and format the array
                $setupArgumentValue = ($currentSetupArgument.Value | Sort-Object | ForEach-Object { '"{0}"' -f $_ }) -join ' '
            }
            elseif ($currentSetupArgument.Value -is [Boolean])
            {
                $setupArgumentValue = @{ $true = 'True'; $false = 'False' }[$currentSetupArgument.Value]
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
                    $setupArgumentValue = '"{0}"' -f $currentSetupArgument.Value
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
        }
        else
        {
            $setupExitMessageSuccessful = ('{0} {1}' -f $setupExitMessage, ($script:localizedData.SetupSuccessful))

            Write-Verbose -Message $setupExitMessageSuccessful
        }

        if ($ForceReboot -or ($null -ne (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue)))
        {
            if (-not ($SuppressReboot))
            {
                Write-Verbose -Message $script:localizedData.Reboot

                $global:DSCMachineStatus = 1
            }
            else
            {
                Write-Verbose -Message $script:localizedData.SuppressReboot
            }
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
        Possible values are 'Install', 'InstallFailoverCluster', 'AddNode', 'PrepareFailoverCluster', and 'CompleteFailoverCluster'

    .PARAMETER SourcePath
        The path to the root of the source files for installation. I.e and UNC path to a shared resource. Environment variables can be used in the path.

    .PARAMETER SourceCredential
        Credentials used to access the path set in the parameter `SourcePath`. Using this parameter will trigger a copy
        of the installation media to a temp folder on the target node. Setup will then be started from the temp folder on the target node.
        For any subsequent calls to the resource, the parameter `SourceCredential` is used to evaluate what major version the file 'setup.exe'
        has in the path set, again, by the parameter `SourcePath`.
        If the path, that is assigned to parameter `SourcePath`, contains a leaf folder, for example '\\server\share\folder', then that leaf
        folder will be used as the name of the temporary folder. If the path, that is assigned to parameter `SourcePath`, does not have a
        leaf folder, for example '\\server\share', then a unique guid will be used as the name of the temporary folder.

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
        Security mode to apply to the SQL Server instance.

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

    .PARAMETER ISSvcAccount
       Service account for Integration Services service.

    .PARAMETER BrowserSvcStartupType
       Specifies the startup mode for SQL Server Browser service

    .PARAMETER FailoverClusterGroupName
        The name of the resource group to create for the clustered SQL Server instance. Default is 'SQL Server (InstanceName)'.

    .PARAMETER FailoverClusterIPAddress
        Array of IP Addresses to be assigned to the clustered SQL Server instance

    .PARAMETER FailoverClusterNetworkName
        Host name to be assigned to the clustered SQL Server instance

    .PARAMETER SetupProcessTimeout
        The timeout, in seconds, to wait for the setup process to finish. Default value is 7200 seconds (2 hours). If the setup process does not finish before this time, and error will be thrown.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Install','InstallFailoverCluster','AddNode','PrepareFailoverCluster','CompleteFailoverCluster')]
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
        [System.Management.Automation.PSCredential]
        $ISSvcAccount,

        [Parameter()]
        [System.String]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        $BrowserSvcStartupType,

        [Parameter(ParameterSetName = 'ClusterInstall')]
        [System.String]
        $FailoverClusterGroupName = "SQL Server ($InstanceName)",

        [Parameter(ParameterSetName = 'ClusterInstall')]
        [System.String[]]
        $FailoverClusterIPAddress,

        [Parameter(ParameterSetName = 'ClusterInstall')]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter()]
        [System.UInt32]
        $SetupProcessTimeout = 7200
    )

    $getTargetResourceParameters = @{
        Action = $Action
        SourcePath = $SourcePath
        SourceCredential = $SourceCredential
        InstanceName = $InstanceName
        FailoverClusterNetworkName = $FailoverClusterNetworkName
    }

    $boundParameters = $PSBoundParameters

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    Write-Verbose -Message ($script:localizedData.FeaturesFound -f $($getTargetResourceResult.Features))

    $result = $true

    if ($getTargetResourceResult.Features )
    {
        foreach ($feature in $Features.Split(","))
        {
            # Given that all the returned features are uppercase, make sure that the feature to search for is also uppercase
            $feature = $feature.ToUpper();

            if(!($getTargetResourceResult.Features.Contains($feature)))
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

            if ($getTargetResourceResult.$variableName -ne $boundParameters[$variableName]) {
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
        [String]
        $Path
    )

    (Get-Item -Path $Path).VersionInfo.ProductVersion.Split('.')[0]
}

<#
    .SYNOPSIS
        Returns the first item value in the registry location provided in the Path parameter.

    .PARAMETER Path
        String containing the path to the registry.
#>
function Get-FirstItemPropertyValue
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Path
    )

    $registryProperty = Get-Item -Path $Path -ErrorAction SilentlyContinue
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
        Copy folder structure using Robocopy. Every file and folder, including empty ones are copied.

    .PARAMETER Path
        Source path to be copied.

    .PARAMETER DestinationPath
        The path to the destination.
#>
function Copy-ItemWithRobocopy
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DestinationPath
    )

    $robocopyExecutable = Get-Command -Name "Robocopy.exe" -ErrorAction Stop

    $robocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
    $robocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
    $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'

    if ([System.Version]$robocopyExecutable.FileVersionInfo.ProductVersion -ge [System.Version]'6.3.9600.16384')
    {
        Write-Verbose -Message $script:localizedData.RobocopyUsingUnbufferedIo

        $robocopyArgumentUseUnbufferedIO = '/J'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.RobocopyNotUsingUnbufferedIo
    }

    $robocopyArgumentList = '{0} {1} {2} {3} {4} {5}' -f $Path,
                                                         $DestinationPath,
                                                         $robocopyArgumentCopySubDirectoriesIncludingEmpty,
                                                         $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                                                         $robocopyArgumentUseUnbufferedIO,
                                                         $robocopyArgumentSilent

    $robocopyStartProcessParameters = @{
        FilePath = $robocopyExecutable.Name
        ArgumentList = $robocopyArgumentList
    }

    Write-Verbose -Message  ($script:localizedData.RobocopyArguments -f $robocopyArgumentList )
    $robocopyProcess = Start-Process @robocopyStartProcessParameters -Wait -NoNewWindow -PassThru

    switch ($($robocopyProcess.ExitCode))
    {
        {$_ -in 8, 16}
        {
            $errorMessage = $script:localizedData.RobocopyErrorCopying -f $_
            New-InvalidOperationException -Message $errorMessage
        }

        {$_ -gt 7 }
        {
            $errorMessage = $script:localizedData.RobocopyFailuresCopying -f $_
            New-InvalidResultException -Message $errorMessage
        }

        1
        {
            Write-Verbose -Message  $script:localizedData.RobocopySuccessful
        }

        2
        {
            Write-Verbose -Message  $script:localizedData.RobocopyRemovedExtraFilesAtDestination
        }

        3
        {
            Write-Verbose -Message  $script:localizedData.RobocopySuccessfulAndRemovedExtraFilesAtDestination
        }

        {$_ -eq 0 -or $null -eq $_ }
        {
            Write-Verbose -Message  $script:localizedData.RobocopyAllFilesPresent
        }
    }
}

<#
    .SYNOPSIS
        Returns the path of the current user's temporary folder.
#>
function Get-TemporaryFolder
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param()

    return [IO.Path]::GetTempPath()
}

<#
    .SYNOPSIS
        Returns the decimal representation of an IP Addresses

    .PARAMETER IPAddress
        The IP Address to be converted
#>
function ConvertTo-Decimal
{
    [CmdletBinding()]
    [OutputType([System.UInt32])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Net.IPAddress]
        $IPAddress
    )

    $i = 3
    $DecimalIP = 0
    $IPAddress.GetAddressBytes() | ForEach-Object {
        $DecimalIP += $_ * [Math]::Pow(256,$i)
        $i--
    }

    return [UInt32]$DecimalIP
}

<#
    .SYNOPSIS
        Determines whether an IP Address is valid for a given network / subnet

    .PARAMETER IPAddress
        IP Address to be checked

    .PARAMETER NetworkID
        IP Address of the network identifier

    .PARAMETER SubnetMask
        Subnet mask of the network to be checked
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
        Builds service account parameters for setup

    .PARAMETER ServiceAccount
        Credential for the service account

    .PARAMETER ServiceType
        Type of service account
#>
function Get-ServiceAccountParameters
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $ServiceAccount,

        [Parameter(Mandatory = $true)]
        [ValidateSet('SQL','AGT','IS','RS','AS','FT')]
        [String]
        $ServiceType
    )

    $parameters = @{}

    switch -Regex ($ServiceAccount.UserName.ToUpper())
    {
        '^(?:NT ?AUTHORITY\\)?(SYSTEM|LOCALSERVICE|LOCAL SERVICE|NETWORKSERVICE|NETWORK SERVICE)$'
        {
            $parameters = @{
                "$($ServiceType)SVCACCOUNT" = "NT AUTHORITY\$($Matches[1])"
            }
        }

        '^(?:NT SERVICE\\)(.*)$'
        {
            $parameters = @{
                "$($ServiceType)SVCACCOUNT" = "NT SERVICE\$($Matches[1])"
            }
        }

        '.*\$'
        {
            $parameters = @{
                "$($ServiceType)SVCACCOUNT" = $ServiceAccount.UserName
            }
        }

        default
        {
            $parameters = @{
                "$($ServiceType)SVCACCOUNT" = $ServiceAccount.UserName
                "$($ServiceType)SVCPASSWORD" = $ServiceAccount.GetNetworkCredential().Password
            }
        }
    }

    return $parameters
}

<#
    .SYNOPSIS
        Starts the SQL setup process-

    .PARAMETER FilePath
        String containing the path to setup.exe.

    .PARAMETER ArgumentList
        The arguments that should be passed to setup.exe.

    .PARAMETER Timeout
        The timeout in seconds to wait for the process to finish.
#>
function Start-SqlSetupProcess
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter()]
        [System.String]
        $ArgumentList,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Timeout
    )

    $startProcessParameters = @{
        FilePath = $FilePath
        ArgumentList = $ArgumentList
    }

    $sqlSetupProcess = Start-Process @startProcessParameters -PassThru -NoNewWindow -ErrorAction Stop

    Write-Verbose -Message ($script:localizedData.StartSetupProcess -f $sqlSetupProcess.Id, $startProcessParameters.FilePath, $Timeout)

    Wait-Process -InputObject $sqlSetupProcess -Timeout $Timeout -ErrorAction Stop

    return $sqlSetupProcess.ExitCode
}

Export-ModuleMember -Function *-TargetResource
