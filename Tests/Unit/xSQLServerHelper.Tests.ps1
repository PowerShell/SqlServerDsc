# Unit Test Template Version: 1.1.0

<#
    AppVeyor build worker loads the SMO assembly which unable the tests to load the SMO stub classes.
    Running the tests in a Start-Job script block give us a clean environment. This is a workaround.
#>
$testJob = Start-Job -ArgumentList $PSScriptRoot -ScriptBlock {
    param
    (
        [System.String] $PSScriptRoot
    )

    $script:moduleName = 'xSQLServerHelper'

    [String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
        (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
    {
        & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
    }

    Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
    Import-Module (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent) -ChildPath 'xSQLServerHelper.psm1') -Scope Global -Force

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

    # Begin Testing
    InModuleScope $script:moduleName {
        Describe 'Testing Restart-SqlService' {

            Context 'Restart-SqlService standalone instance' {

                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'MSSQLSERVER'
                        InstanceName = ''
                        ServiceName = 'MSSQLSERVER'
                    }
                } -Verifiable -ParameterFilter { $SQLInstanceName -eq 'MSSQLSERVER' }

                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'NOAGENT'
                        InstanceName = 'NOAGENT'
                        ServiceName = 'NOAGENT'
                    }
                } -Verifiable -ParameterFilter { $SQLInstanceName -eq 'NOAGENT' }

                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'STOPPEDAGENT'
                        InstanceName = 'STOPPEDAGENT'
                        ServiceName = 'STOPPEDAGENT'
                    }
                } -Verifiable -ParameterFilter { $SQLInstanceName -eq 'STOPPEDAGENT' }

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
                } -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'MSSQLSERVER') }

                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'NAMEDINSTANCE'
                        InstanceName = 'NAMEDINSTANCE'
                        ServiceName = 'NAMEDINSTANCE'
                        IsClustered = $true
                    }
                } -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'NAMEDINSTANCE') }

                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'STOPPEDAGENT'
                        InstanceName = 'STOPPEDAGENT'
                        ServiceName = 'STOPPEDAGENT'
                        IsClustered = $true
                    }
                } -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'STOPPEDAGENT') }

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

        Describe "Testing Get-SqlDatabasePermission" {
            $mockSqlServerObject = [pscustomobject]@{
                InstanceName = 'MSSQLSERVER'
                ComputerNamePhysicalNetBIOS = 'SQL01'
            }

            $mockSqlServerObject = $mockSqlServerObject | Add-Member -MemberType ScriptProperty -Name Databases -Value { 
                return @{
                    'AdventureWorks' = @( ( New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, 'AdventureWorks') ) )
                } | Add-Member -MemberType ScriptMethod -Name EnumDatabasePermissions -Value {
                    return @{
                        'CONTOSO\SqlAdmin' = @( 'Connect','Update' )
                    }
                } -PassThru -Force
            } -PassThru -Force

            $mockSqlServerObject = $mockSqlServerObject | Add-Member -MemberType ScriptProperty -Name Logins -Value { 
                return @{
                    'CONTOSO\SqlAdmin' = @( ( New-Object Microsoft.SqlServer.Management.Smo.Login -ArgumentList @( $null, 'CONTOSO\SqlAdmin') -Property @{ LoginType = 'WindowsUser'} ) )
                }
            } -PassThru -Force
                

            Context 'When the specified database does not exist' {
                $testParameters = @{
                    Sql = $mockSqlServerObject
                    Name = 'CONTOSO\SqlAdmin'
                    Database = 'UnknownDatabase'
                    PermissionState = 'Grant'
                }
                
                It 'Should throw the correct error' {
                    { Get-SqlDatabasePermission @testParameters } | Should Throw "Database 'UnknownDatabase' does not exist on SQL server 'SQL01\MSSQLSERVER'."
                }
            }

            Context 'When the specified login does not exist' {
                $testParameters = @{
                    Sql = $mockSqlServerObject
                    Name = 'CONTOSO\UnknownUser'
                    Database = 'AdventureWorks'
                    PermissionState = 'Grant'
                }
                
                It 'Should throw the correct error' {
                    { Get-SqlDatabasePermission @testParameters } | Should Throw "Login 'CONTOSO\UnknownUser' does not exist on SQL server 'SQL01\MSSQLSERVER'."
                }
            }

            Context 'When the specified database and login exist and the system is not in desired state' {
                $testParameters = @{
                    Sql = $mockSqlServerObject
                    Name = 'CONTOSO\SqlAdmin'
                    Database = 'AdventureWorks'
                    PermissionState = 'Grant'
                }

                It 'Should not return any permissions' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $permission = Get-SqlDatabasePermission @testParameters 
                    $permission | Should BeNullOrEmpty
                }
                
            }

            Context 'When the specified database and login exist and the system is in desired state' {
                $testParameters = @{
                    Sql = $mockSqlServerObject
                    Name = 'CONTOSO\SqlAdmin'
                    Database = 'AdventureWorks'
                    PermissionState = 'Grant'
                }

                It 'Should return the correct permissions' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $permission = Get-SqlDatabasePermission @testParameters
                    $permission -contains 'Connect' | Should Be $true
                    $permission -contains 'Update' | Should Be $true 
                }
            }

            Assert-VerifiableMocks
        }
    }
}

$testJob | Receive-Job -Wait
