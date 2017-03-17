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
    {}

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

        $missingDatabaseNames = $this.GetMissingDatabaseNames($matchingDatabaseNames)

        if ( $matchingDatabaseNames.Count -gt 0 )
        {
            if ( ( $missingDatabaseNames.Count -gt 0 ) -and ( $this.Ensure -ne [Ensure]::Absent ) )
            {
                $configurationInDesiredState = $false

                New-VerboseMessage -Message ( "The following databases were not found in the instance: {0}" -f ( $missingDatabaseNames -join ', ' ) )
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

    [string[]] GetMissingDatabaseNames (
        [string[]]
        $MatchingDatabaseNames
    )
    {
        $missingDatabases = @{}
        foreach ( $dbName in $this.DatabaseName )
        {
            # Assume the database name was not found
            $databaseNameMissing = $true

            foreach ( $matchingDatabaseName in $matchingDatabaseNames )
            {
                if ( $matchingDatabaseName -like $dbName )
                {
                    # If we found the database name, it's not missing
                    $databaseNameMissing = $false
                }
            }

            $missingDatabases.Add($dbName,$databaseNameMissing)
        }

        $result = $missingDatabases.GetEnumerator() | Where-Object { $_.Value } | Select-Object -ExpandProperty Key

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
