# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

    # TODO: Need to test when SourceCredential is set. Must mock NetUse (Get-/Set-method) and Robocopy (Set-method)
    # TODO: Need to test when replication state is installed, see $mockGetItemProperty_ConfigurationState
    # TODO: Need to test other products than just DBENGINE.
    # TODO: Need to test all parameters
    # TODO: Can't test Set-method when state is present because the Set-method is not currently built that way.

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

        $sqlDatabaseEngineName = 'MSSQL'
        $SqlAgentName = 'SQLAgent'
        $sqlCollation = 'Finnish_Swedish_CI_AS'
        $sqlLoginMode = 'Integrated'

        $defaultInstance_InstanceName = 'MSSQLSERVER'
        $defaultInstance_DatabaseServiceName = $defaultInstance_InstanceName
        $defaultInstance_AgentServiceName = 'SQLSERVERAGENT'

        $namedInstance_InstanceName = 'TEST'
        $namedInstance_DatabaseServiceName = "$($sqlDatabaseEngineName)`$$($namedInstance_InstanceName)"
        $namedInstance_AgentServiceName = "$($SqlAgentName)`$$($namedInstance_InstanceName)"

        $setupCredentialUserName = "COMPANY\sqladmin" 
        $setupCredentialPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $setupCredential = New-Object System.Management.Automation.PSCredential( $setupCredentialUserName, $setupCredentialPassword )

        $sqlServiceAccount = 'COMPANY\SqlAccount'
        $agentServiceAccount = 'COMPANY\AgentAccount'

        $sourcePath = 'TestDrive:\'
        $sourceFolder = 'Source'

        $mockGetSQLVersion = {
            $sqlMajorVersion
        }

        $mockEmptyHashtable = {
            return @()
        }

        $mockGetWmiObject_SqlProduct = {
            return @(
                (
                    # Mock product SSMS 2008 and SSMS 2008 R2
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'IdentifyingNumber' -Value '{72AB7E6F-BC24-481E-8C45-1AB5B3DD795D}' -PassThru -Force
                ),
                (
                    # Mock product ADV_SSMS 2008 and SSMS 2008 R2
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'IdentifyingNumber' -Value '{B5FE23CC-0151-4595-84C3-F1DE6F44FE9B}' -PassThru -Force
                ),
                (
                    # Mock product SSMS 2012
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'IdentifyingNumber' -Value '{A7037EB2-F953-4B12-B843-195F4D988DA1}' -PassThru -Force
                ),
                (
                    # Mock product ADV_SSMS 2012
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'IdentifyingNumber' -Value '{7842C220-6E9A-4D5A-AE70-0E138271F883}' -PassThru -Force
                ),
                (
                    # Mock product SSMS 2014
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'IdentifyingNumber' -Value '{75A54138-3B98-4705-92E4-F619825B121F}' -PassThru -Force
                ),
                (
                    # Mock product ADV_SSMS 2014
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'IdentifyingNumber' -Value '{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}' -PassThru -Force
                )
            )
        }

        $mockGetService_DefaultInstance = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $defaultInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $sqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $defaultInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $agentServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetService_NamedInstance = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $namedInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $sqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $namedInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $agentServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetWmiObject_DefaultInstance = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $defaultInstance_InstanceName -PassThru 
                )
            )
        }

        $mockGetWmiObject_NamedInstance = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $namedInstance_InstanceName -PassThru 
                )
            )
        }
        $mockGetItemProperty_ConfigurationState = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'SQL_Replication_Core_Inst' -Value $null -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SQL = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name $defaultInstance_InstanceName -Value $defaultInstance_InstanceId -PassThru -Force                
                ),
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name $namedInstance_InstanceName -Value $namedInstance_InstanceId -PassThru -Force                
                )
            )
        }

        $mockGetItemProperty_Setup = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'SqlProgramDir' -Value 'C:\Program Files\Microsoft SQL Server\' -PassThru -Force
                )
            )
        }

        $mockConnectSQL = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'LoginMode' -Value $sqlLoginMode -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Collation' -Value 'Finnish_Swedish_CI_AS' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstallDataDirectory' -Value $sqlInstallPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'BackupDirectory' -Value $sqlBackupPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBDir' -Value $sqlTempDatabasePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBLogDir' -Value $sqlTempDatabaseLogPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultFile' -Value $sqlDefaultDatabaseFilePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultLog' -Value $sqlDefaultDatabaseLogPath -PassThru |
                        Add-Member ScriptProperty Logins {
                            return 
                                @( ( New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'COMPANY\Stacy' -PassThru | 
                                    Add-Member ScriptProperty ListMembers {
                                        return @('sysadmin')
                                    } -PassThru -Force
                                ) )
                        } -PassThru -Force
                )
            )
        }

        $defaultParameters = @{
            SourcePath = $sourcePath
            SetupCredential = $setupCredential
            Features = 'SQLEngine' 
        }
       
        Describe "$($script:DSCResourceName)\Get-TargetResource" -Tag 'Get' {
            # Setting up TestDrive:\
            # Mocking SourceFolder. SourceFolder has a default value of 'Source', so we mock that as well.
            New-Item (Join-Path -Path $sourcePath -ChildPath $sourceFolder) -ItemType Directory
            # Mocking setup.exe.
            Set-Content (Join-Path -Path (Join-Path -Path $sourcePath -ChildPath $sourceFolder) -ChildPath 'setup.exe') -Value 'Mock exe file'

            BeforeEach {
                # General mocks
                Mock -CommandName GetSQLVersion -MockWith $mockGetSQLVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                    ($Name -eq $defaultInstance_InstanceName -or $Name -eq $namedInstance_InstanceName) 
                } -MockWith $mockGetItemProperty_SQL -Verifiable 
            }

            $testProductVersion | ForEach-Object -Process {
                $sqlMajorVersion = $_

                $defaultInstance_InstanceId = "$($sqlDatabaseEngineName)$($sqlMajorVersion).$($defaultInstance_InstanceName)"

                $sqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL"
                $sqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\Backup"
                $sqlTempDatabasePath = ''
                $sqlTempDatabaseLogPath = ''
                $sqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\DATA\"
                $sqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $sqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $defaultParameters
                        $testParameters += @{
                            InstanceName = $defaultInstance_InstanceName
                            SourceCredential = $null
                        }
                        
                        $testParameters.Features = 'SQLEngine,SSMS,ADV_SSMS'

                        if ($sqlMajorVersion -eq 13) {
                            # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                            Mock -CommandName Get-WmiObject -ParameterFilter { 
                                $Class -eq 'Win32_Product' 
                            } -MockWith $mockGetWmiObject_SqlProduct -Verifiable
                        } else {
                            Mock -CommandName Get-WmiObject -ParameterFilter { 
                                $Class -eq 'Win32_Product' 
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It
                    }

                    It 'Should not return any names of installed features' {
                        $result = Get-TargetResource @testParameters
                        $result.Features | Should Be ''
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $sourcePath
                        $result.SourceFolder | Should Be $sourceFolder
                        $result.InstanceName | Should Be $defaultInstance_InstanceName
                        $result.InstanceID | Should Be ''
                        $result.InstallSharedDir | Should Be ''
                        $result.InstallSharedWOWDir | Should Be ''
                        $result.SQLSvcAccountUsername | Should Be $null
                        $result.AgtSvcAccountUsername | Should Be $null
                        $result.SQLCollation | Should Be ''
                        $result.SQLSysAdminAccounts | Should Be $null
                        $result.SecurityMode | Should Be ''
                        $result.InstallSQLDataDir | Should Be ''
                        $result.SQLUserDBDir | Should Be ''
                        $result.SQLUserDBLogDir | Should Be ''
                        $result.SQLBackupDir | Should Be ''
                        $result.FTSvcAccountUsername | Should Be $null
                        $result.RSSvcAccountUsername | Should Be $null
                        $result.ASSvcAccountUsername | Should Be $null
                        $result.ASCollation | Should Be ''
                        $result.ASSysAdminAccounts | Should Be $null
                        $result.ASDataDir | Should Be ''
                        $result.ASLogDir | Should Be ''
                        $result.ASBackupDir | Should Be ''
                        $result.ASTempDir | Should Be ''
                        $result.ASConfigDir | Should Be ''
                        $result.ISSvcAccountUsername | Should Be $null
                    }
                }

                Context "When SQL Server version is $sqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $defaultParameters
                        $testParameters += @{
                            InstanceName = $defaultInstance_InstanceName
                            SourceCredential = $null
                        }

                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockGetWmiObject_SqlProduct -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockGetWmiObject_DefaultInstance -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 3 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($sqlMajorVersion -eq 13) {
                            $result.Features | Should Be 'SQLENGINE'
                        } else {
                            $result.Features | Should Be 'SQLENGINE,SSMS,ADV_SSMS'
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $sourcePath
                        $result.SourceFolder | Should Be $sourceFolder
                        $result.InstanceName | Should Be $defaultInstance_InstanceName
                        $result.InstanceID | Should Be $defaultInstance_InstanceName
                        $result.InstallSharedDir | Should Be $null
                        $result.InstallSharedWOWDir | Should Be $null
                        $result.SQLSvcAccountUsername | Should Be $null
                        $result.AgtSvcAccountUsername | Should Be $null
                        $result.SQLCollation | Should Be $sqlCollation
                        $result.SQLSysAdminAccounts | Should Be $null
                        $result.SecurityMode | Should Be 'Windows'
                        $result.InstallSQLDataDir | Should Be $sqlInstallPath
                        $result.SQLUserDBDir | Should Be $sqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should Be $sqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should Be $sqlBackupPath
                        $result.FTSvcAccountUsername | Should Be $null
                        $result.RSSvcAccountUsername | Should Be $null
                        $result.ASSvcAccountUsername | Should Be $null
                        $result.ASCollation | Should Be ''
                        $result.ASSysAdminAccounts | Should Be $null
                        $result.ASDataDir | Should Be ''
                        $result.ASLogDir | Should Be ''
                        $result.ASBackupDir | Should Be ''
                        $result.ASTempDir | Should Be ''
                        $result.ASConfigDir | Should Be ''
                        $result.ISSvcAccountUsername | Should Be $null
                    }
                }

                $namedInstance_InstanceId = "$($sqlDatabaseEngineName)$($sqlMajorVersion).$($namedInstance_InstanceName)"

                $sqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($namedInstance_InstanceId)\MSSQL"
                $sqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($namedInstance_InstanceId)\MSSQL\Backup"
                $sqlTempDatabasePath = ''
                $sqlTempDatabaseLogPath = ''
                $sqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($namedInstance_InstanceId)\MSSQL\DATA\"
                $sqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($namedInstance_InstanceId)\MSSQL\DATA\"
                
                Context "When SQL Server version is $sqlMajorVersion and the system is not in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $defaultParameters
                        $testParameters += @{
                            InstanceName = $namedInstance_InstanceName
                            SourceCredential = $null
                        }

                        # Mock this here to make sure we don't return any older components (<=2014) when testing SQL Server 2016
                        if ($sqlMajorVersion -eq 13) {
                            # Mock this here to make sure we don't return any older components (<=2014) when testing SQL Server 2016
                            Mock -CommandName Get-WmiObject -ParameterFilter { 
                                $Class -eq 'Win32_Product' 
                            } -MockWith $mockGetWmiObject_SqlProduct -Verifiable
                        } else {
                            Mock -CommandName Get-WmiObject -ParameterFilter { 
                                $Class -eq 'Win32_Product' 
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$namedInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$namedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It
                    }

                    It 'Should not return any names of installed features' {
                        $result = Get-TargetResource @testParameters
                        $result.Features | Should Be ''
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $sourcePath
                        $result.SourceFolder | Should Be $sourceFolder
                        $result.InstanceName | Should Be $namedInstance_InstanceName
                        $result.InstanceID | Should Be ''
                        $result.InstallSharedDir | Should Be ''
                        $result.InstallSharedWOWDir | Should Be ''
                        $result.SQLSvcAccountUsername | Should Be $null
                        $result.AgtSvcAccountUsername | Should Be $null
                        $result.SQLCollation | Should Be ''
                        $result.SQLSysAdminAccounts | Should Be $null
                        $result.SecurityMode | Should Be ''
                        $result.InstallSQLDataDir | Should Be ''
                        $result.SQLUserDBDir | Should Be ''
                        $result.SQLUserDBLogDir | Should Be ''
                        $result.SQLBackupDir | Should Be ''
                        $result.FTSvcAccountUsername | Should Be $null
                        $result.RSSvcAccountUsername | Should Be $null
                        $result.ASSvcAccountUsername | Should Be $null
                        $result.ASCollation | Should Be ''
                        $result.ASSysAdminAccounts | Should Be $null
                        $result.ASDataDir | Should Be ''
                        $result.ASLogDir | Should Be ''
                        $result.ASBackupDir | Should Be ''
                        $result.ASTempDir | Should Be ''
                        $result.ASConfigDir | Should Be ''
                        $result.ISSvcAccountUsername | Should Be $null
                    }
                }

                Context "When SQL Server version is $sqlMajorVersion and the system is in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $defaultParameters
                        $testParameters += @{
                            InstanceName = $namedInstance_InstanceName
                            SourceCredential = $null
                        }

                        # Mock this here to make sure we don't return any older components (<=2014) when testing SQL Server 2016
                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockGetWmiObject_SqlProduct -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockGetWmiObject_NamedInstance -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$namedInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$namedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 3 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($sqlMajorVersion -eq 13) {
                            $result.Features | Should Be 'SQLENGINE'
                        } else {
                            $result.Features | Should Be 'SQLENGINE,SSMS,ADV_SSMS'
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $sourcePath
                        $result.SourceFolder | Should Be $sourceFolder
                        $result.InstanceName | Should Be $namedInstance_InstanceName
                        $result.InstanceID | Should Be $namedInstance_InstanceName
                        $result.InstallSharedDir | Should Be $null
                        $result.InstallSharedWOWDir | Should Be $null
                        $result.SQLSvcAccountUsername | Should Be $null
                        $result.AgtSvcAccountUsername | Should Be $null
                        $result.SQLCollation | Should Be $sqlCollation
                        $result.SQLSysAdminAccounts | Should Be $null
                        $result.SecurityMode | Should Be 'Windows'
                        $result.InstallSQLDataDir | Should Be $sqlInstallPath
                        $result.SQLUserDBDir | Should Be $sqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should Be $sqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should Be $sqlBackupPath
                        $result.FTSvcAccountUsername | Should Be $null
                        $result.RSSvcAccountUsername | Should Be $null
                        $result.ASSvcAccountUsername | Should Be $null
                        $result.ASCollation | Should Be ''
                        $result.ASSysAdminAccounts | Should Be $null
                        $result.ASDataDir | Should Be ''
                        $result.ASLogDir | Should Be ''
                        $result.ASBackupDir | Should Be ''
                        $result.ASTempDir | Should Be ''
                        $result.ASConfigDir | Should Be ''
                        $result.ISSvcAccountUsername | Should Be $null
                    }
                }
            }

            Assert-VerifiableMocks
        }
        
        Describe "$($script:DSCResourceName)\Test-TargetResource" -Tag 'Test' {
            # Setting up TestDrive:\
            # Mocking SourceFolder. SourceFolder has a default value of 'Source', so we mock that as well.
            New-Item (Join-Path -Path $sourcePath -ChildPath $sourceFolder) -ItemType Directory
            # Mocking setup.exe.
            Set-Content (Join-Path -Path (Join-Path -Path $sourcePath -ChildPath $sourceFolder) -ChildPath 'setup.exe') -Value 'Mock exe file'

            BeforeEach {
                # General mocks
                Mock -CommandName GetSQLVersion -MockWith $mockGetSQLVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                # Mocks for default instance
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                    ($Name -eq $defaultInstance_InstanceName) 
                } -MockWith $mockGetItemProperty_SQL -Verifiable 
            }

            # For this thest we only need to test one SQL Server version
            $sqlMajorVersion = 13

            $defaultInstance_InstanceId = "$($sqlDatabaseEngineName)$($sqlMajorVersion).$($defaultInstance_InstanceName)"

            $sqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL"
            $sqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\Backup"
            $sqlTempDatabasePath = ''
            $sqlTempDatabaseLogPath = ''
            $sqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\DATA\"
            $sqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\DATA\"

            Context "When the system is not in the desired state" {
                BeforeEach {
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        InstanceName = $defaultInstance_InstanceName
                        SourceCredential = $null
                    }

                    # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                    Mock -CommandName Get-WmiObject -ParameterFilter { 
                        $Class -eq 'Win32_Product' 
                    } -MockWith $mockGetWmiObject_SqlProduct -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\ConfigurationState"
                    } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                    Mock -CommandName Get-ItemProperty -ParameterFilter { 
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -MockWith $mockGetItemProperty_Setup -Verifiable 
                }

                It 'Should return that the desired state is absent when no products are installed' {
                    Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                    Mock -CommandName Get-WmiObject -ParameterFilter {
                        $Class -eq 'Win32_Service'
                    } -MockWith $mockEmptyHashtable -Verifiable

                    $result = Test-TargetResource @testParameters
                    $result| Should Be $false
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                        -Exactly -Times 0 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                        -Exactly -Times 1 -Scope It
                }

                It 'Should return that the desired state is asbent when SSMS product is missing' {
                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                    Mock -CommandName Get-WmiObject -ParameterFilter {
                        $Class -eq 'Win32_Service'
                    } -MockWith $mockGetWmiObject_DefaultInstance -Verifiable

                    # Change the default features for this test.
                    $testParameters.Features = 'SSMS'

                    $result = Test-TargetResource @testParameters
                    $result| Should Be $false
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 3 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                        -Exactly -Times 2 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                        -Exactly -Times 1 -Scope It
                }

                It 'Should return that the desired state is asbent when ADV_SSMS product is missing' {
                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                    Mock -CommandName Get-WmiObject -ParameterFilter {
                        $Class -eq 'Win32_Service'
                    } -MockWith $mockGetWmiObject_DefaultInstance -Verifiable

                    # Change the default features for this test.
                    $testParameters.Features = 'ADV_SSMS'

                    $result = Test-TargetResource @testParameters
                    $result| Should Be $false
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 3 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                        -Exactly -Times 2 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                        -Exactly -Times 1 -Scope It
                }
            }

            Context "When the system is in the desired state" {
                BeforeEach {
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        InstanceName = $defaultInstance_InstanceName
                        SourceCredential = $null
                    }

                    Mock -CommandName Get-WmiObject -ParameterFilter { 
                        $Class -eq 'Win32_Product' 
                    } -MockWith $mockGetWmiObject_SqlProduct -Verifiable

                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                    Mock -CommandName Get-WmiObject -ParameterFilter {
                        $Class -eq 'Win32_Service'
                    } -MockWith $mockGetWmiObject_DefaultInstance -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\ConfigurationState"
                    } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                    Mock -CommandName Get-ItemProperty -ParameterFilter { 
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -MockWith $mockGetItemProperty_Setup -Verifiable 
                }

                It 'Should return that the desired state is present' {
                    $result = Test-TargetResource @testParameters
                    $result| Should Be $true
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 3 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                        -Exactly -Times 2 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                        -Exactly -Times 1 -Scope It
                }
            }
            
            Assert-VerifiableMocks
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" -Tag 'Set' {
            # Setting up TestDrive:\
            # Mocking SourceFolder. SourceFolder has a default value of 'Source', so we mock that as well.
            New-Item (Join-Path -Path $sourcePath -ChildPath $sourceFolder) -ItemType Directory
            # Mocking setup.exe.
            Set-Content (Join-Path -Path (Join-Path -Path $sourcePath -ChildPath $sourceFolder) -ChildPath 'setup.exe') -Value 'Mock exe file'

            BeforeEach {
                # General mocks
                Mock -CommandName GetSQLVersion -MockWith $mockGetSQLVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                # Mocks for default instance
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                    ($Name -eq $defaultInstance_InstanceName) 
                } -MockWith $mockGetItemProperty_SQL -Verifiable 

                Mock -CommandName StartWin32Process -MockWith {
                    return 'Process started'
                } -Verifiable
                Mock -CommandName WaitForWin32ProcessEnd -Verifiable
                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                } -Verifiable
            }

            $testProductVersion | ForEach-Object -Process {
                $sqlMajorVersion = $_

                $defaultInstance_InstanceId = "$($sqlDatabaseEngineName)$($sqlMajorVersion).$($defaultInstance_InstanceName)"

                $sqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL"
                $sqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\Backup"
                $sqlTempDatabasePath = ''
                $sqlTempDatabaseLogPath = ''
                $sqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\DATA\"
                $sqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($defaultInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $sqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        $testParameters = $defaultParameters
                        $testParameters += @{
                            InstanceName = $defaultInstance_InstanceName
                            SourceCredential = $null
                        }

                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$defaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        { Set-TargetResource @testParameters } | Should Not Throw
                        
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $sqlMajorVersion -eq 13 ) {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = 'SQLEngine,SSMS'
                            { Set-TargetResource @testParameters } | Should Throw
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = 'SQLEngine,ADV_SSMS'
                            { Set-TargetResource @testParameters } | Should Throw
                        }
                    } else {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters.Features = 'SSMS'
                            { Set-TargetResource @testParameters } | Should Not Throw
                            
                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                                -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                                -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters.Features = 'ADV_SSMS'
                            { Set-TargetResource @testParameters } | Should Not Throw
                            
                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                                -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                                -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                $namedInstance_InstanceId = "$($sqlDatabaseEngineName)$($sqlMajorVersion).$($namedInstance_InstanceName)"

                $sqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($namedInstance_InstanceId)\MSSQL"
                $sqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($namedInstance_InstanceId)\MSSQL\Backup"
                $sqlTempDatabasePath = ''
                $sqlTempDatabaseLogPath = ''
                $sqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($namedInstance_InstanceId)\MSSQL\DATA\"
                $sqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($namedInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $sqlMajorVersion and the system is not in the desired state for a named instance" {
                    BeforeEach {
                        $testParameters = $defaultParameters
                        $testParameters += @{
                            InstanceName = $namedInstance_InstanceName
                            SourceCredential = $null
                        }

                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$namedInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$namedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        { Set-TargetResource @testParameters } | Should Not Throw
                        
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $sqlMajorVersion -eq 13 ) {
                        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = 'SQLEngine,SSMS'
                            { Set-TargetResource @testParameters } | Should Throw
                        }

                        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016' {
                            $testParameters.Features = 'SQLEngine,ADV_SSMS'
                            { Set-TargetResource @testParameters } | Should Throw
                        }
                    } else {
                        It 'Should set the system in the desired state when feature is SSMS' {
                            $testParameters.Features = 'SSMS'
                            { Set-TargetResource @testParameters } | Should Not Throw
                            
                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                                -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                                -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }

                        It 'Should set the system in the desired state when feature is ADV_SSMS' {
                            $testParameters.Features = 'ADV_SSMS'
                            { Set-TargetResource @testParameters } | Should Not Throw
                            
                            Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                                -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                                -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }
            }
            
            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}
