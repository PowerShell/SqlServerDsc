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
        $mockSqlCollation = 'Finnish_Swedish_CI_AS'
        $mockSqlLoginMode = 'Integrated'

        $mockSqlSharedDirectory = 'C:\Program Files\Microsoft SQL Server'
        $mockSqlSharedWowDirectory = 'C:\Program Files (x86)\Microsoft SQL Server'
        $mockSqlProgramDirectory = 'C:\Program Files\Microsoft SQL Server'
        
        $mockDefaultInstance_InstanceName = 'MSSQLSERVER'
        $mockDefaultInstance_DatabaseServiceName = $mockDefaultInstance_InstanceName
        $mockDefaultInstance_AgentServiceName = 'SQLSERVERAGENT'

        $mockNamedInstance_InstanceName = 'TEST'
        $mockNamedInstance_DatabaseServiceName = "$($mockSqlDatabaseEngineName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_AgentServiceName = "$($mockSqlAgentName)`$$($mockNamedInstance_InstanceName)"

        $mockmockSetupCredentialUserName = "COMPANY\sqladmin" 
        $mockmockSetupCredentialPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $mockSetupCredential = New-Object System.Management.Automation.PSCredential( $mockmockSetupCredentialUserName, $mockmockSetupCredentialPassword )

        $mockSqlServiceAccount = 'COMPANY\SqlAccount'
        $mockAgentServiceAccount = 'COMPANY\AgentAccount'

        $mockSourceFolder = 'Source' #  The parameter SourceFolder has a default value of 'Source', so lets mock that as well.

        $mockGetSQLVersion = {
            return $mockSqlMajorVersion
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
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                ),
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force
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
                )
            )
        }

        $mockGetWmiObject_DefaultInstance = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_InstanceName -PassThru 
                )
            )
        }

        $mockGetWmiObject_NamedInstance = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_InstanceName -PassThru 
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

        $mockConnectSQL = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name 'LoginMode' -Value $mockSqlLoginMode -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Collation' -Value $mockSqlCollation -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstallDataDirectory' -Value $mockSqlInstallPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'BackupDirectory' -Value $mockSqlBackupPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBDir' -Value $mockSqlTempDatabasePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SQLTempDBLogDir' -Value $mockSqlTempDatabaseLogPath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultFile' -Value $mockSqlDefaultDatabaseFilePath -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DefaultLog' -Value $mockSqlDefaultDatabaseLogPath -PassThru |
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

        $mockGetTemporaryFolder = {
            return $mockSourcePathUNC
        }
        
        $mockDefaultParameters = @{
            SetupCredential = $mockSetupCredential
            Features = 'SQLEngine' 
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" -Tag 'Get' {
            #region Setting up TestDrive:\

            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName
            $mockSqlMediaPath = Join-Path -Path $mockSourcePath -ChildPath $mockSourceFolder
            
            # UNC path to TestDrive:\
            $testDrive_DriveShare = (Split-Path -Path $mockSourcePath -Qualifier) -replace ':','$'
            $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $mockSourcePath -NoQualifier)
            $mockSqlMediaPathUNC = Join-Path -Path $mockSourcePathUNC -ChildPath $mockSourceFolder

            # Mocking folder structure and mocking setup.exe
            New-Item -Path $mockSqlMediaPath -ItemType Directory
            Set-Content (Join-Path -Path $mockSqlMediaPath -ChildPath 'setup.exe') -Value 'Mock exe file'
            
            #endregion Setting up TestDrive:\

            BeforeEach {
                # General mocks
                Mock -CommandName GetSQLVersion -MockWith $mockGetSQLVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                    ($Name -eq $mockDefaultInstance_InstanceName -or $Name -eq $mockNamedInstance_InstanceName) 
                } -MockWith $mockGetItemProperty_SQL -Verifiable 

                # Mocking SharedDirectory
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D1F366D0FE0E404F8C15EE4F1C15094' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
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

            $testProductVersion | ForEach-Object -Process {
                $mockSqlMajorVersion = $_

                $mockDefaultInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockDefaultInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockSqlTempDatabasePath = ''
                $mockSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }
                        
                        $testParameters.Features = 'SQLEngine,SSMS,ADV_SSMS'

                        if ($mockSqlMajorVersion -eq 13) {
                            # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                            Mock -CommandName Get-WmiObject -ParameterFilter { 
                                $Class -eq 'Win32_Product' 
                            } -MockWith $mockGetWmiObject_SqlProduct -Verifiable
                        } else {
                            Mock -CommandName Get-WmiObject -ParameterFilter { 
                                $Class -eq 'Win32_Product' 
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName NetUse -Verifiable
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
                        
                        Assert-MockCalled -CommandName NetUse -Exactly -Times 0 -Scope It
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
                        $result.SourcePath | Should Be $mockSourcePath
                        $result.SourceFolder | Should Be $mockSourceFolder
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
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }
                        
                        $testParameters.Features = 'SQLEngine,SSMS,ADV_SSMS'

                        if ($mockSqlMajorVersion -eq 13) {
                            # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                            Mock -CommandName Get-WmiObject -ParameterFilter { 
                                $Class -eq 'Win32_Product' 
                            } -MockWith $mockGetWmiObject_SqlProduct -Verifiable
                        } else {
                            Mock -CommandName Get-WmiObject -ParameterFilter { 
                                $Class -eq 'Win32_Product' 
                            } -MockWith $mockEmptyHashtable -Verifiable
                        }

                        Mock -CommandName NetUse -Verifiable
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
                        
                        Assert-MockCalled -CommandName NetUse -Exactly -Times 2 -Scope It
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
                        $result.SourcePath | Should Be $mockSourcePathUNC
                        $result.SourceFolder | Should Be $mockSourceFolder
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

                Context "When SQL Server version is $mockSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockGetWmiObject_SqlProduct -Verifiable

                        Mock -CommandName NetUse -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockGetWmiObject_DefaultInstance -Verifiable

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
                        
                        Assert-MockCalled -CommandName NetUse -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 5 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($mockSqlMajorVersion -eq 13) {
                            $result.Features | Should Be 'SQLENGINE'
                        } else {
                            $result.Features | Should Be 'SQLENGINE,SSMS,ADV_SSMS'
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePath
                        $result.SourceFolder | Should Be $mockSourceFolder
                        $result.InstanceName | Should Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should Be $mockDefaultInstance_InstanceName
                        $result.InstallSharedDir | Should Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should BeNullOrEmpty
                        $result.SqlCollation | Should Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should BeNullOrEmpty
                        $result.SecurityMode | Should Be 'Windows'
                        $result.InstallSQLDataDir | Should Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should Be $mockSqlBackupPath
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

                Context "When using SourceCredential parameter and SQL Server version is $mockSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }

                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockGetWmiObject_SqlProduct -Verifiable

                        Mock -CommandName NetUse -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockGetWmiObject_DefaultInstance -Verifiable

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
                        
                        Assert-MockCalled -CommandName NetUse -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 5 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($mockSqlMajorVersion -eq 13) {
                            $result.Features | Should Be 'SQLENGINE'
                        } else {
                            $result.Features | Should Be 'SQLENGINE,SSMS,ADV_SSMS'
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePathUNC
                        $result.SourceFolder | Should Be $mockSourceFolder
                        $result.InstanceName | Should Be $mockDefaultInstance_InstanceName
                        $result.InstanceID | Should Be $mockDefaultInstance_InstanceName
                        $result.InstallSharedDir | Should Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should BeNullOrEmpty
                        $result.SqlCollation | Should Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should BeNullOrEmpty
                        $result.SecurityMode | Should Be 'Windows'
                        $result.InstallSQLDataDir | Should Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should Be $mockSqlBackupPath
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

                $mockNamedInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockNamedInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL"
                $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\Backup"
                $mockSqlTempDatabasePath = ''
                $mockSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\DATA\"
                
                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        # Mock this here to make sure we don't return any older components (<=2014) when testing SQL Server 2016
                        if ($mockSqlMajorVersion -eq 13) {
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
                        $result.SourcePath | Should Be $mockSourcePath
                        $result.SourceFolder | Should Be $mockSourceFolder
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
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
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
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 5 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It
                    }

                    It 'Should return correct names of installed features' {
                        $result = Get-TargetResource @testParameters
                        if ($mockSqlMajorVersion -eq 13) {
                            $result.Features | Should Be 'SQLENGINE'
                        } else {
                            $result.Features | Should Be 'SQLENGINE,SSMS,ADV_SSMS'
                        }
                    }

                    It 'Should return the correct values in the hash table' {
                        $result = Get-TargetResource @testParameters
                        $result.SourcePath | Should Be $mockSourcePath
                        $result.SourceFolder | Should Be $mockSourceFolder
                        $result.InstanceName | Should Be $mockNamedInstance_InstanceName
                        $result.InstanceID | Should Be $mockNamedInstance_InstanceName
                        $result.InstallSharedDir | Should Be $mockSqlSharedDirectory
                        $result.InstallSharedWOWDir | Should Be $mockSqlSharedWowDirectory
                        $result.SQLSvcAccountUsername | Should BeNullOrEmpty
                        $result.AgtSvcAccountUsername | Should BeNullOrEmpty
                        $result.SqlCollation | Should Be $mockSqlCollation
                        $result.SQLSysAdminAccounts | Should BeNullOrEmpty
                        $result.SecurityMode | Should Be 'Windows'
                        $result.InstallSQLDataDir | Should Be $mockSqlInstallPath
                        $result.SQLUserDBDir | Should Be $mockSqlDefaultDatabaseFilePath
                        $result.SQLUserDBLogDir | Should Be $mockSqlDefaultDatabaseLogPath
                        $result.SQLBackupDir | Should Be $mockSqlBackupPath
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
            }

            Assert-VerifiableMocks
        }
        
        Describe "$($script:DSCResourceName)\Test-TargetResource" -Tag 'Test' {
            #region Setting up TestDrive:\

            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName
            $mockSqlMediaPath = Join-Path -Path $mockSourcePath -ChildPath $mockSourceFolder
            
            # UNC path to TestDrive:\
            $testDrive_DriveShare = (Split-Path -Path $mockSourcePath -Qualifier) -replace ':','$'
            $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $mockSourcePath -NoQualifier)
            $mockSqlMediaPathUNC = Join-Path -Path $mockSourcePathUNC -ChildPath $mockSourceFolder

            # Mocking folder structure and mocking setup.exe
            New-Item -Path $mockSqlMediaPath -ItemType Directory
            Set-Content (Join-Path -Path $mockSqlMediaPath -ChildPath 'setup.exe') -Value 'Mock exe file'
            
            #endregion Setting up TestDrive:\

            BeforeEach {
                # General mocks
                Mock -CommandName GetSQLVersion -MockWith $mockGetSQLVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                # Mocking SharedDirectory
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D1F366D0FE0E404F8C15EE4F1C15094' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
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

                # Mocks for default instance
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                    ($Name -eq $mockDefaultInstance_InstanceName) 
                } -MockWith $mockGetItemProperty_SQL -Verifiable 
            }

            # For this thest we only need to test one SQL Server version
            $mockSqlMajorVersion = 13

            $mockDefaultInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockDefaultInstance_InstanceName)"

            $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
            $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
            $mockSqlTempDatabasePath = ''
            $mockSqlTempDatabaseLogPath = ''
            $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
            $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

            Context "When the system is not in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        InstanceName = $mockDefaultInstance_InstanceName
                        SourceCredential = $null
                        SourcePath = $mockSourcePath
                    }

                    # Mock all SSMS products here to make sure we don't return any when testing SQL Server 2016
                    Mock -CommandName Get-WmiObject -ParameterFilter { 
                        $Class -eq 'Win32_Product' 
                    } -MockWith $mockGetWmiObject_SqlProduct -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                    } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                    Mock -CommandName Get-ItemProperty -ParameterFilter { 
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
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
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 5 -Scope It

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
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 5 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                        -Exactly -Times 2 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                        -Exactly -Times 1 -Scope It
                }
            }

            Context "When the system is in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        InstanceName = $mockDefaultInstance_InstanceName
                        SourceCredential = $null
                        SourcePath = $mockSourcePath
                    }

                    Mock -CommandName Get-WmiObject -ParameterFilter { 
                        $Class -eq 'Win32_Product' 
                    } -MockWith $mockGetWmiObject_SqlProduct -Verifiable

                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable

                    Mock -CommandName Get-WmiObject -ParameterFilter {
                        $Class -eq 'Win32_Service'
                    } -MockWith $mockGetWmiObject_DefaultInstance -Verifiable

                    Mock -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                    } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                    Mock -CommandName Get-ItemProperty -ParameterFilter { 
                        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                    } -MockWith $mockGetItemProperty_Setup -Verifiable 
                }

                It 'Should return that the desired state is present' {
                    $result = Test-TargetResource @testParameters
                    $result| Should Be $true
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 5 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                        -Exactly -Times 2 -Scope It

                    Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                        -Exactly -Times 1 -Scope It
                }
            }
            
            Assert-VerifiableMocks
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" -Tag 'Set' {
            #region Setting up TestDrive:\

            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName
            $mockSqlMediaPath = Join-Path -Path $mockSourcePath -ChildPath $mockSourceFolder
            
            # UNC path to TestDrive:\
            $testDrive_DriveShare = (Split-Path -Path $mockSourcePath -Qualifier) -replace ':','$'
            $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $mockSourcePath -NoQualifier)
            $mockSqlMediaPathUNC = Join-Path -Path $mockSourcePathUNC -ChildPath $mockSourceFolder

            # Mocking folder structure and mocking setup.exe
            New-Item -Path $mockSqlMediaPath -ItemType Directory
            Set-Content (Join-Path -Path $mockSqlMediaPath -ChildPath 'setup.exe') -Value 'Mock exe file'
            
            #endregion Setting up TestDrive:\

            BeforeEach {
                # General mocks
                Mock -CommandName GetSQLVersion -MockWith $mockGetSQLVersion -Verifiable
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                # Mocking SharedDirectory
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D1F366D0FE0E404F8C15EE4F1C15094' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'
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

                # Mocks for default instance
                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                    ($Name -eq $mockDefaultInstance_InstanceName) 
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
                $mockSqlMajorVersion = $_

                $mockDefaultInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockDefaultInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockSqlTempDatabasePath = ''
                $mockSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName NetUse -Verifiable
                        Mock -CommandName Copy-ItemWithRoboCopy -Verifiable
                        Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        { Set-TargetResource @testParameters } | Should Not Throw
                        
                        Assert-MockCalled -CommandName NetUse -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-TemporaryFolder -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Copy-ItemWithRoboCopy -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                            ($Name -eq $mockDefaultInstance_InstanceName) 
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -eq 13 ) {
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
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                                ($Name -eq $mockDefaultInstance_InstanceName) 
                            } -Exactly -Times 0 -Scope It

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
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                                ($Name -eq $mockDefaultInstance_InstanceName) 
                            } -Exactly -Times 0 -Scope It

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

                Context "When using SourceCredential parameter and SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockDefaultInstance_InstanceName
                            SourceCredential = $mockSetupCredential
                            SourcePath = $mockSourcePathUNC
                        }

                        Mock -CommandName NetUse -Verifiable
                        Mock -CommandName Copy-ItemWithRoboCopy -Verifiable
                        Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft copSQL Server\$mockDefaultInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockDefaultInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        { Set-TargetResource @testParameters } | Should Not Throw
                        
                        Assert-MockCalled -CommandName NetUse -Exactly -Times 4 -Scope It
                        Assert-MockCalled -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Copy-ItemWithRoboCopy -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                            ($Name -eq $mockDefaultInstance_InstanceName) 
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -eq 13 ) {
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
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                                ($Name -eq $mockDefaultInstance_InstanceName) 
                            } -Exactly -Times 0 -Scope It

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
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                                ($Name -eq $mockDefaultInstance_InstanceName) 
                            } -Exactly -Times 0 -Scope It

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

                $mockNamedInstance_InstanceId = "$($mockSqlDatabaseEngineName)$($mockSqlMajorVersion).$($mockNamedInstance_InstanceName)"

                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL"
                $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\Backup"
                $mockSqlTempDatabasePath = ''
                $mockSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockNamedInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockSqlMajorVersion and the system is not in the desired state for a named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            InstanceName = $mockNamedInstance_InstanceName
                            SourceCredential = $null
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-WmiObject -ParameterFilter { 
                            $Class -eq 'Win32_Product' 
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-WmiObject -ParameterFilter {
                            $Class -eq 'Win32_Service'
                        } -MockWith $mockEmptyHashtable -Verifiable

                        Mock -CommandName Get-ItemProperty -ParameterFilter {
                                $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\ConfigurationState"
                        } -MockWith $mockGetItemProperty_ConfigurationState -Verifiable 

                        Mock -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockNamedInstance_InstanceId\Setup" -and $Name -eq 'SqlProgramDir'
                        } -MockWith $mockGetItemProperty_Setup -Verifiable 
                    }

                    It 'Should set the system in the desired state when feature is SQLENGINE' {
                        { Set-TargetResource @testParameters } | Should Not Throw
                        
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                            ($Name -eq $mockDefaultInstance_InstanceName) 
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Service' } `
                            -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Get-WmiObject -ParameterFilter { $Class -eq 'Win32_Product' } `
                            -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName StartWin32Process -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName WaitForWin32ProcessEnd -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    }

                    if( $mockSqlMajorVersion -eq 13 ) {
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
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                                ($Name -eq $mockDefaultInstance_InstanceName) 
                            } -Exactly -Times 0 -Scope It

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
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { 
                                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -and 
                                ($Name -eq $mockDefaultInstance_InstanceName) 
                            } -Exactly -Times 0 -Scope It

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
