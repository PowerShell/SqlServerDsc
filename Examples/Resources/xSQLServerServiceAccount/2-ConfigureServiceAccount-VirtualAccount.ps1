<#
.EXAMPLE
    This example shows how to ensure the SQL Server service
    on TestServer\DSC is running under a virtual account.
    Force will cause this account to be set every time the
    configuration is evaluated. Specifying RestartService will
    cause the service to be restarted.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $ServiceAcccountCredential
    )

    Import-DscResource -ModuleName xSqlServer

    Node localhost {
        xSQLServerServiceAccount SetServiceAcccount_User
        {
            SQLServer = 'TestServer'
            SQLInstanceName = 'DSC'
            ServiceType = 'DatabaseEngine'
            ServiceAccount = $ServiceAcccountCredential
            RestartService = $true
            Force = $true
        }
    }
}
