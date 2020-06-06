<#
    .DESCRIPTION
        This example shows how to revoke permissions for the user 'TestAppRole'
        for a table in the database "AdventureWorks".
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
        SqlDatabaseObjectPermission 'Table1_TestAppRole_Permission'
        {
            ServerName           = 'testclu01a'
            InstanceName         = 'sql2014'
            DatabaseName         = 'AdventureWorks'
            SchemaName           = 'dbo'
            ObjectName           = 'Table1'
            ObjectType           = 'Table'
            Name                 = 'TestAppRole'
            Permission           = @(
                DSC_DatabaseObjectPermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @('Select')
                    Ensure     = 'Absent'
                }

                DSC_DatabaseObjectPermission
                {
                    State      = 'Grant'
                    Permission = @('Update')
                    Ensure     = 'Absent'
                }

                DSC_DatabaseObjectPermission
                {
                    State      = 'Deny'
                    Permission = @('Delete', 'Alter')
                    Ensure     = 'Absent'
                }
            )

            PSDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
