<#
.EXAMPLE
    This example shows how to ensure that the server role named 
    AdminSqlforBI is present on instance SQLServer\DSC and logins
    CONTOSO\Mark and CONTOSO\Lucy have been dropped from members of this role.
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
        xSQLServerRole Drop_ServerRole_AdminSqlforBI
        {
            Ensure = 'Present'
            ServerRole = 'AdminSqlforBI'
            MembersToExclude = "CONTOSO\Mark","CONTOSO\Lucy"
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
