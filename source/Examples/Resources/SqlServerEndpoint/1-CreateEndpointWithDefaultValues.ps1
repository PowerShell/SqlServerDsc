<#
    .DESCRIPTION
        This example will add a Database Mirror endpoint, to two instances, using
        the default values.

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
        SqlServerEndpoint 'SQLConfigureEndpoint-Instance1'
        {
            EndpointName         = 'HADR'
            EndpointType         = 'DatabaseMirroring'
            InstanceName         = 'INST1'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlServerEndpoint 'SQLConfigureEndpoint-Instances2'
        {
            EndpointName         = 'HADR'
            EndpointType         = 'DatabaseMirroring'
            InstanceName         = 'INST2'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
