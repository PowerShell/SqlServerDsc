$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerDatabaseRole'

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
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockSqlServerName                          = 'localhost'
        $mockSqlServerInstanceName                  = 'MSSQLSERVER'
        $mockSqlDatabaseName                        = 'AdventureWorks'
        $mockSqlServerLogin                         = 'John'
        $mockSqlServerLoginOne                      = 'CONTOSO\KingJulian'
        $mockSqlServerLoginTwo                      = 'CONTOSO\SQLAdmin'
        $mockSqlServerLoginType                     = 'WindowsUser'
        $mockSqlDatabaseRole                        = 'MyRole'
        $mockSqlDatabaseRoleSecond                  = 'MySecondRole'
        $mockExpectedSqlDatabaseRole                = 'MyRole'
        $mockInvalidOperationForAddMemberMethod     = $false
        $mockInvalidOperationForDropMemberMethod    = $false
        $mockInvalidOperationForCreateMethod        = $false
        $mockExpectedForAddMemberMethod             = 'MySecondRole'
        $mockExpectedForDropMemberMethod            = 'MyRole'
        $mockExpectedForCreateMethod                = 'John'
        
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
                                        Add-Member -MemberType ScriptProperty -Name Users -Value {
                                            return @{
                                                $mockSqlServerLoginOne = @(( 
                                                    New-Object Object |
                                                        Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                            param( 
                                                                [String]
                                                                $mockSqlDatabaseRole 
                                                            )
                                                            if ( $mockSqlDatabaseRole -eq $mockExpectedSqlDatabaseRole ) 
                                                            {
                                                                return $true
                                                            } 
                                                            else
                                                            {
                                                                return $false
                                                            }
                                                        } -PassThru 
                                                ))
                                                $mockSqlServerLoginTwo = @(( 
                                                    New-Object Object |
                                                        Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                                return $true
                                                        } -PassThru 
                                                ))
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType ScriptProperty -Name Roles -Value {
                                            return @{
                                                $mockSqlDatabaseRole = @((
                                                    New-Object Object |
                                                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseRole -PassThru |
                                                        Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                                            param(
                                                                [String]
                                                                $mockSqlServerLogin
                                                            )
                                                            if ($mockInvalidOperationForAddMemberMethod)
                                                            {
                                                                throw 'Mock AddMember Method was called with invalid operation.'
                                                            }
                                                            if ( $this.Name -ne $mockExpectedForAddMemberMethod )
                                                            {
                                                                throw "Called mocked AddMember() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                        -f $mockExpectedForAddMemberMethod, $this.Name
                                                            }
                                                        } -PassThru |
                                                        Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                                            param(
                                                                [String]
                                                                $mockSqlServerLogin
                                                            )
                                                            if ($mockInvalidOperationForDropMemberMethod)
                                                            {
                                                                throw 'Mock DropMember Method was called with invalid operation.'
                                                            }
                                                            if ( $this.Name -ne $mockExpectedForDropMemberMethod )
                                                            {
                                                                throw "Called mocked Drop() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                        -f $mockExpectedForDropMemberMethod, $this.Name
                                                            }
                                                        } -PassThru
                                                ))
                                                $mockSqlDatabaseRoleSecond = @((
                                                    New-Object Object |
                                                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseRoleSecond -PassThru |
                                                        Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                                            param(
                                                                [String]
                                                                $mockSqlServerLogin
                                                            )
                                                            if ($mockInvalidOperationForAddMemberMethod)
                                                            {
                                                                throw 'Mock AddMember Method was called with invalid operation.'
                                                            }
                                                            if ( $this.Name -ne $mockExpectedForAddMemberMethod )
                                                            {
                                                                throw "Called mocked AddMember() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                        -f $mockExpectedForAddMemberMethod, $this.Name
                                                            }
                                                        } -PassThru |
                                                        Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                                            param(
                                                                [String]
                                                                $mockSqlServerLogin
                                                            )
                                                            if ($mockInvalidOperationForDropMemberMethod)
                                                            {
                                                                throw 'Mock DropMember Method was called with invalid operation.'
                                                            }
                                                            if ( $this.Name -ne $mockExpectedForDropMemberMethod )
                                                            {
                                                                throw "Called mocked Drop() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                        -f $mockExpectedForDropMemberMethod, $this.Name
                                                            }
                                                        } -PassThru
                                                ))
                                            }
                                        }-PassThru -Force
                                    ))
                                }
                            } -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name Logins -Value {
                            return @{
                                $mockSqlServerLoginOne = @((
                                    New-Object Object | 
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru 
                                ))
                                $mockSqlServerLoginTwo = @((
                                    New-Object Object | 
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru 
                                ))
                                $mockSqlServerLogin = @((
                                    New-Object Object | 
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru 
                                ))
                            }
                        } -PassThru -Force 
                                       
                )
            )
        }

        $mockNewObjectUser = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlServerLogin -PassThru |
                        Add-Member -MemberType NoteProperty -Name Login -Value $mockSqlServerLogin -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Create -Value {
                            if ($mockInvalidOperationForCreateMethod)
                            {
                                throw 'Mock Create Method was called with invalid operation.'
                            }
                            if ( $this.Name -ne $mockExpectedForCreateMethod )
                            {
                                throw "Called mocked Create() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                        -f $mockExpectedForCreateMethod, $this.Name
                            }
                        } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "MSFT_xSQLServerDatabaseRole\Get-TargetResource" -Tag 'Get'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When passing values to parameters and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = 'unknownDatabaseName'
                        Role        = $mockSqlDatabaseRole
                    }

                    $throwInvalidOperation = ("Database 'unknownDatabaseName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When passing values to parameters and role does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = 'unknownRoleName'
                    }

                     $throwInvalidOperation = ("Role 'unknownRoleName' does not exist on database " + `
                                               "'AdventureWorks' on SQL server 'localhost\MSSQLSERVER'.")

                    { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When passing values to parameters and multiple values to Role parameter' {
                It 'Should not throw' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = @($mockSqlDatabaseRole,$mockSqlDatabaseRoleSecond)
                    }

                    { Get-TargetResource @testParameters } | Should Not Throw 
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When passing values to parameters and login does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = 'unknownLoginName'
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRole
                    }

                    $throwInvalidOperation = ("Login 'unknownLoginName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state, with one role' {
                It 'Should return the state as absent' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRoleSecond
                    }

                    $result = Get-TargetResource @testParameters                
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
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state, with two roles' {
                It 'Should return the state as absent' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = @($mockSqlDatabaseRole,$mockSqlDatabaseRoleSecond)
                    }

                    $result = Get-TargetResource @testParameters                
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
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }
        
            Context 'When the system is not in the desired state, and login is not a member of the database' {
                It 'Should return the state as absent' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLogin
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRole
                    }

                    $result = Get-TargetResource @testParameters                
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Database | Should Be $testParameters.Database
                    $result.Name | Should Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state for a Windows user' {
                It 'Should return the state as absent' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRole
                    }

                    $result = Get-TargetResource @testParameters               
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
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }        
            }

            Assert-VerifiableMocks
        }

        Describe "MSFT_xSQLServerDatabaseRole\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when one desired role is not configured' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRoleSecond
                        Ensure      = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when two desired roles are not configured' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = @($mockSqlDatabaseRole,$mockSqlDatabaseRoleSecond)
                        Ensure      = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should return the state as false when undesired roles are not configured' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginTwo
                        Database    = $mockSqlDatabaseName
                        Role        = @($mockSqlDatabaseRole,$mockSqlDatabaseRoleSecond)
                        Ensure      = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Present' {
                It 'Should return the state as true when one desired role is correctly configured' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRole
                        Ensure      = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Present' {
                It 'Should return the state as true when two desired role are correctly configured' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginTwo
                        Database    = $mockSqlDatabaseName
                        Role        = @($mockSqlDatabaseRole,$mockSqlDatabaseRoleSecond)
                        Ensure      = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                It 'Should return the state as true when two desired role are correctly configured' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginOne
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRoleSecond
                        Ensure      = 'Absent'
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

        Describe "MSFT_xSQLServerDatabaseRole\Set-TargetResource" -Tag 'Set'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectUser -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.User'
                } -Verifiable
            }

            $mockExpectedForAddMemberMethod    = 'MyRole'

            Context 'When the system is not in the desired state, Ensure is set to Present and Login does not exist' {
                It 'Should Not Throw when Ensure parameter is set to Present' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLogin
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRole
                        Ensure      = 'Present'
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.User' {
                    Assert-MockCalled New-Object -Exactly -Times 1 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.User'
                    } -Scope Context
                }
            }

            $mockInvalidOperationForCreateMethod = $true

            Context 'When the system is not in the desired state, Ensure is set to Present and Login does not exist' {
                It 'Should Throw the correct error when Ensure parameter is set to Present' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLogin
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRoleSecond
                        Ensure      = 'Present'
                    }

                    $throwInvalidOperation = ('Failed adding the login John as a user of the database AdventureWorks, on ' + `
                                              'the instance localhost\MSSQLSERVER. InnerException: Exception calling "Create" ' + `
                                              'with "0" argument(s): "Mock Create Method was called with invalid operation."')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.User' {
                    Assert-MockCalled New-Object -Exactly -Times 1 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.User'
                    } -Scope Context
                }
            }

            $mockExpectedForAddMemberMethod    = 'MySecondRole'
            $mockSqlServerLogin = $mockSqlServerLoginOne

            Context 'When the system is not in the desired state, Ensure is set to Present and Login already exist' {
                It 'Should Not Throw when Ensure parameter is set to Present' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLogin
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRoleSecond
                        Ensure      = 'Present'
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.User' {
                    Assert-MockCalled New-Object -Exactly -Times 0 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.User'
                    } -Scope Context
                }
            }

            $mockInvalidOperationForAddMemberMethod = $true

            Context 'When the system is not in the desired state, Ensure is set to Present and Login already exist' {
                It 'Should Throw the correct error when Ensure parameter is set to Present' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLogin
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRoleSecond
                        Ensure      = 'Present'
                    }

                    $throwInvalidOperation = ('Failed adding the login CONTOSO\KingJulian to the role MySecondRole on ' + `
                                              'the database AdventureWorks, on the instance localhost\MSSQLSERVER. ' + `
                                              'InnerException: Exception calling "AddMember" with "1" argument(s): ' + `
                                              '"Mock AddMember Method was called with invalid operation."')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.User' {
                    Assert-MockCalled New-Object -Exactly -Times 0 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.User'
                    } -Scope Context
                }
            }

            Context 'When the system is not in the desired state, Ensure is set to Absent' {
                It 'Should not throw the correct error when Ensure parameter is set to Absent' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginTwo
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRole
                        Ensure      = 'Absent'
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.User' {
                    Assert-MockCalled New-Object -Exactly -Times 0 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.User'
                    } -Scope Context
                }
            }

            $mockInvalidOperationForDropMemberMethod = $true

            Context 'When the system is not in the desired state, Ensure is set to Absent' {
                It 'Should not throw the correct error when Ensure parameter is set to Absent' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name        = $mockSqlServerLoginTwo
                        Database    = $mockSqlDatabaseName
                        Role        = $mockSqlDatabaseRole
                        Ensure      = 'Absent'
                    }

                    $throwInvalidOperation = ('Failed removing the login CONTOSO\SQLAdmin from the role MyRole on ' + `
                                              'the database AdventureWorks, on the instance localhost\MSSQLSERVER. ' + `
                                              'InnerException: Exception calling "DropMember" with "1" argument(s): ' + `
                                              '"Mock DropMember Method was called with invalid operation."')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.User' {
                    Assert-MockCalled New-Object -Exactly -Times 0 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.User'
                    } -Scope Context
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
