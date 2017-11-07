<#
.EXAMPLE
    This example shows how to ensure that the Availability Group 'TestAG' exists.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName        = '*'
            SQLInstanceName = 'MSSQLSERVER'
        },

        @{
            NodeName = 'SP23-VM-SQL1'
            Role     = 'PrimaryReplica'
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
            SQLServer            = $Node.NodeName
            SQLInstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Add the required permissions to the cluster service login
        SqlServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn            = '[SqlServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            NodeName             = $Node.NodeName
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
            SQLServer            = $Node.NodeName
            SQLInstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            SqlAG AddTestAG
            {
                Ensure               = 'Present'
                Name                 = 'TestAG'
                SQLInstanceName      = $Node.SQLInstanceName
                SQLServer            = $Node.NodeName
                DependsOn            = '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
}
