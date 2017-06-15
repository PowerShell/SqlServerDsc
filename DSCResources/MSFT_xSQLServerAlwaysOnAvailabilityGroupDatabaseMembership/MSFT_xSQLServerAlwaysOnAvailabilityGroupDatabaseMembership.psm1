Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

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
            New-VerboseMessage -Message "The availabilty group '$($this.AvailabilityGroupName)' does not exist."

            $currentConfiguration.MatchDatabaseOwner = $false
        }

        return $currentConfiguration
    }

    [void] Set()
    {        
        # Connect to the defined instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the Availabilty Group
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        # Make sure we're communicating with the primary replica in order to make changes to the replica
        $primaryServerObject = Get-PrimaryReplicaServerObject -ServerObject $serverObject -AvailabilityGroup $availabilityGroup

        $databasesToAddToAvailabilityGroup = $this.GetDatabasesToAddToAvailabilityGroup($primaryServerObject,$availabilityGroup)
        if ( $databasesToAddToAvailabilityGroup.Count -gt 0 )
        {
            New-VerboseMessage -Message ( "Adding the following databases to the '{0}' availability group: {1}" -f $this.AvailabilityGroupName,( $databasesToAddToAvailabilityGroup -join ', ' ) )
        }

        $databasesToRemoveFromAvailabilityGroup = $this.GetDatabasesToRemoveFromAvailabilityGroup($primaryServerObject,$availabilityGroup)
        if ( $databasesToRemoveFromAvailabilityGroup.Count -gt 0 )
        {
            New-VerboseMessage -Message ( "Removing the following databases from the '{0}' availability group: {1}" -f $this.AvailabilityGroupName,( $databasesToRemoveFromAvailabilityGroup -join ', ' ) )
        }

        # Create a hash table to store the databases that failed to be added to the Availability Group
        $databasesToAddFailures = @{}

        # Create a hash table to store the databases that failed to be added to the Availability Group
        $databasesToRemoveFailures = @{}
        
        if ( $databasesToAddToAvailabilityGroup.Count -gt 0 )
        {
            # Get only the secondary replicas. Some tests do not need to be performed on the primary replica
            $secondaryReplicas = $availabilityGroup.AvailabilityReplicas | Where-Object { $_.Role -ne 'Primary' }
            
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
                    $newTerminatingErrorParams = @{
                        ErrorType = 'ImpersonatePermissionsMissing'
                        FormatArgs = @(
                            [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
                            ( ( $impersonatePermissionsStatus.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key ) -join ', ' )
                        )
                        ErrorCategory = 'SecurityError'
                    }
                    throw New-TerminatingError @newTerminatingErrorParams
                }
            }
            
            foreach ( $databaseName in $databasesToAddToAvailabilityGroup )
            {
                $database = $primaryServerObject.Databases[$databaseName]

                # Verify the prerequisites prior to joining the database to the availability group
                # https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/prereqs-restrictions-recommendations-always-on-availability#a-nameprerequisitesfordbsa-availability-database-prerequisites-and-restrictions

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
                    if ( $database.($prerequisiteCheck.Key) -ne $prerequisiteCheck.Value )
                    {
                        $prerequisiteCheckFailures += "$($prerequisiteCheck.Key) is not $($prerequisiteCheck.Value)."
                    }
                }

                # Cannot be a system database
                if ( $database.ID -le 4 )
                {
                    $prerequisiteCheckFailures += 'The database cannot be a system database.'
                }

                # If FILESTREAM is enabled, ensure FILESTREAM is enabled on all replica instances
                if (
                    ( -not [string]::IsNullOrEmpty($database.DefaultFileStreamFileGroup) ) `
                    -or ( -not [string]::IsNullOrEmpty($database.FilestreamDirectoryName) ) `
                    -or ( $database.FilestreamNonTransactedAccess -ne 'Off' )
                )
                {
                    $availbilityReplicaFilestreamLevel = @{}
                    foreach ( $availabilityGroupReplica in $secondaryReplicas )
                    {
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                        $availbilityReplicaFilestreamLevel.Add($availabilityGroupReplica.Name, $currentAvailabilityGroupReplicaServerObject.FilestreamLevel)
                    }

                    if ( $availbilityReplicaFilestreamLevel.Values -contains 'Disabled' )
                    {
                        $prerequisiteCheckFailures += ( 'Filestream is disabled on the following instances: {0}' -f ( $availbilityReplicaFilestreamLevel.Keys -join ', ' ) )
                    }
                }

                # If the database is contained, ensure contained database authentication is enabled on all replica instances
                if ( $database.ContainmentType -ne 'None' )
                {
                    $availbilityReplicaContainmentEnabled = @{}
                    foreach ( $availabilityGroupReplica in $secondaryReplicas )
                    {
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                        $availbilityReplicaContainmentEnabled.Add($availabilityGroupReplica.Name, $currentAvailabilityGroupReplicaServerObject.Configuration.ContainmentEnabled.ConfigValue)
                    }

                    if ( $availbilityReplicaContainmentEnabled.Values -notcontains 'None' )
                    {
                        $prerequisiteCheckFailures += ( 'Contained Database Authentication is not enabled on the following instances: {0}' -f ( $availbilityReplicaContainmentEnabled.Keys -join ', ' ) )
                    }
                }

                # Ensure the data and log file paths exist on all replicas
                $databaseFileDirectories = @()
                $databaseFileDirectories += $database.FileGroups.Files.FileName | ForEach-Object { Split-Path -Path $_ -Parent } | Select-Object -Unique
                $databaseFileDirectories += $database.LogFiles.FileName | ForEach-Object { Split-Path -Path $_ -Parent } | Select-Object -Unique
                $databaseFileDirectories = $databaseFileDirectories | Select-Object -Unique

                $availabilityReplicaMissingDirectories = @{}
                foreach ( $availabilityGroupReplica in $secondaryReplicas )
                {
                    $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                    
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
                        $prerequisiteCheckFailures += "The instance '$($availabilityReplicaMissingDirectory.Key)' is missing the following directories: $($availabilityReplicaMissingDirectory.Value)"
                    }
                }

                # If the database is TDE'd, ensure the certificate or asymmetric key is installed on all replicas
                if ( $database.EncryptionEnabled )
                {
                    $databaseCertificateThumbprint = [System.BitConverter]::ToString($database.DatabaseEncryptionKey.Thumbprint)
                    $databaseCertificateName = $database.DatabaseEncryptionKey.EncryptorName

                    $availabilityReplicaMissingCertificates = @{}
                    foreach ( $availabilityGroupReplica in $secondaryReplicas )
                    {
                        $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                        [array]$installedCertificateThumbprints = $currentAvailabilityGroupReplicaServerObject.Databases['master'].Certificates | ForEach-Object { [System.BitConverter]::ToString($_.Thumbprint) }

                        if ( $installedCertificateThumbprints -notcontains $databaseCertificateThumbprint )
                        {
                            $availabilityReplicaMissingCertificates.Add($availabilityGroupReplica, $databaseCertificateName)
                        }
                    }

                    if ( $availabilityReplicaMissingCertificates.Count -gt 0 )
                    {
                        foreach ( $availabilityReplicaMissingCertificate in $availabilityReplicaMissingCertificates.GetEnumerator() )
                        {
                            $prerequisiteCheckFailures += "The instance '$($availabilityReplicaMissingCertificate.Key)' is missing the following certificates: $($availabilityReplicaMissingCertificate.Value)"
                        }
                    }
                }

                if ( $prerequisiteCheckFailures.Count -eq 0 )
                {
                    $databaseFullBackupFile = Join-Path -Path $this.BackupPath -ChildPath "$($database.Name)_Full_$(Get-Date -Format 'yyyyMMddhhmmss').bak"
                    $databaseLogBackupFile = Join-Path -Path $this.BackupPath -ChildPath "$($database.Name)_Log_$(Get-Date -Format 'yyyyMMddhhmmss').trn"
                    
                    $backupSqlDatabaseParams = @{
                        DatabaseObject = $database
                        BackupAction = 'Database'
                        BackupFile = $databaseFullBackupFile
                        ErrorAction = 'Stop'
                    }

                    # If no full backup was ever taken, do not take a backup with CopyOnly
                    if ( $database.LastBackupDate -ne 0 )
                    {
                        $backupSqlDatabaseParams.Add('CopyOnly', $true)
                    }

                    try
                    {
                        Backup-SqlDatabase @backupSqlDatabaseParams
                    }
                    catch
                    {
                        # Log the failure
                        $databasesToAddFailures.Add($databaseName, $_.Exception)

                        # Move on to the next database
                        continue
                    }

                    $backupSqlDatabaseLogParams = @{
                        DatabaseObject = $database
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
                        $restoreDatabaseQueryStringBuilder.Append($database.Owner) | Out-Null
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

                    $restoreSqlDatabaseLogParams = @{
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
                            $currentAvailabilityGroupReplicaServerObject = Connect-SQL -SQLServer $availabilityGroupReplica.Name
                            $currentReplicaAvailabilityGroupObject = $currentAvailabilityGroupReplicaServerObject.AvailabilityGroups[$this.AvailabilityGroupName]

                            # Restore the database
                            Invoke-Query -SQLServer $currentAvailabilityGroupReplicaServerObject.NetName -SQLInstanceName $currentAvailabilityGroupReplicaServerObject.ServiceName -Database master -Query $restoreDatabaseQueryString
                            Restore-SqlDatabase -InputObject $currentAvailabilityGroupReplicaServerObject @restoreSqlDatabaseLogParams

                            # Add the database to the AG
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
        $allFailures = $databasesToAddFailures + $databasesToRemoveFailures

        if ( $allFailures.Count -gt 0 )
        {
            $newTerminatingErrorParams = @{
                ErrorType = 'AlterAvailabilityGroupDatabaseMembershipFailure'
                FormatArgs = ( $allFailures.GetEnumerator() | ForEach-Object { "The operation on the database '$( $_.Key )' failed with the following errors: $( $_.Value -join "`r`n" )" } )
                ErrorCategory = [System.Management.Automation.ErrorCategory]::OperationStopped
            }
            
            throw New-TerminatingError @newTerminatingErrorParams
        }
    }

    [bool] Test()
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
            New-VerboseMessage -Message ( 'No databases found that match the name(s): {0}' -f ($this.DatabaseName -join ', ') )
        }
        else
        {
            $databasesNotFoundOnTheInstance = $this.GetDatabaseNamesNotFoundOnTheInstance($matchingDatabaseNames)

            # If the databases specified are not present on the instance and the desired state is not Absent
            if ( ( $databasesNotFoundOnTheInstance.Count -gt 0 ) -and ( $this.Ensure -ne [Ensure]::Absent ) )
            {
                $configurationInDesiredState = $false
                New-VerboseMessage -Message ( "The following databases were not found in the instance: {0}" -f ( $databasesNotFoundOnTheInstance -join ', ' ) )
            }

            $databasesToAddToAvailabilityGroup = $this.GetDatabasesToAddToAvailabilityGroup($primaryServerObject,$availabilityGroup)

            if ( $databasesToAddToAvailabilityGroup.Count -gt 0 )
            {
                $configurationInDesiredState = $false
                New-VerboseMessage -Message ( "The following databases should be a member of the availability group '{0}': {1}" -f $this.AvailabilityGroupName,( $databasesToAddToAvailabilityGroup -join ', ' ) )
            }

            $databasesToRemoveFromAvailabilityGroup = $this.GetDatabasesToRemoveFromAvailabilityGroup($primaryServerObject,$availabilityGroup)

            if ( $databasesToRemoveFromAvailabilityGroup.Count -gt 0 )
            {
                $configurationInDesiredState = $false
                New-VerboseMessage -Message ( "The following databases should not be a member of the availability group '{0}': {1}" -f $this.AvailabilityGroupName,( $databasesToRemoveFromAvailabilityGroup -join ', ' ) )
            }
        }

        return $configurationInDesiredState
    }

    hidden [string[]] GetDatabasesToAddToAvailabilityGroup (
        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.Server] so that Get-DSCResource will work properly
        [psobject]
        $ServerObject,

        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.AvailabilityGroup] so that Get-DSCResource will work properly
        [psobject]
        $AvailabilityGroup
    )
    {
        if ( ( $ServerObject -eq $null ) -or ( [string]::IsNullOrEmpty($ServerObject) ) )
        {
            throw New-TerminatingError -ErrorType ParameterNullOrEmpty -FormatArgs 'ServerObject' -ErrorCategory InvalidArgument
        }

        if ( ( $AvailabilityGroup -eq $null ) -or ( [string]::IsNullOrEmpty($AvailabilityGroup) ) )
        {
            throw New-TerminatingError -ErrorType ParameterNullOrEmpty -FormatArgs 'AvailabilityGroup' -ErrorCategory InvalidArgument
        }
        
        if ( $ServerObject.pstypenames -notcontains 'Microsoft.SqlServer.Management.Smo.Server' )
        {
            throw New-TerminatingError -ErrorType ParameterNotOfType -FormatArgs 'ServerObject','Microsoft.SqlServer.Management.Smo.Server' -ErrorCategory InvalidType
        }

        if ( $AvailabilityGroup.pstypenames -notcontains 'Microsoft.SqlServer.Management.Smo.AvailabilityGroup' )
        {
            throw New-TerminatingError -ErrorType ParameterNotOfType -FormatArgs 'AvailabilityGroup','Microsoft.SqlServer.Management.Smo.AvailabilityGroup' -ErrorCategory InvalidType
        }
        
        $matchingDatabaseNames = $this.GetMatchingDatabaseNames($ServerObject)
        $databasesInAvailabilityGroup = $AvailabilityGroup.AvailabilityDatabases | Select-Object -ExpandProperty Name

        $comparisonResult = Compare-Object -ReferenceObject $matchingDatabaseNames -DifferenceObject $databasesInAvailabilityGroup
        $databasesToAddToAvailabilityGroup = @()

        if ( $this.Ensure -eq [Ensure]::Present )
        {
            $databasesToAddToAvailabilityGroup = $comparisonResult | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
        }

        return $databasesToAddToAvailabilityGroup
    }

    hidden [string[]] GetDatabasesToRemoveFromAvailabilityGroup (
        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.Server] so that Get-DSCResource will work properly
        [psobject]
        $ServerObject,

        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.AvailabilityGroup] so that Get-DSCResource will work properly
        [psobject]
        $AvailabilityGroup
    )
    {
        if ( ( $ServerObject -eq $null ) -or ( [string]::IsNullOrEmpty($ServerObject) ) )
        {
            throw New-TerminatingError -ErrorType ParameterNullOrEmpty -FormatArgs 'ServerObject' -ErrorCategory InvalidArgument
        }

        if ( ( $AvailabilityGroup -eq $null ) -or ( [string]::IsNullOrEmpty($AvailabilityGroup) ) )
        {
            throw New-TerminatingError -ErrorType ParameterNullOrEmpty -FormatArgs 'AvailabilityGroup' -ErrorCategory InvalidArgument
        }
        
        if ( $ServerObject.pstypenames -notcontains 'Microsoft.SqlServer.Management.Smo.Server' )
        {
            throw New-TerminatingError -ErrorType ParameterNotOfType -FormatArgs 'ServerObject','Microsoft.SqlServer.Management.Smo.Server' -ErrorCategory InvalidType
        }

        if ( $AvailabilityGroup.pstypenames -notcontains 'Microsoft.SqlServer.Management.Smo.AvailabilityGroup' )
        {
            throw New-TerminatingError -ErrorType ParameterNotOfType -FormatArgs 'AvailabilityGroup','Microsoft.SqlServer.Management.Smo.AvailabilityGroup' -ErrorCategory InvalidType
        }
        
        $matchingDatabaseNames = $this.GetMatchingDatabaseNames($ServerObject)
        $databasesInAvailabilityGroup = $AvailabilityGroup.AvailabilityDatabases | Select-Object -ExpandProperty Name

        $comparisonResult = Compare-Object -ReferenceObject $matchingDatabaseNames -DifferenceObject $databasesInAvailabilityGroup -IncludeEqual
        $databasesToRemoveFromAvailabilityGroup = @()

        if ( [Ensure]::Absent -eq $this.Ensure )
        {
            $databasesToRemoveFromAvailabilityGroup = $comparisonResult | Where-Object { '==' -eq $_.SideIndicator } | Select-Object -ExpandProperty InputObject
        }
        elseif ( ( [Ensure]::Present -eq $this.Ensure ) -and ( $this.Force ) )
        {
            $databasesToRemoveFromAvailabilityGroup = $comparisonResult | Where-Object { '=>' -eq $_.SideIndicator } | Select-Object -ExpandProperty InputObject
        }
    
        return $databasesToRemoveFromAvailabilityGroup
    }
    
    hidden [string[]] GetMatchingDatabaseNames (
        # Using psobject here rather than [Microsoft.SqlServer.Management.Smo.Server] so that Get-DSCResource will work properly
        [psobject]
        $ServerObject
    )
    {
        if ( $ServerObject.PSTypeNames -notcontains 'Microsoft.SqlServer.Management.Smo.Server' )
        {
            throw New-TerminatingError -ErrorType ParameterNotOfType -FormatArgs 'ServerObject','Microsoft.SqlServer.Management.Smo.Server' -ErrorCategory InvalidType
        }
        
        $matchingDatabaseNames = @()

        foreach ( $dbName in $this.DatabaseName )
        {
            $matchingDatabaseNames += $ServerObject.Databases | Where-Object { $_.Name -like $dbName } | Select-Object -ExpandProperty Name
        }      

        return $matchingDatabaseNames
    }

    hidden [string[]] GetDatabaseNamesNotFoundOnTheInstance (
        [string[]]
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

        $result = $databasesNotFoundOnTheInstance.GetEnumerator() | Where-Object { $_.Value } | Select-Object -ExpandProperty Key

        return $result
    }
}
