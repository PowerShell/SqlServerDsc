<#
.EXAMPLE
    This example shows how to create a database with 
    the database name equal to 'Contoso'.
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
        xSQLServerDatabase Create_Database
        {
            Ensure = 'Present'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            Name = 'Contoso'
        }
    }
}
