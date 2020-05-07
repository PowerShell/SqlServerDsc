<#
    .SYNOPSIS
        Automated unit test for DSC_SqlAGDatabase DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlAGDatabase'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    # Load the default SQL Module stub
    Import-SQLModuleStub
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {

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

        $mockProcessOnlyOnActiveNode = $false

        #endregion Parameter Mocks

        #region mock names

        $mockServerObjectDomainInstanceName = 'Server1'
        $mockPrimaryServerObjectDomainInstanceName = 'Server2'
        $mockAvailabilityGroupObjectName = 'AvailabilityGroup1'
        $mockAvailabilityGroupWithoutDatabasesObjectName = 'AvailabilityGroupWithoutDatabases'
        $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName = 'AvailabilityGroup2'
        $mockTrueLogin = 'Login1'
        $mockDatabaseOwner = 'DatabaseOwner1'

        #endregion mock names

        #region Availability Replica Mocks

        $mockAvailabilityReplicaObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
        foreach ( $mockAvailabilityReplicaName in @('Server1','Server2') )
        {
            $newAvailabilityReplicaObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
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

        $mockAvailabilityDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
        foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
        {
            $newAvailabilityDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
            $newAvailabilityDatabaseObject.Name = $mockAvailabilityDatabaseName
            $mockAvailabilityDatabaseObjects.Add($newAvailabilityDatabaseObject)
        }

        $mockBadAvailabilityGroupObject = New-Object -TypeName Object

        $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
        $mockAvailabilityGroupObject.AvailabilityDatabases = $mockAvailabilityDatabaseObjects
        $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupObjectName
        $mockAvailabilityGroupObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
        $mockAvailabilityGroupObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

        $mockAvailabilityGroupWithoutDatabasesObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
        $mockAvailabilityGroupWithoutDatabasesObject.Name = $mockAvailabilityGroupWithoutDatabasesObjectName
        $mockAvailabilityGroupWithoutDatabasesObject.PrimaryReplicaServerName = $mockServerObjectDomainInstanceName
        $mockAvailabilityGroupWithoutDatabasesObject.AvailabilityReplicas = $mockAvailabilityReplicaObjects

        $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
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

        $mockCertificateObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
        $mockCertificateObject1.Thumbprint = $mockThumbprint1

        $mockCertificateObject2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Certificate
        $mockCertificateObject2.Thumbprint = $mockThumbprint2

        $mockDatabaseEncryptionKeyObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseEncryptionKey
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
        $mockMasterDatabaseObject1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
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

        $mockDatabaseObjects = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
        foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
        {
            $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
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
            $newDatabaseObject.Owner = $mockDatabaseOwner

            # Add the database object to the database collection
            $mockDatabaseObjects.Add($newDatabaseObject)
        }
        $mockDatabaseObjects.Add($mockMasterDatabaseObject1)

        $mockDatabaseObjectsWithIncorrectFileNames = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabaseCollection
        foreach ( $mockPresentDatabaseName in $mockPresentDatabaseNames )
        {
            $newDatabaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
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
            $newDatabaseObject.Owner = $mockDatabaseOwner

            # Add the database object to the database collection
            $mockDatabaseObjectsWithIncorrectFileNames.Add($newDatabaseObject)
        }

        #endregion Database Mocks

        #region Server mocks

        $mockBadServerObject = New-Object -TypeName Object

        $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
        $mockServerObject.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
        $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
        $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
        $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
        $mockServerObject.ComputerNamePhysicalNetBIOS = $mockServerObjectDomainInstanceName
        $mockServerObject.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
        $mockServerObject.ConnectionContext.TrueLogin = $mockTrueLogin
        $mockServerObject.Databases = $mockDatabaseObjects
        $mockServerObject.DomainInstanceName = $mockServerObjectDomainInstanceName
        $mockServerObject.NetName = $mockServerObjectDomainInstanceName
        $mockServerObject.ServiceName = 'MSSQLSERVER'
        $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObject.Name].LocalReplicaRole = 'Primary'
        $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupWithoutDatabasesObject.Name].LocalReplicaRole = 'Primary'
        $mockServerObject.AvailabilityGroups[$mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name].LocalReplicaRole = 'Secondary'

        $mockServer2Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
        $mockServer2Object.AvailabilityGroups = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
        $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObject.Clone())
        $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupWithoutDatabasesObject.Clone())
        $mockServer2Object.AvailabilityGroups.Add($mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Clone())
        $mockServer2Object.ComputerNamePhysicalNetBIOS = $mockPrimaryServerObjectDomainInstanceName
        $mockServer2Object.ConnectionContext = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
        $mockServer2Object.ConnectionContext.TrueLogin = $mockTrueLogin
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
WITH NORECOVERY*
REVERT'
        }

        #endregion Invoke Query Mock

        Describe 'SqlAGDatabase\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable
                Mock -CommandName Import-SQLPSModule -Verifiable
            }

            BeforeEach {
                $getTargetResourceParameters = @{
                    DatabaseName = $mockDatabaseNameParameter.Clone()
                    ServerName = 'Server1'
                    InstanceName = 'MSSQLSERVER'
                    AvailabilityGroupName = 'AvailabilityGroup1'
                    BackupPath = $($mockBackupPath)
                }
            }

            Context 'When the Get-TargetResource function is called' {
                It 'Should not return an availability group name or availability databases when the availability group does not exist' {
                    $getTargetResourceParameters.AvailabilityGroupName = 'NonExistentAvailabilityGroup'

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                    $result.AvailabilityGroupName | Should -BeNullOrEmpty
                    $result.DatabaseName | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 0 -Exactly
                }

                It 'Should not return any databases if there are no databases in the availability group' {
                    $getTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupWithoutDatabasesObject.Name

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                    $result.AvailabilityGroupName | Should -Be $mockAvailabilityGroupWithoutDatabasesObject.Name
                    $result.DatabaseName | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 0 -Exactly
                }

                It 'Should return databases when there are databases in the availability group' {
                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                    $result.AvailabilityGroupName | Should -Be $mockAvailabilityGroupObject.Name

                    foreach ( $resultDatabaseName in $result.DatabaseName )
                    {
                        $mockAvailabilityDatabaseNames -contains $resultDatabaseName | Should -Be $true
                    }

                    foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                    {
                        $result.DatabaseName -contains $mockAvailabilityDatabaseName | Should -Be $true
                    }

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 0 -Exactly
                }
            }
        }

        Describe 'SqlAGDatabase\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                Mock -CommandName Import-SQLPSModule -Verifiable
                Mock -CommandName Invoke-Query -Verifiable -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                Mock -CommandName Invoke-Query -Verifiable -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                Mock -CommandName Join-Path -MockWith { [IO.Path]::Combine($databaseMembershipClass.BackupPath,"$($database.Name)_Full_$(Get-Date -Format 'yyyyMMddhhmmss').bak") } -Verifiable -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                Mock -CommandName Join-Path -MockWith { [IO.Path]::Combine($databaseMembershipClass.BackupPath,"$($database.Name)_Log_$(Get-Date -Format 'yyyyMMddhhmmss').trn") } -Verifiable -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                Mock -CommandName Remove-Item -Verifiable
            }

            BeforeEach {
                $mockSetTargetResourceParameters = @{
                    DatabaseName = $($mockDatabaseNameParameter)
                    ServerName = $($mockServerObject.DomainInstanceName)
                    InstanceName = $('MSSQLSERVER')
                    AvailabilityGroupName = $($mockAvailabilityGroupObjectName)
                    BackupPath = $($mockBackupPath)
                    Ensure = 'Present'
                    Force = $false
                    MatchDatabaseOwner = $true
                    ReplaceExisting = $false
                }

                Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                Mock -CommandName Add-SqlAvailabilityDatabase -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                Mock -CommandName Backup-SqlDatabase -Verifiable -ParameterFilter { $BackupAction -eq 'Database' }
                Mock -CommandName Backup-SqlDatabase -Verifiable -ParameterFilter { $BackupAction -eq 'Log'}
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $ServerName -eq 'Server1' }
                Mock -CommandName Connect-SQL -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $ServerName -eq 'Server2' }
                Mock -CommandName Invoke-Query -MockWith $mockResultInvokeQueryFileExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                Mock -CommandName Remove-SqlAvailabilityDatabase -Verifiable
                Mock -CommandName Test-ImpersonatePermissions -MockWith { $true } -Verifiable
            }

            Context 'When Ensure is Present' {
                It 'Should add the specified databases to the availability group' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should add the specified databases to the availability group when the primary replica is on another server' {
                    $mockSetTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should not do anything if no databases were found to add' {
                    $mockSetTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }

                It 'Should add the specified databases to the availability group when "MatchDatabaseOwner" is $false' {
                    $mockSetTargetResourceParameters.MatchDatabaseOwner = $false

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }

                It 'Should add the specified databases to the availability group when "ReplaceExisting" is $true' {
                    $mockSetTargetResourceParameters.DatabaseName = 'DB1'
                    $mockSetTargetResourceParameters.ReplaceExisting = $true

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when "MatchDatabaseOwner" is $true and the current login does not have impersonate permissions' {
                    Mock -CommandName Test-ImpersonatePermissions -MockWith { $false } -Verifiable

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The login '$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)' is missing impersonate any login, control server, impersonate login, or control login permissions in the instances 'Server2'."

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
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
                    It "Should throw the correct error when the database property '$($prerequisiteCheck.Key)' is not '$($prerequisiteCheck.Value)'" {
                        $originalValue = $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key)
                        $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key) = $true

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: $($prerequisiteCheck.Key) is not $($prerequisiteCheck.Value)."

                        foreach ( $databaseProperty in $prerequisiteChecks.GetEnumerator() )
                        {
                            if ( $prerequisiteCheck.Key -eq $databaseProperty.Key )
                            {
                                $mockServerObject.Databases['DB1'].($databaseProperty.Key) | Should -Not -Be ($databaseProperty.Value)
                            }
                            else
                            {
                                $mockServerObject.Databases['DB1'].($databaseProperty.Key) | Should -Be ($databaseProperty.Value)
                            }
                        }

                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                        Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                            Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                        $mockServerObject.Databases['DB1'].($prerequisiteCheck.Key) = $originalValue
                    }
                }

                It 'Should throw the correct error when the database property "ID" is less than "4"' {
                    $mockSetTargetResourceParameters.DatabaseName = @('master')

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'master' failed with the following errors: The following prerequisite checks failed: The database cannot be a system database."

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
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

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: Filestream is disabled on the following instances: Server2"

                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                        Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                        Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                        Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                        Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                        Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                        Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                        Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                        Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                        Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                        Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                        Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                            Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                        $mockServerObject.Databases['DB1'].($filestreamProperty.Key) = $originalValue
                    }
                }

                It 'Should throw the correct error when the database property "ContainmentType" is not "Partial"' {
                    $originalValue = $mockServerObject.Databases['DB1'].ContainmentType
                    $mockServerObject.Databases['DB1'].ContainmentType = 'Partial'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: Contained Database Authentication is not enabled on the following instances: "

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                    $mockServerObject.Databases['DB1'].ContainmentType = $originalValue
                }

                It 'Should throw the correct error when the database file path does not exist on the secondary replica' {
                    Mock -CommandName Invoke-Query -MockWith $mockResultInvokeQueryFileNotExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    $originalValue = $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName
                    $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName = ( [IO.Path]::Combine( 'X:\', "DB1.mdf" ) )

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "The operation on the database 'DB1' failed with the following errors: The following prerequisite checks failed: The instance 'Server2' is missing the following directories: X:\, F:\SqlLog"

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                    $mockServer2Object.Databases['DB1'].FileGroups.Files.FileName = $originalValue
                }

                It 'Should throw the correct error when the log file path does not exist on the secondary replica' {
                    Mock -CommandName Invoke-Query -MockWith $mockResultInvokeQueryFileNotExist -Verifiable -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    $originalValue = $mockServer2Object.Databases['DB1'].LogFiles.FileName
                    $mockServer2Object.Databases['DB1'].LogFiles.FileName = ( [IO.Path]::Combine( 'Y:\', "DB1.ldf" ) )

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: The following prerequisite checks failed: The instance ''Server2'' is missing the following directories: E:\SqlData, Y:\'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                    $mockServer2Object.Databases['DB1'].LogFiles.FileName = $originalValue
                }

                It 'Should throw the correct error when TDE is enabled on the database but the certificate is not present on the replica instances' {
                    $mockServerObject.Databases['DB1'].EncryptionEnabled = $true
                    $mockServerObject.Databases['DB1'].DatabaseEncryptionKey = $mockDatabaseEncryptionKeyObject
                    $mockServer2Object.Databases['master'].Certificates = @($mockCertificateObject2)

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: The following prerequisite checks failed: The instance ''Server2'' is missing the following certificates: TDE Cert'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly

                    $mockServerObject.Databases['DB1'].EncryptionEnabled = $false
                    $mockServerObject.Databases['DB1'].DatabaseEncryptionKey = $null
                    $mockServer2Object.Databases['master'].Certificates = @($mockCertificateObject1)
                }

                It 'Should add the specified databases to the availability group when the database has not been previously backed up' {
                    $mockServerObject.Databases['DB1'].LastBackupDate = 0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when it fails to perform a full backup' {
                    Mock -CommandName Backup-SqlDatabase -MockWith { throw } -Verifiable -ParameterFilter { $BackupAction -eq 'Database' }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when it fails to perform a log backup' {
                    Mock -CommandName Backup-SqlDatabase -MockWith { throw } -Verifiable -ParameterFilter { $BackupAction -eq 'Log' }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when it fails to add the database to the primary replica' {
                    Mock -CommandName Add-SqlAvailabilityDatabase -MockWith { throw } -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when it fails to add the database to the primary replica' {
                    Mock -CommandName Add-SqlAvailabilityDatabase -MockWith { throw } -Verifiable -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB1'' failed with the following errors: System.Management.Automation.RuntimeException: ScriptHalted'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }
            }

            Context 'When Ensure is Absent' {
                BeforeEach {
                    $mockSetTargetResourceParameters.Ensure = 'Absent'
                }

                It 'Should remove the specified databases to the availability group(s)' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }

                It 'Should remove the specified databases to the availability group(s) when the primary replica is on another server' {
                    $mockSetTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServerName

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error when it fails to remove the database from the availability group' {
                    $setTargetResourceParameters = $mockSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters.Ensure = 'Absent'
                    $setTargetResourceParameters.DatabaseName = @('DB2')

                    Mock -CommandName Remove-SqlAvailabilityDatabase -MockWith { throw } -Verifiable

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw 'The operation on the database ''DB2'' failed with the following errors: Failed to remove the database from the availability group.'

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 0 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 0 -Exactly
                }
            }

            Context 'When Ensure is Present and Force is True' {
                BeforeEach {
                    $mockSetTargetResourceParameters.Ensure = 'Present'
                    $mockSetTargetResourceParameters.Force = $true
                }

                It 'Should ensure the database membership of the availability group is exactly as specified' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server1' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Primary' }
                    Assert-MockCalled -CommandName Add-SqlAvailabilityDatabase -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.PrimaryReplicaServerName -eq 'Server2' -and $InputObject.LocalReplicaRole -eq 'Secondary' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Database' }
                    Assert-MockCalled -CommandName Backup-SqlDatabase -Scope It -Times 1 -Exactly -ParameterFilter { $BackupAction -eq 'Log' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' -and $InstanceName -eq 'MSSQLSERVER' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $ServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 3 -Exactly -ParameterFilter { $ServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter { $Query -like 'EXEC master.dbo.xp_fileexist *' }
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabase
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 2 -Exactly -ParameterFilter $mockInvokeQueryParameterRestoreDatabaseWithExecuteAs
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Full_*.bak' }
                    Assert-MockCalled -CommandName Join-Path -Scope It -Times 1 -Exactly -ParameterFilter { $ChildPath -like '*_Log_*.trn' }
                    Assert-MockCalled -CommandName Remove-Item -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityDatabase -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ImpersonatePermissions -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'SqlAGDatabase\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith { return $mockServerObject } -Verifiable
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServerObject } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith { return $mockServer2Object } -Verifiable -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                Mock -CommandName Test-ActiveNode -MockWith {
                    return -not $mockProcessOnlyOnActiveNode
                } -Verifiable
            }

            BeforeEach {
                $mockTestTargetResourceParameters = @{
                    DatabaseName = $mockDatabaseNameParameter.Clone()
                    ServerName = $mockServerObject.DomainInstanceName
                    InstanceName = 'MSSQLSERVER'
                    AvailabilityGroupName = $mockAvailabilityGroupObject.Name
                    BackupPath = $($mockBackupPath)
                    Ensure = 'Present'
                    Force = $false
                    MatchDatabaseOwner = $false
                    ProcessOnlyOnActiveNode = $false
                }
            }

            Context 'When Ensure is Present' {
                It 'Should return $true when the configuration is in the desired state' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames.Clone()

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the specified availability group is not found' {
                    $mockTestTargetResourceParameters.AvailabilityGroupName = 'NonExistentAvailabilityGroup'

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when no matching databases are found' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when databases are found to add to the availability group' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames.Clone()
                    $mockTestTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when ProcessOnlyOnActiveNode is "$true" and the current node is not actively hosting the instance' {
                    $mockProcessOnlyOnActiveNode = $true

                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames.Clone()
                    $mockTestTargetResourceParameters.ProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNode

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }

            Context 'When Ensure is Absent' {
                BeforeEach {
                    $mockTestTargetResourceParameters.Ensure = 'Absent'
                }

                It 'Should return $true when the configuration is in the desired state' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }

                }

                It 'Should return $true when no matching databases are found' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to remove from the availability group' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()
                    $mockTestTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }
            }

            Context 'When Ensure is Present and Force is True' {
                BeforeEach {
                    $mockTestTargetResourceParameters.Force = $true
                }

                It 'Should return $true when the configuration is in the desired state' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames.Clone()

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when no matching databases are found' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockDatabaseNameParameterWithNonExistingDatabases.Clone()

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to add to the availability group' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $false when databases are found to remove from the availability group' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }

                It 'Should return $true when the configuration is in the desired state and the primary replica is on another server' {
                    $mockTestTargetResourceParameters.DatabaseName = $mockAvailabilityDatabaseNames.Clone()
                    $mockTestTargetResourceParameters.AvailabilityGroupName = $mockAvailabilityGroupObjectWithPrimaryReplicaOnAnotherServer.Name

                    Test-TargetResource @mockTestTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1' }
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly -ParameterFilter { $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2' }
                }
            }
        }

        Describe 'SqlAGDatabase\Get-DatabasesToAddToAvailabilityGroup' {
            BeforeEach {
                $getDatabasesToAddToAvailabilityGroup = @{
                    DatabaseName = $mockDatabaseNameParameter.Clone()
                    Ensure = 'Present'
                    ServerObject = $mockServerObject
                    AvailabilityGroup = $mockAvailabilityGroupObject
                }
            }

            Context 'When Ensure is Present' {
                It 'Should return an array of database names to add when matches are found' {
                    $results = Get-DatabasesToAddToAvailabilityGroup @getDatabasesToAddToAvailabilityGroup

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabasePresentResults -contains $result | Should -Be $true
                    }
                }

                It 'Should return an array of database names no databases are in the availability group' {
                    $getDatabasesToAddToAvailabilityGroup.AvailabilityGroup = $mockAvailabilityGroupWithoutDatabasesObject

                    $results = Get-DatabasesToAddToAvailabilityGroup @getDatabasesToAddToAvailabilityGroup

                    foreach ( $result in $results )
                    {
                        $mockPresentDatabaseNames -contains $result | Should -Be $true
                    }
                }

                It 'Should return an empty object when no matches are found' {
                    $getDatabasesToAddToAvailabilityGroup.DatabaseName = @()

                    Get-DatabasesToAddToAvailabilityGroup @getDatabasesToAddToAvailabilityGroup | Should -BeNullOrEmpty
                }
            }
        }

        Describe 'SqlAGDatabase\Get-DatabasesToRemoveFromAvailabilityGroup' {
            BeforeEach {
                $getDatabasesToRemoveFromAvailabilityGroupParameters = @{
                    DatabaseName = $mockDatabaseNameParameter.Clone()
                    Ensure = 'Present'
                    Force = $false
                    ServerObject = $mockServerObject
                    AvailabilityGroup = $mockAvailabilityGroupObject
                }
            }

            Context 'When Ensure is Absent' {
                BeforeEach {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.Ensure = 'Absent'
                }

                It 'Should return an array of database names to remove when matches are found' {
                    $results = Get-DatabasesToRemoveFromAvailabilityGroup @getDatabasesToRemoveFromAvailabilityGroupParameters

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseAbsentResults -contains $result | Should -Be $true
                    }
                }

                It 'Should return an array of database names to remove when no databases are in the availability group' {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.AvailabilityGroup = $mockAvailabilityGroupWithoutDatabasesObject

                    $results = Get-DatabasesToRemoveFromAvailabilityGroup @getDatabasesToRemoveFromAvailabilityGroupParameters

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseAbsentResults -contains $result | Should -Be $true
                    }
                }

                It 'Should return an empty object when no matches are found' {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.DatabaseName = @()

                    Get-DatabasesToRemoveFromAvailabilityGroup @getDatabasesToRemoveFromAvailabilityGroupParameters | Should -BeNullOrEmpty
                }
            }

            Context 'When Ensure is Present and Force is True' {
                BeforeEach {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.Force = $true
                }

                It 'Should return an array of database names to remove when matches are found' {
                    $results = Get-DatabasesToRemoveFromAvailabilityGroup @getDatabasesToRemoveFromAvailabilityGroupParameters

                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseExactlyRemoveResults -contains $result | Should -Be $true
                    }
                }

                It 'Should return all of the databases in the availability group if no matches were found' {
                    $getDatabasesToRemoveFromAvailabilityGroupParameters.DatabaseName = @()

                    $results = Get-DatabasesToRemoveFromAvailabilityGroup @getDatabasesToRemoveFromAvailabilityGroupParameters

                    # Ensure all of the results are in the Availability Databases
                    foreach ( $result in $results )
                    {
                        $mockAvailabilityDatabaseNames -contains $result | Should -Be $true
                    }

                    # Ensure all of the Availability Databases are in the results
                    foreach ( $mockAvailabilityDatabaseName in $mockAvailabilityDatabaseNames )
                    {
                        $results -contains $mockAvailabilityDatabaseName | Should -Be $true
                    }
                }
            }
        }

        Describe 'SqlAGDatabase\Get-MatchingDatabaseNames' {
            BeforeEach {
                $getMatchingDatabaseNamesParameters = @{
                    DatabaseName = $mockDatabaseNameParameter.Clone()
                    ServerObject = $mockServerObject
                }
            }

            Context 'When the Get-MatchingDatabaseNames function is called' {
                It 'Should throw the correct error when and invalid object type is passed to the method' {
                    $getMatchingDatabaseNamesParameters.ServerObject = $mockBadServerObject

                    { Get-MatchingDatabaseNames @getMatchingDatabaseNamesParameters } | Should -Throw 'ServerObject'
                }

                It 'Should return an empty object when no matching databases are found' {
                     $getMatchingDatabaseNamesParameters.DatabaseName = @('DatabaseNotHere')

                     Get-MatchingDatabaseNames @getMatchingDatabaseNamesParameters | Should -BeNullOrEmpty
                }

                It 'Should return an array of database names that match the defined databases' {
                     $results = Get-MatchingDatabaseNames @getMatchingDatabaseNamesParameters

                     foreach ( $result in $results )
                     {
                         $mockPresentDatabaseNames -contains $result | Should -Be $true
                     }
                }

                It 'Should return an array of database names that match the defined databases when the case does not match' {
                    $getMatchingDatabaseNamesParameters.DatabaseName = $getMatchingDatabaseNamesParameters.DatabaseName | ForEach-Object -Process { $_.ToLower() }

                    $results = Get-MatchingDatabaseNames @getMatchingDatabaseNamesParameters

                    foreach ( $result in $results )
                    {
                        $mockPresentDatabaseNames -contains $result | Should -Be $true
                    }
               }
            }
        }

        Describe 'SqlAGDatabase\Get-DatabaseNamesNotFoundOnTheInstance' {
            Context 'When the Get-DatabaseNamesNotFoundOnTheInstance function is called' {
                BeforeAll {
                    # The defined databases that should be identified as missing
                    $mockMissingDatabases = @(
                        'AnotherDB'
                        '4th*OfDatabase'
                    )
                }

                BeforeEach {
                    $getDatabaseNamesNotFoundOnTheInstanceParameters = @{
                        DatabaseName = $mockDatabaseNameParameter.Clone()
                        MatchingDatabaseNames = @()
                    }
                }

                It 'Should return an empty object when no missing databases were identified' {
                    $getDatabaseNamesNotFoundOnTheInstanceParameters.MatchingDatabaseNames = $mockDatabaseNameParameter

                    Get-DatabaseNamesNotFoundOnTheInstance @getDatabaseNamesNotFoundOnTheInstanceParameters | Should -BeNullOrEmpty
                }

                It 'Should return a string array of database names when missing databases are identified' {
                    $getDatabaseNamesNotFoundOnTheInstanceParameters.MatchingDatabaseNames = $mockPresentDatabaseNames

                    $results = Get-DatabaseNamesNotFoundOnTheInstance @getDatabaseNamesNotFoundOnTheInstanceParameters

                    foreach ( $result in $results )
                    {
                        $mockMissingDatabases -contains $result | Should -Be $true
                    }
                }

                It 'Should return an empty object is supplied and no databases are defined' {
                    $getDatabaseNamesNotFoundOnTheInstanceParameters.DatabaseName = @()
                    $getDatabaseNamesNotFoundOnTheInstanceParameters.MatchingDatabaseNames = $mockPresentDatabaseNames

                    Get-DatabaseNamesNotFoundOnTheInstance @getDatabaseNamesNotFoundOnTheInstanceParameters | Should -BeNullOrEmpty
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup

}
