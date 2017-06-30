Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership'

enum Ensure
{
    Absent
    Present
}

[DscResource()]
class xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
{
    [DscProperty(Mandatory)]
    [System.String[]]
    $DatabaseName

    [DscProperty(Key)]
    [System.String]
    $SQLServer

    [DscProperty(Key)]
    [System.String]
    $SQLInstanceName

    [DscProperty(Key)]
    [System.String]
    $AvailabilityGroupName

    [DscProperty(Mandatory)]
    [System.String]
    $BackupPath

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [Bool]
    $Force

    [DscProperty()]
    [Bool]
    $MatchDatabaseOwner = $true

    # Load the SQLPS module when the class is initialized
    xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership()
    {
        Import-SQLPSModule
    }

    [xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership] Get()
    {
        # Create an object that reflects the current configuration
        $currentConfiguration = New-Object xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
        $currentConfiguration.SQLServer = $this.SQLServer
        $currentConfiguration.SQLInstanceName = $this.SQLInstanceName

        # Connect to the instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the availabilty group object
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        if ( $availabilityGroup )
        {
            $currentConfiguration.AvailabilityGroupName = $this.AvailabilityGroupName

            # Get the databases in the availability group
            $currentConfiguration.DatabaseName = $availabilityGroup.AvailabilityDatabases | Select-Object -ExpandProperty Name
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.AvailabilityGroupDoesNotExist -f $this.AvailabilityGroupName) -Verbose

            $currentConfiguration.MatchDatabaseOwner = $false
        }

