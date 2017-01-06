$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerAlwaysOnAvailabilityGroup'

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

# Loading stub cmdlets
Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force

$absentAg = @{
    Name = 'AbsentAG'
    SQLInstanceName = 'MSSQLSERVER'
    SQLServer = 'Server1'
    Ensure = 'Present'
    AutomatedBackupPreference = 'Secondary'
    AvailabilityMode = 'AsynchronousCommit'
    BackupPriority = 50
    BasicAvailabilityGroup = $false
    ConnectionModeInPrimaryRole = 'AllowAllConnections'
    ConnectionModeInSecondaryRole = 'AllowNoConnections'
    FailureConditionLevel = 'OnServerDown'
    FailoverMode = 'Manual'
    HealthCheckTimeout = '30000'
}

$presentAg = @{
    Name = 'PresentAG'
    SQLInstanceName = 'MSSQLSERVER'
    SQLServer = 'Server1'
    Ensure = 'Present'
    AutomatedBackupPreference = 'Secondary'
    AvailabilityMode = 'AsynchronousCommit'
    BackupPriority = 50
    BasicAvailabilityGroup = $false
    ConnectionModeInPrimaryRole = 'AllowAllConnections'
    ConnectionModeInSecondaryRole = 'AllowNoConnections'
    FailureConditionLevel = 'OnServerDown'
    FailoverMode = 'Manual'
    HealthCheckTimeout = '30000'
}

$createAg = @{
    Name = 'AvailabilityGroup1'
    SQLInstanceName = 'MSSQLSERVER'
    SQLServer = 'Server1'
    Ensure = 'Present'
    AutomatedBackupPreference = 'Secondary'
    AvailabilityMode = 'AsynchronousCommit'
    BackupPriority = 50
    BasicAvailabilityGroup = $false
    ConnectionModeInPrimaryRole = 'AllowAllConnections'
    ConnectionModeInSecondaryRole = 'AllowNoConnections'
    FailureConditionLevel = 'OnServerDown'
    FailoverMode = 'Manual'
    HealthCheckTimeout = '30000'
}

$createAgReplicaInvalidParameter = @{
    Name = 'AvailabilityGroup1'
    SQLInstanceName = 'MSSQLSERVER'
    SQLServer = 'Server1'
    Ensure = 'Present'
    AutomatedBackupPreference = 'Secondary'
    AvailabilityMode = 'InvalidParameter'
    BackupPriority = 50
    BasicAvailabilityGroup = $false
    ConnectionModeInPrimaryRole = 'AllowAllConnections'
    ConnectionModeInSecondaryRole = 'AllowNoConnections'
    FailureConditionLevel = 'OnServerDown'
    FailoverMode = 'Manual'
    HealthCheckTimeout = '30000'
}

$createAgInvalidParameter = @{
    Name = 'AvailabilityGroup1'
    SQLInstanceName = 'MSSQLSERVER'
    SQLServer = 'Server1'
    Ensure = 'Present'
    AutomatedBackupPreference = 'InvalidParameter'
    AvailabilityMode = 'AsynchronousCommit'
    BackupPriority = 50
    BasicAvailabilityGroup = $false
    ConnectionModeInPrimaryRole = 'AllowAllConnections'
    ConnectionModeInSecondaryRole = 'AllowNoConnections'
    FailureConditionLevel = 'OnServerDown'
    FailoverMode = 'Manual'
    HealthCheckTimeout = '30000'
}

$removeAg = @{
    Name = 'AvailabilityGroup1'
    SQLInstanceName = 'MSSQLSERVER'
    SQLServer = 'Server1'
    Ensure = 'Absent'
}


$mockConnectSqlVersion12 = {
    New-Object PSObject -Property @{
        AvailabilityGroups = @{
            PresentAG = @{
                AutomatedBackupPreference = 'Secondary'
                FailureConditionLevel = 'OnServerDown'
                HealthCheckTimeout = 30000
                Name = 'AvailabilityGroup1'
                AvailabilityReplicas = @{
                    Server1 = @{
                        AvailabilityMode = 'AsynchronousCommit'
                        BackupPriority = 50
                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        FailoverMode = 'Manual'
                    }
                }
            }
        }
        Version = @{
            Major = 12
        }
    }
}

