<#
.EXAMPLE
    This example shows how to ensure the SQL Server service
    on TestServer is running under a user account.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $ServiceAccountCredential
    )

    Import-DscResource -ModuleName xSqlServer

    Node localhost {
        xSQLServerServiceAccount SetServiceAcccount_User
        {
            SQLServer = 'TestServer'
            SQLInstanceName = 'MSSQLSERVER'
            ServiceType = 'SqlServer'
            ServiceAccount = $ServiceAccountCredential
            RestartService = $true
        }
    }
}
