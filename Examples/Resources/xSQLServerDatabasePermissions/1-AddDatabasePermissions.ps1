<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLAdmin
    has "Connect" and "Update" SQL Permissions for database "AdventureWorks". 
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
                Ensure = 'Present'
                Name = 'CONTOSO\SQLAdmin'
                Database = 'AdventureWorks'
                PermissionState = 'Grant'
                Permissions = "Connect","Update"
                SQLServer = 'SQLServer'
                SQLInstanceName = 'DSC'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
