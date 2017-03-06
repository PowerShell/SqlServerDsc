Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

Import-SQLPSModule

enum Ensure
{
    Absent
    Present
}

[DscResource()]
class xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
{
    [DscProperty(Key)]
    [string]
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
        $currentConfiguration.DatabaseName = $this.DatabaseName
        $currentConfiguration.SQLServer = $this.SQLServer
        $currentConfiguration.SQLInstanceName = $this.SQLInstanceName
        
        # Connect to the instance
        $serverObject = Connect-SQL -SQLServer $this.SQLServer -SQLInstanceName $this.SQLInstanceName

        # Get the availabilty group object
        $availabilityGroup = $serverObject.AvailabilityGroups[$this.AvailabilityGroupName]

        if ( $availabilityGroup )
        {
            $currentConfiguration.AvailabilityGroupName = $this.AvailabilityGroupName
            
            # Determine if the database is a member of the availability group
            $availabilityDatabase = $availabilityGroup.AvailabilityDatabases[$this.DatabaseName]

            if ( $availabilityDatabase )
            {
                $currentConfiguration.Ensure = [Ensure]::Present

                # Get the database owner
                $databaseOwner = $serverObject.Databases[$this.DatabaseName].Owner

                # Get the primary replica server object
                $primaryReplicaServerObject = $this.GetPrimaryReplicaServerObject($serverObject,$availabilityGroup)
                
                # Determine if the database owner matches the primary replica database owner
                if ( $primaryReplicaServerObject.DomainInstanceName -ne $availabilityGroup.PrimaryReplicaServerName )
                {
                    $primaryReplicaDatabaseOwner = $primaryReplicaServerObject.Databases[$this.DatabaseName].Owner

                    if ( $primaryReplicaDatabaseOwner -ne $databaseOwner )
                    {
                        $currentConfiguration.MatchDatabaseOwner = $false
                    }
                    else
                    {
                        $currentConfiguration.MatchDatabaseOwner = $true
                    }
                }
                else
                {
                    $currentConfiguration.MatchDatabaseOwner = $true
                }
            }
            else
            {
                $currentConfiguration.Ensure = [Ensure]::Absent
                $currentConfiguration.MatchDatabaseOwner = $false
            }
        }
        else
        {
            New-VerboseMessage -Message "The availabiilty group '$($this.AvailabilityGroupName)' does not exist."
            
            $currentConfiguration.Ensure = [Ensure]::Absent
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

        $propertiesToCheck = @(
            'DatabaseName',
            'SQLServer',
            'SQLInstanceName',
            'AvailabilityGroupName',
            'Ensure',
            'MatchDatabaseOwner'
        )

        foreach ( $propertyName in $propertiesToCheck )
        {
            if ( $this.$propertyName -ne $currentConfiguration.$propertyName )
            {
                New-VerboseMessage -Message "The property '$propertyName' should be '$($this.$propertyName)' but is '$($currentConfiguration.$propertyName)'"
                $configurationInDesiredState = $false
            }
        }

        return $configurationInDesiredState
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
