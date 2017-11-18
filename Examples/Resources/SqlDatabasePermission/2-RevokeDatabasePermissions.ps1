<#
.DESCRIPTION
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

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlDatabasePermission RevokeGrant_SqlDatabasePermissions_SQLAdmin
        {
            Ensure               = 'Absent'
            Name                 = 'CONTOSO\SQLAdmin'
            Database             = 'AdventureWorks'
            PermissionState      = 'Grant'
            Permissions          = 'Connect', 'Update'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlDatabasePermission RevokeDeny_SqlDatabasePermissions_SQLAdmin
        {
            Ensure               = 'Absent'
            Name                 = 'CONTOSO\SQLAdmin'
            Database             = 'AdventureWorks'
            PermissionState      = 'Deny'
            Permissions          = 'Select', 'Create Table'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
