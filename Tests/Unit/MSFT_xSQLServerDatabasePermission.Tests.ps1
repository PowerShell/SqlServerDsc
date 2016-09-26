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

    #endregion Pester Test Initialization

    $defaultParameters = @{
        SQLInstanceName = $instanceName
        SQLServer = $nodeName
        Database = 'AdventureWorks'
        Name = 'CONTOSO\SqlServiceAcct'
        Permission = @( 'CONNECT','CREATE TABLE' )
    }

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
            Mock -CommandName Get-SqlDatabasePermission -MockWith {
                return $null
            } -ModuleName $script:DSCResourceName -Verifiable

            $testParameters = $defaultParameters

            $result = Get-TargetResource @testParameters

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should not return any permissions' {
                $result.Permission | Should Be $null
            }

            It 'Should call the mock function Connect-SQL and Get-SqlDatabasePermission' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context                 
            }
        }
    
        Context 'When the system is in the desired state' {
            Mock -CommandName Get-SqlDatabasePermission -MockWith {
                return $testParameters.Permission
            } -ModuleName $script:DSCResourceName -Verifiable

            $testParameters = $defaultParameters

            $result = Get-TargetResource @testParameters

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should return correct permissions' {
                $result.Permission | Should Be $testParameters.Permission
            }

            It 'Should call the mock function Connect-SQL and Get-SqlDatabasePermission' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
                Assert-MockCalled Get-SqlDatabasePermission -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context                 
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Context 'When the system is not in the desired state' {
            It 'Should return that desired state is absent when wanted desired state is to be Present' {
                Mock -CommandName Get-SQLPSInstance -MockWith {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
        
                $testParameters = $defaultParameters
                $testParameters += @{
                    Ensure = 'Present'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $false

                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }

            It 'Should return that desired state is absent when wanted desired state is to be Absent' {
                Mock -CommandName Get-SQLPSInstance -MockWith {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
        
                $testParameters = $defaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $false

                Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }
        }

        Context 'When the system is in the desired state' {
            It 'Should return that desired state is present when wanted desired state is to be Present' {
                Mock -CommandName Get-SQLPSInstance -MockWith {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
        
                $testParameters = $defaultParameters
                $testParameters += @{
                    Ensure = 'Present'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }

            It 'Should return that desired state is present when wanted desired state is to be Absent' {
                Mock -CommandName Get-SQLPSInstance -MockWith {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
        
                $testParameters = $defaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Context 'When the system is not in the desired state' {
            It 'Should not throw error when desired state is to be Present' {
                Mock -CommandName Get-SQLPSInstance -MockWith {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal   

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
        
                $testParameters = $defaultParameters
                $testParameters += @{
                    Ensure = 'Present'
                }

                { Set-TargetResource @testParameters } | Should Not Throw

                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope It 
            }

            It 'Should not throw error when desired state is to be Absent' {
                Mock -CommandName Get-SQLPSInstance -MockWith {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
        
                $testParameters = $defaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                { Set-TargetResource @testParameters } | Should Not Throw

                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope It 
            }
        }

        Context 'When the system is in the desired state' {
            It 'Should not throw error when desired state is to be Present' {
                Mock -CommandName Get-SQLPSInstance -MockWith {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = 'Should not call Grant() or Revoke()'   

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
        
                $testParameters = $defaultParameters
                $testParameters += @{
                    Ensure = 'Present'
                }

                { Set-TargetResource @testParameters } | Should Not Throw

                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }

            It 'Should not throw error when desired state is to be Absent' {
                Mock -CommandName Get-SQLPSInstance -MockWith {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = 'Should not call Grant() or Revoke()'

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
        
                $testParameters = $defaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                { Set-TargetResource @testParameters } | Should Not Throw

                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
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
