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

$defaultState = @{
    Ensure = 'Absent'
    SQLServer = 'Server01'
    SQLInstanceName = 'MSSQLSERVER'
    RestartTimeout = 120
}

$desiredState = @{
    Ensure = 'Present'
    SQLServer = 'Server01'
    SQLInstanceName = 'MSSQLSERVER'
    RestartTimeout = 120
}

$desiredStateNamedInstance = @{
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

        Context 'The system is not in the desired state' {

            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object PSObject -Property @{ 
                    IsHadrEnabled = $false
                }

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            # Get the current state
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed' {
                $result.IsHadrEnabled | Should Not Be @{ 'Present' = $true; 'Absent' = $false }[$desiredState.Ensure]
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }

        Context 'The system is in the desired state' {

            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object PSObject -Property @{ 
                    IsHadrEnabled = $true
                }

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            # Get the current state
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed' {
                $result.IsHadrEnabled | Should Be ( @{ 'Present' = $true; 'Absent' = $false }[$desiredState.Ensure] )
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
                    $mock = New-Object PSObject -Property @{ 
                        IsHadrEnabled = $true
                    }

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @desiredState
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should disable SQL Always On when Ensure is Absent' {
                
                Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @defaultState
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should enable SQL Always On on a named instance when Ensure is Present' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{ 
                        IsHadrEnabled = $true
                    }

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable
                
                Set-TargetResource @desiredStateNamedInstance
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should call New-TerminatingError when the resource fails to apply the desired state' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable
                
                { Set-TargetResource @desiredState } | Should Throw 'AlterAlwaysOnServiceFailed'
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
            $mock = New-Object PSObject -Property @{ 
                IsHadrEnabled = $true
            }

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable
        
        It 'Should cause Test-TargetResource to return false when not in the desired state' {
            Test-TargetResource @defaultState | Should be $false
        }

        It 'Should cause Test-TargetResource method to return true' {
            Test-TargetResource @desiredState | Should be $true
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}