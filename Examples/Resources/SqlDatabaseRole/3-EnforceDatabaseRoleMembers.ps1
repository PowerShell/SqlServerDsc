<#
.EXAMPLE
    This example shows how to ensure that the database role named ReportViewer is present in the AdventureWorks
    database on instance sqltest.company.local\DSC and that only users CONTOSO\Barbara and CONTOSO\Fred are members of
    this role.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlDatabaseRole ReportViewer_EnforceRoleMembers
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Database             = 'AdventureWorks'
            Name                 = 'ReportViewer'
            Members              = @('CONTOSO\Barbara', 'CONTOSO\Fred')
            Ensure               = 'Present'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
