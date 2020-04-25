<#
    .DESCRIPTION
        This example will disable the TCP/IP protocol.

        The resource will be run as the account provided in $SystemAdministratorAccount.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SystemAdministratorAccount
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlServerProtocol 'ChangeTcpIpOnDefaultInstance'
        {
            InstanceName           = 'MSSQLSERVER'
            ProtocolName           = 'TcpIp'
            Enabled                = $false

            PsDscRunAsCredential   = $SystemAdministratorAccount
        }
    }
}
