<#
.EXAMPLE
    This example shows how to ensure that the server role named
    AdminSqlforBI is present on instance SQLServer\DSC and logins
    CONTOSO\John and CONTOSO\Kelly are added as members of this role.
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
        SqlServerRole Add_ServerRole_AdminSqlforBI
        {
            Ensure               = 'Present'
            ServerRoleName       = 'AdminSqlforBI'
            MembersToInclude     = "CONTOSO\John", "CONTOSO\Kelly"
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
