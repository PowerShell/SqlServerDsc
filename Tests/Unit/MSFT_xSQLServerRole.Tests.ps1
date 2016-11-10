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
    $script:DSCResourceName    = 'MSFT_xSQLServerRole'

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

        $defaultParameters = @{
            SQLInstanceName = $instanceName
            SQLServer = $nodeName
            ServerRole = 'dbcreator'
        }

        #endregion Pester Test Initialization

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Mock -CommandName Connect-SQL -MockWith {
                return New-Object Object | 
                    Add-Member ScriptProperty Roles {
                        return @{
                            'dbcreator' = @( ( New-Object Microsoft.SqlServer.Management.Smo.ServerRole -ArgumentList @( $null, 'CONTOSO\SQL-Admin')) )
                        }
                    } -PassThru -Force 
            } -ModuleName $script:DSCResourceName -Verifiable

            Context 'When the system is not in the desired state' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'UnknownUser'
                }
                
                Mock -CommandName Confirm-SqlServerRoleMember -MockWith { return $false } -ModuleName $script:DSCResourceName -Verifiable

                $result = Get-TargetResource @testParameters

                It 'Should return the state as absent' {
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL and Confirm-SqlServerRoleMember' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                    Assert-MockCalled Confirm-SqlServerRoleMember -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                }
            }
        
            Context 'When the system is in the desired state for a loginName' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'CONTOSO\SQL-Admin'
                    Ensure = 'Present'
                }
                
                Mock -CommandName Confirm-SqlServerRoleMember -MockWith { return $true } -ModuleName $script:DSCResourceName -Verifiable

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL and Confirm-SqlServerRoleMember' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                    Assert-MockCalled Confirm-SqlServerRoleMember -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                }
            }

            Assert-VerifiableMocks
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Mock -CommandName Connect-SQL -MockWith {
                return New-Object Object | 
                    Add-Member ScriptProperty Roles {
                        return @{
                            'dbcreator' = @( ( New-Object Microsoft.SqlServer.Management.Smo.ServerRole -ArgumentList @( $null, 'CONTOSO\SQL-Admin')) )
                        }
                    } -PassThru -Force 
            } -ModuleName $script:DSCResourceName -Verifiable

            Context 'When the system is not in the desired state' {            
                It 'Should return the test as false when desired loginName does not exist' {

                    Mock -CommandName Confirm-SqlServerRoleMember -MockWith { return $false } -ModuleName $script:DSCResourceName -Verifiable

                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Name = 'UnknownUser'
                        Ensure = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                    Assert-MockCalled Confirm-SqlServerRoleMember -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
                }

                It 'Should return the test as false when non-desired loginName exist' {

                    Mock -CommandName Confirm-SqlServerRoleMember -MockWith { return $true } -ModuleName $script:DSCResourceName -Verifiable

                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Name = 'NonDesiredUser'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                    Assert-MockCalled Confirm-SqlServerRoleMember -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return the test as true when desired loginName exist' {

                    Mock -CommandName Confirm-SqlServerRoleMember -MockWith { return $true } -ModuleName $script:DSCResourceName -Verifiable

                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Name = 'CONTOSO\SQL-Admin'
                        Ensure = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                    Assert-MockCalled Confirm-SqlServerRoleMember -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                }
                            
                It 'Should return the test as true when non-desired loginName does not exist' {

                    Mock -CommandName Confirm-SqlServerRoleMember -MockWith { return $false } -ModuleName $script:DSCResourceName -Verifiable

                    $testParameters = $defaultParameters
                    $testParameters += @{
                        Name = 'CONTOSO\SQL-Admin'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                    Assert-MockCalled Confirm-SqlServerRoleMember -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                }
            }

            Assert-VerifiableMocks
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Mock -CommandName Connect-SQL -MockWith {
                return New-Object Object | 
                    Add-Member ScriptProperty Roles {
                        return @{
                            'dbcreator' = @( ( New-Object Microsoft.SqlServer.Management.Smo.ServerRole -ArgumentList @( $null, 'CONTOSO\SQL-Admin')) )
                        }
                    } -PassThru -Force 
            } -ModuleName $script:DSCResourceName -Verifiable

            Context 'When the system is not in the desired state - PRESENT' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'CONTOSO\SQL-Admin'
                    Ensure = 'Present'
                }

                It 'Should call the mock function Connect-SQL and Add-SqlServerRoleMember' {
                    
                    Mock -CommandName Add-SqlServerRoleMember -MockWith { } -ModuleName $script:DSCResourceName -Verifiable
                    
                    Set-TargetResource @testParameters

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                    Assert-MockCalled Add-SqlServerRoleMember -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                }

                It 'Should return the state as present when desired loginName in server role successfully added' {
                    
                    Mock -CommandName Confirm-SqlServerRoleMember -MockWith { return $true } -ModuleName $script:DSCResourceName -Verifiable

                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
                }
            }

            Context 'When the system is not in the desired state - ABSENT' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'NonDesiredLogin'
                    Ensure = 'Absent'
                }

                It 'Should call the mock function Connect-SQL and Remove-SqlServerRoleMember' {

                    Mock -CommandName Remove-SqlServerRoleMember -MockWith { } -ModuleName $script:DSCResourceName -Verifiable

                    Set-TargetResource @testParameters
                    
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                    Assert-MockCalled Remove-SqlServerRoleMember -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
                }

                It 'Should return the state as absent when desired loginName in server role successfully dropped' {
                    
                    Mock -CommandName Confirm-SqlServerRoleMember -MockWith { return $false } -ModuleName $script:DSCResourceName -Verifiable

                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'absent'
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
