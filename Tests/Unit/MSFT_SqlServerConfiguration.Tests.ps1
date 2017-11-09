$script:DSCModuleName      = 'SqlServerDsc'
$script:DSCResourceName    = 'MSFT_SqlServerConfiguration'

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
    SQLServer = 'CLU01'
    SQLInstanceName = 'ClusteredInstance'
    OptionName = 'user connections'
    OptionValue = 0
    RestartService = $false
    RestartTimeout = 120
}

$desiredState = @{
    SQLServer = 'CLU01'
    SQLInstanceName = 'ClusteredInstance'
    OptionName = 'user connections'
    OptionValue = 500
    RestartService = $false
    RestartTimeout = 120
}

$desiredStateRestart = @{
    SQLServer = 'CLU01'
    SQLInstanceName = 'ClusteredInstance'
    OptionName = 'user connections'
    OptionValue = 5000
    RestartService = $true
    RestartTimeout = 120
}

$dynamicOption = @{
    SQLServer = 'CLU02'
    SQLInstanceName = 'ClusteredInstance'
    OptionName = 'show advanced options'
    OptionValue = 0
    RestartService = $false
    RestartTimeout = 120
}

$invalidOption = @{
    SQLServer = 'CLU01'
    SQLInstanceName = 'MSSQLSERVER'
    OptionName = 'Does Not Exist'
    OptionValue = 1
    RestartService = $false
    RestartTimeout = 120
}

## compile the SMO stub
#Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

try
{
    Describe "$($script:DSCResourceName)\Get-TargetResource" {

        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName

        Context 'The system is not in the desired state' {

            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 0
                            }
                        )
                    }
                }

                ## add the Alter method
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            ## Get the current state
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed' {
                $result.SQLServer | Should -Be $desiredState.SQLServer
                $result.SQLInstanceName | Should -Be $desiredState.SQLInstanceName
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
                $mock = New-Object PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 500
                            }
                        )
                    }
                }

                ## add the Alter method
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            ## Get the current state
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed' {
                $result.SQLServer | Should -Be $desiredState.SQLServer
                $result.SQLInstanceName | Should -Be $desiredState.SQLInstanceName
                $result.OptionName | Should -Be $desiredState.OptionName
                $result.OptionValue | Should -Be $desiredState.OptionValue
                $result.RestartService | Should -Be $desiredState.RestartService
                $result.RestartTimeout | Should -Be $desiredState.RestartTimeout
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }

        Context 'Invalid data is supplied' {

            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 0
                            }
                        )
                    }
                }

                ## add the Alter method
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should call New-TerminatingError mock when a bad option name is specified' {
                { Get-TargetResource @invalidOption } | Should -Throw 'ConfigurationOptionNotFound'
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {

        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'user connections'
                            ConfigValue = 500
                        }
                    )
                }
            }

            ## add the Alter method
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
        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName New-TerminatingError -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'user connections'
                            ConfigValue = 0
                            IsDynamic = $false
                        }
                    )
                }
            }

            ## add the Alter method
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $SQLServer -eq 'CLU01' }

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'show advanced options'
                            ConfigValue = 1
                            IsDynamic = $true
                        }
                    )
                }
            }

            ## add the Alter method
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $SQLServer -eq 'CLU02' }

        Mock -CommandName Restart-SqlService -MockWith {} -ModuleName $script:DSCResourceName -Verifiable

        Mock -CommandName New-WarningMessage -MockWith {} -ModuleName $script:DSCResourceName -Verifiable

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

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-WarningMessage -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 0 -Exactly
            }

            It 'Should call Connect-SQL to get option values' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Context -Times 3
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
