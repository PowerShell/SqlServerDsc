<#
.EXAMPLE
This example shows how to ensure that the Availability Group 'TestAG' does not exist.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = '*'
            InstanceName                = 'MSSQLSERVER'

            <#
                NOTE! THIS IS NOT RECOMMENDED IN PRODUCTION.
                This is added so that AppVeyor automatic tests can pass, otherwise
                the tests will fail on passwords being in plain text and not being
                encrypted. Because it is not possible to have a certificate in
                AppVeyor to encrypt the passwords we need to add parameter
                'PSDscAllowPlainTextPassword'.
                NOTE! THIS IS NOT RECOMMENDED IN PRODUCTION.
            #>
            PSDscAllowPlainTextPassword = $true
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
        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            SqlAG RemoveTestAG
            {
                Ensure               = 'Absent'
                Name                 = 'TestAG'
                InstanceName         = $Node.InstanceName
                ServerName           = $Node.NodeName
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
}
