$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerMaxDop'

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

    $serverName     = 'SQL01'
    $instanceName   = 'MSSQLSERVER'

    $defaultParameters = @{
        SQLInstanceName = $instanceName
        SQLServer       = $serverName
    }
    
    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [pscustomobject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MaxDegreeOfParallelism = @{
                        DisplayName = 'max degree of parallelism'
                        Description = 'maximum degree of parallelism'
                        RunValue    = 4
                        ConfigValue = 4
                    }
                }
            }
            
            # Add the Alter method
            $mockSqlServerObject | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Mock -CommandName Get-SqlDscDynamicMaxDop -MockWith {
            return 4
        } -ModuleName $script:DSCResourceName -Verifiable
       
        Context 'When the system is not in the desired state and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxDop          = 1
                DynamicAlloc    = $false
                Ensure          = 'Present'
            }

            $result = Get-TargetResource @testParameters

            It 'Should return the desired state as absent' {
                $result.Ensure | Should Be 'Absent'
            }
            
            It 'Should return wrong MaxDop' {
                $result.MaxDop | Should Not Be $testParameters.MaxDop
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }
    
        Context 'When the system is in the desired state and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxDop          = 4
                DynamicAlloc    = $false
                Ensure          = 'Present'
            }

            $result = Get-TargetResource @testParameters

            It 'Should return the desired state as present' {
                $result.Ensure | Should Be 'Present'
            }
            
            It 'Should return right MaxDop' {
                $result.MaxDop | Should Be $testParameters.MaxDop
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }
                
        Context 'When the system is in the desired state and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc = $true
            }

            $result = Get-TargetResource @testParameters

            It 'Should return the desired state as present' {
                $result.Ensure | Should Be 'Present'
            }
            
            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }
    
        Mock -CommandName Get-SqlDscDynamicMaxDop -MockWith {
            return 8
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc = $true
            }

            $result = Get-TargetResource @testParameters

            It 'Should return the desired state as absent' {
                $result.Ensure | Should Be 'Absent'
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the MaxDop paramater is not null and DynamicAlloc set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxDop          = 4
                DynamicAlloc    = $true
            }

            It 'Should Throw when MaxDop paramater not null if DynamicAlloc set to true' {
                { Get-TargetResource @testParameters } | Should Throw
            }
            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Assert-VerifiableMocks
    }
    
    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [pscustomobject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MaxDegreeOfParallelism = @{
                        DisplayName = 'max degree of parallelism'
                        Description = 'maximum degree of parallelism'
                        RunValue    = 4
                        ConfigValue = 4
                    }
                }
            }
            
            # Add the Alter method
            $mockSqlServerObject | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Mock -CommandName Get-SqlDscDynamicMaxDop -MockWith {
            return 4
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxDop          = 1
                DynamicAlloc    = $false
            }      

            It 'Should return the state as false when desired MaxDop is not present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is in the desired state and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxDop          = 4
                DynamicAlloc    = $false
            }      

            It 'Should return the state as true when desired MaxDop is not present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is in the desired state and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc = $true
            }      

            It 'Should return the state as true when desired MaxDop is present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Mock -CommandName Get-SqlDscDynamicMaxDop -MockWith {
            return 8
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc = $true
            }      

            It 'Should return the state as true when desired MaxDop is not present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Assert-VerifiableMocks
    }
    
    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [pscustomobject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MaxDegreeOfParallelism = @{
                        DisplayName = 'max degree of parallelism'
                        Description = 'maximum degree of parallelism'
                        RunValue    = 4
                        ConfigValue = 4
                    }
                }
            }
            
            # Add the Alter method
            $mockSqlServerObject | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Mock -CommandName Get-SqlDscDynamicMaxDop -MockWith {
            return 4
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the MaxDop paramater is not null and DynamicAlloc set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxDop          = 4
                DynamicAlloc    = $true
                Ensure          = 'Present'
            }

            It 'Should Throw when MaxDop paramater not null if DynamicAlloc set to true' {
                { Set-TargetResource @testParameters } | Should Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the Ensure paramater is set to Absent' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure = 'Absent'
            }

            It 'Should Not Throw when Ensure parameter is set to Absent' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the desired MaxDop parameter is not set' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxDop          = 1
                DynamicAlloc    = $false
                Ensure          = 'Present'
            }

            It 'Should Not Throw when MaxDop paramater is not null and DynamicAlloc set to false' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is not in the desired state and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc    = $true
                Ensure          = 'Present'
            }      

            It 'Should Not Throw when MaxDop paramater is not null and DynamicAlloc set to false' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-SqlDscDynamicMaxDop' {
                Assert-MockCalled Get-SqlDscDynamicMaxDop -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
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
