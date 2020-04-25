<#
    .DESCRIPTION
        This example will enable the Shared Memory protocol.

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
            InstanceName         = 'MSSQLSERVER'
            ProtocolName         = 'SharedMemory'
            Enabled              = $true

            PsDscRunAsCredential = $SystemAdministratorAccount
        }
    }
}
