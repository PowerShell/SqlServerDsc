$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerRole'

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
        $mockSqlServerRole                      = 'AdminSqlforBI'
        $mockSqlServerLoginOne                  = 'CONTOSO\John'
        $mockSqlServerLoginTwo                  = 'CONTOSO\Kelly'
        $mockSqlServerLoginTree                 = 'CONTOSO\Lucy'
        $mockSqlServerLoginFour                 = 'CONTOSO\Steve'
        $mockEnumMemberNames                    = @($mockSqlServerLoginOne,$mockSqlServerLoginTwo)
        $mockSqlServerLoginType                 = 'WindowsUser'
        $mockExpectedServerRoleToDrop           = 'ServerRoleToDrop'

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
                        Add-Member -MemberType ScriptProperty -Name Roles -Value {
                            return @{
                                $mockSqlServerRole = ( New-Object Object | 
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlServerRole -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name EnumMemberNames -Value {
                                        if ($mockInvalidOperationForEnumMethod)
                                        {
                                            throw 'Mock EnumMemberNames Method was called with invalid operation.'
                                        }
                                        else
                                        {
                                            $mockEnumMemberNames
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                        if ($mockInvalidOperationForDropMethod)
                                        {
                                            throw 'Mock Drop Method was called with invalid operation.'
                                        }
                            
                                        if ( $this.Name -ne $mockExpectedServerRoleToDrop )
                                        {
                                            throw "Called mocked drop() method without deleting the right server role. Expected '{0}'. But was '{1}'." `
                                                    -f $mockExpectedServerRoleToDrop, $this.Name
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                        if ($mockInvalidOperationForAddMemberMethod)
                                        {
                                            throw 'Mock AddMember Method was called with invalid operation.'
                                        }
                            
                                        if ( $mockSqlServerLoginToAdd -ne $mockExpectedMemberToAdd )
                                        {
                                            throw "Called mocked AddMember() method without adding the right login. Expected '{0}'. But was '{1}'." `
                                                    -f $mockExpectedMemberToAdd, $mockSqlServerLoginToAdd
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                        if ($mockInvalidOperationForDropMemberMethod)
                                        {
                                            throw 'Mock DropMember Method was called with invalid operation.'
                                        }
                            
                                        if ( $mockSqlServerLoginToDrop -ne $mockExpectedMemberToDrop )
                                        {
                                            throw "Called mocked DropMember() method without deleting the right login. Expected '{0}'. But was '{1}'." `
                                                    -f $mockExpectedMemberToDrop, $mockSqlServerLoginToDrop
                                        }
                                    } -PassThru
                                    )
                                }
                            } -PassThru | 
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
                                $mockSqlServerLoginTree = @((
                                    New-Object Object | 
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru 
                                ))
                                $mockSqlServerLoginFour = @((
                                    New-Object Object | 
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru 
                                ))
                            }
                        } -PassThru -Force                                       
                )
            )
        }

        $mockNewObjectServerRole = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlServerRoleAdd -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Create -Value {
                            if ($mockInvalidOperationForCreateMethod)
                            {
                                throw 'Mock Create Method was called with invalid operation.'
                            }
                            
                            if ( $this.Name -ne $mockExpectedServerRoleToCreate )
                            {
                                throw "Called mocked Create() method without adding the right server role. Expected '{0}'. But was '{1}'." `
                                        -f $mockExpectedServerRoleToCreate, $this.Name
                            }
                        } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "MSFT_xSQLServerRole\Get-TargetResource" -Tag 'Get'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is either in the desired state or not in the desired state' {
                It 'Should return the state as absent' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        ServerRoleName = 'UnknownUser'
                    }

                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the members as null' {
                    $result.Members | Should Be $null
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.ServerRoleName | Should Be $testParameters.ServerRoleName
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }
    
            Context 'When the system is either in the desired state or not in the desired state' {
                It 'Should return the state as present' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        ServerRoleName = $mockSqlServerRole
                    }

                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
                }
                
                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.ServerRoleName | Should Be $testParameters.ServerRoleName
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockInvalidOperationForEnumMethod = $true

            Context 'When passing values to parameters and throwing with EnumMemberNames method' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        ServerRoleName = $mockSqlServerRole
                    }
                    
                    $throwInvalidOperation = ('Failed to enumerate members name of the server role ' + `
                                              'named AdminSqlforBI on localhost\MSSQLSERVER. InnerException: ' + `
                                              'Exception calling "EnumMemberNames" with "0" argument(s): ' + `
                                              '"Mock EnumMemberNames Method was called with invalid operation."')

                    { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMocks
        }

        Describe "MSFT_xSQLServerRole\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            $mockInvalidOperationForEnumMethod = $false

            Context 'When the system is not in the desired state' {            
                It 'Should return the test as false when desired server role exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Absent'
                        ServerRoleName = $mockSqlServerRole
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {            
                It 'Should return the test as false when desired server role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = 'newServerRole'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure parameter is set to Present' {            
                It 'Should return the test as false when desired members are not in desired server role' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = @($mockSqlServerLoginTree,$mockSqlServerLoginFour)
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the system is in the desired state and ensure parameter is set to Absent' {            
                It 'Should return the test as true when desired server role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Absent'
                        ServerRoleName = 'newServerRole'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and ensure parameter is set to Present' {            
                It 'Should return the test as true when desired server role exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = $mockEnumMemberNames
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToInclude parameter is not null and Members parameter is set - PRESENT' {            
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = $mockEnumMemberNames
                        MembersToInclude = $mockSqlServerLoginTree
                    }

                    $throwInvalidOperation = ('The parameter MembersToInclude and/or MembersToExclude ' + `
                                              'must be null when Members parameter is set.')

                    { Test-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToInclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should return the test as true when desired server role exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginTwo
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToInclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should return the test as false when desired server role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginTree
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToExclude parameter is not null and Members parameter is set - PRESENT' {            
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = $mockEnumMemberNames
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $throwInvalidOperation = ('The parameter MembersToInclude and/or MembersToExclude ' + `
                                              'must be null when Members parameter is set.')

                    { Test-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToExclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should return the test as true when desired server roled does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginTree
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToExclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should return the test as false when desired server role exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Assert-VerifiableMocks
        }

        Describe "MSFT_xSQLServerRole\Set-TargetResource" -Tag 'Set'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectServerRole -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRoleName'
                } 
            }
           
            Context 'When the system is not in the desired state - ABSENT' {
                It 'Should not thrown when call drop method' {
                    $mockSqlServerRole = 'ServerRoleToDrop'
                    $mockExpectedServerRoleToDrop = 'ServerRoleToDrop'
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Absent'
                        ServerRoleName = $mockSqlServerRole
                    }
         
                    { Set-TargetResource @testParameters } | Should Not Throw

                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state - ABSENT' {
                It 'Should thrown the correct error when call drop method' {
                    $mockInvalidOperationForDropMethod = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Absent'
                        ServerRoleName = $mockSqlServerRole
                    }
                    
                    $throwInvalidOperation = ('Failed to drop the server role named AdminSqlforBI on ' + `
                                              'localhost\MSSQLSERVER. InnerException: Exception calling ' + `
                                              '"Drop" with "0" argument(s): "Mock Drop Method ' + `
                                              'was called with invalid operation."')
                    
                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state - PRESENT' {
                It 'Should not thrown when call create method' {
                    $mockSqlServerRoleAdd = 'ServerRoleToAdd'
                    $mockExpectedServerRoleToCreate = 'ServerRoleToAdd'
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRoleAdd
                    }
         
                    { Set-TargetResource @testParameters } | Should Not Throw

                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.ServerRoleName' {
                    Assert-MockCalled New-Object -Exactly -Times 1 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRoleName'
                    } -Scope Context
                }
            }

            Context 'When the system is not in the desired state - PRESENT' {
                It 'Should thrown the correct error when call create method' {
                    $mockSqlServerRoleAdd = 'ServerRoleToAdd'
                    $mockExpectedServerRoleToCreate = 'ServerRoleToAdd'
                    $mockInvalidOperationForCreateMethod = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRoleAdd
                    }
         
                    $throwInvalidOperation = ('Failed to create the server role named ServerRoleToAdd on ' + `
                                              'localhost\MSSQLSERVER. InnerException: Exception calling ' + `
                                              '"Create" with "0" argument(s): "Mock Create Method ' + `
                                              'was called with invalid operation."')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.ServerRoleName' {
                    Assert-MockCalled New-Object -Exactly -Times 1 -ParameterFilter { 
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRoleName'
                    } -Scope Context
                }
            }

            Context 'When the MembersToInclude parameter is not null and Members parameter is set - PRESENT' {            
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = $mockEnumMemberNames
                        MembersToInclude = $mockSqlServerLoginTree
                    }

                    $throwInvalidOperation = ('The parameter MembersToInclude and/or MembersToExclude ' + `
                                              'must be null when Members parameter is set.')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersExInclude parameter is not null and Members parameter is set - PRESENT' {            
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = $mockEnumMemberNames
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $throwInvalidOperation = ('The parameter MembersToInclude and/or MembersToExclude ' + `
                                              'must be null when Members parameter is set.')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToInclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should not thrown when call AddMember method' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginTree
                    $mockSqlServerLoginToAdd = $mockSqlServerLoginTree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginTree
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToInclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should thrown the correct error when call AddMember method' {
                    $mockInvalidOperationForAddMemberMethod = $true
                    $mockExpectedMemberToAdd = $mockSqlServerLoginTree
                    $mockSqlServerLoginToAdd = $mockSqlServerLoginTree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginTree
                    }

                    $throwInvalidOperation = ('Failed to add member CONTOSO\Lucy to the server role named AdminSqlforBI ' + `
                                              'on localhost\MSSQLSERVER. InnerException: Exception calling "AddMember" ' + `
                                              'with "1" argument(s): "Mock AddMember Method was called with invalid operation."')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToInclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should thrown the correct error when login does not exist' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginTree
                    $mockSqlServerLoginToAdd = $mockSqlServerLoginTree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToInclude = 'KingJulian'
                    }

                    $throwInvalidOperation = ("Login 'KingJulian' does not exist on SQL server 'localhost\MSSQLSERVER'.")

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToExclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should not thrown when call DropMember method' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginTwo
                    $mockSqlServerLoginToAdd = $mockSqlServerLoginTwo
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToExclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should thrown the correct error when call DropMember method' {
                    $mockInvalidOperationForDropMemberMethod = $true
                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
                    $mockSqlServerLoginToDrop = $mockSqlServerLoginTwo
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $throwInvalidOperation = ('Failed to drop member CONTOSO\Kelly to the server role named AdminSqlforBI ' + `
                                              'on localhost\MSSQLSERVER. InnerException: Exception calling "DropMember" ' + `
                                              'with "1" argument(s): "Mock DropMember Method was called with invalid operation."')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When the MembersToExclude parameter is not null and Members parameter is not set - PRESENT' {            
                It 'Should thrown the correct error when login does not exist' {
                    $mockEnumMemberNames = @('KingJulian',$mockSqlServerLoginOne,$mockSqlServerLoginTwo)
                    $mockExpectedMemberToAdd = $mockSqlServerLoginTree
                    $mockSqlServerLoginToAdd = $mockSqlServerLoginTree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        MembersToExclude = 'KingJulian'
                    }

                    $throwInvalidOperation = ("Login 'KingJulian' does not exist on SQL server 'localhost\MSSQLSERVER'.")

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When Members parameter is set and ensure parameter is set to Present' {            
                It 'Should thrown the correct error when login does not exist' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginTree
                    $mockSqlServerLoginToAdd = $mockSqlServerLoginTree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = @('KingJulian',$mockSqlServerLoginOne,$mockSqlServerLoginTree)
                    }

                    $throwInvalidOperation = ("Login 'KingJulian' does not exist on SQL server 'localhost\MSSQLSERVER'.")

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

            Context 'When Members parameter is set and ensure parameter is set to Present' {            
                It 'Should not thrown when call AddMember and DropMember methods' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginTree
                    $mockSqlServerLoginToAdd = $mockSqlServerLoginTree
                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
                    $mockSqlServerLoginToDrop = $mockSqlServerLoginTwo
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = @($mockSqlServerLoginOne,$mockSqlServerLoginTree)
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            
            }

                Context 'When Members parameter is set and ensure parameter is set to Present' {            
                It 'Should not thrown when call AddMember and DropMember methods' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginTree
                    $mockSqlServerLoginToAdd = $mockSqlServerLoginTree
                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
                    $mockSqlServerLoginToDrop = $mockSqlServerLoginTwo
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members = @($mockSqlServerLoginOne,$mockSqlServerLoginTree)
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
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

