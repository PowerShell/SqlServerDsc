
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
    RestartService = $False
}

# Begin Testing
try
{
    #region Not in the desired state
    Describe 'The system is not in the desired state' {

        Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

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

        Context "Validate returned properties" {
            ## Get the current state
            $result = Get-TargetResource @desiredState

            It "Property: SQLServer" {
                $result.SQLServer | Should Be $desiredState.SQLServer
            }

            It "Property: SQLInstanceName" {
                $result.SQLInstanceName | Should Be $desiredState.SQLInstanceName
            }

            It "Property: OptionName" {
                $result.OptionName | Should Be $desiredState.OptionName
            }

            It "Property: OptionValue" {
                $result.OptionValue | Should Not Be $desiredState.OptionValue
            }

            It "Property: RestartService" {
                $result.RestartService | Should Be $desiredState.RestartService
            }
        }

        It 'Test method returns false' {
            Test-TargetResource @desiredState | Should be $false
        }

        It 'Set method calls Connect-SQL' {
            ## attempt to bring the system into the desired state
            Get-TargetResource @desiredState

            # Check that our mock was called at least 3 times
            ##Assert-MockCalled -CommandName Connect-SQL -Times 1 -Scope Describe
            Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope Describe -Times 3
        }
    }
    #endregion Not in the desired state

    #region In the desired state
    Describe 'The system is in the desired state' {
        
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
        It 'Test method returns true' {
            Test-TargetResource @desiredState | Should be $true
        }
    }
    #endregion In the desired state

    #region Non-Exported Function Unit Tests
    InModuleScope $script:DSCResourceName {
        Describe "Testing Restart-SqlService" {
            
            ## compile the SMO stub
            Add-Type -Path .\Stubs\SMO.cs

            Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

            Context "Standalone Service Restart" {

                ## Mock Get-Service
                Mock -CommandName Get-Service {
                    return @{
                        Name = "MSSQLSERVER"
                        DisplayName = "Microsoft SQL Server (MSSQLSERVER)"
                        DependentServices = @(
                            @{ 
                                Name = "SQLSERVERAGENT"
                                DisplayName = "SQL Server Agent (MSSQLSERVER)"
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

                It "Restart instance" {
                    $Sql = New-Object Microsoft.SqlServer.Management.Smo.Server 
                    $Sql.Name = "MSSQLSERVER"
                    $Sql.InstanceName = ""
                    $Sql.ServiceName = "MSSQLSERVER"

                    ## Call Restart
                    { Restart-SqlService -ServerObject $Sql } | Should Not Throw
                }

                It "Restart instance without Agent" {
                    $Sql = New-Object Microsoft.Sqlserver.Management.Smo.Server
                    $Sql.Name = "NOAGENT"
                    $Sql.InstanceName = "NOAGENT"
                    $Sql.ServiceName = "NOAGENT"

                    { Restart-SqlService -ServerObject $Sql } | Should Not Throw
                }

                It "Assert Restart-SqlService called Mocks" {
                    Assert-MockCalled -CommandName Get-Service -Scope Context -Times 2
                    Assert-MockCalled -CommandName Restart-Service -Scope Context -Times 2
                    Assert-MockCalled -CommandName Start-Service -Scope Context -Times 1
                }
            }

            Context "Clustered Service Restart" {
                
                ## Mock Get-WmiObject for SQL Instance
                Mock -CommandName Get-WmiObject {
                    $mock = New-Object PSObject -Property @{
                        Name = "SQL Server (MSSQLSERVER)"
                    }

                    $mock | Add-Member -MemberType ScriptMethod -Name TakeOffline -Value { param ( [int] $TimeOut ) }

                    return $mock
                } -Verifiable -ParameterFilter { $Filter -imatch "Type = 'SQL Server'" }

                ## Mock Get-WmiObject for SQL Instance
                Mock -CommandName Get-WmiObject {
                    $mock = New-Object PSObject -Property @{
                        Name = "SQL Server Agent (MSSQLSERVER)"
                    }

                    $mock | Add-Member -MemberType ScriptMethod -Name BringOnline -Value { param ( [int] $TimeOut ) }

                    return $mock
                } -Verifiable -ParameterFilter { $Filter -imatch "Type = 'SQL Server Agent'" }

                It "Restart default instance" {
                    $Sql = New-Object Microsoft.SqlServer.Management.Smo.Server 
                    $Sql.Name = "MSSQLSERVER"
                    $Sql.InstanceName = ""
                    $Sql.ServiceName = "MSSQLSERVER"
                    $Sql.IsClustered = $true

                    { Restart-SqlService -ServerObject $Sql } | Should Not Throw
                }

                It "Restart named instance" {
                    $Sql = New-Object Microsoft.SqlServer.Management.Smo.Server 
                    $Sql.Name = "NAMEDINSTANCE"
                    $Sql.InstanceName = ""
                    $Sql.ServiceName = "NAMEDINSTANCE"
                    $Sql.IsClustered = $true

                    { Restart-SqlService -ServerObject $Sql } | Should Not Throw
                }

                It "Assert Restart-SqlService called Mock" {
                    Assert-MockCalled -Scope Context -CommandName Get-WmiObject -Times 4
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
