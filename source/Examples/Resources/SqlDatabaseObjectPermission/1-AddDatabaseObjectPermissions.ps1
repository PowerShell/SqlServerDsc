<#
    .DESCRIPTION
        This example shows how to ensure that the user 'TestAppRole' is given
        the desired permission for a table in the database "AdventureWorks".
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
                }

                DSC_DatabaseObjectPermission
                {
                    State      = 'Grant'
                    Permission = @('Update')
                }

                DSC_DatabaseObjectPermission
                {
                    State      = 'Deny'
                    Permission = @('Delete', 'Alter')
                }
            )

            PSDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
