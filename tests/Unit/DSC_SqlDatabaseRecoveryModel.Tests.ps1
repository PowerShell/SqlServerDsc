<#
    .SYNOPSIS
        Automated unit test for DSC_SqlDatabaseRecoveryModel DSC resource.

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
$script:dscResourceName = 'DSC_SqlDatabaseRecoveryModel'

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
        $mockSqlDatabaseName = 'AdventureWorks'
        $mockSqlDatabaseRecoveryModel = 'Simple'
        $mockInvalidOperationForAlterMethod = $false
        $mockExpectedRecoveryModel = 'Simple'

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
                        Add-Member -MemberType ScriptProperty -Name Databases -Value {
                        return @{
                            $mockSqlDatabaseName = ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                                    Add-Member -MemberType NoteProperty -Name RecoveryModel -Value $mockSqlDatabaseRecoveryModel -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                    if ($mockInvalidOperationForAlterMethod)
                                    {
                                        throw 'Mock Alter Method was called with invalid operation.'
                                    }

                                    if ( $this.RecoveryModel -ne $mockExpectedRecoveryModel )
                                    {
                                        throw "Called Alter Drop() method without setting the right recovery model. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedRecoveryModel, $this.RecoveryModel
                                    }
                                } -PassThru
                            )
                        }
                    } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "DSC_SqlDatabaseRecoveryModel\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When passing values to parameters and database does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'UnknownDatabase'
                        RecoveryModel = 'Full'
                    }

                    $errorMessage = $script:localizedData.DatabaseNotFound -f $testParameters.Name

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should return wrong RecoveryModel' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Full'
                    }

                    $result = Get-TargetResource @testParameters
                    $result.RecoveryModel | Should -Not -Be $testParameters.RecoveryModel
                }

                It 'Should return the same values as passed as parameters' {
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state for a database' {
                It 'Should return the correct RecoveryModel' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Simple'
                    }

                    $result = Get-TargetResource @testParameters
                    $result.RecoveryModel | Should -Be $testParameters.RecoveryModel
                }

                It 'Should return the same values as passed as parameters' {
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "DSC_SqlDatabaseRecoveryModel\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should return the state as false when desired recovery model is not correct' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Full'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return the state as true when desired recovery model is correct' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Simple'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "DSC_SqlDatabaseRecoveryModel\Set-TargetResource" -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state, and database does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'UnknownDatabase'
                        RecoveryModel = 'Full'
                    }

                    $errorMessage = $script:localizedData.DatabaseNotFound -f $testParameters.Name

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should not throw when calling the alter method when desired recovery model should be set' {
                    $mockExpectedRecoveryModel = 'Full'
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Full'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should throw when calling the alter method when desired recovery model should be set' {
                    $mockInvalidOperationForAlterMethod = $true
                    $mockExpectedRecoveryModel = 'Full'
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Full'
                    }

                    $throwInvalidOperation = ('Exception calling "Alter" with "0" argument(s): ' +
                        '"Mock Alter Method was called with invalid operation."')

                    { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
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
