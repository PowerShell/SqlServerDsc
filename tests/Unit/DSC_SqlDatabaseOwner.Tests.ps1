<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlDatabaseOwner DSC resource.

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
$script:dscResourceName = 'MSFT_SqlDatabaseOwner'

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
        $mockSqlServerLogin = 'Zebes\SamusAran'
        $mockSqlServerLoginType = 'WindowsUser'
        $mockDatabaseOwner = 'Elysia\Chozo'
        $mockInvalidOperationForSetOwnerMethod = $false
        $mockExpectedDatabaseOwner = 'Elysia\Chozo'

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
                            $mockSqlDatabaseName = @((
                                    New-Object -TypeName Object |
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
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                        }
                    } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "MSFT_SqlDatabaseOwner\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When passing values to parameters and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = 'unknownDatabaseName'
                        Name     = $mockSqlServerLogin
                    }

                    $errorMessage = $script:localizedData.DatabaseNotFound -f $testParameters.Database

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is either in the desired state or not in the desired state' {
                It 'Should not throw' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = $mockSqlDatabaseName
                        Name     = $mockSqlServerLogin
                    }

                    $result = Get-TargetResource @testParameters
                }

                It 'Should return the name of the owner from the get method' {
                    $result.Name | Should -Be $testParameters.Name
                }

                It 'Should return the same values as passed as parameters' {
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Database | Should -Be $testParameters.Database
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the Connect-Sql fails with an error' {
                BeforeEach {
                    Mock -CommandName Connect-Sql -MockWith {
                        throw 'mocked error'
                    }
                }

                It 'Should throw the correct error when the method SetOwner() set the wrong login' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = $mockSqlDatabaseName
                        Name     = $mockSqlServerLogin
                    }

                    $errorMessage = $script:localizedData.FailedToGetOwnerDatabase -f $testParameters.Database

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }
            }


            Assert-VerifiableMock
        }

        Describe "MSFT_SqlDatabaseOwner\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should return the state as false when desired login is not the database owner' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = $mockSqlDatabaseName
                        Name     = $mockSqlServerLogin
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return the state as true when desired login is the database owner' {
                    $mockDatabaseOwner = 'Zebes\SamusAran'
                    $mockSqlServerLogin = 'Zebes\SamusAran'
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = $mockSqlDatabaseName
                        Name     = $mockSqlServerLogin
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

        Describe "MSFT_SqlDatabaseOwner\Set-TargetResource" -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = 'unknownDatabaseName'
                        Name     = $mockSqlServerLogin
                    }


                    $errorMessage = $script:localizedData.DatabaseNotFound -f $testParameters.Database

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and login name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = $mockSqlDatabaseName
                        Name     = 'John'
                    }

                    $errorMessage = $script:localizedData.LoginNotFound -f $testParameters.Name

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should not throw' {
                    $mockExpectedDatabaseOwner = $mockSqlServerLogin
                    $mockDatabaseOwner = $mockSqlServerLogin
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = $mockSqlDatabaseName
                        Name     = $mockSqlServerLogin
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should throw the correct error when the method SetOwner() set the wrong login' {
                    $mockExpectedDatabaseOwner = $mockSqlServerLogin
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = $mockSqlDatabaseName
                        Name     = $mockSqlServerLogin
                    }

                    $errorMessage = $script:localizedData.FailedToSetOwnerDatabase -f $testParameters.Database

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should throw the correct error when the method SetOwner() was called' {
                    $mockInvalidOperationForSetOwnerMethod = $true
                    $mockExpectedDatabaseOwner = $mockSqlServerLogin
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database = $mockSqlDatabaseName
                        Name     = $mockSqlServerLogin
                    }

                    $errorMessage = $script:localizedData.FailedToSetOwnerDatabase -f $testParameters.Database

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
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
