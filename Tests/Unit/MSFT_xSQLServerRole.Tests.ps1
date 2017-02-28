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
        $mockEnumMemberNames                    = @($mockSqlServerLoginOne,$mockSqlServerLoginTwo)
        $mockSqlServerLoginType                 = 'WindowsUser'
        $mockInvalidOperationForEnumMethod      = $false
        $mockInvalidOperationForCreateMethod    = $false
        $mockInvalidOperationForDropMethod      = $false
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
                                            throw 'Mock Create Method was called with invalid operation.'
                                        }
                            
                                        if ( $this.Name -ne $mockExpectedServerRoleToDrop )
                                        {
                                            throw "Called mocked drop() method without deleting the right server role. Expected '{0}'. But was '{1}'." `
                                                    -f $mockExpectedServerRoleToDrop, $this.Name
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
                            }
                        } -PassThru -Force                                       
                )
            )
        }

        $mockNewObjectServerRole = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlServerRoleName -PassThru |
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
                        ServerRole = 'UnknownUser'
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
                    $result.ServerRole | Should Be $testParameters.ServerRole
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }
    
            Context 'When the system is either in the desired state or not in the desired state' {
                It 'Should return the state as present' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        ServerRole = $mockSqlServerRole
                    }

                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
                }
                
                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.ServerRole | Should Be $testParameters.ServerRole
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
                        ServerRole = $mockSqlServerRole
                    }
                    
                    $throwInvalidOperation = ('Failed to enumerate members name of the server role ' + `
                                              'named AdminSqlforBI on localhost\MSSQLSERVER. InnerException: ' + `                                              'Exception calling "EnumMemberNames" with "0" argument(s): ' + `                                              '"Mock EnumMemberNames Method was called with invalid operation."')

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
                        ServerRole = $mockSqlServerRole
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
                        ServerRole = 'newServerRole'
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
                        ServerRole = 'newServerRole'
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
                        ServerRole = $mockSqlServerRole
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
                        ServerRole = $mockSqlServerRole
                        Members = $mockEnumMemberNames
                        MembersToInclude = $mockSqlServerLoginTree
                    }

                    $throwInvalidOperation = ('The parameter MembersToInclude and/or MembersToExclude ' + `                                              'must be null when Members parameter is set.')

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
                        ServerRole = $mockSqlServerRole
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
                        ServerRole = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginTree
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
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
                        ServerRole = $mockSqlServerRole
                        Members = $mockEnumMemberNames
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $throwInvalidOperation = ('The parameter MembersToInclude and/or MembersToExclude ' + `                                              'must be null when Members parameter is set.')

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
                        ServerRole = $mockSqlServerRole
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
                        ServerRole = $mockSqlServerRole
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
            }

            $mockSqlServerRole = 'ServerRoleToDrop'
            $mockExpectedServerRoleToDrop = 'ServerRoleToDrop'
            
            Context 'When the system is not in the desired state - ABSENT' {
                It 'Should not thrown when call drop method' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Absent'
                        ServerRole = $mockSqlServerRole
                    }
         
                    { Set-TargetResource @testParameters } | Should Not Throw

                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockSqlServerRole = 'AdminSqlforBI'

            Context 'When the system is not in the desired state - ABSENT' {
                It 'Should thrown the correct error when call drop method' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Absent'
                        ServerRole = $mockSqlServerRole
                    }
                                        $throwInvalidOperation = ('Failed to drop the server role named AdminSqlforBI on ' + `                                              'localhost\MSSQLSERVER. InnerException: Exception calling ' + `                                              '"Drop" with "0" argument(s): "Called mocked drop() method ' + `                                              'without deleting the right server role. Expected ' + `                                              "'ServerRoleToDrop'. But was 'AdminSqlforBI'.")
                    
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

