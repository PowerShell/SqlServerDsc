<#
    .SYNOPSIS
        Unit test for DSC_SqlProtocolTcpIp DSC resource.
#>
BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlProtocolTcpIp'

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
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlProtocolTcpIp\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Import-SQLPSModule

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
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceParameters = @{
                        InstanceName   = $mockInstanceName
                        <#
                            Intentionally using lower-case to test so that
                            the correct casing is returned.
                        #>
                        IpAddressGroup = 'ipall'
                    }

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                    # IP address group should always be returned with the correct casing.
                    $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IPAll'
                    $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                    $getTargetResourceResult.SuppressRestart | Should -BeFalse
                    $getTargetResourceResult.RestartTimeout | Should -Be 120
                    $getTargetResourceResult.Enabled | Should -BeFalse
                    $getTargetResourceResult.IPAddress | Should -BeNullOrEmpty
                    $getTargetResourceResult.UseTcpDynamicPort | Should -BeFalse
                    $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty
                    $getTargetResourceResult.IsActive | Should -BeFalse
                    $getTargetResourceResult.AddressFamily | Should -BeNullOrEmpty
                    $getTargetResourceResult.TcpDynamicPort | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When the IP address group is missing' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Get-ServerProtocolObject -MockWith {
                    return @{
                        IPAddresses = @(
                            [PSCustomObject] @{
                                Name = 'IPAll'
                            }
                            [PSCustomObject] @{
                                Name = 'IP1'
                            }
                        )
                    }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceParameters = @{
                        InstanceName   = $mockInstanceName
                        IpAddressGroup = 'IP2'
                    }

                    { Get-TargetResource @getTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Write-Warning
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the IP address group is IPAll' {
            Context 'When the IP address group is using dynamic port' {
                BeforeAll {
                    Mock -CommandName Get-ServerProtocolObject -MockWith {
                        return @{
                            IPAddresses = @{
                                Name  = 'IPAll'
                                IPAll = @{
                                    IPAddressProperties = @{
                                        TcpPort = @{
                                            Value = ''
                                        }
                                        TcpDynamicPorts = @{
                                            Value = '0'
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IPAll'
                        }

                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IPAll'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeFalse
                        $getTargetResourceResult.IPAddress | Should -BeNullOrEmpty
                        $getTargetResourceResult.UseTcpDynamicPort | Should -BeTrue
                        $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty
                        $getTargetResourceResult.IsActive | Should -BeFalse
                        $getTargetResourceResult.AddressFamily | Should -BeNullOrEmpty
                        $getTargetResourceResult.TcpDynamicPort | Should -BeExactly '0'
                    }
                }
            }

            Context 'When the IP address group is using static TCP ports' {
                BeforeAll {
                    Mock -CommandName Get-ServerProtocolObject -MockWith {
                        return @{
                            IPAddresses = @{
                                Name  = 'IPAll'
                                IPAll = @{
                                    IPAddressProperties = @{
                                        TcpPort = @{
                                            Value = '1433,1500,1501'
                                        }
                                        TcpDynamicPorts = @{
                                            Value = ''
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IPAll'
                        }

                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IPAll'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeFalse
                        $getTargetResourceResult.IPAddress | Should -BeNullOrEmpty
                        $getTargetResourceResult.UseTcpDynamicPort | Should -BeFalse
                        $getTargetResourceResult.TcpPort | Should -BeExactly '1433,1500,1501'
                        $getTargetResourceResult.IsActive | Should -BeFalse
                        $getTargetResourceResult.AddressFamily | Should -BeNullOrEmpty
                        $getTargetResourceResult.TcpDynamicPort | Should -BeNullOrEmpty
                    }
                }
            }
        }

        Context 'When the IP address group is IPx (where x is an available group number)' {
            Context 'When the IP address group is using dynamic port' {
                BeforeAll {
                    Mock -CommandName Get-ServerProtocolObject -MockWith {
                        return @{
                            IPAddresses = @{
                                Name  = 'IP1'
                                IP1 = @{
                                    IPAddress = @{
                                        AddressFamily = 'InterNetworkV6'
                                        IPAddressToString = 'fe80::7894:a6b6:59dd:c8ff%9'
                                    }
                                    IPAddressProperties = @{
                                        TcpPort = @{
                                            Value = ''
                                        }
                                        TcpDynamicPorts = @{
                                            Value = '0'
                                        }
                                        Enabled = @{
                                            Value = $true
                                        }
                                        Active = @{
                                            Value = $true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                        }

                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IP1'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeTrue
                        $getTargetResourceResult.IPAddress | Should -Be 'fe80::7894:a6b6:59dd:c8ff%9'
                        $getTargetResourceResult.UseTcpDynamicPort | Should -BeTrue
                        $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty
                        $getTargetResourceResult.IsActive | Should -BeTrue
                        $getTargetResourceResult.AddressFamily | Should -Be 'InterNetworkV6'
                        $getTargetResourceResult.TcpDynamicPort | Should -BeExactly '0'
                    }
                }
            }

            Context 'When the IP address group is using static TCP ports' {
                BeforeAll {
                    Mock -CommandName Get-ServerProtocolObject -MockWith {
                        return @{
                            IPAddresses = @{
                                Name  = 'IP1'
                                IP1 = @{
                                    IPAddress = @{
                                        AddressFamily = 'InterNetworkV6'
                                        IPAddressToString = 'fe80::7894:a6b6:59dd:c8ff%9'
                                    }
                                    IPAddressProperties = @{
                                        TcpPort = @{
                                            Value = '1433,1500,1501'
                                        }
                                        TcpDynamicPorts = @{
                                            Value = ''
                                        }
                                        Enabled = @{
                                            Value = $true
                                        }
                                        Active = @{
                                            Value = $true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                        }

                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IP1'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeTrue
                        $getTargetResourceResult.IPAddress | Should -Be 'fe80::7894:a6b6:59dd:c8ff%9'
                        $getTargetResourceResult.UseTcpDynamicPort | Should -BeFalse
                        $getTargetResourceResult.TcpPort | Should -BeExactly '1433,1500,1501'
                        $getTargetResourceResult.IsActive | Should -BeTrue
                        $getTargetResourceResult.AddressFamily | Should -Be 'InterNetworkV6'
                        $getTargetResourceResult.TcpDynamicPort | Should -BeNullOrEmpty
                    }
                }
            }
        }
    }
}

Describe 'SqlProtocolTcpIp\Test-TargetResource' -Tag 'Test' {
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
                    InstanceName   = 'DSCTEST'
                    IpAddressGroup = 'IPAll'
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
                    InstanceName   = 'DSCTEST'
                    IpAddressGroup = 'IPAll'
                }

                $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                $testTargetResourceResult | Should -BeFalse
            }

            Should -Invoke -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlProtocolTcpIp\Compare-TargetResourceState' -Tag 'Compare' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockInstanceName = 'DSCTEST'
        }
    }

    Context 'When passing wrong set of parameters' {
        It 'Should throw the an exception when passing both UseTcpDynamicPort and TcpPort' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    InstanceName   = $mockInstanceName
                    IpAddressGroup = 'IPAll'
                    UseTcpDynamicPort = $true
                    TcpPort        = '1433'
                }

                { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the IP address group is IPAll' {
            Context 'When the IP address group is using dynamic port' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IPAll'
                            Enabled            = $false
                            IPAddress          = $null
                            UseTcpDynamicPort  = $true
                            TcpPort            = $null
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName      = $mockInstanceName
                            IpAddressGroup    = 'IPAll'
                            UseTcpDynamicPort = $true
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 1

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'UseTcpDynamicPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IP address group is using static TCP ports' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IPAll'
                            Enabled            = $false
                            IPAddress          = $null
                            UseTcpDynamicPort  = $false
                            TcpPort            = '1433'
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IPAll'
                            TcpPort        = '1433'
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 1

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be '1433'
                        $comparedReturnValue.Actual | Should -Be '1433'
                        $comparedReturnValue.InDesiredState | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the IP address group is IPx (where x is an available group number)' {
            Context 'When the IP address group is using dynamic port' {
                BeforeAll {
                    $mockIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IP1'
                            Enabled            = $true
                            IPAddress          = $mockIpAddress
                            UseTcpDynamicPort  = $true
                            TcpPort            = $null
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    $inModuleScopeParameters = @{
                        MockIPAddress = $mockIpAddress
                    }

                    InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                        # This should be able to be removed in a future version of Pester.
                        param
                        (
                            $MockIPAddress
                        )

                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName      = $mockInstanceName
                            IpAddressGroup    = 'IP1'
                            UseTcpDynamicPort = $true
                            Enabled           = $true
                            IPAddress         = $MockIPAddress
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 3

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'UseTcpDynamicPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be $MockIPAddress
                        $comparedReturnValue.Actual | Should -Be $MockIPAddress
                        $comparedReturnValue.InDesiredState | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IP address group is using static TCP ports' {
                BeforeAll {
                    $mockIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IP1'
                            Enabled            = $true
                            IPAddress          = $mockIpAddress
                            UseTcpDynamicPort  = $false
                            TcpPort            = '1433'
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    $inModuleScopeParameters = @{
                        MockIPAddress = $mockIpAddress
                    }

                    InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                        # This should be able to be removed in a future version of Pester.
                        param
                        (
                            $MockIPAddress
                        )

                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                            TcpPort        = '1433'
                            Enabled        = $true
                            IPAddress      = $mockIpAddress
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 3

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be '1433'
                        $comparedReturnValue.Actual | Should -Be '1433'
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be $mockIpAddress
                        $comparedReturnValue.Actual | Should -Be $mockIpAddress
                        $comparedReturnValue.InDesiredState | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the IP address group is IPAll' {
            Context 'When the IP address group should be using dynamic port' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IPAll'
                            Enabled            = $false
                            IPAddress          = $null
                            UseTcpDynamicPort  = $false
                            TcpPort            = '1433'
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName      = $mockInstanceName
                            IpAddressGroup    = 'IPAll'
                            UseTcpDynamicPort = $true
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 1

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'UseTcpDynamicPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeFalse
                        $comparedReturnValue.InDesiredState | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IP address group should be using static TCP ports' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IPAll'
                            Enabled            = $false
                            IPAddress          = $null
                            UseTcpDynamicPort  = $true
                            TcpPort            = $null
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IPAll'
                            TcpPort        = '1433'
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 1

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be '1433'
                        $comparedReturnValue.Actual | Should -BeNullOrEmpty
                        $comparedReturnValue.InDesiredState | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the IP address group is IPx (where x is an available group number)' {
            Context 'When the IP address group should be using dynamic port' {
                BeforeAll {
                    $mockIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IP1'
                            Enabled            = $true
                            IPAddress          = $mockIpAddress
                            UseTcpDynamicPort  = $false
                            TcpPort            = '1433'
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    $inModuleScopeParameters = @{
                        MockIPAddress = $mockIpAddress
                    }

                    InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                        # This should be able to be removed in a future version of Pester.
                        param
                        (
                            $MockIPAddress
                        )

                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName      = $mockInstanceName
                            IpAddressGroup    = 'IP1'
                            UseTcpDynamicPort = $true
                            Enabled           = $true
                            IPAddress         = $mockIpAddress
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 3

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'UseTcpDynamicPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeFalse
                        $comparedReturnValue.InDesiredState | Should -BeFalse

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be $mockIpAddress
                        $comparedReturnValue.Actual | Should -Be $mockIpAddress
                        $comparedReturnValue.InDesiredState | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IP address group should be using static TCP ports' {
                BeforeAll {
                    $mockIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IP1'
                            Enabled            = $true
                            IPAddress          = $mockIpAddress
                            UseTcpDynamicPort  = $true
                            TcpPort            = $null
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    $inModuleScopeParameters = @{
                        MockIPAddress = $mockIpAddress
                    }

                    InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                        # This should be able to be removed in a future version of Pester.
                        param
                        (
                            $MockIPAddress
                        )

                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                            TcpPort        = '1433'
                            Enabled        = $true
                            IPAddress      = $mockIpAddress
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 3

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be '1433'
                        $comparedReturnValue.Actual | Should -BeNullOrEmpty
                        $comparedReturnValue.InDesiredState | Should -BeFalse

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be $mockIpAddress
                        $comparedReturnValue.Actual | Should -Be $mockIpAddress
                        $comparedReturnValue.InDesiredState | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IP address group has the wrong IP adress' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IP1'
                            Enabled            = $true
                            IPAddress          = '10.0.0.1'
                            UseTcpDynamicPort  = $false
                            TcpPort            = '1433'
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                            TcpPort        = '1433'
                            Enabled        = $true
                            IPAddress      = 'fe80::7894:a6b6:59dd:c8ff%9'
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 3

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be '1433'
                        $comparedReturnValue.Actual | Should -Be '1433'
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -BeTrue
                        $comparedReturnValue.Actual | Should -BeTrue
                        $comparedReturnValue.InDesiredState | Should -BeTrue

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty
                        $comparedReturnValue.Expected | Should -Be 'fe80::7894:a6b6:59dd:c8ff%9'
                        $comparedReturnValue.Actual | Should -Be '10.0.0.1'
                        $comparedReturnValue.InDesiredState | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IP address group has the wrong state for Enabled' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName       = $mockInstanceName
                            IpAddressGroup     = 'IP1'
                            Enabled            = $false
                            IPAddress          = '10.0.0.1'
                            UseTcpDynamicPort  = $false
                            TcpPort            = '1433'
                        }
                    }
                }

                It 'Should return the correct metadata for each protocol property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $compareTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                            Enabled        = $true
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
}

Describe 'SqlProtocolTcpIp\Set-TargetResource' -Tag 'Set' {
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
                    InstanceName   = $mockInstanceName
                    IpAddressGroup = 'IPAll'
                }

                { Set-TargetResource @setTargetResourceParameters } |
                    Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
            }
        }
    }

    Context 'When the IP address group is missing' {
        BeforeAll {
            Mock -CommandName Compare-TargetResourceState -MockWith {
                return @(
                    @{
                        InDesiredState = $false
                    }
                )
            }

            Mock -CommandName Get-ServerProtocolObject -MockWith {
                return @{
                    IPAddresses = @(
                        [PSCustomObject] @{
                            Name = 'IPAll'
                        }
                        [PSCustomObject] @{
                            Name = 'IP1'
                        }
                    )
                }
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorRecord = Get-ObjectNotFoundRecord -Message (
                    $script:localizedData.SetMissingIpAddressGroup -f 'IP2'
                )

                $setTargetResourceParameters = @{
                    InstanceName   = $mockInstanceName
                    IpAddressGroup = 'IP2'
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
                    InstanceName      = $mockInstanceName
                    IpAddressGroup    = 'IPAll'
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the IP address group should be using dynamic port' {
            BeforeAll {
                Mock -CommandName Restart-SqlService
                Mock -CommandName Compare-TargetResourceState -MockWith {
                    return @(
                        @{
                            ParameterName = 'UseTcpDynamicPort'
                            Actual = $false
                            Expected = $true
                            InDesiredState = $false
                        }
                    )
                }

                Mock -CommandName Get-ServerProtocolObject -MockWith {
                    return New-Object -TypeName PSObject |
                            Add-Member -MemberType NoteProperty -Name 'IPAddresses' -Value @{
                                Name  = 'IPAll'
                                IPAll = New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IPAddressProperties' -Value @{
                                        TcpPort = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value '1433' -PassThru -Force
                                        TcpDynamicPorts = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value '' -PassThru -Force
                                    } -PassThru -Force
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                <#
                                    Verifies that the correct value was set by the test,
                                    and to verify that the method Alter() is actually called.
                                #>
                                $ipAddressProperties = $this.IPAddresses['IPAll'].IPAddressProperties

                                if ($ipAddressProperties['TcpDynamicPorts'].Value -eq '0' `
                                    -and $ipAddressProperties['TcpPort'].Value -eq '')
                                {
                                    InModuleScope -ScriptBlock {
                                        $script:wasMethodAlterCalled = $true
                                    }
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
                        InstanceName      = $mockInstanceName
                        IpAddressGroup    = 'IPAll'
                        UseTcpDynamicPort = $true
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    <#
                        Addition evaluation is done in the mock to test if the
                        object is set correctly.
                    #>
                    $script:wasMethodAlterCalled | Should -BeTru
                }

                Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the IP address group should be using static port' {
            BeforeAll {
                Mock -CommandName Restart-SqlService
                Mock -CommandName Compare-TargetResourceState -MockWith {
                    return @(
                        @{
                            ParameterName = 'TcpPort'
                            Actual = ''
                            Expected = '1433,1500,1501'
                            InDesiredState = $false
                        }
                    )
                }

                Mock -CommandName Get-ServerProtocolObject -MockWith {
                    return New-Object -TypeName PSObject |
                            Add-Member -MemberType NoteProperty -Name 'IPAddresses' -Value @{
                                Name  = 'IPAll'
                                IPAll = New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IPAddressProperties' -Value @{
                                        TcpPort = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value '' -PassThru -Force
                                        TcpDynamicPorts = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value '50000' -PassThru -Force
                                    } -PassThru -Force
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                <#
                                    Verifies that the correct value was set by the test,
                                    and to verify that the method Alter() is actually called.
                                #>
                                $ipAddressProperties = $this.IPAddresses['IPAll'].IPAddressProperties

                                if ($ipAddressProperties['TcpDynamicPorts'].Value -eq '' `
                                    -and $ipAddressProperties['TcpPort'].Value -eq '1433,1500,1501')
                                {
                                    InModuleScope -ScriptBlock {
                                        $script:wasMethodAlterCalled = $true
                                    }
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
                        InstanceName   = $mockInstanceName
                        IpAddressGroup = 'IPAll'
                        TcpPort        = '1433,1500,1501'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    <#
                        Addition evaluation is done in the mock to test if the
                        object is set correctly.
                    #>
                    $script:wasMethodAlterCalled | Should -BeTrue
                }

                Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the IP address group is IPx (where x is an available group number)' {
            Context 'When the IP address group should be enabled' {
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
                                Add-Member -MemberType NoteProperty -Name 'IPAddresses' -Value @{
                                    Name  = 'IP1'
                                    IP1 = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'IPAddressProperties' -Value @{
                                                Enabled = New-Object -TypeName PSObject |
                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            } -PassThru -Force
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                    <#
                                        Verifies that the correct value was set by the test,
                                        and to verify that the method Alter() is actually called.
                                    #>
                                    $ipAddressProperties = $this.IPAddresses['IP1'].IPAddressProperties

                                    if ($ipAddressProperties['Enabled'].Value -eq $true)
                                    {
                                        InModuleScope -ScriptBlock {
                                            $script:wasMethodAlterCalled = $true
                                        }
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
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                            Enabled        = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        <#
                            Addition evaluation is done in the mock to test if the
                            object is set correctly.
                        #>
                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IP address group should be disabled' {
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
                                Add-Member -MemberType NoteProperty -Name 'IPAddresses' -Value @{
                                    Name  = 'IP1'
                                    IP1 = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'IPAddressProperties' -Value @{
                                                Enabled = New-Object -TypeName PSObject |
                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $true -PassThru -Force
                                            } -PassThru -Force
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                    <#
                                        Verifies that the correct value was set by the test,
                                        and to verify that the method Alter() is actually called.
                                    #>
                                    $ipAddressProperties = $this.IPAddresses['IP1'].IPAddressProperties

                                    if ($ipAddressProperties['Enabled'].Value -eq $false)
                                    {
                                        InModuleScope -ScriptBlock {
                                            $script:wasMethodAlterCalled = $true
                                        }
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
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                            Enabled        = $false
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        <#
                            Addition evaluation is done in the mock to test if the
                            object is set correctly.
                        #>
                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IP address group have the wrong IP adress' {
                BeforeAll {
                    $mockExpectedIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                    Mock -CommandName Restart-SqlService
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName = 'IpAddress'
                                Actual = '10.0.0.1'
                                Expected = $mockExpectedIpAddress
                                InDesiredState = $false
                            }
                        )
                    }

                    Mock -CommandName Get-ServerProtocolObject -MockWith {
                        return New-Object -TypeName PSObject |
                                Add-Member -MemberType NoteProperty -Name 'IPAddresses' -Value @{
                                    Name  = 'IP1'
                                    IP1 = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'IPAddressProperties' -Value @{
                                                IpAddress = New-Object -TypeName PSObject |
                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value '10.0.0.1' -PassThru -Force
                                            } -PassThru -Force
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                    <#
                                        Verifies that the correct value was set by the test,
                                        and to verify that the method Alter() is actually called.
                                    #>
                                    $ipAddressProperties = $this.IPAddresses['IP1'].IPAddressProperties

                                    if ($ipAddressProperties['IpAddress'].Value -eq $mockExpectedIpAddress)
                                    {
                                        InModuleScope -ScriptBlock {
                                            $script:wasMethodAlterCalled = $true
                                        }
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
                    $inModuleScopeParameters = @{
                        MockExpectedIpAddress = $mockExpectedIpAddress
                    }

                    InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                        # This should be able to be removed in a future version of Pester.
                        param
                        (
                            $MockExpectedIpAddress
                        )

                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP1'
                            IpAddress      = $MockExpectedIpAddress
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        <#
                            Addition evaluation is done in the mock to test if the
                            object is set correctly.
                        #>
                        $script:wasMethodAlterCalled | Should -BeTrue
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the restart should be suppressed' {
                BeforeAll {
                    Mock -CommandName Write-Warning
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
                                Add-Member -MemberType NoteProperty -Name 'IPAddresses' -Value @{
                                    Name  = 'IP1'
                                    IP1 = New-Object -TypeName PSObject |
                                            Add-Member -MemberType NoteProperty -Name 'IPAddressProperties' -Value @{
                                                Enabled = New-Object -TypeName PSObject |
                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $true -PassThru -Force
                                            } -PassThru -Force
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {} -PassThru -Force
                    }
                }

                It 'Should set the desired values and restart the SQL Server service' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            InstanceName    = $mockInstanceName
                            IpAddressGroup  = 'IP1'
                            Enabled         = $false
                            SuppressRestart = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
