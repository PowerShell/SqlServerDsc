$script:DSCModuleName      = 'SQLServerDsc'
$script:DSCResourceName    = 'MSFT_SqlServerEndpointPermission'

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
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockNodeName = 'localhost'
        $mockInstanceName = 'SQL2016'
        $mockPrincipal = 'COMPANY\SqlServiceAcct'
        $mockOtherPrincipal = 'COMPANY\OtherAcct'
        $mockEndpointName = 'DefaultEndpointMirror'

        $mockDynamicEndpointName = $mockEndpointName

        $script:mockMethodGrantRan = $false
        $script:mockMethodRevokeRan = $false

        $mockConnectSql = {
            return New-Object Object |
                Add-Member -MemberType ScriptProperty -Name 'Endpoints' {
                    return @(
                        @{
                            # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                            $mockDynamicEndpointName = New-Object Object |
                                                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockEndpointName -PassThru |
                                                        Add-Member -MemberType ScriptMethod -Name 'EnumObjectPermissions' {
                                                            param($permissionSet)
                                                            return @(
                                                                (New-Object Object |
                                                                    Add-Member -MemberType NoteProperty Grantee $mockDynamicPrincipal -PassThru |
                                                                    Add-Member -MemberType NoteProperty PermissionState 'Grant' -PassThru
                                                                )
                                                            )
                                                        } -PassThru |
                                                        Add-Member -MemberType ScriptMethod -Name 'Grant' {
                                                            param(
                                                                $permissionSet,
                                                                $mockPrincipal
                                                            )

                                                            $script:mockMethodGrantRan = $true
                                                        } -PassThru |
                                                        Add-Member -MemberType ScriptMethod -Name 'Revoke' {
                                                            param(
                                                                $permissionSet,
                                                                $mockPrincipal
                                                            )

                                                            $script:mockMethodRevokeRan = $true
                                                        } -PassThru -Force
                        }
                    )
                } -PassThru -Force
        }

        $defaultParameters = @{
            InstanceName = $mockInstanceName
            NodeName = $mockNodeName
            Name = $mockEndpointName
            Principal = $mockPrincipal
        }

        Describe 'MSFT_SqlServerEndpointPermission\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            $mockDynamicPrincipal = $mockOtherPrincipal

            Context 'When the system is not in the desired state' {
                It 'Should return the desired state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.NodeName | Should -Be $testParameters.NodeName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.Principal | Should -Be $testParameters.Principal
                }

                It 'Should not return any permissions' {
                    $result = Get-TargetResource @testParameters
                    $result.Permission | Should -Be ''
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                $mockDynamicEndpointName = 'UnknownEndPoint'

                Context 'When endpoint is missing' {
                    It 'Should throw the correct error message' {
                        { Get-TargetResource @testParameters } | Should -Throw 'Got unexpected result from Get-TargetResource. No change is made. InnerException: Endpoint ''DefaultEndpointMirror'' does not exist'

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointName = $mockEndpointName
            }

            $mockDynamicPrincipal = $mockPrincipal

            Context 'When the system is in the desired state' {
                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.NodeName | Should -Be $testParameters.NodeName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.Principal | Should -Be $testParameters.Principal
                }

                It 'Should return the permissions passed as parameter' {
                    $result = Get-TargetResource @testParameters
                    $result.Permission | Should -Be 'CONNECT'
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlServerEndpointPermission\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicPrincipal = $mockOtherPrincipal

                It 'Should return that desired state is absent when wanted desired state is to be Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Permission'] = 'CONNECT'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                $mockDynamicPrincipal = $mockPrincipal

                It 'Should return that desired state is absent when wanted desired state is to be Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['Permission'] = 'CONNECT'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state' {
                $mockDynamicPrincipal = $mockPrincipal

                It 'Should return that desired state is present when wanted desired state is to be Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Permission'] = 'CONNECT'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                $mockDynamicPrincipal = $mockOtherPrincipal

                It 'Should return that desired state is present when wanted desired state is to be Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['Permission'] = 'CONNECT'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlServerEndpointPermission\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicPrincipal = $mockOtherPrincipal
                $script:mockMethodGrantRan = $false
                $script:mockMethodRevokeRan = $false

                It 'Should call the the method Grant when desired state is to be Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Permission'] = 'CONNECT'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodGrantRan | Should -Be $true
                    $script:mockMethodRevokeRan | Should -Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                }

                $mockDynamicPrincipal = $mockPrincipal
                $script:mockMethodGrantRan = $false
                $script:mockMethodRevokeRan = $false

                It 'Should call the the method Revoke when desired state is to be Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['Permission'] = 'CONNECT'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodGrantRan | Should -Be $false
                    $script:mockMethodRevokeRan | Should -Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                }

                $mockDynamicEndpointName = 'UnknownEndPoint'

                Context 'When endpoint is missing' {
                    It 'Should throw the correct error message' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Absent'
                            }
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should -Throw 'Endpoint ''DefaultEndpointMirror'' does not exist'

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointName = $mockEndpointName
            }

            Context 'When the system is in the desired state' {
                $mockDynamicPrincipal = $mockPrincipal
                $script:mockMethodGrantRan = $false
                $script:mockMethodRevokeRan = $false

                It 'Should not call Grant() or Revoke() method when desired state is already Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Permission'] = 'CONNECT'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodGrantRan | Should -Be $false
                    $script:mockMethodRevokeRan | Should -Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                $mockDynamicPrincipal = $mockOtherPrincipal
                $script:mockMethodGrantRan = $false
                $script:mockMethodRevokeRan = $false

                It 'Should not call Grant() or Revoke() method when desired state is already Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['Permission'] = 'CONNECT'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodGrantRan | Should -Be $false
                    $script:mockMethodRevokeRan | Should -Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
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
