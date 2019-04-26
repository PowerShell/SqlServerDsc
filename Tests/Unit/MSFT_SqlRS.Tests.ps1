<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlRS DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlRS'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName   `
    -DSCResourceName $script:dscResourceName  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    # Importing SQLPS stubs
    Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SQLPSStub.psm1') -Force -Global
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
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

        $mockInvokeCimMethod = {
            throw 'Should not call Invoke-CimMethod directly, should call the wrapper Invoke-RsCimMethod.'
        }

        $mockInvokeRsCimMethod_ListReservedUrls = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name 'Application' -Value {
                return @(
                    $mockDynamicReportServerApplicationName,
                    $mockDynamicReportsApplicationName
                )
            } -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'UrlString' -Value {
                return @(
                    $mockDynamicReportsApplicationUrlString,
                    $mockDynamicReportServerApplicationUrlString
                )
            } -PassThru -Force
        }

        $mockInvokeRsCimMethod_GenerateDatabaseCreationScript = {
            return @{
                Script = 'select * from something'
            }
        }

        $mockInvokeRsCimMethod_GenerateDatabaseRightsScript = {
            return @{
                Script = 'select * from something'
            }
        }

        $mockGetItemProperty = {
            return @{
                InstanceName = $mockInstanceName
                Version      = $mockDynamic_SqlBuildVersion
            }
        }

        $mockGetCimInstance_ConfigurationSetting_NamedInstance = {
            return @(
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                        'MSReportServer_ConfigurationSetting'
                        'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
                    ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $mockDynamicIsInitialized -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockNamedInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value $mockVirtualDirectoryReportServerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value $mockVirtualDirectoryReportManagerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $mockDynamicSecureConnectionLevel -PassThru -Force
                ),
                (
                    # Array is a regression test for issue #819.
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $true -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value 'DummyInstance' -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_ConfigurationSetting_DefaultInstance = {
            return New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                'MSReportServer_ConfigurationSetting'
                'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
            ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName" -PassThru |
                Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockDefaultInstanceName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value '' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value '' -PassThru -Force
                Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $mockDynamicSecureConnectionLevel -PassThru -Force
        }

        $mockGetCimInstance_ConfigurationSetting_ParameterFilter = {
            $ClassName -eq 'MSReportServer_ConfigurationSetting'
        }

        $mockGetCimInstance_Language = {
            return @{
                Language = '1033'
            }
        }

        $mockGetCimInstance_OperatingSystem_ParameterFilter = {
            $ClassName -eq 'Win32_OperatingSystem'
        }

        Describe "SqlRS\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $mockDynamic_SqlBuildVersion = '13.0.4001.0'

                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty -Verifiable
                Mock -CommandName Invoke-RsCimMethod -MockWith $mockInvokeRsCimMethod_ListReservedUrls -ParameterFilter {
                    $MethodName -eq 'ListReservedUrls'
                } -Verifiable

                <#
                    This is mocked here so that no calls are made to it directly,
                    or if any mock of Invoke-RsCimMethod are wrong.
                #>
                Mock -CommandName Invoke-CimMethod -MockWith $mockInvokeCimMethod

                $defaultParameters = @{
                    InstanceName         = $mockNamedInstanceName
                    DatabaseServerName   = $mockReportingServicesDatabaseServerName
                    DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    $mockDynamicReportServerApplicationName = $mockReportServerApplicationName
                    $mockDynamicReportsApplicationName = $mockReportsApplicationName
                    $mockDynamicReportsApplicationUrlString = $mockReportsApplicationUrl
                    $mockDynamicReportServerApplicationUrlString = $mockReportServerApplicationUrl
                }

                BeforeEach {
                    Mock -CommandName Get-CimInstance `
                        -MockWith $mockGetCimInstance_ConfigurationSetting_NamedInstance `
                        -ParameterFilter $mockGetCimInstance_ConfigurationSetting_ParameterFilter `
                        -Verifiable
                }

                $mockDynamicIsInitialized = $true
                It 'Should return the same values as passed as parameters' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.DatabaseServerName | Should -Be $mockReportingServicesDatabaseServerName
                    $resultGetTargetResource.DatabaseInstanceName | Should -Be $mockReportingServicesDatabaseNamedInstanceName
                    $resultGetTargetResource | Should -BeOfType [System.Collections.Hashtable]
                }

                It 'Should return the the state as initialized' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.IsInitialized | Should -Be $true
                    $resultGetTargetResource.ReportServerVirtualDirectory | Should -Be $mockVirtualDirectoryReportServerName
                    $resultGetTargetResource.ReportsVirtualDirectory | Should -Be $mockVirtualDirectoryReportManagerName
                    $resultGetTargetResource.ReportServerReservedUrl | Should -Be $mockReportServerApplicationUrl
                    $resultGetTargetResource.ReportsReservedUrl | Should -Be $mockReportsApplicationUrl
                    $resultGetTargetResource.UseSsl | Should -Be $false

                    Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                        $MethodName -eq 'ListReservedUrls'
                    } -Exactly -Times 1 -Scope It
                }

                $mockDynamicSecureConnectionLevel = 0 # Do not use SSL

                Context 'When SSL is not used' {
                    It 'Should return the the state as initialized' {
                        $resultGetTargetResource = Get-TargetResource @defaultParameters
                        $resultGetTargetResource.UseSsl | Should -Be $false
                    }
                }

                $mockDynamicSecureConnectionLevel = 1 # Use SSL

                Context 'When SSL is used' {
                    It 'Should return the the state as initialized' {
                        $resultGetTargetResource = Get-TargetResource @defaultParameters
                        $resultGetTargetResource.UseSsl | Should -Be $true
                    }
                }

                # Setting the value back to the default.
                $mockDynamicSecureConnectionLevel = 0
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance `
                        -MockWith $mockGetCimInstance_ConfigurationSetting_DefaultInstance `
                        -ParameterFilter $mockGetCimInstance_ConfigurationSetting_ParameterFilter `
                        -Verifiable

                    $testParameters = $defaultParameters.Clone()
                    $testParameters['InstanceName'] = $mockDefaultInstanceName
                }

                $mockDynamicIsInitialized = $false

                It 'Should return the same values as passed as parameters' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockDefaultInstanceName
                    $resultGetTargetResource.DatabaseServerName | Should -Be $mockReportingServicesDatabaseServerName
                    $resultGetTargetResource.DatabaseInstanceName | Should -Be $mockReportingServicesDatabaseDefaultInstanceName
                    $resultGetTargetResource | Should -BeOfType [System.Collections.Hashtable]
                }

                It 'Should return the state as not initialized' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.IsInitialized | Should -Be $false
                    $resultGetTargetResource.ReportServerVirtualDirectory | Should -BeNullOrEmpty
                    $resultGetTargetResource.ReportsVirtualDirectory | Should -BeNullOrEmpty
                    $resultGetTargetResource.ReportServerReservedUrl | Should -BeNullOrEmpty
                    $resultGetTargetResource.ReportsReservedUrl | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                        $MethodName -eq 'ListReservedUrls'
                    } -Exactly -Times 0 -Scope It
                }

                # Regression test for issue #822.
                Context 'When Reporting Services has not been initialized (IsInitialized returns $null)' {
                    $mockDynamicIsInitialized = $null

                    It 'Should return the state as not initialized' {
                        $resultGetTargetResource = Get-TargetResource @testParameters
                        $resultGetTargetResource.IsInitialized | Should -Be $false
                    }
                }

                # Regression test for issue #822.
                Context 'When Reporting Services has not been initialized (IsInitialized returns empty string)' {
                    $mockDynamicIsInitialized = ''

                    It 'Should return the state as not initialized' {
                        $resultGetTargetResource = Get-TargetResource @testParameters
                        $resultGetTargetResource.IsInitialized | Should -Be $false
                    }
                }

                Context 'When there is no Reporting Services instance' {
                    BeforeEach {
                        Mock -CommandName Get-ItemProperty
                    }

                    It 'Should throw the correct error message' {
                        { Get-TargetResource @defaultParameters } | Should -Throw 'SQL Reporting Services instance ''INSTANCE'' does not exist!'
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "SqlRS\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Import-SQLPSModule -Verifiable
                Mock -CommandName Invoke-Sqlcmd -Verifiable
                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty -Verifiable
                Mock -CommandName Restart-ReportingServicesService -Verifiable
                Mock -CommandName Invoke-RsCimMethod -Verifiable
                Mock -CommandName Invoke-RsCimMethod -MockWith $mockInvokeRsCimMethod_GenerateDatabaseCreationScript -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseCreationScript'
                }

                Mock -CommandName Invoke-RsCimMethod -MockWith $mockInvokeRsCimMethod_GenerateDatabaseRightsScript -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseRightsScript'
                }

                <#
                    This is mocked here so that no calls are made to it directly,
                    or if any mock of Invoke-RsCimMethod are wrong.
                #>
                Mock -CommandName Invoke-CimMethod -MockWith $mockInvokeCimMethod

                $mockDynamicReportServerApplicationName = $mockReportServerApplicationName
                $mockDynamicReportsApplicationName = $mockReportsApplicationName
                $mockDynamicReportsApplicationUrlString = $mockReportsApplicationUrl
                $mockDynamicReportServerApplicationUrlString = $mockReportServerApplicationUrl
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
                            InstanceName         = $mockNamedInstanceName
                            DatabaseServerName   = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            UseSsl               = $true
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-CimInstance `
                            -MockWith $mockGetCimInstance_ConfigurationSetting_NamedInstance `
                            -ParameterFilter $mockGetCimInstance_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-CimInstance `
                            -MockWith $mockGetCimInstance_Language `
                            -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter `
                            -Verifiable
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetSecureConnectionLevel'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'RemoveURL'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'InitializeReportServer'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetDatabaseConnection'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'GenerateDatabaseRightsScript'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'GenerateDatabaseCreationScript'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Restart-ReportingServicesService -Exactly -Times 1 -Scope It
                    }

                    Context 'When there is no Reporting Services instance after Set-TargetResource has been called' {
                        BeforeEach {
                            Mock -CommandName Get-ItemProperty -Verifiable
                            Mock -CommandName Test-TargetResource -Verifiable
                        }

                        It 'Should throw the correct error message' {
                            { Set-TargetResource @defaultParameters } | Should -Throw $script:localizedData.TestFailedAfterSet
                        }
                    }

                    Context 'When it is not possible to evaluate OSLanguage' {
                        BeforeEach {
                            Mock -CommandName Get-CimInstance -MockWith {
                                return $null
                            } -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter -Verifiable                        }

                        It 'Should throw the correct error message' {
                            { Set-TargetResource @defaultParameters } | Should -Throw 'Unable to find WMI object Win32_OperatingSystem.'
                        }
                    }
                }

                Context 'When configuring a named instance that are already initialized' {
                    BeforeAll {
                        $mockDynamic_SqlBuildVersion = '13.0.4001.0'
                        $mockDynamicIsInitialized = $true

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                ReportServerReservedUrl = $mockReportServerApplicationUrl
                                ReportsReservedUrl      = $mockReportsApplicationUrl
                            }
                        }

                        Mock -CommandName Test-TargetResource -MockWith {
                            return $true
                        }

                        $testParameters = @{
                            InstanceName                 = $mockNamedInstanceName
                            DatabaseServerName           = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName         = $mockReportingServicesDatabaseNamedInstanceName
                            ReportServerVirtualDirectory = 'ReportServer_NewName'
                            ReportsVirtualDirectory      = 'Reports_NewName'
                            ReportServerReservedUrl      = 'https://+:4443'
                            ReportsReservedUrl           = 'https://+:4443'
                            UseSsl                       = $true
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-CimInstance `
                            -MockWith $mockGetCimInstance_ConfigurationSetting_NamedInstance `
                            -ParameterFilter $mockGetCimInstance_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-CimInstance `
                            -MockWith $mockGetCimInstance_Language `
                            -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter `
                            -Verifiable
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetSecureConnectionLevel'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportsApplicationName
                        } -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'InitializeReportServer'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetDatabaseConnection'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'GenerateDatabaseRightsScript'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'GenerateDatabaseCreationScript'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
                        } -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Restart-ReportingServicesService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When configuring a named instance that are already initialized, suppress restart' {
                    BeforeAll {
                        $mockDynamic_SqlBuildVersion = '13.0.4001.0'
                        $mockDynamicIsInitialized = $true

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                ReportServerReservedUrl = $mockReportServerApplicationUrl
                                ReportsReservedUrl      = $mockReportsApplicationUrl
                            }
                        }

                        Mock -CommandName Test-TargetResource -MockWith {
                            return $true
                        }

                        $testParameters = @{
                            InstanceName                 = $mockNamedInstanceName
                            DatabaseServerName           = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName         = $mockReportingServicesDatabaseNamedInstanceName
                            ReportServerVirtualDirectory = 'ReportServer_NewName'
                            ReportsVirtualDirectory      = 'Reports_NewName'
                            ReportServerReservedUrl      = 'https://+:4443'
                            ReportsReservedUrl           = 'https://+:4443'
                            UseSsl                       = $true
                            SuppressRestart              = $true
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-CimInstance `
                            -MockWith $mockGetCimInstance_ConfigurationSetting_NamedInstance `
                            -ParameterFilter $mockGetCimInstance_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-CimInstance `
                            -MockWith $mockGetCimInstance_Language `
                            -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter `
                            -Verifiable
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetSecureConnectionLevel'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportsApplicationName
                        } -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'InitializeReportServer'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetDatabaseConnection'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'GenerateDatabaseRightsScript'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'GenerateDatabaseCreationScript'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
                        } -Exactly -Times 2 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Restart-ReportingServicesService -Exactly -Times 0 -Scope It
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
                            InstanceName         = $mockDefaultInstanceName
                            DatabaseServerName   = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName = $mockReportingServicesDatabaseDefaultInstanceName
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-CimInstance `
                            -MockWith $mockGetCimInstance_ConfigurationSetting_DefaultInstance `
                            -ParameterFilter $mockGetCimInstance_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-CimInstance `
                            -MockWith $mockGetCimInstance_Language `
                            -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter `
                            -Verifiable
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'RemoveURL'
                        } -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'InitializeReportServer'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetDatabaseConnection'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'GenerateDatabaseRightsScript'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'GenerateDatabaseCreationScript'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationNameLegacy
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Invoke-RsCimMethod -ParameterFilter {
                            $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationNameLegacy
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Restart-ReportingServicesService -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "SqlRS\Test-TargetResource" -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                Context 'When Reporting Services are not initialized' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized = $false
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName         = $mockNamedInstanceName
                            DatabaseServerName   = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When Report Server virtual directory is different' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized                = $true
                                ReportServerVirtualDirectory = $mockVirtualDirectoryReportServerName
                                ReportsVirtualDirectory      = $mockVirtualDirectoryReportsName
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName                 = $mockNamedInstanceName
                            DatabaseServerName           = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName         = $mockReportingServicesDatabaseNamedInstanceName
                            ReportsVirtualDirectory      = $mockVirtualDirectoryReportsName
                            ReportServerVirtualDirectory = 'ReportServer_NewName'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When Report Server virtual directory is different' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized                = $true
                                ReportServerVirtualDirectory = $mockVirtualDirectoryReportServerName
                                ReportsVirtualDirectory      = $mockVirtualDirectoryReportsName
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName                 = $mockNamedInstanceName
                            DatabaseServerName           = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName         = $mockReportingServicesDatabaseNamedInstanceName
                            ReportServerVirtualDirectory = $mockVirtualDirectoryReportServerName
                            ReportsVirtualDirectory      = 'Reports_NewName'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When Report Server Report Server reserved URLs is different' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized           = $true
                                ReportServerReservedUrl = $mockReportServerApplicationUrl
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName            = $mockNamedInstanceName
                            DatabaseServerName      = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName    = $mockReportingServicesDatabaseNamedInstanceName
                            ReportServerReservedUrl = 'https://+:443'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When Report Server Reports reserved URLs is different' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized      = $true
                                ReportsReservedUrl = $mockReportServerApplicationUrl
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName         = $mockNamedInstanceName
                            DatabaseServerName   = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            ReportsReservedUrl   = 'https://+:443'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                $mockDynamicSecureConnectionLevel = 0 # Do not use SSL

                Context 'When SSL is not used' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                IsInitialized      = $true
                                UseSsl             = $false
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName         = $mockNamedInstanceName
                            DatabaseServerName   = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            UseSsl               = $true
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
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
                        InstanceName         = $mockNamedInstanceName
                        DatabaseServerName   = $mockReportingServicesDatabaseServerName
                        DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                    }
                }

                It 'Should return state as in desired state' {
                    $resultTestTargetResource = Test-TargetResource @defaultParameters
                    $resultTestTargetResource | Should -Be $true
                }
            }

            Assert-VerifiableMock
        }

        Describe "SqlRS\Invoke-RsCimMethod" -Tag 'Helper' {
            BeforeAll {
                $cimInstance = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                    'MSReportServer_ConfigurationSetting'
                    'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
                )
            }

            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName Invoke-CimMethod -MockWith {
                        return @{
                            HRESULT = 0
                        }
                    } -Verifiable
                }

                Context 'When calling Invoke-CimMethod without arguments' {
                    It 'Should call Invoke-CimMethod without throwing an error' {
                        $invokeRsCimMethodParameters = @{
                            CimInstance = $cimInstance
                            MethodName  = 'AnyMethod'
                        }

                        $resultTestTargetResource = Invoke-RsCimMethod @invokeRsCimMethodParameters
                        $resultTestTargetResource.HRESULT | Should -Be 0

                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter {
                            $MethodName -eq 'AnyMethod' -and $Arguments -eq $null
                        } -Exactly -Times 1
                    }
                }

                Context 'When calling Invoke-CimMethod with arguments' {
                    It 'Should call Invoke-CimMethod without throwing an error' {
                        $invokeRsCimMethodParameters = @{
                            CimInstance = $cimInstance
                            MethodName  = 'AnyMethod'
                            Arguments   = @{
                                Argument1 = 'ArgumentValue1'
                            }
                        }

                        $resultTestTargetResource = Invoke-RsCimMethod @invokeRsCimMethodParameters
                        $resultTestTargetResource.HRESULT | Should -Be 0

                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter {
                            $MethodName -eq 'AnyMethod' -and $Arguments.Argument1 -eq 'ArgumentValue1'
                        } -Exactly -Times 1
                    }
                }
            }

            Context 'When calling a method that fails with an error' {
                Context 'When Invoke-CimMethod fails and returns an object with a Error property' {
                    BeforeAll {
                        Mock -CommandName Invoke-CimMethod -MockWith {
                            return @{
                                HRESULT = 1
                                Error   = 'Something went wrong'
                            }
                        } -Verifiable
                    }

                    It 'Should call Invoke-CimMethod and throw the correct error' {
                        $invokeRsCimMethodParameters = @{
                            CimInstance = $cimInstance
                            MethodName  = 'AnyMethod'
                        }

                        { Invoke-RsCimMethod @invokeRsCimMethodParameters } | Should -Throw 'Method AnyMethod() failed with an error. Error: Something went wrong (HRESULT:1)'

                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter {
                            $MethodName -eq 'AnyMethod'
                        } -Exactly -Times 1
                    }
                }

                Context 'When Invoke-CimMethod fails and returns an object with a ExtendedErrors property' {
                    BeforeAll {
                        Mock -CommandName Invoke-CimMethod -MockWith {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'HRESULT' -Value 1 -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ExtendedErrors' -Value @('Something went wrong', 'Another thing went wrong') -PassThru -Force
                        } -Verifiable
                    }

                    It 'Should call Invoke-CimMethod and throw the correct error' {
                        $invokeRsCimMethodParameters = @{
                            CimInstance = $cimInstance
                            MethodName  = 'AnyMethod'
                        }

                        { Invoke-RsCimMethod @invokeRsCimMethodParameters } | Should -Throw 'Method AnyMethod() failed with an error. Error: Something went wrong;Another thing went wrong (HRESULT:1)'

                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter {
                            $MethodName -eq 'AnyMethod'
                        } -Exactly -Times 1
                    }
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
