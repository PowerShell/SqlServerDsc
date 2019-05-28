<#
.EXAMPLE
    This example shows how to ensure that the database roles named ReportEditor and ReportViewer is present in the
    AdventureWorks database on instance sqltest.company.local\DSC.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlDatabaseRole ReportEditor_AddRole
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Database             = 'AdventureWorks'
            Name                 = 'ReportEditor'
            Ensure               = 'Present'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabaseRole ReportViewer_AddRole
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Database             = 'AdventureWorks'
            Name                 = 'ReportViewer'
            Ensure               = 'Present'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
