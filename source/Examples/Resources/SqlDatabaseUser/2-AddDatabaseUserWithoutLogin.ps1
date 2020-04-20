<#
    .DESCRIPTION
        This example shows how to ensure that the database user User1 are present
        in the AdventureWorks database in the instance sqltest.company.local\DSC.
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
        SqlDatabaseUser 'AddUser1'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            DatabaseName         = 'AdventureWorks'
            UserName             = 'User1'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
