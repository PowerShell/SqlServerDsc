#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xSQLServer' `
    -DSCResourceName 'MSFT_xSQLServerAlwaysOnAvailabilityGroupReplica' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    # TODO: Optional init code goes here...
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    # TODO: Other Optional Cleanup Code Goes Here...
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xSQLServerAlwaysOnAvailabilityGroupReplica' {
        
        $mockSqlServer = 'Server2'
        $mockSqlInstanceName = 'MSSQLSERVER'
        $mockAvailabilityGroupName = 'AvailabilityGroup1'
        $mockAvailabilityGroupReplicaName = $mockSqlServer
        $mockEnsure = 'Present'
        $mockAvailabilityMode = 'AsynchronousCommit'
        $mockBackupPriority = 50
        $mockConnectionModeInPrimaryRole = 'AllowAllConnections'
        $mockConnectionModeInSecondaryRole = 'AllowNoConnections'
        $mockEndpointHostName = $mockSqlServer
        $mockEndpointPort = 5022
        $mockEndpointProtocol = 'TCP'
        $mockEndpointUrl = "$($mockEndpointProtocol)://$($mockSqlServer):$($mockEndpointPort)"
        $mockFailoverMode = 'Manual'
        $mockIsHadrEnabled = $true
        $mockLocalReplicaRole = 'Secondary'
        $mockPrimaryReplicaSQLServer = 'Server1'
        $mockPrimaryReplicaSQLInstanceName = 'MSSQLSERVER'
        $mockReadOnlyRoutingConnectionUrl = ''
        $mockReadOnlyRoutingList = @()

        #region Login mocks

        $mockNtServiceClusSvcName = 'NT SERVICE\ClusSvc'
        $mockNtAuthoritySystemName = 'NT AUTHORITY\SYSTEM'

        $mockAllLoginsAbsent = @{}

        $mockNtServiceClusSvcPresent = @{
            $mockNtServiceClusSvcName = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockSqlServer,$mockNtServiceClusSvcName) )
        }

        $mockNtAuthoritySystemPresent = @{
            $mockNtAuthoritySystemName = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockSqlServer,$mockNtAuthoritySystemName) )
        }

        $mockAllLoginsPresent = @{
            $mockNtServiceClusSvcName = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockSqlServer,$mockNtServiceClusSvcName) )
            $mockNtAuthoritySystemName = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockSqlServer,$mockNtAuthoritySystemName) )
        }

        #endregion

        $mockDatabaseMirroringEndpointMissing = @()

        $mockDatabaseMirroringEndpointPresent = @(
            (
                New-Object Object |
                    Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value 'DatabaseMirroring' -PassThru |
                    Add-Member ScriptProperty Protocol {
                        return @(
                            (
                                New-Object Object |
                                    Add-Member -MemberType ScriptProperty -Name TCP {
                                        return @(
                                            (
                                                New-Object Object |
                                                    Add-Member -MemberType NoteProperty -Value $mockEndpointPort -PassThru -Force
                                            )
                                        )
                                    } -PassThru -Force
                            )
                        )
                    } -PassThru -Force
            )
        )
        
        #region Function mocks

        $mockLogins = @{} # Will be dynamically set during tests
        $mockEndpoint = @() # Will be dynamically set during tests

        $mockConnectSql = {
            $mock = @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockSqlServer -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'NetName' -Value $mockSqlServer -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsHadrEnabled' -Value $mockIsHadrEnabled -PassThru |
                        Add-Member ScriptProperty Logins {
                            return $mockLogins
                        } -PassThru -Force |
                        Add-Member ScriptProperty AvailabilityGroups {
                            return @{
                                $mockAvailabilityGroupName = ( 
                                    New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroupName -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockPrimaryReplicaSQLInstanceName -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value $mockLocalReplicaRole -PassThru |
                                    Add-Member ScriptProperty AvailabilityReplicas {
                                        $mockAvailabilityGroupReplica = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica.AvailabilityMode = $mockAvailabilityMode
                                        $mockAvailabilityGroupReplica.BackupPriority = $mockBackupPriority
                                        $mockAvailabilityGroupReplica.ConnectionModeInPrimaryRole = $mockConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica.ConnectionModeInSecondaryRole = $mockConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica.EndpointUrl = $mockEndpointUrl
                                        $mockAvailabilityGroupReplica.FailoverMode = $mockFailoverMode
                                        $mockAvailabilityGroupReplica.Name = $mockAvailabilityGroupReplicaName
                                        $mockAvailabilityGroupReplica.ReadOnlyRoutingConnectionUrl = $mockReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica.ReadOnlyRoutingList = $mockReadOnlyRoutingList

                                        return @{
                                            $mockAvailabilityGroupReplicaName = $mockAvailabilityGroupReplica
                                        }
                                    } -PassThru -Force
                                )
                            }
                        } -PassThru -Force | 
                        Add-Member ScriptProperty Endpoints {
                            return $mockEndpoint
                        } -PassThru -Force
                )
            )

            # Type the mock as a server object
            $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

            return $mock
        }

        #endregion

        Describe 'xSQLServerAlwaysOnAvailabilityGroupReplica\Get-TargetResource' {
            BeforeEach {
                $mockLogins = @{} # Reset the logins

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'Context-description' {
                BeforeEach {
                    # per-test-initialization
                }

                AfterEach {
                    # per-test-cleanup
                }

                It 'Should...test-description' {
                    # test-code
                }

                It 'Should...test-description' {
                    # test-code
                }
            }

            Context 'Context-description' {
                It 'Should ....test-description' {
                    # test-code
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupReplica\Set-TargetResource' {
            Context '<Context-description>' {
                It 'Should ...test-description' {
                    # test-code
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupReplica\Test-TargetResource' {
            Context '<Context-description>' {
                It 'Should ...test-description' {
                    # test-code
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}