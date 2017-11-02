<#
.EXAMPLE
    This example shows how to ensure that the server role named
    serverRoleToDelete is not present on instance SQLServer\DSC.
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
        SqlServerRole Remove_ServerRole
        {
            Ensure               = 'Absent'
            ServerRoleName       = "serverRoleToDelete"
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
