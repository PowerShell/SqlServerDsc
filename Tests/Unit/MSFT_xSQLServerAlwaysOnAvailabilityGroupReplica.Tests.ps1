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
        
        $mockSqlServer = 'Server2'
        $mockSqlInstanceName = 'MSSQLSERVER'
        $mockPrimaryReplicaSQLServer = 'Server1'
        $mockPrimaryReplicaSQLInstanceName = 'MSSQLSERVER'
        $mockSecondaryReplicaSQLServer = 'Server3'
        $mockAvailabilityGroupName = 'AG_AllReplicasPresent'
        $mockAvailabilityGroupNameWithAbsentReplica = 'AG_AbsentReplica'
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
        $mockReadOnlyRoutingConnectionUrl = "TCP://$($mockSqlServer).domain.com:1433"
        $mockReadOnlyRoutingList = @($mockSqlServer)

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

        #region Availabilty Group mocks

        $mockAvailabilityGroups = @{}

        $mockAvailabilityGroupsAbsent = @{}

        $mockAvailabilityGroupsPresent = @{
            $mockAvailabilityGroupName = ( 
                New-Object Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroupName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockPrimaryReplicaSQLServer -PassThru |
                Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value $mockLocalReplicaRole -PassThru |
                Add-Member ScriptProperty AvailabilityReplicas {
                    return $mockAvailabilityGroupReplica
                } -PassThru -Force
            )
        }

        #endregion
        
        #region Function mocks

        $mockConnectSql = {
            
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
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $SQLServer -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'NetName' -Value $SQLServer -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsHadrEnabled' -Value $mockIsHadrEnabled -PassThru |
                        Add-Member ScriptProperty Logins {
                            return $mockLogins
                        } -PassThru -Force |
                        Add-Member ScriptProperty AvailabilityGroups {
                            return $mockAvailabilityGroups
                        } -PassThru -Force | 
                        Add-Member ScriptProperty Endpoints {
                            return $mockEndpoint
                        } -PassThru -Force
                )
            )

            if ( @($mockPrimaryReplicaSQLServer, $mockSecondaryReplicaSQLServer) -contains $SQLServer )
            {
                if ( -not $mock.AvailabilityGroups.$mockAvailabilityGroupNameWithAbsentReplica )
                {
                    $mock.AvailabilityGroups.Add(
                        $mockAvailabilityGroupNameWithAbsentReplica,
                        ( 
                            New-Object Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroupNameWithAbsentReplica -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'PrimaryReplicaServerName' -Value $mockPrimaryReplicaSQLServer -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'LocalReplicaRole' -Value 'Primary' -PassThru |
                            Add-Member ScriptProperty AvailabilityReplicas {
                                return $mockAvailabilityGroupReplica
                            } -PassThru -Force
                        )
                    )
                }

                switch ( $SQLServer )
                {
                    $mockPrimaryReplicaSQLServer
                    {
                        $mock.AvailabilityGroups.$mockAvailabilityGroupNameWithAbsentReplica.LocalReplicaRole = 'Primary'
                    }

                    $mockSecondaryReplicaSQLServer
                    {
                        $mock.AvailabilityGroups.$mockAvailabilityGroupNameWithAbsentReplica.LocalReplicaRole = 'Secondary'
                    }
                }
            }

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

                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasPrimary
                    $mockAvailabilityGroups = $mockAvailabilityGroupsAbsent
                    $mockEndpoint = $mockDatabaseMirroringEndpointPresent
                    
                    
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.AvailabilityGroupName | Should BeNullOrEmpty
                    $getTargetResourceResult.AvailabilityMode | Should BeNullOrEmpty
                    $getTargetResourceResult.BackupPriority | Should BeNullOrEmpty
                    $getTargetResourceResult.ConnectionModeInPrimaryRole | Should BeNullOrEmpty
                    $getTargetResourceResult.ConnectionModeInSecondaryRole | Should BeNullOrEmpty
                    $getTargetResourceResult.EndpointUrl | Should BeNullOrEmpty
                    $getTargetResourceResult.EndpointPort | Should Be 5022
                    $getTargetResourceResult.Ensure | Should Be $mockEnsure
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
                    
                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasAll
                    $mockAvailabilityGroups = $mockAvailabilityGroupsPresent
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
                Mock -CommandName Update-AvailabilityGroupReplica {} -Verifiable
            }

            BeforeEach {
                $mockEndpoint = $mockDatabaseMirroringEndpointPresent
                $mockIsHadrEnabled = $true
                $mockLogins = $mockNtServiceClusSvcPresent.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable -ParameterFilter { $SQLServer -eq $mockSqlServer }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer }
                Mock -CommandName Join-SqlAvailabilityGroup -MockWith {} -Verifiable
                Mock -CommandName New-SqlAvailabilityReplica {} -Verifiable
                Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable
            }
            
            Context 'When the desired state is absent' {
                
                BeforeEach {
                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasAll.Clone()
                    $mockAvailabilityGroups = $mockAvailabilityGroupsPresent.Clone()
                    
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

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                }

                BeforeEach {
                    $mockAvailabilityGroupReplica = @{}
                    $mockAvailabilityGroups = $mockAvailabilityGroupsAbsent.Clone()
                    
                    $setTargetResourceParameters = @{
                        Name = $mockSqlServer
                        AvailabilityGroupName = $mockAvailabilityGroupNameWithAbsentReplica
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
                    
                    $mockIsHadrEnabled = $false

                    { Set-TargetResource @setTargetResourceParameters } | Should Throw 'HadrNotEnabled'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should create the availability group replica when primary replica server is incorrectly supplied and the availability group exists' {
                    
                    $setTargetResourceParameters.PrimaryReplicaSQLServer = $mockSecondaryReplicaSQLServer
                    
                    { Set-TargetResource @setTargetResourceParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 1 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSqlServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockPrimaryReplicaSQLServer } -Times 1 -Exactly
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -ParameterFilter { $SQLServer -eq $mockSecondaryReplicaSQLServer } -Times 0 -Exactly
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
                    $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasAll
                    Mock -CommandName Remove-SqlAvailabilityReplica -MockWith {} -Verifiable
                }

                BeforeEach {
                    $mockAvailabilityGroups = $mockAvailabilityGroupsPresent
                    
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

            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupReplica\Test-TargetResource' {

            BeforeEach {            
                $mockAvailabilityGroupReplica = $mockAvailabilityGroupReplicasAll
                $mockAvailabilityGroups = $mockAvailabilityGroupsPresent
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
                    
                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the Availability Replica is present and the Endpoint Port is not in the desired state' {
                    
                    $mockEndpointPort = '1234'
                    
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