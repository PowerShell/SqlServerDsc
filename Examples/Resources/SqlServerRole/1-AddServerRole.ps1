<#
.EXAMPLE
    This example shows how to ensure that both the server role named
    MyServerRole1 and MyServerRole2 is present on instance
    'sqltest.company.local\DSC'.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlServerRole Add_ServerRole_MyServerRole1
        {
            Ensure               = 'Present'
            ServerRoleName       = 'MyServerRole1'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlServerRole Add_ServerRole_MyServerRole1
        {
            Ensure               = 'Present'
            ServerRoleName       = 'MyServerRole2'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