        return $currentConfiguration
    }

    [Void] Set()
    {
        # Connect to the defined instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the Availabilty Group
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        # Make sure we're communicating with the primary replica in order to make changes to the replica
        $primaryServerObject = Get-PrimaryReplicaServerObject -ServerObject $serverObject -AvailabilityGroup $availabilityGroup

        $databasesToAddToAvailabilityGroup = $this.GetDatabasesToAddToAvailabilityGroup($primaryServerObject,$availabilityGroup)

        $databasesToRemoveFromAvailabilityGroup = $this.GetDatabasesToRemoveFromAvailabilityGroup($primaryServerObject,$availabilityGroup)

        # Create a hash table to store the databases that failed to be added to the Availability Group
        $databasesToAddFailures = @{}

        # Create a hash table to store the databases that failed to be added to the Availability Group
        $databasesToRemoveFailures = @{}

        if ( $databasesToAddToAvailabilityGroup.Count -gt 0 )
        {
            Write-Verbose -Message ($script:localizedData.AddingDatabasesToAvailabilityGroup -f $this.AvailabilityGroupName,( $databasesToAddToAvailabilityGroup -join ', ' )) -Verbose

            # Get only the secondary replicas. Some tests do not need to be performed on the primary replica
            $secondaryReplicas = $availabilityGroup.AvailabilityReplicas | Where-Object -FilterScript { $_.Role -ne 'Primary' }

            # Ensure the appropriate permissions are in place on all the replicas
            if ( $this.MatchDatabaseOwner )
            {
                $impersonatePermissionsStatus = @{}

                foreach ( $availabilityGroupReplica in $secondaryReplicas )
                {
                    $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                    $impersonatePermissionsStatus.Add(
                        $availabilityGroupReplica.Name,
                        ( Test-ImpersonatePermissions -ServerObject $currentAvailabilityGroupReplicaServerObject )
                    )
                }

                if ( $impersonatePermissionsStatus.Values -contains $false )
                {
                    $impersonatePermissionsMissingParameters = @(
                        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
                        ( ( $impersonatePermissionsStatus.GetEnumerator() | Where-Object -FilterScript { -not $_.Value } | Select-Object -ExpandProperty Key ) -join ', ' )
                    )
                    throw ($script:localizedData.ImpersonatePermissionsMissing -f $impersonatePermissionsMissingParameters )
                }
            }

            foreach ( $databaseName in $databasesToAddToAvailabilityGroup )
            {
                $databaseObject = $primaryServerObject.Databases[$databaseName]

                <#
                    Verify the prerequisites prior to joining the database to the availability group
                    https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/prereqs-restrictions-recommendations-always-on-availability#a-nameprerequisitesfordbsa-availability-database-prerequisites-and-restrictions
                #>

                # Create a hash table to store prerequisite check failures
                $prerequisiteCheckFailures = @()

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
                    if ( $databaseObject.($prerequisiteCheck.Key) -ne $prerequisiteCheck.Value )
                    {
                        $prerequisiteCheckFailures += "$($prerequisiteCheck.Key) is not $($prerequisiteCheck.Value)."
                    }
                }

                # Cannot be a system database
                if ( $databaseObject.ID -le 4 )
                {
                    $prerequisiteCheckFailures += 'The database cannot be a system database.'
                }

                # If FILESTREAM is enabled, ensure FILESTREAM is enabled on all replica instances
                if (
                    ( -not [System.String]::IsNullOrEmpty($databaseObject.DefaultFileStreamFileGroup) ) `
                    -or ( -not [System.String]::IsNullOrEmpty($databaseObject.FilestreamDirectoryName) ) `
                    -or ( $databaseObject.FilestreamNonTransactedAccess -ne 'Off' )
                )
                {
                    $availabilityReplicaFilestreamLevel = @{}
                    foreach ( $availabilityGroupReplica in $secondaryReplicas )
                    {
                        $connectSqlParameters = Split-FullSQLInstanceName -FullSQLInstanceName $availabilityGroupReplica.Name
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL @connectSqlParameters
                        $availabilityReplicaFilestreamLevel.Add($availabilityGroupReplica.Name, $currentAvailabilityGroupReplicaServerObject.FilestreamLevel)
                    }

                    if ( $availabilityReplicaFilestreamLevel.Values -contains 'Disabled' )
                    {
                        $availabilityReplicaFilestreamLevelDisabled = $availabilityReplicaFilestreamLevel.GetEnumerator() | Where-Object { $_.Value -eq 'Disabled' } | Select-Object -ExpandProperty Key
                        $prerequisiteCheckFailures += ( 'Filestream is disabled on the following instances: {0}' -f ( $availabilityReplicaFilestreamLevelDisabled -join ', ' ) )
                    }
                }

                # If the database is contained, ensure contained database authentication is enabled on all replica instances
                if ( $databaseObject.ContainmentType -ne 'None' )
                {
                    $availabilityReplicaContainmentEnabled = @{}
                    foreach ( $availabilityGroupReplica in $secondaryReplicas )
                    {
                        $connectSqlParameters = Split-FullSQLInstanceName -FullSQLInstanceName $availabilityGroupReplica.Name
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL @connectSqlParameters
                        $availabilityReplicaContainmentEnabled.Add($availabilityGroupReplica.Name, $currentAvailabilityGroupReplicaServerObject.Configuration.ContainmentEnabled.ConfigValue)
                    }

                    if ( $availabilityReplicaContainmentEnabled.Values -notcontains 'None' )
                    {
                        $availabilityReplicaContainmentNotEnabled = $availabilityReplicaContainmentEnabled.GetEnumerator() | Where-Object { $_.Value -eq 'None' } | Select-Object -ExpandProperty Key
                        $prerequisiteCheckFailures += ( 'Contained Database Authentication is not enabled on the following instances: {0}' -f ( $availabilityReplicaContainmentNotEnabled -join ', ' ) )
                    }
                }

                # Ensure the data and log file paths exist on all replicas
                $databaseFileDirectories = @()
                $databaseFileDirectories += $databaseObject.FileGroups.Files.FileName | ForEach-Object { Split-Path -Path $_ -Parent }
                $databaseFileDirectories += $databaseObject.LogFiles.FileName | ForEach-Object { Split-Path -Path $_ -Parent }
                $databaseFileDirectories = $databaseFileDirectories | Select-Object -Unique

                $availabilityReplicaMissingDirectories = @{}
                foreach ( $availabilityGroupReplica in $secondaryReplicas )
                {
                    $connectSqlParameters = Split-FullSQLInstanceName -FullSQLInstanceName $availabilityGroupReplica.Name
                    $currentAvailabilityGroupReplicaServerObject = Connect-SQL @connectSqlParameters

                    $missingDirectories = @()
                    foreach ( $databaseFileDirectory in $databaseFileDirectories )
                    {
                        $fileExistsQuery = "EXEC master.dbo.xp_fileexist '$databaseFileDirectory'"
                        $fileExistsResult = Invoke-Query -SQLServer $currentAvailabilityGroupReplicaServerObject.NetName -SQLInstanceName $currentAvailabilityGroupReplicaServerObject.ServiceName -Database master -Query $fileExistsQuery -WithResults

                        if  ( $fileExistsResult.Tables.Rows.'File is a Directory' -ne 1 )
                        {
                            $missingDirectories += $databaseFileDirectory
                        }
                    }

                    if ( $missingDirectories.Count -gt 0 )
                    {
                        $availabilityReplicaMissingDirectories.Add($availabilityGroupReplica, ( $missingDirectories -join ', ' ))
                    }
                }

                if ( $availabilityReplicaMissingDirectories.Count -gt 0 )
                {
                    foreach ( $availabilityReplicaMissingDirectory in $availabilityReplicaMissingDirectories.GetEnumerator() )
                    {
                        $prerequisiteCheckFailures += "The instance '$($availabilityReplicaMissingDirectory.Key.Name)' is missing the following directories: $($availabilityReplicaMissingDirectory.Value)"
                    }
                }

                # If the database is TDE'd, ensure the certificate or asymmetric key is installed on all replicas
                if ( $databaseObject.EncryptionEnabled )
                {
                    $databaseCertificateThumbprint = [System.BitConverter]::ToString($databaseObject.DatabaseEncryptionKey.Thumbprint)
                    $databaseCertificateName = $databaseObject.DatabaseEncryptionKey.EncryptorName

                    $availabilityReplicaMissingCertificates = @{}
                    foreach ( $availabilityGroupReplica in $secondaryReplicas )
                    {
                        $connectSqlParameters = Split-FullSQLInstanceName -FullSQLInstanceName $availabilityGroupReplica.Name
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL @connectSqlParameters
                        [System.Array]$installedCertificateThumbprints = $currentAvailabilityGroupReplicaServerObject.Databases['master'].Certificates | ForEach-Object { [System.BitConverter]::ToString($_.Thumbprint) }

                        if ( $installedCertificateThumbprints -notcontains $databaseCertificateThumbprint )
                        {
                            $availabilityReplicaMissingCertificates.Add($availabilityGroupReplica, $databaseCertificateName)
                        }
                    }

                    if ( $availabilityReplicaMissingCertificates.Count -gt 0 )
                    {
                        foreach ( $availabilityReplicaMissingCertificate in $availabilityReplicaMissingCertificates.GetEnumerator() )
                        {
                            $prerequisiteCheckFailures += "The instance '$($availabilityReplicaMissingCertificate.Key.Name)' is missing the following certificates: $($availabilityReplicaMissingCertificate.Value)"
                        }
                    }
                }

                if ( $prerequisiteCheckFailures.Count -eq 0 )
                {
                    $databaseFullBackupFile = Join-Path -Path $this.BackupPath -ChildPath "$($databaseObject.Name)_Full_$(Get-Date -Format 'yyyyMMddhhmmss').bak"
                    $databaseLogBackupFile = Join-Path -Path $this.BackupPath -ChildPath "$($databaseObject.Name)_Log_$(Get-Date -Format 'yyyyMMddhhmmss').trn"

                    # Build the backup parameters. If no backup was previously taken, a standard full will be taken. Otherwise a CopyOnly backup will be taken.
                    $backupSqlDatabaseParameters = @{
                        DatabaseObject = $databaseObject
                        BackupAction = 'Database'
                        BackupFile = $databaseFullBackupFile
                        ErrorAction = 'Stop'
                    }

                    # If no full backup was ever taken, do not take a backup with CopyOnly
                    if ( $databaseObject.LastBackupDate -ne 0 )
                    {
                        $backupSqlDatabaseParameters.Add('CopyOnly', $true)
                    }

                    try
                    {
                        Backup-SqlDatabase @backupSqlDatabaseParameters
                    }
                    catch
                    {
                        # Log the failure
                        $databasesToAddFailures.Add($databaseName, $_.Exception)

                        # Move on to the next database
                        continue
                    }

                    # Create the parameters to perform a transaction log backup
                    $backupSqlDatabaseLogParams = @{
                        DatabaseObject = $databaseObject
                        BackupAction = 'Log'
                        BackupFile = $databaseLogBackupFile
                        ErrorAction = 'Stop'
                    }

                    try
                    {
                        Backup-SqlDatabase @backupSqlDatabaseLogParams
                    }
                    catch
                    {
                        # Log the failure
                        $databasesToAddFailures.Add($databaseName, $_.Exception)

                        # Move on to the next database
                        continue
                    }

                    # Add the database to the availability group on the primary instance
                    try
                    {
                        Add-SqlAvailabilityDatabase -InputObject $availabilityGroup -Database $databaseName
                    }
                    catch
                    {
                        # Log the failure
                        $databasesToAddFailures.Add($databaseName, $_.Exception)

                        # Move on to the next database
                        continue
                    }

                    # Need to restore the database with a query in order to impersonate the correct login
                    $restoreDatabaseQueryStringBuilder = New-Object -TypeName System.Text.StringBuilder

                    if ( $this.MatchDatabaseOwner )
                    {
                        $restoreDatabaseQueryStringBuilder.Append('EXECUTE AS LOGIN = ''') | Out-Null
                        $restoreDatabaseQueryStringBuilder.Append($databaseObject.Owner) | Out-Null
                        $restoreDatabaseQueryStringBuilder.AppendLine('''') | Out-Null
                    }

                    $restoreDatabaseQueryStringBuilder.Append('RESTORE DATABASE [') | Out-Null
                    $restoreDatabaseQueryStringBuilder.Append($databaseName) | Out-Null
                    $restoreDatabaseQueryStringBuilder.AppendLine(']') | Out-Null
                    $restoreDatabaseQueryStringBuilder.Append('FROM DISK = ''') | Out-Null
                    $restoreDatabaseQueryStringBuilder.Append($databaseFullBackupFile) | Out-Null
                    $restoreDatabaseQueryStringBuilder.AppendLine('''') | Out-Null
                    $restoreDatabaseQueryStringBuilder.Append('WITH NORECOVERY') | Out-Null
                    $restoreDatabaseQueryString = $restoreDatabaseQueryStringBuilder.ToString()

                    # Build the parameters to restore the transaction log
                    $restoreSqlDatabaseLogParameters = @{
                        Database = $databaseName
                        BackupFile = $databaseLogBackupFile
                        RestoreAction = 'Log'
                        NoRecovery = $true
                    }

                    try
                    {
                        foreach ( $availabilityGroupReplica in $secondaryReplicas )
                        {
                            # Connect to the replica
                            $connectSqlParameters = Split-FullSQLInstanceName -FullSQLInstanceName $availabilityGroupReplica.Name
                            $currentAvailabilityGroupReplicaServerObject = Connect-SQL @connectSqlParameters
                            $currentReplicaAvailabilityGroupObject = $currentAvailabilityGroupReplicaServerObject.AvailabilityGroups[$this.AvailabilityGroupName]

                            # Restore the database
                            Invoke-Query -SQLServer $currentAvailabilityGroupReplicaServerObject.NetName -SQLInstanceName $currentAvailabilityGroupReplicaServerObject.ServiceName -Database master -Query $restoreDatabaseQueryString
                            Restore-SqlDatabase -InputObject $currentAvailabilityGroupReplicaServerObject @restoreSqlDatabaseLogParameters

                            # Add the database to the Availability Group
                            Add-SqlAvailabilityDatabase -InputObject $currentReplicaAvailabilityGroupObject -Database $databaseName
                        }
                    }
                    catch
                    {
                        # Log the failure
                        $databasesToAddFailures.Add($databaseName, $_.Exception)

                        # Move on to the next database
                        continue
                    }
                    finally
                    {
                        # Clean up the backup files
                        Remove-Item -Path $databaseFullBackupFile,$databaseLogBackupFile -Force -ErrorAction Continue
                    }
                }
                else
                {
                    $databasesToAddFailures.Add($databaseName, "The following prerequisite checks failed: $( $prerequisiteCheckFailures -join "`r`n" )" )
                }
            }
        }

        if ( $databasesToRemoveFromAvailabilityGroup.Count -gt 0 )
        {
            Write-Verbose -Message ($script:localizedData.RemovingDatabasesToAvailabilityGroup -f $this.AvailabilityGroupName,( $databasesToRemoveFromAvailabilityGroup -join ', ' )) -Verbose

            foreach ( $databaseName in $databasesToRemoveFromAvailabilityGroup )
            {
                $availabilityDatabase = $primaryServerObject.AvailabilityGroups[$this.AvailabilityGroupName].AvailabilityDatabases[$databaseName]

                try
                {
                    Remove-SqlAvailabilityDatabase -InputObject $availabilityDatabase -ErrorAction Stop
                }
                catch
                {
                    $databasesToRemoveFailures.Add($databaseName, 'Failed to remove the database from the availability group.')
                }
            }
        }

        # Combine the failures into one error message and throw it here. Doing this will allow all the databases that can be processes to be processed and will still show that applying the configuration failed
        if ( ( $databasesToAddFailures.Count -gt 0 ) -or ( $databasesToRemoveFailures.Count -gt 0 ) )
        {
            $formatArgs = @()
            foreach ( $failure in ( $databasesToAddFailures.GetEnumerator() + $databasesToRemoveFailures.GetEnumerator() ) )
            {
                $formatArgs += "The operation on the database '$( $failure.Key )' failed with the following errors: $( $failure.Value -join "`r`n" )"
            }

            throw ($script:localizedData.AlterAvailabilityGroupDatabaseMembershipFailure -f $formatArgs )
        }
    }

    [Bool] Test()
    {
        $configurationInDesiredState = $true
        $currentConfiguration = $this.Get()

        # Connect to the defined instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the Availabilty Group if it exists
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        # Make sure we're communicating with the primary replica in order to make changes to the replica
        $primaryServerObject = Get-PrimaryReplicaServerObject -ServerObject $serverObject -AvailabilityGroup $availabilityGroup

        $matchingDatabaseNames = $this.GetMatchingDatabaseNames($primaryServerObject)
        $databasesNotFoundOnTheInstance = @()

        if ( ( $this.Ensure -eq [Ensure]::Present ) -and $matchingDatabaseNames.Count -eq 0 )
        {
            $configurationInDesiredState = $false
            Write-Verbose -Message ($script:localizedData.DatabasesNotFound -f ($this.DatabaseName -join ', ')) -Verbose
        }
        else
        {
            $databasesNotFoundOnTheInstance = $this.GetDatabaseNamesNotFoundOnTheInstance($matchingDatabaseNames)

            # If the databases specified are not present on the instance and the desired state is not Absent
            if ( ( $databasesNotFoundOnTheInstance.Count -gt 0 ) -and ( $this.Ensure -ne [Ensure]::Absent ) )
            {
                $configurationInDesiredState = $false
                Write-Verbose -Message ($script:localizedData.DatabasesNotFound -f ( $databasesNotFoundOnTheInstance -join ', ' )) -Verbose
            }

            $databasesToAddToAvailabilityGroup = $this.GetDatabasesToAddToAvailabilityGroup($primaryServerObject,$availabilityGroup)

            if ( $databasesToAddToAvailabilityGroup.Count -gt 0 )
            {
                $configurationInDesiredState = $false
                Write-Verbose -Message ($script:localizedData.DatabaseShouldBeMember -f $this.AvailabilityGroupName,( $databasesToAddToAvailabilityGroup -join ', ' )) -Verbose
            }

            $databasesToRemoveFromAvailabilityGroup = $this.GetDatabasesToRemoveFromAvailabilityGroup($primaryServerObject,$availabilityGroup)

            if ( $databasesToRemoveFromAvailabilityGroup.Count -gt 0 )
            {
                $configurationInDesiredState = $false
                Write-Verbose -Message ($script:localizedData.DatabaseShouldNotBeMember -f $this.AvailabilityGroupName,( $databasesToRemoveFromAvailabilityGroup -join ', ' )) -Verbose
            }
        }

        return $configurationInDesiredState
    }

    <#
        .SYNOPSIS
            Get the databases that should be members of the Availability Group.

        .PARAMETER ServerObject
            The server object the databases should be in.

        .PARAMETER AvailabilityGroup
            The availability group object the databases should be a member of.
    #>
    hidden [System.String[]] GetDatabasesToAddToAvailabilityGroup (
        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.Server] so that Get-DSCResource will work properly
        [PSObject]
        $ServerObject,

        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.AvailabilityGroup] so that Get-DSCResource will work properly
        [PSObject]
        $AvailabilityGroup
    )
    {
        if ( ( $ServerObject -eq $null ) -or ( [System.String]::IsNullOrEmpty($ServerObject) ) )
        {
            $errorMessage = $script:localizedData.ParameterNullOrEmpty -f 'ServerObject'
            New-InvalidArgumentException -ArgumentName ParameterValidation -Message $errorMessage
        }

        if ( ( $AvailabilityGroup -eq $null ) -or ( [System.String]::IsNullOrEmpty($AvailabilityGroup) ) )
        {
            $errorMessage = $script:localizedData.ParameterNullOrEmpty -f 'AvailabilityGroup'
            New-InvalidArgumentException -ArgumentName ParameterValidation -Message $errorMessage
        }

        if ( $ServerObject.PSTypeNames -notcontains 'Microsoft.SqlServer.Management.Smo.Server' )
        {
            $errorMessage = $script:localizedData.ParameterNotOfType -f 'ServerObject','Microsoft.SqlServer.Management.Smo.Server'
            New-InvalidArgumentException -ArgumentName ParameterValidation -Message $errorMessage
        }

        if ( $AvailabilityGroup.PSTypeNames -notcontains 'Microsoft.SqlServer.Management.Smo.AvailabilityGroup' )
        {
            $errorMessage = $script:localizedData.ParameterNotOfType -f 'ServerObject','Microsoft.SqlServer.Management.Smo.AvailabilityGroup'
            New-InvalidArgumentException -ArgumentName ParameterValidation -Message $errorMessage
        }

        $matchingDatabaseNames = $this.GetMatchingDatabaseNames($ServerObject)
        $databasesInAvailabilityGroup = $AvailabilityGroup.AvailabilityDatabases | Select-Object -ExpandProperty Name

        $comparisonResult = Compare-Object -ReferenceObject $matchingDatabaseNames -DifferenceObject $databasesInAvailabilityGroup
        $databasesToAddToAvailabilityGroup = @()

        if ( $this.Ensure -eq [Ensure]::Present )
        {
            $databasesToAddToAvailabilityGroup = $comparisonResult | Where-Object -FilterScript { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
        }

        return $databasesToAddToAvailabilityGroup
    }

    <#
        .SYNOPSIS
            Get the databases that should not be members of the Availability Group.

        .PARAMETER ServerObject
            The server object the databases should not be in.

        .PARAMETER AvailabilityGroup
            The availability group object the databases should not be a member of.
    #>
    hidden [System.String[]] GetDatabasesToRemoveFromAvailabilityGroup (
        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.Server] so that Get-DSCResource will work properly
        [PSObject]
        $ServerObject,

        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.AvailabilityGroup] so that Get-DSCResource will work properly
        [PSObject]
        $AvailabilityGroup
    )
    {
        if ( ( $ServerObject -eq $null ) -or ( [System.String]::IsNullOrEmpty($ServerObject) ) )
        {
            $errorMessage = $script:localizedData.ParameterNullOrEmpty -f 'ServerObject'
            New-InvalidArgumentException -ArgumentName ParameterValidation -Message $errorMessage
        }

        if ( ( $AvailabilityGroup -eq $null ) -or ( [System.String]::IsNullOrEmpty($AvailabilityGroup) ) )
        {
            $errorMessage = $script:localizedData.ParameterNullOrEmpty -f 'AvailabilityGroup'
            New-InvalidArgumentException -ArgumentName ParameterValidation -Message $errorMessage
        }

        if ( $ServerObject.PSTypeNames -notcontains 'Microsoft.SqlServer.Management.Smo.Server' )
        {
            $errorMessage = $script:localizedData.ParameterNotOfType -f 'ServerObject','Microsoft.SqlServer.Management.Smo.Server'
            New-InvalidArgumentException -ArgumentName ParameterValidation -Message $errorMessage
        }

        if ( $AvailabilityGroup.PSTypeNames -notcontains 'Microsoft.SqlServer.Management.Smo.AvailabilityGroup' )
        {
            $errorMessage = $script:localizedData.ParameterNotOfType -f 'ServerObject','Microsoft.SqlServer.Management.Smo.AvailabilityGroup'
            New-InvalidArgumentException -ArgumentName ParameterValidation -Message $errorMessage
        }

        $matchingDatabaseNames = $this.GetMatchingDatabaseNames($ServerObject)
        $databasesInAvailabilityGroup = $AvailabilityGroup.AvailabilityDatabases | Select-Object -ExpandProperty Name

        $comparisonResult = Compare-Object -ReferenceObject $matchingDatabaseNames -DifferenceObject $databasesInAvailabilityGroup -IncludeEqual
        $databasesToRemoveFromAvailabilityGroup = @()

        if ( [Ensure]::Absent -eq $this.Ensure )
        {
            $databasesToRemoveFromAvailabilityGroup = $comparisonResult | Where-Object -FilterScript { '==' -eq $_.SideIndicator } | Select-Object -ExpandProperty InputObject
        }
        elseif ( ( [Ensure]::Present -eq $this.Ensure ) -and ( $this.Force ) )
        {
            $databasesToRemoveFromAvailabilityGroup = $comparisonResult | Where-Object -FilterScript { '=>' -eq $_.SideIndicator } | Select-Object -ExpandProperty InputObject
        }

        return $databasesToRemoveFromAvailabilityGroup
    }

    <#
        .SYNOPSIS
            Get the database names that were specified in the configuration that do not exist on the instance.

        .PARAMETER MatchingDatabaseNames
            All of the databases names that match the supplied names and wildcards.
    #>
    hidden [System.String[]] GetMatchingDatabaseNames (
        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.Server] so that Get-DSCResource will work properly
        [PSObject]
        $ServerObject
    )
    {
        if ( $ServerObject.PSTypeNames -notcontains 'Microsoft.SqlServer.Management.Smo.Server' )
        {
            $errorMessage = $script:localizedData.ParameterNotOfType -f 'ServerObject','Microsoft.SqlServer.Management.Smo.Server'
            New-InvalidArgumentException -ArgumentName ParameterNotOfType -Message $errorMessage
        }

        $matchingDatabaseNames = @()

        foreach ( $dbName in $this.DatabaseName )
        {
            $matchingDatabaseNames += $ServerObject.Databases | Where-Object -FilterScript { $_.Name -like $dbName } | Select-Object -ExpandProperty Name
        }

        return $matchingDatabaseNames
    }

    <#
        .SYNOPSIS
            Get the database names that were defined in the DatabaseName property but were not found on the instance.

        .PARAMETER MatchingDatabaseNames
            All of the database names that were found on the instance that match the supplied DatabaseName property.
    #>
    hidden [System.String[]] GetDatabaseNamesNotFoundOnTheInstance (
        [System.String[]]
        $MatchingDatabaseNames
    )
    {
        $databasesNotFoundOnTheInstance = @{}
        foreach ( $dbName in $this.DatabaseName )
        {
            # Assume the database name was not found
            $databaseNameNotFound = $true

            foreach ( $matchingDatabaseName in $matchingDatabaseNames )
            {
                if ( $matchingDatabaseName -like $dbName )
                {
                    # If we found the database name, it's not missing
                    $databaseNameNotFound = $false
                }
            }

            $databasesNotFoundOnTheInstance.Add($dbName,$databaseNameNotFound)
        }

        $result = $databasesNotFoundOnTheInstance.GetEnumerator() | Where-Object -FilterScript { $_.Value } | Select-Object -ExpandProperty Key

        return $result
    }
}
