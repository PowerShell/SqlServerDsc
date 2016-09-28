$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerDatabasePermissions'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment -DSCModuleName $script:DSCModuleName `
                                              -DSCResourceName $script:DSCResourceName `
                                              -TestType Unit 
#endregion HEADER

# Begin Testing
try
{
    #region Pester Test Initialization
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

    $defaultParameters = @{
        SQLInstanceName = 'MSSQLSERVER'
        SQLServer = 'localhost'
        Database = 'AdventureWorks'
        Name = 'CONTOSO\SqlServiceAcct'
    }

    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Databases {
                    return @{
                        'AdventureWorks' = @( ( New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, 'AdventureWorks') ) )
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {
            $testParameters = $defaultParameters
            $testParameters += @{
                PermissionState = 'Grant'
                Permissions = @( 'Connect','Update' )
                Ensure = 'Present'
            }

            Mock -CommandName Get-SqlDatabasePermission -MockWith { 
                return $null
            } -ModuleName $script:DSCResourceName -Verifiable

            $result = Get-TargetResource @testParameters

            It 'Should return the state as absent' {
                $result.Ensure | Should Be 'Absent'
                $result.Permissions | Should Be $null
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
                $result.PermissionState | Should Be $testParameters.PermissionState
            }

            It 'Should call the mock functions Connect-SQL and Get-SqlDatabasePermission' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                 Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }
    
        Context 'When the system is in the desired state for PermissionState equal to Grant' {
            $testParameters = $defaultParameters
            $testParameters += @{
                PermissionState = 'Grant'
                Permissions = @( 'Connect','Update' )
                Ensure = 'Present'
            }

            Mock -CommandName Get-SqlDatabasePermission -MockWith { return @( 'Connect','Update' ) } -ModuleName $script:DSCResourceName -Verifiable

            $result = Get-TargetResource @testParameters

            It 'Should return the state as present' {
                $result.Ensure | Should Be 'Present'
                $result.Permissions | Should Be $testParameters.Permissions
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
                $result.PermissionState | Should Be $testParameters.PermissionState
            }

            It 'Should call the mock functions Connect-SQL and Get-SqlDatabasePermission' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                 Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is in the desired state for PermissionState equal to Deny' {
            $testParameters = $defaultParameters
            $testParameters += @{
                PermissionState = 'Deny'
                Permissions = @( 'Connect','Update' )
                Ensure = 'Present'
            }

            Mock -CommandName Get-SqlDatabasePermission -MockWith { return @( 'Connect','Update' ) } -ModuleName $script:DSCResourceName -Verifiable

            $result = Get-TargetResource @testParameters

            It 'Should return the state as present' {
                $result.Ensure | Should Be 'Present'
                $result.Permissions | Should Be $testParameters.Permissions
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
                $result.PermissionState | Should Be $testParameters.PermissionState
            }

            It 'Should call the mock functions Connect-SQL and Get-SqlDatabasePermission' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                 Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Databases {
                    return @{
                        'AdventureWorks' = @( ( New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, 'AdventureWorks') ) )
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {

            It 'Should return the state as false when desired permissions does not exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    PermissionState = 'Grant'
                    Permissions = @( 'Connect','Update' )
                    Ensure = 'Present'
                }              

                Mock -CommandName Get-SqlDatabasePermission -MockWith { 
                    return $null
                } -ModuleName $script:DSCResourceName -Verifiable

                $result = Test-TargetResource @testParameters
                $result | Should Be $false

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is in the desired state' {
            It 'Should return the state as true when desired permissions exist for PermissionState equal to Grant' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    PermissionState = 'Grant'
                    Permissions = @( 'Connect','Update' )
                    Ensure = 'Present'
                }

                Mock -CommandName Get-SqlDatabasePermission -MockWith { 
                    @( 'Connect','Update') 
                } -ModuleName $script:DSCResourceName -Verifiable

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
            
            It 'Should return the state as true when desired permissions exist for PermissionState equal to Deny' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    PermissionState = 'Deny'
                    Permissions = @( 'Connect','Update' )
                    Ensure = 'Present'
                }

                Mock -CommandName Get-SqlDatabasePermission -MockWith { 
                    @( 'Connect','Update') 
                } -ModuleName $script:DSCResourceName -Verifiable

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Databases {
                    return @{
                        'AdventureWorks' = @( ( New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, 'AdventureWorks') ) )
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {
            $testParameters = $defaultParameters
            $testParameters += @{
                PermissionState = 'Grant'
                Ensure = 'Present'
                Permissions = @( 'Connect','Update' )
            }

            It 'Should throw an error when desired database does not exist' {
                Mock -CommandName Add-SqlDatabasePermission -MockWith {
                    return Throw
                } -ModuleName $script:DSCResourceName -Verifiable
                
                { Set-TargetResource @testParameters } | Should Throw
                
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Add-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should throw an error when desired login does not exist' {
                Mock -CommandName Add-SqlDatabasePermission -MockWith {
                    return Throw
                } -ModuleName $script:DSCResourceName -Verifiable
                
                { Set-TargetResource @testParameters } | Should Throw
                
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Add-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Granting - Should call the function Add-SqlDatabasePermission when desired state is already present' {
                Mock -CommandName Add-SqlDatabasePermission -MockWith { } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @testParameters
               
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Add-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters.Ensure = 'Absent'

            It 'Granting - Should call the function Remove-SqlDatabasePermission when desired state is already absent' {
                Mock -CommandName Remove-SqlDatabasePermission -MockWith { } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @testParameters
               
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Remove-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters.PermissionState = 'Deny'

            It 'Denying - Should call the function Remove-SqlDatabasePermission when desired state is already absent' {
                Mock -CommandName Remove-SqlDatabasePermission -MockWith { } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @testParameters
               
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Remove-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters.Ensure = 'Present'

            It 'Denying - Should call the function Remove-SqlDatabasePermission when desired state is already present' {
                Mock -CommandName Add-SqlDatabasePermission -MockWith { } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @testParameters
               
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Add-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Context 'When the system is in the desired state' {
            $testParameters = $defaultParameters
            $testParameters += @{
                PermissionState = 'Grant'
                Ensure = 'Present'
                Permissions = @( 'Connect','Update' )
            }

            It 'Should throw an error when desired database does not exist' {
                Mock -CommandName Add-SqlDatabasePermission -MockWith {
                    return Throw
                } -ModuleName $script:DSCResourceName -Verifiable
                
                { Set-TargetResource @testParameters } | Should Throw
                
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Add-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should throw an error when desired login does not exist' {
                Mock -CommandName Add-SqlDatabasePermission -MockWith {
                    return Throw
                } -ModuleName $script:DSCResourceName -Verifiable
                
                { Set-TargetResource @testParameters } | Should Throw
                
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Add-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should not call the function Add-SqlDatabasePermission when desired state is already present' {
                Mock -CommandName Get-SqlDatabasePermission -MockWith { return @( 'Connect','Update' ) } -ModuleName $script:DSCResourceName -Verifiable

                $result = Get-TargetResource @testParameters

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Add-SqlDatabasePermission -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters.Ensure = 'Absent'

            It 'Should not call the function Remove-SqlDatabasePermission when desired state is already absent' {
                Mock -CommandName Get-SqlDatabasePermission -MockWith { return $null } -ModuleName $script:DSCResourceName -Verifiable

                $result = Get-TargetResource @testParameters

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                Assert-MockCalled Remove-SqlDatabasePermission -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope It
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
