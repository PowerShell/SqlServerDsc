$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlServerMemory'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

# Loading mocked classes
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
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
        }

        #region Function mocks

        $mockConnectSQL = {
            return @(
                (
                    # New-Object Object |
                    New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name Configuration -Value {
                        return @( ( New-Object Object |
                                    Add-Member -MemberType ScriptProperty -Name MinServerMemory -Value {
                                    return @( ( New-Object Object |
                                                Add-Member -MemberType NoteProperty -Name DisplayName -Value 'min server memory (MB)' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name Description -Value 'Minimum size of server memory (MB)' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name RunValue -Value $mockMinServerMemory -PassThru |
                                                Add-Member -MemberType NoteProperty -Name ConfigValue -Value $mockMinServerMemory -PassThru -Force
                                        ) )
                                } -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name MaxServerMemory -Value {
                                    return @( ( New-Object Object |
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
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Test-ActiveNode' {
                    Assert-MockCalled Test-ActiveNode -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerMemory\Test-TargetResource" -Tag 'Test' {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            Mock -CommandName Get-CimInstance -MockWith {
                throw 'Mocked function Get-CimInstance was called with the wrong set of parameter filters.'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                $mockGetCimInstanceMem = @()

                $mockGetCimInstanceMem += New-Object -TypeName psobject -Property @{
                    Name     = 'Physical Memory'
                    Tag      = 'Physical Memory 0'
                    Capacity = 8589934592
                }

                $mockGetCimInstanceMem += New-Object -TypeName psobject -Property @{
                    Name     = 'Physical Memory'
                    Tag      = 'Physical Memory 1'
                    Capacity = 8589934592
                }

                $mockGetCimInstanceMem
            } -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' } -Verifiable

            Mock -CommandName Get-CimInstance -MockWith {
                $mockGetCimInstanceProc = [PSCustomObject]@{
                    NumberOfCores = 2
                }

                $mockGetCimInstanceProc
            } -ParameterFilter { $ClassName -eq 'Win32_Processor' } -Verifiable

            Mock -CommandName Get-CimInstance -MockWith {
                $mockGetCimInstanceOS = [PSCustomObject]@{
                    OSArchitecture = '64-bit'
                }

                $mockGetCimInstanceOS
            } -ParameterFilter { $ClassName -eq 'Win32_operatingsystem' } -Verifiable

            Mock -CommandName Test-ActiveNode -MockWith { return $mockTestActiveNode } -Verifiable

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

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
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

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the system is in the desired state and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure       = 'Present'
                    MinMemory    = 0
                    MaxMemory    = 10300
                    DynamicAlloc = $false
                }

                It 'Should return the state as true when desired MinMemory and MaxMemory are present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
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
                    { Test-TargetResource @testParameters } | Should -Throw 'The parameter MaxMemory must be null when DynamicAlloc is set to true.'
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the MaxMemory parameter is null and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $false
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    {Test-TargetResource @testParameters } | Should -Throw 'The parameter MaxMemory must not be null when DynamicAlloc is set to false.'
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
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

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_PhysicalMemory'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_operatingsystem'
                    } -Scope Context
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

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ParameterFilter {
                        $ClassName -eq 'Win32_PhysicalMemory'
                    } -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ParameterFilter {
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ParameterFilter {
                        $ClassName -eq 'Win32_operatingsystem'
                    } -Scope Context
                }
            }

            $mockMinServerMemory = 0
            $mockMaxServerMemory = 12083

            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            Context 'When the system is in the desired state and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure       = 'Present'
                    DynamicAlloc = $true
                }

                It 'Should return the state as true when desired MinMemory and MaxMemory are present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_PhysicalMemory'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_operatingsystem'
                    } -Scope Context
                }
            }

            $mockMinServerMemory = 1024
            $mockMaxServerMemory = 8192

            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                It 'Should return the state as false when desired MinMemory and MaxMemory are not set to the default values' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
                }
            }

            $mockMinServerMemory = 0
            $mockMaxServerMemory = 2147483647

            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                It 'Should return the state as true when desired MinMemory and MaxMemory are present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
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

            Mock -CommandName Get-CimInstance -MockWith {
                throw 'Mocked function Get-CimInstance was called with the wrong set of parameter filters.'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                $mockGetCimInstanceMem = @()

                $mockGetCimInstanceMem += New-Object -TypeName psobject -Property @{
                    Name     = 'Physical Memory'
                    Tag      = 'Physical Memory 0'
                    Capacity = 17179869184
                }

                $mockGetCimInstanceMem += New-Object -TypeName psobject -Property @{
                    Name     = 'Physical Memory'
                    Tag      = 'Physical Memory 1'
                    Capacity = 17179869184
                }

                $mockGetCimInstanceMem
            } -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' } -Verifiable

            Mock -CommandName Get-CimInstance -MockWith {
                $mockGetCimInstanceProc = [PSCustomObject]@{
                    NumberOfCores = 6
                }

                $mockGetCimInstanceProc
            } -ParameterFilter { $ClassName -eq 'Win32_Processor' } -Verifiable

            Mock -CommandName Get-CimInstance -MockWith {
                $mockGetCimInstanceOS = [PSCustomObject]@{
                    OSArchitecture = 'IA64-bit'
                }

                $mockGetCimInstanceOS
            } -ParameterFilter { $ClassName -eq 'Win32_operatingsystem' } -Verifiable

            Context 'When the MaxMemory parameter is not null and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxMemory    = 8192
                    DynamicAlloc = $true
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should -Throw 'The parameter MaxMemory must be null when DynamicAlloc is set to true.'
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the MaxMemory parameter is null and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $false
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should -Throw 'The parameter MaxMemory must not be null when DynamicAlloc is set to false.'
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
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
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
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
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
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
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_PhysicalMemory'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_operatingsystem'
                    } -Scope Context
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                $mockGetCimInstanceOS = [PSCustomObject]@{
                    OSArchitecture = '32-bit'
                }

                $mockGetCimInstanceOS
            } -ParameterFilter { $ClassName -eq 'Win32_operatingsystem' } -Verifiable

            Context 'When the system (OS 32-bit) is not in the desired state and Ensure is set to Present, and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $true
                    Ensure       = 'Present'
                }

                It 'Should set the MaxMemory to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to true' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_PhysicalMemory'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_operatingsystem'
                    } -Scope Context
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
                    { Set-TargetResource @testParameters } | Should -Throw ("Failed to alter the server configuration memory for $($env:COMPUTERNAME)" + "\" + `
                            "$mockInstanceName. InnerException: Exception calling ""Alter"" with ""0"" argument(s): " + `
                            """Mock Alter Method was called with invalid operation.""")
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                throw
            } -ParameterFilter { $ClassName -eq 'Win32_operatingsystem' } -Verifiable

            Context 'When the Get-SqlDscDynamicMaxMemory fails to calculate the MaxMemory' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $true
                    Ensure       = 'Present'
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should -Throw 'Failed to calculate dynamically the maximum memory.'
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_PhysicalMemory'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter {
                        $ClassName -eq 'Win32_operatingsystem'
                    } -Scope Context
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
