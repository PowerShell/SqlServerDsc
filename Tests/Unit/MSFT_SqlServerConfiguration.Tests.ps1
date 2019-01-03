<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlServerConfiguration DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

# This is used to make sure the unit test run in a container.
[Microsoft.DscResourceKit.UnitTest(ContainerName = 'Container2', ContainerImage = 'microsoft/windowsservercore')]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlServerConfiguration'

# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

$defaultState = @{
    ServerName     = 'CLU01'
    InstanceName   = 'ClusteredInstance'
    OptionName     = 'user connections'
    OptionValue    = 0
    RestartService = $false
    RestartTimeout = 120
}

$desiredState = @{
    ServerName     = 'CLU01'
    InstanceName   = 'ClusteredInstance'
    OptionName     = 'user connections'
    OptionValue    = 500
    RestartService = $false
    RestartTimeout = 120
}

$desiredStateRestart = @{
    ServerName     = 'CLU01'
    InstanceName   = 'ClusteredInstance'
    OptionName     = 'user connections'
    OptionValue    = 5000
    RestartService = $true
    RestartTimeout = 120
}

$dynamicOption = @{
    ServerName     = 'CLU02'
    InstanceName   = 'ClusteredInstance'
    OptionName     = 'show advanced options'
    OptionValue    = 0
    RestartService = $false
    RestartTimeout = 120
}

$invalidOption = @{
    ServerName     = 'CLU01'
    InstanceName   = 'MSSQLSERVER'
    OptionName     = 'Does Not Exist'
    OptionValue    = 1
    RestartService = $false
    RestartTimeout = 120
}

try
{
    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Context 'The system is not in the desired state' {
            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object -TypeName PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 0
                            }
                        )
                    }
                }

                # Add the Alter method.
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            # Get the current state.
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed' {
                $result.ServerName | Should -Be $desiredState.ServerName
                $result.InstanceName | Should -Be $desiredState.InstanceName
                $result.OptionName | Should -Be $desiredState.OptionName
                $result.OptionValue | Should -Not -Be $desiredState.OptionValue
                $result.RestartService | Should -Be $desiredState.RestartService
                $result.RestartTimeout | Should -Be $desiredState.RestartTimeout
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }

        Context 'The system is in the desired state' {
            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object -TypeName PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 500
                            }
                        )
                    }
                }

                # Add the Alter method.
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            # Get the current state.
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed' {
                $result.ServerName | Should -Be $desiredState.ServerName
                $result.InstanceName | Should -Be $desiredState.InstanceName
                $result.OptionName | Should -Be $desiredState.OptionName
                $result.OptionValue | Should -Be $desiredState.OptionValue
                $result.RestartService | Should -Be $desiredState.RestartService
                $result.RestartTimeout | Should -Be $desiredState.RestartTimeout
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }

        Context 'Invalid option name is supplied' {
            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object -TypeName PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 0
                            }
                        )
                    }
                }

                # Add the Alter method.
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should throw the correct error message' {
                $errorMessage = ($script:localizedData.ConfigurationOptionNotFound -f $invalidOption.OptionName)
                { Get-TargetResource @invalidOption } | Should -Throw $errorMessage
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object -TypeName PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'user connections'
                            ConfigValue = 500
                        }
                    )
                }
            }

            # Add the Alter method.
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable

        It 'Should cause Test-TargetResource to return false when not in the desired state' {
            Test-TargetResource @defaultState | Should -Be $false
        }

        It 'Should cause Test-TargetResource method to return true' {
            Test-TargetResource @desiredState | Should -Be $true
        }
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName New-TerminatingError -ModuleName $script:DSCResourceName
        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object -TypeName PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'user connections'
                            ConfigValue = 0
                            IsDynamic   = $false
                        }
                    )
                }
            }

            # Add the Alter method.
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $ServerName -eq 'CLU01' }

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object -TypeName PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'show advanced options'
                            ConfigValue = 1
                            IsDynamic   = $true
                        }
                    )
                }
            }

            # Add the Alter method.
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $ServerName -eq 'CLU02' }

        Mock -CommandName Restart-SqlService -ModuleName $script:DSCResourceName -Verifiable
        Mock -CommandName Write-Warning -ModuleName $script:DSCResourceName -Verifiable

        Context 'Change the system to the desired state' {
            It 'Should not restart SQL for a dynamic option' {
                Set-TargetResource @dynamicOption
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 0 -Exactly
            }

            It 'Should restart SQL for a non-dynamic option' {
                Set-TargetResource @desiredStateRestart
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 1 -Exactly
            }

            It 'Should warn about restart when required, but not requested' {
                Set-TargetResource @desiredState

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Write-Warning -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 0 -Exactly
            }

            It 'Should call Connect-SQL to get option values' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 3
            }
        }

        Context 'Invalid option name is supplied' {
            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object -TypeName PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 0
                            }
                        )
                    }
                }

                # Add the Alter method.
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should throw the correct error message' {
                $errorMessage = ($script:localizedData.ConfigurationOptionNotFound -f $invalidOption.OptionName)
                { Set-TargetResource @invalidOption } | Should -Throw $errorMessage
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
