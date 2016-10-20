<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLUser
    does not have "setupadmin" SQL server role. 
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
            Ensure = 'Absent'
            Name = 'CONTOSO\SQLUser'
            ServerRole = "setupadmin"
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
