<#
    .EXAMPLE
        This example will add connect permission to the credentials provided in $SqlServiceCredential
        to the endpoint named 'DefaultMirrorEndpoint'.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SysAdminAccount,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlServiceCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerEndpointPermission SQLConfigureEndpointPermission
        {
            Ensure               = 'Present'
            NodeName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceCredential.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
