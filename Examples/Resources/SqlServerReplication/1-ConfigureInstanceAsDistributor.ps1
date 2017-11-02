<#
.EXAMPLE
    This example shows how to configure a SQL Server instance as the distributor.
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

    Import-DscResource -ModuleName xSqlServer

    node localhost
    {
        SqlServerReplication distributor
        {
            Ensure               = 'Present'
            InstanceName         = 'MSSQLSERVER'
            AdminLinkCredentials = $SysAdminAccount
            DistributorMode      = 'Local'
            WorkingDirectory     = 'C:\Temp'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
