<#
    .SYNOPSIS
        Automated unit test for DSC_SqlServerSecureConnection DSC resource.

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
$script:dscResourceName = 'DSC_SqlServerSecureConnection'

function Invoke-TestSetup
{
    $script:timer = [System.Diagnostics.Stopwatch]::StartNew()

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

    # Load the default SQL Module stub
    Import-SQLModuleStub
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Write-Verbose -Message ('Test {1} ran for {0} minutes' -f ([System.TimeSpan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString('mm\:ss'), $script:dscResourceName) -Verbose
    $script:timer.Stop()
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        class MockedAccessControl
        {
            [hashtable]$Access = @{
                IdentityReference = 'Everyone'
                FileSystemRights  = @{
                    value__ = '131209'
                }
            }

            [void] AddAccessRule([System.Security.AccessControl.FileSystemAccessRule] $object)
            {
            }
        }

        class MockedGetItem
        {
            [string] $Thumbprint = '1a11ab1ab1a11111a1111ab111111ab11abcdefa'
            [string] $PSPath = 'PathToItem'
            [string] $Path = 'PathToItem'
            [MockedAccessControl]$ACL = [MockedAccessControl]::new()
            [hashtable]$PrivateKey = @{
                CspKeyContainerInfo = @{
                    UniqueKeyContainerName = 'key'
                }
            }

            [MockedGetItem] GetAccessControl()
            {
                return $this
            }
        }

        $mockNamedInstanceName = 'INSTANCE'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockThumbprint = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
        $mockServiceAccount = 'SqlSvc'

        Describe 'SqlServerSecureConnection\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $mockDynamic_SqlBuildVersion = '13.0.4001.0'

                $defaultParameters = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    Ensure          = 'Present'
                }
            }

            Context 'When the system is in the desired state and Ensure is Present' {
                Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                    return @{
                        ForceEncryption = $true
                        Certificate     = $mockThumbprint
                    }
                } -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                It 'Should return the the state of present' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -BeExactly $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Test-CertificatePermission -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq $mockThumbprint.ToLower() }
                }
            }

            Context 'When the system is not in the desired state and Ensure is Present' {
                Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                    return @{
                        ForceEncryption = $false
                        Certificate     = '987654321'
                    }
                } -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                It "Should return the state of absent when certificate thumbprint and certificate permissions don't match." {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Not -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $false
                    $resultGetTargetResource.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and Ensure is Present' {
                Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                    return @{
                        ForceEncryption = $true
                        Certificate     = '987654321'
                    }
                } -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                It 'Should return the state of absent when certificate permissions match but encryption settings dont' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Not -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and Ensure is Present' {
                Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                    return @{
                        ForceEncryption = $true
                        Certificate     = $mockThumbprint
                    }
                } -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                It 'Should return the state of absent when certificate permissions dont match but encryption settings do' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            $defaultParameters.Ensure = 'Absent'

            Context 'When the system is in the desired state and Ensure is Absent' {
                Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                    return @{
                        ForceEncryption = $false
                        Certificate     = ''
                    }
                } -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                It 'Should return the the state of absent' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -BeNullOrEmpty
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $false
                    $resultGetTargetResource.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and Ensure is Absent' {
                Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                    return @{
                        ForceEncryption = $true
                        Certificate     = $mockThumbprint
                    }
                } -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                It 'Should return the the state of present' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and Ensure is Absent' {
                Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                    return @{
                        ForceEncryption = $false
                        Certificate     = $mockThumbprint
                    }
                } -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                It 'Should return the the state of present when ForceEncryption is False but a thumbprint exist.' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $false
                    $resultGetTargetResource.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and Ensure is Absent' {
                Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                    return @{
                        ForceEncryption = $true
                        Certificate     = ''
                    }
                } -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                It 'Should return the the state of present when Certificate is null but ForceEncryption is True.' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -BeNullOrEmpty
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'SqlServerSecureConnection\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $defaultParameters = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    SuppressRestart = $false
                    Ensure          = 'Present'
                }

                $defaultAbsentParameters = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    Ensure          = 'Absent'
                }

                Mock -CommandName Set-EncryptedConnectionSetting -Verifiable
                Mock -CommandName Set-CertificatePermission -Verifiable
                Mock -CommandName Restart-SqlService -Verifiable
            }

            Context 'When the system is not in the desired state' {

                Context 'When Thumbprint contain upper-case' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint.ToUpper()
                            }
                        } -Verifiable
                    }

                    It 'Should configure with lower-case' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq $mockThumbprint.ToLower() }
                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq $mockThumbprint.ToLower() }
                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When SuppressRestart is true' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint.ToUpper()
                            }
                        } -Verifiable
                    }

                    $defaultParameters.SuppressRestart = $true

                    It 'Should suppress restarting the SQL service' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq $mockThumbprint.ToLower() }
                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq $mockThumbprint.ToLower() }
                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                    }

                    $defaultParameters.SuppressRestart = $false
                }

                Context 'When only certificate permissions are set' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $false
                            Ensure          = 'Present'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                    It 'Should configure only ForceEncryption and Certificate thumbprint' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When there is no certificate permissions set' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                    It 'Should configure only certificate permissions' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSetting -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When no settings are configured' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = '987654321'
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $false
                            Ensure          = 'Present'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                    It 'Should configure Encryption settings and certificate permissions' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When ensure is absent' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Absent'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                    It 'Should configure Encryption settings setting certificate to empty string' {
                        { Set-TargetResource @defaultAbsentParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe 'SqlServerSecureConnection\Test-TargetResource' -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                Context 'When ForceEncryption is not configured properly' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $false
                                Ensure          = 'Absent'
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When Thumbprint is not configured properly' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = '987654321'
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $true
                                Ensure          = 'Absent'
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When certificate permission is not set' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $true
                                Ensure          = 'Absent'
                            }
                        } -Verifiable

                        Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When Ensure is Absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $true
                                Ensure          = 'Absent'
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
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
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    } -Verifiable

                    Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                    $testParameters = @{
                        InstanceName    = $mockNamedInstanceName
                        Thumbprint      = $mockThumbprint
                        ServiceAccount  = $mockServiceAccount
                        ForceEncryption = $true
                        Ensure          = 'Present'
                    }
                }

                It 'Should return state as in desired state' {
                    $resultTestTargetResource = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should -Be $true
                }
            }
        }

        Describe 'SqlServerSecureConnection\Get-EncryptedConnectionSetting' -Tag 'Helper' {

            Mock -CommandName 'Get-ItemProperty' -MockWith {
                return @{
                    ForceEncryption = '1'
                }
            } -ParameterFilter { $Name -eq 'ForceEncryption' } -Verifiable
            Mock -CommandName 'Get-ItemProperty' -MockWith {
                return @{
                    Certificate = '12345678'
                }
            } -ParameterFilter { $Name -eq 'Certificate' } -Verifiable

            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName 'Get-SqlEncryptionValue' -MockWith {
                        return [MockedGetItem]::new()
                    } -Verifiable
                }

                It 'Should return hashtable with ForceEncryption and Certificate' {
                    $result = Get-EncryptedConnectionSetting -InstanceName 'NamedInstance'
                    $result.Certificate | Should -Be '12345678'
                    $result.ForceEncryption | Should -Be 1
                    $result | Should -BeOfType [Hashtable]
                    Assert-VerifiableMock
                }
            }

            Context 'When calling a method that executes unsuccesfuly' {
                BeforeAll {
                    Mock -CommandName 'Get-SqlEncryptionValue' -MockWith {
                        return $null
                    }
                }

                It 'Should return null' {
                    $result = Get-EncryptedConnectionSetting -InstanceName 'NamedInstance'
                    $result | Should -BeNullOrEmpty
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'SqlServerSecureConnection\Set-EncryptedConnectionSetting' -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName 'Get-SqlEncryptionValue' -MockWith {
                        return [MockedGetItem]::new()
                    }
                    Mock -CommandName 'Set-ItemProperty' -Verifiable
                }

                It 'Should not throw' {
                    { Set-EncryptedConnectionSetting -InstanceName 'NamedInstance' -Thumbprint '12345678' -ForceEncryption $true } | Should -Not -Throw
                    Assert-VerifiableMock
                }
            }

            Context 'When calling a method that executes unsuccesfuly' {
                BeforeAll {
                    Mock -CommandName 'Get-SqlEncryptionValue' -MockWith {
                        return $null
                    } -Verifiable
                    Mock -CommandName 'Set-ItemProperty'
                }

                It 'Should throw' {
                    { Set-EncryptedConnectionSetting -InstanceName 'NamedInstance' -Thumbprint '12345678' -ForceEncryption $true } | Should -Throw
                    Assert-MockCalled -CommandName 'Set-ItemProperty' -Times 0
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'SqlServerSecureConnection\Test-CertificatePermission' -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName 'Get-CertificateAcl' -MockWith {
                        return [MockedGetItem]::new()
                    } -Verifiable
                }

                It 'Should return True' {
                    $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'
                    $result | Should -be $true
                    Assert-VerifiableMock
                }
            }

            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName 'Get-CertificateAcl' -MockWith {
                        $mockedItem = [MockedGetItem]::new()
                        $mockedItem.ACL = $null
                        return $mockedItem
                    } -Verifiable
                }

                It 'Should return False when no permissions were found' {
                    $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'
                    $result | Should -be $false
                    Assert-VerifiableMock
                }
            }

            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName 'Get-CertificateAcl' -MockWith {
                        $mockedItem = [MockedGetItem]::new()
                        $mockedItem.ACL.FileSystemRights.Value__ = 1
                        return $mockedItem
                    } -Verifiable
                }

                It 'Should return False when the wrong permissions are added' {
                    $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'
                    $result | Should -be $false
                    Assert-VerifiableMock
                }
            }

            Context 'When calling a method that executes unsuccesfuly' {
                BeforeAll {
                    Mock -CommandName 'Get-CertificateAcl' -MockWith {
                        return $null
                    } -Verifiable
                }

                It 'Should return False' {
                    $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'
                    $result | Should -be $false
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'SqlServerSecureConnection\Set-CertificatePermission' -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName 'Get-CertificateAcl' -MockWith {
                        return [MockedGetItem]::new()
                    } -Verifiable
                    Mock -CommandName 'Set-Acl' -Verifiable
                }

                It 'Should not throw' {
                    { Set-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone' } | Should -Not -Throw
                    Assert-VerifiableMock
                }
            }

            Context 'When calling a method that executes unsuccesfuly' {
                BeforeAll {
                    Mock -CommandName 'Get-Item' -MockWith {
                        return $null
                    } -Verifiable
                    Mock -CommandName 'Get-ChildItem' -MockWith {
                        return $null
                    } -Verifiable
                }

                It 'Should throw' {
                    { Set-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone' } | Should -Throw
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'SqlServerSecureConnection\Get-CertificateAcl' -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName 'Get-ChildItem' -MockWith {
                        return [MockedGetItem]::new()
                    } -Verifiable

                    Mock -CommandName 'Get-Item' -MockWith {
                        return [MockedGetItem]::new()
                    } -Verifiable
                }

                It 'Should not throw' {
                    { Get-CertificateAcl -Thumbprint '12345678' } | Should -Not -Throw
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'SqlServerSecureConnection\Get-SqlEncryptionValue' -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName 'Get-ItemProperty' -MockWith {
                        return [MockedGetItem]::new()
                    } -Verifiable
                    Mock -CommandName 'Get-Item' -MockWith {
                        return [MockedGetItem]::new()
                    } -Verifiable
                }

                It 'Should not throw' {
                    { Get-SqlEncryptionValue -InstanceName $mockNamedInstanceName } | Should -Not -Throw
                    Assert-VerifiableMock
                }
            }

            Context 'When calling a method that execute unsuccessfully' {
                BeforeAll {
                    Mock -CommandName 'Get-ItemProperty' -MockWith {
                        throw "Error"
                    } -Verifiable
                    Mock -CommandName 'Get-Item' -MockWith {
                        return [MockedGetItem]::new()
                    } -Verifiable
                }

                It 'Should throw with expected message' {
                    { Get-SqlEncryptionValue -InstanceName $mockNamedInstanceName } | Should -Throw -ExpectedMessage "SQL instance '$mockNamedInstanceName' not found on SQL Server."
                    Assert-VerifiableMock
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
