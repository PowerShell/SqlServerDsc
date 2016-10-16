
$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerConfiguration'

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

$desiredState = @{
    SQLServer = "CLU01"
    SQLInstanceName = "ClusteredInstance"
    OptionName = "user connections"
    OptionValue = 500
    RestartService = $false
}

$desiredStateRestart = @{
    SQLServer = "CLU01"
    SQLInstanceName = "ClusteredInstance"
    OptionName = "user connections"
    OptionValue = 5000
    RestartService = $true
}

$dynamicOption = @{
    SQLServer = "CLU02"
    SQLInstanceName = "ClusteredInstance"
    OptionName = "show advanced options"
    OptionValue = 0
    RestartService = $false
}

$invalidOption = @{
    SQLServer = "CLU01"
    SQLInstanceName = "MSSQLSERVER"
    OptionName = "Does Not Exist"
    OptionValue = 1
    RestartService = $false
}

## compile the SMO stub
Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

# Begin Testing
try
{
    #region Test getting the current state
    Describe "$($script:DSCResourceName)\Get-TargetResource" {

        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName New-TerminatingError -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object PSObject -Property @{ 
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = "user connections"
                            ConfigValue = 0
                        }
                    )
                }
            }

            ## add the Alter method
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'The system is not in the desired state' {
            ## Get the current state
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed for property SQLServer' {
                $result.SQLServer | Should Be $desiredState.SQLServer
            }

            It 'Should return the same values as passed for property SQLInstanceName' {
                $result.SQLInstanceName | Should Be $desiredState.SQLInstanceName
            }

            It 'Should return the same values as passed for property OptionName' {
                $result.OptionName | Should Be $desiredState.OptionName
            }

            It 'Should return the same values as passed for property OptionValue' {
                $result.OptionValue | Should Not Be $desiredState.OptionValue
            }

            It 'Should return the same values as passed for property RestartService' {
                $result.RestartService | Should Be $desiredState.RestartService
            }

            It 'Should cause Test-TargetResource to return false' {
                Test-TargetResource @desiredState | Should be $false
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Get-TargetResource @desiredState
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Describe -Times 2
            }

            It 'Should call New-TerminatingError mock when a bad option name is specified' {
                { Get-TargetResource @invalidOption } | Should Throw
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope Describe -Times 1
            }
        }   
    }
    #endregion Test getting the current state

    #region Test testing the current state
    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        
        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object PSObject -Property @{ 
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = "user connections"
                            ConfigValue = 500
                        }
                    )
                }
            }

            ## add the Alter method
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable

        ## Test-TargetResource should return true when in the desired state
        It 'Should cause Test-TargetResource method to return true' {
            Test-TargetResource @desiredState | Should be $true
        }
    }
    #endregion Test testing the current state

    #region Test setting the desired state
    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName New-TerminatingError -MockWith {} -ModuleName $script:DSCResourceName

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object PSObject -Property @{ 
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = "user connections"
                            ConfigValue = 0
                            IsDynamic = $false
                        }
                    )
                }
            }

            ## add the Alter method
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $SQLServer -eq "CLU01" }

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object PSObject -Property @{ 
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = "show advanced options"
                            ConfigValue = 1
                            IsDynamic = $true
                        }
                    )
                }
            }

            ## add the Alter method
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $SQLServer -eq "CLU02" }

        Mock -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -MockWith {} -Verifiable

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
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Restart-SqlService -Scope It -Times 0 -Exactly
            }

            It 'Should call Connect-SQL to get option values' {
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Describe -Times 3
            }
        }
    }
    #endregion Test setting the desired state

    #region Non-Exported Function Unit Tests
    InModuleScope $script:DSCResourceName {
        Describe 'Testing Restart-SqlService' {

            Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

            Context 'Restart-SqlService standalone instance' {

                Mock -ModuleName $script:DSCResourceName -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = "MSSQLSERVER"
                        InstanceName = ""
                        ServiceName = "MSSQLSERVER"
                    }
                } -Verifiable -ParameterFilter { $SQLInstanceName -eq "MSSQLSERVER" }

                Mock -ModuleName $script:DSCResourceName -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = "NOAGENT"
                        InstanceName = "NOAGENT"
                        ServiceName = "NOAGENT"
                    }
                } -Verifiable -ParameterFilter { $SQLInstanceName -eq "NOAGENT" }

                ## Mock Get-Service
                Mock -CommandName Get-Service {
                    return @{
                        Name = "MSSQLSERVER"
                        DisplayName = "Microsoft SQL Server (MSSQLSERVER)"
                        DependentServices = @(
                            @{ 
                                Name = "SQLSERVERAGENT"
                                DisplayName = "SQL Server Agent (MSSQLSERVER)"
                                Status = "Running"
                                DependentServices = @()
                            }
                        )
                    }
                } -Verifiable -ParameterFilter { $DisplayName -eq "SQL Server (MSSQLSERVER)" }

                ## Mock Get-Service for non-clustered, no agent instance
                Mock -CommandName Get-Service {
                    return @{
                        Name = 'MSSQL$NOAGENT'
                        DisplayName = 'Microsoft SQL Server (NOAGENT)'
                        DependentServices = @()
                    }
                } -Verifiable -ParameterFilter { $DisplayName -eq "SQL Server (NOAGENT)" }

                Mock -CommandName Restart-Service {} -Verifiable

                Mock -CommandName Start-Service {} -Verifiable

                It 'Should not throw an exception when restarting a default instance' {
                    { Restart-SqlService -SQLServer $env:ComputerName -SQLInstanceName "MSSQLSERVER" } | Should Not Throw
                }

                It 'Should not throw an exception when restarting an instance with no SQL Agent' {
                    { Restart-SqlService -SQLServer $env:ComputerName -SQLInstanceName "NOAGENT" } | Should Not Throw
                }

                It 'Should use mock methods a specific number of times' {
                    Assert-MockCalled -CommandName Get-Service -Scope Context -Exactly -Times 2
                    Assert-MockCalled -CommandName Restart-Service -Scope Context -Exactly -Times 2
                    Assert-MockCalled -CommandName Start-Service -Scope Context -Exactly -Times 1
                }
            }

            Context 'Restart-SqlService clustered instance' {
                
                Mock -ModuleName $script:DSCResourceName -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = "MSSQLSERVER"
                        InstanceName = ""
                        ServiceName = "MSSQLSERVER"
                        IsClustered = $true
                    }
                } -Verifiable -ParameterFilter { ($SQLServer -eq "CLU01") -and ($SQLInstanceName -eq "MSSQLSERVER") }

                Mock -ModuleName $script:DSCResourceName -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = "NAMEDINSTANCE"
                        InstanceName = "NAMEDINSTANCE"
                        ServiceName = "NAMEDINSTANCE"
                        IsClustered = $true
                    }
                } -Verifiable -ParameterFilter { ($SQLServer -eq "CLU01") -and ($SQLInstanceName -eq "NAMEDINSTANCE") }

                ## Mock Get-WmiObject for SQL Instance
                Mock -CommandName Get-WmiObject {
                    return @("MSSQLSERVER","NAMEDINSTANCE") | ForEach-Object {
                        $mock = New-Object PSObject -Property @{
                            Name = "SQL Server ($($_))"
                            PrivateProperties = @{
                                InstanceName = $_
                            }
                        }

                        $mock | Add-Member -MemberType ScriptMethod -Name TakeOffline -Value { param ( [int] $TimeOut ) }

                        return $mock
                    }
                } -Verifiable -ParameterFilter { $Filter -imatch "Type = 'SQL Server'" }

                ## Mock Get-WmiObject for SQL Agent
                Mock -CommandName Get-WmiObject {
                    return @("MSSQLSERVER","NAMEDINSTANCE") | ForEach-Object {
                        $mock = New-Object PSObject -Property @{
                            Name = "SQL Server Agent (MSSQLSERVER)"
                            Type = "SQL Server Agent"
                        }

                        $mock | Add-Member -MemberType ScriptMethod -Name BringOnline -Value { param ( [int] $TimeOut ) }

                        return $mock
                    }
                } -Verifiable -ParameterFilter { $Query -match "^ASSOCIATORS OF" }

                It 'Should not throw an exception when restarting a default instance' {
                    { Restart-SqlService -SQLServer "CLU01" -SQLInstanceName "MSSQLSERVER" } | Should Not Throw
                }

                It 'Should not throw an exception when restarting a named instance' {
                    { Restart-SqlService -SQLServer "CLU01" -SQLInstanceName "NAMEDINSTANCE" } | Should Not Throw
                }

                It 'Should use mock methods a specific number of times' {
                    Assert-MockCalled -Scope Context -CommandName Get-WmiObject -Exactly -Times 4
                }
            }
        }
    }
    #endregion Non-Exported Function Unit Tests
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
