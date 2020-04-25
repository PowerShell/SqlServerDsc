<#
    .DESCRIPTION
        This example will enable the Named Pipes protocol and set the name of the pipe.

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
            ProtocolName         = 'NamedPipes'
            Enabled              = $true
            PipeName             = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'

            PsDscRunAsCredential = $SystemAdministratorAccount
        }
    }
}
