<#
    .DESCRIPTION
        This example shows how to ensure that the database user CONTOSO\ReportViewers
        is absent from the AdventureWorks database in the instance sqltest.company.local\DSC.
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
        SqlDatabaseUser 'ContosoReportViewer_RemoveUser'
        {
            Ensure               = 'Absent'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            DatabaseName         = 'AdventureWorks'
            UserName             = 'CONTOSO\ReportViewer'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
