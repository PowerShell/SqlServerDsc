# Description

The `SqlLogin` DSC resource manages SQL Server logins
for a SQL Server instance.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* When the `LoginType` `'SqlLogin'` is used, then the login authentication
  mode must have been set to `Mixed` or `Normal`. If set to `Integrated`
  and error will be thrown.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlLogin).
