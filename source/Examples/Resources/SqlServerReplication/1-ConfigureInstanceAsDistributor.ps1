<#
    .DESCRIPTION
        This example shows how to configure a SQL Server instance as the distributor.
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
        SqlServerReplication 'distributor'
        {
            Ensure               = 'Present'
            InstanceName         = 'DISTRIBUTOR' # Or 'MSSQLSERVER' for default instance.
            AdminLinkCredentials = $SqlAdministratorCredential
            DistributorMode      = 'Local'
            DistributionDBName   = 'MyDistribution'
            WorkingDirectory     = 'C:\Temp'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
