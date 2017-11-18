<#
.EXAMPLE
    This example shows how to ensure that the server role named
    AdminSqlforBI is present on instance sqltest.company.local\DSC.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlServerRole Add_ServerRole_AdminSqlforBI
        {
            Ensure               = 'Present'
            ServerRoleName       = 'AdminSqlforBI'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
