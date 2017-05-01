$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerNetwork'

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
        $mockInstanceName = 'TEST'
        $mockTcpProtocolName = 'Tcp'

        $script:WasMethodAlterCalled = $false

        $mockFunction_NewObject_ManagedComputer = {
                return New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name 'ServerInstances' {
                        return @{
                            $mockInstanceName = New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'ServerProtocols' {
                                    return @{
                                        $mockTcpProtocolName = New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $mockDynamicValue_IsEnabled -PassThru |
                                            Add-Member -MemberType ScriptProperty -Name 'IPAddresses' {
                                                return @{
                                                    'IPAll' = New-Object -TypeName Object |
                                                        Add-Member -MemberType ScriptProperty -Name 'IPAddressProperties' {
                                                            return @{
                                                                'TcpDynamicPorts' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_TcpDynamicPorts -PassThru -Force
                                                                'TcpPort' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_TcpPort -PassThru -Force
                                                            }
                                                        } -PassThru -Force
                                                }
                                            } -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name 'Alter' {
                                                <#
                                                    It is not possible to verify that the correct value was set here for TcpDynamicPorts and
                                                    TcpPort with the current implementation.
                                                    If `$this.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value` would be
                                                    called it would just return the same value over an over again, not the value that was
                                                    set in the function Set-TargetResource.
                                                    To be able to do this check for TcpDynamicPorts and TcpPort, then the class must be mocked
                                                    in SMO.cs.
                                                #>
                                                if ($this.IsEnabled -ne $mockExpectedValue_IsEnabled)
                                                {
                                                    throw ('Mock method Alter() was called with an unexpected value for IsEnabled. Expected ''{0}'', but was ''{1}''' -f $mockExpectedValue_IsEnabled, $this.IsEnabled)
                                                }

                                                # This can be used to verify so that alter method was actually called.
                                                $script:WasMethodAlterCalled = $true
                                            } -PassThru -Force
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force
        }

        $mockFunction_NewObject_ManagedComputer_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        }

        $mockFunction_RegisterSqlWmiManagement = {
            return [System.AppDomain]::CreateDomain('DummyTestApplicationDomain')
        }

        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ProtocolName = $mockTcpProtocolName
        }

        Describe "MSFT_xSQLServerNetwork\Get-TargetResource" -Tag 'Get'{
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Register-SqlWmiManagement `
                    -MockWith $mockFunction_RegisterSqlWmiManagement `
                    -Verifiable

                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable
            }

            Context 'When Get-TargetResource is called' {
                BeforeEach {
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPorts = '0'
                    $mockDynamicValue_TcpPort = '4509'
                }

                It 'Should return the correct values' {
                    $result = Get-TargetResource @testParameters
                    $result.IsEnabled | Should Be $mockDynamicValue_IsEnabled
                    $result.TcpDynamicPorts | Should Be $mockDynamicValue_TcpDynamicPorts
                    $result.TcpPort | Should Be $mockDynamicValue_TcpPort

                    Assert-MockCalled -CommandName Register-SqlWmiManagement -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.InstanceName | Should Be $testParameters.InstanceName
                    $result.ProtocolName | Should Be $testParameters.ProtocolName
                }
            }

            Assert-VerifiableMocks
        }

        Describe "MSFT_xSQLServerNetwork\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Register-SqlWmiManagement `
                    -MockWith $mockFunction_RegisterSqlWmiManagement `
                    -Verifiable

                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPorts = ''
                    $mockDynamicValue_TcpPort = '4509'
                }

                Context 'When IsEnabled is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            IsEnabled = $false
                            TcpDynamicPorts = ''
                            TcpPort = '4509'
                        }
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }
                }

                Context 'When TcpDynamicPorts is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            TcpDynamicPorts = '0'
                            IsEnabled = $false
                            TcpPort = '4509'
                        }
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }
                }

                Context 'When TcpPort is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            TcpPort = '1433'
                            IsEnabled = $true
                            TcpDynamicPorts = ''
                        }
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }
                }
            }

            Context 'When the system is in the desired state' {
                BeforeEach {
                    $mockDynamicValue_IsEnabled = $false
                    $mockDynamicValue_TcpDynamicPorts = '0'
                    $mockDynamicValue_TcpPort = '1433'

                    $testParameters += @{
                        IsEnabled = $false
                        TcpDynamicPorts = '0'
                        TcpPort = '1433'
                    }
                }

                It 'Should return $true' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }
            }

            Assert-VerifiableMocks
        }

        Describe "MSFT_xSQLServerNetwork\Set-TargetResource" -Tag 'Set'{
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Restart-SqlService -Verifiable
                Mock -CommandName Register-SqlWmiManagement `
                    -MockWith $mockFunction_RegisterSqlWmiManagement `
                    -Verifiable

                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable

                # This is used to evaluate if mocked Alter() method was called.
                $script:WasMethodAlterCalled = $false
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    # This is the values the mock will return
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPorts = ''
                    $mockDynamicValue_TcpPort = '4509'

                    <#
                        This is the values we expect to be set when Alter() method is called.
                        These values will set here to same as the values the mock will return,
                        but before each test the these will be set to the correct value that is
                        expected to be returned for that particular test.
                    #>
                    $mockExpectedValue_IsEnabled = $mockDynamicValue_IsEnabled
                }

                Context 'When IsEnabled is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            IsEnabled = $false
                            TcpDynamicPorts = ''
                            TcpPort = '4509'
                            RestartService = $true
                        }

                        $mockExpectedValue_IsEnabled = $false
                    }

                    It 'Should call Set-TargetResource without throwing and should call Alter()' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw
                        $script:WasMethodAlterCalled | Should -Be $true

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When TcpDynamicPorts is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            IsEnabled = $true
                            TcpDynamicPorts = '0'
                            TcpPort = '4509'
                        }
                    }

                    It 'Should call Set-TargetResource without throwing and should call Alter()' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw
                        $script:WasMethodAlterCalled | Should -Be $true

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When TcpPort is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            IsEnabled = $true
                            TcpDynamicPorts = ''
                            TcpPort = '4508'
                        }
                    }

                    It 'Should call Set-TargetResource without throwing and should call Alter()' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw
                        $script:WasMethodAlterCalled | Should -Be $true

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When the system is in the desired state' {
                BeforeEach {
                    # This is the values the mock will return
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPorts = ''
                    $mockDynamicValue_TcpPort = '4509'

                    <#
                        We do not expect Alter() method to be called. So we set this to $null so
                        if it is, then it will throw an error.
                    #>
                    $mockExpectedValue_IsEnabled = $null

                    $testParameters += @{
                        IsEnabled = $true
                        TcpDynamicPorts = ''
                        TcpPort = '4509'
                    }
                }

                It 'Should call Set-TargetResource without throwing and should not call Alter()' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:WasMethodAlterCalled | Should -Be $false

                    Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
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

