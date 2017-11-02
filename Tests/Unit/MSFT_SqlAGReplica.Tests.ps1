#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'SqlServerDSC' `
    -DSCResourceName 'MSFT_SqlAGReplica' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_SqlAGReplica' {

        #region parameter mocks

        $mockSqlServer = 'Server1'
        $mockSqlInstanceName = 'MSSQLSERVER'
        $mockPrimaryReplicaSQLServer = 'Server2'
        $mockPrimaryReplicaSQLInstanceName = 'MSSQLSERVER'
        $mockAvailabilityGroupName = 'AG_AllServers'
        $mockAvailabilityGroupReplicaName = $mockSqlServer
        $mockEnsure = 'Present'
        $mockAvailabilityMode = 'AsynchronousCommit'
        $mockBackupPriority = 50
        $mockConnectionModeInPrimaryRole = 'AllowAllConnections'
        $mockConnectionModeInSecondaryRole = 'AllowNoConnections'
        $mockEndpointHostName = $mockSqlServer
        $mockFailoverMode = 'Manual'
        $mockReadOnlyRoutingConnectionUrl = "TCP://$($mockSqlServer).domain.com:1433"
        $mockReadOnlyRoutingList = @($mockSqlServer)
        $mockProcessOnlyOnActiveNode = $false

        #endregion

        #region server mock variables

        $mockServer1Name = 'Server1'
        $mockServer1NetName = $mockServer1Name
        $mockServer1IsHadrEnabled = $true
        $mockServer1ServiceName = 'MSSQLSERVER'

        $mockServer2Name = 'Server2'
        $mockServer2NetName = $mockServer1Name
        $mockServer2IsHadrEnabled = $true
        $mockServer2ServiceName = $mockServer1ServiceName

        $mockServer3Name = 'Server3'
        $mockServer3NetName = $mockServer3Name
        $mockServer3IsHadrEnabled = $true
        $mockServer3ServiceName = $mockServer1ServiceName

        #endregion

        #region Login mocks

        $mockLogins = @{} # Will be dynamically set during tests

        $mockNtServiceClusSvcName = 'NT SERVICE\ClusSvc'
        $mockNtAuthoritySystemName = 'NT AUTHORITY\SYSTEM'

        $mockAllLoginsAbsent = @{}

        $mockNtServiceClusSvcPresent = @{
            $mockNtServiceClusSvcName = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockSqlServer, $mockNtServiceClusSvcName) )
        }

        $mockNtAuthoritySystemPresent = @{
            $mockNtAuthoritySystemName = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockSqlServer, $mockNtAuthoritySystemName) )
        }

        $mockAllLoginsPresent = @{
            $mockNtServiceClusSvcName  = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockSqlServer, $mockNtServiceClusSvcName) )
            $mockNtAuthoritySystemName = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockSqlServer, $mockNtAuthoritySystemName) )
        }

        #endregion

        #region Endpoint mock variables

        $mockEndpointPort = 5022

        #endregion Endpoint mock variables

        #region Availability Group mock variables

        $mockAvailabilityGroup1Name = 'AG_AllServers'
        $mockAvailabilityGroup1PrimaryReplicaServer = $mockServer2Name

        $mockAvailabilityGroup2Name = 'AG_PrimaryOnServer2'
        $mockAvailabilityGroup2PrimaryReplicaServer = $mockServer2Name

        $mockAvailabilityGroup3Name = 'AG_PrimaryOnServer3'
        $mockAvailabilityGroup3PrimaryReplicaServer = $mockServer3Name

        #endregion

        #region Availability Group Replica mock variables

        $mockAlternateEndpointPort = $false
        $mockAlternateEndpointProtocol = $false

        $mockAvailabilityGroupReplica1Name = $mockServer1Name
        $mockAvailabilityGroupReplica1AvailabilityMode = 'AsynchronousCommit'
        $mockAvailabilityGroupReplica1BackupPriority = 50
        $mockAvailabilityGroupReplica1ConnectionModeInPrimaryRole = 'AllowAllConnections'
        $mockAvailabilityGroupReplica1ConnectionModeInSecondaryRole = 'AllowNoConnections'
        $mockAvailabilityGroupReplica1EndpointProtocol = 'TCP'
        $mockAvailabilityGroupReplica1EndpointPort = $mockEndpointPort
        $mockAvailabilityGroupReplica1EndpointUrl = "$($mockAvailabilityGroupReplica1EndpointProtocol)://$($mockServer1Name):$($mockAvailabilityGroupReplica1EndpointPort)"
        $mockAvailabilityGroupReplica1FailoverMode = 'Manual'
        $mockAvailabilityGroupReplica1ReadOnlyRoutingConnectionUrl = "TCP://$($mockServer1Name).domain.com:1433"
        $mockAvailabilityGroupReplica1ReadOnlyRoutingList = @($mockServer1Name)

        $mockAvailabilityGroupReplica2Name = $mockServer2Name
        $mockAvailabilityGroupReplica2AvailabilityMode = 'AsynchronousCommit'
        $mockAvailabilityGroupReplica2BackupPriority = 50
        $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole = 'AllowAllConnections'
        $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole = 'AllowNoConnections'
        $mockAvailabilityGroupReplica2EndpointProtocol = 'TCP'
        $mockAvailabilityGroupReplica2EndpointPort = $mockEndpointPort
        $mockAvailabilityGroupReplica2EndpointUrl = "$($mockAvailabilityGroupReplica2EndpointProtocol)://$($mockServer2Name):$($mockAvailabilityGroupReplica2EndpointPort)"
        $mockAvailabilityGroupReplica2FailoverMode = 'Manual'
        $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl = "TCP://$($mockServer2Name).domain.com:1433"
        $mockAvailabilityGroupReplica2ReadOnlyRoutingList = @($mockServer2Name)

        $mockAvailabilityGroupReplica3Name = $mockServer3Name
        $mockAvailabilityGroupReplica3AvailabilityMode = 'AsynchronousCommit'
        $mockAvailabilityGroupReplica3BackupPriority = 50
        $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole = 'AllowAllConnections'
        $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole = 'AllowNoConnections'
        $mockAvailabilityGroupReplica3EndpointProtocol = 'TCP'
        $mockAvailabilityGroupReplica3EndpointPort = $mockEndpointPort
        $mockAvailabilityGroupReplica3EndpointUrl = "$($mockAvailabilityGroupReplica3EndpointProtocol)://$($mockServer3Name):$($mockAvailabilityGroupReplica3EndpointPort)"
        $mockAvailabilityGroupReplica3FailoverMode = 'Manual'
        $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl = "TCP://$($mockServer3Name).domain.com:1433"
        $mockAvailabilityGroupReplica3ReadOnlyRoutingList = @($mockServer3Name)

        #endregion

        #region Function mocks

        $mockConnectSqlServer1 = {
            Param
            (
                [Parameter()]
                [string]
                $SQLServer,

                [Parameter()]
                [string]
                $SQLInstanceName,

                # The following two parameters are used to mock Get-PrimaryReplicaServerObject
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
                $AvailabilityGroup,

                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.Server]
                $ServerObject
            )

            # Mock the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = $mockServer1Name
            $mockServerObject.NetName = $mockServer1NetName
            $mockServerObject.IsHadrEnabled = $mockServer1IsHadrEnabled
            $mockServerObject.Logins = $mockLogins
            $mockServerObject.ServiceName = $mockServer1ServiceName

            # Mock the availability group replicas
            $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica1.AvailabilityMode = $mockAvailabilityGroupReplica1AvailabilityMode
            $mockAvailabilityGroupReplica1.BackupPriority = $mockAvailabilityGroupReplica1BackupPriority
            $mockAvailabilityGroupReplica1.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica1ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica1.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica1ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl
            $mockAvailabilityGroupReplica1.FailoverMode = $mockAvailabilityGroupReplica1FailoverMode
            $mockAvailabilityGroupReplica1.Name = $mockAvailabilityGroupReplica1Name
            $mockAvailabilityGroupReplica1.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica1ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica1.ReadOnlyRoutingList = $mockAvailabilityGroupReplica1ReadOnlyRoutingList

            $mockAvailabilityGroupReplica2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica2.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
            $mockAvailabilityGroupReplica2.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
            $mockAvailabilityGroupReplica2.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica2.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
            $mockAvailabilityGroupReplica2.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
            $mockAvailabilityGroupReplica2.Name = $mockAvailabilityGroupReplica2Name
            $mockAvailabilityGroupReplica2.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica2.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

            $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica3.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
            $mockAvailabilityGroupReplica3.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
            $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
            $mockAvailabilityGroupReplica3.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
            $mockAvailabilityGroupReplica3.Name = $mockAvailabilityGroupReplica3Name
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList

            if ( $mockAlternateEndpointPort )
            {
                $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointPort, '1234')
                $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointPort, '1234')
                $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointPort, '1234')
            }

            if ( $mockAlternateEndpointProtocol )
            {
                $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointProtocol, 'UDP')
                $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointProtocol, 'UDP')
                $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointProtocol, 'UDP')
            }

            # Mock the availability groups
            $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup1.Name = $mockAvailabilityGroup1Name
            $mockAvailabilityGroup1.PrimaryReplicaServerName = $mockAvailabilityGroup1PrimaryReplicaServer
            $mockAvailabilityGroup1.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

            # Mock the mirroring endpoint if required
            if ( $mockDatabaseMirroringEndpoint )
            {
                $mockEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
                $mockEndpoint.EndpointType = 'DatabaseMirroring'
                $mockEndpoint.Protocol = @{
                    TCP = @{
                        ListenerPort = $mockendpointPort
                    }
                }
                $mockServerObject.Endpoints.Add($mockEndpoint)
            }

            return $mockServerObject
        }

        $mockConnectSqlServer2 = {
            Param
            (
                [Parameter()]
                [string]
                $SQLServer,

                [Parameter()]
                [string]
                $SQLInstanceName,

                # The following two parameters are used to mock Get-PrimaryReplicaServerObject
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
                $AvailabilityGroup,

                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.Server]
                $ServerObject
            )

            # Mock the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = $mockServer2Name
            $mockServerObject.NetName = $mockServer2NetName
            $mockServerObject.IsHadrEnabled = $mockServer2IsHadrEnabled
            $mockServerObject.Logins = $mockLogins
            $mockServerObject.ServiceName = $mockServer2ServiceName

            #region Mock the availability group replicas
            $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica1.AvailabilityMode = $mockAvailabilityGroupReplica1AvailabilityMode
            $mockAvailabilityGroupReplica1.BackupPriority = $mockAvailabilityGroupReplica1BackupPriority
            $mockAvailabilityGroupReplica1.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica1ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica1.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica1ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl
            $mockAvailabilityGroupReplica1.FailoverMode = $mockAvailabilityGroupReplica1FailoverMode
            $mockAvailabilityGroupReplica1.Name = $mockAvailabilityGroupReplica1Name
            $mockAvailabilityGroupReplica1.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica1ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica1.ReadOnlyRoutingList = $mockAvailabilityGroupReplica1ReadOnlyRoutingList

            $mockAvailabilityGroupReplica2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica2.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
            $mockAvailabilityGroupReplica2.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
            $mockAvailabilityGroupReplica2.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica2.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
            $mockAvailabilityGroupReplica2.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
            $mockAvailabilityGroupReplica2.Name = $mockAvailabilityGroupReplica2Name
            $mockAvailabilityGroupReplica2.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica2.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

            $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica3.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
            $mockAvailabilityGroupReplica3.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
            $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
            $mockAvailabilityGroupReplica3.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
            $mockAvailabilityGroupReplica3.Name = $mockAvailabilityGroupReplica3Name
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList
            #endregion Mock the availability group replicas

            if ( $mockAlternateEndpointPort )
            {
                $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointPort, '1234')
                $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointPort, '1234')
                $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointPort, '1234')
            }

            if ( $mockAlternateEndpointProtocol )
            {
                $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointProtocol, 'UDP')
                $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointProtocol, 'UDP')
                $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointProtocol, 'UDP')
            }

            # Mock the availability groups
            $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup1.Name = $mockAvailabilityGroup1Name
            $mockAvailabilityGroup1.PrimaryReplicaServerName = $mockAvailabilityGroup1PrimaryReplicaServer
            $mockAvailabilityGroup1.LocalReplicaRole = 'Primary'
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

            $mockAvailabilityGroup2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup2.Name = $mockAvailabilityGroup2Name
            $mockAvailabilityGroup2.PrimaryReplicaServerName = $mockAvailabilityGroup2PrimaryReplicaServer
            $mockAvailabilityGroup2.LocalReplicaRole = 'Primary'
            $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup2)

            $mockAvailabilityGroup3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup3.Name = $mockAvailabilityGroup3Name
            $mockAvailabilityGroup3.PrimaryReplicaServerName = $mockAvailabilityGroup3PrimaryReplicaServer
            $mockAvailabilityGroup3.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup3)

            # Mock the mirroring endpoint if required
            if ( $mockDatabaseMirroringEndpoint )
            {
                $mockEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
                $mockEndpoint.EndpointType = 'DatabaseMirroring'
                $mockEndpoint.Protocol = @{
                    TCP = @{
                        ListenerPort = $mockendpointPort
                    }
                }
                $mockServerObject.Endpoints.Add($mockEndpoint)
            }

            return $mockServerObject
        }

        $mockConnectSqlServer3 = {
            Param
            (
                [Parameter()]
                [string]
                $SQLServer,

                [Parameter()]
                [string]
                $SQLInstanceName,

                # The following two parameters are used to mock Get-PrimaryReplicaServerObject
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
                $AvailabilityGroup,

                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.Server]
                $ServerObject
            )

            # Mock the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = $mockServer3Name
            $mockServerObject.NetName = $mockServer3NetName
            $mockServerObject.IsHadrEnabled = $mockServer3IsHadrEnabled
            $mockServerObject.Logins = $mockLogins
            $mockServerObject.ServiceName = $mockServer3ServiceName

            #region Mock the availability group replicas
            $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica1.AvailabilityMode = $mockAvailabilityGroupReplica1AvailabilityMode
            $mockAvailabilityGroupReplica1.BackupPriority = $mockAvailabilityGroupReplica1BackupPriority
            $mockAvailabilityGroupReplica1.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica1ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica1.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica1ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl
            $mockAvailabilityGroupReplica1.FailoverMode = $mockAvailabilityGroupReplica1FailoverMode
            $mockAvailabilityGroupReplica1.Name = $mockAvailabilityGroupReplica1Name
            $mockAvailabilityGroupReplica1.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica1ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica1.ReadOnlyRoutingList = $mockAvailabilityGroupReplica1ReadOnlyRoutingList

            $mockAvailabilityGroupReplica2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica2.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
            $mockAvailabilityGroupReplica2.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
            $mockAvailabilityGroupReplica2.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica2.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
            $mockAvailabilityGroupReplica2.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
            $mockAvailabilityGroupReplica2.Name = $mockAvailabilityGroupReplica2Name
            $mockAvailabilityGroupReplica2.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica2.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

            $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica3.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
            $mockAvailabilityGroupReplica3.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
            $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
            $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
            $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
            $mockAvailabilityGroupReplica3.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
            $mockAvailabilityGroupReplica3.Name = $mockAvailabilityGroupReplica3Name
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList
            #endregion Mock the availability group replicas

            if ( $mockAlternateEndpointPort )
            {
                $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointPort, '1234')
                $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointPort, '1234')
                $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointPort, '1234')
            }

            if ( $mockAlternateEndpointProtocol )
            {
                $mockAvailabilityGroupReplica1.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointProtocol, 'UDP')
                $mockAvailabilityGroupReplica2.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointProtocol, 'UDP')
                $mockAvailabilityGroupReplica3.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointProtocol, 'UDP')
            }

            # Mock the availability groups
            $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup1.Name = $mockAvailabilityGroup1Name
            $mockAvailabilityGroup1.PrimaryReplicaServerName = $mockAvailabilityGroup1PrimaryReplicaServer
            $mockAvailabilityGroup1.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

            $mockAvailabilityGroup2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup2.Name = $mockAvailabilityGroup2Name
            $mockAvailabilityGroup2.PrimaryReplicaServerName = $mockAvailabilityGroup2PrimaryReplicaServer
            $mockAvailabilityGroup2.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup2)

            $mockAvailabilityGroup3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup3.Name = $mockAvailabilityGroup3Name
            $mockAvailabilityGroup3.PrimaryReplicaServerName = $mockAvailabilityGroup3PrimaryReplicaServer
            $mockAvailabilityGroup3.LocalReplicaRole = 'Primary'
            $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup3)

            # Mock the mirroring endpoint if required
            if ( $mockDatabaseMirroringEndpoint )
            {
                $mockEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
                $mockEndpoint.EndpointType = 'DatabaseMirroring'
                $mockEndpoint.Protocol = @{
                    TCP = @{
                        ListenerPort = $mockendpointPort
                    }
                }
                $mockServerObject.Endpoints.Add($mockEndpoint)
            }

            return $mockServerObject
        }

        $mockAvailabilityGroupReplicaPropertyName = '' # Set dynamically during runtime
        $mockAvailabilityGroupReplicaPropertyValue = '' # Set dynamically during runtime

        $mockUpdateAvailabilityGroupReplica = {
            Param
            (
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
                $AvailabilityGroupReplica
            )

            if ( [string]::IsNullOrEmpty($mockAvailabilityGroupReplicaPropertyName) -and [string]::IsNullOrEmpty($mockAvailabilityGroupReplicaPropertyValue) )
            {
                return
            }

            if ( ( $mockAvailabilityGroupReplicaPropertyValue -join ',' ) -ne ( $AvailabilityGroupReplica.$mockAvailabilityGroupReplicaPropertyName -join ',' ) )
            {
                throw
            }
        }

        #endregion

        Describe 'SqlAGReplica\Get-TargetResource' {
            BeforeEach {
                $getTargetResourceParameters = @{
                    Name                  = $mockAvailabilityGroupReplicaName
                    AvailabilityGroupName = $mockAvailabilityGroupName
                    SQLServer             = $mockSqlServer
                    SQLInstanceName       = $mockSqlInstanceName
                }

                $mockDatabaseMirroringEndpoint = $true

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable
            }

            Context 'When the Availability Group Replica is absent' {

                It 'Should not return an Availability Group Replica' {

                    $getTargetResourceParameters.Name = 'AbsentReplica'
                    $getTargetResourceParameters.AvailabilityGroupName = 'AbsentAG'

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.AvailabilityGroupName | Should -BeNullOrEmpty
                    $getTargetResourceResult.AvailabilityMode | Should -BeNullOrEmpty
                    $getTargetResourceResult.BackupPriority | Should -BeNullOrEmpty
                    $getTargetResourceResult.ConnectionModeInPrimaryRole | Should -BeNullOrEmpty
                    $getTargetResourceResult.ConnectionModeInSecondaryRole | Should -BeNullOrEmpty
                    $getTargetResourceResult.EndpointUrl | Should -BeNullOrEmpty
                    $getTargetResourceResult.EndpointPort | Should -Be $mockendpointPort
                    $getTargetResourceResult.Ensure | Should -Be 'Absent'
                    $getTargetResourceResult.FailoverMode | Should -BeNullOrEmpty
                    $getTargetResourceResult.Name | Should -BeNullOrEmpty
                    $getTargetResourceResult.ReadOnlyRoutingConnectionUrl | Should -BeNullOrEmpty
                    $getTargetResourceResult.ReadOnlyRoutingList | Should -BeNullOrEmpty
                    $getTargetResourceResult.SQLServer | Should -Be $mockSqlServer
                    $getTargetResourceResult.SQLInstanceName | Should -Be $mockSqlInstanceName
                    $getTargetResourceResult.SQLServerNetName | Should -Be $mockSqlServer

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group Replica is present' {

                $mockEnsure = 'Present'

                It 'Should return an Availability Group Replica' {

                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.AvailabilityGroupName | Should -Be $mockAvailabilityGroupName
                    $getTargetResourceResult.AvailabilityMode | Should -Be $mockAvailabilityMode
                    $getTargetResourceResult.BackupPriority | Should -Be $mockBackupPriority
                    $getTargetResourceResult.ConnectionModeInPrimaryRole | Should -Be $mockConnectionModeInPrimaryRole
                    $getTargetResourceResult.ConnectionModeInSecondaryRole | Should -Be $mockConnectionModeInSecondaryRole
                    $getTargetResourceResult.EndpointUrl | Should -Be $mockAvailabilityGroupReplica1EndpointUrl
                    $getTargetResourceResult.EndpointPort | Should -Be $mockendpointPort
                    $getTargetResourceResult.Ensure | Should -Be $mockEnsure
                    $getTargetResourceResult.FailoverMode | Should -Be $mockFailoverMode
                    $getTargetResourceResult.Name | Should -Be $mockSqlServer
                    $getTargetResourceResult.ReadOnlyRoutingConnectionUrl | Should -Be $mockReadOnlyRoutingConnectionUrl
                    $getTargetResourceResult.ReadOnlyRoutingList | Should -Be $mockSqlServer
                    $getTargetResourceResult.SQLServer | Should -Be $mockSqlServer
                    $getTargetResourceResult.SQLInstanceName | Should -Be $mockSqlInstanceName
                    $getTargetResourceResult.SQLServerNetName | Should -Be $mockSqlServer

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'SqlAGReplica\Set-TargetResource' {

            BeforeAll {
                Mock -CommandName Import-SQLPSModule -MockWith {} -Verifiable
                Mock -CommandName New-TerminatingError {
                    $ErrorType
                } -Verifiable
            }

            BeforeEach {
                $mockDatabaseMirroringEndpoint = $true
                $mockLogins = $mockNtServiceClusSvcPresent
                $mockServer1IsHadrEnabled = $true

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter {
                    $SQLServer -eq $mockServer1Name
                }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter {
                    $SQLServer -eq $mockServer2Name
                }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer3 -Verifiable -ParameterFilter {
                    $SQLServer -eq $mockServer3Name
                }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer3 -Verifiable -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                }
                Mock -CommandName Join-SqlAvailabilityGroup -MockWith {} -Verifiable
                Mock -CommandName New-SqlAvailabilityReplica {} -Verifiable
                Mock -CommandName Test-ClusterPermissions -MockWith {
                    $null
                } -Verifiable
            }

            Context 'When the desired state is absent' {

                BeforeAll {
                    Mock -CommandName Update-AvailabilityGroupReplica {} -Verifiable
                }

                BeforeEach {
                    $setTargetResourceParameters = @{
                        Name                  = $mockSqlServer
                        AvailabilityGroupName = $mockAvailabilityGroupName
                        SQLServer             = $mockSqlServer
                        SQLInstanceName       = $mockSqlInstanceName
                        Ensure                = 'Absent'
                    }
                }

                It 'Should silently remove the availability group replica' {

                    Mock -CommandName Remove-SqlAvailabilityReplica -MockWith {} -Verifiable

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (RemoveAvailabilityGroupReplicaFailed) when removing the availability group replica fails' {

                    Mock -CommandName Remove-SqlAvailabilityReplica -MockWith { Throw 'RemoveAvailabilityGroupReplicaFailed' } -Verifiable

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw 'RemoveAvailabilityGroupReplicaFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the desired state is present and the availability group is absent' {

                BeforeAll {
                    Mock -CommandName Remove-SqlAvailabilityReplica -MockWith {} -Verifiable
                    Mock -CommandName Update-AvailabilityGroupReplica {} -Verifiable
                }

                BeforeEach {
                    $setTargetResourceParameters = @{
                        Name                          = $mockSqlServer
                        AvailabilityGroupName         = $mockAvailabilityGroup2Name
                        SQLServer                     = $mockSqlServer
                        SQLInstanceName               = $mockSqlInstanceName
                        PrimaryReplicaSQLServer       = $mockPrimaryReplicaSQLServer
                        PrimaryReplicaSQLInstanceName = $mockPrimaryReplicaSQLInstanceName
                        Ensure                        = $mockEnsure
                        AvailabilityMode              = $mockAvailabilityMode
                        BackupPriority                = $mockBackupPriority
                        ConnectionModeInPrimaryRole   = $mockConnectionModeInPrimaryRole
                        ConnectionModeInSecondaryRole = $mockConnectionModeInSecondaryRole
                        EndpointHostName              = $mockEndpointHostName
                        FailoverMode                  = $mockFailoverMode
                        ReadOnlyRoutingConnectionUrl  = $mockReadOnlyRoutingConnectionUrl
                        ReadOnlyRoutingList           = $mockReadOnlyRoutingList
                    }
                }

                It 'Should throw the correct error (HadrNotEnabled) when HADR is not enabled' {

                    $mockServer1IsHadrEnabled = $false

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw 'HadrNotEnabled'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It "Should throw when the logins '$($mockNtServiceClusSvcName)' or '$($mockNtAuthoritySystemName)' are absent or do not have permissions to manage availability groups" {

                    Mock -CommandName Test-ClusterPermissions -MockWith { throw } -Verifiable

                    $mockLogins = $mockAllLoginsAbsent.Clone()

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It "Should create the availability group replica when '$($mockNtServiceClusSvcName)' or '$($mockNtAuthoritySystemName)' is present and has the permissions to manage availability groups" {

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (DatabaseMirroringEndpointNotFound) when the database mirroring endpoint is absent' {

                    $mockDatabaseMirroringEndpoint = $false

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw 'DatabaseMirroringEndpointNotFound'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should create the availability group replica when the endpoint hostname is not defined' {

                    $setTargetResourceParameters.EndpointHostName = ''

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should create the availability group replica when primary replica server is incorrectly supplied and the availability group exists' {

                    $setTargetResourceParameters.PrimaryReplicaSQLServer = $mockServer3Name

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error when the availability group replica fails to create' {

                    Mock -CommandName New-SqlAvailabilityReplica { throw } -Verifiable

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw 'CreateAvailabilityGroupReplicaFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (JoinAvailabilityGroupFailed) when the availability group replica fails to join the availability group' {

                    Mock -CommandName Join-SqlAvailabilityGroup -MockWith { throw } -Verifiable

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw 'JoinAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (AvailabilityGroupNotFound) when the availability group does not exist on the primary replica' {

                    $setTargetResourceParameters.AvailabilityGroupName = 'DoesNotExist'

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw 'AvailabilityGroupNotFound'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the desired state is present and the availability group is present' {

                BeforeAll {
                    Mock -CommandName Remove-SqlAvailabilityReplica -MockWith {} -Verifiable
                    Mock -CommandName Update-AvailabilityGroupReplica -MockWith $mockUpdateAvailabilityGroupReplica -Verifiable

                    # Create a hash table to provide test properties and values for the update tests
                    $mockTestProperties = @{
                        AvailabilityMode              = 'SynchronousCommit'
                        BackupPriority                = 75
                        ConnectionModeInPrimaryRole   = 'AllowReadWriteConnections'
                        ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
                        FailoverMode                  = 'Automatic'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://TestHost.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                    }
                }

                BeforeEach {
                    $mockAlternateEndpointPort = $false
                    $mockAlternateEndpointProtocol = $false

                    $setTargetResourceParameters = @{
                        Name                          = $mockSqlServer
                        AvailabilityGroupName         = $mockAvailabilityGroupName
                        SQLServer                     = $mockSqlServer
                        SQLInstanceName               = $mockSqlInstanceName
                        PrimaryReplicaSQLServer       = $mockPrimaryReplicaSQLServer
                        PrimaryReplicaSQLInstanceName = $mockPrimaryReplicaSQLInstanceName
                        Ensure                        = $mockEnsure
                        AvailabilityMode              = $mockAvailabilityMode
                        BackupPriority                = $mockBackupPriority
                        ConnectionModeInPrimaryRole   = $mockConnectionModeInPrimaryRole
                        ConnectionModeInSecondaryRole = $mockConnectionModeInSecondaryRole
                        EndpointHostName              = $mockEndpointHostName
                        FailoverMode                  = $mockFailoverMode
                        ReadOnlyRoutingConnectionUrl  = $mockReadOnlyRoutingConnectionUrl
                        ReadOnlyRoutingList           = $mockReadOnlyRoutingList
                    }
                }

                It 'Should throw the correct error (ReplicaNotFound) when the availability group replica does not exist' {

                    $setTargetResourceParameters.Name = 'ReplicaNotFound'

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw 'ReplicaNotFound'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                foreach ( $mockTestProperty in $mockTestProperties.GetEnumerator() )
                {
                    It "Should set the property '$($mockTestProperty.Key)' to the desired state" {

                        $mockAvailabilityGroupReplicaPropertyName = $mockTestProperty.Key
                        $mockAvailabilityGroupReplicaPropertyValue = $mockTestProperty.Value
                        $setTargetResourceParameters.$mockAvailabilityGroupReplicaPropertyName = $mockAvailabilityGroupReplicaPropertyValue

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                            $SQLServer -eq $mockServer1Name
                        } -Times 1 -Exactly
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                            $SQLServer -eq $mockServer2Name
                        } -Times 0 -Exactly
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                            $SQLServer -eq $mockServer3Name
                        } -Times 0 -Exactly
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                            $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                        }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                            $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                        }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                            $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                        }
                        Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 #-Exactly
                    }
                }

                It "Should set the Endpoint Hostname to the desired state" {

                    $setTargetResourceParameters.EndpointHostName = 'AnotherEndpointHostName'

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It "Should set the Endpoint Port to the desired state" {

                    $mockAvailabilityGroupReplicaPropertyName = 'EndpointUrl'
                    $mockAvailabilityGroupReplicaPropertyValue = $mockAvailabilityGroupReplica1EndpointUrl
                    $mockAlternateEndpointPort = $true

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It "Should set the Endpoint Protocol to the desired state" {

                    $mockAvailabilityGroupReplicaPropertyName = 'EndpointUrl'
                    $mockAvailabilityGroupReplicaPropertyValue = $mockAvailabilityGroupReplica1EndpointUrl
                    $mockAlternateEndpointProtocol = $true

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer1Name
                    } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer2Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter {
                        $SQLServer -eq $mockServer3Name
                    } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer1Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer2Name
                    }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                        $AvailabilityGroup.PrimaryReplicaServerName -eq $mockServer3Name
                    }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'SqlAGReplica\Test-TargetResource' {

            BeforeEach {
                $mockAlternateEndpointPort = $false
                $mockAlternateEndpointProtocol = $false
                $mockDatabaseMirroringEndpoint = $true

                $testTargetResourceParameters = @{
                    Name                          = $mockSqlServer
                    AvailabilityGroupName         = $mockAvailabilityGroupName
                    SQLServer                     = $mockSqlServer
                    SQLInstanceName               = $mockSqlInstanceName
                    PrimaryReplicaSQLServer       = $mockPrimaryReplicaSQLServer
                    PrimaryReplicaSQLInstanceName = $mockPrimaryReplicaSQLInstanceName
                    Ensure                        = $mockEnsure
                    AvailabilityMode              = $mockAvailabilityMode
                    BackupPriority                = $mockBackupPriority
                    ConnectionModeInPrimaryRole   = $mockConnectionModeInPrimaryRole
                    ConnectionModeInSecondaryRole = $mockConnectionModeInSecondaryRole
                    EndpointHostName              = $mockEndpointHostName
                    FailoverMode                  = $mockFailoverMode
                    ReadOnlyRoutingConnectionUrl  = $mockReadOnlyRoutingConnectionUrl
                    ReadOnlyRoutingList           = $mockReadOnlyRoutingList
                    ProcessOnlyOnActiveNode       = $mockProcessOnlyOnActiveNode
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable
                Mock -CommandName Test-ActiveNode -MockWith {
                    return -not $mockProcessOnlyOnActiveNode
                } -Verifiable
            }

            Context 'When the desired state is absent' {

                It 'Should return $true when the Availability Replica is absent' {

                    $testTargetResourceParameters.Name = $mockAvailabilityGroupReplica2Name
                    $testTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroup2Name
                    $testTargetResourceParameters.Ensure = 'Absent'

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present' {

                    $testTargetResourceParameters.Ensure = 'Absent'

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the desired state is present' {

                BeforeAll {
                    $propertiesToCheck = @{
                        AvailabilityMode              = 'SynchronousCommit'
                        BackupPriority                = 42
                        ConnectionModeInPrimaryRole   = 'AllowReadWriteConnections'
                        ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
                        FailoverMode                  = 'Automatic'
                        ReadOnlyRoutingConnectionUrl  = 'WrongUrl'
                        ReadOnlyRoutingList           = @('WrongServer')
                    }
                }

                It 'Should return $false when the Availability Replica is absent' {

                    $testTargetResourceParameters.Name = $mockAvailabilityGroupReplica2Name
                    $testTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroup2Name

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the Availability Replica is present' {

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                foreach ( $propertyToCheck in $propertiesToCheck.GetEnumerator() )
                {
                    It "Should return $false when the Availability Replica is present and the property '$($propertyToCheck.Key)' is not in the desired state" {
                        $testTargetResourceParameters.($propertyToCheck.Key) = $propertyToCheck.Value

                        Test-TargetResource @testTargetResourceParameters | Should -Be $false

                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                    }
                }

                It 'Should return $false when the Availability Replica is present and the Availabiltiy Mode is not in the desired state' {

                    $testTargetResourceParameters.AvailabilityMode = 'SynchronousCommit'

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the Availability Replica is present and the Endpoint Hostname is not specified' {

                    $testTargetResourceParameters.EndpointHostName = ''

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present and the Endpoint Hostname is not in the desired state' {

                    $testTargetResourceParameters.EndpointHostName = 'OtherHostName'

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present and the Endpoint Protocol is not in the desired state' {

                    $mockAlternateEndpointProtocol = $true

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present and the Endpoint Port is not in the desired state' {

                    $mockAlternateEndpointPort = $true

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly

                    $mockAlternateEndpointPort = $false
                }

                It 'Should return $true when ProcessOnlyOnActiveNode is "$true" and the current node is not actively hosting the instance' {
                    $mockProcessOnlyOnActiveNode = $true

                    $testTargetResourceParameters.ProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNode

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