$mockConnectSqlVersion13 = {
    New-Object PSObject -Property @{
        AvailabilityGroups = @{
            PresentAG = @{
                AutomatedBackupPreference = 'Secondary'
                FailureConditionLevel = 'OnServerDown'
                HealthCheckTimeout = 30000
                Name = 'AvailabilityGroup1'
                BasicAvailabilityGroup = $false
                AvailabilityReplicas = @{
                    Server1 = @{
                        AvailabilityMode = 'AsynchronousCommit'
                        BackupPriority = 50
                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        FailoverMode = 'Manual'
                    }
                }
            }
        }
        Version = @{
            Major = 13
        }
    }
}

# Begin Testing
try
{
    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        
        Context 'When the Availability Group is Absent'{

            It 'Should not return an Availability Group when Ensure is Present and the version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $getParams = @{
                    Name = $absentAg.Name
                    SQLServer = $absentAg.SQLServer
                    SQLInstanceName = $absentAg.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Ensure | Should Be 'Absent'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should not return an Availability Group when Ensure is Present and the version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $getParams = @{
                    Name = $absentAg.Name
                    SQLServer = $absentAg.SQLServer
                    SQLInstanceName = $absentAg.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Ensure | Should Be 'Absent'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }

        Context 'When the Availability Group is Present'{

            It 'Should return the Availability Group properties when Ensure is Present and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $getParams = @{
                    Name = $presentAg.Name
                    SQLServer = $presentAg.SQLServer
                    SQLInstanceName = $presentAg.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Name | Should Be $presentAg.Name
                $result.SQLServer | Should Be $presentAg.SQLServer
                $result.SQLInstanceName | Should Be $presentAg.SQLInstanceName
                $result.Ensure | Should Be 'Present'
                $result.AutomatedBackupPreference | Should Not Be $null
                $result.AvailabilityMode | Should Not Be $null
                $result.BackupPriority | Should Not Be $null
                $result.ConnectionModeInPrimaryRole | Should Not Be $null
                $result.ConnectionModeInSecondaryRole | Should Not Be $null
                $result.FailureConditionLevel | Should Not Be $null
                $result.FailoverMode | Should Not Be $null
                $result.HealthCheckTimeout | Should Not Be $null
                $result.BasicAvailabilityGroup | Should Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return the Availability Group properties when Ensure is Absent and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $getParams = @{
                    Name = $presentAg.Name
                    SQLServer = $presentAg.SQLServer
                    SQLInstanceName = $presentAg.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Name | Should Be $presentAg.Name
                $result.SQLServer | Should Be $presentAg.SQLServer
                $result.SQLInstanceName | Should Be $presentAg.SQLInstanceName
                $result.Ensure | Should Be 'Present'
                $result.AutomatedBackupPreference | Should Not Be $null
                $result.AvailabilityMode | Should Not Be $null
                $result.BackupPriority | Should Not Be $null
                $result.ConnectionModeInPrimaryRole | Should Not Be $null
                $result.ConnectionModeInSecondaryRole | Should Not Be $null
                $result.FailureConditionLevel | Should Not Be $null
                $result.FailoverMode | Should Not Be $null
                $result.HealthCheckTimeout | Should Not Be $null
                $result.BasicAvailabilityGroup | Should Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return the Availability Group properties when Ensure is Present and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $getParams = @{
                    Name = $presentAg.Name
                    SQLServer = $presentAg.SQLServer
                    SQLInstanceName = $presentAg.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Name | Should Be $presentAg.Name
                $result.SQLServer | Should Be $presentAg.SQLServer
                $result.SQLInstanceName | Should Be $presentAg.SQLInstanceName
                $result.Ensure | Should Be 'Present'
                $result.AutomatedBackupPreference | Should Not Be $null
                $result.AvailabilityMode | Should Not Be $null
                $result.BackupPriority | Should Not Be $null
                $result.ConnectionModeInPrimaryRole | Should Not Be $null
                $result.ConnectionModeInSecondaryRole | Should Not Be $null
                $result.FailureConditionLevel | Should Not Be $null
                $result.FailoverMode | Should Not Be $null
                $result.HealthCheckTimeout | Should Not Be $null
                $result.BasicAvailabilityGroup | Should Not Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return the Availability Group properties when Ensure is Absent and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $getParams = @{
                    Name = $presentAg.Name
                    SQLServer = $presentAg.SQLServer
                    SQLInstanceName = $presentAg.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Name | Should Be $presentAg.Name
                $result.SQLServer | Should Be $presentAg.SQLServer
                $result.SQLInstanceName | Should Be $presentAg.SQLInstanceName
                $result.Ensure | Should Be 'Present'
                $result.AutomatedBackupPreference | Should Not Be $null
                $result.AvailabilityMode | Should Not Be $null
                $result.BackupPriority | Should Not Be $null
                $result.ConnectionModeInPrimaryRole | Should Not Be $null
                $result.ConnectionModeInSecondaryRole | Should Not Be $null
                $result.FailureConditionLevel | Should Not Be $null
                $result.FailoverMode | Should Not Be $null
                $result.HealthCheckTimeout | Should Not Be $null
                $result.BasicAvailabilityGroup | Should Not Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        
        Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName
        Mock -CommandName Import-SQLPSModule -MockWith {} -ModuleName $script:DSCResourceName
        Mock -CommandName New-SqlAvailabilityReplica -MockWith {
            #TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            return New-Object PSObject -Property @{
                AvailabilityMode = 'AsynchronousCommit'
                BackupPriority = 50
                ConnectionModeInPrimaryRole = 'AllowAllConnections'
                ConnectionModeInSecondaryRole = 'AllowNoConnections'
                EndpointUrl = 'TCP://Server1:5022'
                FailoverMode = 'Manual'
                Name = 'Server1'
            }
        } -ModuleName $script:DSCResourceName -Verifiable -Scope Context
        Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable
        Mock -CommandName New-TerminatingError { $ErrorType } -ModuleName $script:DSCResourceName

        Context 'When the Availability Group is Absent' {
            
            It 'Should create the Availability Group when Ensure is set to Present' {

                Mock -CommandName Connect-SQL -MockWith {
                    $mock =  New-Object PSObject -Property @{ 
                        AvailabilityGroups = @{}
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                        }
                        NetName = 'Server1'
                        Roles = @{}
                        Version = @{
                            Major = 12
                        }
                    }

                    # Add the ExecuteWithResults method
                    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
                        return New-Object PSObject -Property @{
                            Tables = @{
                                Rows = @{
                                    permission_name = @(
                                        'testing'
                                    )
                                }
                            }
                        }
                    }

                    # Type the mock as a server object
                    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It

                Mock -CommandName Test-TargetResource -MockWith {$true} -ModuleName $script:DSCResourceName -Scope It
                
                Set-TargetResource @createAg

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Test-TargetResource -Scope It -Times 1
            }

            It 'Should throw HadrNotEnabled when Ensure is set to Present, but Always On is not enabled' {

                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                { Set-TargetResource @createAg } | Should Throw 'HadrNotEnabled'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
            }
            
            It 'Should throw CreateAgReplicaFailed when Ensure is set to Present, but the Availability Group Replica failed to create' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        AvailabilityGroups = @{}
                        IsHadrEnabled = $true
                        NetName = 'Server1'
                        Version = @{
                            Major = 12
                        }
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It

                Mock -CommandName Test-TargetResource -MockWith {$false} -ModuleName $script:DSCResourceName -Scope It
                
                { Set-TargetResource @createAgReplicaInvalidParameter } | Should Throw 'CreateAgReplicaFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
            }

            It 'Should throw CreateAvailabilityGroupFailed when Ensure is set to Present, but the Availability Group failed to create' {
                
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        AvailabilityGroups = @{}
                        IsHadrEnabled = $true
                        NetName = 'Server1'
                        Version = @{
                            Major = 12
                        }
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It

                Mock -CommandName Test-TargetResource -MockWith {$false} -ModuleName $script:DSCResourceName -Scope It
                
                { Set-TargetResource @createAgInvalidParameter } | Should Throw 'CreateAvailabilityGroupFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
            }

            It 'Should throw the correct error message when Ensure is set to Present, but the Availability Group properties are incorrect' {
                
                { Set-TargetResource @createAg } | Should Throw 'CreateAvailabilityGroupFailedWithIncorrectProperties'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
            }
        }

        Context 'When the Availability Group is Present' {

            Mock -CommandName Connect-SQL -MockWith {
                return New-Object PSObject -Property @{ 
                    AvailabilityGroups = @{
                        AvailabilityGroup1 = @{
                            AutomatedBackupPreference = 'Secondary'
                            FailureConditionLevel = 'OnServerDown'
                            HealthCheckTimeout = 30000
                            Name = 'AvailabilityGroup1'
                            AvailabilityReplicas = @{
                                Server1 = @{
                                    AvailabilityMode = 'AsynchronousCommit'
                                    BackupPriority = 50
                                    ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                    ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                    FailoverMode = 'Manual'
                                }
                            }
                        }
                    }
                    NetName = 'Server1'
                    Version = @{
                        Major = 12
                    }
                }
            } -ModuleName $script:DSCResourceName -Verifiable -Scope Context

            It 'Should remove the Availability Group when Ensure is set to Absent' {

                Set-TargetResource @removeAg
            }

            It 'Should correct incorrect properties when Ensure is set to Present' {

                Set-TargetResource @createAg
            }

            It 'Should throw the correct error message when Ensure is set to Absent, but the Availability Group has not been removed' {
                
                { Set-TargetResource @removeAg } | Should Throw 'RemoveAvailabilityGroupFailed'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
            }

            It 'Should throw the correct error message when Ensure is set to Present, but the Availability Group properties are incorrect' {
                
                { Set-TargetResource @createAg } | Should Throw 'AvailabilityGroupFailedWithIncorrectProperties'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        
        Context 'When the Availability Group is Absent' {

            It 'Should be $false when the desired state is Present and the SQL version is 12' {

                $absentAg.Ensure = 'Present'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @absentAg | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Absent and the SQL version is 12' {

                $absentAg.Ensure = 'Absent'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                Test-TargetResource @absentAg | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $false when the desired state is Present and the SQL version is 13' {

                $absentAg.Ensure = 'Present'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @absentAg | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Absent and the SQL version is 13' {

                $absentAg.Ensure = 'Absent'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                Test-TargetResource @absentAg | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }

        Context 'When the Availability Group is Present' {

            It 'Should be $false when the desired state is Absent and the SQL version is 12' {

                $presentAg.Ensure = 'Absent'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @presentAg | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Present and the SQL version is 12' {
                
                $presentAg.Ensure = 'Present'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @presentAg | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 2 -Exactly
            }

            It 'Should be $false when the desired state is Present, there is a parameter not correctly set, and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $presentAgIncorrectParameter = $presentAg.Clone()
                $presentAgIncorrectParameter.Ensure = 'Present'
                $presentAgIncorrectParameter.AvailabilityMode = 'SynchronousCommit'
                
                Test-TargetResource @presentAgIncorrectParameter | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 2 -Exactly
            }

            It 'Should be $false when the desired state is Absent and the SQL version is 13' {

                $presentAg.Ensure = 'Absent'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @presentAg | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Present and the SQL version is 13' {
                
                $presentAg.Ensure = 'Present'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @presentAg | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $false when the desired state is Present, there is a parameter not correctly set, and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $presentAgIncorrectParameter = $presentAg.Clone()
                $presentAgIncorrectParameter.Ensure = 'Present'
                $presentAgIncorrectParameter.AvailabilityMode = 'SynchronousCommit'
                $presentAgIncorrectParameter.BasicAvailabilityGroup = $true
                
                Test-TargetResource @presentAgIncorrectParameter | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 2 -Exactly
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}