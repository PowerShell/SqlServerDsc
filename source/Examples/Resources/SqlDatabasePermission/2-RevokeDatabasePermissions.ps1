<#
    .DESCRIPTION
        This example shows how to ensure that the user account CONTOSO\SQLAdmin
        hasn't "Select" and "Create Table" SQL Permissions for database "AdventureWorks".
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
        SqlDatabasePermission 'RevokeGrant_SqlDatabasePermissions_SQLAdmin'
        {
            Ensure               = 'Absent'
            Name                 = 'CONTOSO\SQLAdmin'
            DatabaseName         = 'AdventureWorks'
            PermissionState      = 'Grant'
            Permissions          = 'Connect', 'Update'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabasePermission 'RevokeDeny_SqlDatabasePermissions_SQLAdmin'
        {
            Ensure               = 'Absent'
            Name                 = 'CONTOSO\SQLAdmin'
            DatabaseName         = 'AdventureWorks'
            PermissionState      = 'Deny'
            Permissions          = 'Select', 'Create Table'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
