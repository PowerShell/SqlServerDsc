$script:ModuleName = 'xSQLServerHelper'

Import-Module (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent) -ChildPath 'xSQLServerHelper.psm1') -Scope Global -Force

Describe "$($script:ModuleName)\Restart-SqlService" {

    Mock -CommandName New-VerboseMessage -MockWith { Write-Host $Message }

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
<#
    Context 'Restart-SqlService clustered instance' {
        
        Mock -CommandName Connect-SQL -MockWith {
            return @{
                Name = 'MSSQLSERVER'
                InstanceName = ''
                ServiceName = 'MSSQLSERVER'
                IsClustered = $true
            }
        } -ModuleName $script:ModuleName -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'MSSQLSERVER') }

        Mock -CommandName Connect-SQL -MockWith {
            return @{
                Name = 'NAMEDINSTANCE'
                InstanceName = 'NAMEDINSTANCE'
                ServiceName = 'NAMEDINSTANCE'
                IsClustered = $true
            }
        } -ModuleName $script:ModuleName -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'NAMEDINSTANCE') }

        Mock -CommandName Connect-SQL -MockWith {
            return @{
                Name = 'STOPPEDAGENT'
                InstanceName = 'STOPPEDAGENT'
                ServiceName = 'STOPPEDAGENT'
                IsClustered = $true
            }
        } -ModuleName $script:ModuleName -Verifiable -ParameterFilter { ($SQLServer -eq 'CLU01') -and ($SQLInstanceName -eq 'STOPPEDAGENT') }

        ## Mock Get-WmiObject for SQL Instance
        Mock -CommandName Get-WmiObject {
            return @('MSSQLSERVER','NAMEDINSTANCE','STOPPEDAGENT') | ForEach-Object {
                $mock = New-Object PSObject -Property @{
                    Name = "SQL Server ($($_))"
                    PrivateProperties = @{
                        InstanceName = $_
                    }
                }

                $mock | Add-Member -MemberType ScriptMethod -Name TakeOffline -Value { param ( [int] $Timeout ) }
                $mock | Add-Member -MemberType ScriptMethod -Name BringOnline -Value { param ( [int] $Timeout ) }

                return $mock
            }
        } -ModuleName $script:ModuleName -Verifiable -ParameterFilter { $Filter -imatch "Type = 'SQL Server'" }

        ## Mock Get-WmiObject for SQL Agent
        Mock -CommandName Get-WmiObject {
            if ($Query -imatch 'SQL Server \((\w+)\)')
            {
                $serviceName = $Matches[1]

                $mock = New-Object PSObject -Property @{
                    Name = "SQL Server Agent ($serviceName)"
                    Type = 'SQL Server Agent'
                    State = (@{ $true = 3; $false = 2 }[($serviceName -eq 'STOPPEDAGENT')])
                }

                $mock | Add-Member -MemberType ScriptMethod -Name TakeOffline -Value { param ( [int] $Timeout ) }
                $mock | Add-Member -MemberType ScriptMethod -Name BringOnline -Value { param ( [int] $Timeout ) }

                return $mock 
            }
        } -ModuleName $script:ModuleName -Verifiable -ParameterFilter { $Query -match '^ASSOCIATORS OF' }

        It 'Should restart SQL Server and SQL Agent resources for a clustered default instance' {
            { Restart-SqlService -SQLServer 'CLU01' -SQLInstanceName 'MSSQLSERVER' } | Should Not Throw
            
            Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
            Assert-MockCalled -CommandName Get-WmiObject -Scope It -Exactly -Times 2

            ## 5 Verbose Messages equates to Get SQL, Get Agent, Stop SQL, Start SQL, Start Agent
            Assert-MockCalled -CommandName New-VerboseMessage -Scope It -Exactly -Times 5
        }

        It 'Should restart SQL Server and SQL Agent resources for a clustered named instance' {
            { Restart-SqlService -SQLServer 'CLU01' -SQLInstanceName 'NAMEDINSTANCE' } | Should Not Throw

            Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
            Assert-MockCalled -CommandName Get-WmiObject -Scope It -Exactly -Times 2

            ## 5 Verbose Messages equates to Get SQL, Get Agent, Stop SQL, Start SQL, Start Agent
            Assert-MockCalled -CommandName New-VerboseMessage -Scope It -Exactly -Times 5
        }

        It 'Should not try to restart a SQL Agent resource that is not online' {
            { Restart-SqlService -SQLServer 'CLU01' -SQLInstanceName 'STOPPEDAGENT' } | Should Not Throw

            Assert-MockCalled -CommandName Connect-SQL -Scope It -Exactly -Times 1
            Assert-MockCalled -CommandName Get-WmiObject -Scope It -Exactly -Times 2

            ## 4 Verbose Messages equates to Get SQL, Get Agent, Stop SQL, Start SQL
            Assert-MockCalled -CommandName New-VerboseMessage -Scope It -Exactly -Times 4
        }
    }
#>
}
