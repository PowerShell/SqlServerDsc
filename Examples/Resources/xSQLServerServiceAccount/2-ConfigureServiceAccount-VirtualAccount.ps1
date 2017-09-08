<#
.EXAMPLE
    This example shows how to ensure the SQL Server service
    on TestServer\DSC is running under a virtual account.
    Restart the service after updating.
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
            ServiceType = 'SqlServer'
            ServiceAccount = $ServiceAcccountCredential
            RestartService = $true
            Force = $true
        }
    }
}
