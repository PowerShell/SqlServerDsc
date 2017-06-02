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
Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )



# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        $defaultAbsentParameters = @{
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

        $defaultPresentParameters = @{
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

        foreach ( $sqlVersion in @(12,13) )
        {
            # Create the availability replica
            $mockAvailabilityReplica = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityReplica.Name = 'Server1'
            $mockAvailabilityReplica.AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityReplica.BackupPriority = 50
            $mockAvailabilityReplica.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityReplica.ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityReplica.EndpointUrl = 'TCP://Server1:5022'
            $mockAvailabilityReplica.FailoverMode = 'Manual'

            # Create the availability replica collection to store the availability replicas in
            $mockAvailabilityReplicaCollection = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
            $mockAvailabilityReplicaCollection.Add($mockAvailabilityReplica)

            # Create the Availability Group
            $mockAvailabilityGroup = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup.Name = 'PresentAG'
            $mockAvailabilityGroup.AutomatedBackupPreference = 'Secondary'
            $mockAvailabilityGroup.FailureConditionLevel = 'OnServerDown'
            $mockAvailabilityGroup.HealthCheckTimeout = 30000
            $mockAvailabilityGroup.PrimaryReplicaServerName = 'Server1'
            $mockAvailabilityGroup.LocalReplicaRole = 'Primary'
            $mockAvailabilityGroup.AvailabilityReplicas = $mockAvailabilityReplicaCollection

            # Create the availability group collectionto store the availability groups in
            $mockAvailabilityGroupCollection = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
            $mockAvailabilityGroupCollection.Add($mockAvailabilityGroup)

            # Create the master database
            $mockMasterDatabaseObject = New-Object Microsoft.SqlServer.Management.Smo.Database
            $mockMasterDatabaseObject.ID = 1
            $mockMasterDatabaseObject.Name = 'master'

            # Create the databases collection
            $mockDatabaseCollection = New-Object Microsoft.SqlServer.Management.Smo.DatabaseCollection
            $mockDatabaseCollection.Add($mockMasterDatabaseObject)

            # Create the database mirroring endpoint
            $mockDatabaseMirroringEndpoint = New-Object Microsoft.SqlServer.Management.Smo.Endpoint
            $mockDatabaseMirroringEndpoint.Name = 'Hadr_endpoint'
            $mockDatabaseMirroringEndpoint.EndpointType = 'DatabaseMirroring'
            $mockDatabaseMirroringEndpoint.Protocol = @{
                TCP = @{
                    ListenerPort = 5022
                }
            }

            # Create the endpointcollection object
            $mockEndpointCollection = New-Object Microsoft.SqlServer.Management.Smo.EndpointCollection
            $mockEndpointCollection.Add($mockDatabaseMirroringEndpoint)

            # Create the server object
            $mockServerObject = New-Object Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.AvailabilityGroups = $mockAvailabilityGroupCollection
            $mockServerObject.Databases = $mockDatabaseCollection
            $mockServerObject.Endpoints = $mockEndpointCollection
            $mockServerObject.IsHadrEnabled = $true
            $mockServerObject.Logins = $mockLogins
            $mockServerObject.Name = 'Server1'
            $mockServerObject.NetName = 'Server1'
            $mockServerObject.Roles = @{}
            $mockServerObject.Version = @{
                Major = $sqlVersion
            }

            # Clone the server object to a version specific variable
            $mockConnectSqlServerObjectVariableName = "mockConnectSqlVersion$($sqlVersion)ServerObject"
            New-Variable -Name $mockConnectSqlServerObjectVariableName
            Set-Variable -Name $mockConnectSqlServerObjectVariableName -Value $mockServerObject.Clone()
        }

        $mockConnectSqlVersion12 = { $mockConnectSqlVersion12ServerObject }
        $mockConnectSqlVersion13 = { $mockConnectSqlVersion13ServerObject }

        $mockConnectSqlVersion12IncorrectEndpointProtocol = {
            $mock = New-Object PSObject -Property @{
                AvailabilityGroups = @{
                    PresentAG = @{
                        AutomatedBackupPreference = 'Secondary'
                        FailureConditionLevel = 'OnServerDown'
                        HealthCheckTimeout = 30000
                        Name = 'AvailabilityGroup1'
                        PrimaryReplicaServerName = 'Server1'
                        LocalReplicaRole = 'Primary'
                        AvailabilityReplicas = @{
                            Server1 = @{
                                AvailabilityMode = 'AsynchronousCommit'
                                BackupPriority = 50
                                ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                EndpointUrl = 'UDP://Server1:5022'
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
                Logins = $mockLogins
                Name = 'Server1'
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

        $mockConnectSqlVersion12IncorrectEndpointPort = {
            $mock = New-Object PSObject -Property @{
                AvailabilityGroups = @{
                    PresentAG = @{
                        AutomatedBackupPreference = 'Secondary'
                        FailureConditionLevel = 'OnServerDown'
                        HealthCheckTimeout = 30000
                        Name = 'AvailabilityGroup1'
                        PrimaryReplicaServerName = 'Server1'
                        LocalReplicaRole = 'Primary'
                        AvailabilityReplicas = @{
                            Server1 = @{
                                AvailabilityMode = 'AsynchronousCommit'
                                BackupPriority = 50
                                ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                EndpointUrl = 'TCP://Server1:1000'
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
                Logins = $mockLogins
                Name = 'Server1'
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

        $mockNewSqlAvailabilityReplica = {
            $mock = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mock.AvailabilityMode = 'AsynchronousCommit'
            $mock.BackupPriority = 50
            $mock.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mock.ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mock.EndpointUrl = 'TCP://Server1:5022'
            $mock.FailoverMode = 'Manual'
            $mock.Name = 'Server1'

            return $mock
        }

        $mockAvailabilityGroupProperty = '' # Set dynamically during runtime
        $mockAvailabilityGroupPropertyValue = '' # Set dynamically during runtime

        $mockUpdateAvailabilityGroup = {
            Param
            (
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
                $AvailabilityGroup
            )

            if ( $mockAvailabilityGroupPropertyValue -ne $AvailabilityGroup.$mockAvailabilityGroupProperty )
            {
                foreach ( $property in ( $AvailabilityGroup | Get-Member -MemberType Property | Select-Object -ExpandProperty Name ) )
                {
                    New-VerboseMessage -Message "$($property): $($AvailabilityGroup.$property) ($($defaultPresentParameters.$property))"
                }
                
                throw "Update-AvailabilityGroup should be setting the property '$($mockAvailabilityGroupProperty)' to '$($mockAvailabilityGroupPropertyValue)'"
            }
        }

        $mockAvailabilityGroupReplicaProperty = '' # Set dynamically during runtime
        $mockAvailabilityGroupReplicaPropertyValue = '' # Set dynamically during runtime

        $mockUpdateAvailabilityGroupReplica = {
            Param
            (
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
                $AvailabilityGroupReplica
            )

            if ( [string]::IsNullOrEmpty($mockAvailabilityGroupReplicaProperty) -and [string]::IsNullOrEmpty($mockAvailabilityGroupReplicaPropertyValue) )
            {
                return
            }

            if ( $mockAvailabilityGroupReplicaPropertyValue -ne $AvailabilityGroupReplica.$mockAvailabilityGroupReplicaProperty )
            {
                foreach ( $property in ( $AvailabilityGroupReplica | Get-Member -MemberType Property | Select-Object -ExpandProperty Name ) )
                {
                    New-VerboseMessage -Message "$($property): $($AvailabilityGroupReplica.$property) ($($defaultPresentParameters.$property))"
                }
                
                throw "Update-AvailabilityGroupReplica should be setting the property '$($mockAvailabilityGroupReplicaProperty)' to '$($mockAvailabilityGroupReplicaPropertyValue)'"
            }
        }
        
        Describe "xSQLServerAlwaysOnAvailabilityGroup\Get-TargetResource" {
            
            BeforeEach {
                $mockLogins = $mockAllLoginsPresent
            }
            
            Context 'When the Availability Group is Absent'{

                It 'Should not return an Availability Group when Ensure is set to Present and the version is 12' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    
                    $getParams = @{
                        Name = $defaultAbsentParameters.Name
                        SQLServer = $defaultAbsentParameters.SQLServer
                        SQLInstanceName = $defaultAbsentParameters.SQLInstanceName
                    }
                    
                    # Get the current state
                    $result = Get-TargetResource @getParams

                    $result.Ensure | Should Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should not return an Availability Group when Ensure is set to Present and the version is 13' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    
                    $getParams = @{
                        Name = $defaultAbsentParameters.Name
                        SQLServer = $defaultAbsentParameters.SQLServer
                        SQLInstanceName = $defaultAbsentParameters.SQLInstanceName
                    }
                    
                    # Get the current state
                    $result = Get-TargetResource @getParams

                    $result.Ensure | Should Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present'{

                It 'Should return the correct Availability Group properties when Ensure is set to Present and the SQL version is 12' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It

                    $getParams = @{
                        Name = $defaultPresentParameters.Name
                        SQLServer = $defaultPresentParameters.SQLServer
                        SQLInstanceName = $defaultPresentParameters.SQLInstanceName
                    }
                    
                    # Get the current state
                    $result = Get-TargetResource @getParams

                    $result.Name | Should Be $defaultPresentParameters.Name
                    $result.SQLServer | Should Be $defaultPresentParameters.SQLServer
                    $result.SQLInstanceName | Should Be $defaultPresentParameters.SQLInstanceName
                    $result.Ensure | Should Be 'Present'
                    $result.AutomatedBackupPreference | Should Be 'Secondary'
                    $result.AvailabilityMode | Should Be 'AsynchronousCommit'
                    $result.BackupPriority | Should Be 50
                    $result.ConnectionModeInPrimaryRole | Should Be 'AllowAllConnections'
                    $result.ConnectionModeInSecondaryRole | Should Be 'AllowNoConnections'
                    $result.FailureConditionLevel | Should Be 'OnServerDown'
                    $result.FailoverMode | Should Be 'Manual'
                    $result.HealthCheckTimeout | Should Be 30000
                    $result.BasicAvailabilityGroup | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return the correct Availability Group properties when Ensure is set to Absent and the SQL version is 12' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    
                    $getParams = @{
                        Name = $defaultPresentParameters.Name
                        SQLServer = $defaultPresentParameters.SQLServer
                        SQLInstanceName = $defaultPresentParameters.SQLInstanceName
                    }
                    
                    # Get the current state
                    $result = Get-TargetResource @getParams

                    $result.Name | Should Be $defaultPresentParameters.Name
                    $result.SQLServer | Should Be $defaultPresentParameters.SQLServer
                    $result.SQLInstanceName | Should Be $defaultPresentParameters.SQLInstanceName
                    $result.Ensure | Should Be 'Present'
                    $result.AutomatedBackupPreference | Should Be 'Secondary'
                    $result.AvailabilityMode | Should Be 'AsynchronousCommit'
                    $result.BackupPriority | Should Be 50
                    $result.ConnectionModeInPrimaryRole | Should Be 'AllowAllConnections'
                    $result.ConnectionModeInSecondaryRole | Should Be 'AllowNoConnections'
                    $result.FailureConditionLevel | Should Be 'OnServerDown'
                    $result.FailoverMode | Should Be 'Manual'
                    $result.HealthCheckTimeout | Should Be 30000
                    $result.BasicAvailabilityGroup | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return the correct Availability Group properties when Ensure is set to Present and the SQL version is 13' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It

                    $getParams = @{
                        Name = $defaultPresentParameters.Name
                        SQLServer = $defaultPresentParameters.SQLServer
                        SQLInstanceName = $defaultPresentParameters.SQLInstanceName
                    }
                    
                    # Get the current state
                    $result = Get-TargetResource @getParams

                    $result.Name | Should Be $defaultPresentParameters.Name
                    $result.SQLServer | Should Be $defaultPresentParameters.SQLServer
                    $result.SQLInstanceName | Should Be $defaultPresentParameters.SQLInstanceName
                    $result.Ensure | Should Be 'Present'
                    $result.AutomatedBackupPreference | Should Be 'Secondary'
                    $result.AvailabilityMode | Should Be 'AsynchronousCommit'
                    $result.BackupPriority | Should Be 50
                    $result.ConnectionModeInPrimaryRole | Should Be 'AllowAllConnections'
                    $result.ConnectionModeInSecondaryRole | Should Be 'AllowNoConnections'
                    $result.FailureConditionLevel | Should Be 'OnServerDown'
                    $result.FailoverMode | Should Be 'Manual'
                    $result.HealthCheckTimeout | Should Be 30000
                    $result.BasicAvailabilityGroup | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return the correct Availability Group properties when Ensure is set to Absent and the SQL version is 13' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    
                    $getParams = @{
                        Name = $defaultPresentParameters.Name
                        SQLServer = $defaultPresentParameters.SQLServer
                        SQLInstanceName = $defaultPresentParameters.SQLInstanceName
                    }
                    
                    # Get the current state
                    $result = Get-TargetResource @getParams

                    $result.Name | Should Be $defaultPresentParameters.Name
                    $result.SQLServer | Should Be $defaultPresentParameters.SQLServer
                    $result.SQLInstanceName | Should Be $defaultPresentParameters.SQLInstanceName
                    $result.Ensure | Should Be 'Present'
                    $result.AutomatedBackupPreference | Should Be 'Secondary'
                    $result.AvailabilityMode | Should Be 'AsynchronousCommit'
                    $result.BackupPriority | Should Be 50
                    $result.ConnectionModeInPrimaryRole | Should Be 'AllowAllConnections'
                    $result.ConnectionModeInSecondaryRole | Should Be 'AllowNoConnections'
                    $result.FailureConditionLevel | Should Be 'OnServerDown'
                    $result.FailoverMode | Should Be 'Manual'
                    $result.HealthCheckTimeout | Should Be 30000
                    $result.BasicAvailabilityGroup | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe "xSQLServerAlwaysOnAvailabilityGroup\Set-TargetResource" {
            
            BeforeEach {
                $mockLogins = $mockAllLoginsPresent # Need this for legacy purposes
                $mockConnectSqlVersion12ServerObject.Logins = $mockAllLoginsPresent
                $mockConnectSqlVersion13ServerObject.Logins = $mockAllLoginsPresent
            }
            
            Mock -CommandName Invoke-Query -MockWith {} -Verifiable
            Mock -CommandName Import-SQLPSModule -MockWith {} -Verifiable
            Mock -CommandName New-TerminatingError { $ErrorType } -Verifiable

            Context 'When the Availability Group is Absent' {

                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -Verifiable -Scope Context
                Mock -CommandName Update-AvailabilityGroup -MockWith {} -Verifiable -Scope Context
                Mock -CommandName Update-AvailabilityGroupReplica -MockWith {} -Verifiable -Scope Context
                
                It 'Should create the Availability Group when Ensure is set to Present and the SQL version is 12' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $false } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    
                    $defaultAbsentParameters.Ensure = 'Present'

                    { Set-TargetResource @defaultAbsentParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should create the Availability Group when Ensure is set to Present and the SQL version is 13' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $false } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    
                    $defaultAbsentParameters.Ensure = 'Present'
                    $defaultAbsentParameters.BasicAvailabilityGroup = $true

                    { Set-TargetResource @defaultAbsentParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, HadrNotEnabled, when Ensure is set to Present, but Always On is not enabled' {
                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object PSObject -Property @{ 
                            IsHadrEnabled = $false
                        }
                    } -Verifiable -Scope It
                    Mock -CommandName Invoke-Query -MockWith {} -Verifiable
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $false } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    
                    $defaultAbsentParameters.Ensure = 'Present'
                    
                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'HadrNotEnabled'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error (ClusterPermissionsMissing) when the logins "NT SERVICE\ClusSvc" or "NT AUTHORITY\SYSTEM" are absent' {
                    
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It

                    $defaultAbsentParameters.Ensure = 'Present'
                    $mockConnectSqlVersion12ServerObject.Logins = $mockAllLoginsAbsent.Clone()
                    
                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'ClusterPermissionsMissing'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
                
                It 'Should create the Availability Group when Ensure is set to Present and NT AUTHORITY\SYSTEM has the correct permissions' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $false } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    
                    $defaultAbsentParameters.Ensure = 'Present'

                    { Set-TargetResource @defaultAbsentParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
                
                It 'Should throw the correct error, ClusterPermissionsMissing, when Ensure is set to Present, but the cluster does not have the correct permissions' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $false } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $false } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    
                    $defaultAbsentParameters.Ensure = 'Present'
                    
                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'ClusterPermissionsMissing'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT AUTHORITY\SYSTEM' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, DatabaseMirroringEndpointNotFound, when Ensure is set to Present, but no DatabaseMirroring endpoints are present' {
                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object PSObject -Property @{ 
                            AvailabilityGroups = @()
                            Endpoints = @()
                            IsHadrEnabled = $true
                            Logins = $mockNtServiceClusSvcPresent
                        }
                    } -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultAbsentParameters.Ensure = 'Present'
                    
                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'DatabaseMirroringEndpointNotFound'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
                
                It 'Should throw the correct error, CreateAvailabilityGroupReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is 12' {
                    
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith { throw 'CreateAvailabilityGroupReplicaFailed' } -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultAbsentParameters.Ensure = 'Present'
                    
                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupReplicaFailed'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, CreateAvailabilityGroupReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is 13' {
                    
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith { throw 'CreateAvailabilityGroupReplicaFailed' } -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultAbsentParameters.Ensure = 'Present'
                    
                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupReplicaFailed'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is 12' {
                    
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup { throw 'CreateAvailabilityGroupFailed' } -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Mock -CommandName Test-TargetResource -MockWith {$false} -Verifiable -Scope It
                    
                    $defaultAbsentParameters.Ensure = 'Present'
                    
                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupFailed'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is 13' {
                    
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -Scope It
                    Mock -CommandName New-SqlAvailabilityGroup { throw 'CreateAvailabilityGroupFailed' } -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Mock -CommandName Test-TargetResource -MockWith {$false} -Scope It
                    
                    $defaultAbsentParameters.Ensure = 'Present'

                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupFailed'
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the Availability Group is Present' {
                BeforeEach {
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable
                    Mock -CommandName Update-AvailabilityGroup -MockWith $mockUpdateAvailabilityGroup -Verifiable
                    Mock -CommandName Update-AvailabilityGroupReplica -MockWith $mockUpdateAvailabilityGroupReplica -Verifiable
                }
                
                It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is 12' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith {} -Verifiable -Scope It
                    
                    $defaultPresentParameters.Ensure = 'Absent'
                    
                    { Set-TargetResource @defaultPresentParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is 13' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith {} -Verifiable -Scope It
                    
                    $defaultPresentParameters.Ensure = 'Absent'
                    
                    { Set-TargetResource @defaultPresentParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
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
                                    PrimaryReplicaServerName = 'Server1'
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
                    } -Verifiable -Scope It
                    
                    Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith {} -Verifiable -Scope It
                    
                    $defaultPresentParameters.Ensure = 'Absent'
                    
                    { Set-TargetResource @defaultPresentParameters } | Should Throw 'InstanceNotPrimaryReplica'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error message when Ensure is set to Absent but the Availability Group remove fails, and the SQL version is 12' {
                    
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName Remove-SqlAvailabilityGroup -MockWith { throw 'RemoveAvailabilityGroupFailed' } -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith {} -Verifiable -Scope It
                    
                    $defaultPresentParameters.Ensure = 'Absent'
                    
                    { Set-TargetResource @defaultPresentParameters } | Should Throw 'RemoveAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error message when Ensure is set to Absent but the Availability Group remove fails, and the SQL version is 13' {
                    
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    Mock -CommandName Remove-SqlAvailabilityGroup -MockWith { throw 'RemoveAvailabilityGroupFailed' } -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith {} -Verifiable -Scope It
                    
                    $defaultPresentParameters.Ensure = 'Absent'
                    
                    { Set-TargetResource @defaultPresentParameters } | Should Throw 'RemoveAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should connect to the instance hosting the primary replica when the LocalReplicaRole is not Primary' {

                    Mock -CommandName Connect-SQL -MockWith {
                        $mock = New-Object PSObject -Property @{
                            AvailabilityGroups = @{
                                PresentAG = @{
                                    AutomatedBackupPreference = 'Secondary'
                                    FailureConditionLevel = 'OnServerDown'
                                    HealthCheckTimeout = 30000
                                    Name = 'AvailabilityGroup1'
                                    PrimaryReplicaServerName = 'Server2'
                                    LocalReplicaRole = 'Secondary'
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
                            Logins = $mockLogins
                            Name = 'Server1'
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
                    } -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    
                    Mock -CommandName Connect-SQL -MockWith {
                        $mock = New-Object PSObject -Property @{
                            AvailabilityGroups = @{
                                PresentAG = @{
                                    AutomatedBackupPreference = 'Secondary'
                                    FailureConditionLevel = 'OnServerDown'
                                    HealthCheckTimeout = 30000
                                    Name = 'AvailabilityGroup1'
                                    PrimaryReplicaServerName = 'Server2'
                                    LocalReplicaRole = 'Primary'
                                    AvailabilityReplicas = @{
                                        Server1 = @{
                                            AvailabilityMode = 'AsynchronousCommit'
                                            BackupPriority = 50
                                            ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                            ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                            EndpointUrl = 'TCP://Server2:5022'
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
                            Logins = $mockLogins
                            Name = 'Server1'
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
                    } -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server2' }
                    
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $mockAvailabilityGroupReplicaProperty = ''
                    $mockAvailabilityGroupReplicaPropertyValue = ''
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }
                
                It 'Should set the AutomatedBackupPreference to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.AutomatedBackupPreference = 'Primary'
                    $mockAvailabilityGroupProperty = 'AutomatedBackupPreference'
                    $mockAvailabilityGroupPropertyValue = 'Primary'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AutomatedBackupPreference = $defaultPresentParameters.AutomatedBackupPreference
                }

                It 'Should set the AvailabilityMode to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.AvailabilityMode = 'SynchronousCommit'
                    $mockAvailabilityGroupReplicaProperty = 'AvailabilityMode'
                    $mockAvailabilityGroupReplicaPropertyValue = 'SynchronousCommit'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].AvailabilityMode = $defaultPresentParameters.AvailabilityMode
                }

                It 'Should set the BackupPriority to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.BackupPriority = 42
                    $mockAvailabilityGroupReplicaProperty = 'BackupPriority'
                    $mockAvailabilityGroupReplicaPropertyValue = 42
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].BackupPriority = $defaultPresentParameters.BackupPriority
                }

                It 'Should set the BasicAvailabilityGroup to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.BasicAvailabilityGroup = $true
                    $mockAvailabilityGroupProperty = 'BasicAvailabilityGroup'
                    $mockAvailabilityGroupPropertyValue = $true
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly

                    $mockConnectSqlVersion13ServerObject.AvailabilityGroups['PresentAG'].BasicAvailabilityGroup = $defaultPresentParameters.BasicAvailabilityGroup
                }

                It 'Should set the ConnectionModeInPrimaryRole to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.ConnectionModeInPrimaryRole = 'AllowReadWriteConnections'
                    $mockAvailabilityGroupReplicaProperty = 'ConnectionModeInPrimaryRole'
                    $mockAvailabilityGroupReplicaPropertyValue = 'AllowReadWriteConnections'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].ConnectionModeInPrimaryRole = $defaultPresentParameters.ConnectionModeInPrimaryRole
                    $mockConnectSqlVersion13ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].ConnectionModeInPrimaryRole = $defaultPresentParameters.ConnectionModeInPrimaryRole
                }

                It 'Should set the ConnectionModeInSecondaryRole to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
                    $mockAvailabilityGroupReplicaProperty = 'ConnectionModeInSecondaryRole'
                    $mockAvailabilityGroupReplicaPropertyValue = 'AllowReadIntentConnectionsOnly'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].ConnectionModeInSecondaryRole = $defaultPresentParameters.ConnectionModeInSecondaryRole
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
                                    PrimaryReplicaServerName = 'Server1'
                                    LocalReplicaRole = 'Primary'
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
                            Logins = $mockLogins
                            Name = 'Server1'
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
                    } -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $mockAvailabilityGroupReplicaProperty = 'EndpointUrl'
                    $mockAvailabilityGroupReplicaPropertyValue = 'TCP://Server1:5022'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].EndpointUrl = $mockAvailabilityReplica.EndpointUrl
                }

                It 'Should set the EndpointUrl to the desired state when the EndpointHostName is specified' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.EndpointHostName = 'TestServer.Contoso.com'
                    $mockAvailabilityGroupReplicaProperty = 'EndpointUrl'
                    $mockAvailabilityGroupReplicaPropertyValue = 'TCP://TestServer.Contoso.com:5022'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].EndpointUrl = $mockAvailabilityReplica.EndpointUrl
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
                                    PrimaryReplicaServerName = 'Server1'
                                    LocalReplicaRole = 'Primary'
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
                            Logins = $mockLogins
                            Name = 'Server1'
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
                    } -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.Remove('EndpointHostName')
                    $mockAvailabilityGroupReplicaProperty = 'EndpointUrl'
                    $mockAvailabilityGroupReplicaPropertyValue = 'TCP://Server1:5022'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].EndpointUrl = $mockAvailabilityReplica.EndpointUrl
                }

                It 'Should set the EndpointUrl to the desired state when the endpoint protocol is changed' {

                    Mock -CommandName Connect-SQL -MockWith {
                        $mock = New-Object PSObject -Property @{
                            AvailabilityGroups = @{
                                PresentAG = @{
                                    AutomatedBackupPreference = 'Secondary'
                                    FailureConditionLevel = 'OnServerDown'
                                    HealthCheckTimeout = 30000
                                    Name = 'AvailabilityGroup1'
                                    PrimaryReplicaServerName = 'Server1'
                                    LocalReplicaRole = 'Primary'
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
                            Logins = $mockLogins
                            Name = 'Server1'
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
                    } -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $mockAvailabilityGroupReplicaProperty = 'EndpointUrl'
                    $mockAvailabilityGroupReplicaPropertyValue = 'TCP://Server1:5022'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].EndpointUrl = $mockAvailabilityReplica.EndpointUrl
                }

                It 'Should set the FailureConditionLevel to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.FailureConditionLevel = 'OnAnyQualifiedFailureCondition'
                    $mockAvailabilityGroupProperty = 'FailureConditionLevel'
                    $mockAvailabilityGroupPropertyValue = 'OnAnyQualifiedFailureCondition'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].FailureConditionLevel = $defaultPresentParameters.FailureConditionLevel
                }

                It 'Should set the FailoverMode to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.FailoverMode = 'Automatic'
                    $mockAvailabilityGroupReplicaProperty = 'FailoverMode'
                    $mockAvailabilityGroupReplicaPropertyValue = 'Automatic'
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].FailoverMode = $defaultPresentParameters.FailoverMode
                }

                It 'Should set the HealthCheckTimeout to the desired state' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    Mock -CommandName Test-LoginEffectivePermissions -MockWith { $true } -Verifiable -Scope It -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    
                    $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                    $defaultPresentParametersIncorrectProperties.HealthCheckTimeout = 42
                    $mockAvailabilityGroupProperty = 'HealthCheckTimeout'
                    $mockAvailabilityGroupPropertyValue = 42
                    
                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter { $LoginName -eq 'NT SERVICE\ClusSvc' }
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].HealthCheckTimeout = $defaultPresentParameters.HealthCheckTimeout
                }
            }
        }

        Describe "xSQLServerAlwaysOnAvailabilityGroup\Test-TargetResource" {
            
            BeforeEach {
                $mockLogins = $mockAllLoginsPresent
            }
            
            Context 'When the Availability Group is Absent' {

                It 'Should be $false when the desired state is Present and the SQL version is 12' {

                    $defaultAbsentParameters.Ensure = 'Present'
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    
                    Test-TargetResource @defaultAbsentParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $true when the desired state is Absent and the SQL version is 12' {

                    $defaultAbsentParameters.Ensure = 'Absent'
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It

                    Test-TargetResource @defaultAbsentParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $false when the desired state is Present and the SQL version is 13' {

                    $defaultAbsentParameters.Ensure = 'Present'
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    
                    Test-TargetResource @defaultAbsentParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $true when the desired state is Absent and the SQL version is 13' {

                    $defaultAbsentParameters.Ensure = 'Absent'
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It

                    Test-TargetResource @defaultAbsentParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present' {

                It 'Should be $false when the desired state is Absent and the SQL version is 12' {

                    $defaultPresentParameters.Ensure = 'Absent'
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    
                    Test-TargetResource @defaultPresentParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $true when the desired state is Present and the SQL version is 12' {
                    
                    $defaultPresentParameters.Ensure = 'Present'
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    
                    Test-TargetResource @defaultPresentParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $false when the desired state is Present, there is a parameter not correctly set, and the SQL version is 12' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It

                    $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                    $defaultPresentParametersIncorrectParameter.AvailabilityMode = 'SynchronousCommit'
                    
                    Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $false when the desired state is Absent and the SQL version is 13' {

                    $defaultPresentParameters.Ensure = 'Absent'
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    
                    Test-TargetResource @defaultPresentParameters | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $true when the desired state is Present and the SQL version is 13' {
                    
                    $defaultPresentParameters.Ensure = 'Present'
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It
                    
                    Test-TargetResource @defaultPresentParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $false when the desired state is Present, there is a parameter not correctly set, and the SQL version is 13' {

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -Verifiable -Scope It

                    $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                    $defaultPresentParametersIncorrectParameter.AvailabilityMode = 'SynchronousCommit'
                    $defaultPresentParametersIncorrectParameter.BasicAvailabilityGroup = $true
                    
                    Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $true when the desired state is Present and the Endpoint Host Name is not specified' {
                    $defaultPresentParametersEndpointHostNameNotSpecified = $defaultPresentParameters.Clone()
                    $defaultPresentParametersEndpointHostNameNotSpecified.Ensure = 'Present'
                    $defaultPresentParametersEndpointHostNameNotSpecified.Remove('EndpointHostName')
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It
                    
                    Test-TargetResource @defaultPresentParametersEndpointHostNameNotSpecified | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
                
                It 'Should be $false when the desired state is Present and the Endpoint Hostname is incorrectly configured' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -Verifiable -Scope It

                    $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                    $defaultPresentParametersIncorrectParameter.EndpointHostName = 'server1.contoso.com'
                    
                    Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $false when the desired state is Present and the Endpoint Protocol is incorrectly configured' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12IncorrectEndpointProtocol -Verifiable -Scope It

                    $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                    
                    Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $false when the desired state is Present and the Endpoint Port is incorrectly configured' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12IncorrectEndpointPort -Verifiable -Scope It

                    $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                    $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                    
                    Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe "xSQLServerAlwaysOnAvailabilityGroup\Update-AvailabilityGroup" {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType }
            
            Context 'When the Availability Group is altered' {
                It 'Should silently alter the Availability Group' {
                    $ag = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    
                    { Update-AvailabilityGroup -AvailabilityGroup $ag } | Should Not Throw

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, AlterAvailabilityGroupFailed, when altering the Availaiblity Group fails' {
                    $ag = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $ag.Name = 'AlterFailed'
                    
                    { Update-AvailabilityGroup -AvailabilityGroup $ag } | Should Throw 'AlterAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
