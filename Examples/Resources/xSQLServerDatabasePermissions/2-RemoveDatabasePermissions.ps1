<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLAdmin
    hasn't "Select" and "Create Table" SQL Permissions for database "AdventureWorks". 
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
        xSQLServerLogin Add_SqlServerLogin_SQLAdmin
        {
            DependsOn = '[xSqlServerSetup]SETUP_SqlMSSQLSERVER'
            Ensure = 'Present'
            Name = 'CONTOSO\SQLAdmin'
            LoginType = 'WindowsUser'        
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerDatabasePermissions Add_SqlDatabasePermissions_SQLAdmin
        {
            DependsOn = '[xSQLServerLogin]Add_SqlServerLogin_SQLAdmin'
            Ensure = 'Absent'
            Name = 'CONTOSO\SQLAdmin'
            Database = 'AdventureWorks'
            PermissionState = 'Deny'
            Permissions = 'Select','Create Table'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
