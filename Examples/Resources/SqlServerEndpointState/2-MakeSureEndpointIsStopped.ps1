<#
    .EXAMPLE
        This example will make sure that the endpoint DefaultMirrorEndpoint is in stopped state, if not it will stop the endpoint.
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

    Import-DscResource -ModuleName SqlServerDSC

    node localhost
    {
        SqlServerEndpointState StopEndpoint
        {
            NodeName             = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            Name                 = 'DefaultMirrorEndpoint'
            State                = 'Stopped'

            PsDscRunAsCredential = $SysAdminAccount

        }
    }
}
