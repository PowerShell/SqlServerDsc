#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global
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

        #endregion        
        
        #region server mock variables

            $mockServer1Name = 'Server1'
            $mockServer1NetName = $mockServer1Name
            $mockServer1IsHadrEnabled = $true

            $mockServer2Name = 'Server2'
            $mockServer2NetName = $mockServer1Name
            $mockServer2IsHadrEnabled = $true

            $mockServer3Name = 'Server3'
            $mockServer3NetName = $mockServer3Name
            $mockServer3IsHadrEnabled = $true

        #endregion        

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
                                                        Add-Member -MemberType NoteProperty -Name ListenerPort -Value 5022 -PassThru -Force
                                                )
                                            )
                                        } -PassThru -Force
                                )
                            )
                        } -PassThru -Force
                )
            )

        #endregion

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
            $mockAvailabilityGroupReplica1EndpointPort = 5022
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
            $mockAvailabilityGroupReplica2EndpointPort = 5022
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
            $mockAvailabilityGroupReplica3EndpointPort = 5022
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
                $SQLInstanceName
            )
            
            $mock = @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockServer1Name -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'NetName' -Value $mockServer1NetName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsHadrEnabled' -Value $mockServer1IsHadrEnabled -PassThru |
                        Add-Member ScriptProperty Logins {
                            return $mockLogins
                        } -PassThru -Force |
                        Add-Member ScriptProperty AvailabilityGroups {
                            return @{
                                $mockAvailabilityGroup1Name = ( 
                                    New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroup1Name -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockAvailabilityGroup1PrimaryReplicaServer -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value 'Secondary' -PassThru |
                                    Add-Member ScriptProperty AvailabilityReplicas {
                                        $mockAvailabilityGroupReplica1Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica1Object.AvailabilityMode = $mockAvailabilityGroupReplica1AvailabilityMode
                                        $mockAvailabilityGroupReplica1Object.BackupPriority = $mockAvailabilityGroupReplica1BackupPriority
                                        $mockAvailabilityGroupReplica1Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica1ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica1Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica1ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica1Object.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl
                                        $mockAvailabilityGroupReplica1Object.FailoverMode = $mockAvailabilityGroupReplica1FailoverMode
                                        $mockAvailabilityGroupReplica1Object.Name = $mockAvailabilityGroupReplica1Name
                                        $mockAvailabilityGroupReplica1Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica1ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica1Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica1ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica2Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica2Object.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
                                        $mockAvailabilityGroupReplica2Object.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
                                        $mockAvailabilityGroupReplica2Object.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
                                        $mockAvailabilityGroupReplica2Object.Name = $mockAvailabilityGroupReplica2Name
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica3Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica3Object.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
                                        $mockAvailabilityGroupReplica3Object.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
                                        $mockAvailabilityGroupReplica3Object.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
                                        $mockAvailabilityGroupReplica3Object.Name = $mockAvailabilityGroupReplica3Name
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList

                                        if ( $mockAlternateEndpointPort )
                                        {
                                            $mockAvailabilityGroupReplica1Object.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointPort,'1234')
                                            $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointPort,'1234')
                                            $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointPort,'1234')
                                        }
                                        
                                        if ( $mockAlternateEndpointProtocol )
                                        {
                                            $mockAvailabilityGroupReplica1Object.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointProtocol,'UDP')
                                            $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointProtocol,'UDP')
                                            $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointProtocol,'UDP')
                                        }

                                        return @{
                                            $mockAvailabilityGroupReplica1Name = $mockAvailabilityGroupReplica1Object
                                            $mockAvailabilityGroupReplica2Name = $mockAvailabilityGroupReplica2Object
                                            $mockAvailabilityGroupReplica3Name = $mockAvailabilityGroupReplica3Object
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

        $mockConnectSqlServer2 = {
            Param
            (
                [Parameter()]
                [string]
                $SQLServer,

                [Parameter()]
                [string]
                $SQLInstanceName
            )
            
            $mock = @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockServer1Name -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'NetName' -Value $mockServer1NetName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsHadrEnabled' -Value $mockServer1IsHadrEnabled -PassThru |
                        Add-Member ScriptProperty Logins {
                            return $mockLogins
                        } -PassThru -Force |
                        Add-Member ScriptProperty AvailabilityGroups {
                            return @{
                                $mockAvailabilityGroup1Name = ( 
                                    New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroup1Name -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockAvailabilityGroup1PrimaryReplicaServer -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value 'Primary' -PassThru |
                                    Add-Member ScriptProperty AvailabilityReplicas {
                                        $mockAvailabilityGroupReplica1Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica1Object.AvailabilityMode = $mockAvailabilityGroupReplica1AvailabilityMode
                                        $mockAvailabilityGroupReplica1Object.BackupPriority = $mockAvailabilityGroupReplica1BackupPriority
                                        $mockAvailabilityGroupReplica1Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica1ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica1Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica1ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica1Object.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl
                                        $mockAvailabilityGroupReplica1Object.FailoverMode = $mockAvailabilityGroupReplica1FailoverMode
                                        $mockAvailabilityGroupReplica1Object.Name = $mockAvailabilityGroupReplica1Name
                                        $mockAvailabilityGroupReplica1Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica1ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica1Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica1ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica2Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica2Object.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
                                        $mockAvailabilityGroupReplica2Object.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
                                        $mockAvailabilityGroupReplica2Object.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
                                        $mockAvailabilityGroupReplica2Object.Name = $mockAvailabilityGroupReplica2Name
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica3Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica3Object.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
                                        $mockAvailabilityGroupReplica3Object.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
                                        $mockAvailabilityGroupReplica3Object.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
                                        $mockAvailabilityGroupReplica3Object.Name = $mockAvailabilityGroupReplica3Name
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList
                                        
                                        if ( $mockAlternateEndpointPort )
                                        {
                                            $mockAvailabilityGroupReplica1Object.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointPort,'1234')
                                            $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointPort,'1234')
                                            $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointPort,'1234')
                                        }
                                        
                                        if ( $mockAlternateEndpointProtocol )
                                        {
                                            $mockAvailabilityGroupReplica1Object.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl.Replace($mockAvailabilityGroupReplica1EndpointProtocol,'UDP')
                                            $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl.Replace($mockAvailabilityGroupReplica2EndpointProtocol,'UDP')
                                            $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl.Replace($mockAvailabilityGroupReplica3EndpointProtocol,'UDP')
                                        }
                                        
                                        return @{
                                            $mockAvailabilityGroupReplica1Name = $mockAvailabilityGroupReplica1Object
                                            $mockAvailabilityGroupReplica2Name = $mockAvailabilityGroupReplica2Object
                                            $mockAvailabilityGroupReplica3Name = $mockAvailabilityGroupReplica3Object
                                        }
                                    } -PassThru -Force
                                )
                                $mockAvailabilityGroup2Name = ( 
                                    New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroup2Name -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockAvailabilityGroup2PrimaryReplicaServer -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value 'Primary' -PassThru |
                                    Add-Member ScriptProperty AvailabilityReplicas {
                                        $mockAvailabilityGroupReplica2Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica2Object.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
                                        $mockAvailabilityGroupReplica2Object.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
                                        $mockAvailabilityGroupReplica2Object.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
                                        $mockAvailabilityGroupReplica2Object.Name = $mockAvailabilityGroupReplica2Name
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica3Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica3Object.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
                                        $mockAvailabilityGroupReplica3Object.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
                                        $mockAvailabilityGroupReplica3Object.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
                                        $mockAvailabilityGroupReplica3Object.Name = $mockAvailabilityGroupReplica3Name
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList
                                        
                                        return @{
                                            $mockAvailabilityGroupReplica2Name = $mockAvailabilityGroupReplica2Object
                                            $mockAvailabilityGroupReplica3Name = $mockAvailabilityGroupReplica3Object
                                        }
                                    } -PassThru -Force
                                )
                                $mockAvailabilityGroup3Name = ( 
                                    New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroup3Name -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockAvailabilityGroup3PrimaryReplicaServer -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value 'Secondary' -PassThru |
                                    Add-Member ScriptProperty AvailabilityReplicas {
                                        $mockAvailabilityGroupReplica2Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica2Object.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
                                        $mockAvailabilityGroupReplica2Object.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
                                        $mockAvailabilityGroupReplica2Object.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
                                        $mockAvailabilityGroupReplica2Object.Name = $mockAvailabilityGroupReplica2Name
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica3Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica3Object.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
                                        $mockAvailabilityGroupReplica3Object.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
                                        $mockAvailabilityGroupReplica3Object.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
                                        $mockAvailabilityGroupReplica3Object.Name = $mockAvailabilityGroupReplica3Name
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList
                                        
                                        return @{
                                            $mockAvailabilityGroupReplica2Name = $mockAvailabilityGroupReplica2Object
                                            $mockAvailabilityGroupReplica3Name = $mockAvailabilityGroupReplica3Object
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

        $mockConnectSqlServer3 = {
            Param
            (
                [Parameter()]
                [string]
                $SQLServer,

                [Parameter()]
                [string]
                $SQLInstanceName
            )
            
            $mock = @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockServer1Name -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'NetName' -Value $mockServer1NetName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsHadrEnabled' -Value $mockServer1IsHadrEnabled -PassThru |
                        Add-Member ScriptProperty Logins {
                            return $mockLogins
                        } -PassThru -Force |
                        Add-Member ScriptProperty AvailabilityGroups {
                            return @{
                                $mockAvailabilityGroup1Name = ( 
                                    New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroup1Name -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockAvailabilityGroup1PrimaryReplicaServer -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value 'Secondary' -PassThru |
                                    Add-Member ScriptProperty AvailabilityReplicas {
                                        $mockAvailabilityGroupReplica1Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica1Object.AvailabilityMode = $mockAvailabilityGroupReplica1AvailabilityMode
                                        $mockAvailabilityGroupReplica1Object.BackupPriority = $mockAvailabilityGroupReplica1BackupPriority
                                        $mockAvailabilityGroupReplica1Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica1ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica1Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica1ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica1Object.EndpointUrl = $mockAvailabilityGroupReplica1EndpointUrl
                                        $mockAvailabilityGroupReplica1Object.FailoverMode = $mockAvailabilityGroupReplica1FailoverMode
                                        $mockAvailabilityGroupReplica1Object.Name = $mockAvailabilityGroupReplica1Name
                                        $mockAvailabilityGroupReplica1Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica1ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica1Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica1ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica2Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica2Object.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
                                        $mockAvailabilityGroupReplica2Object.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
                                        $mockAvailabilityGroupReplica2Object.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
                                        $mockAvailabilityGroupReplica2Object.Name = $mockAvailabilityGroupReplica2Name
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica3Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica3Object.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
                                        $mockAvailabilityGroupReplica3Object.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
                                        $mockAvailabilityGroupReplica3Object.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
                                        $mockAvailabilityGroupReplica3Object.Name = $mockAvailabilityGroupReplica3Name
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList
                                        
                                        return @{
                                            $mockAvailabilityGroupReplica1Name = $mockAvailabilityGroupReplica1Object
                                            $mockAvailabilityGroupReplica2Name = $mockAvailabilityGroupReplica2Object
                                            $mockAvailabilityGroupReplica3Name = $mockAvailabilityGroupReplica3Object
                                        }
                                    } -PassThru -Force
                                )
                                $mockAvailabilityGroup2Name = ( 
                                    New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroup2Name -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockAvailabilityGroup2PrimaryReplicaServer -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value 'Secondary' -PassThru |
                                    Add-Member ScriptProperty AvailabilityReplicas {
                                        $mockAvailabilityGroupReplica2Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica2Object.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
                                        $mockAvailabilityGroupReplica2Object.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
                                        $mockAvailabilityGroupReplica2Object.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
                                        $mockAvailabilityGroupReplica2Object.Name = $mockAvailabilityGroupReplica2Name
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica3Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica3Object.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
                                        $mockAvailabilityGroupReplica3Object.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
                                        $mockAvailabilityGroupReplica3Object.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
                                        $mockAvailabilityGroupReplica3Object.Name = $mockAvailabilityGroupReplica3Name
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList
                                        
                                        return @{
                                            $mockAvailabilityGroupReplica2Name = $mockAvailabilityGroupReplica2Object
                                            $mockAvailabilityGroupReplica3Name = $mockAvailabilityGroupReplica3Object
                                        }
                                    } -PassThru -Force
                                )
                                $mockAvailabilityGroup3Name = ( 
                                    New-Object Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroup3Name -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockAvailabilityGroup3PrimaryReplicaServer -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value 'Primary' -PassThru |
                                    Add-Member ScriptProperty AvailabilityReplicas {
                                        $mockAvailabilityGroupReplica2Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica2Object.AvailabilityMode = $mockAvailabilityGroupReplica2AvailabilityMode
                                        $mockAvailabilityGroupReplica2Object.BackupPriority = $mockAvailabilityGroupReplica2BackupPriority
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica2ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica2ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica2Object.EndpointUrl = $mockAvailabilityGroupReplica2EndpointUrl
                                        $mockAvailabilityGroupReplica2Object.FailoverMode = $mockAvailabilityGroupReplica2FailoverMode
                                        $mockAvailabilityGroupReplica2Object.Name = $mockAvailabilityGroupReplica2Name
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica2ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica2Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica2ReadOnlyRoutingList

                                        $mockAvailabilityGroupReplica3Object = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                                        $mockAvailabilityGroupReplica3Object.AvailabilityMode = $mockAvailabilityGroupReplica3AvailabilityMode
                                        $mockAvailabilityGroupReplica3Object.BackupPriority = $mockAvailabilityGroupReplica3BackupPriority
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplica3ConnectionModeInPrimaryRole
                                        $mockAvailabilityGroupReplica3Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplica3ConnectionModeInSecondaryRole
                                        $mockAvailabilityGroupReplica3Object.EndpointUrl = $mockAvailabilityGroupReplica3EndpointUrl
                                        $mockAvailabilityGroupReplica3Object.FailoverMode = $mockAvailabilityGroupReplica3FailoverMode
                                        $mockAvailabilityGroupReplica3Object.Name = $mockAvailabilityGroupReplica3Name
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingConnectionUrl = $mockAvailabilityGroupReplica3ReadOnlyRoutingConnectionUrl
                                        $mockAvailabilityGroupReplica3Object.ReadOnlyRoutingList = $mockAvailabilityGroupReplica3ReadOnlyRoutingList
                                        
                                        return @{
                                            $mockAvailabilityGroupReplica2Name = $mockAvailabilityGroupReplica2Object
                                            $mockAvailabilityGroupReplica3Name = $mockAvailabilityGroupReplica3Object
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

        Describe 'xSQLServerAlwaysOnAvailabilityGroupReplica\Get-TargetResource' {
            BeforeEach {               
                $getTargetResourceParameters = @{
                    Name = $mockAvailabilityGroupReplicaName
                    AvailabilityGroupName = $mockAvailabilityGroupName
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockSqlInstanceName
                }

                $mockEndpoint = $mockDatabaseMirroringEndpointPresent

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable
            }

            Context 'When the Availability Group Replica is absent' {

                It 'Should not return an Availability Group Replica' {

                    $getTargetResourceParameters.Name = 'AbsentReplica'
                    $getTargetResourceParameters.AvailabilityGroupName = 'AbsentAG'
                    
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.AvailabilityGroupName | Should BeNullOrEmpty
                    $getTargetResourceResult.AvailabilityMode | Should BeNullOrEmpty
                    $getTargetResourceResult.BackupPriority | Should BeNullOrEmpty
                    $getTargetResourceResult.ConnectionModeInPrimaryRole | Should BeNullOrEmpty
                    $getTargetResourceResult.ConnectionModeInSecondaryRole | Should BeNullOrEmpty
                    $getTargetResourceResult.EndpointUrl | Should BeNullOrEmpty
                    $getTargetResourceResult.EndpointPort | Should Be $mockAvailabilityGroupReplica2EndpointPort
                    $getTargetResourceResult.Ensure | Should Be 'Absent'
                    $getTargetResourceResult.FailoverMode | Should BeNullOrEmpty
                    $getTargetResourceResult.Name | Should BeNullOrEmpty
                    $getTargetResourceResult.ReadOnlyRoutingConnectionUrl | Should BeNullOrEmpty
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
                    
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.AvailabilityGroupName | Should Be $mockAvailabilityGroupName
                    $getTargetResourceResult.AvailabilityMode | Should Be $mockAvailabilityMode
                    $getTargetResourceResult.BackupPriority | Should Be $mockBackupPriority
                    $getTargetResourceResult.ConnectionModeInPrimaryRole | Should Be $mockConnectionModeInPrimaryRole
                    $getTargetResourceResult.ConnectionModeInSecondaryRole | Should Be $mockConnectionModeInSecondaryRole
                    $getTargetResourceResult.EndpointUrl | Should Be $mockAvailabilityGroupReplica1EndpointUrl
                    $getTargetResourceResult.EndpointPort | Should Be $mockAvailabilityGroupReplica1EndpointPort
                    $getTargetResourceResult.Ensure | Should Be $mockEnsure
                    $getTargetResourceResult.FailoverMode | Should Be $mockFailoverMode
                    $getTargetResourceResult.Name | Should Be $mockSqlServer
                    $getTargetResourceResult.ReadOnlyRoutingConnectionUrl | Should Be $mockReadOnlyRoutingConnectionUrl
                    $getTargetResourceResult.ReadOnlyRoutingList | Should Be $mockSqlServer
                    $getTargetResourceResult.SQLServer | Should Be $mockSqlServer
                    $getTargetResourceResult.SQLInstanceName | Should Be $mockSqlInstanceName
                    $getTargetResourceResult.SQLServerNetName | Should Be $mockSqlServer

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupReplica\Set-TargetResource' {
            
            BeforeAll {
                Mock -CommandName Import-SQLPSModule -MockWith {} -Verifiable
                Mock -CommandName New-TerminatingError { $ErrorType } -Verifiable
            }

            BeforeEach {
                $mockEndpoint = $mockDatabaseMirroringEndpointPresent
                $mockLogins = $mockNtServiceClusSvcPresent
                $mockServer1IsHadrEnabled = $true

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer1Name }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer2Name }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer3 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer3Name }
                Mock -CommandName Join-SqlAvailabilityGroup -MockWith {} -Verifiable
                Mock -CommandName New-SqlAvailabilityReplica {} -Verifiable
                Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable
            }
            
            Context 'When the desired state is absent' {
                
                BeforeAll {
                    Mock -CommandName Update-AvailabilityGroupReplica {} -Verifiable
                }

                BeforeEach {                    
                    $setTargetResourceParameters = @{
                        Name = $mockSqlServer
                        AvailabilityGroupName = $mockAvailabilityGroupName
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockSqlInstanceName
                        Ensure = 'Absent'
                    }
                }
                
                It 'Should silently remove the availability group replica' {
                    
                    Mock -CommandName Remove-SqlAvailabilityReplica -MockWith {} -Verifiable
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (RemoveAvailabilityGroupReplicaFailed) when removing the availability group replica fails' {
                    
                    Mock -CommandName Remove-SqlAvailabilityReplica -MockWith { Throw 'RemoveAvailabilityGroupReplicaFailed' } -Verifiable
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'RemoveAvailabilityGroupReplicaFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
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
                        Name = $mockSqlServer
                        AvailabilityGroupName = $mockAvailabilityGroup2Name
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
                }

                It 'Should throw the correct error (HadrNotEnabled) when HADR is not enabled' {

                    $mockServer1IsHadrEnabled = $false
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'HadrNotEnabled'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (ClusterPermissionsMissing) when the logins "NT SERVICE\ClusSvc" or "NT AUTHORITY\SYSTEM" are absent' {
                    
                    $mockLogins = $mockAllLoginsAbsent.Clone()

                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'ClusterPermissionsMissing'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (ClusterPermissionsMissing) when the logins "NT SERVICE\ClusSvc" and "NT AUTHORITY\SYSTEM" do not have permissions to manage availability groups' {

                    $mockLogins = $mockAllLoginsPresent.Clone()
                    
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $false } -Verifiable

                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'ClusterPermissionsMissing'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should create the availability group replica when "NT SERVICE\ClusSvc" is present and has the permissions to manage availability groups' {

                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should create the availability group replica when "NT AUTHORITY\SYSTEM" is present and has the permissions to manage availability groups' {

                    $mockLogins = $mockNtAuthoritySystemPresent
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (DatabaseMirroringEndpointNotFound) when the database mirroring endpoint is not absent' {
                    
                    $mockEndpoint = $mockDatabaseMirroringEndpointAbsent
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'DatabaseMirroringEndpointNotFound'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should create the availability group replica when the endpoint hostname is not defined' {

                    $setTargetResourceParameters.EndpointHostName = ''
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should create the availability group replica when primary replica server is incorrectly supplied and the availability group exists' {
                    
                    $setTargetResourceParameters.PrimaryReplicaSQLServer = $mockServer3Name
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (CreateAvailabilityGroupReplicaFailed) when the availability group replica fails to create' {
                    
                    Mock -CommandName New-SqlAvailabilityReplica { throw } -Verifiable
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'CreateAvailabilityGroupReplicaFailed'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (JoinAvailabilityGroupFailed) when the availability group replica fails to join the availability group' {
                    
                    Mock -CommandName Join-SqlAvailabilityGroup -MockWith { throw } -Verifiable
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'JoinAvailabilityGroupFailed'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (AvailabilityGroupNotFound) when the availability group does not exist on the primary replica' {

                    $setTargetResourceParameters.AvailabilityGroupName = 'DoesNotExist'
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'AvailabilityGroupNotFound'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the desired state is present and the availability group is present' {
                
                BeforeAll {
                    Mock -CommandName Remove-SqlAvailabilityReplica -MockWith {} -Verifiable
                    Mock -CommandName Update-AvailabilityGroupReplica -MockWith $mockUpdateAvailabilityGroupReplica -Verifiable

                    # Create a hash table to provide test properties and values for the update tests
                    $mockTestProperties = @{
                        AvailabilityMode = 'SynchronousCommit'
                        BackupPriority = 75
                        ConnectionModeInPrimaryRole = 'AllowReadWriteConnections'
                        ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
                        FailoverMode = 'Automatic'
                        ReadOnlyRoutingConnectionUrl = 'TCP://TestHost.domain.com:1433'
                        ReadOnlyRoutingList = @('Server1','Server2')
                    }
                }

                BeforeEach {
                    $mockAlternateEndpointPort = $false
                    $mockAlternateEndpointProtocol = $false
                    
                    $setTargetResourceParameters = @{
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
                }

                It 'Should throw the correct error (ReplicaNotFound) when the availability group replica does not exist' {

                    $setTargetResourceParameters.Name = 'ReplicaNotFound'
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'ReplicaNotFound'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                foreach ( $mockTestProperty in $mockTestProperties.GetEnumerator() )
                {
                    It "Should set the property '$($mockTestProperty.Key)' to the desired state" {
                        
                        $mockAvailabilityGroupReplicaPropertyName = $mockTestProperty.Key
                        $mockAvailabilityGroupReplicaPropertyValue = $mockTestProperty.Value
                        $setTargetResourceParameters.$mockAvailabilityGroupReplicaPropertyName = $mockAvailabilityGroupReplicaPropertyValue
                        
                        { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                        
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                        Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 #-Exactly
                    }
                }

                It "Should set the Endpoint Hostname to the desired state" {
                    
                    $setTargetResourceParameters.EndpointHostName = 'AnotherEndpointHostName'

                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }
                
                It "Should set the Endpoint Port to the desired state" {

                    $mockAvailabilityGroupReplicaPropertyName = 'EndpointUrl'
                    $mockAvailabilityGroupReplicaPropertyValue = $mockAvailabilityGroupReplica1EndpointUrl
                    $mockAlternateEndpointPort = $true

                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It "Should set the Endpoint Protocol to the desired state" {
                    
                    $mockAvailabilityGroupReplicaPropertyName = 'EndpointUrl'
                    $mockAvailabilityGroupReplicaPropertyValue = $mockAvailabilityGroupReplica1EndpointUrl
                    $mockAlternateEndpointProtocol = $true

                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer1Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer2Name } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockServer3Name } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupReplica\Test-TargetResource' {

            BeforeEach {            
                $mockAlternateEndpointPort = $false
                $mockAlternateEndpointProtocol = $false
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

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable
            }

            Context 'When the desired state is absent' {
                
                It 'Should return $true when the Availability Replica is absent' {

                    $testTargetResourceParameters.Name = $mockAvailabilityGroupReplica2Name
                    $testTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroup2Name
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

                    $testTargetResourceParameters.Name = $mockAvailabilityGroupReplica2Name
                    $testTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroup2Name
                    
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
                    
                    $mockAlternateEndpointProtocol = $true
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present and the Endpoint Port is not in the desired state' {
                    
                    $mockAlternateEndpointPort = $true
                    
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
