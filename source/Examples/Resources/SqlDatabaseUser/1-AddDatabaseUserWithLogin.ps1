<#
    .DESCRIPTION
        This example shows how to ensure that the database users ReportAdmin,
        CONTOSO\ReportEditors, and CONTOSO\ReportViewers are present in the
        AdventureWorks database in the instance sqltest.company.local\DSC.
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
        SqlDatabaseUser 'ReportAdmin_AddUser'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            DatabaseName         = 'AdventureWorks'
            UserName             = 'ReportAdmin'
            UserType             = 'Login'
            LoginName            = 'ReportAdmin'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabaseUser 'ContosoReportEditor_AddUser'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            DatabaseName         = 'AdventureWorks'
            UserName             = 'CONTOSO\ReportEditor'
            UserType             = 'Login'
            LoginName            = 'CONTOSO\ReportEditor'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabaseUser 'ContosoReportViewer_AddUser'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            DatabaseName         = 'AdventureWorks'
            UserName             = 'CONTOSO\ReportViewer'
            UserType             = 'Login'
            LoginName            = 'CONTOSO\ReportViewer'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
