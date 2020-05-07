$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlServerProtocol'

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
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Write-Verbose -Message ('Test {1} ran for {0} minutes' -f ([System.TimeSpan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString('mm\:ss'), $script:dscResourceName) -Verbose
    $script:timer.Stop()
}

# Begin Testing

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        Set-StrictMode -Version 1.0

        Describe 'SqlServerProtocol\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $mockInstanceName = 'DSCTEST'

                Mock -CommandName Import-SQLPSModule
            }

            Context 'When the system is not in the desired state' {
                Context 'When the SQL Server instance does not exist' {
                    BeforeAll {
                        Mock -CommandName Get-ServerProtocolObject -MockWith {
                            return $null
                        }

                        $getTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'TcpIp'
                        }
                    }

                    It 'Should return the correct values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.ProtocolName | Should -Be 'TcpIp'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeFalse
                        $getTargetResourceResult.ListenOnAllIpAddresses | Should -BeFalse
                        $getTargetResourceResult.KeepAlive | Should -Be 0
                        $getTargetResourceResult.PipeName | Should -BeNullOrEmpty
                        $getTargetResourceResult.HasMultiIPAddresses | Should -BeFalse
                    }
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the desired protocol is TCP/IP' {
                    BeforeAll {
                        Mock -CommandName Get-ServerProtocolObject -MockWith {
                            return @{
                                IsEnabled           = $true
                                HasMultiIPAddresses = $true
                                ProtocolProperties  = @{
                                    ListenOnAllIPs = @{
                                        Value = $true
                                    }
                                    KeepAlive      = @{
                                        Value = 30000
                                    }
                                }
                            }
                        }

                        $getTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'TcpIp'
                        }
                    }

                    It 'Should return the correct values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.ProtocolName | Should -Be 'TcpIp'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeTrue
                        $getTargetResourceResult.ListenOnAllIpAddresses | Should -BeTrue
                        $getTargetResourceResult.KeepAlive | Should -Be 30000
                        $getTargetResourceResult.PipeName | Should -BeNullOrEmpty
                        $getTargetResourceResult.HasMultiIPAddresses | Should -BeTrue
                    }
                }

                Context 'When the desired protocol is Named Pipes' {
                    BeforeAll {
                        $mockPipeName = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'

                        Mock -CommandName Get-ServerProtocolObject -MockWith {
                            return @{
                                IsEnabled           = $true
                                HasMultiIPAddresses = $false
                                ProtocolProperties  = @{
                                    PipeName = @{
                                        Value = $mockPipeName
                                    }
                                }
                            }
                        }

                        $getTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'NamedPipes'
                        }
                    }

                    It 'Should return the correct values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.ProtocolName | Should -Be 'NamedPipes'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeTrue
                        $getTargetResourceResult.ListenOnAllIpAddresses | Should -BeFalse
                        $getTargetResourceResult.KeepAlive | Should -Be 0
                        $getTargetResourceResult.PipeName | Should -Be $mockPipeName
                        $getTargetResourceResult.HasMultiIPAddresses | Should -BeFalse
                    }
                }

                Context 'When the desired protocol is Shared Memory' {
                    BeforeAll {
                        Mock -CommandName Get-ServerProtocolObject -MockWith {
                            return @{
                                IsEnabled           = $true
                                HasMultiIPAddresses = $false
                                ProtocolProperties  = @{ }
                            }
                        }

                        $getTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'SharedMemory'
                        }
                    }

                    It 'Should return the correct values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.ProtocolName | Should -Be 'SharedMemory'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeTrue
                        $getTargetResourceResult.ListenOnAllIpAddresses | Should -BeFalse
                        $getTargetResourceResult.KeepAlive | Should -Be 0
                        $getTargetResourceResult.PipeName | Should -BeNullOrEmpty
                        $getTargetResourceResult.HasMultiIPAddresses | Should -BeFalse
                    }
                }

                Context 'When the restart service is requested' {
                    BeforeAll {
                        Mock -CommandName Get-ServerProtocolObject -MockWith {
                            return @{
                                IsEnabled           = $true
                                HasMultiIPAddresses = $false
                                ProtocolProperties  = @{ }
                            }
                        }

                        $getTargetResourceParameters = @{
                            InstanceName    = $mockInstanceName
                            ProtocolName    = 'SharedMemory'
                            SuppressRestart = $true
                            RestartTimeout  = 300
                        }
                    }

                    It 'Should return the correct values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.ProtocolName | Should -Be 'SharedMemory'
                        $getTargetResourceResult.SuppressRestart | Should -BeTrue
                        $getTargetResourceResult.RestartTimeout | Should -Be 300
                    }
                }
            }
        }

        Describe 'SqlServerProtocol\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $testTargetResourceParameters = @{
                    InstanceName = 'DSCTEST'
                    ProtocolName = 'SharedMemory'
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Enabled'
                                InDesiredState = $true
                            }
                        )
                    }
                }

                It 'Should return $true' {
                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeTrue

                    Assert-MockCalled -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Enabled'
                                InDesiredState = $false
                            }
                        )
                    }
                }

                It 'Should return $false' {
                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse

                    Assert-MockCalled -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'SqlServerProtocol\Compare-TargetResourceState' -Tag 'Compare' {
            BeforeAll {
                $mockInstanceName = 'DSCTEST'
            }

            Context 'When passing wrong set of parameters for either TCP/IP or Named Pipes' {
                It 'Should throw the an exception when passing both ListenOnAllIpAddresses and PipeName' {
                    $testTargetResourceParameters = @{
                        InstanceName           = $mockInstanceName
                        ProtocolName           = 'TcpIp'
                        Enabled                = $true
                        ListenOnAllIpAddresses = $false
                        PipeName               = 'any pipe name'
                    }

                    { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
                }

                It 'Should throw the an exception when passing both KeepAlive and PipeName' {
                    $testTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'TcpIp'
                        Enabled      = $true
                        KeepAlive    = 30000
                        PipeName     = 'any pipe name'
                    }

                    { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
                }
            }

            Context 'When passing wrong set of parameters for Shared Memory' {
                It 'Should throw the an exception when passing PipeName' {
                    $testTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'SharedMemory'
                        Enabled      = $true
                        PipeName     = 'any pipe name'
                    }

                    { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
                }

                It 'Should throw the an exception when passing KeepAlive' {
                    $testTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'SharedMemory'
                        Enabled      = $true
                        KeepAlive    = 30000
                    }

                    { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
                }

                It 'Should throw the an exception when passing ListenOnAllIpAddresses' {
                    $testTargetResourceParameters = @{
                        InstanceName           = $mockInstanceName
                        ProtocolName           = 'SharedMemory'
                        Enabled                = $true
                        ListenOnAllIpAddresses = $true
                    }

                    { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the desired protocol is TCP/IP' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName           = $mockInstanceName
                                ProtocolName           = 'TcpIp'
                                Enabled                = $true
                                KeepAlive              = 30000
                                ListenOnAllIpAddresses = $true
                            }
                        }

                        $compareTargetResourceParameters = @{
                            InstanceName           = $mockInstanceName
                            ProtocolName           = 'TcpIp'
                            Enabled                = $true
                            KeepAlive              = 30000
                            ListenOnAllIpAddresses = $true
                        }
                    }

                    It 'Should return the correct metadata for each protocol property' {
                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 3

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'ListenOnAllIpAddresses' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'KeepAlive' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be 30000
                        $comparedReturnValue.Actual | Should -Be 30000
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the desired protocol is Named Pipes' {
                    BeforeAll {
                        $mockPipeName = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'NamedPipes'
                                Enabled      = $true
                                PipeName     = $mockPipeName
                            }
                        }

                        $compareTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'NamedPipes'
                            Enabled      = $true
                            PipeName     = $mockPipeName
                        }
                    }

                    It 'Should return the correct metadata for each protocol property' {
                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 2

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'PipeName' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be $mockPipeName
                        $comparedReturnValue.Actual | Should -Be $mockPipeName
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the desired protocol is Shared Memory' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'SharedMemory'
                                Enabled      = $true
                            }
                        }

                        $compareTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'SharedMemory'
                            Enabled      = $true
                        }
                    }

                    It 'Should return the correct metadata for each protocol property' {
                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 1

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the desired protocol is TCP/IP' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName           = $mockInstanceName
                                ProtocolName           = 'TcpIp'
                                Enabled                = $false
                                KeepAlive              = 30000
                                ListenOnAllIpAddresses = $false
                            }
                        }

                        $compareTargetResourceParameters = @{
                            InstanceName           = $mockInstanceName
                            ProtocolName           = 'TcpIp'
                            Enabled                = $true
                            KeepAlive              = 50000
                            ListenOnAllIpAddresses = $true
                        }
                    }

                    It 'Should return the correct metadata for each protocol property' {
                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 3

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeFalse
                        $comparedReturnValue.InDesiredState | Should -BeFalse

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'ListenOnAllIpAddresses' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeFalse
                        $comparedReturnValue.InDesiredState | Should -BeFalse

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'KeepAlive' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be 50000
                        $comparedReturnValue.Actual | Should -Be 30000
                        $comparedReturnValue.InDesiredState | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the desired protocol is Named Pipes' {
                    BeforeAll {
                        $mockPipeName = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'
                        $mockExpectedPipeName = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'NamedPipes'
                                Enabled      = $false
                                PipeName     = $mockPipeName
                            }
                        }

                        $compareTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'NamedPipes'
                            Enabled      = $true
                            PipeName     = $mockExpectedPipeName
                        }
                    }

                    It 'Should return the correct metadata for each protocol property' {
                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 2

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeFalse
                        $comparedReturnValue.InDesiredState | Should -BeFalse

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'PipeName' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be $mockExpectedPipeName
                        $comparedReturnValue.Actual | Should -Be $mockPipeName
                        $comparedReturnValue.InDesiredState | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the desired protocol is Shared Memory' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'SharedMemory'
                                Enabled      = $false
                            }
                        }

                        $compareTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'SharedMemory'
                            Enabled      = $true
                        }
                    }

                    It 'Should return the correct metadata for each protocol property' {
                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 1

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeFalse
                        $comparedReturnValue.InDesiredState | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe 'SqlServerProtocol\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $mockInstanceName = 'DSCTEST'
            }

            Context 'When the SQL Server instance does not exist' {
                Mock -CommandName Compare-TargetResourceState -MockWith {
                    return @(
                        @{
                            InDesiredState = $false
                        }
                    )
                }

                BeforeAll {
                    Mock -CommandName Get-ServerProtocolObject -MockWith {
                        return $null
                    }

                    $setTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'SharedMemory'
                    }
                }

                It 'Should throw the correct error' {
                    $expectedErrorMessage = $script:localizedData.FailedToGetSqlServerProtocol

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $expectedErrorMessage
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                InDesiredState = $true
                            }
                        )
                    }

                    $setTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'SharedMemory'
                        Enabled      = $true
                    }
                }

                It 'Should return $true' {
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the desired protocol is TCP/IP' {
                    Context 'When enabling and setting all the protocol properties' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                    @{
                                        ParameterName = 'ListenOnAllIpAddresses'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                    @{
                                        ParameterName = 'KeepAlive'
                                        Actual = 30000
                                        Expected = 50000
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName           = $mockInstanceName
                                ProtocolName           = 'TcpIp'
                                ListenOnAllIpAddresses = $true
                                KeepAlive              = 50000
                                Enabled                = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When enabling the protocol and leaving the rest of the properties to their default value' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'TcpIp'
                                Enabled      = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When disabling the protocol and leaving the rest of the properties to their default value' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $true
                                        Expected = $false
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $true -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'TcpIp'
                                Enabled      = $false
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When setting the individual protocol properties regardless if the protocol is enabled or disabled' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'ListenOnAllIpAddresses'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                    @{
                                        ParameterName = 'KeepAlive'
                                        Actual = 30000
                                        Expected = 50000
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName           = $mockInstanceName
                                ProtocolName           = 'TcpIp'
                                ListenOnAllIpAddresses = $true
                                KeepAlive              = 50000
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and _not_ restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                        }
                    }

                    Context 'When suppressing the restart' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Write-Warning
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName    = $mockInstanceName
                                ProtocolName    = 'TcpIp'
                                Enabled         = $true
                                SuppressRestart = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should not restart the SQL Server service but instead write a warning message' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the desired protocol is Named Pipes' {
                    Context 'When enabling and setting all the protocol properties' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                    @{
                                        ParameterName = 'PipeName'
                                        Actual = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'
                                        Expected = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            PipeName = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'NamedPipes'
                                PipeName     = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                                Enabled      = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When enabling the protocol and leaving the rest of the properties to their default value' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            PipeName = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'NamedPipes'
                                Enabled      = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When setting the individual protocol properties regardless if the protocol is enabled or disabled' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'PipeName'
                                        Actual = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'
                                        Expected = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            PipeName = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'NamedPipes'
                                PipeName     = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and _not_ restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                        }
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
