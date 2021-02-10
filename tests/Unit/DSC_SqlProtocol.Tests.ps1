<#
    .SYNOPSIS
        Unit test for DSC_SqlProtocol DSC resource.
#>

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlProtocol'

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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlProtocol\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        <#
            It is possible to mock cmdlets from the common modules without
            scoping them to the module's scope since they are imported by
            the module that is being tested.
        #>
        Mock -CommandName Import-SQLPSModule

        <#
            This sets a variable inside the module scope. The name of the
            variable starts with 'mock' so it is unique and does not override
            a real variable inside any of the module's functions.
        #>
        InModuleScope -ScriptBlock {
            $script:mockInstanceName = 'DSCTEST'
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the SQL Server instance does not exist' {
            BeforeAll {
                Mock -CommandName Get-ServerProtocolObject -MockWith {
                    return $null
                }
            }

            It 'Should return the correct values' {
                <#
                    Using InModuleScope to explicit define what functions is tested
                    when several DSC resource are imported which all have the same
                    exported function names (Get-, Set-, Test-TargetResource).
                #>
                InModuleScope -ScriptBlock {
                    <#
                        We want to test that functions aligns with a certain strict mode,
                        but not necessarily want to enforce if during runtime in a user
                        environment. This enables strict mode in the module's scope when
                        the tests run.
                    #>
                    Set-StrictMode -Version 1.0

                    $getTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'TcpIp'
                    }

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                    $getTargetResourceResult.ProtocolName | Should -Be 'TcpIp'
                    # Use the helper function from inside the module (DscResource.Common).
                    $getTargetResourceResult.ServerName | Should -Be (Get-ComputerName)
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
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'TcpIp'
                    }

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                    $getTargetResourceResult.ProtocolName | Should -Be 'TcpIp'
                    # Use the helper function from inside the module (DscResource.Common).
                    $getTargetResourceResult.ServerName | Should -Be (Get-ComputerName)
                    $getTargetResourceResult.SuppressRestart | Should -BeFalse
                    $getTargetResourceResult.RestartTimeout | Should -Be 120
                    $getTargetResourceResult.Enabled | Should -BeTrue
                    $getTargetResourceResult.ListenOnAllIpAddresses | Should -BeTrue
                    $getTargetResourceResult.KeepAlive | Should -Be 30000
                    $getTargetResourceResult.PipeName | Should -BeNullOrEmpty
                    $getTargetResourceResult.HasMultiIPAddresses | Should -BeTrue
                }
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
            }

            It 'Should return the correct values' {
                $inModuleScopeParameters = @{
                    MockPipeName = $mockPipeName
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockPipeName
                    )

                    Set-StrictMode -Version 1.0

                    $getTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'NamedPipes'
                    }

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                    $getTargetResourceResult.ProtocolName | Should -Be 'NamedPipes'
                    # Use the helper function from inside the module (DscResource.Common).
                    $getTargetResourceResult.ServerName | Should -Be (Get-ComputerName)
                    $getTargetResourceResult.SuppressRestart | Should -BeFalse
                    $getTargetResourceResult.RestartTimeout | Should -Be 120
                    $getTargetResourceResult.Enabled | Should -BeTrue
                    $getTargetResourceResult.ListenOnAllIpAddresses | Should -BeFalse
                    $getTargetResourceResult.KeepAlive | Should -Be 0
                    $getTargetResourceResult.PipeName | Should -Be $MockPipeName
                    $getTargetResourceResult.HasMultiIPAddresses | Should -BeFalse
                }
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
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'SharedMemory'
                    }

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                    $getTargetResourceResult.ProtocolName | Should -Be 'SharedMemory'
                    # Use the helper function from inside the module (DscResource.Common).
                    $getTargetResourceResult.ServerName | Should -Be (Get-ComputerName)
                    $getTargetResourceResult.SuppressRestart | Should -BeFalse
                    $getTargetResourceResult.RestartTimeout | Should -Be 120
                    $getTargetResourceResult.Enabled | Should -BeTrue
                    $getTargetResourceResult.ListenOnAllIpAddresses | Should -BeFalse
                    $getTargetResourceResult.KeepAlive | Should -Be 0
                    $getTargetResourceResult.PipeName | Should -BeNullOrEmpty
                    $getTargetResourceResult.HasMultiIPAddresses | Should -BeFalse
                }
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
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceParameters = @{
                        InstanceName    = $mockInstanceName
                        ProtocolName    = 'SharedMemory'
                        SuppressRestart = $true
                        RestartTimeout  = 300
                    }

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                    $getTargetResourceResult.ProtocolName | Should -Be 'SharedMemory'
                    $getTargetResourceResult.SuppressRestart | Should -BeTrue
                    $getTargetResourceResult.RestartTimeout | Should -Be 300
                }
            }
        }
    }
}


