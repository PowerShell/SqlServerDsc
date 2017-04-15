$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerEndpointState'

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
    # Loading stub cmdlets
    Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SQLPSStub.psm1') -Force
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
        $mockEndpointName = 'DefaultEndpointMirror'
        $mockEndpointStateStarted = 'Started'
        $mockEndpointStateStopped = 'Stopped'

        $mockOtherEndpointName = 'OtherEndpoint'

        $mockDynamicEndpointName = $mockEndpointName
        $mockDynamicEndpointState = $mockEndpointStateStarted

        $mockConnectSql = {
            return New-Object Object |
                Add-Member -MemberType ScriptProperty -Name 'Endpoints' {
                    return @(
                        @{
                            # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                            $mockDynamicEndpointName = New-Object Object |
                                                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDynamicEndpointName -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value $mockDynamicEndpointState -PassThru -Force
                        }
                    )
                } -PassThru -Force
        }

        $defaultParameters = @{
            InstanceName = $mockInstanceName
            NodeName = $mockNodeName
            Name = $mockEndpointName
        }

        #endregion Pester Test Initialization

        Describe 'MSFT_xSQLServerEndpointState\Get-TargetResource' -Tag Get {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            $mockDynamicEndpointName = $mockEndpointName

            Context 'When the system is not in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Started, but the current state is Stopped' {
                    It 'Should not return the state as Started' {
                        $result = Get-TargetResource @testParameters
                        $result.State | Should Not Be $mockEndpointStateStarted
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.NodeName | Should Be $testParameters.NodeName
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.Name | Should Be $testParameters.Name
                    }

                    It 'Should call the mock function Connect-SQL' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Stopped, but the current state is Started' {
                    It 'Should not return the state as Stopped' {
                        $result = Get-TargetResource @testParameters
                        $result.State | Should Not Be $mockEndpointStateStopped
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.NodeName | Should Be $testParameters.NodeName
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.Name | Should Be $testParameters.Name
                    }

                    It 'Should call the mock function Connect-SQL' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointName = $mockOtherEndpointName

                Context 'When endpoint is missing' {
                    It 'Should throw the correct error message' {
                        { Get-TargetResource @testParameters } | Should Throw 'Unexpected result when trying to verify existence of endpoint 'DefaultEndpointMirror'. InnerException: Endpoint 'DefaultEndpointMirror' does not exist'

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointName = $mockEndpointName
            }

            Context 'When the system is in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state is Started' {
                    It 'Should return the state as Started' {
                        $result = Get-TargetResource @testParameters
                        $result.State | Should Be $mockEndpointStateStarted
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.NodeName | Should Be $testParameters.NodeName
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.Name | Should Be $testParameters.Name
                    }

                    It 'Should call the mock function Connect-SQL' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state is Stopped' {
                    It 'Should return the state as Stopped' {
                        $result = Get-TargetResource @testParameters
                        $result.State | Should Be $mockEndpointStateStopped
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.NodeName | Should Be $testParameters.NodeName
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.Name | Should Be $testParameters.Name
                    }

                    It 'Should call the mock function Connect-SQL' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMocks
        }

        Describe 'MSFT_xSQLServerEndpointState\Test-TargetResource' -Tag Test {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Started, but the current state is Stopped' {
                    It 'Should return that desired state as absent' {
                        $testParameters += @{
                            State = $mockEndpointStateStarted
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Stopped, but the current state is Started' {
                    It 'Should return that desired state as absent' {
                        $testParameters += @{
                            State = $mockEndpointStateStopped
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Started, and the current state is Started' {
                    It 'Should return that desired state as absent' {
                        $testParameters += @{
                            State = $mockEndpointStateStarted
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Stopped, and the current state is Stopped' {
                    It 'Should return that desired state as absent' {
                        $testParameters += @{
                            State = $mockEndpointStateStopped
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When Get-TargetResource returns nothing' {
                    It 'Should thor the correct error message' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return $null
                        } -Verifiable

                        { Test-TargetResource @testParameters } | Should Throw 'Got unexpected result from Get-TargetResource. No change is made.'

                        Assert-MockCalled Connect-SQL -Exactly -Times 0 -Scope It
                    }
                }
            }

            Assert-VerifiableMocks
        }

        Describe 'MSFT_xSQLServerEndpointState\Set-TargetResource' -Tag Set {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock Set-SqlHADREndpoint -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Started, but the current state is Stopped' {
                    It 'Should call the mock function Set-SqlHADREndpoint to set the state to Started' {
                        $testParameters += @{
                            State = $mockEndpointStateStarted
                        }

                        Set-TargetResource @testParameters

                        Assert-MockCalled Set-SqlHADREndpoint -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Stopped, but the current state is Started' {
                    It 'Should call the mock function Set-SqlHADREndpoint to set the state to Stopped' {
                        $testParameters += @{
                            State = $mockEndpointStateStopped
                        }

                        Set-TargetResource @testParameters

                        Assert-MockCalled Set-SqlHADREndpoint -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Started, and the current state is Started' {
                    It 'Should not call the mock function Set-SqlHADREndpoint' {
                        $testParameters += @{
                            State = $mockEndpointStateStarted
                        }

                        Set-TargetResource @testParameters

                        Assert-MockCalled Set-SqlHADREndpoint -Exactly -Times 0 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Stopped, and the current state is Stopped' {
                    It 'Should not call the mock function Set-SqlHADREndpoint' {
                        $testParameters += @{
                            State = $mockEndpointStateStopped
                        }

                        Set-TargetResource @testParameters

                        Assert-MockCalled Set-SqlHADREndpoint -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When Get-TargetResource returns nothing' {
                    It 'Should throw the correct error message' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return $null
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should Throw 'Got unexpected result from Get-TargetResource. No change is made.'

                        Assert-MockCalled Connect-SQL -Exactly -Times 0 -Scope It
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
