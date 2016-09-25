<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLAdmin
    has "CONNECT" and "CREATE TABLE" SQL Permissions for database "AdventureWorks". 
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
                Name = 'CONTOSO\SQLAdmin'
                Database = 'AdventureWorks'
                Permissions = "CONNECT","CREATE TABLE"
                SQLServer = 'SQLServer'
                SQLInstanceName = 'DSC'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
