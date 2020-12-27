<#
    .SYNOPSIS
        Unit test for DSC_SqlAgentOperator DSC resource.
#>

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlAgentOperator'

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

Describe 'DSC_SqlAgentOperator\Get-TargetResource' -Tag 'Get' {
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
                        Add-Member -MemberType 'ScriptProperty' -Name 'JobServer' -Value {
                            return (
                                New-Object -TypeName 'Object' |
                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $mockServerName -PassThru |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'Operators' -Value {
                                        return (
                                            New-Object -TypeName 'Object' |
                                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Nancy' -PassThru |
                                                Add-Member -MemberType 'NoteProperty' -Name 'EmailAddress' -Value 'nancy@contoso.com' -PassThru -Force
                                        )
                                    } -PassThru
                            )
                        } -PassThru -Force
                )
            )
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
    }

    Context 'When the system is not in the desired state' {
        It 'Should return the state as absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'MissingOperator'
                }

                $result = Get-TargetResource @testParameters

                $result.Ensure | Should -Be 'Absent'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'MissingOperator'
                }

                $result = Get-TargetResource @testParameters

                $result.ServerName | Should -Be $testParameters.ServerName
                $result.InstanceName | Should -Be $testParameters.InstanceName
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is in the desired state for a sql agent operator' {
        It 'Should return the state as present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'Nancy'
                }

                $result = Get-TargetResource @testParameters

                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'Nancy'
                }

                $result = Get-TargetResource @testParameters

                $result.ServerName | Should -Be $testParameters.ServerName
                $result.InstanceName | Should -Be $testParameters.InstanceName
                $result.Name | Should -Be $testParameters.Name
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    It 'Should call all verifiable mocks' {
        Should -InvokeVerifiable
    }
}

