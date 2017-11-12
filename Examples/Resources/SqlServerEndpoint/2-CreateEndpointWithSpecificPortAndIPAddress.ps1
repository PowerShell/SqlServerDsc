<#
    .EXAMPLE
        This example will add a Database Mirror endpoint with a specific listener port and a specific listener IP address.
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
        SqlServerEndpoint SQLConfigureEndpoint
        {
            Ensure               = 'Present'

            EndpointName         = 'HADR'
            Port                 = 9001
            IpAddress            = '192.168.0.20'

            ServerName           = 'server1.company.local'
            InstanceName         = 'INST1'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
