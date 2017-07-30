$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerRSConfig'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName   `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SQLPSStub.psm1') -Global -Force
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockNamedInstanceName = 'INSTANCE'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockReportingServicesDatabaseServerName = 'SERVER'
        $mockReportingServicesDatabaseNamedInstanceName = $mockNamedInstanceName
        $mockReportingServicesDatabaseDefaultInstanceName = $mockDefaultInstanceName

        $mockReportsApplicationName = 'ReportServerWebApp'
        $mockReportsApplicationNameLegacy = 'ReportManager'
        $mockReportServerApplicationName = 'ReportServerWebService'
        $mockReportsApplicationUrl = 'http://+:80'
        $mockReportServerApplicationUrl = 'http://+:80'
        $mockVirtualDirectoryReportManagerName = 'Reports_SQL2016'
        $mockVirtualDirectoryReportServerName = 'ReportServer_SQL2016'

        $mockGetItemProperty = {
            return @{
                InstanceName = $mockInstanceName
                Version = $mockDynamic_SqlBuildVersion
            }
        }

        $mockGetWmiObject_ConfigurationSetting_NamedInstance = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $mockDynamicIsInitialized -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockNamedInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value $mockVirtualDirectoryReportServerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value $mockVirtualDirectoryReportManagerName -PassThru |
                        Add-Member -MemberType ScriptMethod -Name SetVirtualDirectory {
                            $script:mockIsMethodCalled_SetVirtualDirectory = $true

                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name ReserveURL {
                            $script:mockIsMethodCalled_ReserveURL = $true

                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name GenerateDatabaseCreationScript {
                            $script:mockIsMethodCalled_GenerateDatabaseCreationScript = $true

                            return @{
                                Script = 'select * from something'
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name GenerateDatabaseRightsScript {
                            $script:mockIsMethodCalled_GenerateDatabaseRightsScript = $true

                            return @{
                                Script = 'select * from something'
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name SetDatabaseConnection {
                            $script:mockIsMethodCalled_SetDatabaseConnection = $true

                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name InitializeReportServer {
                            $script:mockIsMethodCalled_InitializeReportServer = $true

                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name RemoveURL {
                            $script:mockIsMethodCalled_RemoveURL = $true

                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name ListReservedUrls {
                            $script:mockIsMethodCalled_ListReservedUrls = $true

                            return New-Object Object |
                                Add-Member -MemberType ScriptProperty -Name 'Application' {
                                    return @(
                                        $mockDynamicReportServerApplicationName,
                                        $mockDynamicReportsApplicationName
                                    )
                                } -PassThru |
                                Add-Member -MemberType ScriptProperty -Name 'UrlString' {
                                    return @(
                                        $mockDynamicReportsApplicationUrlString,
                                        $mockDynamicReportServerApplicationUrlString
                                    )
                                } -PassThru -Force
                        } -PassThru -Force
                ),
                (
                    # Array is a regression test for issue #819.
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $true -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value 'DummyInstance' -PassThru -Force
                )
            )
        }

        $mockGetWmiObject_ConfigurationSetting_DefaultInstance = {
            return New-Object Object |
                Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName" -PassThru |
                Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockDefaultInstanceName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value '' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value '' -PassThru |
                Add-Member -MemberType ScriptMethod -Name SetVirtualDirectory {
                    $script:mockIsMethodCalled_SetVirtualDirectory = $true

                    return $null
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name ReserveURL {
                    $script:mockIsMethodCalled_ReserveURL = $true

                    return $null
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name GenerateDatabaseCreationScript {
                    $script:mockIsMethodCalled_GenerateDatabaseCreationScript = $true

                    return @{
                        Script = 'select * from something'
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name GenerateDatabaseRightsScript {
                    $script:mockIsMethodCalled_GenerateDatabaseRightsScript = $true

                    return @{
                        Script = 'select * from something'
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name SetDatabaseConnection {
                    $script:mockIsMethodCalled_SetDatabaseConnection = $true

                    return $null
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name InitializeReportServer {
                    $script:mockIsMethodCalled_InitializeReportServer = $true

                    return $null
                } -PassThru -Force
        }

        $mockGetWmiObject_ConfigurationSetting_ParameterFilter = {
            $Class -eq 'MSReportServer_ConfigurationSetting'
        }

        $mockGetWmiObject_Language = {
            return @{
                Language = '1033'
            }
        }

        $mockGetWmiObject_OperatingSystem_ParameterFilter = {
            $Class -eq 'Win32_OperatingSystem'
        }

        Describe "xSQLServerRSConfig\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $mockDynamic_SqlBuildVersion = '13.0.4001.0'

                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty -Verifiable

                $defaultParameters = @{
                    InstanceName = $mockNamedInstanceName
                    RSSQLServer = $mockReportingServicesDatabaseServerName
                    RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    $mockDynamicReportServerApplicationName = $mockReportServerApplicationName
                    $mockDynamicReportsApplicationName = $mockReportsApplicationName
                    $mockDynamicReportsApplicationUrlString = $mockReportsApplicationUrl
                    $mockDynamicReportServerApplicationUrlString = $mockReportServerApplicationUrl

                    $mockDynamicIsInitialized = $true
                }

                BeforeEach {
                    Mock -CommandName Get-WmiObject `
                        -MockWith $mockGetWmiObject_ConfigurationSetting_NamedInstance `
                        -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                        -Verifiable
                }

                $mockDynamicIsInitialized = $true

                It 'Should return the same values as passed as parameters' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should Be $mockNamedInstanceName
                    $resultGetTargetResource.RSSQLServer | Should Be $mockReportingServicesDatabaseServerName
                    $resultGetTargetResource.RSSQLInstanceName | Should Be $mockReportingServicesDatabaseNamedInstanceName
                    $resultGetTargetResource | Should BeOfType [System.Collections.Hashtable]
                }

                It 'Should return the the state as initialized' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.IsInitialized | Should Be $true
                    $resultGetTargetResource.ReportServerVirtualDirectory | Should Be $mockVirtualDirectoryReportServerName
                    $resultGetTargetResource.ReportsVirtualDirectory | Should Be $mockVirtualDirectoryReportManagerName
                    $resultGetTargetResource.ReportServerReservedUrl | Should Be $mockReportServerApplicationUrl
                    $resultGetTargetResource.ReportsReservedUrl | Should Be $mockReportsApplicationUrl
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    $mockDynamicIsInitialized = $false
                }

                BeforeEach {
                    Mock -CommandName Get-WmiObject `
                        -MockWith $mockGetWmiObject_ConfigurationSetting_DefaultInstance `
                        -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                        -Verifiable

                    $testParameters = $defaultParameters.Clone()
                    $testParameters['InstanceName'] = $mockDefaultInstanceName
                }

                $mockDynamicIsInitialized = $false

                It 'Should return the same values as passed as parameters' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.InstanceName | Should Be $mockDefaultInstanceName
                    $resultGetTargetResource.RSSQLServer | Should Be $mockReportingServicesDatabaseServerName
                    $resultGetTargetResource.RSSQLInstanceName | Should Be $mockReportingServicesDatabaseDefaultInstanceName
                    $resultGetTargetResource | Should BeOfType [System.Collections.Hashtable]
                }

                It 'Should return the state as not initialized' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.IsInitialized | Should Be $false
                    $resultGetTargetResource.ReportServerVirtualDirectory | Should BeNullOrEmpty
                    $resultGetTargetResource.ReportsVirtualDirectory | Should BeNullOrEmpty
                    $resultGetTargetResource.ReportServerReservedUrl | Should BeNullOrEmpty
                    $resultGetTargetResource.ReportsReservedUrl | Should BeNullOrEmpty
                }

                # Regression test for issue #822.
                Context 'When Reporting Services has not been initialized (IsInitialized returns $null)' {
                    $mockDynamicIsInitialized = $null

                    It 'Should return the state as not initialized' {
                        $resultGetTargetResource = Get-TargetResource @testParameters
                        $resultGetTargetResource.IsInitialized | Should Be $false
                    }
                }

                # Regression test for issue #822.
                Context 'When Reporting Services has not been initialized (IsInitialized returns empty string)' {
                    $mockDynamicIsInitialized = ''

                    It 'Should return the state as not initialized' {
                        $resultGetTargetResource = Get-TargetResource @testParameters
                        $resultGetTargetResource.IsInitialized | Should Be $false
                    }
                }

                Context 'When there is no Reporting Services instance' {
                    BeforeEach {
                        Mock -CommandName Get-ItemProperty
                    }

                    It 'Should throw the correct error message' {
                        { Get-TargetResource @defaultParameters } | Should Throw 'SQL Reporting Services instance ''INSTANCE'' does not exist!'
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "xSQLServerRSConfig\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Import-SQLPSModule -Verifiable
                Mock -CommandName Invoke-Sqlcmd -Verifiable
                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty -Verifiable
                Mock -CommandName Restart-ReportingServicesService -Verifiable
            }

            Context 'When the system is not in the desired state' {
                Context 'When configuring a named instance that are not initialized' {
                    BeforeAll {
                        $mockDynamic_SqlBuildVersion = '13.0.4001.0'
                        $mockDynamicIsInitialized = $false

                        Mock -CommandName Test-TargetResource -MockWith {
                            return $true
                        }

                        $defaultParameters = @{
                            InstanceName = $mockNamedInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_ConfigurationSetting_NamedInstance `
                            -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_Language `
                            -ParameterFilter $mockGetWmiObject_OperatingSystem_ParameterFilter `
                            -Verifiable

                        # Start each test with each method in correct state.
                        $script:mockIsMethodCalled_GenerateDatabaseCreationScript = $false
                        $script:mockIsMethodCalled_GenerateDatabaseRightsScript = $false
                        $script:mockIsMethodCalled_SetVirtualDirectory = $false
                        $script:mockIsMethodCalled_ReserveURL = $false
                        $script:mockIsMethodCalled_SetDatabaseConnection = $false
                        $script:mockIsMethodCalled_InitializeReportServer = $false
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @defaultParameters } | Should Not Throw

                        # Test so each mock of methods was called.
                        $script:mockIsMethodCalled_GenerateDatabaseRightsScript | Should Be $true
                        $script:mockIsMethodCalled_GenerateDatabaseCreationScript | Should Be $true
                        $script:mockIsMethodCalled_SetVirtualDirectory | Should Be $true
                        $script:mockIsMethodCalled_ReserveURL | Should Be $true
                        $script:mockIsMethodCalled_SetDatabaseConnection | Should Be $true
                        $script:mockIsMethodCalled_InitializeReportServer | Should Be $true

                        Assert-MockCalled -CommandName Get-WmiObject -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Restart-ReportingServicesService -Exactly -Times 1 -Scope It
                    }

                    Context 'When there is no Reporting Services instance after Set-TargetResource has been called' {
                        BeforeEach {
                            Mock -CommandName Get-ItemProperty -Verifiable
                            Mock -CommandName Test-TargetResource -Verifiable
                        }

                        It 'Should throw the correct error message' {
                            { Set-TargetResource @defaultParameters } | Should Throw 'Test-TargetResource returned false after calling set.'
                        }
                    }
                }

                Context 'When configuring a named instance that are already initialized' {
                    BeforeAll {
                        $mockDynamic_SqlBuildVersion = '13.0.4001.0'
                        $mockDynamicIsInitialized = $true

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                ReportServerReservedUrl      = $mockReportServerApplicationUrl
                                ReportsReservedUrl           = $mockReportsApplicationUrl
                            }
                        }

                        Mock -CommandName Test-TargetResource -MockWith {
                            return $true
                        }

                        $testParameters = @{
                            InstanceName = $mockNamedInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            ReportServerVirtualDirectory = 'ReportServer_NewName'
                            ReportsVirtualDirectory = 'Reports_NewName'
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_ConfigurationSetting_NamedInstance `
                            -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_Language `
                            -ParameterFilter $mockGetWmiObject_OperatingSystem_ParameterFilter `
                            -Verifiable

                        # Start each test with each method in correct state.
                        $script:mockIsMethodCalled_GenerateDatabaseCreationScript = $false
                        $script:mockIsMethodCalled_GenerateDatabaseRightsScript = $false
                        $script:mockIsMethodCalled_SetVirtualDirectory = $false
                        $script:mockIsMethodCalled_ReserveURL = $false
                        $script:mockIsMethodCalled_SetDatabaseConnection = $false
                        $script:mockIsMethodCalled_InitializeReportServer = $false
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @testParameters } | Should Not Throw

                        # Test so each mock of methods was called.
                        $script:mockIsMethodCalled_GenerateDatabaseRightsScript | Should Be $false
                        $script:mockIsMethodCalled_GenerateDatabaseCreationScript | Should Be $false
                        $script:mockIsMethodCalled_SetVirtualDirectory | Should Be $true
                        $script:mockIsMethodCalled_ReserveURL | Should Be $true
                        $script:mockIsMethodCalled_SetDatabaseConnection | Should Be $false
                        $script:mockIsMethodCalled_InitializeReportServer | Should Be $false

                        Assert-MockCalled -CommandName Get-WmiObject -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When configuring a default instance that are not initialized' {
                    BeforeAll {
                        $mockDynamic_SqlBuildVersion = '12.0.4100.1'
                        $mockDynamicIsInitialized = $false

                        Mock -CommandName Test-TargetResource -MockWith {
                            return $true
                        } -Verifiable

                        $defaultParameters = @{
                            InstanceName = $mockDefaultInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseDefaultInstanceName
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_ConfigurationSetting_DefaultInstance `
                            -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_Language `
                            -ParameterFilter $mockGetWmiObject_OperatingSystem_ParameterFilter `
                            -Verifiable
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @defaultParameters } | Should Not Throw

                        # Test so each mock of methods was called.
                        $script:mockIsMethodCalled_GenerateDatabaseRightsScript | Should Be $true
                        $script:mockIsMethodCalled_GenerateDatabaseCreationScript | Should Be $true
                        $script:mockIsMethodCalled_SetVirtualDirectory | Should Be $true
                        $script:mockIsMethodCalled_ReserveURL | Should Be $true
                        $script:mockIsMethodCalled_SetDatabaseConnection | Should Be $true
                        $script:mockIsMethodCalled_InitializeReportServer | Should Be $true

                        Assert-MockCalled -CommandName Get-WmiObject -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Restart-ReportingServicesService -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "xSQLServerRSConfig\Test-TargetResource" -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                Context 'When Reporting Services are not initialized' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized = $false
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName = $mockNamedInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource  = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should Be $false
                    }
                }

                Context 'When Report Server virtual directory is different' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized = $true
                                ReportServerVirtualDirectory = $mockVirtualDirectoryReportServerName
                                ReportsVirtualDirectory = $mockVirtualDirectoryReportsName
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName = $mockNamedInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            ReportsVirtualDirectory = $mockVirtualDirectoryReportsName
                            ReportServerVirtualDirectory = 'ReportServer_NewName'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource  = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should Be $false
                    }
                }

                Context 'When Report Server virtual directory is different' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized = $true
                                ReportServerVirtualDirectory = $mockVirtualDirectoryReportServerName
                                ReportsVirtualDirectory = $mockVirtualDirectoryReportsName
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName = $mockNamedInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            ReportServerVirtualDirectory = $mockVirtualDirectoryReportServerName
                            ReportsVirtualDirectory = 'Reports_NewName'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource  = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should Be $false
                    }
                }

                Context 'When Report Server Report Server reserved URLs is different' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized = $true
                                ReportServerReservedUrl = $mockReportServerApplicationUrl
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName = $mockNamedInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            ReportServerReservedUrl = 'https://+:443'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource  = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should Be $false
                    }
                }

                Context 'When Report Server Reports reserved URLs is different' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized = $true
                                ReportsReservedUrl = $mockReportServerApplicationUrl
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName = $mockNamedInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            ReportsReservedUrl = 'https://+:443'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource  = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should Be $false
                    }
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            IsInitialized = $true
                        }
                    } -Verifiable

                    $defaultParameters = @{
                        InstanceName = $mockNamedInstanceName
                        RSSQLServer = $mockReportingServicesDatabaseServerName
                        RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                    }
                }

                It 'Should return state as in desired state' {
                    $resultTestTargetResource  = Test-TargetResource @defaultParameters
                    $resultTestTargetResource | Should Be $true
                }
            }

            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}
