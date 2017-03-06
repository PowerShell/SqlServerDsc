$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerDatabaseRecoveryModel'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup
    InModuleScope $script:DSCResourceName {
        $mockSqlServerName                   = 'localhost'
        $mockSqlServerInstanceName           = 'MSSQLSERVER'
        $mockSqlDatabaseName                 = 'AdventureWorks'
        $mockSqlDatabaseRecoveryModel        = 'Simple'
        $mockInvalidOperationForAlterMethod  = $false
        $mockExpectedRecoveryModel           = 'Simple'

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            SQLInstanceName = $mockSqlServerInstanceName
            SQLServer       = $mockSqlServerName
        }
        
        #region Function mocks        
        $mockConnectSQL = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockSqlServerInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockSqlServerName -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Databases -Value {
                            return @{
                                $mockSqlDatabaseName = ( New-Object Object | 
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

        Describe "MSFT_xSQLServerDatabase\Get-TargetResource" -Tag 'Get'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

        Context 'When passing values to parameters and database does not exist' {
            It 'Should throw the correct error' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name        = 'UnknownDatabase'
                    RecoveryModel = 'Full'
                }

                $throwInvalidOperation = ("Database 'UnknownDatabase' does not exist " + `
                                          "on SQL server 'localhost\MSSQLSERVER'.")

                { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
            }
        }
               
        Context 'When the system is not in the desired state' {
            It 'Should return wrong RecoveryModel' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    RecoveryModel = 'Full'
                }

                $result = Get-TargetResource @testParameters
                $result.RecoveryModel | Should Not Be $testParameters.RecoveryModel
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
            }
        }
    
        Context 'When the system is in the desired state for a database' {
            It 'Should return the correct RecoveryModel' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    RecoveryModel = 'Simple'
                }
    
                $result = Get-TargetResource @testParameters
                $result.RecoveryModel | Should Be $testParameters.RecoveryModel
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
            }
        }

        Assert-VerifiableMocks
    }
    
    
    Describe "MSFT_xSQLServerDatabase\Test-TargetResource" -Tag 'Test'{
        BeforeEach {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
        }

        Context 'When the system is not in the desired state' {
            It 'Should return the state as false when desired recovery model is not correct' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    RecoveryModel = 'Full'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }
            
            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
            }                
        }

        Context 'When the system is in the desired state' {
            It 'Should return the state as true when desired recovery model is correct' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    RecoveryModel = 'Simple'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
            } 
        }

        Assert-VerifiableMocks
    }
    
    Describe "MSFT_xSQLServerDatabase\Set-TargetResource" -Tag 'Set'{
        BeforeEach {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
        }

        Context 'When the system is not in the desired state, and database does not exist' {
            It 'Should throw the correct error' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name        = 'UnknownDatabase'
                    RecoveryModel = 'Full'
                }

                $throwInvalidOperation = ("Database 'UnknownDatabase' does not exist " + `
                                          "on SQL server 'localhost\MSSQLSERVER'.")

                { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When the system is not in the desired state' {
            It 'Should not throw when calling the alter method when desired recovery model should be set' {
                $mockExpectedRecoveryModel = 'Full'
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    RecoveryModel = 'Full'
                }

                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
            } 
        }

        Context 'When the system is not in the desired state' {
            It 'Should throw when calling the alter method when desired recovery model should be set' {
                $mockInvalidOperationForAlterMethod  = $true
                $mockExpectedRecoveryModel = 'Full'
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    RecoveryModel = 'Full'
                }

                $throwInvalidOperation = ('Exception calling "Alter" with "0" argument(s): ' + 
                                          '"Mock Alter Method was called with invalid operation."')

                { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
            } 
        }
        
        Assert-VerifiableMocks

        }
    }
}
finally
{
    Invoke-TestCleanup
}
