<#
    .SYNOPSIS
        Automated unit test for DSC_SqlServerEndpointState DSC resource.

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
$script:dscResourceName = 'DSC_SqlServerEndpointState'

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

    # Load the default SQL Module stub
    Import-SQLModuleStub
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $mockNodeName = 'localhost'
        $mockInstanceName = 'INSTANCE1'
        $mockEndpointName = 'DefaultEndpointMirror'
        $mockEndpointStateStarted = 'Started'
        $mockEndpointStateStopped = 'Stopped'

        $mockOtherEndpointName = 'OtherEndpoint'

        $mockDynamicEndpointName = $mockEndpointName
        $mockDynamicEndpointState = $mockEndpointStateStarted

        $mockConnectSql = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name 'Endpoints' -Value {
                return @(
                    @{
                        # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                        $mockDynamicEndpointName = New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDynamicEndpointName -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value $mockDynamicEndpointState -PassThru -Force
                    }
                )
            } -PassThru -Force
        }

        $defaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockNodeName
            Name         = $mockEndpointName
        }

        #endregion Pester Test Initialization

        Describe 'DSC_SqlServerEndpointState\Get-TargetResource' -Tag Get {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            $mockDynamicEndpointName = $mockEndpointName

            Context 'When the system is not in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Started, but the current state is Stopped' {
                    It 'Should not return the state as Started' {
                        $result = Get-TargetResource @testParameters
                        $result.State | Should -Not -Be $mockEndpointStateStarted
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.ServerName | Should -Be $testParameters.ServerName
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.Name | Should -Be $testParameters.Name
                    }

                    It 'Should call the mock function Connect-SQL' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Stopped, but the current state is Started' {
                    It 'Should not return the state as Stopped' {
                        $result = Get-TargetResource @testParameters
                        $result.State | Should -Not -Be $mockEndpointStateStopped
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.ServerName | Should -Be $testParameters.ServerName
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.Name | Should -Be $testParameters.Name
                    }

                    It 'Should call the mock function Connect-SQL' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointName = $mockOtherEndpointName

                Context 'When endpoint is missing' {
                    It 'Should throw the correct error message' {
                        { Get-TargetResource @testParameters } | Should -Throw ($script:localizedData.EndpointErrorVerifyExist -f $testParameters.Name)

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointName = $mockEndpointName
            }

            Context 'When the system is in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state is Started' {
                    It 'Should return the state as Started' {
                        $result = Get-TargetResource @testParameters
                        $result.State | Should -Be $mockEndpointStateStarted
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.ServerName | Should -Be $testParameters.ServerName
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.Name | Should -Be $testParameters.Name
                    }

                    It 'Should call the mock function Connect-SQL' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state is Stopped' {
                    It 'Should return the state as Stopped' {
                        $result = Get-TargetResource @testParameters
                        $result.State | Should -Be $mockEndpointStateStopped
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.ServerName | Should -Be $testParameters.ServerName
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.Name | Should -Be $testParameters.Name
                    }

                    It 'Should call the mock function Connect-SQL' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DSC_SqlServerEndpointState\Test-TargetResource' -Tag Test {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Started, but the current state is Stopped' {
                    It 'Should return that desired state as absent' {
                        $testParameters.Add('State', $mockEndpointStateStarted)

                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $false

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Stopped, but the current state is Started' {
                    It 'Should return that desired state as absent' {
                        $testParameters.Add('State', $mockEndpointStateStopped)

                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $false

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Started, and the current state is Started' {
                    It 'Should return that desired state as absent' {
                        $testParameters.Add('State', $mockEndpointStateStarted)

                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $true

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Stopped, and the current state is Stopped' {
                    It 'Should return that desired state as absent' {
                        $testParameters.Add('State', $mockEndpointStateStopped)

                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $true

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When Get-TargetResource returns nothing' {
                    It 'Should throw the correct error message' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return $null
                        } -Verifiable

                        { Test-TargetResource @testParameters } | Should -Throw $script:localizedData.UnexpectedErrorFromGet

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DSC_SqlServerEndpointState\Set-TargetResource' -Tag Set {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock Set-SqlHADREndpoint -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Started, but the current state is Stopped' {
                    It 'Should call the mock function Set-SqlHADREndpoint to set the state to Started' {
                        $testParameters.Add('State', $mockEndpointStateStarted)

                        Set-TargetResource @testParameters

                        Assert-MockCalled -CommandName Set-SqlHADREndpoint -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Stopped, but the current state is Started' {
                    It 'Should call the mock function Set-SqlHADREndpoint to set the state to Stopped' {
                        $testParameters.Add('State', $mockEndpointStateStopped)

                        Set-TargetResource @testParameters

                        Assert-MockCalled -CommandName Set-SqlHADREndpoint -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is in the desired state' {
                $mockDynamicEndpointState = $mockEndpointStateStarted

                Context 'When desired state should be Started, and the current state is Started' {
                    It 'Should not call the mock function Set-SqlHADREndpoint' {
                        $testParameters.Add('State', $mockEndpointStateStarted)

                        Set-TargetResource @testParameters

                        Assert-MockCalled -CommandName Set-SqlHADREndpoint -Exactly -Times 0 -Scope It
                    }
                }

                $mockDynamicEndpointState = $mockEndpointStateStopped

                Context 'When desired state should be Stopped, and the current state is Stopped' {
                    It 'Should not call the mock function Set-SqlHADREndpoint' {
                        $testParameters.Add('State', $mockEndpointStateStopped)

                        Set-TargetResource @testParameters

                        Assert-MockCalled -CommandName Set-SqlHADREndpoint -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When Get-TargetResource returns nothing' {
                    It 'Should throw the correct error message' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return $null
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.UnexpectedErrorFromGet

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
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
