<#
    .DESCRIPTION
        This example shows how to ensure that the user account CONTOSO\SQLAdmin
        has "Connect" and "Update" SQL Permissions for database "AdventureWorks".
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlServerLogin 'Add_SqlServerLogin_SQLAdmin'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            LoginType            = 'WindowsUser'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlServerLogin 'Add_SqlServerLogin_SQLUser'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLUser'
            LoginType            = 'WindowsUser'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabasePermission 'Deny_SqlDatabasePermissions_SQLAdmin_Db01'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            DatabaseName         = 'AdventureWorks'
            PermissionState      = 'Deny'
            Permissions          = 'Select', 'Create Table'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabasePermission 'Deny_SqlDatabasePermissions_SQLUser_Db01'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLUser'
            DatabaseName         = 'AdventureWorks'
            PermissionState      = 'Deny'
            Permissions          = 'Select', 'Create Table'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabasePermission 'Deny_SqlDatabasePermissions_SQLAdmin_Db02'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            DatabaseName         = 'AdventureWorksLT'
            PermissionState      = 'Deny'
            Permissions          = 'Select', 'Create Table'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
