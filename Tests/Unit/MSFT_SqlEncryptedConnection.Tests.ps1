$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlEncryptedConnection'

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
    -DSCModuleName $script:DSCModuleName   `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SQLPSStub.psm1') -Global -Force
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockNamedInstanceName   = 'INSTANCE'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockThumbprint          = '123456789'
        $mockServiceAccount      = 'SqlSvc'


        Describe "SqlEncryptedConnection\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $mockDynamic_SqlBuildVersion = '13.0.4001.0'

                $defaultParameters  = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    Ensure          = 'Present'
                }
            }

            Context 'When the system is in the desired state' {
                Mock -CommandName Get-EncryptedConnectionSettings -MockWith {return @{ForceEncryption = $true; Certificate = $mockThumbprint}} -Verifiable

                It 'Should return the the state as initialized' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSettings -Exactly -Times 1 -Scope It
                }

            }

            Context 'When the system is not in the desired state' {
                Mock -CommandName Get-EncryptedConnectionSettings -MockWith {return @{ForceEncryption = $true; Certificate = '987654321'}} -Verifiable

                It 'Should return the state as not initialized' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Not -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSettings -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "SqlEncryptedConnection\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                $defaultParameters = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    Ensure          = 'Present'
                }

                $defaultAbsentParameters = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    Ensure          = 'Absent'
                }

                Mock -CommandName Set-EncryptedConnectionSettings -Verifiable
                Mock -CommandName Set-CertificatePermission -Verifiable
                Mock -CommandName Restart-SqlService -Verifiable
            }

            Context 'When the system is not in the desired state' {

                Context 'When only certificate permissions arent set' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = '987654321'
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $false
                            Ensure          = 'Present'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $true}

                    It 'Should configure only ForceEncryption and Certificate values' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSettings -Exactly -Times 1 -Scope It

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
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false}
                    It 'Should configure only certificate permissions' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSettings -Exactly -Times 0 -Scope It

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
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false}

                    It 'Should configure Encryption settings and certificate permissions' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSettings -Exactly -Times 1 -Scope It

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
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false}

                    It 'Should configure Encryption settings setting certificate to empty string' {
                        { Set-TargetResource @defaultAbsentParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSettings -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe "SqlEncryptedConnection\Test-TargetResource" -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                Context 'When ForceEncryption is not configured properly' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $false
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
                                Ensure          = 'Present'
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

                        Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Absent'
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
    }
}
finally
{
    Invoke-TestCleanup
}
