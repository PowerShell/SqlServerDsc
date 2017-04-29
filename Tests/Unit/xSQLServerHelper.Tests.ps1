# To run these tests, we have to fake login credentials
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

# Unit Test Template Version: 1.1.0

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
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

# Begin Testing
InModuleScope $script:moduleName {
    $mockNewObject_MicrosoftAnalysisServicesServer = {
        return New-Object Object |
                    Add-Member ScriptMethod Connect {
                        param(
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNullOrEmpty()]
                            [System.String]
                            $dataSource
                        )

                        if ($dataSource -ne $mockExpectedDataSource)
                        {
                            throw ("Datasource was expected to be '{0}', but was '{1}'." -f $mockExpectedDataSource,$dataSource)
                        }

                        if ($mockThrowInvalidOperation)
                        {
                            throw 'Unable to connect.'
                        }
                    } -PassThru -Force
    }

    $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter = {
        $TypeName -eq 'Microsoft.AnalysisServices.Server'
    }

    $mockSqlMajorVersion = 13
    $mockInstanceName = 'TEST'

    $mockSetupCredentialUserName = 'TestUserName12345'
    $mockSetupCredentialPassword = 'StrongOne7.'
    $mockSetupCredentialSecurePassword = ConvertTo-SecureString -String $mockSetupCredentialPassword -AsPlainText -Force
    $mockSetupCredential = New-Object PSCredential ($mockSetupCredentialUserName, $mockSetupCredentialSecurePassword)

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

    Describe 'Testing Connect-SQLAnalysis' {
        BeforeEach {
            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftAnalysisServicesServer `
                -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter `
                -Verifiable
        }

        Context 'When connecting to the default instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$env:COMPUTERNAME"

                { Connect-SQLAnalysis } | Should -Not -Throw

                Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the named instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$env:COMPUTERNAME\$mockInstanceName"

                { Connect-SQLAnalysis -SQLInstanceName $mockInstanceName } | Should -Not -Throw

                Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the named instance using Windows Authentication impersonation' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$env:COMPUTERNAME\$mockInstanceName;User ID=$mockSetupCredentialUserName;Password=$mockSetupCredentialPassword"

                { Connect-SQLAnalysis -SQLInstanceName $mockInstanceName -SetupCredential $mockSetupCredential } | Should -Not -Throw

                Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the default instance using the correct service instance but does not return a correct Analysis Service object' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = ''

                Mock -CommandName New-Object `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter `
                    -Verifiable

                $mockCorrectErrorMessage = ('Failed to connect to Analysis Services ''{0}''. InnerException: Did not get the expected Analysis Services server object.' -f $env:COMPUTERNAME)
                { Connect-SQLAnalysis } | Should -Throw $mockCorrectErrorMessage

                Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the default instance using a Analysis Service instance that does not exist' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = "Data Source=$env:COMPUTERNAME"

                # Force the mock of Connect() method to throw 'Unable to connect.'
                $mockThrowInvalidOperation = $true

                $mockCorrectErrorMessage = ('Failed to connect to Analysis Services ''{0}''. InnerException: Exception calling "Connect" with "1" argument(s): "Unable to connect."'  -f $env:COMPUTERNAME)
                { Connect-SQLAnalysis } | Should -Throw $mockCorrectErrorMessage

                Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter

                # Setting it back to the default so it does not disturb other tests.
                $mockThrowInvalidOperation = $false
            }
        }

        # This test is to test the mock so that it throws correct when data source is not the expected data source
        Context 'When connecting to the named instance using another data source then expected' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = "Force wrong datasource"

                $mockCorrectErrorMessage = 'Failed to connect to Analysis Services ''DummyHost\TEST''. InnerException: Exception calling "Connect" with "1" argument(s): "Datasource was expected to be ''Force wrong datasource'', but was ''Data Source=DummyHost\TEST''."'
                { Connect-SQLAnalysis -SQLServer 'DummyHost' -SQLInstanceName $mockInstanceName } | Should -Throw $mockCorrectErrorMessage

                Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Assert-VerifiableMocks
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

    Describe "Testing Add-SqlDatabasePermission" {
        $mockSqlServerObject = [PSCustomObject]@{
            InstanceName = 'MSSQLSERVER'
            ComputerNamePhysicalNetBIOS = 'SQL01'
        }

        $mockSqlServerObject = $mockSqlServerObject | Add-Member -MemberType ScriptProperty -Name Databases -Value {
            return @{
                'AdventureWorks' = @(
                    (
                        New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, 'AdventureWorks') |
                            Add-Member -MemberType ScriptProperty -Name Users -Value {
                                return @{
                                    'CONTOSO\SqlAdmin' = $true
                                    'CONTOSO\UnknownUser' = $false
                                }
                            } -PassThru -Force
                    )
                 )
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

        Context 'When the specified database and login exist and the system is not in desired state' {
            $testParameters = @{
                Sql             = $mockSqlServerObject
                Name            = 'CONTOSO\SqlAdmin'
                Database        = 'AdventureWorks'
                PermissionState = 'Grant'
                Permissions     = @( 'Connect','Update' )
            }

            It 'Should add permissions to the specified database' {
                Add-SqlDatabasePermission @testParameters
            }
        }

        Context 'When the specified database does not exist' {
            $testParameters = @{
                Sql             = $mockSqlServerObject
                Name            = 'CONTOSO\SqlAdmin'
                Database        = 'UnknownDatabase'
                PermissionState = 'Grant'
                Permissions     = @( 'Connect','Update' )
            }

            It 'Should throw the correct error' {
                { Add-SqlDatabasePermission @testParameters } | Should Throw "Database 'UnknownDatabase' does not exist on SQL server 'SQL01\MSSQLSERVER'."
            }
        }

        Context 'When the specified login does not exist' {
            $testParameters = @{
                Sql             = $mockSqlServerObject
                Name            = 'CONTOSO\UnknownUser'
                Database        = 'AdventureWorks'
                PermissionState = 'Grant'
                Permissions     = @( 'Connect','Update' )
            }

            It 'Should throw the correct error' {
                { Add-SqlDatabasePermission @testParameters } | Should Throw "Login 'CONTOSO\UnknownUser' does not exist on SQL server 'SQL01\MSSQLSERVER'."
            }
        }

        Assert-VerifiableMocks
    }

    Describe "Testing Remove-SqlDatabasePermission" {
        $mockSqlServerObject = [PSCustomObject]@{
            InstanceName = 'MSSQLSERVER'
            ComputerNamePhysicalNetBIOS = 'SQL01'
        }

        $mockSqlServerObject = $mockSqlServerObject | Add-Member -MemberType ScriptProperty -Name Databases -Value {
            return @{
                'AdventureWorks' = @(
                    (
                        New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, 'AdventureWorks') |
                            Add-Member -MemberType ScriptProperty -Name Users -Value {
                                return @{
                                    'CONTOSO\SqlAdmin' = $true
                                    'CONTOSO\UnknownUser' = $false
                                }
                            } -PassThru -Force
                    )
                 )
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

        Context 'When the specified database and login exist and the system is not in desired state' {
            $testParameters = @{
                Sql             = $mockSqlServerObject
                Name            = 'CONTOSO\SqlAdmin'
                Database        = 'AdventureWorks'
                PermissionState = 'Grant'
                Permissions     = @( 'Connect','Update' )
            }

            It 'Should remove permissions to the specified database' {
                Remove-SqlDatabasePermission @testParameters
            }
        }

        Context 'When the specified database does not exist' {
            $testParameters = @{
                Sql             = $mockSqlServerObject
                Name            = 'CONTOSO\SqlAdmin'
                Database        = 'UnknownDatabase'
                PermissionState = 'Grant'
                Permissions     = @( 'Connect','Update' )
            }

            It 'Should throw the correct error' {
                { Remove-SqlDatabasePermission @testParameters } | Should Throw "Database 'UnknownDatabase' does not exist on SQL server 'SQL01\MSSQLSERVER'."
            }
        }

        Context 'When the specified login does not exist' {
            $testParameters = @{
                Sql             = $mockSqlServerObject
                Name            = 'CONTOSO\UnknownUser'
                Database        = 'AdventureWorks'
                PermissionState = 'Grant'
                Permissions     = @( 'Connect','Update' )
            }

            It 'Should throw the correct error' {
                { Remove-SqlDatabasePermission @testParameters } | Should Throw "Login 'CONTOSO\UnknownUser' does not exist on SQL server 'SQL01\MSSQLSERVER'."
            }
        }

        Assert-VerifiableMocks
    }

    Describe 'Testing Invoke-Query' {
        $mockExpectedQuery = ''

        $mockConnectSql = {
            return @(
                (
                    New-Object -TypeName PSObject -Property @{
                        Databases = @{
                            'master' = (
                                New-Object -TypeName PSObject -Property @{ Name = 'master' } |
                                    Add-Member -MemberType ScriptMethod -Name ExecuteNonQuery -Value {
                                        param
                                        (
                                            [Parameter()]
                                            [string]
                                            $sqlCommand
                                        )

                                        if ( $sqlCommand -ne $mockExpectedQuery )
                                        {
                                            throw
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
                                        param
                                        (
                                            [Parameter()]
                                            [string]
                                            $sqlCommand
                                        )

                                        if ( $sqlCommand -ne $mockExpectedQuery )
                                        {
                                            throw
                                        }

                                        return New-Object System.Data.DataSet
                                    } -PassThru
                            )
                        }
                    }
                )
            )
        }

        BeforeEach {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSql -ModuleName $script:DSCResourceName -Verifiable
        }
        Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName

        $queryParams = @{
            SQLServer = 'Server1'
            SQLInstanceName = 'MSSQLSERVER'
            Database = 'master'
            Query = ''
        }

        Context 'Execute a query with no results' {
            It 'Should execute the query silently' {
                $queryParams.Query = "EXEC sp_configure 'show advanced option', '1'"
                $mockExpectedQuery = $queryParams.Query.Clone()

                { Invoke-Query @queryParams } | Should Not Throw

                Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, ExecuteNonQueryFailed, when executing the query fails' {
                $queryParams.Query = 'BadQuery'

                { Invoke-Query @queryParams } | Should Throw 'ExecuteNonQueryFailed'

                Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
            }
        }

        Context 'Execute a query with results' {
            It 'Should execute the query and return a result set' {
                $queryParams.Query = 'SELECT name FROM sys.databases'
                $mockExpectedQuery = $queryParams.Query.Clone()

                Invoke-Query @queryParams -WithResults | Should Not BeNullOrEmpty

                Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, ExecuteQueryWithResultsFailed, when executing the query fails' {
                $queryParams.Query = 'BadQuery'

                { Invoke-Query @queryParams -WithResults } | Should Throw 'ExecuteQueryWithResultsFailed'

                Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
            }
        }
    }

    Describe "Testing Update-AvailabilityGroupReplica" {
        Mock -CommandName New-TerminatingError { $ErrorType } -Verifiable

        Context 'When the Availability Group Replica is altered' {
            It 'Should silently alter the Availability Group Replica' {
                $availabilityReplica = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica

                { Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityReplica } | Should Not Throw

                Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, AlterAvailabilityGroupReplicaFailed, when altering the Availaiblity Group Replica fails' {
                $availabilityReplica = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                $availabilityReplica.Name = 'AlterFailed'

                { Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityReplica } | Should Throw 'AlterAvailabilityGroupReplicaFailed'

                Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
            }
        }
    }

    Describe "Testing Test-LoginEffectivePermissions" {

        $mockAllPermissionsPresent = @(
            'Connect SQL',
            'Alter Any Availability Group',
            'View Server State'
        )

        $mockPermissionsMissing = @(
            'Connect SQL',
            'View Server State'
        )

        $mockInvokeQueryClusterServicePermissionsSet = @() # Will be set dynamically in the check

        $mockInvokeQueryClusterServicePermissionsResult = {
            return New-Object PSObject -Property @{
                Tables = @{
                    Rows = @{
                        permission_name = $mockInvokeQueryClusterServicePermissionsSet
                    }
                }
            }
        }

        $testLoginEffectivePermissionsParams = @{
            SQLServer = 'Server1'
            SQLInstanceName = 'MSSQLSERVER'
            Login = 'NT SERVICE\ClusSvc'
            Permissions = @()
        }

        BeforeEach {
            Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServicePermissionsResult -Verifiable
        }

        Context 'When all of the permissions are present' {

            It 'Should return $true when the desired permissions are present' {
                $mockInvokeQueryClusterServicePermissionsSet = $mockAllPermissionsPresent.Clone()
                $testLoginEffectivePermissionsParams.Permissions = $mockAllPermissionsPresent.Clone()

                Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams | Should Be $true

                Assert-MockCalled -CommandName Invoke-Query -Times 1 -Exactly
            }
        }

        Context 'When a permission is missing' {

            It 'Should return $false when the desired permissions are not present' {
                $mockInvokeQueryClusterServicePermissionsSet = $mockPermissionsMissing.Clone()
                $testLoginEffectivePermissionsParams.Permissions = $mockAllPermissionsPresent.Clone()

                Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams | Should Be $false

                Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 1 -Exactly
            }

            It 'Should return $false when the specified login has no permissions assigned' {
                $mockInvokeQueryClusterServicePermissionsSet = @()
                $testLoginEffectivePermissionsParams.Permissions = $mockAllPermissionsPresent.Clone()

                Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams | Should Be $false

                Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 1 -Exactly
            }
        }
    }

    $mockImportModule = {
        if ($Name -ne $mockExpectedModuleNameToImport)
        {
            throw ('Wrong module was loaded. Expected {0}, but was {1}.' -f $mockExpectedModuleNameToImport, $Name[0])
        }
    }

    $mockGetModule = {
        return New-Object PSObject -Property @{
            Name = $mockModuleNameToImport
        }
    }

    $mockGetModule_SqlServer_ParameterFilter = {
        $FullyQualifiedName.Name -eq 'SqlServer' -and $ListAvailable -eq $true
    }

    $mockGetModule_SQLPS_ParameterFilter = {
        $FullyQualifiedName.Name -eq 'SQLPS' -and $ListAvailable -eq $true
    }

    Describe 'Testing Import-SQLPSModule' -Tag ImportSQLPSModule {
        BeforeEach {
            Mock -CommandName Push-Location -Verifiable
            Mock -CommandName Pop-Location -Verifiable
            Mock -CommandName Import-Module -MockWith $mockImportModule -Verifiable
        }

        Context 'When module SqlServer exists' {
            $mockModuleNameToImport = 'SqlServer'
            $mockExpectedModuleNameToImport = 'SqlServer'

            It 'Should import the SqlServer module without throwing' {
                Mock -CommandName Get-Module -MockWith $mockGetModule -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Verifiable

                { Import-SQLPSModule } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-Module -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Push-Location -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Pop-Location -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Import-Module -Exactly -Times 1 -Scope It
            }
        }

        Context 'When only module SQLPS exists' {
            $mockModuleNameToImport = 'SQLPS'
            $mockExpectedModuleNameToImport = 'SQLPS'

            It 'Should import the SqlServer module without throwing' {
                Mock -CommandName Get-Module -MockWith $mockGetModule -ParameterFilter $mockGetModule_SQLPS_ParameterFilter -Verifiable
                Mock -CommandName Get-Module -MockWith {
                    return $null
                } -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Verifiable

                { Import-SQLPSModule } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-Module -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Get-Module -ParameterFilter $mockGetModule_SQLPS_ParameterFilter -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Push-Location -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Pop-Location -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Import-Module -Exactly -Times 1 -Scope It
            }
        }

        Context 'When neither SqlServer or SQLPS exists' {
            $mockModuleNameToImport = 'UnknownModule'
            $mockExpectedModuleNameToImport = 'SQLPS'

            It 'Should throw the correct error message' {
                Mock -CommandName Get-Module

                { Import-SQLPSModule } | Should -Throw 'Neither SqlServer module or SQLPS module was found.'

                Assert-MockCalled -CommandName Get-Module -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Push-Location -Exactly -Times 0 -Scope It
                Assert-MockCalled -CommandName Pop-Location -Exactly -Times 0 -Scope It
                Assert-MockCalled -CommandName Import-Module -Exactly -Times 0 -Scope It
            }
        }

        Context 'When Import-Module fails to load the module' {
            $mockModuleNameToImport = 'SqlServer'
            $mockExpectedModuleNameToImport = 'SqlServer'

            It 'Should throw the correct error message' {
                Mock -CommandName Get-Module -MockWith $mockGetModule -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Verifiable
                Mock -CommandName Import-Module -MockWith {
                    throw 'Mock Import-Module throwing a mocked error.'
                }

                { Import-SQLPSModule } | Should -Throw 'Failed to import SqlServer module. InnerException: Mock Import-Module throwing a mocked error.'

                Assert-MockCalled -CommandName Get-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Push-Location -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Pop-Location -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Import-Module -Exactly -Times 1 -Scope It
            }
        }

        # This is to test the tests (so the mock throws correctly)
        Context 'When mock Import-Module is called with wrong module name' {
            $mockModuleNameToImport = 'SqlServer'
            $mockExpectedModuleNameToImport = 'UnknownModule'

            It 'Should throw the correct error message' {
                Mock -CommandName Get-Module -MockWith $mockGetModule -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Verifiable

                { Import-SQLPSModule } | Should -Throw 'Failed to import SqlServer module. InnerException: Wrong module was loaded. Expected UnknownModule, but was SqlServer.'

                Assert-MockCalled -CommandName Get-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Push-Location -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Pop-Location -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Import-Module -Exactly -Times 1 -Scope It
            }
        }

        Assert-VerifiableMocks
    }

    $mockGetItemProperty_MicrosoftSQLServer_InstanceNames_SQL = {
        return @(
            (
                New-Object Object |
                    Add-Member -MemberType NoteProperty -Name $mockInstanceName -Value $mockInstance_InstanceId -PassThru -Force
            )
        )
    }

    $mockGetItemProperty_MicrosoftSQLServer_FullInstanceId_Setup = {
        return @(
            (
                New-Object Object |
                    Add-Member -MemberType NoteProperty -Name 'Version' -Value "$($mockSqlMajorVersion).0.4001.0" -PassThru -Force
            )
        )
    }

    $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL = {
        $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
    }

    $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup = {
        $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockInstance_InstanceId\Setup"
    }

    Describe 'Testing Get-SqlMajorVersion' -Tag GetSqlMajorVersion {
        BeforeEach {
            Mock -CommandName Get-ItemProperty `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL `
                -MockWith $mockGetItemProperty_MicrosoftSQLServer_InstanceNames_SQL `
                -Verifiable

            Mock -CommandName Get-ItemProperty `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup `
                -MockWith $mockGetItemProperty_MicrosoftSQLServer_FullInstanceId_Setup `
                -Verifiable
        }

        $mockInstance_InstanceId = "MSSQL$($mockSqlMajorVersion).$($mockInstanceName)"

        Context 'When calling Get-SqlMajorVersion' {
            It 'Should return the correct major SQL version number' {
                $result = Get-SqlMajorVersion -SQLInstanceName $mockInstanceName
                $result | Should -Be $mockSqlMajorVersion

                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL

                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup
            }
        }

        Context 'When calling Get-SqlMajorVersion and nothing is returned' {
            It 'Should throw the correct error' {
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup `
                    -MockWith {
                        return New-Object Object
                    } -Verifiable

                 { Get-SqlMajorVersion -SQLInstanceName $mockInstanceName } | Should -Throw 'Could not get the SQL version for the instance ''TEST''.'

                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL

                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup
            }
        }

        Assert-VerifiableMocks
    }

    $mockApplicationDomainName = 'xSQLServerHelperTests'
    $mockApplicationDomainObject = [System.AppDomain]::CreateDomain($mockApplicationDomainName)

    <#
        It is not possible to fully test this helper function since we can't mock having the correct assembly
        in the GAC. So these test will try to load the wrong assembly and will catch the error. But that means
        it will never test the rows after if fails to load the assembly.
    #>
    Describe 'Testing Register-SqlSmo' -Tag RegisterSqlSmo {
        BeforeEach {
            Mock -CommandName Get-SqlMajorVersion -MockWith {
                return '0' # Mocking zero because that could never match a correct assembly
            } -Verifiable
        }

        Context 'When calling Register-SqlSmo to load the wrong assembly' {
            It 'Should throw with the correct error' {
                {
                    Register-SqlSmo -SQLInstanceName $mockInstanceName
                } | Should -Throw 'Exception calling "Load" with "1" argument(s): "Could not load file or assembly ''Microsoft.SqlServer.Smo, Version=0.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'' or one of its dependencies. The system cannot find the file specified."'

                Assert-MockCalled -CommandName Get-SqlMajorVersion
            }
        }

        Context 'When calling Register-SqlSmo with a application domain to load the wrong assembly' {
            It 'Should throw with the correct error' {
                {
                    Register-SqlSmo -SQLInstanceName $mockInstanceName -ApplicationDomain $mockApplicationDomainObject
                } | Should -Throw 'Exception calling "Load" with "1" argument(s): "Could not load file or assembly ''Microsoft.SqlServer.Smo, Version=0.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'' or one of its dependencies. The system cannot find the file specified."'

                Assert-MockCalled -CommandName Get-SqlMajorVersion
            }
        }

        Assert-VerifiableMocks
    }

    <#
        It is not possible to fully test this helper function since we can't mock having the correct assembly
        in the GAC. So these test will try to load the wrong assembly and will catch the error. But that means
        it will never test the rows after if fails to load the assembly.
    #>
    Describe 'Testing Register-SqlWmiManagement' -Tag RegisterSqlWmiManagement {
        BeforeEach {
            Mock -CommandName Get-SqlMajorVersion -MockWith {
                return '0' # Mocking zero because that could never match a correct assembly
            } -Verifiable

            Mock -CommandName Register-SqlSmo -MockWith {
                [System.AppDomain]::CreateDomain('xSQLServerHelper')
            } -ParameterFilter {
                $SQLInstanceName -eq $mockInstanceName
            } -Verifiable
        }

        Context 'When calling Register-SqlWmiManagement to load the wrong assembly' {
            It 'Should throw with the correct error' {
                {
                    Register-SqlWmiManagement -SQLInstanceName $mockInstanceName
                } | Should -Throw 'Exception calling "Load" with "1" argument(s): "Could not load file or assembly ''Microsoft.SqlServer.SqlWmiManagement, Version=0.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'' or one of its dependencies. The system cannot find the file specified."'

                Assert-MockCalled -CommandName Get-SqlMajorVersion
                Assert-MockCalled -CommandName Register-SqlSmo -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SQLInstanceName -eq $mockInstanceName -and $ApplicationDomain -eq $null
                }
            }
        }

        Context 'When calling Register-SqlWmiManagement with a application domain to load the wrong assembly' {
            It 'Should throw with the correct error' {
                {
                    Register-SqlWmiManagement -SQLInstanceName $mockInstanceName -ApplicationDomain $mockApplicationDomainObject
                } | Should -Throw 'Exception calling "Load" with "1" argument(s): "Could not load file or assembly ''Microsoft.SqlServer.SqlWmiManagement, Version=0.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'' or one of its dependencies. The system cannot find the file specified."'

                Assert-MockCalled -CommandName Get-SqlMajorVersion
                Assert-MockCalled -CommandName Register-SqlSmo -Exactly -Times 0 -Scope It -ParameterFilter {
                    $SQLInstanceName -eq $mockInstanceName -and $ApplicationDomain -eq $null
                }

                Assert-MockCalled -CommandName Register-SqlSmo -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SQLInstanceName -eq $mockInstanceName -and $ApplicationDomain.FriendlyName -eq $mockApplicationDomainName
                }
            }
        }

        Assert-VerifiableMocks
    }

    <#
        NOTE! This test must be after the tests for Register-SqlSmo and Register-SqlWmiManagement.
        This test unloads the application domain that is used during those tests.
    #>
    Describe 'Testing Unregister-SqlAssemblies' -Tag UnregisterSqlAssemblies {
        Context 'When calling Unregister-SqlAssemblies to unload the assemblies' {
            It 'Should not throw an error' {
                {
                    Unregister-SqlAssemblies -ApplicationDomain $mockApplicationDomainObject
                } | Should -Not -Throw
            }
        }
    }
}
