# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerSetup'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        # Testing each supported SQL Server version
        $testProductVersion = @(
            13, # SQL Server 2016
            12, # SQL Server 2014
            11, # SQL Server 2012
            10  # SQL Server 2008 and 2008 R2
        )

        $mockSqlDatabaseEngineName = 'MSSQL'
        $mockSqlAgentName = 'SQLAgent'
        $mockSqlFullTextName = 'MSSQLFDLauncher'
        $mockSqlReportingName = 'ReportServer'
        $mockSqlIntegrationName = 'MsDtsServer{0}0' # {0} will be replaced by SQL major version in runtime
        $mockSqlAnalysisName = 'MSOLAP'

        $mockSqlCollation = 'Finnish_Swedish_CI_AS'
        $mockSqlLoginMode = 'Integrated'

        $mockSqlSharedDirectory = 'C:\Program Files\Microsoft SQL Server'
        $mockSqlSharedWowDirectory = 'C:\Program Files (x86)\Microsoft SQL Server'
        $mockSqlProgramDirectory = 'C:\Program Files\Microsoft SQL Server'
        $mockSqlSystemAdministrator = 'COMPANY\Stacy'

        $mockSqlAnalysisCollation = 'Finnish_Swedish_CI_AS'
        $mockSqlAnalysisAdmins = @('COMPANY\Stacy','COMPANY\SSAS Administrators')
        $mockSqlAnalysisDataDirectory = 'C:\Program Files\Microsoft SQL Server\OLAP\Data'
        $mockSqlAnalysisTempDirectory= 'C:\Program Files\Microsoft SQL Server\OLAP\Temp'
        $mockSqlAnalysisLogDirectory = 'C:\Program Files\Microsoft SQL Server\OLAP\Log'
        $mockSqlAnalysisBackupDirectory = 'C:\Program Files\Microsoft SQL Server\OLAP\Backup'
        $mockSqlAnalysisConfigDirectory = 'C:\Program Files\Microsoft SQL Server\OLAP\Config'

        $mockDefaultInstance_InstanceName = 'MSSQLSERVER'
        $mockDefaultInstance_DatabaseServiceName = $mockDefaultInstance_InstanceName
        $mockDefaultInstance_AgentServiceName = 'SQLSERVERAGENT'
        $mockDefaultInstance_FullTextServiceName = $mockSqlFullTextName
        $mockDefaultInstance_ReportingServiceName = $mockSqlReportingName
        $mockDefaultInstance_IntegrationServiceName = $mockSqlIntegrationName
        $mockDefaultInstance_AnalysisServiceName = 'MSSQLServerOLAPService'

        $mockDefaultInstance_FailoverClusterNetworkName = 'TestDefaultCluster'
        $mockDefaultInstance_FailoverClusterIPAddress = '10.0.0.10'
        $mockDefaultInstance_FailoverClusterIPAddress_SecondSite = '10.0.10.100'
        $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
        $mockDefaultInstance_FailoverClusterIPAddressParameter_MultiSite = 'IPv4;10.0.0.10;SiteA_Prod;255.255.255.0; IPv4;10.0.10.100;SiteB_Prod;255.255.255.0'
        $mockDefaultInstance_FailoverClusterGroupName = "SQL Server ($mockDefaultInstance_InstanceName)"

        $mockNamedInstance_InstanceName = 'TEST'
        $mockNamedInstance_DatabaseServiceName = "$($mockSqlDatabaseEngineName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_AgentServiceName = "$($mockSqlAgentName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_FullTextServiceName = "$($mockSqlFullTextName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_ReportingServiceName = "$($mockSqlReportingName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_IntegrationServiceName = $mockSqlIntegrationName
        $mockNamedInstance_AnalysisServiceName = "$($mockSqlAnalysisName)`$$($mockNamedInstance_InstanceName)"

        $mockNamedInstance_FailoverClusterNetworkName = 'TestDefaultCluster'
        $mockNamedInstance_FailoverClusterIPAddress = '10.0.0.20'
        $mockNamedInstance_FailoverClusterGroupName = "SQL Server ($mockNamedInstance_InstanceName)"

        $mockmockSetupCredentialUserName = "COMPANY\sqladmin"

        $mockmockSetupCredentialPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $mockSetupCredential = New-Object System.Management.Automation.PSCredential( $mockmockSetupCredentialUserName, $mockmockSetupCredentialPassword )

        $mockSqlServiceAccount = 'COMPANY\SqlAccount'
        $mockSqlServicePassword = 'Sqls3v!c3P@ssw0rd'
        $mockSQLServiceCredential = New-Object System.Management.Automation.PSCredential($mockSqlServiceAccount,($mockSQLServicePassword | ConvertTo-SecureString -AsPlainText -Force))
        $mockAgentServiceAccount = 'COMPANY\AgentAccount'
        $mockAgentServicePassword = 'Ag3ntP@ssw0rd'
        $mockSQLAgentCredential = New-Object System.Management.Automation.PSCredential($mockAgentServiceAccount,($mockAgentServicePassword | ConvertTo-SecureString -AsPlainText -Force))

        $mockClusterNodes = @($env:COMPUTERNAME,'SQL01','SQL02')

        $mockSqlDataDirectoryPath = 'E:\MSSQL\Data'
        $mockSqlUserDatabasePath = 'K:\MSSQL\Data'
        $mockSqlUserDatabaseLogPath = 'L:\MSSQL\Logs'
        $mockSqlTempDatabasePath = 'M:\MSSQL\TempDb\Data'
        $mockSqlTempDatabaseLogPath = 'N:\MSSQL\TempDb\Logs'
        $mockSqlBackupPath = 'O:\MSSQL\Backup'

        $mockClusterDiskMap = {
            @{
                SysData = Split-Path -Path $mockDynamicSqlDataDirectoryPath -Qualifier
                UserData = Split-Path -Path $mockDynamicSqlUserDatabasePath -Qualifier
                UserLogs = Split-Path -Path $mockDynamicSqlUserDatabaseLogPath -Qualifier
                TempDbData = Split-Path -Path $mockDynamicSqlTempDatabasePath -Qualifier
                TempDbLogs = Split-Path -Path $mockDynamicSqlTempDatabaseLogPath -Qualifier
                Backup = Split-Path -Path $mockDynamicSqlBackupPath -Qualifier
            }
        }

        $mockCSVClusterDiskMap = @{
            SysData = @{Path='C:\ClusterStorage\SysData';Name="Cluster Virtual Disk (SQL System Data Disk)"}
            UserData = @{Path='C:\ClusterStorage\SQLData';Name="Cluster Virtual Disk (SQL Data Disk)"}
            UserLogs = @{Path='C:\ClusterStorage\SQLLogs';Name="Cluster Virtual Disk (SQL Log Disk)"}
            TempDbData = @{Path='C:\ClusterStorage\TempDBData';Name="Cluster Virtual Disk (SQL TempDBData Disk)"}
            TempDbLogs = @{Path='C:\ClusterStorage\TempDBLogs';Name="Cluster Virtual Disk (SQL TempDBLog Disk)"}
            Backup = @{Path='C:\ClusterStorage\SQLBackup';Name="Cluster Virtual Disk (SQL Backup Disk)"}
        }

        $mockClusterSites = @(
            @{
                Name = 'SiteA'
                Address = $mockDefaultInstance_FailoverClusterIPAddress
                Mask = '255.255.255.0'
            },
            @{
                Name = 'SiteB'
                Address = $mockDefaultInstance_FailoverClusterIPAddress_SecondSite
                Mask = '255.255.255.0'
            }
        )

        #region Function mocks
        $mockGetSqlMajorVersion = {
            return $mockSqlMajorVersion
        }

        $mockEmptyHashtable = {
            return @()
        }

        $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber = '{72AB7E6F-BC24-481E-8C45-1AB5B3DD795D}'
        $mockSqlServerManagementStudio2012_ProductIdentifyingNumber = '{A7037EB2-F953-4B12-B843-195F4D988DA1}'
        $mockSqlServerManagementStudio2014_ProductIdentifyingNumber = '{75A54138-3B98-4705-92E4-F619825B121F}'
        $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber = '{B5FE23CC-0151-4595-84C3-F1DE6F44FE9B}'
        $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber = '{7842C220-6E9A-4D5A-AE70-0E138271F883}'
        $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber = '{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}'

        $mockRegistryUninstallProductsPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

        $mockGetItemProperty_UninstallProducts2008R2 = {
            return @(
                $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber,  # Mock product SSMS 2008 and SSMS 2008 R2
                $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber  # Mock product ADV_SSMS 2012
            )
        }

        $mockGetItemProperty_UninstallProducts2012 = {
            return @(
                $mockSqlServerManagementStudio2012_ProductIdentifyingNumber,    # Mock product ADV_SSMS 2008 and ADV_SSMS 2008 R2
                $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber    # Mock product SSMS 2014
            )
        }

        $mockGetItemProperty_UninstallProducts2014 = {
            return @(
                $mockSqlServerManagementStudio2014_ProductIdentifyingNumber,    # Mock product SSMS 2012
                $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber     # Mock product ADV_SSMS 2014
            )
        }

        $mockGetItemProperty_UninstallProducts = {
            return @(
                $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber,  # Mock product SSMS 2008 and SSMS 2008 R2
                $mockSqlServerManagementStudio2012_ProductIdentifyingNumber,    # Mock product ADV_SSMS 2008 and ADV_SSMS 2008 R2
                $mockSqlServerManagementStudio2014_ProductIdentifyingNumber,    # Mock product SSMS 2012
                $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber,  # Mock product ADV_SSMS 2012
                $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber,    # Mock product SSMS 2014
                $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber     # Mock product ADV_SSMS 2014
            )
        }

        $mockGetCimInstance_DefaultInstance_DatabaseService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_AgentService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_FullTextService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_ReportingService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_IntegrationService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_AnalysisService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetService_DefaultInstance = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_DatabaseService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_AgentService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_FullTextService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_ReportingService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_IntegrationService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockNamedInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_AnalysisService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetService_NamedInstance = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockNamedInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ConfigurationState = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'SQL_Replication_Core_Inst' -Value 1 -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ClientComponentsFull_FeatureList = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'FeatureList' -Value 'Connectivity_Full=3 SQL_SSMS_Full=3 Tools_Legacy_Full=3 Connectivity_FNS=3 SQL_Tools_Standard_FNS=3 Tools_Legacy_FNS=3' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ClientComponentsFull_EmptyFeatureList = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'FeatureList' -Value '' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SQL = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name $mockDefaultInstance_InstanceName -Value $mockDefaultInstance_InstanceId -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name $mockNamedInstance_InstanceName -Value $mockNamedInstance_InstanceId -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SharedDirectory = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name '28A1158CDF9ED6B41B2B7358982D4BA8' -Value $mockSqlSharedDirectory -PassThru -Force
                )
            )
        }

        $mockGetItem_SharedDirectory = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Property' -Value '28A1158CDF9ED6B41B2B7358982D4BA8' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SharedWowDirectory = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name '28A1158CDF9ED6B41B2B7358982D4BA8' -Value $mockSqlSharedWowDirectory -PassThru -Force
                )
            )
        }

        $mockGetItem_SharedWowDirectory = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Property' -Value '28A1158CDF9ED6B41B2B7358982D4BA8' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_Setup = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'SqlProgramDir' -Value $mockSqlProgramDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ServicesAnalysis = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'ImagePath' -Value ('"C:\Program Files\Microsoft SQL Server\OLAP\bin\msmdsrv.exe" -s "{0}"' -f $mockSqlAnalysisConfigDirectory) -PassThru -Force
                )
            )
        }

        $mockConnectSQL = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'LoginMode' -Value $mockSqlLoginMode -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Collation' -Value $mockSqlCollation -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstallDataDirectory' -Value $mockSqlInstallPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'BackupDirectory' -Value $mockDynamicSqlBackupPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBDir' -Value $mockDynamicSqlTempDatabasePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBLogDir' -Value $mockDynamicSqlTempDatabaseLogPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultFile' -Value $mockSqlDefaultDatabaseFilePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultLog' -Value $mockSqlDefaultDatabaseLogPath -PassThru |
                        Add-Member ScriptProperty Logins {
                            return @( ( New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockSqlSystemAdministrator -PassThru |
                                    Add-Member ScriptMethod ListMembers {
                                        return @('sysadmin')
                                    } -PassThru -Force
                                ) )
                        } -PassThru -Force
                )
            )
        }

        $mockConnectSQLCluster = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'LoginMode' -Value $mockSqlLoginMode -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Collation' -Value $mockSqlCollation -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstallDataDirectory' -Value $mockSqlInstallPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'BackupDirectory' -Value $mockDynamicSqlBackupPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBDir' -Value $mockDynamicSqlTempDatabasePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBLogDir' -Value $mockDynamicSqlTempDatabaseLogPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultFile' -Value $mockSqlDefaultDatabaseFilePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultLog' -Value $mockSqlDefaultDatabaseLogPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsClustered' -Value $true -PassThru |
                        Add-Member ScriptProperty Logins {
                            return @( ( New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockSqlSystemAdministrator -PassThru |
                                    Add-Member ScriptMethod ListMembers {
                                        return @('sysadmin')
                                    } -PassThru -Force
                                ) )
                        } -PassThru -Force
                )
            )
        }

        $mockConnectSQLAnalysis = {
            return @(
                (
                    New-Object Object |
                        Add-Member ScriptProperty ServerProperties  {
                            return @{
                                'CollationName' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisCollation -PassThru -Force )
                                'DataDir' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisDataDirectory -PassThru -Force )
                                'TempDir' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisTempDirectory -PassThru -Force )
                                'LogDir' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisLogDirectory -PassThru -Force )
                                'BackupDir' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisBackupDirectory -PassThru -Force )
                            }
                        } -PassThru |
                        Add-Member ScriptProperty Roles  {
                            return @{
                                'Administrators' = @( New-Object Object |
                                    Add-Member ScriptProperty Members {
                                        return New-Object Object |
                                            Add-Member ScriptProperty Name {
                                                return $mockSqlAnalysisAdmins
                                            } -PassThru -Force
                                    } -PassThru -Force
                                ) }
                        } -PassThru -Force
                )
            )
        }

        $mockRobocopyExecutableName = 'Robocopy.exe'
        $mockRobocopyExectuableVersionWithoutUnbufferedIO = '6.2.9200.00000'
        $mockRobocopyExectuableVersionWithUnbufferedIO = '6.3.9600.16384'
        $mockRobocopyExectuableVersion = ''     # Set dynamically during runtime
        $mockRobocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
        $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
        $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'
        $mockRobocopyArgumentUseUnbufferedIO = '/J'
        $mockRobocopyArgumentSourcePath = 'C:\Source\SQL2016'
        $mockRobocopyArgumentDestinationPath = 'D:\Temp'

        $mockGetCommand = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockRobocopyExecutableName -PassThru |
                        Add-Member ScriptProperty FileVersionInfo {
                            return @( ( New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'ProductVersion' -Value $mockRobocopyExectuableVersion -PassThru -Force
                                ) )
                        } -PassThru -Force
                )
            )
        }

        $mockStartProcessExpectedArgument = ''  # Set dynamically during runtime
        $mockStartProcessExitCode = 0  # Set dynamically during runtime

        $mockStartProcess = {
            if ( $ArgumentList -cne $mockStartProcessExpectedArgument )
            {
                throw "Expected arguments was not the same as the arguments in the function call.`nExpected: '$mockStartProcessExpectedArgument' `n But was: '$ArgumentList'"
            }

            return New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value 0 -PassThru -Force
        }

        $mockStartProcess_WithExitCode = {
            return New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value $mockStartProcessExitCode -PassThru -Force
        }

        $mockSourcePathUNCWithoutLeaf = '\\server\share'
        $mockSourcePathGuid = 'cc719562-0f46-4a16-8605-9f8a47c70402'
        $mockNewGuid = {
            return New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Guid' -Value $mockSourcePathGuid -PassThru -Force
        }

        $mockGetTemporaryFolder = {
            return $mockSourcePathUNC
        }

        $mockGetCimInstance_MSClusterResource = {
            return @(
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource','root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server ($mockCurrentInstanceName)" -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{ InstanceName = $mockCurrentInstanceName } -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage = {
            return @(
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ResourceGroup', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Available Storage' -PassThru -Force
                )
            )
        }

        $mockGetCIMInstance_MSCluster_ClusterSharedVolume = {
            return @(
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['SysData'].Path -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['UserData'].Path -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['UserLogs'].Path -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['TempDBData'].Path -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['TempDBLogs'].Path -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['Backup'].Path -PassThru -Force
                )
            )
        }

        $mockGetCIMInstance_MSCluster_ClusterSharedVolumeToResource = {
            return @(
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['SysData'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['SysData'].Name}) -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['UserData'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['UserData'].Name}) -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['UserLogs'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['UserLogs'].Name}) -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['TempDBData'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['TempDBData'].Name}) -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['TempDBLogs'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['TempDBLogs'].Name}) -PassThru -Force
                ),
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['Backup'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object PSObject -Property @{Name=$mockCSVClusterDiskMap['Backup'].Name}) -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_MSClusterNetwork = {
            return @(
                (
                    $mockClusterSites | ForEach-Object {
                        $network = $_

                        New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Network', 'root/MSCluster' |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value "$($network.Name)_Prod" -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'Role' -Value 2 -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'Address' -Value $network.Address -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'AddressMask' -Value $network.Mask -PassThru -Force
                    }
                )
            )
        }

        $mockGetCimAssociatedInstance_MSClusterResourceGroup_DefaultInstance = {
            return @(
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ResourceGroup', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_FailoverClusterGroupName -PassThru -Force
                )
            )
        }

        $mockGetCimAssociatedInstance_MSClusterResource_DefaultInstance = {
            return @(
                (
                    @('Network Name','IP Address') | ForEach-Object {
                        $resourceType = $_

                        $propertyValue = @{
                            MemberType = 'NoteProperty'
                            Name = 'PrivateProperties'
                            Value = $null
                        }

                        switch ($resourceType)
                        {
                            'Network Name'
                            {
                                $propertyValue.Value = @{ DnsName = $mockDefaultInstance_FailoverClusterNetworkName }
                            }

                            'IP Address'
                            {
                                $propertyValue.Value = @{ Address = $mockDefaultInstance_FailoverClusterIPAddress }
                            }
                        }

                        return New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource', 'root/MSCluster' |
                            Add-Member -MemberType NoteProperty -Name 'Type' -Value $resourceType -PassThru -Force |
                            Add-Member @propertyValue -PassThru -Force
                    }
                )
            )
        }

        # Mock to return physical disks that are part of the "Available Storage" cluster role
        $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource = {
            return @(
                (
                    # $mockClusterDiskMap contains variables that are assigned dynamically (during runtime) before each test.
                    (& $mockClusterDiskMap).Keys | ForEach-Object {
                        $diskName = $_
                        New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource','root/MSCluster' |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $diskName -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Physical Disk' -PassThru -Force
                    }
                )
            )
        }

        $mockGetCimAssociatedInstance_MSCluster_ResourceToPossibleOwner = {
            return @(
                (
                    $mockClusterNodes | ForEach-Object {
                        $node = $_
                        New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Node', 'root/MSCluster' |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $node -PassThru -Force
                    }
                )
            )
        }

        $mockGetCimAssociatedInstance_MSCluster_DiskPartition = {
            $clusterDiskName = $InputObject.Name

            # $mockClusterDiskMap contains variables that are assigned dynamically (during runtime) before each test.
            $clusterDiskPath = (& $mockClusterDiskMap).$clusterDiskName

            return @(
                (
                    New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_DiskPartition','root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Path' -Value $clusterDiskPath -PassThru -Force
                )
            )
        }

        <#
        Needed a way to see into the Set-method for the arguments the Set-method is building and sending to 'setup.exe', and fail
        the test if the arguments is different from the expected arguments.
        Solved this by dynamically set the expected arguments before each It-block. If the arguments differs the mock of
        StartWin32Process throws an error message, similiar to what Pester would have reported (expected -> but was).
        #>
        $mockStartWin32ProcessExpectedArgument = @{}

        $mockStartWin32ProcessExpectedArgumentClusterDefault = @{
            IAcceptSQLServerLicenseTerms = 'True'
            Quiet = 'True'
            InstanceName = 'MSSQLSERVER'
            Features = 'SQLENGINE'
            SQLSysAdminAccounts = 'COMPANY\sqladmin'
            FailoverClusterGroup = 'SQL Server (MSSQLSERVER)'
        }

        $mockStartWin32Process = {
            $argumentHashTable = @{}

            # Break the argument string into a hash table
            ($Arguments -split ' ?/') | ForEach-Object {
                if ($_ -imatch '(\w+)="?([^/]+)"?')
                {
                    $key = $Matches[1]
                    if ($key -in ('FailoverClusterDisks','FailoverClusterIPAddresses'))
                    {
                        $value = ($Matches[2] -replace '" "','; ') -replace '"',''
                    }
                    else
                    {
                        $value = ($Matches[2] -replace '" "',' ') -replace '"',''
                    }

                    $null = $argumentHashTable.Add($key, $value)
                }
            }

            # Start by checking whether we have the same number of parameters
            Write-Verbose 'Verifying setup argument count (expected vs actual)' -Verbose

            $argumentHashTable.Keys.Count | Should BeExactly $mockStartWin32ProcessExpectedArgument.Keys.Count

            Write-Verbose 'Verifying actual setup arguments against expected setup arguments' -Verbose
            foreach ($argumentKey in $mockStartWin32ProcessExpectedArgument.Keys)
            {
                $argumentKeyName = $argumentHashTable.GetEnumerator() | Where-Object -FilterScript { $_.Name -eq $argumentKey } | Select-Object -ExpandProperty Name
                $argumentKeyName | Should Be $argumentKey

                $argumentValue = $argumentHashTable.$argumentKey
                $argumentValue | Should Be $mockStartWin32ProcessExpectedArgument.$argumentKey
            }

            return 'Process Started'
        }
        #endregion Function mocks

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            SetupCredential = $mockSetupCredential
            <#
                These are written with both lower-case and upper-case to make sure we support that.
                The feature list must be written in the order it is returned by the function Get-TargerResource.
            #>
            Features = 'SQLEngine,Replication,Conn,Bc,FullText,Rs,As,Is,Ssms,Adv_Ssms'
        }

        $mockDefaultClusterParameters = @{
            SetupCredential = $mockSetupCredential

            # Feature support is tested elsewhere, so just include the minimum
            Features = 'SQLEngine'

        }

        Describe "xSQLServerSetup\Get-TargetResource" -Tag 'Get' {
            #region Setting up TestDrive:\

            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            # UNC path to TestDrive:\
            $testDrive_DriveShare = (Split-Path -Path $mockSourcePath -Qualifier) -replace ':','$'
            $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $mockSourcePath -NoQualifier)

            #endregion Setting up TestDrive:\

            BeforeEach {
                # General mocks
                Mock -CommandName Get-SqlMajorVersion -MockWith $mockGetSqlMajorVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Connect-SQLAnalysis -MockWith $mockConnectSQLAnalysis -Verifiable
                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                    ($Name -eq $mockDefaultInstance_InstanceName -or $Name -eq $mockNamedInstance_InstanceName)
                } -MockWith $mockGetItemProperty_SQL -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    (
                        $Path -eq "HKLM:\SYSTEM\CurrentControlSet\Services\$mockDefaultInstance_AnalysisServiceName" -or
                        $Path -eq "HKLM:\SYSTEM\CurrentControlSet\Services\$mockNamedInstance_AnalysisServiceName"
                    ) -and
                    $Name -eq 'ImagePath'
                } -MockWith $mockGetItemProperty_ServicesAnalysis -Verifiable

                # Mocking SharedDirectory
                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D1F366D0FE0E404F8C15EE4F1C15094' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\30AE1F084B1CF8B4797ECB3CCAA3B3B6'
                } -MockWith $mockGetItemProperty_SharedDirectory -Verifiable

                Mock -CommandName Get-Item -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D1F366D0FE0E404F8C15EE4F1C15094' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
                } -MockWith $mockGetItem_SharedDirectory -Verifiable

                # Mocking SharedWowDirectory
                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C90BFAC020D87EA46811C836AD3C507F' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4'
                } -MockWith $mockGetItemProperty_SharedWowDirectory -Verifiable

                Mock -CommandName Get-Item -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C90BFAC020D87EA46811C836AD3C507F' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4'
                } -MockWith $mockGetItem_SharedWowDirectory -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                } -MockWith $mockGetItemProperty_ClientComponentsFull_FeatureList -Verifiable
            }

            $testProductVersion | ForEach-Object -Process {
                $mockSqlMajorVersion = $_

                $mockDefaultInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockDefaultInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockDynamicSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockDynamicSqlTempDatabasePath = ''
                $mockDynamicSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -eq 13) {
                            # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts -Verifiable
                        } else {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -Exactly -Times 6 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                    }

                    It 'Should not return any names of installed features' {
                        $result = Get-TargetResource @testParameters
                        $result.Features | Should Be ''
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePath
                        $result.InstanceName | Should Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should BeNullOrEmpty
                        $result.InstallSharedDir | Should BeNullOrEmpty
                        $result.InstallSharedWOWDir | Should BeNullOrEmpty
                        $result.SQLSvcAccountUsername | Should BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should BeNullOrEmpty
                        $result.SqlCollation | Should BeNullOrEmpty
                        $result.SQLSysAdminAccounts | Should BeNullOrEmpty
                        $result.SecurityMode | Should BeNullOrEmpty
                        $result.InstallSQLDataDir | Should BeNullOrEmpty
                        $result.SQLUserDBDir | Should BeNullOrEmpty
                        $result.SQLUserDBLogDir | Should BeNullOrEmpty
                        $result.SQLBackupDir | Should BeNullOrEmpty
                        $result.FTSvcAccountUsername | Should BeNullOrEmpty
                        $result.RSSvcAccountUsername | Should BeNullOrEmpty
                        $result.ASSvcAccountUsername | Should BeNullOrEmpty
                        $result.ASCollation | Should BeNullOrEmpty
                        $result.ASSysAdminAccounts | Should BeNullOrEmpty
                        $result.ASDataDir | Should BeNullOrEmpty
                        $result.ASLogDir | Should BeNullOrEmpty
                        $result.ASBackupDir | Should BeNullOrEmpty
                        $result.ASTempDir | Should BeNullOrEmpty
                        $result.ASConfigDir | Should BeNullOrEmpty
                        $result.ISSvcAccountUsername | Should BeNullOrEmpty
                    }
                }

                Context "When using SourceCredential parameter and SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }

                        if ($mockSqlMajorVersion -eq 13) {
                            # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts -Verifiable
                        } else {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -Exactly -Times 6 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                    }

                    It 'Should not return any names of installed features' {
                        $result = Get-TargetResource @testParameters
                        $result.Features | Should Be ''
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePathUNC
                        $result.InstanceName | Should Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should BeNullOrEmpty
                        $result.InstallSharedDir | Should BeNullOrEmpty
                        $result.InstallSharedWOWDir | Should BeNullOrEmpty
                        $result.SQLSvcAccountUsername | Should BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should BeNullOrEmpty
                        $result.SqlCollation | Should BeNullOrEmpty
                        $result.SQLSysAdminAccounts | Should BeNullOrEmpty
                        $result.SecurityMode | Should BeNullOrEmpty
                        $result.InstallSQLDataDir | Should BeNullOrEmpty
                        $result.SQLUserDBDir | Should BeNullOrEmpty
                        $result.SQLUserDBLogDir | Should BeNullOrEmpty
                        $result.SQLBackupDir | Should BeNullOrEmpty
                        $result.FTSvcAccountUsername | Should BeNullOrEmpty
                        $result.RSSvcAccountUsername | Should BeNullOrEmpty
                        $result.ASSvcAccountUsername | Should BeNullOrEmpty
                        $result.ASCollation | Should BeNullOrEmpty
                        $result.ASSysAdminAccounts | Should BeNullOrEmpty
                        $result.ASDataDir | Should BeNullOrEmpty
                        $result.ASLogDir | Should BeNullOrEmpty
                        $result.ASBackupDir | Should BeNullOrEmpty
                        $result.ASTempDir | Should BeNullOrEmpty
                        $result.ASConfigDir | Should BeNullOrEmpty
                        $result.ISSvcAccountUsername | Should BeNullOrEmpty
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for features 'CONN' and 'BC'" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -eq 10) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 11) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 12) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2014 -Verifiable
                        }

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                        #region Mock Get-CimInstance
                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_DatabaseService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_AgentService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_FullTextService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_ReportingService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_IntegrationService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_AnalysisService -Verifiable

                        # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
                        Mock -CommandName Get-CimInstance -MockWith {
                            throw "Mock Get-CimInstance was called with unexpected parameters. ClassName=$ClassName, Filter=$Filter"
                        } -Verifiable
                        #endregion Mock Get-CimInstance

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -MockWith $mockGetItemProperty_ClientComponentsFull_EmptyFeatureList -Verifiable
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($mockSqlMajorVersion -eq 13)
                        {
                            $result.Features | Should Be 'SQLENGINE,REPLICATION,FULLTEXT,RS,AS,IS'
                        } else {
                            $result.Features | Should Be 'SQLENGINE,REPLICATION,FULLTEXT,RS,AS,IS,SSMS,ADV_SSMS'
                        }
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -eq 10) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 11) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 12) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2014 -Verifiable
                        }

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                        #region Mock Get-CimInstance
                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_DatabaseService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_AgentService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_FullTextService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_ReportingService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_IntegrationService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_AnalysisService -Verifiable

                        # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
                        Mock -CommandName Get-CimInstance -MockWith {
                            throw "Mock Get-CimInstance was called with unexpected parameters. ClassName=$ClassName, Filter=$Filter"
                        } -Verifiable
                        #endregion Mock Get-CimInstance

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Exactly -Times 1 -Scope It

                        if ($mockSqlMajorVersion -eq 13) {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 0 -Scope It
                        } else {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 2 -Scope It
                        }

                        #region Assert Get-CimInstance
                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                        } -Exactly -Times 1 -Scope It
                        #endregion Assert Get-CimInstance
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($mockSqlMajorVersion -eq 13)
                        {
                            $featuresForSqlServer2016 = (($mockDefaultParameters.Features.ToUpper()) -replace 'SSMS,','') -replace ',ADV_SSMS',''
                            $result.Features | Should Be $featuresForSqlServer2016
                        } else {
                            $result.Features | Should Be $mockDefaultParameters.Features.ToUpper()
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePath
                        $result.InstanceName | Should Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should Be $mockDefaultInstance_InstanceName
                        $result.InstallSharedDir | Should Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.AgtSvcAccountUsername | Should Be $mockAgentServiceAccount
                        $result.SqlCollation | Should Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should Be $mockSqlSystemAdministrator
                        $result.SecurityMode | Should Be 'Windows'
                        $result.InstallSQLDataDir | Should Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should Be $mockDynamicSqlBackupPath
                        $result.FTSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.RSSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.ASSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.ASCollation | Should Be $mockSqlAnalysisCollation
                        $result.ASSysAdminAccounts | Should Be $mockSqlAnalysisAdmins
                        $result.ASDataDir | Should Be $mockSqlAnalysisDataDirectory
                        $result.ASLogDir | Should Be $mockSqlAnalysisLogDirectory
                        $result.ASBackupDir | Should Be $mockSqlAnalysisBackupDirectory
                        $result.ASTempDir | Should Be $mockSqlAnalysisTempDirectory
                        $result.ASConfigDir | Should Be $mockSqlAnalysisConfigDirectory
                        $result.ISSvcAccountUsername | Should Be $mockSqlServiceAccount
                    }
                }

                Context "When using SourceCredential parameter and SQL Server version is $mockSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }

                        if ($mockSqlMajorVersion -eq 10) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 11) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 12) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2014 -Verifiable
                        }

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                        #region Mock Get-CimInstance
                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_DatabaseService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_AgentService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_FullTextService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_ReportingService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_IntegrationService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                        } -MockWith $mockGetCimInstance_DefaultInstance_AnalysisService -Verifiable

                        # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
                        Mock -CommandName Get-CimInstance -MockWith {
                            throw "Mock Get-CimInstance was called with unexpected parameters. ClassName=$ClassName, Filter=$Filter"
                        } -Verifiable
                        #endregion Mock Get-CimInstance

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Exactly -Times 1 -Scope It

                        if ($mockSqlMajorVersion -eq 13) {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 0 -Scope It
                        } else {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 2 -Scope It
                        }

                        #region Assert Get-CimInstance
                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                        } -Exactly -Times 1 -Scope It
                        #endregion Assert Get-CimInstance
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($mockSqlMajorVersion -eq 13)
                        {
                            $featuresForSqlServer2016 = (($mockDefaultParameters.Features.ToUpper()) -replace 'SSMS,','') -replace ',ADV_SSMS',''
                            $result.Features | Should Be $featuresForSqlServer2016
                        } else {
                            $result.Features | Should Be $mockDefaultParameters.Features.ToUpper()
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePathUNC
                        $result.InstanceName | Should Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should Be $mockDefaultInstance_InstanceName
                        $result.InstallSharedDir | Should Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.AgtSvcAccountUsername | Should Be $mockAgentServiceAccount
                        $result.SqlCollation | Should Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should Be $mockSqlSystemAdministrator
                        $result.SecurityMode | Should Be 'Windows'
                        $result.InstallSQLDataDir | Should Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should Be $mockDynamicSqlBackupPath
                        $result.FTSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.RSSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.ASSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.ASCollation | Should Be $mockSqlAnalysisCollation
                        $result.ASSysAdminAccounts | Should Be $mockSqlAnalysisAdmins
                        $result.ASDataDir | Should Be $mockSqlAnalysisDataDirectory
                        $result.ASLogDir | Should Be $mockSqlAnalysisLogDirectory
                        $result.ASBackupDir | Should Be $mockSqlAnalysisBackupDirectory
                        $result.ASTempDir | Should Be $mockSqlAnalysisTempDirectory
                        $result.ASConfigDir | Should Be $mockSqlAnalysisConfigDirectory
                        $result.ISSvcAccountUsername | Should Be $mockSqlServiceAccount
                    }
                }

                $mockNamedInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockNamedInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL"
                $mockDynamicSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\Backup"
                $mockDynamicSqlTempDatabasePath = ''
                $mockDynamicSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -eq 13) {
                            # Mock this here to make sure we don't return any older components (<=2014) when testing SQL Server 2016
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts -Verifiable
                        } else {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -Exactly -Times 6 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                    }

                    It 'Should not return any names of installed features' {
                        $result = Get-TargetResource @testParameters
                        $result.Features | Should Be ''
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePath
                        $result.InstanceName | Should Be $mockNamedInstance_InstanceName
                        $result.InstanceID | Should BeNullOrEmpty
                        $result.InstallSharedDir | Should BeNullOrEmpty
                        $result.InstallSharedWOWDir | Should BeNullOrEmpty
                        $result.SQLSvcAccountUsername | Should BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should BeNullOrEmpty
                        $result.SqlCollation | Should BeNullOrEmpty
                        $result.SQLSysAdminAccounts | Should BeNullOrEmpty
                        $result.SecurityMode | Should BeNullOrEmpty
                        $result.InstallSQLDataDir | Should BeNullOrEmpty
                        $result.SQLUserDBDir | Should BeNullOrEmpty
                        $result.SQLUserDBLogDir | Should BeNullOrEmpty
                        $result.SQLBackupDir | Should BeNullOrEmpty
                        $result.FTSvcAccountUsername | Should BeNullOrEmpty
                        $result.RSSvcAccountUsername | Should BeNullOrEmpty
                        $result.ASSvcAccountUsername | Should BeNullOrEmpty
                        $result.ASCollation | Should BeNullOrEmpty
                        $result.ASSysAdminAccounts | Should BeNullOrEmpty
                        $result.ASDataDir | Should BeNullOrEmpty
                        $result.ASLogDir | Should BeNullOrEmpty
                        $result.ASBackupDir | Should BeNullOrEmpty
                        $result.ASTempDir | Should BeNullOrEmpty
                        $result.ASConfigDir | Should BeNullOrEmpty
                        $result.ISSvcAccountUsername | Should BeNullOrEmpty
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -eq 10) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 11) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 12) {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2014 -Verifiable
                        }

                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable

                        #region Mock Get-CimInstance
                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_DatabaseServiceName'"
                        } -MockWith $mockGetCimInstance_NamedInstance_DatabaseService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_AgentServiceName'"
                        } -MockWith $mockGetCimInstance_NamedInstance_AgentService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_FullTextServiceName'"
                        } -MockWith $mockGetCimInstance_NamedInstance_FullTextService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_ReportingServiceName'"
                        } -MockWith $mockGetCimInstance_NamedInstance_ReportingService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$(($mockNamedInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                        } -MockWith $mockGetCimInstance_NamedInstance_IntegrationService -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_AnalysisServiceName'"
                        } -MockWith $mockGetCimInstance_NamedInstance_AnalysisService -Verifiable

                        # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
                        Mock -CommandName Get-CimInstance -MockWith {
                            throw "Mock Get-CimInstance was called with unexpected parameters. ClassName=$ClassName, Filter=$Filter"
                        } -Verifiable
                        #endregion Mock Get-CimInstance

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Exactly -Times 1 -Scope It

                        if ($mockSqlMajorVersion -eq 13) {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 0 -Scope It
                        } else {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 2 -Scope It
                        }

                        #region Assert Get-CimInstance
                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_DatabaseServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_AgentServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_FullTextServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_ReportingServiceName'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$(($mockNamedInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'Win32_Service' -and
                            $Filter -eq "Name = '$mockNamedInstance_AnalysisServiceName'"
                        } -Exactly -Times 1 -Scope It
                        #endregion Assert Get-CimInstance
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($mockSqlMajorVersion -eq 13)
                        {
                            $featuresForSqlServer2016 = (($mockDefaultParameters.Features.ToUpper()) -replace 'SSMS,','') -replace ',ADV_SSMS',''
                            $result.Features | Should Be $featuresForSqlServer2016
                        } else {
                            $result.Features | Should Be $mockDefaultParameters.Features.ToUpper()
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePath
                        $result.InstanceName | Should Be $mockNamedInstance_InstanceName
                        $result.InstanceID | Should Be $mockNamedInstance_InstanceName
                        $result.InstallSharedDir | Should Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.AgtSvcAccountUsername | Should Be $mockAgentServiceAccount
                        $result.SqlCollation | Should Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should Be $mockSqlSystemAdministrator
                        $result.SecurityMode | Should Be 'Windows'
                        $result.InstallSQLDataDir | Should Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should Be $mockDynamicSqlBackupPath
                        $result.FTSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.RSSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.ASSvcAccountUsername | Should Be $mockSqlServiceAccount
                        $result.ASCollation | Should Be $mockSqlAnalysisCollation
                        $result.ASSysAdminAccounts | Should Be $mockSqlAnalysisAdmins
                        $result.ASDataDir | Should Be $mockSqlAnalysisDataDirectory
                        $result.ASLogDir | Should Be $mockSqlAnalysisLogDirectory
                        $result.ASBackupDir | Should Be $mockSqlAnalysisBackupDirectory
                        $result.ASTempDir | Should Be $mockSqlAnalysisTempDirectory
                        $result.ASConfigDir | Should Be $mockSqlAnalysisConfigDirectory
                        $result.ISSvcAccountUsername | Should Be $mockSqlServiceAccount
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a clustered default instance" {

                    BeforeAll {
                        $testParams = $mockDefaultParameters.Clone()
                        $testParams.Remove('Features')
                        $testParams += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith {} -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith {} -Verifiable

                        Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty_Setup -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                    }

                    It 'Should not attempt to collect cluster information for a standalone instance' {

                        $currentState = Get-TargetResource @testParams

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 0 -Scope It

                        $currentState.FailoverClusterGroupName | Should BeNullOrEmpty
                        $currentState.FailoverClusterNetworkName | Should BeNullOrEmpty
                        $currentState.FailoverClusterIPAddress | Should BeNullOrEmpty
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is in the desired state for a clustered default instance" {

                    BeforeEach {
                        $testParams = $mockDefaultParameters.Clone()
                        $testParams.Remove('Features')
                        $testParams += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        $mockCurrentInstanceName = $mockDefaultInstance_InstanceName

                        Mock -CommandName Connect-SQL -MockWith $mockConnectSQLCluster -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResource -Verifiable -ParameterFilter {
                            $Filter -eq "Type = 'SQL Server'"
                        }

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSClusterResourceGroup_DefaultInstance -Verifiable -ParameterFilter { $ResultClassName -eq 'MSCluster_ResourceGroup' }

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSClusterResource_DefaultInstance -Verifiable -ParameterFilter { $ResultClassName -eq 'MSCluster_Resource' }

                        Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty_Setup -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should collect information for a clustered instance' {
                        $currentState = Get-TargetResource @testParams

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -Scope It -ParameterFilter { $Filter -eq "Type = 'SQL Server'" }
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 1 -Scope It -ParameterFilter { $ResultClassName -eq 'MSCluster_ResourceGroup' }
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 2 -Scope It -ParameterFilter { $ResultClassName -eq 'MSCluster_Resource' }

                        $currentState.InstanceName | Should Be $testParams.InstanceName
                    }

                    It 'Should return correct cluster information' {
                        $currentState = Get-TargetResource @testParams

                        $currentState.FailoverClusterGroupName | Should Be $mockDefaultInstance_FailoverClusterGroupName
                        $currentState.FailoverClusterIPAddress | Should Be $mockDefaultInstance_FailoverClusterIPAddress
                        $currentSTate.FailoverClusterNetworkName | Should Be $mockDefaultInstance_FailoverClusterNetworkName
                    }
                }
            }

            Assert-VerifiableMocks
        }

        Describe "xSQLServerSetup\Test-TargetResource" -Tag 'Test' {
            #region Setting up TestDrive:\

            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            # UNC path to TestDrive:\
            $testDrive_DriveShare = (Split-Path -Path $mockSourcePath -Qualifier) -replace ':','$'
            $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $mockSourcePath -NoQualifier)

            #endregion Setting up TestDrive:\

            BeforeEach {
                # General mocks
                Mock -CommandName Get-SqlMajorVersion -MockWith $mockGetSqlMajorVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Connect-SQLAnalysis -MockWith $mockConnectSQLAnalysis -Verifiable
                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                    ($Name -eq $mockDefaultInstance_InstanceName -or $Name -eq $mockNamedInstance_InstanceName)
                } -MockWith $mockGetItemProperty_SQL -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    (
                        $Path -eq "HKLM:\SYSTEM\CurrentControlSet\Services\$mockDefaultInstance_AnalysisServiceName" -or
                        $Path -eq "HKLM:\SYSTEM\CurrentControlSet\Services\$mockNamedInstance_AnalysisServiceName"
                    ) -and
                    $Name -eq 'ImagePath'
                } -MockWith $mockGetItemProperty_ServicesAnalysis -Verifiable

                # Mocking SharedDirectory
                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D1F366D0FE0E404F8C15EE4F1C15094' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\30AE1F084B1CF8B4797ECB3CCAA3B3B6'
                } -MockWith $mockGetItemProperty_SharedDirectory -Verifiable

                Mock -CommandName Get-Item -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D1F366D0FE0E404F8C15EE4F1C15094' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
                } -MockWith $mockGetItem_SharedDirectory -Verifiable

                # Mocking SharedWowDirectory
                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C90BFAC020D87EA46811C836AD3C507F' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4'
                } -MockWith $mockGetItemProperty_SharedWowDirectory -Verifiable

                Mock -CommandName Get-Item -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C90BFAC020D87EA46811C836AD3C507F' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4'
                } -MockWith $mockGetItem_SharedWowDirectory -Verifiable
            }

            # For this test we only need to test one SQL Server version. Mocking SQL Server 2016 for the 'not in the desired state' test.
            $mockSqlMajorVersion = 13

            $mockDefaultInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockDefaultInstance_InstanceName)"

            $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
            $mockDynamicSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
            $mockDynamicSqlTempDatabasePath = ''
            $mockDynamicSqlTempDatabaseLogPath = ''
            $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
            $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        InstanceName = $mockDefaultInstance_InstanceName
                        SourceCredential = $null
                        SourcePath = $mockSourcePath
                    }

                    # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                    } -MockWith $mockGetItemProperty_UninstallProducts -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                    } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -MockWith $mockGetItemProperty_Setup -Verifiable
                }

                It 'Should return that the desired state is absent when no products are installed' {
                    Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                    Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                    } -Exactly -Times 0 -Scope It

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -Exactly -Times 0 -Scope It

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                    } -Exactly -Times 6 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                }

                It 'Should return that the desired state is asbent when SSMS product is missing' {
                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                    #region Mock Get-CimInstance
                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_DatabaseService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_AgentService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_FullTextService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_ReportingService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_IntegrationService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_AnalysisService -Verifiable

                    # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
                    Mock -CommandName Get-CimInstance -MockWith {
                        throw "Mock Get-CimInstance was called with unexpected parameters. ClassName=$ClassName, Filter=$Filter"
                    } -Verifiable
                    #endregion Mock Get-CimInstance

                    # Change the default features for this test.
                    $testParameters.Features = 'SSMS'

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                    } -Exactly -Times 6 -Scope It

                    #region Assert Get-CimInstance
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                    } -Exactly -Times 1 -Scope It
                    #endregion Assert Get-CimInstance
                }

                It 'Should return that the desired state is asbent when ADV_SSMS product is missing' {
                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                    #region Mock Get-CimInstance
                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_DatabaseService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_AgentService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_FullTextService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_ReportingService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_IntegrationService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_AnalysisService -Verifiable

                    # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
                    Mock -CommandName Get-CimInstance -MockWith {
                        throw "Mock Get-CimInstance was called with unexpected parameters. ClassName=$ClassName, Filter=$Filter"
                    } -Verifiable
                    #endregion Mock Get-CimInstance

                    # Change the default features for this test.
                    $testParameters.Features = 'ADV_SSMS'

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                    } -Exactly -Times 6 -Scope It

                    #region Assert Get-CimInstance
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                    } -Exactly -Times 1 -Scope It
                    #endregion Assert Get-CimInstance
                }

                It 'Should return that the desired state is absent when a clustered instance cannot be found' {
                    $testClusterParameters = $testParameters.Clone()

                    $testClusterParameters += @{
                        FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                        FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                        FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                    }

                    $result = Test-TargetResource @testClusterParameters

                    $result | Should Be $false
                }

                It 'Should return false if SQL Server failover cluster is missing features ' {
                    $mockCurrentInstanceName = $mockDefaultInstance_InstanceName

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                                Features = 'SQLEngine,AS'
                                FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                                FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                                FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            }
                    } -Verifiable

                    $testClusterParameters = $testParameters.Clone()
                    $testClusterParameters['Features'] = 'SQLEngine,AS'

                    $testClusterParameters += @{
                        FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                        FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                        FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                    }

                    $result = Test-TargetResource @testClusterParameters
                    $result | Should Be $false
                }
            }

            # For this test we only need to test one SQL Server version. Mocking SQL Server 2014 for the 'in the desired state' test.
            $mockSqlMajorVersion = 12

            Context "When the system is in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        InstanceName = $mockDefaultInstance_InstanceName
                        SourceCredential = $null
                        SourcePath = $mockSourcePath
                    }

                    # Mock all SSMS products.
                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                    } -MockWith $mockGetItemProperty_UninstallProducts -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                    } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                    } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                    } -MockWith $mockGetItemProperty_UninstallProducts2014 -Verifiable

                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                    #region Mock Get-CimInstance
                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_DatabaseService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_AgentService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_FullTextService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_ReportingService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_IntegrationService -Verifiable

                    Mock -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                    } -MockWith $mockGetCimInstance_DefaultInstance_AnalysisService -Verifiable

                    # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
                    Mock -CommandName Get-CimInstance -MockWith {
                        throw "Mock Get-CimInstance was called with unexpected parameters. ClassName=$ClassName, Filter=$Filter"
                    } -Verifiable
                    #endregion Mock Get-CimInstance

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                    } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                    } -MockWith $mockGetItemProperty_ClientComponentsFull_FeatureList -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -MockWith $mockGetItemProperty_Setup -Verifiable
                }

                It 'Should return that the desired state is present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                        $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                    } -Exactly -Times 6 -Scope It

                    #region Assert Get-CimInstance
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_DatabaseServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AgentServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_FullTextServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_ReportingServiceName'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$(($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion))'"
                    } -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'Win32_Service' -and
                        $Filter -eq "Name = '$mockDefaultInstance_AnalysisServiceName'"
                    } -Exactly -Times 1 -Scope It
                    #endregion Assert Get-CimInstance
                }

                It 'Should return that the desired state is present when the correct clustered instance was found' {
                    $mockCurrentInstanceName = $mockDefaultInstance_InstanceName

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQLCluster -Verifiable

                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResource -Verifiable -ParameterFilter {
                        $Filter -eq "Type = 'SQL Server'"
                    }

                    Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSClusterResourceGroup_DefaultInstance -Verifiable -ParameterFilter { $ResultClassName -eq 'MSCluster_ResourceGroup' }

                    Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSClusterResource_DefaultInstance -Verifiable -ParameterFilter { $ResultClassName -eq 'MSCluster_Resource' }

                    $testClusterParameters = $testParameters.Clone()

                    $testClusterParameters += @{
                        FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                        FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                        FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                    }

                    $result = Test-TargetResource @testClusterParameters

                    $result | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -Scope It -ParameterFilter { $Filter -eq "Type = 'SQL Server'" }
                    Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 3 -Scope It
                }

                It 'Should not return false after a clustered install due to the presence of a variable called "FailoverClusterDisks"' {
                    $mockCurrentInstanceName = $mockDefaultInstance_InstanceName

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQLCluster -Verifiable

                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResource -Verifiable -ParameterFilter {
                        $Filter -eq "Type = 'SQL Server'"
                    }

                    Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSClusterResourceGroup_DefaultInstance -Verifiable -ParameterFilter { $ResultClassName -eq 'MSCluster_ResourceGroup' }

                    Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSClusterResource_DefaultInstance -Verifiable -ParameterFilter { $ResultClassName -eq 'MSCluster_Resource' }

                    $testClusterParameters = $testParameters.Clone()

                    $testClusterParameters += @{
                        FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                        FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                        FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                    }

                    $mockDynamicSqlDataDirectoryPath = $mockSqlDataDirectoryPath
                    $mockDynamicSqlUserDatabasePath = $mockSqlUserDatabasePath
                    $mockDynamicSqlUserDatabaseLogPath = $mockSqlUserDatabaseLogPath
                    $mockDynamicSqlTempDatabasePath = $mockSqlTempDatabasePath
                    $mockDynamicSqlTempDatabaseLogPath = $mockSqlTempDatabaseLogPath
                    $mockDynamicSqlBackupPath = $mockSqlBackupPath

                    New-Variable -Name 'FailoverClusterDisks' -Value (& $mockClusterDiskMap)['UserData']

                    $result = Test-TargetResource @testClusterParameters

                    $result | Should Be $true
                }
            }

            Assert-VerifiableMocks
        }

        Describe "xSQLServerSetup\Set-TargetResource" -Tag 'Set' {
            #region Setting up TestDrive:\

            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            # UNC path to TestDrive:\
            $testDrive_DriveShare = (Split-Path -Path $mockSourcePath -Qualifier) -replace ':','$'
            $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $mockSourcePath -NoQualifier)

            <#
                Mocking folder structure. This takes the leaf from the $mockSourcePath (the Guid in this case) and
                uses that to create a mock folder to mimic the temp folder that would be created in, for example,
                temp folder 'C:\Windows\Temp'.
                This folder is used when SourcePath is called with a leaf, for example '\\server\share\folder'.
            #>
            $mediaTempSourcePathWithLeaf = (Join-Path -Path $mockSourcePath -ChildPath (Split-Path -Path $mockSourcePath -Leaf))
            if (-not (Test-Path $mediaTempSourcePathWithLeaf))
            {
                New-Item -Path $mediaTempSourcePathWithLeaf -ItemType Directory
            }

            <#
                Mocking folder structure. This takes the leaf from the New-Guid mock and uses that
                to create a mock folder to mimic the temp folder that would be created in, for example,
                temp folder 'C:\Windows\Temp'.
                This folder is used when SourcePath is called without a leaf, for example '\\server\share'.
            #>
            $mediaTempSourcePathWithoutLeaf = (Join-Path -Path $mockSourcePath -ChildPath $mockSourcePathGuid)
            if (-not (Test-Path $mediaTempSourcePathWithoutLeaf))
            {
                New-Item -Path $mediaTempSourcePathWithoutLeaf -ItemType Directory
            }

            # Mocking executable setup.exe which will be used for tests without parameter SourceCredential
            Set-Content (Join-Path -Path $mockSourcePath -ChildPath 'setup.exe') -Value 'Mock exe file'

            # Mocking executable setup.exe which will be used for tests with parameter SourceCredential and an UNC path with leaf
            Set-Content (Join-Path -Path $mediaTempSourcePathWithLeaf -ChildPath 'setup.exe') -Value 'Mock exe file'

            # Mocking executable setup.exe which will be used for tests with parameter SourceCredential and an UNC path without leaf
            Set-Content (Join-Path -Path $mediaTempSourcePathWithoutLeaf -ChildPath 'setup.exe') -Value 'Mock exe file'

            #endregion Setting up TestDrive:\

            BeforeEach {
                # General mocks
                Mock -CommandName Get-SqlMajorVersion -MockWith $mockGetSqlMajorVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Connect-SQLAnalysis -MockWith $mockConnectSQLAnalysis -Verifiable
                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                    ($Name -eq $mockDefaultInstance_InstanceName -or $Name -eq $mockNamedInstance_InstanceName)
                } -MockWith $mockGetItemProperty_SQL -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    (
                        $Path -eq "HKLM:\SYSTEM\CurrentControlSet\Services\$mockDefaultInstance_AnalysisServiceName" -or
                        $Path -eq "HKLM:\SYSTEM\CurrentControlSet\Services\$mockNamedInstance_AnalysisServiceName"
                    ) -and
                    $Name -eq 'ImagePath'
                } -MockWith $mockGetItemProperty_ServicesAnalysis -Verifiable

                # Mocking SharedDirectory and SharedWowDirectory (when not previously installed)
                Mock -CommandName Get-ItemProperty -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                } -MockWith $mockGetItemProperty_ClientComponentsFull_FeatureList -Verifiable

                Mock -CommandName StartWin32Process -MockWith $mockStartWin32Process -Verifiable
                Mock -CommandName WaitForWin32ProcessEnd -Verifiable
                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                } -Verifiable
            }

            $testProductVersion | ForEach-Object -Process {
                $mockSqlMajorVersion = $_

                $mockDefaultInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockDefaultInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockDynamicSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockDynamicSqlTempDatabasePath = ''
                $mockDynamicSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Start-Process -Verifiable
                        Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder -Verifiable
                        Mock -CommandName New-Guid -MockWith $mockNewGuid -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                            ProductKey = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                            SQLSysAdminAccounts = 'COMPANY\User1','COMPANY\SQLAdmins'
                            ASSysAdminAccounts = 'COMPANY\User1','COMPANY\SQLAdmins'
                            InstanceDir = 'D:'
                            InstallSQLDataDir = 'E:'
                            InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
                            InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
                        }

                        if ( $mockSqlMajorVersion -eq 13 )
                        {
                            $testParameters.Features = $testParameters.Features -replace ',SSMS,ADV_SSMS',''
                        }

                        $mockStartWin32ProcessExpectedArgument = @{
                            Quiet = 'True'
                            IAcceptSQLServerLicenseTerms = 'True'
                            Action = 'Install'
                            AGTSVCSTARTUPTYPE = 'Automatic'
                            InstanceName = 'MSSQLSERVER'
                            Features = $testParameters.Features
                            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                            ASSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                            PID = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                            InstanceDir = 'D:\'
                            InstallSQLDataDir = 'E:\'
                            InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
                            InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-TemporaryFolder -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName New-Guid -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Start-Process -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                            ($Name -eq $mockDefaultInstance_InstanceName)
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -Exactly -Times 6 -Scope It

                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -eq 13 ) {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016' {
                            $testParameters = $mockDefaultParameters.Clone()
                            $testParameters += @{
                                InstanceName = $mockDefaultInstance_InstanceName
                                SourceCredential = $null
                                SourcePath = $mockSourcePath
                            }

                            $testParameters.Features = 'SSMS'
                            $mockStartWin32ProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should Throw "'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016' {
                            $testParameters = $mockDefaultParameters.Clone()
                            $testParameters += @{
                                InstanceName = $mockDefaultInstance_InstanceName
                                SourceCredential = $null
                                SourcePath = $mockSourcePath
                            }

                            $testParameters.Features = 'ADV_SSMS'
                            $mockStartWin32ProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should Throw "'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }
                    } else {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters = $mockDefaultParameters.Clone()
                            $testParameters += @{
                                InstanceName = $mockDefaultInstance_InstanceName
                                SourceCredential = $null
                                SourcePath = $mockSourcePath
                            }

                            $testParameters.Features = 'SSMS'

                            $mockStartWin32ProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                                ($Name -eq $mockDefaultInstance_InstanceName)
                            } -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 6 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters = $mockDefaultParameters.Clone()
                            $testParameters += @{
                                InstanceName = $mockDefaultInstance_InstanceName
                                SourceCredential = $null
                                SourcePath = $mockSourcePath
                            }

                            $testParameters.Features = 'ADV_SSMS'

                            $mockStartWin32ProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'ADV_SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                                ($Name -eq $mockDefaultInstance_InstanceName)
                            } -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 6 -Scope It


                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context "When using SourceCredential parameter, and using a UNC path with a leaf, and SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }

                        if ( $mockSqlMajorVersion -eq 13 )
                        {
                            $testParameters.Features = $testParameters.Features -replace ',SSMS,ADV_SSMS',''
                        }

                        # Mocking SharedDirectory (when previously installed and should not be installed again).
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D1F366D0FE0E404F8C15EE4F1C15094' -or
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\30AE1F084B1CF8B4797ECB3CCAA3B3B6'
                        } -MockWith $mockGetItemProperty_SharedDirectory -Verifiable

                        # Mocking SharedWowDirectory (when previously installed and should not be installed again).
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C90BFAC020D87EA46811C836AD3C507F' -or
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4'
                        } -MockWith $mockGetItemProperty_SharedWowDirectory -Verifiable

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Start-Process -Verifiable
                        Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder -Verifiable
                        Mock -CommandName New-Guid -MockWith $mockNewGuid -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -MockWith $mockEmptyHashtable -Verifiable
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {

                        $mockStartWin32ProcessExpectedArgument = @{
                            Quiet = 'True'
                            IAcceptSQLServerLicenseTerms = 'True'
                            Action = 'Install'
                            AgtSvcStartupType = 'Automatic'
                            InstanceName = 'MSSQLSERVER'
                            Features = $testParameters.Features
                            SQLSysAdminAccounts = 'COMPANY\sqladmin'
                            ASSysAdminAccounts = 'COMPANY\sqladmin'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName New-Guid -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                            ($Name -eq $mockDefaultInstance_InstanceName)
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -Exactly -Times 6 -Scope It


                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -eq 13 ) {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = 'SSMS'
                            $mockStartWin32ProcessExpectedArgument = ''

                            { Set-TargetResource @testParameters } | Should Throw "'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = 'ADV_SSMS'
                            $mockStartWin32ProcessExpectedArgument = ''

                            { Set-TargetResource @testParameters } | Should Throw "'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }
                    } else {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters.Features = 'SSMS'

                            $mockStartWin32ProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                                ($Name -eq $mockDefaultInstance_InstanceName)
                            } -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 6 -Scope It


                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters.Features = 'ADV_SSMS'

                            $mockStartWin32ProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'ADV_SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                                ($Name -eq $mockDefaultInstance_InstanceName)
                            } -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 6 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context "When using SourceCredential parameter, and using a UNC path without a leaf, and SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNCWithoutLeaf
                        }

                        if ( $mockSqlMajorVersion -eq 13 )
                        {
                            $testParameters.Features = $testParameters.Features -replace ',SSMS,ADV_SSMS',''
                        }

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Start-Process -Verifiable
                        Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder -Verifiable
                        Mock -CommandName New-Guid -MockWith $mockNewGuid -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -MockWith $mockEmptyHashtable -Verifiable
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        $mockStartWin32ProcessExpectedArgument = @{
                            Quiet = 'True'
                            IAcceptSQLServerLicenseTerms = 'True'
                            Action = 'Install'
                            AGTSVCSTARTUPTYPE = 'Automatic'
                            InstanceName = 'MSSQLSERVER'
                            Features = $testParameters.Features
                            SQLSysAdminAccounts = 'COMPANY\sqladmin'
                            ASSysAdminAccounts = 'COMPANY\sqladmin'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName New-Guid -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                            ($Name -eq $mockDefaultInstance_InstanceName)
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -Exactly -Times 6 -Scope It


                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -eq 13 ) {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = 'SSMS'
                            $mockStartWin32ProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should Throw "'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = 'ADV_SSMS'
                            $mockStartWin32ProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should Throw "'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }
                    } else {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters.Features = 'SSMS'

                            $mockStartWin32ProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                                ($Name -eq $mockDefaultInstance_InstanceName)
                            } -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 6 -Scope It


                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters.Features = 'ADV_SSMS'

                            $mockStartWin32ProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'ADV_SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                                ($Name -eq $mockDefaultInstance_InstanceName)
                            } -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 6 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                $mockNamedInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockNamedInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL"
                $mockDynamicSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\Backup"
                $mockDynamicSqlTempDatabasePath = ''
                $mockDynamicSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ( $mockSqlMajorVersion -eq 13 )
                        {
                            $testParameters.Features = $testParameters.Features -replace ',SSMS,ADV_SSMS',''
                        }

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        $mockStartWin32ProcessExpectedArgument = @{
                            Quiet = 'True'
                            IAcceptSQLServerLicenseTerms = 'True'
                            Action = 'Install'
                            AGTSVCSTARTUPTYPE = 'Automatic'
                            InstanceName = 'TEST'
                            Features = $testParameters.Features
                            SQLSysAdminAccounts = 'COMPANY\sqladmin'
                            ASSysAdminAccounts = 'COMPANY\sqladmin'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                            ($Name -eq $mockDefaultInstance_InstanceName)
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                            $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                        } -Exactly -Times 6 -Scope It

                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -eq 13 ) {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = $($testParameters.Features), 'SSMS' -join ','
                            $mockStartWin32ProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should Throw "'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = $($testParameters.Features), 'ADV_SSMS' -join ','
                            $mockStartWin32ProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should Throw "'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }
                    } else {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters.Features = 'SSMS'

                            $mockStartWin32ProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'TEST'
                                Features = 'SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                                ($Name -eq $mockDefaultInstance_InstanceName)
                            } -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 6 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters.Features = 'ADV_SSMS'

                            $mockStartWin32ProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'TEST'
                                Features = 'ADV_SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                                ($Name -eq $mockDefaultInstance_InstanceName)
                            } -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 6 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                # For testing AddNode action
                Context "When SQL Server version is $mockSQLMajorVersion and the system is not in the desired state and the action is AddNode" {
                    BeforeAll {
                        $testParameters = $mockDefaultClusterParameters.Clone()

                        $testParameters += @{
                            InstanceName = 'MSSQLSERVER'
                            SourcePath = $mockSourcePath
                            Action = 'AddNode'
                            AgtSvcAccount = $mockSQLAgentCredential
                            SqlSvcAccount = $mockSQLServiceCredential
                        }

                        $testParameters.Remove('Features')
                        $testParameters.Remove('SQLUserDBDir')
                        $testParameters.Remove('SQLUserDBLogDir')
                        $testParameters.Remove('SQLTempDbDir')
                        $testParameters.Remove('SQLTempDBlogDir')

                    }

                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage -ParameterFilter {
                            $Filter -eq "Name = 'Available Storage'"
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource -ParameterFilter {
                            ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
                        } -Verfiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceToPossibleOwner -ParameterFilter {
                            $Association -eq 'MSCluster_ResourceToPossibleOwner'
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_DiskPartition -ParameterFilter {
                            $ResultClassName -eq 'MSCluster_DiskPartition'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterNetwork -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCIMInstance_MSCluster_ClusterSharedVolume -ParameterFilter {
                            $ClassName -eq 'MSCluster_ClusterSharedVolume'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCIMInstance_MSCluster_ClusterSharedVolumeToResource -ParameterFilter {
                            $ClassName -eq 'MSCluster_ClusterSharedVolumeToResource'
                        } -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                    }

                    It 'Should pass proper parameters to setup' {
                        $mockStartWin32ProcessExpectedArgument = @{
                            IAcceptSQLServerLicenseTerms = 'True'
                            Quiet = 'True'
                            Action = 'AddNode'
                            InstanceName = 'MSSQLSERVER'
                            AgtSvcAccount = $mockAgentServiceAccount
                            AgtSvcPassword = $mockSqlAgentCredential.GetNetworkCredential().Password
                            SqlSvcAccount = $mockSqlServiceAccount
                            SqlSvcPassword = $mockSQLServiceCredential.GetNetworkCredential().Password

                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should pass the SetupCredential object to the StartWin32Process function' {
                        $mockStartWin32Process_SetupCredential = {
                            $Credential | Should Not BeNullOrEmpty
                            return 'Process started.'
                        }

                        Mock -CommandName StartWin32Process -MockWith $mockStartWin32Process_SetupCredential

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }
                }

                # For testing InstallFailoverCluster action
                Context "When SQL Server version is $mockSQLMajorVersion and the system is not in the desired state and the action is InstallFailoverCluster" {
                    BeforeAll {
                        $mockDynamicSqlDataDirectoryPath = $mockSqlDataDirectoryPath
                        $mockDynamicSqlUserDatabasePath = $mockSqlUserDatabasePath
                        $mockDynamicSqlUserDatabaseLogPath = $mockSqlUserDatabaseLogPath
                        $mockDynamicSqlTempDatabasePath = $mockSqlTempDatabasePath
                        $mockDynamicSqlTempDatabaseLogPath = $mockSqlTempDatabaseLogPath
                        $mockDynamicSqlBackupPath = $mockSqlBackupPath

                        $testParameters = $mockDefaultClusterParameters.Clone()
                        $testParameters += @{
                            InstanceName = 'MSSQLSERVER'
                            SourcePath = $mockSourcePath
                            Action = 'InstallFailoverCluster'
                            FailoverClusterGroupName = 'SQL Server (MSSQLSERVER)'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress

                            # Ensure we use "clustered" disks for our paths
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDbDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDbLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                        }

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage -ParameterFilter {
                            $Filter -eq "Name = 'Available Storage'"
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource -ParameterFilter {
                            ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
                        } -Verfiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceToPossibleOwner -ParameterFilter {
                            $Association -eq 'MSCluster_ResourceToPossibleOwner'
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_DiskPartition -ParameterFilter {
                            $ResultClassName -eq 'MSCluster_DiskPartition'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCIMInstance_MSCluster_ClusterSharedVolume -ParameterFilter {
                            $ClassName -eq 'MSCluster_ClusterSharedVolume'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCIMInstance_MSCluster_ClusterSharedVolumeToResource -ParameterFilter {
                            $ClassName -eq 'MSCluster_ClusterSharedVolumeToResource'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterNetwork -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                    }

                    It 'Should pass proper parameters to setup' {
                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            Action = 'InstallFailoverCluster'
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            SkipRules = 'Cluster_VerifyForErrors'
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should pass proper parameters to setup when only InstallSQLDataDir is assigned a path' {
                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            Action = 'InstallFailoverCluster'
                            FailoverClusterDisks = 'SysData'
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            SkipRules = 'Cluster_VerifyForErrors'
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                        }

                        $setTargetResourceParameters = $testParameters.Clone()
                        $setTargetResourceParameters.Remove('SQLUserDBDir')
                        $setTargetResourceParameters.Remove('SQLUserDBLogDir')
                        $setTargetResourceParameters.Remove('SQLTempDbDir')
                        $setTargetResourceParameters.Remove('SQLTempDbLogDir')
                        $setTargetResourceParameters.Remove('SQLBackupDir')

                        { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    }

                    It 'Should pass proper parameters to setup when three variables are assigned the same drive, but different paths' {
                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            Action = 'InstallFailoverCluster'
                            FailoverClusterDisks = 'SysData'
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            SkipRules = 'Cluster_VerifyForErrors'
                            InstallSQLDataDir = 'E:\SQLData'
                            SQLUserDBDir = 'E:\SQLData\UserDb'
                            SQLUserDBLogDir = 'E:\SQLData\UserDbLogs'
                        }

                        $setTargetResourceParameters = $testParameters.Clone()
                        $setTargetResourceParameters.Remove('SQLTempDbDir')
                        $setTargetResourceParameters.Remove('SQLTempDbLogDir')
                        $setTargetResourceParameters.Remove('SQLBackupDir')

                        $setTargetResourceParameters['InstallSQLDataDir'] = 'E:\SQLData\' # This ends with \ to test removal of paths ending with \
                        $setTargetResourceParameters['SQLUserDBDir'] = 'E:\SQLData\UserDb'
                        $setTargetResourceParameters['SQLUserDBLogDir'] = 'E:\SQLData\UserDbLogs'

                        { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    }

                    It 'Should pass the SetupCredential object to the StartWin32Process function' {
                        $mockStartWin32Process_SetupCredential = {
                            $Credential | Should Not BeNullOrEmpty
                            return 'Process started.'
                        }

                        Mock -CommandName StartWin32Process -MockWith $mockStartWin32Process_SetupCredential

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should throw an error when one or more paths are not resolved to clustered storage' {
                        $badPathParameters = $testParameters.Clone()

                        # Pass in a bad path
                        $badPathParameters.SQLUserDBDir = 'C:\MSSQL\'

                        { Set-TargetResource @badPathParameters } | Should Throw 'Unable to map the specified paths to valid cluster storage. Drives mapped: Backup; SysData; TempDbData; TempDbLogs; UserLogs'
                    }

                    It 'Should properly map paths to clustered disk resources' {
                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            Action = 'InstallFailoverCluster'
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                            SkipRules = 'Cluster_VerifyForErrors'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should build a DEFAULT address string when no network is specified' {
                        $missingNetworkParams = $testParameters.Clone()
                        $missingNetworkParams.Remove('FailoverClusterIPAddress')

                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            Action = 'InstallFailoverCluster'
                            FailoverClusterIPAddresses = 'DEFAULT'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                            SkipRules = 'Cluster_VerifyForErrors'
                        }

                        { Set-TargetResource @missingNetworkParams } | Should Not Throw
                    }

                    It 'Should throw an error when an invalid IP Address is specified' {
                        $invalidAddressParameters = $testParameters.Clone()

                        $invalidAddressParameters.Remove('FailoverClusterIPAddress')
                        $invalidAddressParameters += @{
                            FailoverClusterIPAddress = '192.168.0.100'
                        }

                        { Set-TargetResource @invalidAddressParameters } | Should Throw 'Unable to map the specified IP Address(es) to valid cluster networks.'
                    }

                    It 'Should throw an error when an invalid IP Address is specified for a multi-subnet instance' {
                        $invalidAddressParameters = $testParameters.Clone()

                        $invalidAddressParameters.Remove('FailoverClusterIPAddress')
                        $invalidAddressParameters += @{
                            FailoverClusterIPAddress = @('10.0.0.100','192.168.0.100')
                        }

                        { Set-TargetResource @invalidAddressParameters } | Should Throw 'Unable to map the specified IP Address(es) to valid cluster networks.'
                    }

                    It 'Should build a valid IP address string for a single address' {

                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Action = 'InstallFailoverCluster'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should build a valid IP address string for a multi-subnet cluster' {
                        $multiSubnetParameters = $testParameters.Clone()
                        $multiSubnetParameters.Remove('FailoverClusterIPAddress')
                        $multiSubnetParameters += @{
                            FailoverClusterIPAddress = ($mockClusterSites | ForEach-Object { $_.Address })
                        }

                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_MultiSite
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Action = 'InstallFailoverCluster'
                        }

                        { Set-TargetResource @multiSubnetParameters } | Should Not Throw
                    }

                    It 'Should pass proper parameters to setup when Cluster Shared volumes are specified' {
                        $csvTestParameters = $testParameters.Clone()

                        $csvTestParameters['InstallSQLDataDir'] = $mockCSVClusterDiskMap['SysData'].Path
                        $csvTestParameters['SQLUserDBDir'] = $mockCSVClusterDiskMap['UserData'].Path
                        $csvTestParameters['SQLUserDBLogDir'] = $mockCSVClusterDiskMap['UserLogs'].Path
                        $csvTestParameters['SQLTempDBDir'] = $mockCSVClusterDiskMap['TempDBData'].Path
                        $csvTestParameters['SQLTempDBLogDir'] = $mockCSVClusterDiskMap['TempDBLogs'].Path
                        $csvTestParameters['SQLBackupDir'] = $mockCSVClusterDiskMap['Backup'].Path

                        $mockStartWin32ProcessExpectedArgument = @{
                            IAcceptSQLServerLicenseTerms = 'True'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Quiet = 'True'
                            SQLSysAdminAccounts = 'COMPANY\sqladmin'
                            Action = 'InstallFailoverCluster'
                            InstanceName = 'MSSQLSERVER'
                            Features = 'SQLEngine'
                            FailoverClusterDisks = "$($mockCSVClusterDiskMap['Backup'].Name); $($mockCSVClusterDiskMap['UserData'].Name); $($mockCSVClusterDiskMap['UserLogs'].Name); $($mockCSVClusterDiskMap['SysData'].Name); $($mockCSVClusterDiskMap['TempDBData'].Name); $($mockCSVClusterDiskMap['TempDBLogs'].Name)"
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            FailoverClusterGroup = 'SQL Server (MSSQLSERVER)'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = $mockCSVClusterDiskMap['SysData'].Path
                            SQLUserDBDir = $mockCSVClusterDiskMap['UserData'].Path
                            SQLUserDBLogDir = $mockCSVClusterDiskMap['UserLogs'].Path
                            SQLTempDBDir = $mockCSVClusterDiskMap['TempDBData'].Path
                            SQLTempDBLogDir = $mockCSVClusterDiskMap['TempDBLogs'].Path
                            SQLBackupDir = $mockCSVClusterDiskMap['Backup'].Path
                        }

                        { Set-TargetResource @csvTestParameters } | Should Not Throw
                    }

                    It 'Should pass proper parameters to setup when Cluster Shared volumes are specified and are the same for one or more parameter values' {
                        $csvTestParameters = $testParameters.Clone()

                        $csvTestParameters['InstallSQLDataDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\Data'
                        $csvTestParameters['SQLUserDBDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\Data'
                        $csvTestParameters['SQLUserDBLogDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\Logs'
                        $csvTestParameters['SQLTempDBDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\TEMPDB'
                        $csvTestParameters['SQLTempDBLogDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\TEMPDBLOG'
                        $csvTestParameters['SQLBackupDir'] = $mockCSVClusterDiskMap['Backup'].Path + '\Backup'

                        $mockStartWin32ProcessExpectedArgument = @{
                            IAcceptSQLServerLicenseTerms = 'True'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Quiet = 'True'
                            SQLSysAdminAccounts = 'COMPANY\sqladmin'
                            Action = 'InstallFailoverCluster'
                            InstanceName = 'MSSQLSERVER'
                            Features = 'SQLEngine'
                            FailoverClusterDisks = "$($mockCSVClusterDiskMap['Backup'].Name); $($mockCSVClusterDiskMap['UserData'].Name)"
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            FailoverClusterGroup = 'SQL Server (MSSQLSERVER)'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = "$($mockCSVClusterDiskMap['UserData'].Path)\Data"
                            SQLUserDBDir = "$($mockCSVClusterDiskMap['UserData'].Path)\Data"
                            SQLUserDBLogDir = "$($mockCSVClusterDiskMap['UserData'].Path)\Logs"
                            SQLTempDBDir = "$($mockCSVClusterDiskMap['UserData'].Path)\TEMPDB"
                            SQLTempDBLogDir = "$($mockCSVClusterDiskMap['UserData'].Path)\TEMPDBLOG"
                            SQLBackupDir = "$($mockCSVClusterDiskMap['Backup'].Path)\Backup"
                        }

                        { Set-TargetResource @csvTestParameters } | Should Not Throw
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state and the action is PrepareFailoverCluster" {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters.Remove('SourceCredential')
                        $testParameters.Remove('ASSysAdminAccounts')

                        $testParameters += @{
                            Features = 'SQLENGINE'
                            InstanceName = 'MSSQLSERVER'
                            SourcePath = $mockSourcePath
                            Action = 'PrepareFailoverCluster'
                        }

                        Mock -CommandName NetUse -Verifiable
                        Mock -CommandName Copy-ItemWithRoboCopy -Verifiable
                        Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable

                        Mock -CommandName StartWin32Process -MockWith $mockStartWin32Process -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith {} -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_ResourceGroup') -and ($Filter -eq "Name = 'Available Storage'")
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith {} -ParameterFilter {
                            ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
                        } -Verfiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith {} -ParameterFilter {
                            $Association -eq 'MSCluster_ResourceToPossibleOwner'
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith {} -ParameterFilter {
                            $ResultClass -eq 'MSCluster_DiskPartition'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith {} -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
                        } -Verifiable
                    }

                    It 'Should pass correct arguments to the setup process' {

                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            Action = 'PrepareFailoverCluster'
                            SkipRules = 'Cluster_VerifyForErrors'
                        }
                        $mockStartWin32ProcessExpectedArgument.Remove('FailoverClusterGroup')
                        $mockStartWin32ProcessExpectedArgument.Remove('SQLSysAdminAccounts')

                        { Set-TargetResource @testParameters } | Should Not throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and
                            ($Name -eq $mockDefaultInstance_InstanceName)
                        } -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_ResourceGroup') -and ($Filter -eq "Name = 'Available Storage'")
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter {
                            ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter {
                            $Association -eq 'MSCluster_ResourceToPossibleOwner'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter {
                            $ResultClass -eq 'MSCluster_DiskPartition'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
                        } -Exactly -Times 0 -Scope It
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state and the action is CompleteFailoverCluster." {
                    BeforeEach {
                        $mockDynamicSqlDataDirectoryPath = $mockSqlDataDirectoryPath
                        $mockDynamicSqlUserDatabasePath = $mockSqlUserDatabasePath
                        $mockDynamicSqlUserDatabaseLogPath = $mockSqlUserDatabaseLogPath
                        $mockDynamicSqlTempDatabasePath = $mockSqlTempDatabasePath
                        $mockDynamicSqlTempDatabaseLogPath = $mockSqlTempDatabaseLogPath
                        $mockDynamicSqlBackupPath = $mockSqlBackupPath

                        $testParameters = $mockDefaultClusterParameters.Clone()
                        $testParameters += @{
                            InstanceName = 'MSSQLSERVER'
                            SourcePath = $mockSourcePath
                            Action = 'CompleteFailoverCluster'
                            FailoverClusterGroupName = 'SQL Server (MSSQLSERVER)'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress

                            # Ensure we use "clustered" disks for our paths
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDbDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDbLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                        }
                    }

                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage -ParameterFilter {
                            $Filter -eq "Name = 'Available Storage'"
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource -ParameterFilter {
                            ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
                        } -Verfiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceToPossibleOwner -ParameterFilter {
                            $Association -eq 'MSCluster_ResourceToPossibleOwner'
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_DiskPartition -ParameterFilter {
                            $ResultClassName -eq 'MSCluster_DiskPartition'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterNetwork -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCIMInstance_MSCluster_ClusterSharedVolume -ParameterFilter {
                            $ClassName -eq 'MSCluster_ClusterSharedVolume'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCIMInstance_MSCluster_ClusterSharedVolumeToResource -ParameterFilter {
                            $ClassName -eq 'MSCluster_ClusterSharedVolumeToResource'
                        } -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                    }

                    It 'Should throw an error when one or more paths are not resolved to clustered storage' {
                        $badPathParameters = $testParameters.Clone()

                        # Pass in a bad path
                        $badPathParameters.SQLUserDBDir = 'C:\MSSQL\'

                        { Set-TargetResource @badPathParameters } | Should Throw 'Unable to map the specified paths to valid cluster storage. Drives mapped: Backup; SysData; TempDbData; TempDbLogs; UserLogs'
                    }

                    It 'Should properly map paths to clustered disk resources' {

                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            Action = 'CompleteFailoverCluster'
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                            SkipRules = 'Cluster_VerifyForErrors'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should build a DEFAULT address string when no network is specified' {
                        $missingNetworkParams = $testParameters.Clone()
                        $missingNetworkParams.Remove('FailoverClusterIPAddress')

                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            Action = 'CompleteFailoverCluster'
                            FailoverClusterIPAddresses = 'DEFAULT'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                            SkipRules = 'Cluster_VerifyForErrors'
                        }

                        { Set-TargetResource @missingNetworkParams } | Should Not Throw
                    }

                    It 'Should throw an error when an invalid IP Address is specified' {
                        $invalidAddressParameters = $testParameters.Clone()

                        $invalidAddressParameters.Remove('FailoverClusterIPAddress')
                        $invalidAddressParameters += @{
                            FailoverClusterIPAddress = '192.168.0.100'
                        }

                        { Set-TargetResource @invalidAddressParameters } | Should Throw 'Unable to map the specified IP Address(es) to valid cluster networks.'
                    }

                    It 'Should throw an error when an invalid IP Address is specified for a multi-subnet instance' {
                        $invalidAddressParameters = $testParameters.Clone()

                        $invalidAddressParameters.Remove('FailoverClusterIPAddress')
                        $invalidAddressParameters += @{
                            FailoverClusterIPAddress = @('10.0.0.100','192.168.0.100')
                        }

                        { Set-TargetResource @invalidAddressParameters } | Should Throw 'Unable to map the specified IP Address(es) to valid cluster networks.'
                    }

                    It 'Should build a valid IP address string for a single address' {

                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Action = 'CompleteFailoverCluster'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should build a valid IP address string for a multi-subnet cluster' {
                        $multiSubnetParameters = $testParameters.Clone()
                        $multiSubnetParameters.Remove('FailoverClusterIPAddress')
                        $multiSubnetParameters += @{
                            FailoverClusterIPAddress = ($mockClusterSites | ForEach-Object { $_.Address })
                        }

                        $mockStartWin32ProcessExpectedArgument = $mockStartWin32ProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartWin32ProcessExpectedArgument += @{
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_MultiSite
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Action = 'CompleteFailoverCluster'
                        }

                        { Set-TargetResource @multiSubnetParameters } | Should Not Throw
                    }

                    It 'Should pass proper parameters to setup' {
                        $mockStartWin32ProcessExpectedArgument = @{
                            IAcceptSQLServerLicenseTerms = 'True'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Quiet = 'True'
                            SQLSysAdminAccounts = 'COMPANY\sqladmin'

                            Action = 'CompleteFailoverCluster'
                            InstanceName = 'MSSQLSERVER'
                            Features = 'SQLEngine'
                            FailoverClusterDisks = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                            FailoverClusterIPAddresses = $mockDefaultInstance_FailoverClusterIPAddressParameter_SingleSite
                            FailoverClusterGroup = 'SQL Server (MSSQLSERVER)'
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            InstallSQLDataDir = $mockDynamicSqlDataDirectoryPath
                            SQLUserDBDir = $mockDynamicSqlUserDatabasePath
                            SQLUserDBLogDir = $mockDynamicSqlUserDatabaseLogPath
                            SQLTempDBDir = $mockDynamicSqlTempDatabasePath
                            SQLTempDBLogDir = $mockDynamicSqlTempDatabaseLogPath
                            SQLBackupDir = $mockDynamicSqlBackupPath
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }
                }

            }

            Assert-VerifiableMocks
        }

        # Tests only the parts of the code that does not already get tested thru the other tests.
        Describe 'Copy-ItemWithRoboCopy' -Tag 'Helper' {
            Context 'When Copy-ItemWithRoboCopy is called it should return the correct arguments' {
                BeforeEach {
                    Mock -CommandName Get-Command -MockWith $mockGetCommand -Verifiable
                    Mock -CommandName Start-Process -MockWith $mockStartProcess -Verifiable
                }


                It 'Should use Unbuffered IO when copying' {
                    $mockRobocopyExectuableVersion = $mockRobocopyExectuableVersionWithUnbufferedIO

                    $mockStartProcessExpectedArgument =
                        $mockRobocopyArgumentSourcePath,
                        $mockRobocopyArgumentDestinationPath,
                        $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty,
                        $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                        $mockRobocopyArgumentUseUnbufferedIO,
                        $mockRobocopyArgumentSilent -join ' '

                    $copyItemWithRoboCopyParameter = @{
                        Path = $mockRobocopyArgumentSourcePath
                        DestinationPath = $mockRobocopyArgumentDestinationPath
                    }

                    { Copy-ItemWithRoboCopy @copyItemWithRoboCopyParameter } | Should Not Throw

                    Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                }

                It 'Should not use Unbuffered IO when copying' {
                    $mockRobocopyExectuableVersion = $mockRobocopyExectuableVersionWithoutUnbufferedIO

                    $mockStartProcessExpectedArgument =
                        $mockRobocopyArgumentSourcePath,
                        $mockRobocopyArgumentDestinationPath,
                        $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty,
                        $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                        '',
                        $mockRobocopyArgumentSilent -join ' '

                    $copyItemWithRoboCopyParameter = @{
                        Path = $mockRobocopyArgumentSourcePath
                        DestinationPath = $mockRobocopyArgumentDestinationPath
                    }

                    { Copy-ItemWithRoboCopy @copyItemWithRoboCopyParameter } | Should Not Throw

                    Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Copy-ItemWithRoboCopy throws an exception it should return the correct error messages' {
                BeforeEach {
                    $mockRobocopyExectuableVersion = $mockRobocopyExectuableVersionWithUnbufferedIO

                    Mock -CommandName Get-Command -MockWith $mockGetCommand -Verifiable
                    Mock -CommandName Start-Process -MockWith $mockStartProcess_WithExitCode -Verifiable
                }

                It 'Should throw the correct error message when error code is 8' {
                    $mockStartProcessExitCode = 8

                    $copyItemWithRoboCopyParameter = @{
                        Path = $mockRobocopyArgumentSourcePath
                        DestinationPath = $mockRobocopyArgumentDestinationPath
                    }

                    { Copy-ItemWithRoboCopy @copyItemWithRoboCopyParameter } | Should Throw "Robocopy reported errors when copying files. Error code: $mockStartProcessExitCode."

                    Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                }

                It 'Should throw the correct error message when error code is 16' {
                    $mockStartProcessExitCode = 16

                    $copyItemWithRoboCopyParameter = @{
                        Path = $mockRobocopyArgumentSourcePath
                        DestinationPath = $mockRobocopyArgumentDestinationPath
                    }

                    { Copy-ItemWithRoboCopy @copyItemWithRoboCopyParameter } | Should Throw "Robocopy reported errors when copying files. Error code: $mockStartProcessExitCode."

                    Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                }

                It 'Should throw the correct error message when error code is greater than 7 (but not 8 or 16)' {
                    $mockStartProcessExitCode = 9

                    $copyItemWithRoboCopyParameter = @{
                        Path = $mockRobocopyArgumentSourcePath
                        DestinationPath = $mockRobocopyArgumentDestinationPath
                    }

                    { Copy-ItemWithRoboCopy @copyItemWithRoboCopyParameter } | Should Throw "Robocopy reported that failures occured when copying files. Error code: $mockStartProcessExitCode."

                    Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Copy-ItemWithRoboCopy is called and finishes succesfully it should return the correct exit code' {
                BeforeEach {
                    $mockRobocopyExectuableVersion = $mockRobocopyExectuableVersionWithUnbufferedIO

                    Mock -CommandName Get-Command -MockWith $mockGetCommand -Verifiable
                    Mock -CommandName Start-Process -MockWith $mockStartProcess_WithExitCode -Verifiable
                }

                It 'Should finish succesfully with exit code 1' {
                    $mockStartProcessExitCode = 1

                    $copyItemWithRoboCopyParameter = @{
                        Path = $mockRobocopyArgumentSourcePath
                        DestinationPath = $mockRobocopyArgumentDestinationPath
                    }

                    { Copy-ItemWithRoboCopy @copyItemWithRoboCopyParameter } | Should Not Throw

                    Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                }

                It 'Should finish succesfully with exit code 2' {
                    $mockStartProcessExitCode = 2

                    $copyItemWithRoboCopyParameter = @{
                        Path = $mockRobocopyArgumentSourcePath
                        DestinationPath = $mockRobocopyArgumentDestinationPath
                    }

                    { Copy-ItemWithRoboCopy @copyItemWithRoboCopyParameter } | Should Not Throw

                    Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                }

                It 'Should finish succesfully with exit code 3' {
                    $mockStartProcessExitCode = 3

                    $copyItemWithRoboCopyParameter = @{
                        Path = $mockRobocopyArgumentSourcePath
                        DestinationPath = $mockRobocopyArgumentDestinationPath
                    }

                    { Copy-ItemWithRoboCopy @copyItemWithRoboCopyParameter } | Should Not Throw

                    Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'Get-ServiceAccountParameters' -Tag 'Helper' {
            $serviceTypes = @('SQL','AGT','IS','RS','AS','FT')

            BeforeAll {
                $mockServiceAccountPassword = ConvertTo-SecureString 'Password' -AsPlainText -Force

                $mockSystemServiceAccount = (
                    New-Object System.Management.Automation.PSCredential 'NT AUTHORITY\SYSTEM', $mockServiceAccountPassword
                )

                $mockVirtualServiceAccount = (
                    New-Object System.Management.Automation.PSCredential 'NT SERVICE\MSSQLSERVER', $mockServiceAccountPassword
                )

                $mockManagedServiceAccount = (
                    New-Object System.Management.Automation.PSCredential 'COMPANY\ManagedAccount$', $mockServiceAccountPassword
                )

                $mockDomainServiceAccount = (
                    New-Object System.Management.Automation.PSCredential 'COMPANY\sql.service', $mockServiceAccountPassword
                )
            }

            $serviceTypes | ForEach-Object {

                $serviceType = $_

                Context "When service type is $serviceType" {

                    It "Should return the correct parameters when the account is a system account." {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockSystemServiceAccount -ServiceType $serviceType

                        $result.$("$($serviceType)SVCACCOUNT") | Should BeExactly $mockSystemServiceAccount.UserName
                        $result.ContainsKey("$($serviceType)SVCPASSWORD") | Should Be $false
                    }

                    It "Should return the correct parameters when the account is a virtual service account" {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockVirtualServiceAccount -ServiceType $serviceType

                        $result.$("$($serviceType)SVCACCOUNT") | Should BeExactly $mockVirtualServiceAccount.UserName
                        $result.ContainsKey("$($serviceType)SVCPASSWORD") | Should Be $false
                    }

                    It "Should return the correct parameters when the account is a managed service account" {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockManagedServiceAccount -ServiceType $serviceType

                        $result.$("$($serviceType)SVCACCOUNT") | Should BeExactly $mockManagedServiceAccount.UserName
                        $result.ContainsKey("$($serviceType)SVCPASSWORD") | Should Be $false
                    }

                    It "Should return the correct parameters when the account is a domain account" {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockDomainServiceAccount -ServiceType $serviceType

                        $result.$("$($serviceType)SVCACCOUNT") | Should BeExactly $mockDomainServiceAccount.UserName
                        $result.$("$($serviceType)SVCPASSWORD") | Should BeExactly $mockDomainServiceAccount.GetNetworkCredential().Password
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
