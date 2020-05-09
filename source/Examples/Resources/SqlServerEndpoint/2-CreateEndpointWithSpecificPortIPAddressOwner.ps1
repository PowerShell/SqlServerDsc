<#
    .DESCRIPTION
        This example will add a Database Mirror endpoint with specific listener port,
        listener IP address and owner.
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
        SqlServerEndpoint 'SQLConfigureEndpoint'
        {
            Ensure               = 'Present'

            EndpointName         = 'HADR'
            EndpointType         = 'DatabaseMirroring'
            Port                 = 9001
            IpAddress            = '192.168.0.20'
            Owner                = 'sa'
            State                = 'Started'

            ServerName           = 'server1.company.local'
            InstanceName         = 'INST1'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
