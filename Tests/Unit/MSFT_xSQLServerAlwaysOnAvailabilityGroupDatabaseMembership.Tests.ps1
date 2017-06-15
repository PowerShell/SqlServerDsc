#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent) -ChildPath 'xSQLServerHelper.psm1') -Scope Global -Force
Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global

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

            $mockBackupPath = 'X:\Backup'

        #endregion Parameter Mocks

        #region mock names

            $mockServerObjectDomainInstanceName = 'Server1'
            $mockPrimaryServerObjectDomainInstanceName = 'Server2'
            $mockAvailabilityGroupObjectName = 'AvailabilityGroup1'
            $mockAvailabilityGroupWithoutDatabasesObjectName = 'AvailabilityGroupWithoutDatabases'
            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName = 'AvailabilityGroup2'

        #endregion mock names

        #region Availability Replica Mocks

            $mockAvailabilityReplicaObjects = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
            foreach ( $mockAvailabilityReplicaName in @('Server1','Server2') )
            {
                $newAvailabilityReplicaObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                $newAvailabilityReplicaObject.Name = $mockAvailabilityReplicaName

                if ( $mockServerObjectDomainInstanceName -eq $mockAvailabilityReplicaName )
                {
                    $newAvailabilityReplicaObject.Role = 'Primary'
                }

                $mockAvailabilityReplicaObjects.Add($newAvailabilityReplicaObject)
            }
            
        #endregion Availability Replica Mocks

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

            $mockAvailabilityDatabaseObjects = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
            foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
            {
                $newAvailabilityDatabaseObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
                $newAvailabilityDatabaseObject.Name = $mockAvailabilityDatabaseName
                $mockAvailabilityDatabaseObjects.Add($newAvailabilityDatabaseObject)
            }
            
            $mockBadAvailabilityGroupObject = New-Object -TypeName Object

            $mockAvailabilityGroupObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupObject.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
            $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupObjectName
            $mockAvailabilityGroupObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
            $mockAvailabilityGroupObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

            $mockAvailabilityGroupWithoutDatabasesObject = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupWithoutDatabasesObject.Name = $mockAvailabilityGroupWithoutDatabasesObjectName
            $mockAvailabilityGroupWithoutDatabasesObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
            $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName
            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.PrimaryReplicaServerName = $mockPrimaryServerObjectDomainInstanceName
            $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.AvailabilityReplicas = $mockAvailabilityReplicaObjects

        #endregion Availability Group Mocks

        #region Certificate Mocks

            [byte[]]$mockThumbprint1 = @(
                83
                121
                115
                116
                101
                109
                46
                84
                101
                120
                116
                46
                85
                84
                70
                56
                69
                110
                99
                111
                100
                105
                110
                103
            )

            [byte[]]$mockThumbprint2 = @(
                83
                121
                115
                23
                101
                109
                46
                84
                101
                120
                116
                85
                85
                84
                70
                56
                69
                23
                99
                111
                100
                105
                110
                103
            )
            
            $mockCertificateObject1 = New-Object Microsoft.SqlServer.Management.Smo.Certificate
            $mockCertificateObject1.Thumbprint = $mockThumbprint1

            $mockCertificateObject2 = New-Object Microsoft.SqlServer.Management.Smo.Certificate
            $mockCertificateObject2.Thumbprint = $mockThumbprint2
            
            $mockDatabaseEncryptionKeyObject = New-Object Microsoft.SqlServer.Management.Smo.DatabaseEncryptionKey
            $mockDatabaseEncryptionKeyObject.EncryptorName = 'TDE Cert'
            $mockDatabaseEncryptionKeyObject.Thumbprint = $mockThumbprint1

        #endregion Certificate Mocks

        #region Database File Mocks

            $mockDataFilePath = 'E:\SqlData'
            $mockLogFilePath = 'F:\SqlLog'
            $mockDataFilePathIncorrect = 'G:\SqlData'
            $mockLogFilePathIncorrect = 'H:\SqlData'

        #endregion Database File Mocks

        #region Database Mocks

            # The databases found on the instance
            $mockPresentDatabaseNames = @(
                'DB1'
                'DB2'
                '3rdTypeOfDatabase'
                'UndefinedDatabase'
            )

            $mockMasterDatabaseName = 'master'
            $mockMasterDatabaseObject1 = New-Object Microsoft.SqlServer.Management.Smo.Database
            $mockMasterDatabaseObject1.Name = $mockMasterDatabaseName
            $mockMasterDatabaseObject1.ID = 1
            $mockMasterDatabaseObject1.Certificates = @($mockCertificateObject1)
            $mockMasterDatabaseObject1.FileGroups = @{
                Name = 'PRIMARY'
                Files = @{
                    FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockMasterDatabaseName).mdf" ) )
                }
            }
            $mockMasterDatabaseObject1.LogFiles = @{
                FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockMasterDatabaseName).ldf" ) )
            }
            
            $mockDatabaseObjects = New-Object Microsoft.SqlServer.Management.Smo.DatabaseCollection
            foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
            {
                $newDatabaseObject = New-Object Microsoft.SqlServer.Management.Smo.Database
                $newDatabaseObject.Name = $mockPresentDatabaseName
                $newDatabaseObject.FileGroups = @{
                    Name = 'PRIMARY'
                    Files = @{
                        FileName = ( [IO.Path]::Combine( $mockDataFilePath, "$($mockPresentDatabaseName).mdf" ) )
                    }
                }
                $newDatabaseObject.LogFiles = @{
                    FileName = ( [IO.Path]::Combine( $mockLogFilePath, "$($mockPresentDatabaseName).ldf" ) )
                }

                # Add the database object to the database collection
                $mockDatabaseObjects.Add($newDatabaseObject)
            }
            $mockDatabaseObjects.Add($mockMasterDatabaseObject1)
            
            $mockDatabaseObjectsWithIncorrectFileNames = New-Object Microsoft.SqlServer.Management.Smo.DatabaseCollection
            foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
            {
                $newDatabaseObject = New-Object Microsoft.SqlServer.Management.Smo.Database
                $newDatabaseObject.Name = $mockPresentDatabaseName
                $newDatabaseObject.FileGroups = @{
                    Name = 'PRIMARY'
                    Files = @{
                        FileName = ( [IO.Path]::Combine( $mockDataFilePathIncorrect, "$($mockPresentDatabaseName).mdf" ) )
                    }
                }
                $newDatabaseObject.LogFiles = @{
                    FileName = ( [IO.Path]::Combine( $mockLogFilePathIncorrect, "$($mockPresentDatabaseName).ldf" ) )
                }

                # Add the database object to the database collection
                $mockDatabaseObjectsWithIncorrectFileNames.Add($newDatabaseObject)
            }
        
        #endregion Database Mocks
        
        #region Server mocks
            
            $mockBadServerObject = New-Object -TypeName Object
                        
            $mockServerObject = New-Object Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.AvailabilityGroups = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
            $mockServerObject.Databases = $mockDatabaseObjects
            $mockServerObject.DomainInstanceName = $mockServerObjectDomainInstanceName
            $mockServerObject.NetName = $mockServerObjectDomainInstanceName
            $mockServerObject.ServiceName = 'MSSQLSERVER'
            $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Primary'
            $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Primary'
            $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Secondary'

            $mockServer2Object = New-Object Microsoft.SqlServer.Management.Smo.Server
            $mockServer2Object.AvailabilityGroups = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
            $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
            $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
            $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
            $mockServer2Object.Databases = $mockDatabaseObjects
            $mockServer2Object.DomainInstanceName = $mockPrimaryServerObjectDomainInstanceName
            $mockServer2Object.NetName = $mockPrimaryServerObjectDomainInstanceName
            $mockServer2Object.ServiceName = 'MSSQLSERVER'
            $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Secondary'
            $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Secondary'
            $mockServer2Object.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Primary'

        #endregion Server mocks

        #region Invoke Query Mock

            $mockResultInvokeQueryFileExist = {
                return @{
                    Tables = @{
                        Rows = @{
                            'File is a Directory' = 1
                        }
                    }
                }
            }

            $mockResultInvokeQueryFileNotExist = {
                return @{
                    Tables = @{
                        Rows = @{
                            'File is a Directory' = 0
                        }
                    }
                }
            }

            $mockInvokeQueryParameterRestoreDatabase = {
                $Query -like 'RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY'
            }
            
            $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs = {
                $Query -like 'EXECUTE AS LOGIN = *
RESTORE DATABASE *
FROM DISK = *
WITH NORECOVERY'
            }

        #endregion Invoke Query Mock
        
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
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                Mock -CommandName Invoke-Query -MockWith {} -Verifiable -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                Mock -CommandName Invoke-Query -MockWith {} -Verifiable -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                Mock -CommandName Join-Path -MockWith { [IO.Path]::Combine($databaseMembershipClass.BackupPath,"$($database.Name)_Full_$(Get-Date -Format 'yyyyMMddhhmmss').bak") } -Verifiable -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                Mock -CommandName Join-Path -MockWith { [IO.Path]::Combine($databaseMembershipClass.BackupPath,"$($database.Name)_Log_$(Get-Date -Format 'yyyyMMddhhmmss').trn") } -Verifiable -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                Mock -CommandName New-TerminatingError { $ErrorType } -Verifiable
                Mock -CommandName Remove-Item -MockWith {} -Verifiable
                Mock -CommandName Restore-SqlDatabase -MockWith {} -Verifiable
                
            }

            BeforeEach {

                $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                $databaseMembershipClass.DatabaseName = $($mockDatabaseNameParameter)
                $databaseMembershipClass.SqlServer = $($mockServerObject.DomainInstanceName)
                $databaseMembershipClass.SQLInstanceName = $('MSSQLSERVER')
                $databaseMembershipClass.AvailabilityGroupName = $($mockAvailabilityGroupObjectName)
                $databaseMembershipClass.BackupPath = $($mockBackupPath)

                Mock -CommandName Add-SqlAvailabilityDatabase -MockWith {} -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                Mock -CommandName Add-SqlAvailabilityDatabase -MockWith {} -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                Mock -CommandName Add-SqlAvailabilityDatabase -MockWith {} -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                Mock -CommandName Add-SqlAvailabilityDatabase -MockWith {} -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                Mock -CommandName Backup-SqlDatabase -MockWith {} -Verifiable -ParameterFilter { $BackupAction -eq 'Database' }
                Mock -CommandName Backup-SqlDatabase -MockWith {} -Verifiable -ParameterFilter { $BackupAction -eq 'Log'}
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $SqlServer -eq 'Server1' }
                Mock -CommandName Connect-SQL -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $SqlServer -eq 'Server2' }
                Mock -CommandName Invoke-Query -MockWith $mockResultInvokeQueryFileExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                Mock -CommandName Remove-SqlAvailabilityDatabase -MockWith {} -Verifiable
                Mock -CommandName Test-ImpersonatePermissions -MockWith { $true } -Verifiable
            }

            Context 'When Ensure is Present' {

                It 'Should add the specified databases to the availability group' {

                    { $databaseMembershipClass.Set() } | Should Not Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should add the specified databases to the availability group when the primary replica is on another server' {

                    $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName
                    
                    { $databaseMembershipClass.Set() } | Should Not Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should not do anything if no databases were found to add' {

                    $databaseMembershipClass.DatabaseName = $mockAvailabilityDatabaseNames
                    
                    { $databaseMembershipClass.Set() } | Should Not Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }

                It 'Should add the specified databases to the availability group when "MatchDatabaseOwner" is $false' {

                    $databaseMembershipClass.MatchDatabaseOwner = $false
                    
                    { $databaseMembershipClass.Set() } | Should Not Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "ImpersonatePermissionsMissing" when "MatchDatabaseOwner" is $true and the current login does not have impersonate permissions' {

                    Mock -CommandName Test-ImpersonatePermissions -MockWith { $false } -Verifiable

                    { $databaseMembershipClass.Set() } | Should Throw 'ImpersonatePermissionsMissing'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                $prerequisiteChecks = @{
                    RecoveryModel = 'Full'
                    ReadOnly = $false
                    UserAccess = 'Multiple'
                    AutoClose = $false
                    AvailabilityGroupName = ''
                    IsMirroringEnabled = $false
                }

                foreach ( $prerequisiteCheck in $prerequisiteChecks.GetEnumerator() )
                {
                    It "Should throw the correct error 'AlterAvailabilityGroupDatabaseMembershipFailure' when the database property '$($prerequisiteCheck.Key)' is not '$($prerequisiteCheck.Value)'" {

                        $originalValue = $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key)
                        $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key) = $true
                        
                        { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                        foreach ( $databaseProperty in $prerequisiteChecks.GetEnumerator() )
                        {
                            if ( $prerequisiteCheck.Key -eq $databaseProperty.Key )
                            {
                                $mockServerObject.Databases['DB1'].($databaseProperty.Key) | Should Not Be ($databaseProperty.Value)
                            }
                            else
                            {
                                $mockServerObject.Databases['DB1'].($databaseProperty.Key) | Should Be ($databaseProperty.Value)
                            }
                        }

                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                        Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                        $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key) = $originalValue
                    }
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when the database property "ID" is less than "4"' {

                    $databaseMembershipClass.DatabaseName = @('master')

                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                $filestreamProperties = @{
                    DefaultFileStreamFileGroup = ''
                    FilestreamDirectoryName = ''
                    FilestreamNonTransactedAccess = 'Off'
                }
                
                foreach ( $filestreamProperty in $filestreamProperties.GetEnumerator() )
                {
                    It "Should throw the correct error 'AlterAvailabilityGroupDatabaseMembershipFailure' when the database property '$($filestreamProperty.Key)' is not '$($filestreamProperty.Value)'" {

                        $originalValue = $mockServerObject.Databases['DB1'].($filestreamProperty.Key)
                        $mockServerObject.Databases['DB1'].($filestreamProperty.Key) = 'On'

                        { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                        Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                        $mockServerObject.Databases['DB1'].($filestreamProperty.Key) = $originalValue
                    }
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when the database property "ContainmentType" is not "Partial"' {

                    $originalValue = $mockServerObject.Databases['DB1'].ContainmentType
                    $mockServerObject.Databases['DB1'].ContainmentType = 'Partial'

                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                    $mockServerObject.Databases['DB1'].ContainmentType = $originalValue
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when the database file path does not exist on the secondary replica' {

                    Mock -CommandName Invoke-Query -MockWith $mockResultInvokeQueryFileNotExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    $originalValue = $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName
                    $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName = ( [IO.Path]::Combine( 'X:\', "DB1.mdf" ) )

                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                    
                    $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName = $originalValue
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when the log file path does not exist on the secondary replica' {

                    Mock -CommandName Invoke-Query -MockWith $mockResultInvokeQueryFileNotExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    $originalValue = $mockServer2Object.Databases['DB1'].LogFiles.FileName
                    $mockServer2Object.Databases['DB1'].LogFiles.FileName = ( [IO.Path]::Combine( 'Y:\', "DB1.ldf" ) )

                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                    $mockServer2Object.Databases['DB1'].LogFiles.FileName = $originalValue
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when TDE is enabled on the database but the certificate is not present on the replica instances' {

                    $mockServerObject.Databases['DB1'].EncryptionEnabled = $true
                    $mockServerObject.Databases['DB1'].DatabaseEncryptionKey = $mockDatabaseEncryptionKeyObject
                    $mockServer2Object.Databases['master'].Certificates = @($mockCertificateObject2)

                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                    $mockServerObject.Databases['DB1'].EncryptionEnabled = $false
                    $mockServerObject.Databases['DB1'].DatabaseEncryptionKey = $null
                    $mockServer2Object.Databases['master'].Certificates = @($mockCertificateObject1)
                }

                It 'Should add the specified databases to the availability group when the database has not been previously backed up' {

                    $mockServerObject.Databases['DB1'].LastBackupDate = 0
                    
                    { $databaseMembershipClass.Set() } | Should Not Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when it fails to perform a full backup' {

                    Mock -CommandName Backup-SqlDatabase -MockWith { throw } -Verifiable -ParameterFilter { $BackupAction -eq 'Database' }
                    
                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when it fails to perform a log backup' {

                    Mock -CommandName Backup-SqlDatabase -MockWith { throw } -Verifiable -ParameterFilter { $BackupAction -eq 'Log' }
                    
                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when it fails to add the database to the primary replica' {
                    
                    Mock -CommandName Add-SqlAvailabilityDatabase -MockWith { throw } -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    
                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when it fails to add the database to the primary replica' {
                    
                    Mock -CommandName Add-SqlAvailabilityDatabase -MockWith { throw } -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    
                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }
            }

            Context 'When Ensure is Absent' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Absent'
                }
                
                It 'Should remove the specified databases to the availability group(s)' {

                    { $databaseMembershipClass.Set() } | Should Not Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }

                It 'Should remove the specified databases to the availability group(s) when the primary replica is on another server' {

                    $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName
                    
                    { $databaseMembershipClass.Set() } | Should Not Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "AlterAvailabilityGroupDatabaseMembershipFailure" when it fails to remove the database from the availability group' {

                    Mock -CommandName Remove-SqlAvailabilityDatabase -MockWith { throw } -Verifiable

                    { $databaseMembershipClass.Set() } | Should Throw 'AlterAvailabilityGroupDatabaseMembershipFailure'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }
            }

            Context 'When Ensure is Present and Force is True' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Present'
                    $databaseMembershipClass.Force = $true
                }

                It 'Should ensure the database membership of the availability group is exactly as specified' {

                    { $databaseMembershipClass.Set() } | Should Not Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' -and $SQLInstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SqlServer -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $SqlServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Restore-SqlDatabase -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }
            }
        }
        
        Describe 'xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\Test()' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
            }

            BeforeEach {
                $databaseMembershipClass = [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership]::New()
                $databaseMembershipClass.DatabaseName = $mockDatabaseNameParameter.Clone()
                $databaseMembershipClass.SqlServer = $mockServerObject.DomainInstanceName
                $databaseMembershipClass.SQLInstanceName = 'MSSQLSERVER'
                $databaseMembershipClass.AvailabilityGroupName = $mockAvailabilityGroupObject.Name
            }

            Context 'When Ensure is Present' {

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

            Context 'When Ensure is Absent' {

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

            Context 'When Ensure is Present and Force is True' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Present'
                    $databaseMembershipClass.Force = $true
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

            Context 'When Ensure is Present and Force is True' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Present'
                    $databaseMembershipClass.Force = $true
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

            Context 'When Ensure is Present and Force is True' {

                BeforeEach {
                    $databaseMembershipClass.Ensure = 'Present'
                    $databaseMembershipClass.Force = $true
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
