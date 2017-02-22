<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLAdmin
    hasn't the "DeleteRole" SQL database roles.
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
        xSQLServerDatabaseRole Remove_Database_Role
        {
            Ensure = 'Present'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            Name = 'CONTOSO\SQLAdmin'
            Role = 'DeleteRole'
            Database = 'AdventureWorks'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
