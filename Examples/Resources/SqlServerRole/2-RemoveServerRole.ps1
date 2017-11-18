<#
.EXAMPLE
    This example shows how to ensure that the server role named
    serverRoleToDelete is not present on instance sqltest.company.local\DSC.
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
        SqlServerRole Remove_ServerRole
        {
            Ensure               = 'Absent'
            ServerRoleName       = 'serverRoleToDelete'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
