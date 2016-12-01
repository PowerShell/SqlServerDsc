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

$absentState = @{
    Ensure = 'Absent'
    SQLServer = 'Server01'
    SQLInstanceName = 'MSSQLSERVER'
    RestartTimeout = 120
}

$presentState = @{
    Ensure = 'Present'
    SQLServer = 'Server01'
    SQLInstanceName = 'MSSQLSERVER'
    RestartTimeout = 120
}

$presentStateNamedInstance = @{
    Ensure = 'Present'
    SQLServer = 'Server01'
    SQLInstanceName = 'NamedInstance'
    RestartTimeout = 120
}

# Begin Testing
try
{
    Describe "$($script:DSCResourceName)\Get-TargetResource" {

        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

        Context 'When the system is not in the desired state' {

            Mock -CommandName Connect-SQL -MockWith {
                return New-Object PSObject -Property @{ 
                    IsHadrEnabled = $false
                }
            } -ModuleName $script:DSCResourceName -Verifiable

            # Get the current state
            $result = Get-TargetResource @presentState

            It 'Should return the state as $false' {
                $result.IsHadrEnabled | Should Not Be @{ 'Present' = $true; 'Absent' = $false }[$presentState.Ensure]
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }

        Context 'When the system is in the desired state' {

            Mock -CommandName Connect-SQL -MockWith {
                return New-Object PSObject -Property @{ 
                    IsHadrEnabled = $true
                }
            } -ModuleName $script:DSCResourceName -Verifiable

            # Get the current state
            $result = Get-TargetResource @presentState

            It 'Should return the state as $true' {
                $result.IsHadrEnabled | Should Be ( @{ 'Present' = $true; 'Absent' = $false }[$presentState.Ensure] )
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {

        
        
        Mock -CommandName Disable-SqlAlwaysOn -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName Enable-SqlAlwaysOn -MockWith {} -ModuleName $script:DSCResourceName
        
        Mock -CommandName New-TerminatingError { $ErrorType } -ModuleName $script:DSCResourceName

        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName Restart-SqlService -MockWith {} -ModuleName $script:DSCResourceName -Verifiable

        Context 'Change the system to the desired state' {
            It 'Should enable SQL Always On when Ensure is Present' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $true
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @presentState
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should disable SQL Always On when Ensure is Absent' {
                
                Mock -CommandName Connect-SQL -MockWith {
                return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @absentState
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should enable SQL Always On on a named instance when Ensure is Present' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $true
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @presentStateNamedInstance
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should call New-TerminatingError when the resource fails to apply the desired state' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:DSCResourceName -Verifiable
                
                { Set-TargetResource @presentState } | Should Throw 'AlterAlwaysOnServiceFailed'
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        
        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName
        
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object PSObject -Property @{ 
                IsHadrEnabled = $true
            }
        } -ModuleName $script:DSCResourceName -Verifiable
        
        It 'Should cause Test-TargetResource to return false when not in the desired state' {
            Test-TargetResource @absentState | Should be $false
        }

        It 'Should cause Test-TargetResource method to return true' {
            Test-TargetResource @presentState | Should be $true
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
