$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerAlwaysOnService'

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

$disableHadr = @{
    Ensure = 'Absent'
    SQLServer = 'Server01'
    SQLInstanceName = 'MSSQLSERVER'
}

$enableHadr = @{
    Ensure = 'Present'
    SQLServer = 'Server01'
    SQLInstanceName = 'MSSQLSERVER'
}

$disableHadrNamedInstance = @{
    Ensure = 'Absent'
    SQLServer = 'Server01'
    SQLInstanceName = 'NamedInstance'
}

$enableHadrNamedInstance = @{
    Ensure = 'Present'
    SQLServer = 'Server01'
    SQLInstanceName = 'NamedInstance'
}

# Begin Testing
try
{
    Describe "$($script:DSCResourceName)\Get-TargetResource" {

        Context 'When HADR is disabled' {

            Mock -CommandName Connect-SQL -MockWith {
                return New-Object PSObject -Property @{ 
                    IsHadrEnabled = $false
                }
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should return that HADR is disabled' {
                
                # Get the current state
                $result = Get-TargetResource @enableHadr
                
                $result.IsHadrEnabled | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return that HADR is disabled' {
                
                # Get the current state
                $result = Get-TargetResource @enableHadrNamedInstance
                
                $result.IsHadrEnabled | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }

        Context 'When HADR is enabled' {

            Mock -CommandName Connect-SQL -MockWith {
                return New-Object PSObject -Property @{ 
                    IsHadrEnabled = $true
                }
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should return that HADR is enabled' {
                
                # Get the current state
                $result = Get-TargetResource @enableHadr
                
                $result.IsHadrEnabled | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return that HADR is enabled' {
                
                # Get the current state
                $result = Get-TargetResource @enableHadrNamedInstance
                
                $result.IsHadrEnabled | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {

        # Loading stub cmdlets
        Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force

        Mock -CommandName Disable-SqlAlwaysOn -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName Enable-SqlAlwaysOn -MockWith {} -ModuleName $script:DSCResourceName
        
        Mock -CommandName New-TerminatingError { $ErrorType } -ModuleName $script:DSCResourceName

        Mock -CommandName Restart-SqlService -MockWith {} -ModuleName $script:DSCResourceName -Verifiable

        Context 'Change the system to the desired state' {
            It 'Should enable SQL Always On when Ensure is Present' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $true
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @enableHadr
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should disable SQL Always On when Ensure is Absent' {
                
                Mock -CommandName Connect-SQL -MockWith {
                return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @disableHadr
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should enable SQL Always On on a named instance when Ensure is Present' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $true
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @enableHadrNamedInstance
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should disable SQL Always On on a named instance when Ensure is Absent' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @disableHadrNamedInstance
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should throw the correct error message when Ensure is Present, but IsHadrEnabled is $false' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                { Set-TargetResource @enableHadr } | Should Throw 'AlterAlwaysOnServiceFailed'
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
            }

            It 'Should throw the correct error message when Ensure is Absent, but IsHadrEnabled is $true' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $true
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                { Set-TargetResource @disableHadr } | Should Throw 'AlterAlwaysOnServiceFailed'
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object PSObject -Property @{ 
                IsHadrEnabled = $true
            }
        } -ModuleName $script:DSCResourceName -Verifiable
        
        It 'Should cause Test-TargetResource to return false when not in the desired state' {
            Test-TargetResource @disableHadr | Should be $false
        }

        It 'Should cause Test-TargetResource to return true when in the desired state' {
            Test-TargetResource @enableHadr | Should be $true
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