Describe 'SqlProtocol\Test-TargetResource' -Tag 'Test' {
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
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InstanceName = 'DSCTEST'
                    ProtocolName = 'SharedMemory'
                }

                $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                $testTargetResourceResult | Should -BeTrue
            }

            Should -Invoke -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
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
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InstanceName = 'DSCTEST'
                    ProtocolName = 'SharedMemory'
                }

                $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                $testTargetResourceResult | Should -BeFalse
            }

            Should -Invoke -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlProtocol\Compare-TargetResourceState' -Tag 'Compare' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockInstanceName = 'DSCTEST'
        }
    }

    Context 'When passing wrong set of parameters for either TCP/IP or Named Pipes' {
        It 'Should throw the an exception when passing both ListenOnAllIpAddresses and PipeName' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InstanceName           = $mockInstanceName
                    ProtocolName           = 'TcpIp'
                    Enabled                = $true
                    ListenOnAllIpAddresses = $false
                    PipeName               = 'any pipe name'
                }

                { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
            }
        }

        It 'Should throw the an exception when passing both KeepAlive and PipeName' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

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
    }

    Context 'When passing wrong set of parameters for Shared Memory' {
        It 'Should throw the an exception when passing PipeName' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InstanceName = $mockInstanceName
                    ProtocolName = 'SharedMemory'
                    Enabled      = $true
                    PipeName     = 'any pipe name'
                }

                { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
            }
        }

        It 'Should throw the an exception when passing KeepAlive' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InstanceName = $mockInstanceName
                    ProtocolName = 'SharedMemory'
                    Enabled      = $true
                    KeepAlive    = 30000
                }

                { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
            }
        }

        It 'Should throw the an exception when passing ListenOnAllIpAddresses' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InstanceName           = $mockInstanceName
                    ProtocolName           = 'SharedMemory'
                    Enabled                = $true
                    ListenOnAllIpAddresses = $true
                }

                { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
            }
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
            }

            It 'Should return the correct metadata for each protocol property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareTargetResourceParameters = @{
                        InstanceName           = $mockInstanceName
                        ProtocolName           = 'TcpIp'
                        Enabled                = $true
                        KeepAlive              = 30000
                        ListenOnAllIpAddresses = $true
                    }

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
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
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
            }

            It 'Should return the correct metadata for each protocol property' {
                $inModuleScopeParameters = @{
                    MockPipeName = $mockPipeName
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockPipeName
                    )

                    Set-StrictMode -Version 1.0

                    $compareTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'NamedPipes'
                        Enabled      = $true
                        PipeName     = $MockPipeName
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 2

                    $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.Expected | Should -BeTrue
                    $comparedReturnValue.Actual | Should -BeTrue
                    $comparedReturnValue.InDesiredState | Should -BeTrue

                    $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'PipeName' })
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.Expected | Should -Be $MockPipeName
                    $comparedReturnValue.Actual | Should -Be $MockPipeName
                    $comparedReturnValue.InDesiredState | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
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
            }

            It 'Should return the correct metadata for each protocol property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'SharedMemory'
                        Enabled      = $true
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.Expected | Should -BeTrue
                    $comparedReturnValue.Actual | Should -BeTrue
                    $comparedReturnValue.InDesiredState | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
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
            }

            It 'Should return the correct metadata for each protocol property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareTargetResourceParameters = @{
                        InstanceName           = $mockInstanceName
                        ProtocolName           = 'TcpIp'
                        Enabled                = $true
                        KeepAlive              = 50000
                        ListenOnAllIpAddresses = $true
                    }

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
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the desired protocol is Named Pipes' {
            BeforeAll {
                $mockPipeName = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'NamedPipes'
                        Enabled      = $false
                        PipeName     = $mockPipeName
                    }
                }
            }

            It 'Should return the correct metadata for each protocol property' {
                $inModuleScopeParameters = @{
                    MockPipeName = $mockPipeName
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockPipeName
                    )

                    Set-StrictMode -Version 1.0

                    $mockExpectedPipeName = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'

                    $compareTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'NamedPipes'
                        Enabled      = $true
                        PipeName     = $mockExpectedPipeName
                    }

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
                    $comparedReturnValue.Actual | Should -Be $MockPipeName
                    $comparedReturnValue.InDesiredState | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
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
            }

            It 'Should return the correct metadata for each protocol property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $compareTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'SharedMemory'
                        Enabled      = $true
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.Expected | Should -BeTrue
                    $comparedReturnValue.Actual | Should -BeFalse
                    $comparedReturnValue.InDesiredState | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlProtocol\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockInstanceName = 'DSCTEST'
        }
    }

    Context 'When the SQL Server instance does not exist' {
        BeforeAll {
            Mock -CommandName Compare-TargetResourceState -MockWith {
                return @(
                    @{
                        InDesiredState = $false
                    }
                )
            }

            Mock -CommandName Get-ServerProtocolObject -MockWith {
                return $null
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorRecord = Get-InvalidOperationRecord -Message $script:localizedData.FailedToGetSqlServerProtocol

                $setTargetResourceParameters = @{
                    InstanceName = $mockInstanceName
                    ProtocolName = 'SharedMemory'
                }

                { Set-TargetResource @setTargetResourceParameters } |
                    Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
            }
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
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    InstanceName = $mockInstanceName
                    ProtocolName = 'SharedMemory'
                    Enabled      = $true
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
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
                                ParameterName  = 'Enabled'
                                Actual         = $false
                                Expected       = $true
                                InDesiredState = $false
                            }
                            @{
                                ParameterName  = 'ListenOnAllIpAddresses'
                                Actual         = $false
                                Expected       = $true
                                InDesiredState = $false
                            }
                            @{
                                ParameterName  = 'KeepAlive'
                                Actual         = 30000
                                Expected       = 50000
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
                                        KeepAlive  = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        InModuleScope -ScriptBlock {
                                            $script:wasMethodAlterCalled = $true
                                        }
                                    } -PassThru -Force
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $script:wasMethodAlterCalled = $false
                    }
                }

                It 'Should set the desired values and restart the SQL Server service' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName           = $mockInstanceName
                            ProtocolName           = 'TcpIp'
                            ListenOnAllIpAddresses = $true
                            KeepAlive              = 50000
                            Enabled                = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }

            Context 'When enabling the protocol and leaving the rest of the properties to their default value' {
                BeforeAll {
                    Mock -CommandName Restart-SqlService
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Enabled'
                                Actual         = $false
                                Expected       = $true
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
                                        KeepAlive  = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        InModuleScope -ScriptBlock {
                                            $script:wasMethodAlterCalled = $true
                                        }
                                    } -PassThru -Force
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $script:wasMethodAlterCalled = $false
                    }
                }

                It 'Should set the desired values and restart the SQL Server service' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'TcpIp'
                            Enabled      = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }

            Context 'When disabling the protocol and leaving the rest of the properties to their default value' {
                BeforeAll {
                    Mock -CommandName Restart-SqlService
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Enabled'
                                Actual         = $true
                                Expected       = $false
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
                                        KeepAlive  = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        InModuleScope -ScriptBlock {
                                            $script:wasMethodAlterCalled = $true
                                        }
                                    } -PassThru -Force
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $script:wasMethodAlterCalled = $false
                    }
                }

                It 'Should set the desired values and restart the SQL Server service' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'TcpIp'
                            Enabled      = $false
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }

            Context 'When setting the individual protocol properties regardless if the protocol is enabled or disabled' {
                BeforeAll {
                    Mock -CommandName Restart-SqlService
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'ListenOnAllIpAddresses'
                                Actual         = $false
                                Expected       = $true
                                InDesiredState = $false
                            }
                            @{
                                ParameterName  = 'KeepAlive'
                                Actual         = 30000
                                Expected       = 50000
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
                                        KeepAlive  = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        InModuleScope -ScriptBlock {
                                            $script:wasMethodAlterCalled = $true
                                        }
                                    } -PassThru -Force
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $script:wasMethodAlterCalled = $false
                    }
                }

                It 'Should set the desired values and _not_ restart the SQL Server service' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName           = $mockInstanceName
                            ProtocolName           = 'TcpIp'
                            ListenOnAllIpAddresses = $true
                            KeepAlive              = 50000
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                }
            }

            Context 'When suppressing the restart' {
                BeforeAll {
                    Mock -CommandName Restart-SqlService
                    Mock -CommandName Write-Warning
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Enabled'
                                Actual         = $false
                                Expected       = $true
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
                                        KeepAlive  = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        InModuleScope -ScriptBlock {
                                            $script:wasMethodAlterCalled = $true
                                        }
                                    } -PassThru -Force
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $script:wasMethodAlterCalled = $false
                    }
                }

                It 'Should not restart the SQL Server service but instead write a warning message' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName    = $mockInstanceName
                            ProtocolName    = 'TcpIp'
                            Enabled         = $true
                            SuppressRestart = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Scope It
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
                                ParameterName  = 'Enabled'
                                Actual         = $false
                                Expected       = $true
                                InDesiredState = $false
                            }
                            @{
                                ParameterName  = 'PipeName'
                                Actual         = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'
                                Expected       = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
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
                                    InModuleScope -ScriptBlock {
                                        $script:wasMethodAlterCalled = $true
                                    }
                                } -PassThru -Force
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $script:wasMethodAlterCalled = $false
                    }
                }

                It 'Should set the desired values and restart the SQL Server service' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'NamedPipes'
                            PipeName     = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                            Enabled      = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }

            Context 'When enabling the protocol and leaving the rest of the properties to their default value' {
                BeforeAll {
                    Mock -CommandName Restart-SqlService
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Enabled'
                                Actual         = $false
                                Expected       = $true
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
                                    InModuleScope -ScriptBlock {
                                        $script:wasMethodAlterCalled = $true
                                    }
                                } -PassThru -Force
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $script:wasMethodAlterCalled = $false
                    }
                }

                It 'Should set the desired values and restart the SQL Server service' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'NamedPipes'
                            Enabled      = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }

            Context 'When setting the individual protocol properties regardless if the protocol is enabled or disabled' {
                BeforeAll {
                    Mock -CommandName Restart-SqlService
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'PipeName'
                                Actual         = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'
                                Expected       = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
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
                                    InModuleScope -ScriptBlock {
                                        $script:wasMethodAlterCalled = $true
                                    }
                                } -PassThru -Force
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $script:wasMethodAlterCalled = $false
                    }
                }

                It 'Should set the desired values and _not_ restart the SQL Server service' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName = $mockInstanceName
                            ProtocolName = 'NamedPipes'
                            PipeName     = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                }
            }
        }
    }
}
