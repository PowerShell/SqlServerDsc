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
        $mockSqlDatabaseCollation            = 'SQL_Latin1_General_CP1_CI_AS'

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
                        Add-Member -MemberType NoteProperty -Name Collation -Value $mockSqlDatabaseCollation -PassThru |
                        Add-Member -MemberType ScriptMethod -Name EnumCollations -Value {
                            return @(
                                ( New-Object Object |
                                    Add-Member -MemberType NoteProperty Name -Value $mockSqlDatabaseCollation -PassThru
                                ),
                                ( New-Object Object |
                                    Add-Member -MemberType NoteProperty Name -Value 'SQL_Latin1_General_CP1_CS_AS' -PassThru
                                ),
                                ( New-Object Object |
                                    Add-Member -MemberType NoteProperty Name -Value 'SQL_Latin1_General_Pref_CP850_CI_AS' -PassThru
                                )
                            )
                        } -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name Databases -Value {
                            return @{
                                    $mockSqlDatabaseName = ( New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                                    Add-Member -MemberType NoteProperty -Name Collation -Value $mockSqlDatabaseCollation -PassThru |
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
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                        if ($mockInvalidOperationForAlterMethod)
                                        {
                                            throw 'Mock Alter Method was called with invalid operation.'
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
                        Add-Member -MemberType NoteProperty -Name Collation -Value '' -PassThru |
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
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'UnknownDatabase'
                    Collation = 'SQL_Latin1_General_CP1_CI_AS'
                }

                It 'Should return the state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                    $result.Collation | Should Be $testParameters.Collation
                }


                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is in the desired state for a database' {

                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    Collation = 'SQL_Latin1_General_CP1_CI_AS'
                }

                It 'Should return the state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                    $result.Collation | Should Be $testParameters.Collation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Assert-VerifiableMock
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
                        Collation = 'SQL_Latin1_General_CP1_CS_AS'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should return the state as false when desired database exists but is the incorrect collation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'AdventureWorks'
                        Ensure  = 'Present'
                        Collation = 'SQL_Latin1_General_CP1_CS_AS'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
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
                        Collation = 'SQL_Latin1_General_CP1_CI_AS'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should return the state as true when desired database exists and is correct collation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'AdventureWorks'
                        Ensure  = 'Present'
                        Collation = 'SQL_Latin1_General_CP1_CI_AS'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
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

            Assert-VerifiableMock
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

                It 'Should not throw when changing the database collation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'AdventureWorks'
                        Ensure  = 'Present'
                        Collation = 'SQL_Latin1_General_CP1_CS_AS'
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Database' {
                    Assert-MockCalled New-Object -Exactly -Times 2 -ParameterFilter {
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
            $mockInvalidOperationForAlterMethod  = $true

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

                It 'Should throw the correct error when invalid collation is specified' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name    = 'NewDatabase'
                        Ensure  = 'Present'
                        Collation = 'InvalidCollation'
                    }

                    $throwInvalidOperation = ('Collation specified {3} is not a valid collation for database {2} on {0}\{1}.' -f $mockSqlServerName, $mockSqlServerInstanceName, $testParameters.Name, $testParameters.Collation)

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope Context
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
                    Collation = 'SQL_Latin1_General_CP1_CS_AS'
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

            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}
