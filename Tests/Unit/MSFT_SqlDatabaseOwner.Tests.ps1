$script:DSCModuleName      = 'SqlServerDsc'
$script:DSCResourceName    = 'MSFT_SqlDatabaseOwner'

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
        $mockSqlServerName                      = 'localhost'
        $mockSqlServerInstanceName              = 'MSSQLSERVER'
        $mockSqlDatabaseName                    = 'AdventureWorks'
        $mockSqlServerLogin                     = 'Zebes\SamusAran'
        $mockSqlServerLoginType                 = 'WindowsUser'
        $mockDatabaseOwner                      = 'Elysia\Chozo'
        $mockInvalidOperationForSetOwnerMethod  = $false
        $mockExpectedDatabaseOwner              = 'Elysia\Chozo'

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
                                $mockSqlDatabaseName = @((
                                    New-Object Object |
                                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                                        Add-Member -MemberType NoteProperty -Name Owner -Value $mockDatabaseOwner -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name SetOwner -Value {
                                            if ($mockInvalidOperationForSetOwnerMethod)
                                            {
                                                throw 'Mock of method SetOwner() was called with invalid operation.'
                                            }

                                            if ( $this.Owner -ne $mockExpectedDatabaseOwner )
                                            {
                                                throw "Called mocked SetOwner() method without setting the right login. Expected '{0}'. But was '{1}'." `
                                                        -f $mockExpectedDatabaseOwner, $this.Owner
                                            }
                                        } -PassThru -Force
                                    ))
                                }
                            } -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name Logins -Value {
                            return @{
                                $mockSqlServerLogin = @((
                                    New-Object Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                            }
                        } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "MSFT_SqlDatabaseOwner\Get-TargetResource" -Tag 'Get'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When passing values to parameters and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = 'unknownDatabaseName'
                        Name        = $mockSqlServerLogin
                    }

                    $throwInvalidOperation = ("Database 'unknownDatabaseName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Get-TargetResource @testParameters } | Should -Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is either in the desired state or not in the desired state' {
                It 'Should not throw' {
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockSqlServerLogin
                    }

                    $result = Get-TargetResource @testParameters
                }

                It 'Should return the name of the owner from the get method' {
                    $result.Name | Should -Be $testParameters.Name
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should -Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should -Be $testParameters.SQLInstanceName
                    $result.Database | Should -Be $testParameters.Database
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlDatabaseOwner\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should return the state as false when desired login is not the database owner' {
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockSqlServerLogin
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return the state as true when desired login is the database owner' {
                    $mockDatabaseOwner = 'Zebes\SamusAran'
                    $mockSqlServerLogin = 'Zebes\SamusAran'
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockSqlServerLogin
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

        Describe "MSFT_SqlDatabaseOwner\Set-TargetResource" -Tag 'Set'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = 'unknownDatabaseName'
                        Name        = $mockSqlServerLogin
                    }

                    $throwInvalidOperation = ("Database 'unknownDatabaseName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and login name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = 'John'
                    }

                    $throwInvalidOperation = ("Login 'John' does not exist on " + `
                                              "SQL server 'localhost\MSSQLSERVER'.")

                    { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should not throw' {
                    $mockExpectedDatabaseOwner = $mockSqlServerLogin
                    $mockDatabaseOwner = $mockSqlServerLogin
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockSqlServerLogin
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should throw the correct error when the method SetOwner() set the wrong login' {
                    $mockExpectedDatabaseOwner = $mockSqlServerLogin
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockSqlServerLogin
                    }

                    $throwInvalidOperation = ('Failed to set owner named Zebes\SamusAran of the database ' + `
                                              'named AdventureWorks on localhost\MSSQLSERVER. InnerException: ' + `
                                              'Exception calling "SetOwner" with "1" argument(s): "Called mocked ' + `
                                              'SetOwner() method without setting the right login. ' + `
                                              "Expected 'Zebes\SamusAran'. But was 'Elysia\Chozo'.")

                    { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should throw the correct error when the method SetOwner() was called' {
                    $mockInvalidOperationForSetOwnerMethod  = $true
                    $mockExpectedDatabaseOwner = $mockSqlServerLogin
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockSqlServerLogin
                    }

                    $throwInvalidOperation = ('Failed to set owner named Zebes\SamusAran of the database ' + `
                                              'named AdventureWorks on localhost\MSSQLSERVER. InnerException: ' + `
                                              'Exception calling "SetOwner" with "1" argument(s): "Mock ' + `
                                              'of method SetOwner() was called with invalid operation.')

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
