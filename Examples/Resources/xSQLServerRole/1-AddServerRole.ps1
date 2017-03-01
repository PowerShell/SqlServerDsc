<#
.EXAMPLE
    This example shows how to ensure that the server role named 
    AdminSqlforBI is present on instance SQLServer\DSC.
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
            ServerRoleName          = "AdminSqlforBI"
            SQLServer               = 'SQLServer'
            SQLInstanceName         = 'DSC'
            PsDscRunAsCredential    = $SysAdminAccount
        }
    }
}
