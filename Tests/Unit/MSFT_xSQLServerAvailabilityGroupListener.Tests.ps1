$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerAvailabilityGroupListener'

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
    Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        # Static parameter values
        $mockNodeName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockAvailabilityGroup = 'AG01'
        $mockListenerName = 'AGListner'
        $mockPortNumber = 5031
        $mockIsDhcp = $true

        $mockConnectSql = {
            return New-Object Object |
                Add-Member ScriptProperty AvailabilityGroups {
                    return @(
                        @{
                            $mockAvailabilityGroup = New-Object Object |
                                Add-Member ScriptProperty AvailabilityGroupListeners {
                                    @(
                                        @{
                                            $mockListenerName = New-Object Object |
                                                Add-Member NoteProperty PortNumber $mockPortNumber -PassThru |
                                                Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                                                    return @(
                                                        # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                                        (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                                            Add-Member NoteProperty IsDHCP $mockIsDhcp -PassThru |
                                                            Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                                            Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                                        )
                                                    )
                                                } -PassThru -Force
                                        }
                                    )
                                } -PassThru -Force
                        }
                    )
                } -PassThru -Force
        }

        $defaultParameters = @{
            InstanceName = $mockInstanceName
            NodeName = $mockNodeName
            Name = $mockListenerName
            AvailabilityGroup = $mockAvailabilityGroup
        }

        #endregion Pester Test Initialization

        Describe 'xSQLServerAvailabilityGroupListener\Get-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {} -Verifiable

                It 'Should return the desired state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.NodeName | Should Be $testParameters.NodeName
                    $result.InstanceName | Should Be $testParameters.InstanceName
                    $result.Name | Should Be $testParameters.Name
                    $result.AvailabilityGroup | Should Be $testParameters.AvailabilityGroup
                }

                It 'Should not return any IP addresses' {
                    $result = Get-TargetResource @testParameters
                    $result.IpAddress | Should Be $null
                }

                It 'Should not return port' {
                    $result = Get-TargetResource @testParameters
                    $result.Port | Should Be 0
                }

                It 'Should return that DHCP is not used' {
                    $result = Get-TargetResource @testParameters
                    $result.DHCP | Should Be $false
                }

                It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state, without DHCP' {
                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.NodeName | Should Be $testParameters.NodeName
                    $result.InstanceName | Should Be $testParameters.InstanceName
                    $result.Name | Should Be $testParameters.Name
                    $result.AvailabilityGroup | Should Be $testParameters.AvailabilityGroup
                }

                It 'Should return correct IP address' {
                    $result = Get-TargetResource @testParameters
                    $result.IpAddress | Should Be '192.168.0.1/255.255.255.0'
                }

                It 'Should return correct port' {
                    $result = Get-TargetResource @testParameters
                    $result.Port | Should Be $mockPortNumber
                }

                It 'Should return that DHCP is not used' {
                    $mockIsDhcp = $false

                    $result = Get-TargetResource @testParameters
                    $result.DHCP | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state, with DHCP' {
                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.NodeName | Should Be $testParameters.NodeName
                    $result.InstanceName | Should Be $testParameters.InstanceName
                    $result.Name | Should Be $testParameters.Name
                    $result.AvailabilityGroup | Should Be $testParameters.AvailabilityGroup
                }

                It 'Should return correct IP address' {
                    $result = Get-TargetResource @testParameters
                    $result.IpAddress | Should Be '192.168.0.1/255.255.255.0'
                }

                It 'Should return correct port' {
                    $result = Get-TargetResource @testParameters
                    $result.Port | Should Be $mockPortNumber
                }

                It 'Should return that DHCP is used' {
                    $mockIsDhcp = $true

                    $result = Get-TargetResource @testParameters
                    $result.DHCP | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMocks
        }

        Describe 'xSQLServerAvailabilityGroupListener\Test-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters
            }

            Context 'When the system is not in the desired state (for static IP)' {
                It 'Should return that desired state is absent when wanted desired state is to be Present' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.10.45/255.255.252.0'
                        Port = 5030
                        DHCP = $false
                    }

                    Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {} -Verifiable

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                    return New-Object Object |
                        Add-Member NoteProperty PortNumber 5030 -PassThru |
                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                            return @(
                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                    Add-Member NoteProperty IsDHCP $false -PassThru |
                                    Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                    Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                )
                            )
                        } -PassThru -Force
                } -Verifiable

                It 'Should return that desired state is absent when wanted desired state is to be Absent' {
                    $testParameters += @{
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when IP address is different' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.10.45/255.255.252.0'
                        Port = 5030
                        DHCP = $false
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when DHCP is absent but should be present' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.0.1/255.255.255.0'
                        Port = 5030
                        DHCP = $true
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when DHCP is the only set parameter' {
                    $testParameters += @{
                        DHCP = $true
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                    return New-Object Object |
                        Add-Member NoteProperty PortNumber 5555 -PassThru |
                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                            return @(
                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                    Add-Member NoteProperty IsDHCP $false -PassThru |
                                    Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                    Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                )
                            )
                        } -PassThru -Force
                } -Verifiable

                It 'Should return that desired state is absent when port is different' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.0.1/255.255.255.0'
                        Port = 5030
                        DHCP = $false
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state (for DHCP)' {
                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                    return New-Object Object |
                        Add-Member NoteProperty PortNumber 5030 -PassThru |
                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                            return @(
                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                    Add-Member NoteProperty IsDHCP $true -PassThru |
                                    Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                    Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                )
                            )
                        } -PassThru -Force
                } -Verifiable

                It 'Should return that desired state is absent when DHCP is present but should be absent' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.0.100/255.255.255.0'
                        Port = 5030
                        DHCP = $false
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when IP address is the only set parameter' {
                    $testParameters += @{
                        IpAddress = '192.168.10.45/255.255.252.0'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                    return New-Object Object |
                        Add-Member NoteProperty PortNumber 5555 -PassThru |
                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                            return @(
                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                    Add-Member NoteProperty IsDHCP $true -PassThru |
                                    Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                    Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                )
                            )
                        } -PassThru -Force
                } -Verifiable

                It 'Should return that desired state is absent when port is the only set parameter' {
                    $testParameters += @{
                        Port = 5030
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state (for static IP)' {
                It 'Should return that desired state is present when wanted desired state is to be Absent' {
                    $testParameters += @{
                        Ensure = 'Absent'
                        IpAddress = '192.168.10.45/255.255.252.0'
                        Port = 5030
                        DHCP = $false
                    }

                    Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {} -Verifiable

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                    return New-Object Object |
                        Add-Member NoteProperty PortNumber 5030 -PassThru |
                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                            return @(
                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                    Add-Member NoteProperty IsDHCP $false -PassThru |
                                    Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                    Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                )
                            )
                        } -PassThru -Force
                } -Verifiable

                It 'Should return that desired state is present when wanted desired state is to be Present, without DHCP' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.0.1/255.255.255.0'
                        Port = 5030
                        DHCP = $false
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is present when IP address is the only set parameter' {
                    $testParameters += @{
                        IpAddress = '192.168.0.1/255.255.255.0'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is present when port is the only set parameter' {
                    $testParameters += @{
                        Port = 5030
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state (for DHCP)' {
                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                    return New-Object Object |
                        Add-Member NoteProperty PortNumber 5030 -PassThru |
                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                            return @(
                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                    Add-Member NoteProperty IsDHCP $true -PassThru |
                                    Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                    Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                )
                            )
                        } -PassThru -Force
                } -Verifiable

                It 'Should return that desired state is present when wanted desired state is to be Present, with DHCP' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.0.1/255.255.255.0'
                        Port = 5030
                        DHCP = $true
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is present when DHCP is the only set parameter' {
                    $testParameters += @{
                        DHCP = $true
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMocks
        }

        Describe 'xSQLServerAvailabilityGroupListener\Set-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityGroupListener -MockWith {} -Verifiable
                Mock -CommandName Set-SqlAvailabilityGroupListener -MockWith {} -Verifiable
                Mock -CommandName Add-SqlAvailabilityGroupListenerStaticIp -MockWith {} -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should call the cmdlet New-SqlAvailabilityGroupListener when system is not in desired state' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.10.45/255.255.252.0'
                        Port = 5030
                        DHCP = $false
                    }

                    Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {} -Verifiable

                    { Set-TargetResource @testParameters } | Should Not Throw

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                    return New-Object Object |
                        Add-Member NoteProperty PortNumber 5030 -PassThru |
                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                            return @(
                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                    Add-Member NoteProperty IsDHCP $false -PassThru |
                                    Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                    Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                )
                            )
                        } -PassThru -Force
                } -Verifiable

                It 'Should throw when trying to change an existing IP address' {
                    $testParameters += @{
                        IpAddress = '10.0.0.1/255.255.252.0'
                        Port = 5030
                        DHCP = $false
                    }

                    { Set-TargetResource @testParameters } | Should Throw

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                It 'Should throw when trying to change from static IP to DHCP' {
                    $testParameters += @{
                        IpAddress = '192.168.0.1/255.255.255.0'
                        Port = 5030
                        DHCP = $true
                    }

                    { Set-TargetResource @testParameters } | Should Throw

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                It 'Should call the cmdlet Add-SqlAvailabilityGroupListenerStaticIp, when adding another IP address, and system is not in desired state' {
                    $testParameters += @{
                        IpAddress = @('192.168.0.1/255.255.255.0','10.0.0.1/255.255.252.0')
                        Port = 5030
                        DHCP = $false
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 1 -Scope It
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                    return New-Object Object |
                        Add-Member NoteProperty PortNumber 5555 -PassThru |
                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                            return @(
                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                    Add-Member NoteProperty IsDHCP $false -PassThru |
                                    Add-Member NoteProperty IPAddress '192.168.10.45' -PassThru |
                                    Add-Member NoteProperty SubnetMask '255.255.252.0' -PassThru
                                )
                            )
                        } -PassThru -Force
                } -Verifiable

                It 'Should call the cmdlet Set-SqlAvailabilityGroupListener when port is not in desired state' {
                    $testParameters += @{
                        IpAddress = '192.168.10.45/255.255.252.0'
                        Port = 5030
                        DHCP = $false
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }
            }

            Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
                return New-Object Object |
                    Add-Member NoteProperty PortNumber 5030 -PassThru |
                    Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                        return @(
                            # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                            (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                Add-Member NoteProperty IsDHCP $false -PassThru |
                                Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                            )
                        )
                    } -PassThru -Force
            } -Verifiable

            Context 'When the system is in the desired state' {
                It 'Should not call the any cmdlet *-SqlAvailability* when system is in desired state' {
                    $testParameters += @{
                        Ensure = 'Present'
                        IpAddress = '192.168.0.1/255.255.255.0'
                        Port = 5030
                        DHCP = $false
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                It 'Should not call the any cmdlet *-SqlAvailability* when system is in desired state (without ensure parameter)' {
                    $testParameters += @{
                        IpAddress = '192.168.0.1/255.255.255.0'
                        Port = 5030
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
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
