$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerDatabase'

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
    # Loading mocked classes
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
        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod   = $false
        $mockExpectedDatabaseNameToCreate    = 'Contoso'
        $mockExpectedDatabaseNameToDrop      = 'Sales'

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
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                        if ($mockInvalidOperationForDropMethod)
                                        {
                                            throw 'Mock Drop Method was called with invalid operation.'
                                        }
                                        
                                        if ( $this.Name -ne $mockExpectedDatabaseNameToDrop )
                                        {
                                            throw "Called mocked Drop() method without dropping the right database. Expected '{0}'. But was '{1}'." `
                                                  -f $mockExpectedDatabaseNameToDrop, $this.Name
                                        }
                                    } -PassThru
                                    )
                                }
                            } -PassThru -Force                                        
                )
            )
        }

        $mockNewObjectDatabase = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Create -Value {
                            if ($mockInvalidOperationForCreateMethod)
                            {
                                throw 'Mock Create Method was called with invalid operation.'
                            }
                            
                            if ( $this.Name -ne $mockExpectedDatabaseNameToCreate )
                            {
                                throw "Called mocked Create() method without adding the right database. Expected '{0}'. But was '{1}'." `
                                        -f $mockExpectedDatabaseNameToCreate, $this.Name
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

            Context 'When the system is not in the desired state' {
                It 'Should return the state as absent' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name = 'UnknownDatabase'
                    }

                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Absent'
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
                It 'Should return the state as present' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name = 'AdventureWorks'
                    }

                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
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

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when desired database does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'UnknownDatabase'
                        Ensure  = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should return the state as false when non-desired database exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'AdventureWorks'
                        Ensure  = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Present' {
                It 'Should return the state as true when desired database exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'AdventureWorks'
                        Ensure  = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                It 'Should return the state as true when desired database does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'UnknownDatabase'
                        Ensure  = 'Absent'
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
                Mock -CommandName New-Object -MockWith $mockNewObjectDatabase -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                } -Verifiable
            }

            $mockSqlDatabaseName                = 'Contoso'
            $mockExpectedDatabaseNameToCreate   = 'Contoso'

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should not throw when creating the database' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'NewDatabase'
                        Ensure  = 'Present'
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Database' {
                    Assert-MockCalled New-Object -Exactly -Times 1 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                    } -Scope Context
                }
            }

            $mockExpectedDatabaseNameToDrop = 'Sales'
            $mockSqlDatabaseName            = 'Sales'

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should not throw when dropping the database' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'Sales'
                        Ensure  = 'Absent'
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockInvalidOperationForCreateMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should throw the correct error when Create() method was called with invalid operation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'NewDatabase'
                        Ensure  = 'Present'
                    }
                    
                    $throwInvalidOperation = ('InnerException: Exception calling "Create" ' + `
                                              'with "0" argument(s): "Mock Create Method was called with invalid operation."')
                    
                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation 
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Database' {
                    Assert-MockCalled New-Object -Exactly -Times 1 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                    } -Scope Context
                }
            }

            $mockSqlDatabaseName = 'AdventureWorks'
            $mockInvalidOperationForDropMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name    = 'AdventureWorks'
                    Ensure  = 'Absent'
                }
                
                It 'Should throw the correct error when Drop() method was called with invalid operation' {
                    $throwInvalidOperation = ('InnerException: Exception calling "Drop" ' + `
                                              'with "0" argument(s): "Mock Drop Method was called with invalid operation."')
                    
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
