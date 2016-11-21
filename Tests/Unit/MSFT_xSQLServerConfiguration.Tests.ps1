<#
    AppVeyor build worker loads the SMO assembly which unable the tests to load the SMO stub classes.
    Running the tests in a Start-Job script block give us a clean environment. This is a workaround.
#>
$testJob = Start-Job -ArgumentList $PSScriptRoot -ScriptBlock {
    param
    (
        [System.String] $PSScriptRoot
    )

    $script:DSCModuleName      = 'xSQLServer'
    $script:DSCResourceName    = 'MSFT_xSQLServerConfiguration'

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
                    $result.SQLServer | Should Be $desiredState.SQLServer
                    $result.SQLInstanceName | Should Be $desiredState.SQLInstanceName
                    $result.OptionName | Should Be $desiredState.OptionName
                    $result.OptionValue | Should Not Be $desiredState.OptionValue
                    $result.RestartService | Should Be $desiredState.RestartService
                    $result.RestartTimeout | Should Be $desiredState.RestartTimeout
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
                    $result.SQLServer | Should Be $desiredState.SQLServer
                    $result.SQLInstanceName | Should Be $desiredState.SQLInstanceName
                    $result.OptionName | Should Be $desiredState.OptionName
                    $result.OptionValue | Should Be $desiredState.OptionValue
                    $result.RestartService | Should Be $desiredState.RestartService
                    $result.RestartTimeout | Should Be $desiredState.RestartTimeout
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
                    { Get-TargetResource @invalidOption } | Should Throw 'ConfigurationOptionNotFound'
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
                Test-TargetResource @defaultState | Should be $false
            }

            It 'Should cause Test-TargetResource method to return true' {
                Test-TargetResource @desiredState | Should be $true
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

        InModuleScope $script:DSCResourceName {
            Describe 'Testing Restart-SqlService' {

                Mock -CommandName New-VerboseMessage -MockWith {} -ModuleName $script:DSCResourceName

                Context 'Restart-SqlService standalone instance' {

                    Mock -CommandName Connect-SQL -MockWith {
                        return @{
                            Name = 'MSSQLSERVER'
                            InstanceName = ''
                            ServiceName = 'MSSQLSERVER'
                        }
                    } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $SQLInstanceName -eq 'MSSQLSERVER' }

                    Mock -CommandName Connect-SQL -MockWith {
                        return @{
                            Name = 'NOAGENT'
                            InstanceName = 'NOAGENT'
                            ServiceName = 'NOAGENT'
                        }
                    } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $SQLInstanceName -eq 'NOAGENT' }

                    Mock -CommandName Connect-SQL -MockWith {
                        return @{
                            Name = 'STOPPEDAGENT'
                            InstanceName = 'STOPPEDAGENT'
                            ServiceName = 'STOPPEDAGENT'
                        }
                    } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $SQLInstanceName -eq 'STOPPEDAGENT' }

                    ## SQL instance with running SQL Agent Service
                    Mock -CommandName Get-Service {
                        return @{
                            Name = 'MSSQLSERVER'
                            DisplayName = 'Microsoft SQL Server (MSSQLSERVER)'
                            DependentServices = @(
                                @{ 
                                    Name = 'SQLSERVERAGENT'
                                    DisplayName = 'SQL Server Agent (MSSQLSERVER)'
                                    Status = 'Running'
                                    DependentServices = @()
                                }
                            )
                        }
                    } -Verifiable -ParameterFilter { $DisplayName -eq 'SQL Server (MSSQLSERVER)' }

                    ## SQL instance with no installed SQL Agent Service
                    Mock -CommandName Get-Service {
                        return @{
                            Name = 'MSSQL$NOAGENT'
                            DisplayName = 'Microsoft SQL Server (NOAGENT)'
                            DependentServices = @()
                        }
                    } -Verifiable -ParameterFilter { $DisplayName -eq 'SQL Server (NOAGENT)' }

                    ## SQL instance with stopped SQL Agent Service
                    Mock -CommandName Get-Service {
                        return @{
                            Name = 'MSSQL$STOPPEDAGENT'
                            DisplayName = 'Microsoft SQL Server (STOPPEDAGENT)'
                            DependentServices = @(
                                @{ 
                                    Name = 'SQLAGENT$STOPPEDAGENT'
                                    DisplayName = 'SQL Server Agent (STOPPEDAGENT)'
                                    Status = 'Stopped'
                                    DependentServices = @()
                                }
                            )
                        }
                    } -Verifiable -ParameterFilter { $DisplayName -eq 'SQL Server (STOPPEDAGENT)' }

                    Mock -CommandName Restart-Service {} -Verifiable

                    Mock -CommandName Start-Service {} -Verifiable

                    It 'Should restart SQL Service and running SQL Agent service' {
                        { Restart-SqlService -SQLServer $env:ComputerName -SQLInstanceName 'MSSQLSERVER' } | Should Not Throw

                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-Service -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Restart-Service -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Start-Service -Scope It -Exactly -Times 1
                    }

                    It 'Should restart SQL Service and not try to restart missing SQL Agent service' {
                        { Restart-SqlService -SQLServer $env:ComputerName -SQLInstanceName 'NOAGENT' } | Should Not Throw

                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-Service -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Restart-Service -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Start-Service -Scope It -Exactly -Times 0
                    }

                    It 'Should restart SQL Service and not try to restart stopped SQL Agent service' {
                        { Restart-SqlService -SQLServer $env:ComputerName -SQLInstanceName 'STOPPEDAGENT' } | Should Not Throw

                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-Service -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Restart-Service -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Start-Service -Scope It -Exactly -Times 0
                    }
                }

                Context 'Restart-SqlService clustered instance' {
                    
                    Mock -CommandName Connect-SQL -MockWith {
                        return @{
                            Name = 'MSSQLSERVER'
                            InstanceName = ''
                            ServiceName = 'MSSQLSERVER'
                            IsClustered = $true
                        }
                    } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'MSSQLSERVER') }

                    Mock -CommandName Connect-SQL -MockWith {
                        return @{
                            Name = 'NAMEDINSTANCE'
                            InstanceName = 'NAMEDINSTANCE'
                            ServiceName = 'NAMEDINSTANCE'
                            IsClustered = $true
                        }
                    } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'NAMEDINSTANCE') }

                    Mock -CommandName Connect-SQL -MockWith {
                        return @{
                            Name = 'STOPPEDAGENT'
                            InstanceName = 'STOPPEDAGENT'
                            ServiceName = 'STOPPEDAGENT'
                            IsClustered = $true
                        }
                    } -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'STOPPEDAGENT') }

                    Mock -CommandName Get-CimInstance -MockWith {
                        @('MSSQLSERVER','NAMEDINSTANCE','STOPPEDAGENT') | ForEach-Object {
                            $mock = New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource','root/MSCluster'
                            
                            $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server ($($_))" -TypeName 'String'
                            $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                            $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{ InstanceName = $_ }

                            return $mock
                        }
                    } -Verifiable -ParameterFilter { ($ClassName -eq 'MSCluster_Resource') -and ($Filter -eq "Type = 'SQL Server'") }

                    Mock -CommandName Get-CimAssociatedInstance -MockWith {
                        $mock = New-Object Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource','root/MSCluster'
                            
                        $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                        $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                        $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value (@{ $true = 3; $false = 2 }[($InputObject.PrivateProperties.InstanceName -eq 'STOPPEDAGENT')]) -TypeName 'Int32'
                        
                        return $mock
                    } -Verifiable -ParameterFilter { $ResultClassName -eq 'MSCluster_Resource' }

                    Mock -CommandName Invoke-CimMethod -MockWith {} -Verifiable -ParameterFilter { $MethodName -eq 'TakeOffline' }

                    Mock -CommandName Invoke-CimMethod -MockWith {} -Verifiable -ParameterFilter { $MethodName -eq 'BringOnline' } 

                    It 'Should restart SQL Server and SQL Agent resources for a clustered default instance' {
                        { Restart-SqlService -SQLServer 'CLU01' } | Should Not Throw
                        
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter { $MethodName -eq 'TakeOffline' } -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter { $MethodName -eq 'BringOnline' } -Scope It -Exactly -Times 2 
                    }

                    It 'Should restart SQL Server and SQL Agent resources for a clustered named instance' {
                        { Restart-SqlService -SQLServer 'CLU01' -SQLInstanceName 'NAMEDINSTANCE' } | Should Not Throw

                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter { $MethodName -eq 'TakeOffline' } -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter { $MethodName -eq 'BringOnline' } -Scope It -Exactly -Times 2 
                    }

                    It 'Should not try to restart a SQL Agent resource that is not online' {
                        { Restart-SqlService -SQLServer 'CLU01' -SQLInstanceName 'STOPPEDAGENT' } | Should Not Throw

                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter { $MethodName -eq 'TakeOffline' } -Scope It -Exactly -Times 1
                        Assert-MockCalled -CommandName Invoke-CimMethod -ParameterFilter { $MethodName -eq 'BringOnline' } -Scope It -Exactly -Times 1
                    }
                }
            }
        }
    }
    finally
    {
        Restore-TestEnvironment -TestEnvironment $TestEnvironment
    }
}

$testJob | Receive-Job -Wait
