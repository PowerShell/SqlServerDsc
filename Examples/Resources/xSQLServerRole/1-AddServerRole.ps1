<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLAdmin
    has "dbcreator" and "securityadmin" SQL server roles. 
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

    node localhost {
        xSQLServerRole Add_SqlServerRole_SQLAdmin
        {
            DependsOn = '[xSQLServerLogin]Add_SqlServerLogin_SQLAdmin'
            Ensure = 'Present'
            Name = 'CONTOSO\SQLAdmin'
            ServerRole = "dbcreator","securityadmin"
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
