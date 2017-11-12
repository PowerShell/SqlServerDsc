<#
    .EXAMPLE
        This example will add a Database Mirror endpoint, to two instances, using the default values.

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
        SqlServerEndpoint SQLConfigureEndpoint-Instance1
        {
            EndpointName         = 'HADR'
            InstanceName         = 'INST1'

            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlServerEndpoint SQLConfigureEndpoint-Instances2
        {
            EndpointName         = 'HADR'
            InstanceName         = 'INST2'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
