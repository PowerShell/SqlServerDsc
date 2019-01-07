<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlAgentOperator DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

# This is used to make sure the unit test run in a container.
[Microsoft.DscResourceKit.UnitTest(ContainerName = 'Container1', ContainerImage = 'microsoft/windowsservercore')]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlAgentOperator'

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
    # Loading mocked classes
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
        $mockSqlAgentOperatorName = 'Nancy'
        $mockSqlAgentOperatorEmail = 'nancy@contoso.com'
        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod = $false
        $mockInvalidOperationForAlterMethod = $false
        $mockExpectedSqlAgentOperatorToCreate = 'Bob'
        $mockExpectedSqlAgentOperatorToDrop = 'Bill'

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
        }

        #region Function mocks
        $mockConnectSQL = {
            return @(
                (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
                    Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
                    Add-Member -MemberType ScriptProperty -Name JobServer -Value {
                        return (New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name Name -Value $mockServerName -PassThru |
                            Add-Member -MemberType ScriptProperty -Name Operators -Value {
                                return ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.Operator |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlAgentOperatorName -PassThru -Force |
                                    Add-Member -MemberType NoteProperty -Name EmailAddress -Value $mockSqlAgentOperatorEmail -PassThru -Force |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                        if ($mockInvalidOperationForDropMethod)
                                        {
                                            throw 'Mock Drop Method was called with invalid operation.'
                                        }
                                        if ( $this.Name -ne $mockExpectedSqlAgentOperatorToDrop )
                                        {
                                            throw "Called mocked Drop() method without dropping the right sql agent operator. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedSqlAgentOperatorToDrop, $this.Name
                                        }
                                    } -PassThru -Force |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                        if ($mockInvalidOperationForAlterMethod)
                                        {
                                            throw 'Mock Alter Method was called with invalid operation.'
                                        }
                                    } -PassThru -Force
                                )
                            } -PassThru
                        )
                    } -PassThru -Force
                )
            )
        }

        $mockNewSqlAgentOperator  = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlAgentOperatorName -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Create -Value {
                        if ($mockInvalidOperationForCreateMethod)
                        {
                            throw 'Mock Create Method was called with invalid operation.'
                        }

                        if ( $this.Name -ne $mockExpectedSqlAgentOperatorToCreate )
                        {
                            throw "Called mocked Create() method without adding the right sql agent operator. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedSqlAgentOperatorToCreate, $this.Name
                        }
                    } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "MSFT_SqlAgentOperator\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name         = 'MissingOperator'
                    EmailAddress = 'missing@operator.com'
                }

                It 'Should return the state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is in the desired state for a sql agent operator' {

                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name         = 'Nancy'
                    EmailAddress = 'nancy@contoso.com'
                }

                It 'Should return the state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.EmailAddress | Should -Be $testParameters.EmailAddress
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

Describe "MSFT_SqlAgentOperator\Test-TargetResource" -Tag 'Test' {
    BeforeEach {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when desired sql agent operator does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name         = 'MissingOperator'
                        EmailAddress = 'missing@operator.com'
                        Ensure       = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should return the state as false when desired sql agent operator exists but has the incorrect email' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name            = 'Nancy'
                        Ensure          = 'Present'
                        EmailAddress    = 'wrongEmail@contoso.com'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should return the state as false when non-desired sql agent operator exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Nancy'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Present' {
                It 'Should return the state as true when desired sql agent operator exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'Nancy'
                        Ensure    = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should return the state as true when desired sql asgent operator exists and has the correct email' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name            = 'Nancy'
                        Ensure          = 'Present'
                        EmailAddress    = 'nancy@contoso.com'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                It 'Should return the state as true when desired sql agent operator does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'UnknownOperator'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlAgentOperator\Set-TargetResource" -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewSqlAgentOperator -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator'
                } -Verifiable
            }

            $mockSqlAgentOperatorName = 'Fred'

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should not throw when creating the sql agent operator' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Bob'
                        Ensure = 'Present'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should not throw when changing the email address' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'Nancy'
                        Ensure    = 'Present'
                        EmailAddress = 'newemail@contoso.com'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Operator' {
                    Assert-MockCalled New-Object -Exactly -Times 4 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator'
                    } -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should not throw when dropping the sql agent operator' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Bob'
                        Ensure = 'Absent'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockInvalidOperationForCreateMethod = $true
            $mockInvalidOperationForAlterMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should throw the correct error when Create() method was called with invalid operation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'NewOperator'
                        Ensure = 'Present'
                    }

                    $throwInvalidOperation = ('InnerException: Exception calling "Create" ' + `
                            'with "0" argument(s): "Mock Create Method was called with invalid operation."')

                            { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation
                        }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Operator' {
                    Assert-MockCalled New-Object -Exactly -Times 2 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator'
                    } -Scope Context
                }
            }

            #$mockSqlAgentOperatorName = 'Bill'
            $mockInvalidOperationForDropMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Absent' {

                write-host ("mockInvalidOperationForDropMethod set to {0}" -f $mockInvalidOperationForDropMethod)
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name      = 'Nancy'
                    Ensure    = 'Absent'
                }
                $throwInvalidOperation = ('InnerException: Exception calling "Drop" ' + `
                        'with "0" argument(s): "Mock Drop Method was called with invalid operation."')

                It 'Should throw the correct error when Drop() method was called with invalid operation' {
                    { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
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
