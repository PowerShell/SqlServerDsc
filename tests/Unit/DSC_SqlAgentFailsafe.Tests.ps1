<#
    .SYNOPSIS
        Unit test for DSC_SqlAgentFailsafe DSC resource.
#>

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlAgentFailsafe'

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

Describe 'DSC_SqlAgentFailsafe\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockServerName = 'localhost'
            $script:mockInstanceName = 'MSSQLSERVER'

            # Default parameters that are used for the It-blocks
            $script:mockDefaultParameters = @{
                InstanceName = $mockInstanceName
                ServerName   = $mockServerName
            }
        }

        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName 'Object' |
                        Add-Member -MemberType 'ScriptProperty' -Name JobServer -Value {
                            return @(
                                (
                                    New-Object -TypeName 'Object' |
                                        Add-Member -MemberType 'ScriptProperty' -Name AlertSystem -Value {
                                            return ( New-Object -TypeName 'Object' |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'FailSafeOperator' -Value 'FailsafeOp' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'NotificationMethod' -Value 'NotifyEmail' -PassThru -Force
                                                )
                                            } -PassThru -Force
                                        )
                                    )
                        } -PassThru -Force
                )
            )
        }
    }

    Context 'When Connect-SQL returns nothing' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                return $null
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()
                $mockTestParameters.Name = 'FailsafeOp'

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.ConnectServerFailed -f $mockTestParameters.ServerName, $mockTestParameters.InstanceName
                )

                { Get-TargetResource @mockTestParameters } |
                    Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            InModuleScope -ScriptBlock {
                $script:mockTestParameters = $mockDefaultParameters.Clone()
                $script:mockTestParameters.Name = 'DifferentOp'
            }
        }

        It 'Should return the state as absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockTestParameters

                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockTestParameters

                $result.ServerName | Should -Be $mockTestParameters.ServerName
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
            }
        }

        It 'Should call the mock function Connect-SQL' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-TargetResource @mockTestParameters } | Should -Not -Throw

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }

    Context 'When the system is in the desired state for a sql agent failsafe operator' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

            InModuleScope -ScriptBlock {
                $script:mockTestParameters = $mockDefaultParameters.Clone()
                $script:mockTestParameters.Name = 'FailsafeOp'
            }
        }

        It 'Should return the state as present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0


                $result = Get-TargetResource @mockTestParameters

                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockTestParameters

                $result.ServerName | Should -Be $mockTestParameters.ServerName
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
                $result.Name | Should -Be $mockTestParameters.Name
                $result.NotificationMethod | Should -Be 'NotifyEmail'
            }
        }

        It 'Should call the mock function Connect-SQL' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-TargetResource @mockTestParameters } | Should -Not -Throw

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }
}

