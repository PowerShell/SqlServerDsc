<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlDatabaseOwner DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlDatabaseOwner'

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
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

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
                        Add-Member -MemberType NoteProperty -Name NetName -Value $mockServerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name Collation -Value $mockSqlDatabaseCollation -PassThru |
                        Add-Member -MemberType ScriptMethod -Name EnumCollations -Value {
                        return @(
                            ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty Name -Value $mockSqlDatabaseCollation -PassThru
                            ),
                            ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty Name -Value 'SQL_Latin1_General_CP1_CS_AS' -PassThru
                            ),
                            ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty Name -Value 'SQL_Latin1_General_Pref_CP850_CI_AS' -PassThru
                            )
                        )
                    } -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name Databases -Value {
                        return @{
                            $mockSqlDatabaseName = ( New-Object -TypeName Object |
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

        Describe 'SqlDatabaseOwner\Export-TargetResource' {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

            # Mocking for protocol TCP
            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
                return $null
            } -Verifiable

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'Extract the existing configuration' {
                $result = Export-TargetResource


                It 'Should return content from the extraction' {
                    $result | Should -Not -Be $null
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
