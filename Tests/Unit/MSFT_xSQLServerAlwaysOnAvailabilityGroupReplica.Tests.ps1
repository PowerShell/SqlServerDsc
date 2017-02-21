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
        $mockPrimaryReplicaSQLServer = 'Server1'
        $mockPrimaryReplicaSQLInstanceName = 'MSSQLSERVER'
        $mockAvailabilityGroupName = 'AvailabilityGroup1'
        $mockAbsentAvailabilityGroupName = 'AvailabilityGroup2'
        $mockAvailabilityGroupReplicaName = $mockPrimaryReplicaSQLServer
        $mockEnsure = 'Present'
        $mockAvailabilityMode = 'AsynchronousCommit'
        $mockBackupPriority = 50
        $mockConnectionModeInPrimaryRole = 'AllowAllConnections'
        $mockConnectionModeInSecondaryRole = 'AllowNoConnections'
        $mockEndpointHostName = $mockSqlServer
        $mockEndpointPort = 5022
        $mockEndpointProtocol = 'TCP'
        $mockEndpointProtocolIncorrect = 'UDP'
        $mockEndpointUrl = "$($mockEndpointProtocol)://$($mockSqlServer):$($mockEndpointPort)"
        $mockEndpointUrlIncorrectProtocol = "$($mockEndpointProtocolIncorrect)://$($mockSqlServer):$($mockEndpointPort)"
        $mockFailoverMode = 'Manual'
        $mockIsHadrEnabled = $true
        $mockLocalReplicaRole = 'Secondary'
        $mockReadOnlyRoutingConnectionUrl = ''
        $mockReadOnlyRoutingList = @()

        #region Login mocks

        $mockLogins = @{} # Will be dynamically set during tests
        
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

        #region Endpoint mocks

        $mockEndpoint = @() # Will be dynamically set during tests

        $mockDatabaseMirroringEndpointAbsent = @()

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
                                                    Add-Member -MemberType NoteProperty -Name ListenerPort -Value $mockEndpointPort -PassThru -Force
                                            )
                                        )
                                    } -PassThru -Force
                            )
                        )
                    } -PassThru -Force
            )
        )

        #endregion

        #region Availability Group Replica mocks

        $mockAvailabilityGroupReplica = @{}

        $mockAvailabilityGroupReplicaPrimaryObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
        $mockAvailabilityGroupReplicaPrimaryObject.AvailabilityMode = $mockAvailabilityMode
        $mockAvailabilityGroupReplicaPrimaryObject.BackupPriority = $mockBackupPriority
        $mockAvailabilityGroupReplicaPrimaryObject.ConnectionModeInPrimaryRole = $mockConnectionModeInPrimaryRole
        $mockAvailabilityGroupReplicaPrimaryObject.ConnectionModeInSecondaryRole = $mockConnectionModeInSecondaryRole
        $mockAvailabilityGroupReplicaPrimaryObject.EndpointUrl = $mockEndpointUrl
        $mockAvailabilityGroupReplicaPrimaryObject.FailoverMode = $mockFailoverMode
        $mockAvailabilityGroupReplicaPrimaryObject.Name = $mockAvailabilityGroupReplicaName
        $mockAvailabilityGroupReplicaPrimaryObject.ReadOnlyRoutingConnectionUrl = $mockReadOnlyRoutingConnectionUrl
        $mockAvailabilityGroupReplicaPrimaryObject.ReadOnlyRoutingList = $mockReadOnlyRoutingList

        $mockAvailabilityGroupReplicasPrimary = @{
            $mockAvailabilityGroupReplicaName = $mockAvailabilityGroupReplicaPrimaryObject
        }

        $mockAvailabilityGroupReplicaSecondaryObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
        $mockAvailabilityGroupReplicaSecondaryObject.AvailabilityMode = $mockAvailabilityMode
        $mockAvailabilityGroupReplicaSecondaryObject.BackupPriority = $mockBackupPriority
        $mockAvailabilityGroupReplicaSecondaryObject.ConnectionModeInPrimaryRole = $mockConnectionModeInPrimaryRole
        $mockAvailabilityGroupReplicaSecondaryObject.ConnectionModeInSecondaryRole = $mockConnectionModeInSecondaryRole
        $mockAvailabilityGroupReplicaSecondaryObject.EndpointUrl = $mockEndpointUrl
        $mockAvailabilityGroupReplicaSecondaryObject.FailoverMode = $mockFailoverMode
        $mockAvailabilityGroupReplicaSecondaryObject.Name = $mockSqlServer
        $mockAvailabilityGroupReplicaSecondaryObject.ReadOnlyRoutingConnectionUrl = $mockReadOnlyRoutingConnectionUrl
        $mockAvailabilityGroupReplicaSecondaryObject.ReadOnlyRoutingList = $mockReadOnlyRoutingList

        $mockAvailabilityGroupReplicasAll = $mockAvailabilityGroupReplicasPrimary.Clone()
        $mockAvailabilityGroupReplicasAll.Add($mockSqlServer,$mockAvailabilityGroupReplicaSecondaryObject)

        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.AvailabilityMode = $mockAvailabilityMode
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.BackupPriority = $mockBackupPriority
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.ConnectionModeInPrimaryRole = $mockConnectionModeInPrimaryRole
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.ConnectionModeInSecondaryRole = $mockConnectionModeInSecondaryRole
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.EndpointUrl = $mockEndpointUrlIncorrectProtocol
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.FailoverMode = $mockFailoverMode
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.Name = $mockSqlServer
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.ReadOnlyRoutingConnectionUrl = $mockReadOnlyRoutingConnectionUrl
        $mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl.ReadOnlyRoutingList = $mockReadOnlyRoutingList

        $mockAvailabilityGroupReplicasAllIncorrectProtocolInEndpointUrl = $mockAvailabilityGroupReplicasPrimary.Clone()
        $mockAvailabilityGroupReplicasAllIncorrectProtocolInEndpointUrl.Add($mockSqlServer,$mockAvailabilityGroupReplicasIncorrectProtocolInEndpointUrl)

        #endregion
        
        #region Function mocks

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
                                        return $mockAvailabilityGroupReplica
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
                $getTargetResourceParameters = @{
                    Name = $mockSqlServer
                    AvailabilityGroupName = $mockAvailabilityGroupName
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockSqlInstanceName
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the Availability Group Replica is absent' {

                $mockEnsure = 'Absent'

                It 'Should not return an Availability Group Replica' {
                    
                    $getTargetResourceParameters.AvailabilityGroupName = $mockAbsentAvailabilityGroupName
                    $mockAvailabilityGroupName = $mockAbsentAvailabilityGroupName
                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasPrimary
                    $mockEndpoint = $mockDatabaseMirroringEndpointPresent
                    
                    
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.AvailabilityGroupName | Should Be $mockAvailabilityGroupName
                    $getTargetResourceResult.AvailabilityMode | Should BeNullOrEmpty
                    $getTargetResourceResult.BackupPriority | Should BeNullOrEmpty
                    $getTargetResourceResult.ConnectionModeInPrimaryRole | Should BeNullOrEmpty
                    $getTargetResourceResult.ConnectionModeInSecondaryRole | Should BeNullOrEmpty
                    $getTargetResourceResult.EndpointUrl | Should BeNullOrEmpty
                    $getTargetResourceResult.EndpointPort | Should Be 5022
                    $getTargetResourceResult.Ensure | Should Be $mockEnsure
                    $getTargetResourceResult.FailoverMode | Should BeNullOrEmpty
                    $getTargetResourceResult.Name | Should BeNullOrEmpty
                    $getTargetResourceResult.ReadOnlyConnectionUrl | Should BeNullOrEmpty
                    $getTargetResourceResult.ReadOnlyRoutingList | Should BeNullOrEmpty
                    $getTargetResourceResult.SQLServer | Should Be $mockSqlServer
                    $getTargetResourceResult.SQLInstanceName | Should Be $mockSqlInstanceName
                    $getTargetResourceResult.SQLServerNetName | Should Be $mockSqlServer

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group Replica is present' {

                $mockEnsure = 'Present'

                It 'Should return an Availability Group Replica' {
                    
                    $mockAvailabilityGroupName = 'AvailabilityGroup1'
                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasAll
                    $mockEndpoint = $mockDatabaseMirroringEndpointPresent
                    
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.AvailabilityGroupName | Should Be $mockAvailabilityGroupName
                    $getTargetResourceResult.AvailabilityMode | Should Be $mockAvailabilityMode
                    $getTargetResourceResult.BackupPriority | Should Be $mockBackupPriority
                    $getTargetResourceResult.ConnectionModeInPrimaryRole | Should Be $mockConnectionModeInPrimaryRole
                    $getTargetResourceResult.ConnectionModeInSecondaryRole | Should Be $mockConnectionModeInSecondaryRole
                    $getTargetResourceResult.EndpointUrl | Should Be $mockEndpointUrl
                    $getTargetResourceResult.EndpointPort | Should Be $mockEndpointPort
                    $getTargetResourceResult.Ensure | Should Be $mockEnsure
                    $getTargetResourceResult.FailoverMode | Should Be $mockFailoverMode
                    $getTargetResourceResult.Name | Should Be $mockSqlServer
                    $getTargetResourceResult.ReadOnlyConnectionUrl | Should BeNullOrEmpty
                    $getTargetResourceResult.ReadOnlyRoutingList | Should BeNullOrEmpty
                    $getTargetResourceResult.SQLServer | Should Be $mockSqlServer
                    $getTargetResourceResult.SQLInstanceName | Should Be $mockSqlInstanceName
                    $getTargetResourceResult.SQLServerNetName | Should Be $mockSqlServer

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
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

            BeforeEach {            
                $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasAll
                $mockEndpoint = $mockDatabaseMirroringEndpointPresent
                
                $testTargetResourceParameters = @{
                    Name = $mockSqlServer
                    AvailabilityGroupName = $mockAvailabilityGroupName
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockSqlInstanceName
                    PrimaryReplicaSQLServer = $mockPrimaryReplicaSQLServer
                    PrimaryReplicaSQLInstanceName = $mockPrimaryReplicaSQLInstanceName
                    Ensure = $mockEnsure
                    AvailabilityMode = $mockAvailabilityMode
                    BackupPriority = $mockBackupPriority
                    ConnectionModeInPrimaryRole = $mockConnectionModeInPrimaryRole
                    ConnectionModeInSecondaryRole = $mockConnectionModeInSecondaryRole
                    EndpointHostName = $mockEndpointHostName
                    FailoverMode = $mockFailoverMode
                    ReadOnlyRoutingConnectionUrl = $mockReadOnlyRoutingConnectionUrl
                    ReadOnlyRoutingList = $mockReadOnlyRoutingList
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the desired state is absent' {
                
                It 'Should return $true when the Availability Replica is absent' {

                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasPrimary
                    $testTargetResourceParameters.Ensure = 'Absent'
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present' {

                    $testTargetResourceParameters.Ensure = 'Absent'
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the desired state is present' {

                It 'Should return $false when the Availability Replica is absent' {

                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasPrimary
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the Availability Replica is present' {

                    Test-TargetResource @testTargetResourceParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present and the Availabiltiy Mode is not in the desired state' {

                    $testTargetResourceParameters.AvailabilityMode = 'SynchronousCommit'
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the Availability Replica is present and the Endpoint Hostname is not specified' {

                    $testTargetResourceParameters.EndpointHostName = ''
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present and the Endpoint Hostname is not in the desired state' {

                    $testTargetResourceParameters.EndpointHostName = 'OtherHostName'
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present and the Endpoint Protocol is not in the desired state' {

                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasAllIncorrectProtocolInEndpointUrl
                    $mockEndpoint = $mockDatabaseMirroringEndpointPresentIncorrectProtocol
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}