Describe 'DSC_SqlAgentFailsafe\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockServerName = 'localhost'
            $script:mockInstanceName = 'MSSQLSERVER'

            # Default parameters that are used for the It-blocks
            $script:mockDefaultParameters = @{
                InstanceName = $mockInstanceName
                ServerName   = $mockServerName
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When desired sql agent failsafe operator does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = $null
                        Ensure             = 'Absent'
                        ServerName         = $ServerName
                        InstanceName       = $InstanceName
                        NotificationMethod = $null
                    }
                }
            }

            It 'Should return the state as false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters.Clone()
                    $mockTestParameters.Name = 'MissingFailsafe'
                    $mockTestParameters.NotificationMethod = 'NotifyEmail'
                    $mockTestParameters.Ensure = 'Present'

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When desired sql agent failsafe operator exists but has the incorrect notification method' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'FailsafeOp'
                        Ensure             = 'Absent'
                        ServerName         = $ServerName
                        InstanceName       = $InstanceName
                        NotificationMethod = 'NotifyEmail'
                    }
                }
            }

            It 'Should return the state as false ' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters.Clone()
                    $mockTestParameters.Name = 'FailsafeOp'
                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.NotificationMethod = 'Pager'

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the failsafe operator should not exists' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'FailsafeOp'
                        Ensure             = 'Present'
                        ServerName         = $ServerName
                        InstanceName       = $InstanceName
                        NotificationMethod = 'NotifyEmail'
                    }
                }
            }

            It 'Should return the state as false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters.Clone()
                    $mockTestParameters.Name = 'FailsafeOp'
                    $mockTestParameters.Ensure = 'Absent'

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When desired sql agent failsafe operator exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'FailsafeOp'
                        Ensure             = 'Present'
                        ServerName         = $ServerName
                        InstanceName       = $InstanceName
                        NotificationMethod = 'NotifyEmail'
                    }
                }
            }

            It 'Should return the state as true ' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters.Clone()
                    $mockTestParameters.Name = 'FailsafeOp'
                    $mockTestParameters.Ensure = 'Present'

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When desired sql agent failsafe operator exists and has the correct notification method' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'FailsafeOp'
                        Ensure             = 'Present'
                        ServerName         = $ServerName
                        InstanceName       = $InstanceName
                        NotificationMethod = 'NotifyEmail'
                    }
                }
            }

            It 'Should return the state as true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters.Clone()
                    $mockTestParameters.Name = 'FailsafeOp'
                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.NotificationMethod = 'NotifyEmail'

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When desired sql agent failsafe operator does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = $null
                        Ensure             = 'Absent'
                        ServerName         = $ServerName
                        InstanceName       = $InstanceName
                        NotificationMethod = $null
                    }
                }
            }

            It 'Should return the state as true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters.Clone()
                    $mockTestParameters.Name = 'NotFailsafe'
                    $mockTestParameters.Ensure = 'Absent'

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_SqlAgentFailsafe\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockServerName = 'localhost'
            $script:mockInstanceName = 'MSSQLSERVER'

            # Default parameters that are used for the It-blocks
            $script:mockDefaultParameters = @{
                InstanceName = $mockInstanceName
                ServerName   = $mockServerName
            }
        }

        $mockInvalidOperationForAlterMethod = $false

        # Mocked object for Connect-SQL.
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName 'Object' |
                        Add-Member -MemberType 'ScriptProperty' -Name JobServer -Value {
                            return @(
                                (
                                    New-Object -TypeName 'Object' |
                                        Add-Member -MemberType 'ScriptProperty' -Name AlertSystem -Value {
                                            return ( New-Object -TypeName 'Object' |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'FailSafeOperator' -Value 'FailsafeOp' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'NotificationMethod' -Value 'NotifyEmail' -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                                        if ($mockInvalidOperationForAlterMethod)
                                                        {
                                                            throw 'Mock Alter Method was called with invalid operation.'
                                                        }
                                                    } -PassThru -Force
                                                )
                                            } -PassThru -Force
                                        )
                                    )
                                } -PassThru -Force
                )
            )
        }
    }

    Context 'When Connect-SQL returns nothing' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                return $null
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()
                $mockTestParameters += @{
                    Name   = 'FailsafeOp'
                    Ensure = 'Present'
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.ConnectServerFailed -f $mockTestParameters.ServerName, $mockTestParameters.InstanceName
                )

                { Set-TargetResource @mockTestParameters } |
                    Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
            }
        }
    }

    Context 'When the system is not in the desired state and Ensure is set to Present'{
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
        }

        BeforeEach {
            $mockInvalidOperationForAlterMethod = $false
        }

        It 'Should not throw when adding the sql agent failsafe operator' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()

                $mockTestParameters += @{
                    Name   = 'Newfailsafe'
                    Ensure = 'Present'
                }

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should not throw when changing the severity'  {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()

                $mockTestParameters += @{
                    Name                = 'Newfailsafe'
                    Ensure              = 'Present'
                    NotificationMethod  = 'Pager'
                }

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should throw when notification method is not valid' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()

                $mockTestParameters += @{
                    Name                = 'Newfailsafe'
                    Ensure              = 'Present'
                    NotificationMethod  = 'Letter'
                }

                { Set-TargetResource @mockTestParameters } | Should -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 0 -Scope It
        }

        It 'Should throw the correct error when Alter() method was called with invalid operation' {
            $mockInvalidOperationForAlterMethod = $true

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()

                $mockTestParameters += @{
                    Name   = 'NewFailsafe'
                    Ensure = 'Present'
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.UpdateFailsafeOperatorError -f $mockTestParameters.Name, $mockTestParameters.ServerName, $mockTestParameters.InstanceName
                )

                { Set-TargetResource @mockTestParameters } |
                    Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }

    Context 'When the system is not in the desired state and Ensure is set to Absent' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
        }

        BeforeEach {
            $mockInvalidOperationForAlterMethod = $false
        }

        It 'Should not throw when removing the sql agent failsafe operator' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()

                $mockTestParameters += @{
                    Name   = 'FailsafeOp'
                    Ensure = 'Absent'
                }

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should throw the correct error when Alter() method was called with invalid operation' {
            $mockInvalidOperationForAlterMethod = $true

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()

                $mockTestParameters += @{
                    Name   = 'FailsafeOp'
                    Ensure = 'Absent'
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.UpdateFailsafeOperatorError -f $mockTestParameters.Name, $mockTestParameters.ServerName, $mockTestParameters.InstanceName
                )

                { Set-TargetResource @mockTestParameters } |
                    Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }
}
