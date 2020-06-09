# Description

The `SqlWindowsFirewall` DSC resource will set default firewall rules for
the Database Engine, Analysis Services, SQL Browser, SQL Reporting Services,
and Integration Services features.

## Requirements

* Target machine must be running Windows Server 2012 or later.

## Firewall rules

### Database Engine (SQLENGINE) - Default instance

Firewall Rule | Firewall Display Name
--- | ---
Application: sqlservr.exe | SQL Server Database Engine instance MSSQLSERVER
Service: SQLBrowser | SQL Server Browser

### Database Engine (SQLENGINE) - Named instance

Firewall Rule | Firewall Display Name
--- | ---
Application: sqlservr.exe | SQL Server Database Engine instance \<INSTANCE\>
Service: SQLBrowser | SQL Server Browser

### Analysis Services (AS) - Default instance

Firewall Rule | Firewall Display Name
--- | ---
Service: MSSQLServerOLAPService | SQL Server Analysis Services instance MSSQLSERVER
Service: SQLBrowser | SQL Server Browser

### Analysis Services (AS) - Named instance

Firewall Rule | Firewall Display Name
--- | ---
Service: MSOLAP$\<INSTANCE\> | SQL Server Analysis Services instance \<INSTANCE\>
Service: SQLBrowser | SQL Server Browser

### Reporting Services (RS)

Firewall Rule | Firewall Display Name
--- | ---
Port: tcp/80 | SQL Server Reporting Services 80
Port: tcp/443 | SQL Server Reporting Services 443

### Integration Services (IS)

Firewall Rule | Firewall Display Name
--- | ---
Application: MsDtsSrvr.exe | SQL Server Integration Services Application
Port: tcp/135 | SQL Server Integration Services Port

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlWindowsFirewall).
