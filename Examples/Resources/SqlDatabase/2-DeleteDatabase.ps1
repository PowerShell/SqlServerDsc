<#
.EXAMPLE
    This example shows how to remove a database with
    the database name equal to 'AdventureWorks'.
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

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlDatabase Delete_Database
        {
            Ensure       = 'Absent'
            ServerName   = 'sqltest.company.local'
            InstanceName = 'DSC'
            Name         = 'AdventureWorks'
        }
    }
}
