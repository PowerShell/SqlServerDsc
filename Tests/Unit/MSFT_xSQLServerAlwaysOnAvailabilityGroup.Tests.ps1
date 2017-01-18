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
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

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
    EndpointHostName = 'Server1'
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
    EndpointHostName = 'Server1'
}

$mockConnectSqlVersion12 = {
    $mock = New-Object PSObject -Property @{
        AvailabilityGroups = @{
            PresentAG = @{
                AutomatedBackupPreference = 'Secondary'
                FailureConditionLevel = 'OnServerDown'
                HealthCheckTimeout = 30000
                Name = 'AvailabilityGroup1'
                PrimaryReplica = 'Server1'
                AvailabilityReplicas = @{
                    Server1 = @{
                        AvailabilityMode = 'AsynchronousCommit'
                        BackupPriority = 50
                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointUrl = 'TCP://Server1:5022'
                        FailoverMode = 'Manual'
                    }
                }
            }
        }
        Databases = @{
            'master' = @{
                Name = 'master'
            }
        }
        Endpoints = @(
            New-Object PSObject -Property @{
                EndpointType = 'DatabaseMirroring'
                Protocol = @{
                    TCP = @{
                        ListenerPort = 5022
                    }
                }
            }
        )
        IsHadrEnabled = $true
        Logins = @{
            'NT SERVICE\ClusSvc' = @{}
            'NT AUTHORITY\SYSTEM' = @{}
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
}

$mockConnectSqlVersion13 = {
    $mock = New-Object PSObject -Property @{
        AvailabilityGroups = @{
            PresentAG = @{
                AutomatedBackupPreference = 'Secondary'
                FailureConditionLevel = 'OnServerDown'
                HealthCheckTimeout = 30000
                Name = 'AvailabilityGroup1'
                BasicAvailabilityGroup = $false
                PrimaryReplica = 'Server1'
                AvailabilityReplicas = @{
                    Server1 = @{
                        AvailabilityMode = 'AsynchronousCommit'
                        BackupPriority = 50
                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointUrl = 'TCP://Server1:5022'
                        FailoverMode = 'Manual'
                    }
                }
            }
        }
        Databases = @{
            'master' = @{
                Name = 'master'
            }
        }
        Endpoints = @(
            New-Object PSObject -Property @{
                EndpointType = 'DatabaseMirroring'
                Protocol = @{
                    TCP = @{
                        ListenerPort = 5022
                    }
                }
            }
        )
        IsHadrEnabled = $true
        Logins = @{
            'NT SERVICE\ClusSvc' = @{}
            'NT AUTHORITY\SYSTEM' = @{}
        }
        NetName = 'Server1'
        Roles = @{}
        Version = @{
            Major = 13
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
}

$mockNewSqlAvailabilityReplica = {
    #TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    $mock = return New-Object PSObject -Property @{
        AvailabilityMode = 'AsynchronousCommit'
        BackupPriority = 50
        ConnectionModeInPrimaryRole = 'AllowAllConnections'
        ConnectionModeInSecondaryRole = 'AllowNoConnections'
        EndpointUrl = 'TCP://Server1:5022'
        FailoverMode = 'Manual'
        Name = 'Server1'
    }

    # Type the mock as an Availability Replica object
    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.AvailabilityReplica')

    return $mock
}

$mockInvokeQueryClusterServiceCorrectPermissions = {
    return New-Object PSObject -Property @{
        Tables = @{
            Rows = @{
                permission_name = @(
                    'Connect SQL',
                    'Alter Any Availability Group',
                    'View Server State'
                )
            }
        }
    }
}

$mockInvokeQueryClusterServiceMissingPermissions = {
    return New-Object PSObject -Property @{
        Tables = @{
            Rows = @{
                permission_name = @(
                    'Connect SQL',
                    'View Server State'
                )
            }
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
        
        Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
        Mock -CommandName Import-SQLPSModule -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
        Mock -CommandName New-TerminatingError { $ErrorType } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the Availability Group is Absent' {

            Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName Update-AvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName Update-AvailabilityGroupReplica -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            
            It 'Should create the Availability Group when Ensure is set to Present and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'

                { Set-TargetResource @absentAg } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should create the Availability Group when Ensure is set to Present and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'
                $absentAg.BasicAvailabilityGroup = $true

                { Set-TargetResource @absentAg } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, HadrNotEnabled, when Ensure is set to Present, but Always On is not enabled' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'
                
                { Set-TargetResource @absentAg } | Should Throw 'HadrNotEnabled'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should create the Availability Group when Ensure is set to Present and NT AUTHORITY\SYSTEM has the correct permissions' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceMissingPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' } -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT AUTHORITY\\SYSTEM' } -Scope It
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'

                { Set-TargetResource @absentAg } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 2 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
            
            It 'Should throw the correct error, ClusterPermissionsMissing, when Ensure is set to Present, but the cluster does not have the correct permissions' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceMissingPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' } -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceMissingPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT AUTHORITY\\SYSTEM' } -Scope It
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'
                
                { Set-TargetResource @absentAg } | Should Throw 'ClusterPermissionsMissing'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 2 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, DatabaseMirroringEndpointNotFound, when Ensure is set to Present, but no DatabaseMirroring endpoints are present' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        AvailabilityGroups = @()
                        Endpoints = @()
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                        }
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'
                
                { Set-TargetResource @absentAg } | Should Throw 'DatabaseMirroringEndpointNotFound'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
            
            It 'Should throw the correct error, CreateAgReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is 12' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith { throw 'CreateAgReplicaFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'
                
                { Set-TargetResource @absentAg } | Should Throw 'CreateAgReplicaFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, CreateAgReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is 13' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith { throw 'CreateAgReplicaFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'
                
                { Set-TargetResource @absentAg } | Should Throw 'CreateAgReplicaFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is 12' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityGroup { throw 'CreateAvailabilityGroupFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Test-TargetResource -MockWith {$false} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $absentAg.Ensure = 'Present'
                
                { Set-TargetResource @absentAg } | Should Throw 'CreateAvailabilityGroupFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is 13' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityGroup { throw 'CreateAvailabilityGroupFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Test-TargetResource -MockWith {$false} -ModuleName $script:DSCResourceName -Scope It
                
                $absentAg.Ensure = 'Present'

                { Set-TargetResource @absentAg } | Should Throw 'CreateAvailabilityGroupFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }

        Context 'When the Availability Group is Present' {
            Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName Update-AvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName Update-AvailabilityGroupReplica -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            
            It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $presentAg.Ensure = 'Absent'
                
                { Set-TargetResource @presentAg } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $presentAg.Ensure = 'Absent'
                
                { Set-TargetResource @presentAg } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error message, InstanceNotPrimaryReplica, when Ensure is set to Absent and the primary replica is not on the current instance' {

                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplica = 'Server1'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'TCP://Server1:5022'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        IsHadrEnabled = $true
                        NetName = 'Server2'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $presentAg.Ensure = 'Absent'
                
                { Set-TargetResource @presentAg } | Should Throw 'InstanceNotPrimaryReplica'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error message when Ensure is set to Absent but the Availability Group remove fails, and the SQL version is 12' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith { throw 'RemoveAvailabilityGroupFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $presentAg.Ensure = 'Absent'
                
                { Set-TargetResource @presentAg } | Should Throw 'RemoveAvailabilityGroupFailed'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error message when Ensure is set to Absent but the Availability Group remove fails, and the SQL version is 13' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith { throw 'RemoveAvailabilityGroupFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $presentAg.Ensure = 'Absent'
                
                { Set-TargetResource @presentAg } | Should Throw 'RemoveAvailabilityGroupFailed'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should set the AutomatedBackupPreference to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.AutomatedBackupPreference = 'Primary'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should set the AvailabilityMode to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.AvailabilityMode = 'SynchronousCommit'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the BackupPriority to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.BackupPriority = 42
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the BasicAvailabilityGroup to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.BasicAvailabilityGroup = $true
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should set the ConnectionModeInPrimaryRole to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.ConnectionModeInPrimaryRole = 'AllowReadWriteConnections'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the ConnectionModeInSecondaryRole to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the EndpointUrl to the desired state when the endpoint port is changed' {

                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplica = 'Server1'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'TCP://Server1:5021'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        Endpoints = @(
                            New-Object PSObject -Property @{
                                EndpointType = 'DatabaseMirroring'
                                Protocol = @{
                                    TCP = @{
                                        ListenerPort = 5022
                                    }
                                }
                            }
                        )
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                            'NT AUTHORITY\SYSTEM' = @{}
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
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the EndpointUrl to the desired state when the EndpointHostName is specified' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.EndpointHostName = 'TestServer.Contoso.com'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the EndpointUrl to the desired state when the EndpointHostName is not specified' {

                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplica = 'Server1'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'TCP://Server1.contoso.com:5022'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        Endpoints = @(
                            New-Object PSObject -Property @{
                                EndpointType = 'DatabaseMirroring'
                                Protocol = @{
                                    TCP = @{
                                        ListenerPort = 5022
                                    }
                                }
                            }
                        )
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                            'NT AUTHORITY\SYSTEM' = @{}
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
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.Remove('EndpointHostName')
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the EndpointUrl to the desired state when the endpoint protocal is changed' {

                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplica = 'Server1'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'HTTP://Server1:5022'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        Endpoints = @(
                            New-Object PSObject -Property @{
                                EndpointType = 'DatabaseMirroring'
                                Protocol = @{
                                    TCP = @{
                                        ListenerPort = 5022
                                    }
                                }
                            }
                        )
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                            'NT AUTHORITY\SYSTEM' = @{}
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
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the FailureConditionLevel to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.FailureConditionLevel = 'OnAnyQualifiedFailureCondition'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should set the FailoverMode to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.FailoverMode = 'Automatic'
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the HealthCheckTimeout to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $presentAgIncorrectProperties = $presentAg.Clone()
                $presentAgIncorrectProperties.Ensure = 'Present'
                $presentAgIncorrectProperties.HealthCheckTimeout = 42
                
                { Set-TargetResource @presentAgIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
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
