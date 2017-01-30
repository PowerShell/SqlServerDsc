<#
.EXAMPLE
This example shows how to ensure that the Availability Group 'TestAG' does not exist.
#>

$ConfigData = @{
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
        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            xSQLServerAlwaysOnAvailabilityGroup RemoveTestAG
            {
                Ensure = 'Absent'
                Name = 'TestAG'
                SQLInstanceName = $Node.SQLInstanceName
                SQLServer = $Node.NodeName
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
}
