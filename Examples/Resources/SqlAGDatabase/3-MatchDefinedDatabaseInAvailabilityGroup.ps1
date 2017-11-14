<#
.EXAMPLE
    This example shows how to ensure that the databases 'DB*' and 'AdventureWorks' are the only members of the Availability Group 'TestAG'.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName              = '*'
            SQLInstanceName       = 'MSSQLSERVER'
            AvailabilityGroupName = 'TestAG'
        },

        @{
            NodeName = 'SQL1'
            Role     = 'PrimaryReplica'
        },

        @{
            NodeName = 'SQL2'
            Role     = 'SecondaryReplica'
        }
    )
}

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName SqlServerDsc

    Node $AllNodes.NodeName {
        # Adding the required service account to allow the cluster to log into SQL
        SqlServerLogin AddNTServiceClusSvc
        {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            ServerName            = $Node.NodeName
            InstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Add the required permissions to the cluster service login
        SqlServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn            = '[SqlServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            ServerName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Create a DatabaseMirroring endpoint
        SqlServerEndpoint HADREndpoint
        {
            EndPointName         = 'HADR'
            Ensure               = 'Present'
            Port                 = 5022
            ServerName            = $Node.NodeName
            InstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            SqlAG AddTestAG
            {
                Ensure               = 'Present'
                Name                 = $Node.AvailabilityGroupName
                InstanceName      = $Node.SQLInstanceName
                ServerName            = $Node.NodeName
                DependsOn            = '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }

        if ( $Node.Role -eq 'SecondaryReplica' )
        {
            # Add the availability group replica to the availability group
            SqlAGReplica AddReplica
            {
                Ensure                        = 'Present'
                Name                          = $Node.NodeName
                AvailabilityGroupName         = $Node.AvailabilityGroupName
                ServerName                    = $Node.NodeName
                InstanceName                  = $Node.SQLInstanceName
                PrimaryReplicaSQLServer       = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).NodeName
                PrimaryReplicaSQLInstanceName = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).SQLInstanceName
            }
        }

        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            SqlAGDatabase 'TestAGDatabaseMemberships'
            {
                AvailabilityGroupName = $Node.AvailabilityGroupName
                BackupPath            = '\\SQL1\AgInitialize'
                DatabaseName          = 'DB*', 'AdventureWorks'
                InstanceName          = $Node.SQLInstanceName
                ServerName            = $Node.NodeName
                Ensure                = 'Present'
                Force                 = $true
                PsDscRunAsCredential  = $SysAdminAccount
            }
        }
    }
}
