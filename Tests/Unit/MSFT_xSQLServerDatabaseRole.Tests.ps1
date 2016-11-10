$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerDatabaseRole'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

# Begin Testing
try
{
    #region Pester Test Initialization

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

    $nodeName = 'localhost'
    $instanceName = 'MSSQLSERVER'
    $loginName = 'COMPANY\Stacy'
    $loginNameReturnsAbsent = 'John'
    $databaseName = 'MyDatabase'
    $roleName = 'MyRole'
    $secondRoleName = 'MySecondRole'

    $unknownLoginName = 'UnknownLogin'
    $unknownDatabaseName = 'UnknownDatabase'
    $unknownRoleName = 'UnknownRole'


    $defaultParameters = @{
        SQLInstanceName = $instanceName
        SQLServer = $nodeName
    }

    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Logins {
                    return @{
                        'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru ) )
                        'John' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru ) )
                    }
                } -PassThru | 
                Add-Member ScriptProperty Databases {
                    return @{
                        'MyDatabase' = @( ( New-Object Object |
                            Add-Member ScriptProperty Users {
                                return @{
                                    'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member ScriptMethod IsMember {
                                            return $true
                                        } -PassThru ) )
                                    'John' = @( ( New-Object Object |
                                        Add-Member ScriptMethod IsMember {
                                            param( 
                                                [String] $Role 
                                            )
                                            if( $Role -eq 'MySecondRole' ) {
                                                return $true
                                            } else {
                                                return $false
                                            }
                                        } -PassThru ) )                                }
                            } -PassThru | 
                            Add-Member ScriptProperty Roles {
                                return @{
                                    'MyRole' = @( ( New-Object Object ) )
                                    'MySecondRole' = @( ( New-Object Object ) )
                                }
                            } -PassThru ) ) 
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When passing values to parameters' {
            It 'Should throw when database name does not exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = $loginName
                    Database = $unknownDatabaseName
                    Role = $roleName
                }

                { Get-TargetResource @testParameters } | Should Throw

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should throw when role does not exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = $loginName
                    Database = $databaseName
                    Role = $unknownRoleName
                }

                { Get-TargetResource @testParameters } | Should Throw

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should not throw when adding two roles' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = $loginName
                    Database = $databaseName
                    Role = @( $roleName, $secondRoleName )
                }

                { Get-TargetResource @testParameters } | Should Not Throw

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should throw when login does not exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = $unknownLoginName
                    Database = $databaseName
                    Role = $roleName
                }

                { Get-TargetResource @testParameters } | Should Throw

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Context 'When the system is not in the desired state, with one role' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = $loginNameReturnsAbsent
                Database = $databaseName
                Role = $roleName
            }

            $result = Get-TargetResource @testParameters

            It 'Should return the state as absent' {
                $result.Ensure | Should Be 'Absent'
            }

            It 'Should not return any granted roles' {
                $result.Role | Should Be $null
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Database | Should Be $testParameters.Database
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Connect-SQL' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is not in the desired state, with two roles' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = $loginNameReturnsAbsent
                Database = $databaseName
                Role = @( $roleName, $secondRoleName )
            }

            $result = Get-TargetResource @testParameters

            It 'Should return the state as absent' {
                $result.Ensure | Should Be 'Absent'
            }

            It 'Should only return the one granted role' {
                $result.Role | Should Be $secondRoleName
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Database | Should Be $testParameters.Database
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Connect-SQL' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }
    
        Context 'When the system is in the desired state for a Windows user' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = $loginName
                Database = $databaseName
                Role = $roleName
            }

            $result = Get-TargetResource @testParameters

            It 'Should return the state as absent' {
                $result.Ensure | Should Be 'Present'
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Database | Should Be $testParameters.Database
                $result.Name | Should Be $testParameters.Name
                $result.Role | Should Be $testParameters.Role
            }

            It 'Should call the mock function Connect-SQL' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }        
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Logins {
                    return @{
                        'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru ) )
                        'John' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru ) )
                    }
                } -PassThru | 
                Add-Member ScriptProperty Databases {
                    return @{
                        'MyDatabase' = @( ( New-Object Object |
                            Add-Member ScriptProperty Users {
                                return @{
                                    'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member ScriptMethod IsMember {
                                            return $true
                                        } -PassThru ) )
                                    'John' = @( ( New-Object Object |
                                        Add-Member ScriptMethod IsMember {
                                            param( 
                                                [String] $Role 
                                            )
                                            if( $Role -eq 'MySecondRole' ) {
                                                return $true
                                            } else {
                                                return $false
                                            }
                                        } -PassThru ) )                                }
                            } -PassThru | 
                            Add-Member ScriptProperty Roles {
                                return @{
                                    'MyRole' = @( ( New-Object Object ) )
                                    'MySecondRole' = @( ( New-Object Object ) )
                                }
                            } -PassThru ) ) 
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {
            It 'Should return that desired state as absent when adding one role' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = $loginNameReturnsAbsent
                    Database = $databaseName
                    Role = $roleName
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $false

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should return that desired state as absent when adding two roles' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = $loginNameReturnsAbsent
                    Database = $databaseName
                    Role = @( $roleName, $secondRoleName )
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $false

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Context 'When the system is in the desired state' {
            It 'Should return that desired state as present when adding one role' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = $loginName
                    Database = $databaseName
                    Role = $roleName
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should return that desired state as present when adding two roles' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = $loginName
                    Database = $databaseName
                    Role = @( $roleName, $secondRoleName )
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Logins {
                    return @{
                        'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru ) )
                        'John' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru ) )
                    }
                } -PassThru | 
                Add-Member ScriptProperty Databases {
                    return @{
                        'MyDatabase' = @( ( New-Object Object |
                            Add-Member ScriptProperty Users {
                                return @{
                                    'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member ScriptMethod IsMember {
                                            return $true
                                        } -PassThru ) )
                                    'John' = @( ( New-Object Object |
                                        Add-Member ScriptMethod IsMember {
                                            param( 
                                                [String] $Role 
                                            )
                                            if( $Role -eq 'MySecondRole' ) {
                                                return $true
                                            } else {
                                                return $false
                                            }
                                        } -PassThru ) )                                }
                            } -PassThru | 
                            Add-Member ScriptProperty Roles {
                                return @{
                                    'MyRole' = @( ( New-Object Object |
                                        Add-Member ScriptMethod AddMember {
                                            param(
                                                [String] $Name
                                            )
                                        } -PassThru ) )
                                    'MySecondRole' = @( ( New-Object Object |
                                        Add-Member ScriptMethod AddMember {
                                            param(
                                                [String] $Name
                                            )
                                        } -PassThru ) )
                                }
                            } -PassThru ) ) 
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = $loginName
                Database = $databaseName
                Role = $roleName
            }

            It 'Should not throw when login is not member of the group' {
                { Set-TargetResource @testParameters } | Should Not Throw

                Assert-MockCalled Connect-SQL -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Context 'When the system is in the desired state' {
            # Mock the return value from the Get-method, because Test-method is ran at the end of the Set-method to validate that the Set (in this case) was successful.
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    Ensure = 'Present'
                }
            } -ModuleName $script:DSCResourceName -Verifiable

            $testParameters = $defaultParameters
            $testParameters += @{
                Name = $loginNameReturnsAbsent
                Database = $databaseName
                Role = $roleName
            }

            It 'Should not throw when login is already member of the group' {
                { Set-TargetResource @testParameters } | Should Not Throw

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Assert-VerifiableMocks
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment 

    #endregion
}