Describe 'DSC_SqlAgentOperator\Test-TargetResource' -Tag 'Test' {
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
        Context 'When desired sql agent operator does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = $null
                        Ensure       = 'Absent'
                        ServerName   = $ServerName
                        InstanceName = $mockInstanceName
                        EmailAddress = $null
                    }
                }
            }

            It 'Should return the state as false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name         = 'MissingOperator'
                        EmailAddress = 'missing@operator.com'
                        Ensure       = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When desired sql agent operator exists but has the incorrect email' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'Nancy'
                        Ensure       = 'Present'
                        ServerName   = $ServerName
                        InstanceName = $mockInstanceName
                        EmailAddress = 'wrongEmail@contoso.com'
                    }
                }
            }

            It 'Should return the state as false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name         = 'Nancy'
                        Ensure       = 'Present'
                        EmailAddress = 'desiredEmail@contoso.com'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the operator should not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'Nancy'
                        Ensure       = 'Present'
                        ServerName   = $ServerName
                        InstanceName = $mockInstanceName
                        EmailAddress = 'wrongEmail@contoso.com'
                    }
                }
            }

            It 'Should return the state as false when non-desired sql agent operator exist' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Nancy'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When desired sql agent operator exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'Nancy'
                        Ensure       = 'Present'
                        ServerName   = $ServerName
                        InstanceName = $mockInstanceName
                        EmailAddress = 'desiredEmail@contoso.com'
                    }
                }
            }

            It 'Should return the state as true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Nancy'
                        Ensure = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When desired sql agent operator exists and has the correct email' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'Nancy'
                        Ensure       = 'Present'
                        ServerName   = $ServerName
                        InstanceName = $mockInstanceName
                        EmailAddress = 'nancy@contoso.com'
                    }
                }
            }

            It 'Should return the state as true ' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name         = 'Nancy'
                        Ensure       = 'Present'
                        EmailAddress = 'nancy@contoso.com'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When desired sql agent operator does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = $null
                        Ensure       = 'Absent'
                        ServerName   = $ServerName
                        InstanceName = $mockInstanceName
                        EmailAddress = $null
                    }
                }
            }

            It 'Should return the state as true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'UnknownOperator'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_SqlAgentOperator\Set-TargetResource' -Tag 'Set' {
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

        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod = $false
        $mockInvalidOperationForAlterMethod = $false
        $mockExpectedSqlAgentOperatorToCreate = 'Bob'
        $mockExpectedSqlAgentOperatorToDrop = 'Bill'

        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName 'Object' |
                        Add-Member -MemberType 'ScriptProperty' -Name 'JobServer' -Value {
                            return (
                                New-Object -TypeName 'Object' |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'Operators' -Value {
                                        return (
                                            New-Object -TypeName 'Object' |
                                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Nancy' -PassThru |
                                                Add-Member -MemberType 'NoteProperty' -Name 'EmailAddress' -Value 'nancy@contoso.com' -PassThru |
                                                Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                                                    if ($mockInvalidOperationForDropMethod)
                                                    {
                                                        throw 'Mock Drop Method was called with invalid operation.'
                                                    }

                                                    if ($this.Name -eq $mockExpectedSqlAgentOperatorToDrop)
                                                    {
                                                        throw "Called mocked Drop() method without dropping the right sql agent operator. Expected '{0}'. But was '{1}'." `
                                                            -f $mockExpectedSqlAgentOperatorToDrop, $this.Name
                                                    }
                                                } -PassThru |
                                                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                                                    if ($mockInvalidOperationForAlterMethod)
                                                    {
                                                        throw 'Mock Alter Method was called with invalid operation.'
                                                    }
                                                } -PassThru -Force
                                        )
                                    } -PassThru -Force
                            )
                        } -PassThru -Force
                )
            )
        }

        $mockNewSqlAgentOperator = {
            return @(
                (
                    New-Object -TypeName 'Object' |
                        # Using the value from the second property passed in the parameter ArgumentList of the cmdlet New-Object.
                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $ArgumentList[1] -PassThru |
                        Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                            if ($mockInvalidOperationForCreateMethod)
                            {
                                throw 'Mock Create Method was called with invalid operation.'
                            }

                            if ($this.Name -ne $mockExpectedSqlAgentOperatorToCreate)
                            {
                                throw "Called mocked Create() method without adding the right sql agent operator. Expected '{0}'. But was '{1}'." `
                                    -f $mockExpectedSqlAgentOperatorToCreate, $this.Name
                            }
                        } -PassThru -Force
                )
            )
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            Mock -CommandName New-Object -MockWith $mockNewSqlAgentOperator -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator'
            } -Verifiable
        }

        Context 'When creating the sql agent operator' {
            It 'Should not throw' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Bob'
                        Ensure = 'Present'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator'
                } -Scope It
            }
        }

        Context 'When changing the email address' {
            It 'Should not throw' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name         = 'Nancy'
                        Ensure       = 'Present'
                        EmailAddress = 'newemail@contoso.com'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When dropping the sql agent operator' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            It 'Should not throw' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Bill'
                        Ensure = 'Absent'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Create() method was called with invalid operation' {
            It 'Should throw the correct error' {
                $mockInvalidOperationForCreateMethod = $true

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'NewOperator'
                        Ensure = 'Present'
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message (
                        $script:localizedData.CreateOperatorSetError -f $testParameters.Name, $testParameters.ServerName, $testParameters.InstanceName
                    )

                    <#
                        Using wildcard for comparison due to that the mock throws and adds
                        the mocked exception message on top of the original message.
                    #>
                    { Set-TargetResource @testParameters } |
                        Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
                }

                $mockInvalidOperationForCreateMethod = $false
            }
        }

        Context 'When Alter() method was called with invalid operation' {
            It 'Should not throw' {
                $mockInvalidOperationForAlterMethod = $true

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name         = 'Nancy'
                        Ensure       = 'Present'
                        EmailAddress = 'newemail@contoso.com'
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message (
                        $script:localizedData.UpdateOperatorSetError -f $testParameters.ServerName, $testParameters.InstanceName, $testParameters.Name, $testParameters.EmailAddress
                    )

                    <#
                        Using wildcard for comparison due to that the mock throws and adds
                        the mocked exception message on top of the original message.
                    #>
                    { Set-TargetResource @testParameters } |
                        Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
                }

                $mockInvalidOperationForAlterMethod = $false
            }
        }

        Context 'When Drop() method was called with invalid operation' {
            It 'Should throw the correct error' {
                $mockInvalidOperationForDropMethod = $true

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Nancy'
                        Ensure = 'Absent'
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message (
                        $script:localizedData.DropOperatorSetError -f $testParameters.Name, $testParameters.ServerName, $testParameters.InstanceName
                    )

                    <#
                        Using wildcard for comparison due to that the mock throws and adds
                        the mocked exception message on top of the original message.
                    #>
                    { Set-TargetResource @testParameters } |
                        Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
                }

                $mockInvalidOperationForDropMethod = $false
            }
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }
}
