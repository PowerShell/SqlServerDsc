<#
    .DESCRIPTION
        This example shows how to ensure that the database role named
        ReportViewer is not present in the AdventureWorks database on
        instance sqltest.company.local\DSC.
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
        SqlDatabaseRole 'ReportViewer_DropRole'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            DatabaseName         = 'AdventureWorks'
            RoleName             = 'ReportViewer'
            Ensure               = 'Absent'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
