<#
    .DESCRIPTION
        This example will enable the TCP/IP protocol, set the protocol to listen
        on all IP addresses, and set the keep alive duration.

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
            Enabled                = $true
            ListenOnAllIpAddresses = $false
            KeepAlive              = 20000

            PsDscRunAsCredential   = $SystemAdministratorAccount
        }
    }
}
