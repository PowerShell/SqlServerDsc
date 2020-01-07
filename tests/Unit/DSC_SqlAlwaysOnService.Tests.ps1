<#
    .SYNOPSIS
        Automated unit test for DSC_SqlAlwaysOnService DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlAlwaysOnService'

$script:timer = [System.Diagnostics.Stopwatch]::StartNew()

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Unit'

$disableHadr = @{
    Ensure       = 'Absent'
    ServerName   = 'Server01'
    InstanceName = 'MSSQLSERVER'
}

$enableHadr = @{
    Ensure       = 'Present'
    ServerName   = 'Server01'
    InstanceName = 'MSSQLSERVER'
}

$disableHadrNamedInstance = @{
    Ensure       = 'Absent'
    ServerName   = 'Server01'
    InstanceName = 'NamedInstance'
}

$enableHadrNamedInstance = @{
    Ensure       = 'Present'
    ServerName   = 'Server01'
    InstanceName = 'NamedInstance'
}

# Load the default SQL Module stub
Import-SQLModuleStub

try
{
    Describe "$($script:dscResourceName)\Get-TargetResource" {
        Context 'When HADR is disabled' {
            Mock -CommandName Connect-SQL -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    IsHadrEnabled = $false
                }
            } -ModuleName $script:dscResourceName -Verifiable

            It 'Should return that HADR is disabled' {
                # Get the current state
                $result = Get-TargetResource @enableHadr
                $result.IsHadrEnabled | Should -Be $false

                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return that HADR is disabled' {
                # Get the current state
                $result = Get-TargetResource @enableHadrNamedInstance
                $result.IsHadrEnabled | Should -Be $false

                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }

        Context 'When HADR is enabled' {
            Mock -CommandName Connect-SQL -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    IsHadrEnabled = $true
                }
            } -ModuleName $script:dscResourceName -Verifiable

            It 'Should return that HADR is enabled' {
                # Get the current state
                $result = Get-TargetResource @enableHadr
                $result.IsHadrEnabled | Should -Be $true

                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return that HADR is enabled' {
                # Get the current state
                $result = Get-TargetResource @enableHadrNamedInstance
                $result.IsHadrEnabled | Should -Be $true

                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }

        # This it regression test for issue #519.
        Context 'When Server.IsHadrEnabled returns $null' {
            Mock -CommandName Connect-SQL -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    IsHadrEnabled = $null
                }
            } -ModuleName $script:dscResourceName -Verifiable

            It 'Should fail with the correct error message' {
                # Regression test for issue #519
                { Get-TargetResource @enableHadr } | Should -Not -Throw 'Index operation failed; the array index evaluated to null'

                $result = Get-TargetResource @enableHadr
                $result.IsHadrEnabled | Should -Be $false

                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 2 -Exactly
            }
        }
    }

    Describe "$($script:dscResourceName)\Set-TargetResource" {
        Mock -CommandName Disable-SqlAlwaysOn -ModuleName $script:dscResourceName
        Mock -CommandName Enable-SqlAlwaysOn -ModuleName $script:dscResourceName
        Mock -CommandName Import-SQLPSModule -ModuleName $script:dscResourceName
        Mock -CommandName Restart-SqlService -ModuleName $script:dscResourceName -Verifiable

        Context 'When HADR is not in the desired state' {
            It 'Should enable SQL Always On when Ensure is set to Present' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        IsHadrEnabled = $true
                    }
                } -ModuleName $script:dscResourceName -Verifiable

                Set-TargetResource @enableHadr
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should disable SQL Always On when Ensure is set to Absent' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:dscResourceName -Verifiable

                Set-TargetResource @disableHadr
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should enable SQL Always On on a named instance when Ensure is set to Present' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        IsHadrEnabled = $true
                    }
                } -ModuleName $script:dscResourceName -Verifiable

                Set-TargetResource @enableHadrNamedInstance
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should disable SQL Always On on a named instance when Ensure is set to Absent' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:dscResourceName -Verifiable

                Set-TargetResource @disableHadrNamedInstance
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should throw the correct error message when Ensure is set to Present, but IsHadrEnabled is $false' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:dscResourceName -Verifiable

                { Set-TargetResource @enableHadr } | Should -Throw ($script:localizedData.AlterAlwaysOnServiceFailed -f 'enabled', $enableHadr.ServerName, $enableHadr.InstanceName)
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }

            It 'Should throw the correct error message when Ensure is set to Absent, but IsHadrEnabled is $true' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        IsHadrEnabled = $true
                    }
                } -ModuleName $script:dscResourceName -Verifiable

                { Set-TargetResource @disableHadr } | Should -Throw ($script:localizedData.AlterAlwaysOnServiceFailed -f 'disabled', $disableHadr.ServerName, $disableHadr.InstanceName)
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Disable-SqlAlwaysOn -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Enable-SqlAlwaysOn -Scope It -Times 0
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 1
            }
        }
    }

    Describe "$($script:dscResourceName)\Test-TargetResource" {
        Context 'When HADR is not in the desired state' {
            Mock -CommandName Connect-SQL -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    IsHadrEnabled = $true
                }
            } -ModuleName $script:dscResourceName -Verifiable

            It 'Should cause Test-TargetResource to return false when not in the desired state' {
                Test-TargetResource @disableHadr | Should -Be $false
            }
        }

        Context 'When HADR is in the desired state' {
            Mock -CommandName Connect-SQL -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    IsHadrEnabled = $true
                }
            } -ModuleName $script:dscResourceName -Verifiable

            It 'Should cause Test-TargetResource to return true when in the desired state' {
                Test-TargetResource @enableHadr | Should -Be $true
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Write-Verbose -Message ('Test {1} run for {0} minutes' -f ([System.TimeSpan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString('mm\:ss'), $script:dscResourceName) -Verbose
    $script:timer.Stop()
}
