<#
.EXAMPLE
    This example shows how to configure a SQL Server instance as the publisher.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerReplication publisher
        {
            Ensure               = 'Present'
            InstanceName         = 'PUBLISHER'
            AdminLinkCredentials = $SysAdminAccount
            DistributorMode      = 'Remote'
            RemoteDistributor    = 'distsqlsrv.company.local'
            WorkingDirectory     = 'C:\Temp'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
