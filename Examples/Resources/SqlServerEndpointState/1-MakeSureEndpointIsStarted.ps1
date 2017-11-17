<#
    .EXAMPLE
        This example will make sure that the endpoint DefaultMirrorEndpoint is in started state in the default instance, if not it will start the endpoint.

    .EXAMPLE
        This example will make sure that the endpoint HADR is in started state in the default instance, if not it will start the endpoint.

    .EXAMPLE
        This example will make sure that the endpoint DefaultMirrorEndpoint is in started state in the named instance INSTANCE1, if not it will start the endpoint.

    .NOTES
        There is three different scenarios in this example to validate the schema during unit testing.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        # Start the DefaultMirrorEndpoint in the default instance
        SqlServerEndpointState StartEndpoint1
        {
            ServerName           = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            Name                 = 'DefaultMirrorEndpoint'
            State                = 'Started'

            PsDscRunAsCredential = $SysAdminAccount
        }

        # Start the HADR in the default instance
        SqlServerEndpointState StartEndpoint2
        {
            ServerName           = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            Name                 = 'HADR'
            State                = 'Started'

            PsDscRunAsCredential = $SysAdminAccount
        }

        # Start the DefaultMirrorEndpoint in the named instance INSTANCE1
        SqlServerEndpointState StartEndpoint3
        {
            ServerName           = 'SQLNODE01.company.local'
            InstanceName         = 'INSTANCE1'
            Name                 = 'DefaultMirrorEndpoint'
            State                = 'Started'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
