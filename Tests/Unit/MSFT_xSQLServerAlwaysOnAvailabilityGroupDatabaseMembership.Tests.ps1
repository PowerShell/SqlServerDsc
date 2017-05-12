#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Import-Module (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent) -ChildPath 'xSQLServerHelper.psm1') -Scope Global -Force

# Loading mocked classes
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xSQLServer' `
    -DSCResourceName 'MSFT_xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    # TODO: Other Optional Cleanup Code Goes Here...
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership' {

        #region Parameter Mocks

            # The databases defined in the resource
            $mockDatabaseNameParameter = @(
                'DB*'
                'AnotherDB'
                '3rd*OfDatabase'
                '4th*OfDatabase'
            )

            $mockDatabaseNameParameterWithNonExistingDatabases = @(
                'NotFound*'
                'Unknown1'
            )

        #endregion Parameter Mocks

        #region Availability Group Mocks

            $mockAvailabilityDatabaseNames = @(
                'DB2'
                '3rdTypeOfDatabase'
                'UndefinedDatabase'
            )

            $mockAvailabilityDatabaseAbsentResults = @(
                'DB2'
                '3rdTypeOfDatabase'
            )

            $mockAvailabilityDatabaseExactlyAddResults = @(
                'DB1'
            )
            
            $mockAvailabilityDatabaseExactlyRemoveResults = @(
                'UndefinedDatabase'
            )

            $mockAvailabilityDatabasePresentResults = @(
                'DB1'
            )

            $mockAvailabilityDatabaseObjects = @()
            foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
            {
                $newAvailabilityDatabaseObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
                $newAvailabilityDatabaseObject.Name = $mockAvailabilityDatabaseName
                $mockAvailabilityDatabaseObjects += $newAvailabilityDatabaseObject
            }
            
            $mockBadAvailabilityGroupObject = New-Object -TypeName Object

            $mockAvailabilityGroupObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupObject.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
            $mockAvailabilityGroupObject.Name = 'AvailabilityGroup1'
            $mockAvailabilityGroupObject.PrimaryReplicaServerName = 'Server1'

            $mockAvailabilityGroupWithoutDatabasesObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityDatabases = @()
            $mockAvailabilityGroupWithoutDatabasesObject.Name = 'AvailabilityGroupWithoutDatabases'
            $mockAvailabilityGroupWithoutDatabasesObject.PrimaryReplicaServerName = 'Server1'

            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name = 'AvailabilityGroup2'
            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.PrimaryReplicaServerName = 'Server2'

        #endregion Availability Group Mocks

        #region Database Mocks

            # The databases found on the instance
            $mockPresentDatabaseNames = @(
                'DB1'
                'DB2'
                '3rdTypeOfDatabase'
                'UndefinedDatabase'
            )

            $mockDatabaseObjects = @()
            foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
            {
                $newDatabaseObject = New-Object Microsoft.SqlServer.Management.Smo.Database
                $newDatabaseObject.Name = $mockPresentDatabaseName
                $mockDatabaseObjects += $newDatabaseObject
            }

        #endregion Database Mocks
        
        #region Server mocks
            
            $mockBadServerObject = New-Object -TypeName Object
                        
            $mockServerObject = New-Object Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.AvailabilityGroups = @{
                $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupObject
                $mockAvailabilityGroupWithoutDatabasesObject.Name = $mockAvailabilityGroupWithoutDatabasesObject
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer
            }
            $mockServerObject.Databases = $mockDatabaseObjects
            $mockServerObject.DomainInstanceName = 'Server1'

            $mockPrimaryServerObject = New-Object Microsoft.SqlServer.Management.Smo.Server
            $mockPrimaryServerObject.AvailabilityGroups = @{
                $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupObject
                $mockAvailabilityGroupWithoutDatabasesObject.Name = $mockAvailabilityGroupWithoutDatabasesObject
                $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer
            }
            $mockPrimaryServerObject.Databases = $mockDatabaseObjects
            $mockPrimaryServerObject.DomainInstanceName = 'Server2'

        #endregion Server mocks
        
        Describe 'xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\Get()' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable
            }

            BeforeEach {
                $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameter.Clone()
                $databaseMembershipClass.SqlServer = 'Server1'
                $databaseMembershipClass.SQLInstanceName = 'MSSQLSERVER'
                $databaseMembershipClass.AvailabilityGroupName = 'AvailabilityGroup1'
            }

            Context 'When the Get method is called' {

                It 'Should not return an availability group name or availability databases when the availability group does not exist' {

                    $databaseMembershipClass.AvailabilityGroupName = 'NonExistentAvailabilityGroup'

                    $result = $databaseMembershipClass.Get()

                    $result.SqlServer | Should Be $databaseMembershipClass.SqlServer
                    $result.SQLInstanceName | Should Be $databaseMembershipClass.SQLInstanceName
                    $result.AvailabilityGroupName | Should BeNullOrEmpty
                    $result.DatabaseName | Should BeNullOrEmpty
                    $result.BackupPath | Should BeNullOrEmpty
                    $result.Ensure | Should Be 'Present'
                    $result.MatchDatabaseOwner | Should Be $false
                    
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should not return any databases if there are no databases in the availability group' {
                    
                    $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupWithoutDatabasesObject.Name
                    
                    $result = $databaseMembershipClass.Get()

                    $result.SqlServer | Should Be $databaseMembershipClass.SqlServer
                    $result.SQLInstanceName | Should Be $databaseMembershipClass.SQLInstanceName
                    $result.AvailabilityGroupName | Should Be $mockAvailabilityGroupWithoutDatabasesObject.Name
                    $result.DatabaseName | Should BeNullOrEmpty
                    $result.BackupPath | Should BeNullOrEmpty
                    $result.Ensure | Should Be 'Present'
                    $result.MatchDatabaseOwner | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return databases when there are databases in the availability group' {

                    $result = $databaseMembershipClass.Get()

                    $result.SqlServer | Should Be $databaseMembershipClass.SqlServer
                    $result.SQLInstanceName | Should Be $databaseMembershipClass.SQLInstanceName
                    $result.AvailabilityGroupName | Should Be $mockAvailabilityGroupObject.Name
                    $result.BackupPath | Should BeNullOrEmpty
                    $result.Ensure | Should Be 'Present'
                    $result.MatchDatabaseOwner | Should Be $true

                    foreach ( $resultDatabaseName in $result.DatabaseName )
                    {
                        $mockAvailabilityDatabaseNames -contains $resultDatabaseName | Should Be $true
                    }

                    foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                    {
                        $result.DatabaseName -contains $mockAvailabilityDatabaseName | Should Be $true
                    }

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\Set()' {
            BeforeAll {
                #Mock -CommandName Add-SqlAvailabilityDatabase -MockWith {} -Verifiable # Primary and secondaries
                #Mock -CommandName Backup-SqlDatabase -MockWith {} -Verifiable
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockPrimaryServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                #Mock -CommandName Invoke-Query -MockWith {} -Verifiable # Restore
                #Mock -CommandName New-TerminatingError { $ErrorType } -Verifiable
                #Mock -CommandName Remove-Item -MockWith {} -Verifiable
                #Mock -CommandName Remove-SqlAvailabilityDatabase -MockWith {} -Verifiable
                #Mock -CommandName Restore-SqlDatabase -MockWith {} -Verifiable
                #Mock -CommandName Test-ImpersonatePermissions -MockWith {} -Verifiable
            }

            BeforeEach {
                $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameter.Clone()
                $databaseMembershipClass.SqlServer = $mockServerObject.DomainInstanceName
                $databaseMembershipClass.SQLInstanceName = 'MSSQLSERVER'
                $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupObject.Name
            }

            It 'Should add the specified databases to the availability group' {
                $databaseMembershipClass.Set()
            }
        }
        
        Describe 'xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\Test()' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockPrimaryServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
            }

            BeforeEach {
                $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameter.Clone()
                $databaseMembershipClass.SqlServer = $mockServerObject.DomainInstanceName
                $databaseMembershipClass.SQLInstanceName = 'MSSQLSERVER'
                $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupObject.Name
            }

            Context 'When the desired state is Present' {

                It 'Should return $true when the configuration is in the desired state' {
                    $databaseMembershipClass.DatabaseName = $mockAvailabilityDatabaseNames.Clone()
                    
                    $databaseMembershipClass.Test() | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when no matching databases are found' {
                    $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()
                    
                    $databaseMembershipClass.Test() | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to add to the availability group' {
                    $databaseMembershipClass.Test() | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $databaseMembershipClass.DatabaseName = $mockAvailabilityDatabaseNames.Clone()
                    $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name
                    
                    $databaseMembershipClass.Test() | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }
            }

            Context 'When the desired state is Absent' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Absent'
                }

                It 'Should return $true when the configuration is in the desired state' {
                    $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()
                    
                    $databaseMembershipClass.Test() | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $true when no matching databases are found' {
                    $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()
                    
                    $databaseMembershipClass.Test() | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to remove from the availability group' {
                    $databaseMembershipClass.Test() | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()
                    $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name
                    
                    $databaseMembershipClass.Test() | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }
            }

            Context 'When the desired state is Exactly' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Exactly'
                }

                It 'Should return $true when the configuration is in the desired state' {
                    $databaseMembershipClass.DatabaseName = $mockAvailabilityDatabaseNames.Clone()
                    
                    $databaseMembershipClass.Test() | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when no matching databases are found' {
                    $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()
                    
                    $databaseMembershipClass.Test() | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to add to the availability group' {
                    $databaseMembershipClass.Test() | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to remove from the availability group' {
                    $databaseMembershipClass.Test() | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $databaseMembershipClass.DatabaseName = $mockAvailabilityDatabaseNames.Clone()
                    $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name
                    
                    $databaseMembershipClass.Test() | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\GetDatabasesToAddToAvailabilityGroup()' {
            BeforeAll {
                Mock -CommandName New-TerminatingError { $ErrorType } -Verifiable
            }

            BeforeEach {
                $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameter.Clone()
            }

            Context 'When invalid objects are passed to the method' {

                It 'Should throw the correct error when an empty object is passed to the ServerObject property of the method' {

                    { $databaseMembershipClass.GetDatabasesToAddToAvailabilityGroup($null,$mockAvailabilityGroupObject) } | Should Throw 'ParameterNullOrEmpty'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when empty invalid object is passed to the AvailabilityGroup property of the method' {
                    { $databaseMembershipClass.GetDatabasesToAddToAvailabilityGroup($mockServerObject,$null) } | Should Throw 'ParameterNullOrEmpty'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }
                
                It 'Should throw the correct error when an invalid object is passed to the ServerObject property of the method' {

                    { $databaseMembershipClass.GetDatabasesToAddToAvailabilityGroup($mockBadServerObject,$mockAvailabilityGroupObject) } | Should Throw 'ParameterNotOfType'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when an invalid object is passed to the AvailabilityGroup property of the method' {
                    { $databaseMembershipClass.GetDatabasesToAddToAvailabilityGroup($mockServerObject,$mockBadAvailabilityGroupObject) } | Should Throw 'ParameterNotOfType'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }
            }
            
            Context 'When Ensure is Present' {
                
                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Present'
                }
                
                It 'Should return an array of database names to add when matches are found' {

                    $results = $databaseMembershipClass.GetDatabasesToAddToAvailabilityGroup($mockServerObject,$mockAvailabilityGroupObject)

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabasePresentResults -contains $result | Should Be $true
                    }

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should return an empty object when no matches are found' {

                    $databaseMembershipClass.DatabaseName = @()
                    
                    $databaseMembershipClass.GetDatabasesToAddToAvailabilityGroup($mockServerObject,$mockAvailabilityGroupObject) | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }
            }

            Context 'When Ensure is Exactly' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Exactly'
                }

                It 'Should return an array of database names to add when matches are found' {

                    $results = $databaseMembershipClass.GetDatabasesToAddToAvailabilityGroup($mockServerObject,$mockAvailabilityGroupObject)

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseExactlyAddResults -contains $result | Should Be $true
                    }

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should return all of the databases in the availability group if no matches were found' {

                    $databaseMembershipClass.DatabaseName = @()

                    $databaseMembershipClass.GetDatabasesToAddToAvailabilityGroup($mockServerObject,$mockAvailabilityGroupObject) | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\GetDatabasesToRemoveFromAvailabilityGroup()' {
            BeforeAll {
                Mock -CommandName New-TerminatingError { $ErrorType } -Verifiable
            }

            BeforeEach {
                $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameter.Clone()
            }

            Context 'When invalid objects are passed to the method' {

                It 'Should throw the correct error when an empty object is passed to the ServerObject property of the method' {

                    { $databaseMembershipClass.GetDatabasesToRemoveFromAvailabilityGroup($null,$mockAvailabilityGroupObject) } | Should Throw 'ParameterNullOrEmpty'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when empty invalid object is passed to the AvailabilityGroup property of the method' {
                    { $databaseMembershipClass.GetDatabasesToRemoveFromAvailabilityGroup($mockServerObject,$null) } | Should Throw 'ParameterNullOrEmpty'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }
                
                It 'Should throw the correct error when an invalid object is passed to the ServerObject property of the method' {

                    { $databaseMembershipClass.GetDatabasesToRemoveFromAvailabilityGroup($mockBadServerObject,$mockAvailabilityGroupObject) } | Should Throw 'ParameterNotOfType'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when an invalid object is passed to the AvailabilityGroup property of the method' {
                    { $databaseMembershipClass.GetDatabasesToRemoveFromAvailabilityGroup($mockServerObject,$mockBadAvailabilityGroupObject) } | Should Throw 'ParameterNotOfType'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }
            }
            
            Context 'When Ensure is Absent' {
                
                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Absent'
                }
                
                It 'Should return an array of database names to remove when matches are found' {

                    $results = $databaseMembershipClass.GetDatabasesToRemoveFromAvailabilityGroup($mockServerObject,$mockAvailabilityGroupObject)

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseAbsentResults -contains $result | Should Be $true
                    }

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should return an empty object when no matches are found' {

                    $databaseMembershipClass.DatabaseName = @()
                    
                    $databaseMembershipClass.GetDatabasesToRemoveFromAvailabilityGroup($mockServerObject,$mockAvailabilityGroupObject) | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }
            }

            Context 'When Ensure is Exactly' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Exactly'
                }

                It 'Should return an array of database names to remove when matches are found' {

                    $results = $databaseMembershipClass.GetDatabasesToRemoveFromAvailabilityGroup($mockServerObject,$mockAvailabilityGroupObject)

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseExactlyRemoveResults -contains $result | Should Be $true
                    }

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should return all of the databases in the availability group if no matches were found' {

                    $databaseMembershipClass.DatabaseName = @()
                    
                    $results = $databaseMembershipClass.GetDatabasesToRemoveFromAvailabilityGroup($mockServerObject,$mockAvailabilityGroupObject)

                    # Ensure all of the results are in the Availability Databases
                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseNames -contains $result | Should Be $true
                    }

                    # Ensure all of the Availability Databases are in the results
                    foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                    {
                        $results -contains $mockAvailabilityDatabaseName | Should Be $true
                    }

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\GetMatchingDatabaseNames()' {
            BeforeAll {
                Mock -CommandName New-TerminatingError { $ErrorType } -Verifiable
            }

            BeforeEach {
                $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameter.Clone()
            }

            Context 'When the GetMatchingDatabaseNames method is called' {

                It 'Should throw the correct error when and invalid object type is passed to the method' {

                    { $databaseMembershipClass.GetMatchingDatabaseNames($mockBadServerObject) } | Should Throw 'ParameterNotOfType'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }

                It 'Should return an empty object when no matching databases are found' {
                     
                     $databaseMembershipClass.DatabaseName = @('DatabaseNotHere')

                     $databaseMembershipClass.GetMatchingDatabaseNames($mockServerObject) | Should BeNullOrEmpty

                     Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should return an array of database names that match the defined databases' {
                     
                     $databaseMembershipClass.DatabaseName = @('DatabaseNotHere')
                     
                     $results = $databaseMembershipClass.GetMatchingDatabaseNames($mockServerObject)

                     foreach ( $result in $results )
                     {
                         $mockPresentDatabaseNames -contains $result | Should Be $true
                     }

                     Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\GetDatabaseNamesNotFoundOnTheInstance()' {

            Context 'When the GetDatabaseNamesNotFoundOnTheInstance method is called' {

                BeforeAll {
                    # The defined databases that should be identified as missing
                    $mockMissingDatabases = @(
                        'AnotherDB'
                        '4th*OfDatabase'
                    )
                }

                BeforeEach {
                    $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                    $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameter.Clone()
                }
                
                It 'Should return an empty object when no missing databases were identified' {
                    $databaseMembershipClass.GetDatabaseNamesNotFoundOnTheInstance($mockDatabaseNameParameter) | Should BeNullOrEmpty
                }

                It 'Should return a string array of database names when missing databases are identified' {
                    $results = $databaseMembershipClass.GetDatabaseNamesNotFoundOnTheInstance($mockPresentDatabaseNames)

                    foreach ( $result in $results )
                    {
                        $mockMissingDatabases -contains $result | Should Be $true
                    }
                }

                It 'Should return an empty object when an empty object is supplied and no databases are defined' {
                    $databaseMembershipClass.DatabaseName = @()

                    $databaseMembershipClass.GetDatabaseNamesNotFoundOnTheInstance('') | Should BeNullOrEmpty
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup

}