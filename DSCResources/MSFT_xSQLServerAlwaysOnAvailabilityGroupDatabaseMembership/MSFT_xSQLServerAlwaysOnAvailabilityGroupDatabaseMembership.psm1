Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

Import-SQLPSModule

enum Ensure
{
    Absent
    Exactly
    Present
}

[DscResource()]
class xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
{
    [DscProperty(Mandatory)]
    [string[]]
    $DatabaseName

    [DscProperty(Key)]
    [string]
    $SQLServer

    [DscProperty(Key)]
    [string]
    $SQLInstanceName

    [DscProperty(Key)]
    [string]
    $AvailabilityGroupName

    [DscProperty()]
    [string]
    $BackupPath

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [switch]
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
            New-VerboseMessage -Message "The availabiilty group '$($this.AvailabilityGroupName)' does not exist."

            $currentConfiguration.MatchDatabaseOwner = $false
        }

        return $currentConfiguration
    }

    [void] Set()
    {        
        # Connect to the defined instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the Availabilty Group if it exists
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        # Make sure we're communicating with the primary replica in order to make changes to the replica
        $primaryServerObject = ''
        if ( $availabilityGroup )
        {
            while ( $availabilityGroup.LocalReplicaRole -ne 'Primary' )
            {
                $primaryServerObject = Connect-SQL -SQLServer $availabilityGroup.PrimaryReplicaServerName
                $availabilityGroup = $primaryServerObject.AvailabilityGroups[$this.AvailabilityGroupName]
            }
        }

        # Ensure the appropriate permissions are in place
        if ( $this.MatchDatabaseOwner )
        {
            $testLoginEffectivePermissionsParams = @{
                SQLServer = $primaryServerObject.ComputerNamePhysicalNetBIOS
                SQLInstanceName = $primaryServerObject.ServiceName
                LoginName = $primaryServerObject.ConnectionContext.TrueLogin
                Permissions = @('IMPERSONATE ANY LOGIN')
            }
            
            $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

            if ( -not $impersonatePermissionsPresent )
            {
                throw New-TerminatingError -ErrorType ImpersonatePermissionNotPresent -ErrorCategory SecurityError
            }
        }
    }

    [bool] Test()
    {
        $configurationInDesiredState = $true
        $currentConfiguration = $this.Get()

        $comparisonLookupTable = @{
            'Absent' = '=='
            'Present' = '<='
            'Exactly' = '<=|=>'
        }

        $matchingDatabaseNames = $this.GetMatchingDatabaseNames()

        $databasesNotFoundOnTheInstance = $this.GetDatabaseNamesNotFoundOnTheInstance($matchingDatabaseNames)

        if ( $matchingDatabaseNames.Count -gt 0 )
        {
            # If the databases specified are not present on the instance and the desired state is not Absent
            if ( ( $databasesNotFoundOnTheInstance.Count -gt 0 ) -and ( $this.Ensure -ne [Ensure]::Absent ) )
            {
                $configurationInDesiredState = $false

                New-VerboseMessage -Message ( "The following databases were not found in the instance: {0}" -f ( $databasesNotFoundOnTheInstance -join ', ' ) )
            }
            
            [array]$comparisonResults = Compare-Object -ReferenceObject $matchingDatabaseNames -DifferenceObject $currentConfiguration.DatabaseName -IncludeEqual | 
                                    Where-Object { $_.SideIndicator -match $comparisonLookupTable.($this.Ensure.ToString()) }
            
            if ( $comparisonResults.Count -gt 0 )
            {
                $configurationInDesiredState = $false
                
                foreach ( $comparisonResult in $comparisonResults )
                {
                    # Create an array of values to use when providing verbose feedback
                    $verboseMessageValues = @(
                        $comparisonResult.InputObject,
                        (
                            @{
                                '=>' = 'not '
                                '==' = 'not '
                                '<=' = ''
                            }.($comparisonResult.SideIndicator)
                        ),
                        $this.AvailabilityGroupName
                    )

                    New-VerboseMessage -Message ( "The database '{0}' should {1}be a member of the availability group '{2}'." -f $verboseMessageValues )
                }
            }
        }
        else
        {
            if ( @('Present','Exactly') -contains $this.Ensure.ToString() )
            {
                $configurationInDesiredState = $false
                New-VerboseMessage -Message ( 'No databases found that match the name(s): {0}' -f ($this.DatabaseName -join ', ') )
            }
        }

        return $configurationInDesiredState
    }

    [string[]] GetDatabasesToAddToAvailabilityGroup ()
    {
        return @()
    }

    [string[]] GetDatabasesToRemoveFromAvailabilityGroup ()
    {
        return @()
    }
    
    [string[]] GetMatchingDatabaseNames ()
    {
        $matchingDatabaseNames = @()
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        if ( $AvailabilityGroup )
        {
            $primaryReplicaServerObject = $this.GetPrimaryReplicaServerObject($serverObject,$availabilityGroup)

            foreach ( $dbName in $this.DatabaseName )
            {
                $matchingDatabaseNames += $primaryReplicaServerObject.Databases | Where-Object { $_.Name -like $dbName } | Select-Object -ExpandProperty Name
            }
        }        

        return $matchingDatabaseNames
    }

    [string[]] GetDatabaseNamesNotFoundOnTheInstance (
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

    [Microsoft.SqlServer.Management.Smo.Server] GetPrimaryReplicaServerObject (
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,
        
        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
        $AvailabilityGroup
    )
    {
        $primaryReplicaServerObject = $serverObject
        
        # Determine if we're connected to the primary replica
        if ( $AvailabilityGroup.PrimaryReplicaServerName -ne $serverObject.DomainInstanceName )
        {
            $primaryReplicaServerObject = Connect-SQL -SQLServer $AvailabilityGroup.PrimaryReplicaServerName
        }

        return $primaryReplicaServerObject
    }
}
