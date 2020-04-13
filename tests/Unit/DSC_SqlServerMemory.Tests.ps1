<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlServerMemory DSC resource.

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
$script:dscResourceName = 'MSFT_SqlServerMemory'

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

    # Loading mocked classes
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
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockMinServerMemory = 2048
        $mockMaxServerMemory = 10300
        $mockPhysicalMemoryCapacity = 8589934592
        $mockExpectedMinMemoryForAlterMethod = 0
        $mockExpectedMaxMemoryForAlterMethod = 2147483647
        $mockTestActiveNode = $true

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
            Verbose = $true
        }

        #region Function mocks

        $mockConnectSQL = {
            return @(
                (
                    # New-Object -TypeName Object |
                    New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name Configuration -Value {
                        return @( ( New-Object -TypeName Object |
                                    Add-Member -MemberType ScriptProperty -Name MinServerMemory -Value {
                                    return @( ( New-Object -TypeName Object |
                                                Add-Member -MemberType NoteProperty -Name DisplayName -Value 'min server memory (MB)' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name Description -Value 'Minimum size of server memory (MB)' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name RunValue -Value $mockMinServerMemory -PassThru |
                                                Add-Member -MemberType NoteProperty -Name ConfigValue -Value $mockMinServerMemory -PassThru -Force
                                        ) )
                                } -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name MaxServerMemory -Value {
                                    return @( ( New-Object -TypeName Object |
                                                Add-Member -MemberType NoteProperty -Name DisplayName -Value 'max server memory (MB)' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name Description -Value 'Maximum size of server memory (MB)' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name RunValue -Value $mockMaxServerMemory -PassThru |
                                                Add-Member -MemberType NoteProperty -Name ConfigValue -Value $mockMaxServerMemory -PassThru -Force
                                        ) )
                                } -PassThru -Force
                            ) )
                    } -PassThru -Force |
                        Add-Member -MemberType ScriptMethod -Name Alter -Value {
                        if ( $this.Configuration.MinServerMemory.ConfigValue -ne $mockExpectedMinMemoryForAlterMethod )
                        {
                            throw "Called mocked Alter() method without setting the right minimum server memory. Expected '{0}'. But was '{1}'." -f $mockExpectedMinMemoryForAlterMethod, $this.Configuration.MinServerMemory.ConfigValue
                        }
                        if ( $this.Configuration.MaxServerMemory.ConfigValue -ne $mockExpectedMaxMemoryForAlterMethod )
                        {
                            throw "Called mocked Alter() method without setting the right maximum server memory. Expected '{0}'. But was '{1}'." -f $mockExpectedMaxMemoryForAlterMethod, $this.Configuration.MaxServerMemory.ConfigValue
                        }
                    } -PassThru -Force
                )
            )
        }

        #endregion

        Describe "MSFT_SqlServerMemory\Get-TargetResource" -Tag 'Get' {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            Mock -CommandName Test-ActiveNode -MockWith { return $mockTestActiveNode } -Verifiable

            Context 'When the system is either in the desired state or not in the desired state' {
                $testParameters = $mockDefaultParameters

                $result = Get-TargetResource @testParameters

                It 'Should return the current value for MinMemory' {
                    $result.MinMemory | Should -Be 2048
                }

                It 'Should return the current value for MaxMemory' {
                    $result.MaxMemory | Should -Be 10300
                }

                It 'Should return the same values as passed as parameters' {
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Test-ActiveNode' {
                    Assert-MockCalled -CommandName Test-ActiveNode -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerMemory\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192 # MB
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = $mockInstanceName
                        ServerName   = $mockServerName
                        MinMemory    = $mockMinServerMemory
                        MaxMemory    = $mockMaxServerMemory
                        IsActiveNode = $mockTestActiveNode
                    }
                }
            }

            $mockMinServerMemory = 0
            $mockMaxServerMemory = 16384

            Context 'When the system is not in the desired state and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure       = 'Present'
                    MinMemory    = 1024
                    MaxMemory    = 8192
                    DynamicAlloc = $false
                }

                It 'Should return the state as false when desired MinMemory and MaxMemory are not present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }
            }

            Context 'When the system is not in the desired state and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure       = 'Present'
                    MaxMemory    = 8192
                    DynamicAlloc = $false
                }

                It 'Should return the state as false when desired MaxMemory is not present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }
            }

            Context 'When the system is in the desired state and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure       = 'Present'
                    MinMemory    = $mockMinServerMemory
                    MaxMemory    = $mockMaxServerMemory
                    DynamicAlloc = $false
                }

                It 'Should return the state as true when desired MinMemory and MaxMemory are present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }
            }

            Context 'When the MaxMemory parameter is not null and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxMemory    = 8192
                    DynamicAlloc = $true
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    { Test-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxMemoryParamMustBeNull
                }
            }

            Context 'When the MaxMemory parameter is null and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $false
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    {Test-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxMemoryParamMustNotBeNull
                }
            }

            Context 'When the system is not in the desired state and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure       = 'Present'
                    DynamicAlloc = $true
                }

                It 'Should return the state as false when desired MinMemory and MaxMemory are not present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }
            }

            Context 'When the system is not in the desired state, DynamicAlloc is set to true and ProcessOnlyOnActiveNode is set to true' {
                AfterAll {
                    $mockTestActiveNode = $true
                }

                BeforeAll {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure                  = 'Present'
                        DynamicAlloc            = $true
                        ProcessOnlyOnActiveNode = $true
                    }

                    $mockTestActiveNode = $false
                }

                It 'Should return the state as true' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }
            }

            $mockMinServerMemory = 0
            $mockMaxServerMemory = 12083

            Context 'When the system is in the desired state and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure       = 'Present'
                    DynamicAlloc = $true
                }

                It 'Should return the state as false when desired MinMemory and MaxMemory are wrong values' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }
            }

            $mockMinServerMemory = 1024
            $mockMaxServerMemory = 8192

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                It 'Should return the state as false when desired MinMemory and MaxMemory are not set to the default values' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }
            }

            $mockMinServerMemory = 0
            $mockMaxServerMemory = 2147483647

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                It 'Should return the state as true when desired MinMemory and MaxMemory are present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }
            }

            # This is regression test for issue #576
            Context 'When the system is in the desired state and ServerName is not set' {
                $testParameters = $mockDefaultParameters
                $testParameters.Remove('ServerName')
                $testParameters += @{
                    Ensure = 'Absent'
                }

                It 'Should not throw an error' {
                    { Test-TargetResource @testParameters } | Should -Not -Throw
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerMemory\Set-TargetResource" -Tag 'Set' {
            $mockMinServerMemory = 0
            $mockMaxServerMemory = 2147483647

            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                return 16384 # MB
            }

            Context 'When the MaxMemory parameter is not null and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxMemory    = 8192
                    DynamicAlloc = $true
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxMemoryParamMustBeNull
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
                    Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the MaxMemory parameter is null and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $false
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxMemoryParamMustNotBeNull
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
                    Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                $mockExpectedMinMemoryForAlterMethod = 0
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                It 'Should set the MinMemory and MaxMemory to the default values' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
                    Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Present, and DynamicAlloc is set to false' {
                $mockMinServerMemory = 1024
                $mockMaxServerMemory = 8192

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $mockExpectedMinMemoryForAlterMethod = 1024
                $mockExpectedMaxMemoryForAlterMethod = 8192
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxMemory    = 8192
                    MinMemory    = 1024
                    DynamicAlloc = $false
                    Ensure       = 'Present'
                }

                It 'Should set the MinMemory and MaxMemory to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to false' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
                    Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the system (OS IA64-bit) is not in the desired state and Ensure is set to Present, and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $true
                    Ensure       = 'Present'
                    MinMemory    = 2048
                }

                It 'Should set the MaxMemory to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to true' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-SqlDscDynamicMaxMemory' {
                    Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 1 -Scope Context
                }
            }

            Mock -CommandName Connect-SQL -MockWith {
                $mockSqlServerObject = [PSCustomObject]@{
                    InstanceName                = $mockInstanceName
                    ComputerNamePhysicalNetBIOS = $mockServerName
                    Configuration               = @{
                        MinServerMemory = @{
                            DisplayName = 'min server memory (MB)'
                            Description = 'Minimum size of server memory (MB)'
                            RunValue    = 0
                            ConfigValue = 0
                        }
                        MaxServerMemory = @{
                            DisplayName = 'max server memory (MB)'
                            Description = 'Maximum size of server memory (MB)'
                            RunValue    = 10300
                            ConfigValue = 10300
                        }
                    }
                }

                # Add the Alter method
                $mockSqlServerObject | Add-Member -MemberType ScriptMethod -Name Alter -Value {
                    throw 'Mock Alter Method was called with invalid operation.'
                }

                $mockSqlServerObject
            } -Verifiable

            Context 'When the desired MinMemory and MaxMemory fails to be set' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxMemory    = 8192
                    MinMemory    = 1024
                    DynamicAlloc = $false
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.AlterServerMemoryFailed -f $env:COMPUTERNAME, $mockInstanceName)
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
                    Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlServerMemory\Get-SqlDscDynamicMaxMemory' -Tag 'Helper' {
            Context 'When the physical memory should be calculated' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return New-Object -TypeName PSObject -Property @{
                            TotalPhysicalMemory = $mockTotalPhysicalMemory
                        }
                    } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }

                    Mock -CommandName Get-CimInstance -MockWith {
                        return  [PSCustomObject]@{
                            NumberOfCores = $mockNumberOfCores
                        }
                    } -ParameterFilter { $ClassName -eq 'Win32_Processor' }

                    Mock -CommandName Get-CimInstance -MockWith {
                        return [PSCustomObject]@{
                            OSArchitecture = $mockOSArchitecture
                        }
                    } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
                }

                Context 'When number of cores is 2' {
                    $mockNumberOfCores = 2

                    Context 'When OS Architecture is 64-bit' {
                        $mockOSArchitecture = '64-bit'

                        context 'When physical memory is less than 20480MB' {
                            $mockTotalPhysicalMemory = 20426260480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 14560
                            }
                        }

                        context 'When physical memory is equal to 20480MB' {
                            $mockTotalPhysicalMemory = 21474836480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 16896
                            }
                        }

                        context 'When physical memory is more than 20480MB' {
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 25646
                            }
                        }


                    }

                    Context 'When OS Architecture is 32-bit' {
                        $mockOSArchitecture = '32-bit'

                        context 'When physical memory is less than 20480MB' {
                            # Dynamically set the mock return value.
                            $mockTotalPhysicalMemory = 20426260480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 14560
                            }
                        }

                        context 'When physical memory is equal to 20480MB' {
                            $mockTotalPhysicalMemory = 21474836480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 16896
                            }
                        }

                        context 'When physical memory is more than 20480MB' {
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 25646
                            }
                        }
                    }

                    Context 'When OS Architecture is IA64-bit' {
                        $mockOSArchitecture = 'IA64-bit'

                        context 'When physical memory is less than 20480MB' {
                            # Dynamically set the mock return value.
                            $mockTotalPhysicalMemory = 20426260480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 14560
                            }
                        }

                        context 'When physical memory is equal to 20480MB' {
                            $mockTotalPhysicalMemory = 21474836480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 16896
                            }
                        }

                        context 'When physical memory is more than 20480MB' {
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 25646
                            }
                        }
                    }
                }

                Context 'When number of cores is 4' {
                    $mockNumberOfCores = 4
                    Context 'When OS Architecture is 64-bit' {
                        $mockOSArchitecture = '64-bit'

                        context 'When physical memory is more than 20480MB' {
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 25134
                            }
                        }
                    }

                    Context 'When OS Architecture is 32-bit' {
                        $mockOSArchitecture = '32-bit'

                        context 'When physical memory is more than 20480MB' {
                            # Dynamically set the mock return value.
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 25390
                            }
                        }
                    }

                    Context 'When OS Architecture is IA64-bit' {
                        $mockOSArchitecture = 'IA64-bit'

                        context 'When physical memory is more than 20480MB' {
                            # Dynamically set the mock return value.
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 24622
                            }
                        }
                    }
                }

                Context 'When number of cores is 6' {
                    $mockNumberOfCores = 6
                    Context 'When OS Architecture is 64-bit' {
                        $mockOSArchitecture = '64-bit'

                        context 'When physical memory is more than 20480MB' {
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 24078
                            }
                        }
                    }

                    Context 'When OS Architecture is 32-bit' {
                        $mockOSArchitecture = '32-bit'

                        context 'When physical memory is more than 20480MB' {
                            # Dynamically set the mock return value.
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 24350
                            }
                        }
                    }

                    Context 'When OS Architecture is IA64-bit' {
                        $mockOSArchitecture = 'IA64-bit'

                        context 'When physical memory is more than 20480MB' {
                            # Dynamically set the mock return value.
                            $mockTotalPhysicalMemory = 31960596480

                            It 'Should return the correct max memory (in megabytes) value' {
                                $result = Get-SqlDscDynamicMaxMemory
                                $result | Should -Be 23534
                            }
                        }
                    }
                }
            }

            Context 'When the physical memory fails to be calculated' {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        throw 'mocked unkown error'
                    }
                }

                It 'Should throw the correct error' {
                    { Get-SqlDscDynamicMaxMemory } | Should -Throw $script:localizedData.ErrorGetDynamicMaxMemory
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
