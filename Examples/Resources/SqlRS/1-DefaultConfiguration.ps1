<#
.EXAMPLE
    This example performs a default SSRS configuration. It will initialize SSRS
    and register default Report Server Web Service and Report Manager URLs:

    http://localhost:80/ReportServer (Report Server Web Service)

    http://localhost:80/Reports (Report Manager)
#>
Configuration Example
{
    Import-DscResource -ModuleName xSqlServer

    node localhost {
        SqlRS DefaultConfiguration
        {
            InstanceName = 'MSSQLSERVER'
            RSSQLServer = 'localhost'
            RSSQLInstanceName = 'MSSQLSERVER'
        }
    }
}
