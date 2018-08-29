<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLAdmin
    is "Owner" of SQL database "AdventureWorks".
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
        SqlServerLogin Add_SqlServerLogin_SQLAdmin_DSC
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            LoginType            = 'WindowsUser'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlServerLogin Add_SqlServerLogin_SQLAdmin_DSC2
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            LoginType            = 'WindowsUser'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC2'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabaseOwner Set_SqlDatabaseOwner_SQLAdmin_DSC
        {
            Name                 = 'CONTOSO\SQLAdmin'
            Database             = 'AdventureWorks'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabaseOwner Set_SqlDatabaseOwner_SQLAdmin_DSC2
        {
            Name                 = 'CONTOSO\SQLAdmin'
            Database             = 'AdventureWorks'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC2'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
