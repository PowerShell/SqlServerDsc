<#
    .DESCRIPTION
        This example shows how to configure a SQL Server instance as the publisher.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlServerReplication 'publisher'
        {
            Ensure               = 'Present'
            InstanceName         = 'PUBLISHER' # Or 'MSSQLSERVER' for default instance.
            AdminLinkCredentials = $SqlAdministratorCredential
            DistributorMode      = 'Remote'
            DistributionDBName   = 'MyDistribution'
            RemoteDistributor    = 'distsqlsrv.company.local\DISTRIBUTOR'
            WorkingDirectory     = 'C:\Temp'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
