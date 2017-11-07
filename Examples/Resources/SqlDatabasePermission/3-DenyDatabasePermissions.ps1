<#
.DESCRIPTION
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

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlServerLogin Add_SqlServerLogin_SQLAdmin
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            LoginType            = 'WindowsUser'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlServerLogin Add_SqlServerLogin_SQLUser
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLUser'
            LoginType            = 'WindowsUser'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlDatabasePermission Deny_SqlDatabasePermissions_SQLAdmin_Db01
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            Database             = 'AdventureWorks'
            PermissionState      = 'Deny'
            Permissions          = 'Select', 'Create Table'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlDatabasePermission Deny_SqlDatabasePermissions_SQLUser_Db01
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLUser'
            Database             = 'AdventureWorks'
            PermissionState      = 'Deny'
            Permissions          = 'Select', 'Create Table'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlDatabasePermission Deny_SqlDatabasePermissions_SQLAdmin_Db02
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            Database             = 'AdventureWorksLT'
            PermissionState      = 'Deny'
            Permissions          = 'Select', 'Create Table'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
