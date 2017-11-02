<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLAdmin
    has "MyRole" and "MySecondRole" SQL database roles.
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

    node localhost
    {
        SqlDatabaseRole Add_Database_Role
        {
            Ensure               = 'Present'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            Name                 = 'CONTOSO\SQLAdmin'
            Role                 = 'MyRole', 'MySecondRole'
            Database             = 'AdventureWorks'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
