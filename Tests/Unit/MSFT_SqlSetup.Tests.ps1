<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlSetup DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName      = 'SqlServerDsc'
$script:dscResourceName    = 'MSFT_SqlSetup'

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
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
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

    InModuleScope $script:dscResourceName {
        <#
            .SYNOPSIS
                Used to test arguments passed to Start-SqlSetupProcess while inside and It-block.

                This function must be called inside a Mock, since it depends being run inside an It-block.

            .PARAMETER Argument
                A string containing all the arguments separated with space and each argument should start with '/'.
                Only the first string in the array is evaluated.

            .PARAMETER ExpectedArgument
                A hash table containing all the expected arguments.
        #>
        function Test-SetupArgument
        {
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $Argument,

                [Parameter(Mandatory = $true)]
                [System.Collections.Hashtable]
                $ExpectedArgument
            )

            $argumentHashTable = @{}

            # Break the argument string into a hash table
            ($Argument -split ' ?/') | ForEach-Object {
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

                    $argumentHashTable.Add($key, $value)
                }
            }

            $actualValues = $argumentHashTable.Clone()

            # Limit the output in the console when everything is fine.
            if ($actualValues.Count -ne $ExpectedArgument.Count)
            {
                Write-Warning -Message 'Verified the setup argument count (expected vs actual)'
                Write-Warning -Message ('Expected: {0}' -f ($ExpectedArgument.Keys -join ','))
                Write-Warning -Message ('Actual: {0}' -f ($actualValues.Keys -join ','))
            }

            # Start by checking whether we have the same number of parameters
            $actualValues.Count | Should -Be $ExpectedArgument.Count `
                -Because ('the expected arguments was: {0}' -f ($ExpectedArgument.Keys -join ','))

            Write-Verbose -Message 'Verified actual setup argument values against expected setup argument values' -Verbose

            foreach ($argumentKey in $ExpectedArgument.Keys)
            {
                $argumentKeyName = $actualValues.GetEnumerator() |
                    Where-Object -FilterScript {
                        $_.Name -eq $argumentKey
                    } | Select-Object -ExpandProperty 'Name'

                $argumentKeyName | Should -Be $argumentKey

                $argumentValue = $actualValues.$argumentKey
                $argumentValue | Should -Be $ExpectedArgument.$argumentKey
            }
        }

        # Testing each supported SQL Server version
        $testProductVersion = @(
            14, # SQL Server 2017
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
        $mockSetupCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockmockSetupCredentialUserName, $mockmockSetupCredentialPassword)

        $mockSqlServiceAccount = 'COMPANY\SqlAccount'
        $mockSqlServicePassword = 'Sqls3v!c3P@ssw0rd'
        $mockSQLServiceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockSqlServiceAccount,($mockSQLServicePassword | ConvertTo-SecureString -AsPlainText -Force))
        $mockAgentServiceAccount = 'COMPANY\AgentAccount'
        $mockAgentServicePassword = 'Ag3ntP@ssw0rd'
        $mockSQLAgentCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockAgentServiceAccount,($mockAgentServicePassword | ConvertTo-SecureString -AsPlainText -Force))
        $mockAnalysisServiceAccount = 'COMPANY\AnalysisAccount'
        $mockAnalysisServicePassword = 'Analysiss3v!c3P@ssw0rd'
        $mockAnalysisServiceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockAnalysisServiceAccount,($mockAnalysisServicePassword | ConvertTo-SecureString -AsPlainText -Force))

        $mockAgtSvcStartupMode = 'Auto'
        $mockAsSvcStartupMode = 'Auto'
        $mockIsSvcStartupMode = 'Auto'
        $mockRsSvcStartupMode = 'Auto'

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
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockSqlSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_AgentService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockAgtSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_FullTextService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockSqlSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_ReportingService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockSqlSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_IntegrationService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockSqlSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_AnalysisService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockSqlSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetService_DefaultInstance = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockSqlSvcStartupMode -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockAgtSvcStartupMode -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockRsSvcStartupMode -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockIsSvcStartupMode -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockAsSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_DatabaseService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockSqlSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_AgentService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockAgtSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_FullTextService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_ReportingService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockRsSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_IntegrationService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockNamedInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockIsSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_AnalysisService = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockAsSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetService_NamedInstance = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockSqlSvcStartupMode -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockAgtSvcStartupMode -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockRsSvcStartupMode -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockNamedInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockIsSvcStartupMode -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value $mockAsSvcStartupMode -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_InstanceId_ConfigurationState = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'SQL_Replication_Core_Inst' -Value 1 -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_DQFeature = {
            return @(
                (
                    New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'DQ_Components' -Value 1 -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SqlVersion_ConfigurationState = {
            return @(
                (
                    New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'SQL_BOL_Components' -Value 1 -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'SQL_DQ_CLIENT_Full' -Value 1 -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'MDSCoreFeature' -Value 1 -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ClientComponentsFull_FeatureList = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'FeatureList' -Value 'Connectivity_Full=3 SQL_SSMS_Full=3 Tools_Legacy_Full=3 Connectivity_FNS=3 SQL_Tools_Standard_FNS=3 Tools_Legacy_FNS=3 SDK_Full=3 SDK_FNS=3' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ClientComponentsFull_EmptyFeatureList = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'FeatureList' -Value '' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name $mockDefaultInstance_InstanceName -Value $mockDefaultInstance_InstanceId -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name $mockNamedInstance_InstanceName -Value $mockNamedInstance_InstanceId -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SharedDirectory = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name '28A1158CDF9ED6B41B2B7358982D4BA8' -Value $mockSqlSharedDirectory -PassThru -Force
                )
            )
        }

        $mockGetItem_SharedDirectory = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Property' -Value '28A1158CDF9ED6B41B2B7358982D4BA8' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SharedWowDirectory = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name '28A1158CDF9ED6B41B2B7358982D4BA8' -Value $mockSqlSharedWowDirectory -PassThru -Force
                )
            )
        }

        $mockGetItem_SharedWowDirectory = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Property' -Value '28A1158CDF9ED6B41B2B7358982D4BA8' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_Setup = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'SqlProgramDir' -Value $mockSqlProgramDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ServicesAnalysis = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'ImagePath' -Value ('"C:\Program Files\Microsoft SQL Server\OLAP\bin\msmdsrv.exe" -s "{0}"' -f $mockSqlAnalysisConfigDirectory) -PassThru -Force
                )
            )
        }

        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'LoginMode' -Value $mockSqlLoginMode -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Collation' -Value $mockSqlCollation -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstallDataDirectory' -Value $mockSqlInstallPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'BackupDirectory' -Value $mockDynamicSqlBackupPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBDir' -Value $mockDynamicSqlTempDatabasePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBLogDir' -Value $mockDynamicSqlTempDatabaseLogPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultFile' -Value $mockSqlDefaultDatabaseFilePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultLog' -Value $mockSqlDefaultDatabaseLogPath -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Logins -Value {
                            return @( ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockSqlSystemAdministrator -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name ListMembers -Value {
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
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'LoginMode' -Value $mockSqlLoginMode -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Collation' -Value $mockSqlCollation -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstallDataDirectory' -Value $mockSqlInstallPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'BackupDirectory' -Value $mockDynamicSqlBackupPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBDir' -Value $mockDynamicSqlTempDatabasePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBLogDir' -Value $mockDynamicSqlTempDatabaseLogPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultFile' -Value $mockSqlDefaultDatabaseFilePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultLog' -Value $mockSqlDefaultDatabaseLogPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsClustered' -Value $true -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Logins -Value {
                            return @( ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockSqlSystemAdministrator -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name ListMembers -Value {
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
                    New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name ServerProperties -Value {
                            return @{
                                'CollationName' = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockSqlAnalysisCollation -PassThru -Force )
                                'DataDir' = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockSqlAnalysisDataDirectory -PassThru -Force )
                                'TempDir' = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockSqlAnalysisTempDirectory -PassThru -Force )
                                'LogDir' = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockSqlAnalysisLogDirectory -PassThru -Force )
                                'BackupDir' = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockSqlAnalysisBackupDirectory -PassThru -Force )
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Roles -Value {
                            return @{
                                'Administrators' = @( New-Object -TypeName Object |
                                    Add-Member -MemberType ScriptProperty -Name Members -Value {
                                        return New-Object -TypeName Object |
                                            Add-Member -MemberType ScriptProperty -Name Name -Value {
                                                return $mockDynamicSqlAnalysisAdmins
                                            } -PassThru -Force
                                    } -PassThru -Force
                                ) }
                        } -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'ServerMode' -Value $mockDynamicAnalysisServerMode -PassThru -Force
                )
            )
        }

        $mockSourcePathUNCWithoutLeaf = '\\server\share'
        $mockSourcePathGuid = 'cc719562-0f46-4a16-8605-9f8a47c70402'

        $mockNewTemporaryFolder = {
            return $mockSourcePathUNC
        }

        $mockGetCimInstance_MSClusterResource = {
            return @(
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource','root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server ($mockCurrentInstanceName)" -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                            InstanceName = $mockCurrentInstanceName
                        } -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage = {
            return @(
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ResourceGroup', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Available Storage' -PassThru -Force
                )
            )
        }

        $mockGetCIMInstance_MSCluster_ClusterSharedVolume = {
            return @(
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['SysData'].Path -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['UserData'].Path -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['UserLogs'].Path -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['TempDBData'].Path -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['TempDBLogs'].Path -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCSVClusterDiskMap['Backup'].Path -PassThru -Force
                )
            )
        }

        $mockGetCIMInstance_MSCluster_ClusterSharedVolumeToResource = {
            return @(
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['SysData'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['SysData'].Name}) -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['UserData'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['UserData'].Name}) -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['UserLogs'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['UserLogs'].Name}) -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['TempDBData'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['TempDBData'].Name}) -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['TempDBLogs'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['TempDBLogs'].Name}) -PassThru -Force
                ),
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['Backup'].Path}) -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{Name=$mockCSVClusterDiskMap['Backup'].Name}) -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_MSClusterNetwork = {
            return @(
                (
                    $mockClusterSites | ForEach-Object {
                        $network = $_

                        New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Network', 'root/MSCluster' |
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
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ResourceGroup', 'root/MSCluster' |
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
                                $propertyValue.Value = @{
                                    DnsName = $mockDefaultInstance_FailoverClusterNetworkName
                                }
                            }

                            'IP Address'
                            {
                                $propertyValue.Value = @{
                                    Address = $mockDefaultInstance_FailoverClusterIPAddress
                                }
                            }
                        }

                        return New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource', 'root/MSCluster' |
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
                        New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource','root/MSCluster' |
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
                        New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Node', 'root/MSCluster' |
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
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_DiskPartition','root/MSCluster' |
                        Add-Member -MemberType NoteProperty -Name 'Path' -Value $clusterDiskPath -PassThru -Force
                )
            )
        }

        <#
        Needed a way to see into the Set-method for the arguments the Set-method is building and sending to 'setup.exe', and fail
        the test if the arguments is different from the expected arguments.
        Solved this by dynamically set the expected arguments before each It-block. If the arguments differs the mock of
        Start-SqlSetupProcess throws an error message, similar to what Pester would have reported (expected -> but was).
        #>
        $mockStartSqlSetupProcessExpectedArgument = @{}

        $mockStartSqlSetupProcessExpectedArgumentClusterDefault = @{
            IAcceptSQLServerLicenseTerms = 'True'
            Quiet = 'True'
            InstanceName = 'MSSQLSERVER'
            Features = 'SQLENGINE'
            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
            FailoverClusterGroup = 'SQL Server (MSSQLSERVER)'
        }

        $mockStartSqlSetupProcess = {
            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcessExpectedArgument

            return 0
        }

        $mockDynamicSetupProcessExitCode = 0
        $mockStartSqlSetupProcess_WithDynamicExitCode = {
            return $mockDynamicSetupProcessExitCode
        }
        #endregion Function mocks

        <#
            These are written with both lower-case and upper-case to make sure we support that.
            The feature list must be written in the order it is returned by the function Get-TargetResource.
        #>
        $mockDefaultFeatures = 'SQLEngine,Replication,Dq,Dqc,FullText,Rs,As,Is,Bol,Conn,Bc,Sdk,Mds,Ssms,Adv_Ssms'

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            Features = $mockDefaultFeatures
        }

        $MockSqlSvcStartupType = 'Automatic'
        $MockAgtSvcStartupType = 'Automatic'
        $MockAsSvcStartupType = 'Automatic'
        $MockIsSvcStartupType = 'Automatic'
        $MockRsSvcStartupType = 'Automatic'

        $mockDefaultClusterParameters = @{
            SQLSysAdminAccounts = 'COMPANY\User1','COMPANY\SQLAdmins'

            # Feature support is tested elsewhere, so just include the minimum.
            Features = 'SQLEngine'
        }

        Describe 'SqlSetup\Get-TargetResource' -Tag 'Get' {
            #region Setting up TestDrive:\

            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            # UNC path to TestDrive:\
            $testDrive_DriveShare = (Split-Path -Path $mockSourcePath -Qualifier) -replace ':','$'
            $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $mockSourcePath -NoQualifier)

            #endregion Setting up TestDrive:\

            BeforeAll {
                # General mocks
                Mock -CommandName Get-SqlMajorVersion -MockWith $mockGetSqlMajorVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
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
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
                } -MockWith $mockGetItemProperty_SharedDirectory -Verifiable

                Mock -CommandName Get-Item -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
                } -MockWith $mockGetItem_SharedDirectory -Verifiable

                # Mocking SharedWowDirectory
                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4'
                } -MockWith $mockGetItemProperty_SharedWowDirectory -Verifiable

                Mock -CommandName Get-Item -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4'
                } -MockWith $mockGetItem_SharedWowDirectory -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                } -MockWith $mockGetItemProperty_ClientComponentsFull_FeatureList -Verifiable

                <#
                    This make sure the mock for Connect-SQLAnalysis get the correct
                    value for ServerMode property for the tests. It's dynamically
                    changed in other tests for testing different server modes.
                #>
                $mockDynamicAnalysisServerMode = 'MULTIDIMENSIONAL'
            }

            BeforeEach {
                Mock -CommandName Connect-SQLAnalysis -MockWith $mockConnectSQLAnalysis -Verifiable

                $testParameters = $mockDefaultParameters.Clone()
            }

            foreach ($version in $testProductVersion)
            {
                $mockSqlMajorVersion = $version

                $mockDefaultInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockDefaultInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockDynamicSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockDynamicSqlTempDatabasePath = ''
                $mockDynamicSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                # This sets administrators dynamically in the mock Connect-SQLAnalysis.
                $mockDynamicSqlAnalysisAdmins = $mockSqlAnalysisAdmins

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016 and 2017
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts -Verifiable
                        }
                        else
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName Connect-UncPath -Verifiable
                        Mock -CommandName Disconnect-UncPath -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\DQ\*"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName Connect-UncPath -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Disconnect-UncPath -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 1 -Scope It

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
                        $result.Features | Should -Be ''
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should -Be $mockSourcePath
                        $result.InstanceName | Should -Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should -BeNullOrEmpty
                        $result.InstallSharedDir | Should -BeNullOrEmpty
                        $result.InstallSharedWOWDir | Should -BeNullOrEmpty
                        $result.SQLSvcAccountUsername | Should -BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should -BeNullOrEmpty
                        $result.SqlCollation | Should -BeNullOrEmpty
                        $result.SQLSysAdminAccounts | Should -BeNullOrEmpty
                        $result.SecurityMode | Should -BeNullOrEmpty
                        $result.InstallSQLDataDir | Should -BeNullOrEmpty
                        $result.SQLUserDBDir | Should -BeNullOrEmpty
                        $result.SQLUserDBLogDir | Should -BeNullOrEmpty
                        $result.SQLBackupDir | Should -BeNullOrEmpty
                        $result.FTSvcAccountUsername | Should -BeNullOrEmpty
                        $result.RSSvcAccountUsername | Should -BeNullOrEmpty
                        $result.ASSvcAccountUsername | Should -BeNullOrEmpty
                        $result.ASCollation | Should -BeNullOrEmpty
                        $result.ASSysAdminAccounts | Should -BeNullOrEmpty
                        $result.ASDataDir | Should -BeNullOrEmpty
                        $result.ASLogDir | Should -BeNullOrEmpty
                        $result.ASBackupDir | Should -BeNullOrEmpty
                        $result.ASTempDir | Should -BeNullOrEmpty
                        $result.ASConfigDir | Should -BeNullOrEmpty
                        $result.ASServerMode | Should -BeNullOrEmpty
                        $result.ISSvcAccountUsername | Should -BeNullOrEmpty
                    }
                }

                if ($mockSqlMajorVersion -in (14))
                {
                    Context 'When using feature flag DetectionSharedFeatures' {
                        Context "When SQL Server version is $mockSqlMajorVersion and the system is in the desired state for default instance" {
                            BeforeEach {
                                $testParameters.Remove('Features')
                                $testParameters += @{
                                    InstanceName = $mockDefaultInstance_InstanceName
                                    SourceCredential = $null
                                    SourcePath = $mockSourcePath
                                    FeatureFlag = @('DetectionSharedFeatures')
                                }

                                Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                                    return @(
                                        'DQC'
                                        'BOL'
                                        'CONN'
                                        'BC'
                                        'SDK'
                                        'MDS'
                                    )
                                } -Verifiable

                                Mock -CommandName Connect-UncPath -Verifiable
                                Mock -CommandName Disconnect-UncPath -Verifiable
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

                                Mock -CommandName Get-ItemProperty -ParameterFilter {
                                    $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                                } -MockWith $mockGetItemProperty_InstanceId_ConfigurationState -Verifiable

                                # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
                                Mock -CommandName Get-CimInstance -MockWith {
                                    throw "Mock Get-CimInstance was called with unexpected parameters. ClassName=$ClassName, Filter=$Filter"
                                } -Verifiable
                                #endregion Mock Get-CimInstance

                                Mock -CommandName Get-ItemProperty -ParameterFilter {
                                    $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                                } -MockWith $mockGetItemProperty_InstanceId_ConfigurationState -Verifiable

                                Mock -CommandName Get-ItemProperty -ParameterFilter {
                                    $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\DQ\*"
                                } -MockWith $mockGetItemProperty_DQFeature -Verifiable

                                Mock -CommandName Get-ItemProperty -ParameterFilter {
                                    $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                                } -MockWith $mockGetItemProperty_Setup -Verifiable
                            }

                            It 'Should return the same values as passed as parameters' {
                                $result = Get-TargetResource @testParameters
                                $result.InstanceName | Should -Be $testParameters.InstanceName

                                Assert-MockCalled -CommandName Connect-UncPath -Exactly -Times 0 -Scope It
                                Assert-MockCalled -CommandName Disconnect-UncPath -Exactly -Times 0 -Scope It
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
                                } -Exactly -Times 0 -Scope It

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

                                $result.Features | Should -Be 'SQLENGINE,REPLICATION,DQ,FULLTEXT,RS,AS,IS,DQC,BOL,CONN,BC,SDK,MDS'
                            }

                            It 'Should return the correct values in the hash table' {
                                $result = Get-TargetResource @testParameters
                                $result.SourcePath | Should -Be $mockSourcePath
                                $result.InstanceName | Should -Be $mockDefaultInstance_InstanceName
                                $result.InstanceID | Should -Be $mockDefaultInstance_InstanceName
                                $result.InstallSharedDir | Should -Be $mockSqlSharedDirectory
                                $result.InstallSharedWOWDir | Should -Be $mockSqlSharedWowDirectory
                                $result.SQLSvcAccountUsername | Should -Be $mockSqlServiceAccount
                                $result.AgtSvcAccountUsername | Should -Be $mockAgentServiceAccount
                                $result.SqlCollation | Should -Be $mockSqlCollation
                                $result.SQLSysAdminAccounts | Should -Be $mockSqlSystemAdministrator
                                $result.SecurityMode | Should -Be 'Windows'
                                $result.InstallSQLDataDir | Should -Be $mockSqlInstallPath
                                $result.SQLUserDBDir | Should -Be $mockSqlDefaultDatabaseFilePath
                                $result.SQLUserDBLogDir | Should -Be $mockSqlDefaultDatabaseLogPath
                                $result.SQLBackupDir | Should -Be $mockDynamicSqlBackupPath
                                $result.FTSvcAccountUsername | Should -Be $mockSqlServiceAccount
                                $result.RSSvcAccountUsername | Should -Be $mockSqlServiceAccount
                                $result.ASSvcAccountUsername | Should -Be $mockSqlServiceAccount
                                $result.ASCollation | Should -Be $mockSqlAnalysisCollation
                                $result.ASSysAdminAccounts | Should -Be $mockSqlAnalysisAdmins
                                $result.ASDataDir | Should -Be $mockSqlAnalysisDataDirectory
                                $result.ASLogDir | Should -Be $mockSqlAnalysisLogDirectory
                                $result.ASBackupDir | Should -Be $mockSqlAnalysisBackupDirectory
                                $result.ASTempDir | Should -Be $mockSqlAnalysisTempDirectory
                                $result.ASConfigDir | Should -Be $mockSqlAnalysisConfigDirectory
                                $result.ASServerMode | Should -Be 'MULTIDIMENSIONAL'
                                $result.ISSvcAccountUsername | Should -Be $mockSqlServiceAccount
                            }

                            $mockDynamicAnalysisServerMode = 'POWERPIVOT'

                            It 'Should return the correct values in the hash table' {
                                $result = Get-TargetResource @testParameters
                                $result.ASServerMode | Should -Be 'POWERPIVOT'
                            }

                            $mockDynamicAnalysisServerMode = 'TABULAR'

                            It 'Should return the correct values in the hash table' {
                                $result = Get-TargetResource @testParameters
                                $result.ASServerMode | Should -Be 'TABULAR'
                            }

                            # Return the state to the default for all other tests.
                            $mockDynamicAnalysisServerMode = 'MULTIDIMENSIONAL'

                            <#
                                This is a regression test for issue #691.
                                This sets administrators to only one for mock Connect-SQLAnalysis.
                            #>

                            $mockSqlAnalysisSingleAdministrator = 'COMPANY\AnalysisAdmin'
                            $mockDynamicSqlAnalysisAdmins = $mockSqlAnalysisSingleAdministrator

                            It 'Should return the correct type and value for property ASSysAdminAccounts' {
                                $result = Get-TargetResource @testParameters
                                Write-Output -NoEnumerate $result.ASSysAdminAccounts | Should -BeOfType [System.String[]]
                                $result.ASSysAdminAccounts | Should -Be $mockSqlAnalysisSingleAdministrator
                            }

                            # Setting back the default administrators for mock Connect-SQLAnalysis.
                            $mockDynamicSqlAnalysisAdmins = $mockSqlAnalysisAdmins
                        }
                    }
                }

                Context "When using SourceCredential parameter and SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }

                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts -Verifiable
                        }
                        else
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName Connect-UncPath -Verifiable
                        Mock -CommandName Disconnect-UncPath -Verifiable
                        Mock -CommandName Get-CimInstance -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\DQ\*"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 1 -Scope It

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

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -Verifiable

                        $result = Get-TargetResource @testParameters
                        $result.Features | Should -Be ''
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should -Be $mockSourcePathUNC
                        $result.InstanceName | Should -Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should -BeNullOrEmpty
                        $result.InstallSharedDir | Should -BeNullOrEmpty
                        $result.InstallSharedWOWDir | Should -BeNullOrEmpty
                        $result.SQLSvcAccountUsername | Should -BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should -BeNullOrEmpty
                        $result.SqlCollation | Should -BeNullOrEmpty
                        $result.SQLSysAdminAccounts | Should -BeNullOrEmpty
                        $result.SecurityMode | Should -BeNullOrEmpty
                        $result.InstallSQLDataDir | Should -BeNullOrEmpty
                        $result.SQLUserDBDir | Should -BeNullOrEmpty
                        $result.SQLUserDBLogDir | Should -BeNullOrEmpty
                        $result.SQLBackupDir | Should -BeNullOrEmpty
                        $result.FTSvcAccountUsername | Should -BeNullOrEmpty
                        $result.RSSvcAccountUsername | Should -BeNullOrEmpty
                        $result.ASSvcAccountUsername | Should -BeNullOrEmpty
                        $result.ASCollation | Should -BeNullOrEmpty
                        $result.ASSysAdminAccounts | Should -BeNullOrEmpty
                        $result.ASDataDir | Should -BeNullOrEmpty
                        $result.ASLogDir | Should -BeNullOrEmpty
                        $result.ASBackupDir | Should -BeNullOrEmpty
                        $result.ASTempDir | Should -BeNullOrEmpty
                        $result.ASConfigDir | Should -BeNullOrEmpty
                        $result.ISSvcAccountUsername | Should -BeNullOrEmpty
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for features 'CONN', 'SDK' and 'BC'" {
                    BeforeEach {
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -eq 10)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 11)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 12)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2014 -Verifiable
                        }

                        Mock -CommandName Connect-UncPath -Verifiable
                        Mock -CommandName Disconnect-UncPath -Verifiable
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
                        } -MockWith $mockGetItemProperty_InstanceId_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\DQ\*"
                        } -MockWith $mockGetItemProperty_DQFeature -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -MockWith $mockGetItemProperty_SqlVersion_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -MockWith $mockGetItemProperty_ClientComponentsFull_EmptyFeatureList -Verifiable
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            $result.Features | Should -Be 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,RS,AS,IS,BOL,MDS'
                        }
                        else
                        {
                            $result.Features | Should -Be 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,RS,AS,IS,BOL,MDS,SSMS,ADV_SSMS'
                        }
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -eq 10)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 11)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 12)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2014 -Verifiable
                        }

                        Mock -CommandName Connect-UncPath -Verifiable
                        Mock -CommandName Disconnect-UncPath -Verifiable
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
                        } -MockWith $mockGetItemProperty_InstanceId_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\DQ\*"
                        } -MockWith $mockGetItemProperty_DQFeature -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -MockWith $mockGetItemProperty_SqlVersion_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName Connect-UncPath -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Disconnect-UncPath -Exactly -Times 0 -Scope It
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

                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 0 -Scope It
                        }
                        else
                        {
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
                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            $featuresForSqlServer2016 = (($mockDefaultParameters.Features.ToUpper()) -replace 'SSMS,','') -replace ',ADV_SSMS',''
                            $result.Features | Should -Be $featuresForSqlServer2016
                        }
                        else
                        {
                            $result.Features | Should -Be $mockDefaultParameters.Features.ToUpper()
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should -Be $mockSourcePath
                        $result.InstanceName | Should -Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should -Be $mockDefaultInstance_InstanceName
                        $result.InstallSharedDir | Should -Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should -Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.AgtSvcAccountUsername | Should -Be $mockAgentServiceAccount
                        $result.SqlCollation | Should -Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should -Be $mockSqlSystemAdministrator
                        $result.SecurityMode | Should -Be 'Windows'
                        $result.InstallSQLDataDir | Should -Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should -Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should -Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should -Be $mockDynamicSqlBackupPath
                        $result.FTSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.RSSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.ASSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.ASCollation | Should -Be $mockSqlAnalysisCollation
                        $result.ASSysAdminAccounts | Should -Be $mockSqlAnalysisAdmins
                        $result.ASDataDir | Should -Be $mockSqlAnalysisDataDirectory
                        $result.ASLogDir | Should -Be $mockSqlAnalysisLogDirectory
                        $result.ASBackupDir | Should -Be $mockSqlAnalysisBackupDirectory
                        $result.ASTempDir | Should -Be $mockSqlAnalysisTempDirectory
                        $result.ASConfigDir | Should -Be $mockSqlAnalysisConfigDirectory
                        $result.ASServerMode | Should -Be 'MULTIDIMENSIONAL'
                        $result.ISSvcAccountUsername | Should -Be $mockSqlServiceAccount
                    }

                    $mockDynamicAnalysisServerMode = 'POWERPIVOT'

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.ASServerMode | Should -Be 'POWERPIVOT'
                    }

                    $mockDynamicAnalysisServerMode = 'TABULAR'

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.ASServerMode | Should -Be 'TABULAR'
                    }

                    # Return the state to the default for all other tests.
                    $mockDynamicAnalysisServerMode = 'MULTIDIMENSIONAL'

                    <#
                        This is a regression test for issue #691.
                        This sets administrators to only one for mock Connect-SQLAnalysis.
                    #>

                    $mockSqlAnalysisSingleAdministrator = 'COMPANY\AnalysisAdmin'
                    $mockDynamicSqlAnalysisAdmins = $mockSqlAnalysisSingleAdministrator

                    It 'Should return the correct type and value for property ASSysAdminAccounts' {
                        $result = Get-TargetResource @testParameters
                        Write-Output -NoEnumerate $result.ASSysAdminAccounts | Should -BeOfType [System.String[]]
                        $result.ASSysAdminAccounts | Should -Be $mockSqlAnalysisSingleAdministrator
                    }

                    # Setting back the default administrators for mock Connect-SQLAnalysis.
                    $mockDynamicSqlAnalysisAdmins = $mockSqlAnalysisAdmins
                }

                Context "When using SourceCredential parameter and SQL Server version is $mockSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }

                        if ($mockSqlMajorVersion -eq 10)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 11)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 12)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2014 -Verifiable
                        }

                        Mock -CommandName Connect-UncPath -Verifiable
                        Mock -CommandName Disconnect-UncPath -Verifiable
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
                        } -MockWith $mockGetItemProperty_InstanceId_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\DQ\*"
                        } -MockWith $mockGetItemProperty_DQFeature -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -MockWith $mockGetItemProperty_SqlVersion_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
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

                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 0 -Scope It
                        }
                        else
                        {
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
                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            $featuresForSqlServer2016 = (($mockDefaultParameters.Features.ToUpper()) -replace 'SSMS,','') -replace ',ADV_SSMS',''
                            $result.Features | Should -Be $featuresForSqlServer2016
                        }
                        else
                        {
                            $result.Features | Should -Be $mockDefaultParameters.Features.ToUpper()
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should -Be $mockSourcePathUNC
                        $result.InstanceName | Should -Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should -Be $mockDefaultInstance_InstanceName
                        $result.InstallSharedDir | Should -Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should -Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.AgtSvcAccountUsername | Should -Be $mockAgentServiceAccount
                        $result.SqlCollation | Should -Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should -Be $mockSqlSystemAdministrator
                        $result.SecurityMode | Should -Be 'Windows'
                        $result.InstallSQLDataDir | Should -Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should -Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should -Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should -Be $mockDynamicSqlBackupPath
                        $result.FTSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.RSSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.ASSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.ASCollation | Should -Be $mockSqlAnalysisCollation
                        $result.ASSysAdminAccounts | Should -Be $mockSqlAnalysisAdmins
                        $result.ASDataDir | Should -Be $mockSqlAnalysisDataDirectory
                        $result.ASLogDir | Should -Be $mockSqlAnalysisLogDirectory
                        $result.ASBackupDir | Should -Be $mockSqlAnalysisBackupDirectory
                        $result.ASTempDir | Should -Be $mockSqlAnalysisTempDirectory
                        $result.ASConfigDir | Should -Be $mockSqlAnalysisConfigDirectory
                        $result.ISSvcAccountUsername | Should -Be $mockSqlServiceAccount
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
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            # Mock this here to make sure we don't return any older components (<=2014) when testing SQL Server 2016
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts -Verifiable
                        }
                        else
                        {
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
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\DQ\*"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQLAnalysis -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\ConfigurationState"
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Exactly -Times 1 -Scope It

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
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -Verifiable

                        $result = Get-TargetResource @testParameters
                        $result.Features | Should -Be ''
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should -Be $mockSourcePath
                        $result.InstanceName | Should -Be $mockNamedInstance_InstanceName
                        $result.InstanceID | Should -BeNullOrEmpty
                        $result.InstallSharedDir | Should -BeNullOrEmpty
                        $result.InstallSharedWOWDir | Should -BeNullOrEmpty
                        $result.SQLSvcAccountUsername | Should -BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should -BeNullOrEmpty
                        $result.SqlCollation | Should -BeNullOrEmpty
                        $result.SQLSysAdminAccounts | Should -BeNullOrEmpty
                        $result.SecurityMode | Should -BeNullOrEmpty
                        $result.InstallSQLDataDir | Should -BeNullOrEmpty
                        $result.SQLUserDBDir | Should -BeNullOrEmpty
                        $result.SQLUserDBLogDir | Should -BeNullOrEmpty
                        $result.SQLBackupDir | Should -BeNullOrEmpty
                        $result.FTSvcAccountUsername | Should -BeNullOrEmpty
                        $result.RSSvcAccountUsername | Should -BeNullOrEmpty
                        $result.ASSvcAccountUsername | Should -BeNullOrEmpty
                        $result.ASCollation | Should -BeNullOrEmpty
                        $result.ASSysAdminAccounts | Should -BeNullOrEmpty
                        $result.ASDataDir | Should -BeNullOrEmpty
                        $result.ASLogDir | Should -BeNullOrEmpty
                        $result.ASBackupDir | Should -BeNullOrEmpty
                        $result.ASTempDir | Should -BeNullOrEmpty
                        $result.ASConfigDir | Should -BeNullOrEmpty
                        $result.ISSvcAccountUsername | Should -BeNullOrEmpty
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is in the desired state for named instance" {
                    BeforeEach {
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        if ($mockSqlMajorVersion -eq 10)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2008R2 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 11)
                        {
                            Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                            } -MockWith $mockGetItemProperty_UninstallProducts2012 -Verifiable
                        }

                        if ($mockSqlMajorVersion -eq 12)
                        {
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
                        } -MockWith $mockGetItemProperty_InstanceId_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\DQ\*"
                        } -MockWith $mockGetItemProperty_DQFeature -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                        } -MockWith $mockGetItemProperty_SqlVersion_ConfigurationState -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName

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

                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber) -or
                                $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                            } -Exactly -Times 0 -Scope It
                        }
                        else
                        {
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
                        if ($mockSqlMajorVersion -in (13,14))
                        {
                            $featuresForSqlServer2016 = (($mockDefaultParameters.Features.ToUpper()) -replace 'SSMS,','') -replace ',ADV_SSMS',''
                            $result.Features | Should -Be $featuresForSqlServer2016
                        }
                        else
                        {
                            $result.Features | Should -Be $mockDefaultParameters.Features.ToUpper()
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should -Be $mockSourcePath
                        $result.InstanceName | Should -Be $mockNamedInstance_InstanceName
                        $result.InstanceID | Should -Be $mockNamedInstance_InstanceName
                        $result.InstallSharedDir | Should -Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should -Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.AgtSvcAccountUsername | Should -Be $mockAgentServiceAccount
                        $result.SqlCollation | Should -Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should -Be $mockSqlSystemAdministrator
                        $result.SecurityMode | Should -Be 'Windows'
                        $result.InstallSQLDataDir | Should -Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should -Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should -Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should -Be $mockDynamicSqlBackupPath
                        $result.FTSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.RSSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.ASSvcAccountUsername | Should -Be $mockSqlServiceAccount
                        $result.ASCollation | Should -Be $mockSqlAnalysisCollation
                        $result.ASSysAdminAccounts | Should -Be $mockSqlAnalysisAdmins
                        $result.ASDataDir | Should -Be $mockSqlAnalysisDataDirectory
                        $result.ASLogDir | Should -Be $mockSqlAnalysisLogDirectory
                        $result.ASBackupDir | Should -Be $mockSqlAnalysisBackupDirectory
                        $result.ASTempDir | Should -Be $mockSqlAnalysisTempDirectory
                        $result.ASConfigDir | Should -Be $mockSqlAnalysisConfigDirectory
                        $result.ISSvcAccountUsername | Should -Be $mockSqlServiceAccount
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a clustered default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                        Mock -CommandName Get-CimInstance -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -Verifiable

                        Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty_Setup -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                    }

                    It 'Should not attempt to collect cluster information for a standalone instance' {
                        $currentState = Get-TargetResource @testParameters

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 0 -Scope It

                        $currentState.FailoverClusterGroupName | Should -BeNullOrEmpty
                        $currentState.FailoverClusterNetworkName | Should -BeNullOrEmpty
                        $currentState.FailoverClusterIPAddress | Should -BeNullOrEmpty
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is in the desired state for a clustered default instance" {

                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters.Remove('Features')
                        $testParameters += @{
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

                    It 'Should throw the correct error message when failover cluster resource cannot be found' {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return $null
                        } -Verifiable -ParameterFilter {
                            $Filter -eq "Type = 'SQL Server'"
                        }

                        { Get-TargetResource @testParameters } | Should -Throw 'Could not locate a SQL Server cluster resource for instance MSSQLSERVER.'

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -Scope It -ParameterFilter { $Filter -eq "Type = 'SQL Server'" }
                    }

                    It 'Should collect information for a clustered instance' {
                        $currentState = Get-TargetResource @testParameters

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -Scope It -ParameterFilter { $Filter -eq "Type = 'SQL Server'" }
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 1 -Scope It -ParameterFilter { $ResultClassName -eq 'MSCluster_ResourceGroup' }
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 2 -Scope It -ParameterFilter { $ResultClassName -eq 'MSCluster_Resource' }

                        $currentState.InstanceName | Should -Be $testParameters.InstanceName
                    }

                    It 'Should return correct cluster information' {
                        $currentState = Get-TargetResource @testParameters

                        $currentState.FailoverClusterGroupName | Should -Be $mockDefaultInstance_FailoverClusterGroupName
                        $currentState.FailoverClusterIPAddress | Should -Be $mockDefaultInstance_FailoverClusterIPAddress
                        $currentSTate.FailoverClusterNetworkName | Should -Be $mockDefaultInstance_FailoverClusterNetworkName
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "SqlSetup\Test-TargetResource" -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                Context 'When no features are installed' {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @testParameters -Verbose
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When a clustered instance cannot be found' {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                            FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                            FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                                FailoverClusterGroupName = $null
                                FailoverClusterNetworkName = $null
                                FailoverClusterIPAddress = $null
                            }
                        } -Verifiable
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @testParameters -Verbose
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When a SQL Server failover cluster is missing features' {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters['Features'] = 'SQLEngine,AS'
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                            FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                            FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                    Features = 'SQLENGINE' # Must be upper-case since Get-TargetResource returns upper-case.
                                    FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                                    FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                                    FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                                }
                        } -Verifiable
                    }

                    # This is a test for regression testing of issue #432
                    It 'Should return $false' {
                        $result = Test-TargetResource @testParameters -Verbose
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }
            }

            Context "When the system is in the desired state" {
                Context 'When all features are installed' {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = $mockDefaultFeatures
                            }
                        } -Verifiable
                    }

                    It 'Should return $true' {
                        $result = Test-TargetResource @testParameters -Verbose
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the correct clustered instance was found' {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                            FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                            FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = $mockDefaultFeatures
                                FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                                FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                                FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            }
                        } -Verifiable
                    }

                    It 'Should return $true' {
                        $result = Test-TargetResource @testParameters -Verbose
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }

                    # Regression test when the variables were detected differently.
                    It 'Should not return false after a clustered install due to the presence of a variable called "FailoverClusterDisks"' {
                        # These are needed to populate paths when calling (& $mockClusterDiskMap).
                        $mockDynamicSqlDataDirectoryPath = $mockSqlDataDirectoryPath
                        $mockDynamicSqlUserDatabasePath = $mockSqlUserDatabasePath
                        $mockDynamicSqlUserDatabaseLogPath = $mockSqlUserDatabaseLogPath
                        $mockDynamicSqlTempDatabasePath = $mockSqlTempDatabasePath
                        $mockDynamicSqlTempDatabaseLogPath = $mockSqlTempDatabaseLogPath
                        $mockDynamicSqlBackupPath = $mockSqlBackupPath

                        New-Variable -Name 'FailoverClusterDisks' -Value (& $mockClusterDiskMap)['UserData']

                        $result = Test-TargetResource @testParameters -Verbose
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                # This is a test for regression testing of issue #432.
                Context 'When the SQL Server failover cluster has all features and is in desired state' {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters['Features'] = 'SQLENGINE,AS'
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                            FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                            FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'SQLEngine,AS'
                                FailoverClusterGroupName = $mockDefaultInstance_FailoverClusterGroupName
                                FailoverClusterIPAddress = $mockDefaultInstance_FailoverClusterIPAddress
                                FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                            }
                        } -Verifiable
                    }

                    It 'Should return $true' {
                        $result = Test-TargetResource @testParameters -Verbose
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "SqlSetup\Set-TargetResource" -Tag 'Set' {
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

            BeforeAll {
                # General mocks
                Mock -CommandName Import-SQLPSModule
                Mock -CommandName Get-SqlMajorVersion -MockWith $mockGetSqlMajorVersion -Verifiable

                # Mocking SharedDirectory and SharedWowDirectory (when not previously installed)
                Mock -CommandName Get-ItemProperty -Verifiable

                Mock -CommandName Start-SqlSetupProcess -MockWith $mockStartSqlSetupProcess -Verifiable
                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                } -Verifiable

                Mock -CommandName Test-PendingRestart -MockWith {
                    return $false
                }

                # Mock PsDscRunAsCredential context.
                $PsDscContext = @{
                    RunAsUser = $mockSetupCredential.UserName
                }
            }

            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()
                $testParameters += @{
                    SQLSysAdminAccounts = 'COMPANY\User1','COMPANY\SQLAdmins'
                    ASSysAdminAccounts = 'COMPANY\User1','COMPANY\SQLAdmins'
                }
            }

            foreach ($mockSqlMajorVersion in $testProductVersion)
            {
                $mockDefaultInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockDefaultInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockDynamicSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockDynamicSqlTempDatabasePath = ''
                $mockDynamicSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                # This sets administrators dynamically in the mock Connect-SQLAnalysis.
                $mockDynamicSqlAnalysisAdmins = $mockSqlAnalysisAdmins

                Context "When setup process fails with exit code " {
                    BeforeEach {
                        Mock -CommandName Start-SqlSetupProcess -MockWith $mockStartSqlSetupProcess_WithDynamicExitCode -Verifiable
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable

                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }
                        $testParameters.Features = 'SQLENGINE'
                    }

                    Context 'When exit code is 3010' {
                        $mockDynamicSetupProcessExitCode = 3010

                        Mock -CommandName Write-Warning

                        It 'Should warn that target node need to restart' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When exit code is any other (exit code is set to 1 for the test)' {
                        $mockDynamicSetupProcessExitCode = 1

                        Mock -CommandName Write-Warning

                        It 'Should throw the correct error message' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Import-SQLPSModule -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable

                        Mock -CommandName Invoke-InstallationMediaCopy -MockWith $mockNewTemporaryFolder
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        $testParameters = $mockDefaultParameters.Clone()
                        # This is also used to regression test issue #1254, SqlSetup fails when root directory is specified.
                        $testParameters += @{
                            SQLSysAdminAccounts = 'COMPANY\User1','COMPANY\SQLAdmins'
                            ASSysAdminAccounts = 'COMPANY\User1','COMPANY\SQLAdmins'
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                            ProductKey = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                            InstanceDir = 'D:'
                            InstallSQLDataDir = 'E:'
                            InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
                            InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
                            UpdateEnabled = 'True'
                            UpdateSource = 'C:\Updates\' # Regression test for issue #720
                            ASServerMode = 'TABULAR'
                            RSInstallMode = 'DefaultNativeMode'
                            SqlSvcStartupType = $mockSqlSvcStartupType
                            AgtSvcStartupType = $mockAgtSvcStartupType
                            AsSvcStartupType = $mockAsSvcStartupType
                            IsSvcStartupType = $mockIsSvcStartupType
                            RsSvcStartupType = $mockRsSvcStartupType
                            SqlTempDbFileCount = 2
                            SqlTempDbFileSize = 128
                            SqlTempDbFileGrowth = 128
                            SqlTempDbLogFileSize = 128
                            SqlTempDbLogFileGrowth = 128
                        }

                        if ( $mockSqlMajorVersion -in (13,14) )
                        {
                            $testParameters.Features = $testParameters.Features -replace ',SSMS,ADV_SSMS',''
                        }

                        $mockStartSqlSetupProcessExpectedArgument = @{
                            Quiet = 'True'
                            IAcceptSQLServerLicenseTerms = 'True'
                            Action = 'Install'
                            InstanceName = 'MSSQLSERVER'
                            Features = $testParameters.Features
                            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                            ASSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                            PID = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                            InstanceDir = 'D:\'
                            InstallSQLDataDir = 'E:\'
                            InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
                            InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
                            UpdateEnabled = 'True'
                            UpdateSource = 'C:\Updates' # Regression test for issue #720
                            ASServerMode = 'TABULAR'
                            RSInstallMode = 'DefaultNativeMode'
                            SqlSvcStartupType = $mockSqlSvcStartupType
                            AgtSvcStartupType = $mockAgtSvcStartupType
                            AsSvcStartupType = $mockAsSvcStartupType
                            IsSvcStartupType = $mockIsSvcStartupType
                            RsSvcStartupType = $mockRsSvcStartupType
                            SqlTempDbFileCount = 2
                            SqlTempDbFileSize = 128
                            SqlTempDbFileGrowth = 128
                            SqlTempDbLogFileSize = 128
                            SqlTempDbLogFileGrowth = 128
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-InstallationMediaCopy -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-SQLPSModule -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -in (13,14) )
                    {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016 and 2017' {
                            $testParameters += @{
                                InstanceName = $mockDefaultInstance_InstanceName
                                SourceCredential = $null
                                SourcePath = $mockSourcePath
                            }

                            $testParameters.Features = 'SSMS'
                            $mockStartSqlSetupProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should -Throw "'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016 and 2017' {
                            $testParameters += @{
                                InstanceName = $mockDefaultInstance_InstanceName
                                SourceCredential = $null
                                SourcePath = $mockSourcePath
                            }

                            $testParameters.Features = 'ADV_SSMS'
                            $mockStartSqlSetupProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should -Throw "'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }
                    }
                    else
                    {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters += @{
                                InstanceName = $mockDefaultInstance_InstanceName
                                SourceCredential = $null
                                SourcePath = $mockSourcePath
                            }

                            $testParameters.Features = 'SSMS'

                            $mockStartSqlSetupProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters += @{
                                InstanceName = $mockDefaultInstance_InstanceName
                                SourceCredential = $null
                                SourcePath = $mockSourcePath
                            }

                            $testParameters.Features = 'ADV_SSMS'

                            $mockStartSqlSetupProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'ADV_SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context "When using SourceCredential parameter, and using a UNC path with a leaf, and SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }

                        if ( $mockSqlMajorVersion -in (13,14) )
                        {
                            $testParameters.Features = $testParameters.Features -replace ',SSMS,ADV_SSMS',''
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable

                        Mock -CommandName Invoke-InstallationMediaCopy -MockWith $mockNewTemporaryFolder -Verifiable
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        $mockStartSqlSetupProcessExpectedArgument = @{
                            Quiet = 'True'
                            IAcceptSQLServerLicenseTerms = 'True'
                            Action = 'Install'
                            AgtSvcStartupType = 'Automatic'
                            InstanceName = 'MSSQLSERVER'
                            Features = $testParameters.Features
                            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                            ASSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-InstallationMediaCopy -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -in (13,14) )
                    {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016 and 2017' {
                            $testParameters.Features = 'SSMS'
                            $mockStartSqlSetupProcessExpectedArgument = ''

                            { Set-TargetResource @testParameters } | Should -Throw "'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016 and 2017' {
                            $testParameters.Features = 'ADV_SSMS'
                            $mockStartSqlSetupProcessExpectedArgument = ''

                            { Set-TargetResource @testParameters } | Should -Throw "'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }
                    }
                    else
                    {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters.Features = 'SSMS'

                            $mockStartSqlSetupProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters.Features = 'ADV_SSMS'

                            $mockStartSqlSetupProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'ADV_SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context "When using SourceCredential parameter, and using a UNC path without a leaf, and SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNCWithoutLeaf
                            ForceReboot = $true
                            SuppressReboot = $true
                        }

                        if ( $mockSqlMajorVersion -in (13,14) )
                        {
                            $testParameters.Features = $testParameters.Features -replace ',SSMS,ADV_SSMS',''
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable

                        Mock -CommandName Invoke-InstallationMediaCopy -MockWith $mockNewTemporaryFolder -Verifiable
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        $mockStartSqlSetupProcessExpectedArgument = @{
                            Quiet = 'True'
                            IAcceptSQLServerLicenseTerms = 'True'
                            Action = 'Install'
                            AGTSVCSTARTUPTYPE = 'Automatic'
                            InstanceName = 'MSSQLSERVER'
                            Features = $testParameters.Features
                            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                            ASSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-InstallationMediaCopy -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-SQLPSModule -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -in (13,14) )
                    {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016 and 2017' {
                            $testParameters.Features = 'SSMS'
                            $mockStartSqlSetupProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should -Throw "'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016 and 2017' {
                            $testParameters.Features = 'ADV_SSMS'
                            $mockStartSqlSetupProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should -Throw "'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }
                    }
                    else
                    {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters.Features = 'SSMS'

                            $mockStartSqlSetupProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters.Features = 'ADV_SSMS'

                            $mockStartSqlSetupProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'MSSQLSERVER'
                                Features = 'ADV_SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
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
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                            ForceReboot = $true
                        }

                        if ( $mockSqlMajorVersion -in (13,14) )
                        {
                            $testParameters.Features = $testParameters.Features -replace ',SSMS,ADV_SSMS',''
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        $mockStartSqlSetupProcessExpectedArgument = @{
                            Quiet = 'True'
                            IAcceptSQLServerLicenseTerms = 'True'
                            Action = 'Install'
                            AGTSVCSTARTUPTYPE = 'Automatic'
                            InstanceName = 'TEST'
                            Features = $testParameters.Features
                            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                            ASSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -in (13,14) )
                    {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016 and 2017' {
                            $testParameters.Features = $($testParameters.Features), 'SSMS' -join ','
                            $mockStartSqlSetupProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should -Throw "'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016 and 2017' {
                            $testParameters.Features = $($testParameters.Features), 'ADV_SSMS' -join ','
                            $mockStartSqlSetupProcessExpectedArgument = @{}

                            { Set-TargetResource @testParameters } | Should -Throw "'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
                        }
                    }
                    else
                    {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters.Features = 'SSMS'

                            $mockStartSqlSetupProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'TEST'
                                Features = 'SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters.Features = 'ADV_SSMS'

                            $mockStartSqlSetupProcessExpectedArgument = @{
                                Quiet = 'True'
                                IAcceptSQLServerLicenseTerms = 'True'
                                Action = 'Install'
                                InstanceName = 'TEST'
                                Features = 'ADV_SSMS'
                            }

                            { Set-TargetResource @testParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                # For testing AddNode action
                Context "When SQL Server version is $mockSQLMajorVersion and the system is not in the desired state and the action is AddNode" {
                    BeforeEach {
                        $testParameters = $mockDefaultClusterParameters.Clone()
                        $testParameters['Features'] += 'AS'
                        $testParameters += @{
                            InstanceName = 'MSSQLSERVER'
                            SourcePath = $mockSourcePath
                            Action = 'AddNode'
                            AgtSvcAccount = $mockSQLAgentCredential
                            SqlSvcAccount = $mockSQLServiceCredential
                            ASSvcAccount = $mockAnalysisServiceCredential
                            FailoverClusterNetworkName = $mockDefaultInstance_FailoverClusterNetworkName
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable
                    }

                    It 'Should pass proper parameters to setup' {
                        $mockStartSqlSetupProcessExpectedArgument = @{
                            IAcceptSQLServerLicenseTerms = 'True'
                            Quiet = 'True'
                            Action = 'AddNode'
                            InstanceName = 'MSSQLSERVER'
                            AgtSvcAccount = $mockAgentServiceAccount
                            AgtSvcPassword = $mockSqlAgentCredential.GetNetworkCredential().Password
                            SqlSvcAccount = $mockSqlServiceAccount
                            SqlSvcPassword = $mockSQLServiceCredential.GetNetworkCredential().Password
                            AsSvcAccount = $mockAnalysisServiceAccount
                            AsSvcPassword = $mockAnalysisServiceCredential.GetNetworkCredential().Password
                            SkipRules = 'Cluster_VerifyForErrors'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }
                }

                # For testing InstallFailoverCluster action
                Context "When SQL Server version is $mockSQLMajorVersion and the system is not in the desired state and the action is InstallFailoverCluster" {
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

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage -ParameterFilter {
                            $Filter -eq "Name = 'Available Storage'"
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource -ParameterFilter {
                            ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
                        } -Verifiable

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
                    }

                    It 'Should pass proper parameters to setup' {
                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }

                    It 'Should pass proper parameters to setup when only InstallSQLDataDir is assigned a path' {
                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                    }

                    It 'Should pass proper parameters to setup when three variables are assigned the same drive, but different paths' {
                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                    }

                    It 'Should throw an error when one or more paths are not resolved to clustered storage' {
                        $badPathParameters = $testParameters.Clone()

                        # Pass in a bad path
                        $badPathParameters.SQLUserDBDir = 'C:\MSSQL\'

                        { Set-TargetResource @badPathParameters } | Should -Throw 'Unable to map the specified paths to valid cluster storage. Drives mapped: Backup; SysData; TempDbData; TempDbLogs; UserLogs'
                    }

                    It 'Should properly map paths to clustered disk resources' {
                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }

                    It 'Should build a DEFAULT address string when no network is specified' {
                        $missingNetworkParameters = $testParameters.Clone()
                        $missingNetworkParameters.Remove('FailoverClusterIPAddress')

                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @missingNetworkParameters } | Should -Not -Throw
                    }

                    It 'Should throw an error when an invalid IP Address is specified' {
                        $invalidAddressParameters = $testParameters.Clone()

                        $invalidAddressParameters.Remove('FailoverClusterIPAddress')
                        $invalidAddressParameters += @{
                            FailoverClusterIPAddress = '192.168.0.100'
                        }

                        { Set-TargetResource @invalidAddressParameters } | Should -Throw 'Unable to map the specified IP Address(es) to valid cluster networks.'
                    }

                    It 'Should throw an error when an invalid IP Address is specified for a multi-subnet instance' {
                        $invalidAddressParameters = $testParameters.Clone()

                        $invalidAddressParameters.Remove('FailoverClusterIPAddress')
                        $invalidAddressParameters += @{
                            FailoverClusterIPAddress = @('10.0.0.100','192.168.0.100')
                        }

                        { Set-TargetResource @invalidAddressParameters } | Should -Throw 'Unable to map the specified IP Address(es) to valid cluster networks.'
                    }

                    It 'Should build a valid IP address string for a single address' {

                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }

                    It 'Should build a valid IP address string for a multi-subnet cluster' {
                        $multiSubnetParameters = $testParameters.Clone()
                        $multiSubnetParameters.Remove('FailoverClusterIPAddress')
                        $multiSubnetParameters += @{
                            FailoverClusterIPAddress = ($mockClusterSites | ForEach-Object { $_.Address })
                        }

                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @multiSubnetParameters } | Should -Not -Throw
                    }

                    It 'Should pass proper parameters to setup when Cluster Shared volumes are specified' {
                        $csvTestParameters = $testParameters.Clone()

                        $csvTestParameters['InstallSQLDataDir'] = $mockCSVClusterDiskMap['SysData'].Path
                        $csvTestParameters['SQLUserDBDir'] = $mockCSVClusterDiskMap['UserData'].Path
                        $csvTestParameters['SQLUserDBLogDir'] = $mockCSVClusterDiskMap['UserLogs'].Path
                        $csvTestParameters['SQLTempDBDir'] = $mockCSVClusterDiskMap['TempDBData'].Path
                        $csvTestParameters['SQLTempDBLogDir'] = $mockCSVClusterDiskMap['TempDBLogs'].Path
                        $csvTestParameters['SQLBackupDir'] = $mockCSVClusterDiskMap['Backup'].Path

                        $mockStartSqlSetupProcessExpectedArgument = @{
                            IAcceptSQLServerLicenseTerms = 'True'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Quiet = 'True'
                            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
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

                        { Set-TargetResource @csvTestParameters } | Should -Not -Throw
                    }

                    It 'Should pass proper parameters to setup when Cluster Shared volumes are specified and are the same for one or more parameter values' {
                        $csvTestParameters = $testParameters.Clone()

                        $csvTestParameters['InstallSQLDataDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\Data'
                        $csvTestParameters['SQLUserDBDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\Data'
                        $csvTestParameters['SQLUserDBLogDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\Logs'
                        $csvTestParameters['SQLTempDBDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\TEMPDB'
                        $csvTestParameters['SQLTempDBLogDir'] = $mockCSVClusterDiskMap['UserData'].Path + '\TEMPDBLOG'
                        $csvTestParameters['SQLBackupDir'] = $mockCSVClusterDiskMap['Backup'].Path + '\Backup'

                        $mockStartSqlSetupProcessExpectedArgument = @{
                            IAcceptSQLServerLicenseTerms = 'True'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Quiet = 'True'
                            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
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

                        { Set-TargetResource @csvTestParameters } | Should -Not -Throw
                    }
                }

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state and the action is PrepareFailoverCluster" {
                    BeforeEach {
                        $testParameters.Remove('Features')
                        $testParameters.Remove('SourceCredential')
                        $testParameters.Remove('ASSysAdminAccounts')

                        $testParameters += @{
                            Features = 'SQLENGINE'
                            InstanceName = 'MSSQLSERVER'
                            SourcePath = $mockSourcePath
                            Action = 'PrepareFailoverCluster'
                        }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable

                        Mock -CommandName Invoke-InstallationMediaCopy -MockWith $mockNewTemporaryFolder -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_ResourceGroup') -and ($Filter -eq "Name = 'Available Storage'")
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter {
                            ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter {
                            $Association -eq 'MSCluster_ResourceToPossibleOwner'
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter {
                            $ResultClass -eq 'MSCluster_DiskPartition'
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -ParameterFilter {
                            ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
                        } -Verifiable
                    }

                    BeforeEach {
                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\Tools\Setup\Client_Components_Full"
                        } -Verifiable
                    }

                    It 'Should pass correct arguments to the setup process' {
                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
                            Action = 'PrepareFailoverCluster'
                            SkipRules = 'Cluster_VerifyForErrors'
                        }
                        $mockStartSqlSetupProcessExpectedArgument.Remove('FailoverClusterGroup')
                        $mockStartSqlSetupProcessExpectedArgument.Remove('SQLSysAdminAccounts')

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
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

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = ''
                            }
                        } -Verifiable

                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage -ParameterFilter {
                            $Filter -eq "Name = 'Available Storage'"
                        } -Verifiable

                        Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource -ParameterFilter {
                            ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
                        } -Verifiable

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
                    }

                    It 'Should throw an error when one or more paths are not resolved to clustered storage' {
                        $badPathParameters = $testParameters.Clone()

                        # Pass in a bad path
                        $badPathParameters.SQLUserDBDir = 'C:\MSSQL\'

                        { Set-TargetResource @badPathParameters } | Should -Throw 'Unable to map the specified paths to valid cluster storage. Drives mapped: Backup; SysData; TempDbData; TempDbLogs; UserLogs'
                    }

                    It 'Should properly map paths to clustered disk resources' {
                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }

                    It 'Should build a DEFAULT address string when no network is specified' {
                        $missingNetworkParameters = $testParameters.Clone()
                        $missingNetworkParameters.Remove('FailoverClusterIPAddress')

                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @missingNetworkParameters } | Should -Not -Throw
                    }

                    It 'Should throw an error when an invalid IP Address is specified' {
                        $invalidAddressParameters = $testParameters.Clone()

                        $invalidAddressParameters.Remove('FailoverClusterIPAddress')
                        $invalidAddressParameters += @{
                            FailoverClusterIPAddress = '192.168.0.100'
                        }

                        { Set-TargetResource @invalidAddressParameters } | Should -Throw 'Unable to map the specified IP Address(es) to valid cluster networks.'
                    }

                    It 'Should throw an error when an invalid IP Address is specified for a multi-subnet instance' {
                        $invalidAddressParameters = $testParameters.Clone()

                        $invalidAddressParameters.Remove('FailoverClusterIPAddress')
                        $invalidAddressParameters += @{
                            FailoverClusterIPAddress = @('10.0.0.100','192.168.0.100')
                        }

                        { Set-TargetResource @invalidAddressParameters } | Should -Throw 'Unable to map the specified IP Address(es) to valid cluster networks.'
                    }

                    It 'Should build a valid IP address string for a single address' {
                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }

                    It 'Should build a valid IP address string for a multi-subnet cluster' {
                        $multiSubnetParameters = $testParameters.Clone()
                        $multiSubnetParameters.Remove('FailoverClusterIPAddress')
                        $multiSubnetParameters += @{
                            FailoverClusterIPAddress = ($mockClusterSites | ForEach-Object { $_.Address })
                        }

                        $mockStartSqlSetupProcessExpectedArgument = $mockStartSqlSetupProcessExpectedArgumentClusterDefault.Clone()
                        $mockStartSqlSetupProcessExpectedArgument += @{
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

                        { Set-TargetResource @multiSubnetParameters } | Should -Not -Throw
                    }

                    It 'Should pass proper parameters to setup' {
                        $mockStartSqlSetupProcessExpectedArgument = @{
                            IAcceptSQLServerLicenseTerms = 'True'
                            SkipRules = 'Cluster_VerifyForErrors'
                            Quiet = 'True'
                            SQLSysAdminAccounts = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'

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

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe 'Get-ServiceAccountParameters' -Tag 'Helper' {
            $serviceTypes = @('SQL','AGT','IS','RS','AS','FT')

            BeforeAll {
                $mockServiceAccountPassword = ConvertTo-SecureString 'Password' -AsPlainText -Force

                $mockSystemServiceAccount = `
                    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'NT AUTHORITY\SYSTEM', $mockServiceAccountPassword

                $mockVirtualServiceAccount = `
                    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'NT SERVICE\MSSQLSERVER', $mockServiceAccountPassword

                $mockManagedServiceAccount = `
                    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'COMPANY\ManagedAccount$', $mockServiceAccountPassword

                $mockDomainServiceAccount = `
                    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'COMPANY\sql.service', $mockServiceAccountPassword

                $mockDomainServiceAccountContainingDollarSign = `
                    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'COMPANY\$sql.service', $mockServiceAccountPassword
            }

            foreach ($serviceType in $serviceTypes )
            {
                Context "When service type is $serviceType" {
                    $mockAccountArgumentName = ('{0}SVCACCOUNT' -f $serviceType)
                    $mockPasswordArgumentName = ('{0}SVCPASSWORD' -f $serviceType)

                    It 'Should return the correct parameters when the account is a system account.' {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockSystemServiceAccount -ServiceType $serviceType

                        $result.$mockAccountArgumentName | Should -BeExactly $mockSystemServiceAccount.UserName
                        $result.ContainsKey($mockPasswordArgumentName) | Should -Be $false
                    }

                    It 'Should return the correct parameters when the account is a virtual service account' {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockVirtualServiceAccount -ServiceType $serviceType

                        $result.$mockAccountArgumentName | Should -BeExactly $mockVirtualServiceAccount.UserName
                        $result.ContainsKey($mockPasswordArgumentName) | Should -Be $false
                    }

                    It 'Should return the correct parameters when the account is a managed service account' {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockManagedServiceAccount -ServiceType $serviceType

                        $result.$mockAccountArgumentName | Should -BeExactly $mockManagedServiceAccount.UserName
                        $result.ContainsKey($mockPasswordArgumentName) | Should -Be $false
                    }

                    It 'Should return the correct parameters when the account is a domain account' {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockDomainServiceAccount -ServiceType $serviceType

                        $result.$mockAccountArgumentName | Should -BeExactly $mockDomainServiceAccount.UserName
                        $result.$mockPasswordArgumentName | Should -BeExactly $mockDomainServiceAccount.GetNetworkCredential().Password
                    }

                    # Regression test for issue #1055
                    It 'Should return the correct parameters when the account is a domain account containing a dollar sign ($)' {
                        $result = Get-ServiceAccountParameters -ServiceAccount $mockDomainServiceAccountContainingDollarSign -ServiceType $serviceType

                        $result.$mockAccountArgumentName | Should -BeExactly $mockDomainServiceAccountContainingDollarSign.UserName
                        $result.$mockPasswordArgumentName | Should -BeExactly $mockDomainServiceAccountContainingDollarSign.GetNetworkCredential().Password
                    }

                }
            }
        }

        Describe 'Get-InstalledSharedFeatures' -Tag 'Helper' {
            Context 'When there are no shared features installed' {
                BeforeAll {
                    $mockSqlMajorVersion = 14

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                    } -MockWith {
                        return @(
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'UnknownKey' -Value 1 -PassThru -Force
                            )
                        )
                    } -Verifiable
                }

                It 'Should return an empty array' {
                    $getInstalledSharedFeaturesResult = Get-InstalledSharedFeatures -SqlVersion $mockSqlMajorVersion

                    $getInstalledSharedFeaturesResult | Should -HaveCount 0
                }
            }

            Context 'When there are shared features installed' {
                BeforeAll {
                    $mockSqlMajorVersion = 14

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockSqlMajorVersion)0\ConfigurationState"
                    } -MockWith {
                        return @(
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'SQL_DQ_CLIENT_Full' -Value 1 -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'SQL_BOL_Components' -Value 1 -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Connectivity_Full' -Value 1 -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Tools_Legacy_Full' -Value 1 -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'SDK_Full' -Value 1 -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'MDSCoreFeature' -Value 1 -PassThru -Force
                            )
                        )
                    } -Verifiable
                }

                It 'Should return the correct array with installed shared features' {
                    $getInstalledSharedFeaturesResult = Get-InstalledSharedFeatures -SqlVersion $mockSqlMajorVersion

                    $getInstalledSharedFeaturesResult | Should -HaveCount 6
                    $getInstalledSharedFeaturesResult | Should -Contain 'DQC'
                    $getInstalledSharedFeaturesResult | Should -Contain 'BOL'
                    $getInstalledSharedFeaturesResult | Should -Contain 'CONN'
                    $getInstalledSharedFeaturesResult | Should -Contain 'BC'
                    $getInstalledSharedFeaturesResult | Should -Contain 'SDK'
                    $getInstalledSharedFeaturesResult | Should -Contain 'MDS'
                }
            }
        }

        Describe 'Test-FeatureFlag' -Tag 'Helper' {
            Context 'When no feature flags was provided' {
                It 'Should return $false' {
                    Test-FeatureFlag -FeatureFlag $null -TestFlag 'MyFlag' | Should -Be $false
                }
            }

            Context 'When feature flags was provided' {
                It 'Should return $true' {
                    Test-FeatureFlag -FeatureFlag @('FirstFlag','SecondFlag') -TestFlag 'SecondFlag' | Should -Be $true
                }
            }

            Context 'When feature flags was provided, but missing' {
                It 'Should return $false' {
                    Test-FeatureFlag -FeatureFlag @('MyFlag2') -TestFlag 'MyFlag' | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
