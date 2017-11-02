<#
.EXAMPLE
    This example performs a custom SSRS configuration. It will initialize SSRS
    and register custom Report Server Web Service and Report Manager URLs:

    http://localhost:80/MyReportServer
    https://localhost:443/MyReportServer (Report Server Web Service)

    http://localhost:80/MyReports
    https://localhost:443/MyReports (Report Manager)

    Please note: this resource does not currently handle SSL bindings for HTTPS
    endpoints.
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
            ReportServerVirtualDirectory = 'MyReportServer'
            ReportsVirtualDirectory = 'MyReports'
            ReportServerReservedUrl = @('http://+:80', 'https://+:443')
            ReportsReservedUrl = @('http://+:80', 'https://+:443')
        }
    }
}
