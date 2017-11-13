<#
    .EXAMPLE
        This example will remove an Database Mirror endpoint from two instances.

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
            Ensure               = 'Absent'

            EndpointName         = 'HADR'
            InstanceName      = 'INST1'

            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlServerEndpoint SQLConfigureEndpoint-Instance2
        {
            Ensure               = 'Absent'

            EndpointName         = 'HADR'
            InstanceName      = 'INST2'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
