<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlDatabaseUser DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlDatabaseUser'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $mockName = 'DatabaseUser1'
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockDatabaseName = 'TestDB'
        $mockLoginName = 'CONTOSO\Login1'
        $mockAsymmetricKeyName = 'AsymmetricKey1'
        $mockCertificateName = 'Certificate1'
        $mockLoginType = 'WindowsUser'
        $mockUserType = 'Login'
        $mockAuthenticationType = 'Windows'

        # Default parameters that are used for the It-blocks.
        $mockDefaultParameters = @{
            Name         = $mockName
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
            DatabaseName = $mockDatabaseName
            Verbose      = $true
        }

        Describe 'MSFT_SqlDatabaseUser\Get-TargetResource' -Tag 'Get' {
            Context 'When the system is in the desired state' {
                BeforeAll {
                    # Scriptblock for mocked object for mocks of Connect-SQL.
                    $mockSqlServerObject = {
                        New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name 'Databases' -Value {
                            return @(
                                @{
                                    $mockDatabaseName = New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDatabaseName -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'Users' -Value {
                                        return @(
                                            @{
                                                $mockName = New-Object -TypeName Object |
                                                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockName -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'AsymmetricKey' -Value $mockAsymmetricKeyName -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Certificate' -Value $mockCertificateName -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'AuthenticationType' -Value $mockAuthenticationType -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'LoginType' -Value $mockLoginType -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Login' -Value $mockLoginName -PassThru -Force
                                            }
                                        )
                                    } -PassThru -Force
                                }
                            )
                        } -PassThru -Force
                    }

                    Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject
                }

                AfterEach {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                Context 'When the configuration is absent' {
                    BeforeAll {
                        $mockMissingName = 'MissingUser1'

                        $getTargetResourceParameters = $mockDefaultParameters.Clone()
                        $getTargetResourceParameters['Name'] = $mockMissingName
                    }

                    It 'Should return the state as absent' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Ensure | Should -Be 'Absent'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @getTargetResourceParameters
                        $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                        $result.DatabaseName | Should -Be $getTargetResourceParameters.DatabaseName
                        $result.Name | Should -Be $mockMissingName
                    }

                    It 'Should return $null for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.LoginName | Should -BeNullOrEmpty
                        $getTargetResourceResult.AsymmetricKeyName | Should -BeNullOrEmpty
                        $getTargetResourceResult.CertificateName | Should -BeNullOrEmpty
                        $getTargetResourceResult.AuthenticationType | Should -BeNullOrEmpty
                        $getTargetResourceResult.LoginType | Should -BeNullOrEmpty
                        $getTargetResourceResult.UserType | Should -BeNullOrEmpty
                    }
                }

                Context 'When the configuration is present' {
                    BeforeAll {
                        $getTargetResourceParameters = $mockDefaultParameters.Clone()
                    }

                    It 'Should return the state as present' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Ensure | Should -Be 'Present'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @getTargetResourceParameters
                        $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                        $result.DatabaseName | Should -Be $getTargetResourceParameters.DatabaseName
                        $result.Name | Should -Be $getTargetResourceParameters.Name
                    }

                    It 'Should return the correct values for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.LoginName | Should -Be $mockLoginName
                        $getTargetResourceResult.AsymmetricKeyName | Should -Be $mockAsymmetricKeyName
                        $getTargetResourceResult.CertificateName | Should -Be $mockCertificateName
                        $getTargetResourceResult.AuthenticationType | Should -Be $mockAuthenticationType
                        $getTargetResourceResult.LoginType | Should -Be 'WindowsUser'
                        $getTargetResourceResult.UserType | Should -Be $mockUserType
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the database name does not exist' {
                    BeforeAll {
                        Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject

                        $mockMissingName = 'MissingUser1'
                        $mockMissingDatabaseName = 'MissingDatabase1'

                        $getTargetResourceParameters = $mockDefaultParameters.Clone()
                        $getTargetResourceParameters['DatabaseName'] = $mockMissingDatabaseName
                        $getTargetResourceParameters['Name'] = $mockMissingName
                    }

                    It 'Should throw the correct error' {
                        {
                            Get-TargetResource @getTargetResourceParameters
                        } | Should -Throw ($script:localizedData.DatabaseNotFound -f $mockMissingDatabaseName)

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlDatabaseUser\Test-TargetResource' -Tag 'Test' {
            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure             = 'Absent'
                                Name               = $mockName
                                ServerName         = $mockServerName
                                InstanceName       = $mockInstanceName
                                DatabaseName       = $mockDatabaseName
                                LoginName          = $null
                                AsymmetricKeyName  = $null
                                CertificateName    = $null
                                UserType           = $null
                                AuthenticationType = $null
                                LoginType          = $null
                            }
                        }

                        $testTargetResourceParameters = $mockDefaultParameters.Clone()
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is present' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure             = 'Present'
                                Name               = $mockName
                                ServerName         = $mockServerName
                                InstanceName       = $mockInstanceName
                                DatabaseName       = $mockDatabaseName
                                LoginName          = $mockLoginName
                                AsymmetricKeyName  = $null
                                CertificateName    = $null
                                UserType           = $mockUserType
                                AuthenticationType = $mockAuthenticationType
                                LoginType          = $mockLoginType
                            }
                        }

                        $testTargetResourceParameters = $mockDefaultParameters.Clone()
                        $testTargetResourceParameters['UserType'] = $mockUserType
                        $testTargetResourceParameters['LoginName'] = $mockLoginName
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                            }
                        }

                        $testTargetResourceParameters = $mockDefaultParameters.Clone()
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration should be present' {
                    Context 'When the property LoginName is not in desired state' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure            = 'Present'
                                    LoginName         = 'OtherLogin1'
                                    AsymmetricKeyName = $null
                                    CertificateName   = $null
                                    UserType          = 'Login'
                                }
                            }

                            $testTargetResourceParameters = $mockDefaultParameters.Clone()
                            $testTargetResourceParameters['LoginName'] = $mockLoginName
                            $testTargetResourceParameters['UserType'] = 'Login'
                        }

                        It 'Should return the state as $false' {
                            $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                            $testTargetResourceResult | Should -Be $false

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the property AsymmetricKeyName is not in desired state' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure            = 'Present'
                                    LoginName         = $null
                                    AsymmetricKeyName = 'OtherAsymmetricKey1'
                                    CertificateName   = $null
                                    UserType          = 'AsymmetricKey'
                                }
                            }

                            $testTargetResourceParameters = $mockDefaultParameters.Clone()
                            $testTargetResourceParameters['AsymmetricKeyName'] = $mockAsymmetricKeyName
                            $testTargetResourceParameters['UserType'] = 'AsymmetricKey'
                        }

                        It 'Should return the state as $false' {
                            $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                            $testTargetResourceResult | Should -Be $false

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the property CertificateName is not in desired state' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure            = 'Present'
                                    LoginName         = $null
                                    AsymmetricKeyName = $null
                                    CertificateName   = 'OtherCertificate1'
                                    UserType          = 'Certificate'
                                }
                            }

                            $testTargetResourceParameters = $mockDefaultParameters.Clone()
                            $testTargetResourceParameters['CertificateName'] = $mockCertificateName
                            $testTargetResourceParameters['UserType'] = 'Certificate'
                        }

                        It 'Should return the state as $false' {
                            $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                            $testTargetResourceResult | Should -Be $false

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the property UserType is not in desired state' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure            = 'Present'
                                    LoginName         = $null
                                    AsymmetricKeyName = $null
                                    CertificateName   = 'OtherCertificate1'
                                    UserType          = 'Certificate'
                                }
                            }

                            $testTargetResourceParameters = $mockDefaultParameters.Clone()
                            $testTargetResourceParameters['LoginName'] = $mockLoginName
                            $testTargetResourceParameters['UserType'] = 'Login'
                        }

                        It 'Should return the state as $false' {
                            $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                            $testTargetResourceResult | Should -Be $false

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlDatabaseUser\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Invoke-Query
                Mock -CommandName Assert-SqlLogin
                Mock -CommandName Assert-DatabaseAsymmetricKey
                Mock -CommandName Assert-DatabaseCertificate
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure             = 'Absent'
                                Name               = $mockName
                                ServerName         = $mockServerName
                                InstanceName       = $mockInstanceName
                                DatabaseName       = $mockDatabaseName
                                LoginName          = $null
                                AsymmetricKeyName  = $null
                                CertificateName    = $null
                                UserType           = $null
                                AuthenticationType = $null
                                LoginType          = $null
                            }
                        }

                        $setTargetResourceParameters = $mockDefaultParameters.Clone()
                        $setTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should not throw and should call the correct mocks' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Invoke-Query -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When the configuration is present' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure             = 'Present'
                                Name               = $mockName
                                ServerName         = $mockServerName
                                InstanceName       = $mockInstanceName
                                DatabaseName       = $mockDatabaseName
                                LoginName          = $mockLoginName
                                AsymmetricKeyName  = $null
                                CertificateName    = $null
                                UserType           = $mockUserType
                                AuthenticationType = $mockAuthenticationType
                                LoginType          = $mockLoginType
                            }
                        }

                        $setTargetResourceParameters = $mockDefaultParameters.Clone()
                        $setTargetResourceParameters['UserType'] = $mockUserType
                        $setTargetResourceParameters['LoginName'] = $mockLoginName
                    }

                    It 'Should not throw and should call the correct mocks' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Invoke-Query -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure             = 'Present'
                                Name               = $mockName
                                ServerName         = $mockServerName
                                InstanceName       = $mockInstanceName
                                DatabaseName       = $mockDatabaseName
                                LoginName          = $mockLoginName
                                AsymmetricKeyName  = $null
                                CertificateName    = $null
                                UserType           = $mockUserType
                                AuthenticationType = $mockAuthenticationType
                                LoginType          = $mockLoginType
                            }
                        }

                        $setTargetResourceParameters = $mockDefaultParameters.Clone()
                        $setTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should not throw and should call the correct mocks' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                            $Query -eq ('DROP USER [{0}];' -f $mockName)
                        } -Exactly -Times 1 -Scope It
                    }

                    Context 'When trying to drop a database user but Invoke-Query fails' {
                        BeforeAll {
                            Mock -CommandName Invoke-Query -MockWith {
                                throw
                            }

                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['Ensure'] = 'Absent'
                        }

                        It 'Should throw the correct error' {
                            {
                                Set-TargetResource @setTargetResourceParameters
                            } | Should -Throw ($script:localizedData.FailedDropDatabaseUser -f $mockName, $MockDatabaseName)

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Invoke-Query -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the configuration should be present' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure             = 'Absent'
                                Name               = $mockName
                                ServerName         = $mockServerName
                                InstanceName       = $mockInstanceName
                                DatabaseName       = $mockDatabaseName
                                LoginName          = $null
                                AsymmetricKeyName  = $null
                                CertificateName    = $null
                                UserType           = $null
                                AuthenticationType = $null
                                LoginType          = $null
                            }
                        }
                    }

                    Context 'When creating a database user with a login' {
                        BeforeAll {
                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['LoginName'] = $mockLoginName
                            $setTargetResourceParameters['UserType'] = 'Login'
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('CREATE USER [{0}] FOR LOGIN [{1}];' -f $mockName, $mockLoginName)
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When creating a database user without a login' {
                        BeforeAll {
                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['UserType'] = 'NoLogin'
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('CREATE USER [{0}] WITHOUT LOGIN;' -f $mockName)
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When creating a database user mapped to a certificate' {
                        BeforeAll {
                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['CertificateName'] = $mockCertificateName
                            $setTargetResourceParameters['UserType'] = 'Certificate'
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('CREATE USER [{0}] FOR CERTIFICATE [{1}];' -f $mockName, $mockCertificateName)
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When creating a database user mapped to an asymmetric key' {
                        BeforeAll {
                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['AsymmetricKeyName'] = $mockAsymmetricKeyName
                            $setTargetResourceParameters['UserType'] = 'AsymmetricKey'
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('CREATE USER [{0}] FOR ASYMMETRIC KEY [{1}];' -f $mockName, $mockAsymmetricKeyName)
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When trying to create a database user but Invoke-Query fails' {
                        BeforeAll {
                            Mock -CommandName Invoke-Query -MockWith {
                                throw
                            }

                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['UserType'] = 'NoLogin'
                        }

                        It 'Should throw the correct error' {
                            {
                                Set-TargetResource @setTargetResourceParameters
                            } | Should -Throw ($script:localizedData.FailedCreateDatabaseUser -f $mockName, $MockDatabaseName, 'NoLogin')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Invoke-Query -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When properties are not in desired state' {
                    Context 'When the database user has the wrong login name' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure             = 'Present'
                                    Name               = $mockName
                                    ServerName         = $mockServerName
                                    InstanceName       = $mockInstanceName
                                    DatabaseName       = $mockDatabaseName
                                    LoginName          = $mockLoginName
                                    AsymmetricKeyName  = $null
                                    CertificateName    = $null
                                    UserType           = $mockUserType
                                    AuthenticationType = $mockAuthenticationType
                                    LoginType          = 'WindowsUser'
                                }
                            }

                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['LoginName'] = 'OtherLogin1'
                            $setTargetResourceParameters['UserType'] = 'Login'
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('ALTER USER [{0}] WITH NAME = [{1}], LOGIN = [{2}];' -f $mockName, $mockName, 'OtherLogin1')
                            } -Exactly -Times 1 -Scope It
                        }

                        Context 'When trying to alter the login name but Invoke-Query fails' {
                            BeforeAll {
                                Mock -CommandName Invoke-Query -MockWith {
                                    throw
                                }
                            }

                            It 'Should throw the correct error' {
                                {
                                    Set-TargetResource @setTargetResourceParameters
                                } | Should -Throw ($script:localizedData.FailedUpdateDatabaseUser -f $mockName, $MockDatabaseName, 'Login')

                                Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                                Assert-MockCalled -CommandName Invoke-Query -Exactly -Times 1 -Scope It
                            }
                        }
                    }

                    Context 'When the database user has the wrong asymmetric key name' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure             = 'Present'
                                    Name               = $mockName
                                    ServerName         = $mockServerName
                                    InstanceName       = $mockInstanceName
                                    DatabaseName       = $mockDatabaseName
                                    LoginName          = $mockLoginName
                                    AsymmetricKeyName  = $mockAsymmetricKeyName
                                    CertificateName    = $null
                                    UserType           = 'AsymmetricKey'
                                    AuthenticationType = $mockAuthenticationType
                                    LoginType          = 'AsymmetricKey'
                                }
                            }

                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['AsymmetricKeyName'] = 'OtherAsymmetricKey1'
                            $setTargetResourceParameters['UserType'] = 'AsymmetricKey'
                            $setTargetResourceParameters['Force'] = $true
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('DROP USER [{0}];' -f $mockName)
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('CREATE USER [{0}] FOR ASYMMETRIC KEY [{1}];' -f $mockName, 'OtherAsymmetricKey1')
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the database user has the wrong certificate name' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure             = 'Present'
                                    Name               = $mockName
                                    ServerName         = $mockServerName
                                    InstanceName       = $mockInstanceName
                                    DatabaseName       = $mockDatabaseName
                                    LoginName          = $mockLoginName
                                    AsymmetricKeyName  = $mockAsymmetricKeyName
                                    CertificateName    = $null
                                    UserType           = 'Certificate'
                                    AuthenticationType = $mockAuthenticationType
                                    LoginType          = 'Certificate'
                                }
                            }

                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['CertificateName'] = 'OtherCertificate1'
                            $setTargetResourceParameters['UserType'] = 'Certificate'
                            $setTargetResourceParameters['Force'] = $true
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('DROP USER [{0}];' -f $mockName)
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('CREATE USER [{0}] FOR CERTIFICATE [{1}];' -f $mockName, 'OtherCertificate1')
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the database user has the wrong certificate name' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure             = 'Present'
                                    Name               = $mockName
                                    ServerName         = $mockServerName
                                    InstanceName       = $mockInstanceName
                                    DatabaseName       = $mockDatabaseName
                                    LoginName          = $mockLoginName
                                    AsymmetricKeyName  = $mockAsymmetricKeyName
                                    CertificateName    = $null
                                    UserType           = 'Certificate'
                                    AuthenticationType = $mockAuthenticationType
                                    LoginType          = 'Certificate'
                                }
                            }

                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['LoginName'] = 'OtherLogin1'
                            $setTargetResourceParameters['UserType'] = 'Login'
                            $setTargetResourceParameters['Force'] = $true
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('DROP USER [{0}];' -f $mockName)
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Invoke-Query -ParameterFilter {
                                $Query -eq ('CREATE USER [{0}] FOR LOGIN [{1}];' -f $mockName, 'OtherLogin1')
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the configuration has not opt-in to re-create a database user' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure             = 'Present'
                                    Name               = $mockName
                                    ServerName         = $mockServerName
                                    InstanceName       = $mockInstanceName
                                    DatabaseName       = $mockDatabaseName
                                    LoginName          = $mockLoginName
                                    AsymmetricKeyName  = $mockAsymmetricKeyName
                                    CertificateName    = $null
                                    UserType           = 'Certificate'
                                    AuthenticationType = $mockAuthenticationType
                                    LoginType          = 'Certificate'
                                }
                            }

                            $setTargetResourceParameters = $mockDefaultParameters.Clone()
                            $setTargetResourceParameters['LoginName'] = 'OtherLogin1'
                            $setTargetResourceParameters['UserType'] = 'Login'
                        }

                        It 'Should not throw and should call the correct mocks' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Throw  $script:localizedData.ForceNotEnabled

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Invoke-Query -Exactly -Times 0 -Scope It
                        }
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe 'Assert-Parameters' -Tag 'Helper' {
            BeforeAll {
                $mockUserType = 'NoLogin'
            }

            Context 'When parameter LoginName is provided, but with the wrong user type' {
                It 'Should throw the correct error' {
                    {
                        Assert-Parameters -LoginName 'AnyValue' -UserType $mockUserType
                    } | Should -Throw ($script:localizedData.LoginNameProvidedWithWrongUserType -f $mockUserType)
                }
            }

            Context 'When parameter CertificateName is provided, but with the wrong user type' {
                It 'Should throw the correct error' {
                    {
                        Assert-Parameters -CertificateName 'AnyValue' -UserType $mockUserType
                    } | Should -Throw ($script:localizedData.CertificateNameProvidedWithWrongUserType -f $mockUserType)
                }
            }

            Context 'When parameter AsymmetricKeyName is provided, but with the wrong user type' {
                It 'Should throw the correct error' {
                    {
                        Assert-Parameters -AsymmetricKeyName 'AnyValue' -UserType $mockUserType
                    } | Should -Throw ($script:localizedData.AsymmetricKeyNameProvidedWithWrongUserType -f $mockUserType)
                }
            }

            Context 'When parameter LoginName is not provided when providing the user type ''Login''' {
                It 'Should throw the correct error' {
                    {
                        Assert-Parameters -UserType 'Login'
                    } | Should -Throw ($script:localizedData.LoginUserTypeWithoutLoginName -f 'Login')
                }
            }

            Context 'When parameter AsymmetricKeyName is not provide when providing the user type ''AsymmetricKey''' {
                It 'Should throw the correct error' {
                    {
                        Assert-Parameters -UserType 'AsymmetricKey'
                    } | Should -Throw ($script:localizedData.AsymmetricKeyUserTypeWithoutAsymmetricKeyName -f 'AsymmetricKey')
                }
            }

            Context 'When parameter CertificateName is not provide when providing the user type ''Certificate''' {
                It 'Should throw the correct error' {
                    {
                        Assert-Parameters -UserType 'Certificate'
                    } | Should -Throw ($script:localizedData.CertificateUserTypeWithoutCertificateName -f 'Certificate')
                }
            }
        }

        Describe 'ConvertTo-UserType' -Tag 'Helper' {
            Context 'When converting to a user type' {
                BeforeAll {
                    $testCases = @(
                        @{
                            AuthenticationType = 'Windows'
                            LoginType          = 'WindowsUser'
                            ExpectedResult     = 'Login'
                        }
                        @{
                            AuthenticationType = 'Windows'
                            LoginType          = 'WindowsGroup'
                            ExpectedResult     = 'Login'
                        }
                        @{
                            AuthenticationType = 'Instance'
                            LoginType          = 'SqlLogin'
                            ExpectedResult     = 'Login'
                        }
                        @{
                            AuthenticationType = 'None'
                            LoginType          = 'SqlLogin'
                            ExpectedResult     = 'NoLogin'
                        }
                        @{
                            AuthenticationType = 'None'
                            LoginType          = 'AsymmetricKey'
                            ExpectedResult     = 'AsymmetricKey'
                        }
                        @{
                            AuthenticationType = 'None'
                            LoginType          = 'Certificate'
                            ExpectedResult     = 'Certificate'
                        }
                    )
                }

                It 'Should return the correct value when converting authentication type <AuthenticationType> and login type <LoginType>' -TestCases $testCases {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $AuthenticationType,

                        [Parameter()]
                        [System.String]
                        $LoginType,

                        [Parameter()]
                        [System.String]
                        $ExpectedResult
                    )

                    $convertToUserTypeResult = ConvertTo-UserType -AuthenticationType $AuthenticationType -LoginType $LoginType
                    $convertToUserTypeResult | Should -Be $ExpectedResult
                }

                Context 'When calling with an unsupported authentication type' {
                    BeforeAll {
                        $mockUnsupportedValue = 'UnsupportedValue'
                        $mockLoginType = 'SqlLogin'
                    }

                    It 'Should throw the correct error' {
                        {
                            ConvertTo-UserType -AuthenticationType $mockUnsupportedValue -LoginType $mockLoginType
                        } | Should -Throw ($script:localizedData.UnknownAuthenticationType -f $mockUnsupportedValue, $mockLoginType)
                    }
                }
            }
        }

        Describe 'Assert-SqlLogin' -Tag 'Helper' {
            BeforeAll {
                $mockSqlServerObject = {
                    New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name 'Logins' -Value {
                        return @(
                            @{
                                $mockLoginName = New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockLoginName -PassThru -Force
                            }
                        )
                    } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject
            }

            Context 'When the SQL login exist' {
                BeforeAll {
                    $assertSqlLoginParameters = $mockDefaultParameters.Clone()
                    $assertSqlLoginParameters['LoginName'] = $mockLoginName
                }

                It 'Should not throw any error' {
                    { Assert-SqlLogin @assertSqlLoginParameters } | Should -Not -Throw
                }
            }

            Context 'When the SQL login does not exist' {
                BeforeAll {
                    $assertSqlLoginParameters = $mockDefaultParameters.Clone()
                    $assertSqlLoginParameters['LoginName'] = 'AnyValue'
                }

                It 'Should throw the correct error' {
                    {
                        Assert-SqlLogin @assertSqlLoginParameters
                    } | Should -Throw ($script:localizedData.SqlLoginNotFound -f 'AnyValue')
                }
            }
        }

        Describe 'Assert-DatabaseCertificate' -Tag 'Helper' {
            BeforeAll {
                $mockSqlServerObject = {
                    New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name 'Databases' -Value {
                        return @(
                            @{
                                $mockDatabaseName = New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDatabaseName -PassThru |
                                Add-Member -MemberType ScriptProperty -Name 'Certificates' -Value {
                                    return @(
                                        @{
                                            $mockCertificateName = New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockCertificateName -PassThru -Force
                                        }
                                    )
                                } -PassThru -Force
                            }
                        )
                    } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject
            }

            Context 'When the certificate exist in the database' {
                BeforeAll {
                    $assertDatabaseCertificateParameters = $mockDefaultParameters.Clone()
                    $assertDatabaseCertificateParameters['CertificateName'] = $mockCertificateName
                }

                It 'Should not throw any error' {
                    { Assert-DatabaseCertificate @assertDatabaseCertificateParameters } | Should -Not -Throw
                }
            }

            Context 'When the certificate does not exist in the database' {
                BeforeAll {
                    $assertDatabaseCertificateParameters = $mockDefaultParameters.Clone()
                    $assertDatabaseCertificateParameters['CertificateName'] = 'AnyValue'
                }

                It 'Should throw the correct error' {
                    {
                        Assert-DatabaseCertificate @assertDatabaseCertificateParameters
                    } | Should -Throw ($script:localizedData.CertificateNotFound -f 'AnyValue', $mockDatabaseName)
                }
            }
        }

        Describe 'Assert-DatabaseAsymmetricKey' -Tag 'Helper' {
            BeforeAll {
                $mockSqlServerObject = {
                    New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name 'Databases' -Value {
                        return @(
                            @{
                                $mockDatabaseName = New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDatabaseName -PassThru |
                                Add-Member -MemberType ScriptProperty -Name 'AsymmetricKeys' -Value {
                                    return @(
                                        @{
                                            $mockAsymmetricKeyName = New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAsymmetricKeyName -PassThru -Force
                                        }
                                    )
                                } -PassThru -Force
                            }
                        )
                    } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject
            }

            Context 'When the asymmetric key exist in the database' {
                BeforeAll {
                    $assertDatabaseAsymmetricKeyParameters = $mockDefaultParameters.Clone()
                    $assertDatabaseAsymmetricKeyParameters['AsymmetricKeyName'] = $mockAsymmetricKeyName
                }

                It 'Should not throw any error' {
                    { Assert-DatabaseAsymmetricKey @assertDatabaseAsymmetricKeyParameters } | Should -Not -Throw
                }
            }

            Context 'When the asymmetric key does not exist in the database' {
                BeforeAll {
                    $assertDatabaseAsymmetricKeyParameters = $mockDefaultParameters.Clone()
                    $assertDatabaseAsymmetricKeyParameters['AsymmetricKeyName'] = 'AnyValue'
                }

                It 'Should throw the correct error' {
                    {
                        Assert-DatabaseAsymmetricKey @assertDatabaseAsymmetricKeyParameters
                    } | Should -Throw ($script:localizedData.AsymmetryKeyNotFound -f 'AnyValue', $mockDatabaseName)
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
