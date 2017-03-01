<#
.EXAMPLE
    This example shows how to ensure that the server role named 
    AdminSqlforBI is present on instance SQLServer\DSC and only logins
    CONTOSO\SQLAdmin and CONTOSO\SQLAdminBI are members of this role.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    node localhost {
        xSQLServerRole Add_ServerRole_AdminSqlforBI
        {
            Ensure                  = 'Present'
            ServerRoleName          = 'AdminSqlforBI'
            Members                 = "CONTOSO\SQLAdmin","CONTOSO\SQLAdminBI"
            SQLServer               = 'SQLServer'
            SQLInstanceName         = 'DSC'
            PsDscRunAsCredential    = $SysAdminAccount
        }
    }
}
