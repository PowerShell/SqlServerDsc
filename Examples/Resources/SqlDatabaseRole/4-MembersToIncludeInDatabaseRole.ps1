<#
.EXAMPLE
    This example shows how to ensure that the database role named ReportViewer is present in the AdventureWorks
    database on instance sqltest.company.local\DSC and that users CONTOSO\Barbara and CONTOSO\Fred are added as members
    of this role.
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
        SqlDatabaseRole ReportViewer_IncludeRoleMembers
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Database             = 'AdventureWorks'
            Name                 = 'ReportViewer'
            MembersToInclude     = @('CONTOSO\Barbara', 'CONTOSO\Fred')
            Ensure               = 'Present'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
