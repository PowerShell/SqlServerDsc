<#
    .DESCRIPTION
        This example shows how to ensure that the database user User1 are
        mapped to the certificate Certificate1 in the AdventureWorks database in
        the instance sqltest.company.local\DSC.
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
            UserType             = 'Certificate'
            CertificateName      = 'Certificate1'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
