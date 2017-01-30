<#
.EXAMPLE
    This example shows how to ensure that the Availability Group 'TestAG' exists.
#>

$CreateAvailabilityGroupConfigData = @{
    AllNodes = @(
        @{
            NodeName= '*'
            CertificateFile = '763E73C85EA410AADCE94584687573F65EDC45FB'
            SQLInstanceName = 'MSSQLSERVER'
        },

        @{ 
            NodeName = 'SP23-VM-SQL1'
            Role = 'PrimaryReplica'
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
    
    Import-DscResource -ModuleName xSqlServer

    Node $AllNodes.NodeName {
        # Adding the required service account to allow the cluster to log into SQL
        xSQLServerLogin AddNTServiceClusSvc
        {
            Ensure = 'Present'
            Name = 'NT SERVICE\ClusSvc'
            LoginType = 'WindowsUser'
            SQLServer = $Node.NodeName
            SQLInstanceName = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Add the required permissions to the cluster service login
        xSQLServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn = '[xSQLServerLogin]AddNTServiceClusSvc'
            Ensure = 'Present'
            NodeName = $Node.NodeName
            InstanceName = $Node.SqlInstanceName
            Principal = 'NT SERVICE\ClusSvc' 
            Permission = 'AlterAnyAvailabilityGroup','ViewServerState'
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Create a DatabaseMirroring endpoint
        xSQLServerEndpoint HADREndpoint
        {
            EndPointName = 'HADR'
            Ensure = 'Present'
            Port = 5022
            AuthorizedUser = 'sa'
            SQLServer = $Node.NodeName
            SQLInstanceName = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            xSQLServerAlwaysOnAvailabilityGroup AddTestAG
            {
                Ensure = 'Present'
                Name = 'TestAG'
                SQLInstanceName = $Node.SQLInstanceName
                SQLServer = $Node.NodeName
                DependsOn = '[xSQLServerEndpoint]HADREndpoint','[xSQLServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
}
