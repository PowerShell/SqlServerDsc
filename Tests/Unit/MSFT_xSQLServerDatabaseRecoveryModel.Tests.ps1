<#
    AppVeyor build worker loads the SMO assembly which unable the tests to load the SMO stub classes.
    Running the tests in a Start-Job script block give us a clean environment. This is a workaround.
#>
$testJob = Start-Job -ArgumentList $PSScriptRoot -ScriptBlock {
    param
    (
        [System.String] $PSScriptRoot
    )

    $script:DSCModuleName      = 'xSQLServer'
    $script:DSCResourceName    = 'MSFT_xSQLServerDatabaseRecoveryModel'

    #region HEADER

    # Unit Test Template Version: 1.1.0
    [String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

    # Begin Testing
    try
    {
        #region Pester Test Initialization

        # Loading mocked classes
        Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

        $nodeName = 'localhost'
        $instanceName = 'MSSQLSERVER'

        $defaultParameters = @{
            SQLInstanceName = $instanceName
            SQLServer = $nodeName
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

            Mock -CommandName Get-SqlDatabaseRecoveryModel -MockWith {
                return 'Simple'
            } -ModuleName $script:DSCResourceName -Verifiable

            Context 'When the database does not exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'UnknownDatabase'
                    RecoveryModel = 'Full'
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as absent' {
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                    $result.RecoveryModel | Should Be $testParameters.RecoveryModel
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                }
                It 'Should not call the mock function Get-SqlDatabaseRecoveryModel' {
                    Assert-MockCalled Get-SqlDatabaseRecoveryModel -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
                }
            }
            
            Context 'When the system is not in the desired state' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    RecoveryModel = 'Full'
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as absent' {
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                }

                It 'Should call the mock functions Connect-SQL and Get-SqlDatabaseRecoveryModel' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                    Assert-MockCalled Get-SqlDatabaseRecoveryModel -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                }
            }
        
            Context 'When the system is in the desired state for a database' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    RecoveryModel = 'Simple'
                }
        
                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                }

                It 'Should call the mock functions Connect-SQL and Get-SqlDatabaseRecoveryModel' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                    Assert-MockCalled Get-SqlDatabaseRecoveryModel -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
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

            Mock -CommandName Get-SqlDatabaseRecoveryModel -MockWith {
                return 'Simple'
            } -ModuleName $script:DSCResourceName -Verifiable

            Context 'When the system is not in the desired state' {
                It 'Should return the state as false when desired recovery model is not correct' {
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Name = 'AdventureWorks'
                        RecoveryModel = 'Full'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                }                
            }

            Context 'When the system is in the desired state' {
                It 'Should return the state as true when desired recovery model is correct' {
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Name = 'AdventureWorks'
                        RecoveryModel = 'Simple'
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
                    Add-Member ScriptProperty Databases {
                        return @{
                            'AdventureWorks' = @( ( New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, 'AdventureWorks') ) )
                        }
                    } -PassThru -Force
            } -ModuleName $script:DSCResourceName -Verifiable

            Context 'When desired database does not exist' {
                It 'Should not call the mock function Set-SqlDatabaseRecoveryModel' {
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Name = 'UnknownDatabase'
                        RecoveryModel = 'Simple'
                    }

                    Mock -CommandName Set-SqlDatabaseRecoveryModel -MockWith {
                        return Throw
                    } -ModuleName $script:DSCResourceName -Verifiable
                
                    Set-TargetResource @testParameters
                
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It         
                    Assert-MockCalled Set-SqlDatabaseRecoveryModel -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope It
                }
            }

            Context 'When desired recovery model is not setting' {
                It 'Should call the function Set-SqlDatabaseRecoveryModel when desired recovery model should be present' {
                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Name = 'AdventureWorks'
                        RecoveryModel = 'Simple'
                    }
                    Mock -CommandName Set-SqlDatabaseRecoveryModel -MockWith { } -ModuleName $script:DSCResourceName -Verifiable

                    Set-TargetResource @testParameters

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                    Assert-MockCalled Set-SqlDatabaseRecoveryModel -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                }
            }
        }
    }
    finally
    {
        #region FOOTER

        Restore-TestEnvironment -TestEnvironment $TestEnvironment 

        #endregion
    }
}

$testJob | Receive-Job -Wait
