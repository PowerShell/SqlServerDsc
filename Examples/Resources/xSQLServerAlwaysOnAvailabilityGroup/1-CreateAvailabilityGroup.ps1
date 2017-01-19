<#
.EXAMPLE
This example shows how to ensure that the Windows user 'CONTOSO\WindowsUser' exists. 
#>

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName= '*'
            CertificateFile = '333895F4346E654E236082EAACE99AB31C900DCF'
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
    
    Import-DscResource -ModuleName xSqlServer -ModuleVersion 4.0.0.1

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
                SQLServer = $Node.NodeNAme
                DependsOn = '[xSQLServerEndpoint]HADREndpoint','[xSQLServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
}