$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlAGListener'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    # Loading stub cmdlets
    Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global
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

        $mockKnownAvailabilityGroup = 'AG01'
        $mockUnknownAvailabilityGroup = 'UnknownAG'
        $mockKnownListenerName = 'AGListener'
        $mockUnknownListenerName = 'UnknownListener'
        $mockKnownPortNumber = 5031
        $mockUnknownPortNumber = 9001

        # Static parameter values
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockDynamicAvailabilityGroup = $mockKnownAvailabilityGroup
        $mockDynamicListenerName = $mockKnownListenerName
        $mockDynamicPortNumber = $mockKnownPortNumber
        $mockDynamicIsDhcp = $true
        $script:mockMethodDropRan = $false

        $mockConnectSql = {
            return New-Object Object |
                Add-Member ScriptProperty AvailabilityGroups {
                return @(
                    @{
                        $mockDynamicAvailabilityGroup = New-Object Object |
                            Add-Member ScriptProperty AvailabilityGroupListeners {
                            @(
                                @{
                                    $mockDynamicListenerName = New-Object Object |
                                        Add-Member NoteProperty PortNumber $mockDynamicPortNumber -PassThru |
                                        Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                                        return @(
                                            # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                            (New-Object Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                                    Add-Member NoteProperty IsDHCP $mockDynamicIsDhcp -PassThru |
                                                    Add-Member NoteProperty IPAddress '192.168.0.1' -PassThru |
                                                    Add-Member NoteProperty SubnetMask '255.255.255.0' -PassThru
                                            )
                                        )
                                    } -PassThru |
                                        Add-Member ScriptMethod Drop {
                                        $script:mockMethodDropRan = $true
                                    } -PassThru -Force
                                }
                            )
                        } -PassThru -Force
                    }
                )
            } -PassThru -Force
        }

        $defaultParameters = @{
            InstanceName      = $mockInstanceName
            ServerName        = $mockServerName
            Name              = $mockKnownListenerName
            AvailabilityGroup = $mockKnownAvailabilityGroup
        }

        #endregion Pester Test Initialization

        Describe 'SqlAGListener\Get-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {} -Verifiable

                It 'Should return the desired state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.AvailabilityGroup | Should -Be $testParameters.AvailabilityGroup
                }

                It 'Should not return any IP addresses' {
                    $result = Get-TargetResource @testParameters
                    $result.IpAddress | Should -Be $null
                }

                It 'Should not return port' {
                    $result = Get-TargetResource @testParameters
                    $result.Port | Should -Be 0
                }

                It 'Should return that DHCP is not used' {
                    $result = Get-TargetResource @testParameters
                    $result.DHCP | Should -Be $false
                }

                It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state, without DHCP' {
                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.AvailabilityGroup | Should -Be $testParameters.AvailabilityGroup
                }

                It 'Should return correct IP address' {
                    $result = Get-TargetResource @testParameters
                    $result.IpAddress | Should -Be '192.168.0.1/255.255.255.0'
                }

                It 'Should return correct port' {
                    $result = Get-TargetResource @testParameters
                    $result.Port | Should -Be $mockKnownPortNumber
                }

                It 'Should return that DHCP is not used' {
                    $mockDynamicIsDhcp = $false

                    $result = Get-TargetResource @testParameters
                    $result.DHCP | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state, with DHCP' {
                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.AvailabilityGroup | Should -Be $testParameters.AvailabilityGroup
                }

                It 'Should return correct IP address' {
                    $result = Get-TargetResource @testParameters
                    $result.IpAddress | Should -Be '192.168.0.1/255.255.255.0'
                }

                It 'Should return correct port' {
                    $result = Get-TargetResource @testParameters
                    $result.Port | Should -Be $mockKnownPortNumber
                }

                It 'Should return that DHCP is used' {
                    $mockDynamicIsDhcp = $true

                    $result = Get-TargetResource @testParameters
                    $result.DHCP | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Get-SQLAlwaysOnAvailabilityGroupListener throws an error' {
                # Setting dynamic mock to an availability group that the test is not expecting.
                $mockDynamicAvailabilityGroup = $mockUnknownAvailabilityGroup

                It 'Should throw the correct error' {
                    { Get-TargetResource @testParameters } | Should -Throw 'Trying to make a change to a listener that does not exist. InnerException: Unable to locate the availability group ''AG01'' on the instance ''MSSQLSERVER''.'
                }
            }

            Assert-VerifiableMock
        }

        Describe 'SqlAGListener\Test-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()
            }

            Context 'When the system is not in the desired state (for static IP)' {
                It 'Should return that desired state is absent when wanted desired state is to be Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $false

                    Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {} -Verifiable

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

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
                    $testParameters['Ensure'] = 'Absent'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when IP address is different' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $false

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when DHCP is absent but should be present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $true

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when DHCP is the only set parameter' {
                    $testParameters['DHCP'] = $true

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

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
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $false

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

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
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.100/255.255.255.0'
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $false

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when IP address is the only set parameter' {
                    $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

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
                    $testParameters['Port'] = 5030

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state (for static IP)' {
                It 'Should return that desired state is present when wanted desired state is to be Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $false

                    Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {} -Verifiable

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

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
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $false

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is present when IP address is the only set parameter' {
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is present when port is the only set parameter' {
                    $testParameters['Port'] = 5030

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

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
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $true

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is present when DHCP is the only set parameter' {
                    $testParameters['DHCP'] = $true

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Get-TargetResource returns $null' {
                It 'Should throw the correct error' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return $null
                    }

                    { Test-TargetResource @testParameters } | Should -Throw 'Got unexpected result from Get-TargetResource. No change is made.'
                }
            }

            Assert-VerifiableMock
        }

        Describe 'SqlAGListener\Set-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock -CommandName New-SqlAvailabilityGroupListener -MockWith {} -Verifiable
                Mock -CommandName Set-SqlAvailabilityGroupListener -MockWith {} -Verifiable
                Mock -CommandName Add-SqlAvailabilityGroupListenerStaticIp -MockWith {} -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicListenerName = $mockUnknownListenerName

                It 'Should call the cmdlet New-SqlAvailabilityGroupListener when system is not in desired state, when using Static IP' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $false

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicListenerName = $mockUnknownListenerName

                It 'Should call the cmdlet New-SqlAvailabilityGroupListener when system is not in desired state, when using DHCP and specific DhcpSubnet' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.10.1/255.255.252.0'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $true

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicListenerName = $mockUnknownListenerName

                It 'Should call the cmdlet New-SqlAvailabilityGroupListener when system is not in desired state, when using DHCP and server default DhcpSubnet' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $true

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicIsDhcp = $false
                $mockDynamicListenerName = $mockKnownListenerName
                $mockDynamicPortNumber = $mockKnownPortNumber

                It 'Should throw when trying to change an existing IP address' {
                    $testParameters['IpAddress'] = '10.0.0.1/255.255.252.0'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $false

                    { Set-TargetResource @testParameters } | Should -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicIsDhcp = $false
                $mockDynamicListenerName = $mockKnownListenerName
                $mockDynamicPortNumber = $mockKnownPortNumber

                It 'Should throw when trying to change from static IP to DHCP' {
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $true

                    { Set-TargetResource @testParameters } | Should -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicIsDhcp = $false
                $mockDynamicListenerName = $mockKnownListenerName
                $mockDynamicPortNumber = $mockKnownPortNumber

                It 'Should call the cmdlet Add-SqlAvailabilityGroupListenerStaticIp, when adding another IP address, and system is not in desired state' {
                    $testParameters['IpAddress'] = @('192.168.0.1/255.255.255.0', '10.0.0.1/255.255.252.0')
                    $testParameters['Port'] = 5030
                    $testParameters['DHCP'] = $false

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 1 -Scope It
                }

                $mockDynamicIsDhcp = $false
                $mockDynamicListenerName = $mockKnownListenerName
                $mockDynamicPortNumber = $mockKnownPortNumber

                It 'Should not call the any cmdlet *-SqlAvailability* when system is in desired state' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $false

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicListenerName = $mockKnownListenerName
                $script:mockMethodDropRan = $false # This is set to $true when Drop() method is called. make sure we start the test with $false.

                It 'Should not call the any cmdlet *-SqlAvailability* or the the Drop() method when system is in desired state and ensure is set to ''Absent''' {
                    $testParameters['Ensure'] = 'Absent'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodDropRan | Should -Be $true # Should have made one call to the Drop() method.

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicAvailabilityGroup = $mockUnknownAvailabilityGroup
                $mockDynamicListenerName = $mockUnknownListenerName

                It 'Should throw the correct error when availability group is not found and Ensure is set to ''Present''' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $false

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    }

                    { Set-TargetResource @testParameters } | Should -Throw 'Unable to locate the availability group ''AG01'' on the instance ''MSSQLSERVER''.'
                }

                It 'Should throw the correct error when availability group is not found and Ensure is set to ''Absent''' {
                    $testParameters['Ensure'] = 'Absent'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    }

                    { Set-TargetResource @testParameters } | Should -Throw 'Unable to locate the availability group ''AG01'' on the instance ''MSSQLSERVER''.'
                }

                $mockDynamicAvailabilityGroup = $mockKnownAvailabilityGroup
                $mockDynamicListenerName = $mockUnknownListenerName

                It 'Should throw the correct error when listener is not found and Ensure is set to ''Absent''' {
                    $testParameters['Ensure'] = 'Absent'

                    { Set-TargetResource @testParameters } | Should -Throw 'Trying to make a change to a listener that does not exist.'
                }

                It 'Should throw the correct error when listener is not found and Ensure is set to ''Present''' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $false

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = $mockUnknownListenerName
                            AvailabilityGroup = $mockKnownAvailabilityGroup
                            IpAddress         = '192.168.0.1/255.255.255.0'
                            Port              = $mockKnownPortNumber
                            DHCP              = $false
                        }
                    }

                    { Set-TargetResource @testParameters } | Should -Throw 'Trying to make a change to a listener that does not exist.'
                }

                $mockDynamicAvailabilityGroup = $mockUnknownAvailabilityGroup
                $mockDynamicListenerName = $mockUnknownListenerName

                It 'Should throw the correct error when availability group is not found and Ensure is set to ''Present''' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = $mockKnownPortNumber
                    $testParameters['DHCP'] = $false

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = $mockUnknownListenerName
                            AvailabilityGroup = $mockUnknownAvailabilityGroup
                            IpAddress         = '192.168.0.1/255.255.255.0'
                            Port              = $mockKnownPortNumber
                            DHCP              = $false
                        }
                    }

                    { Set-TargetResource @testParameters } | Should -Throw 'Unable to locate the availability group ''AG01'' on the instance ''MSSQLSERVER''.'
                }
            }

            Context 'When the system is in the desired state' {
                $mockDynamicIsDhcp = $false
                $mockDynamicListenerName = $mockKnownListenerName
                $mockDynamicPortNumber = $mockKnownPortNumber

                It 'Should not call the any cmdlet *-SqlAvailability* when system is in desired state' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = $mockKnownPortNumber

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicIsDhcp = $false
                $mockDynamicListenerName = $mockKnownListenerName
                $mockDynamicPortNumber = $mockKnownPortNumber

                It 'Should not call the any cmdlet *-SqlAvailability* when system is in desired state (without ensure parameter)' {
                    $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
                    $testParameters['Port'] = $mockKnownPortNumber

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
                }

                $mockDynamicListenerName = $mockUnknownListenerName
                $script:mockMethodDropRan = $false # This is set to $true when Drop() method is called. make sure we start the test with $false.

                It 'Should not call the any cmdlet *-SqlAvailability* or the the Drop() method when system is in desired state and ensure is set to ''Absent''' {
                    $testParameters['Ensure'] = 'Absent'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodDropRan | Should -Be $false # Should not have called Drop() method.

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It

                }
            }

            Context 'When Get-TargetResource returns $null' {
                It 'Should throw the correct error' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return $null
                    }

                    { Set-TargetResource @testParameters } | Should -Throw 'Got unexpected result from Get-TargetResource. No change is made.'
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
