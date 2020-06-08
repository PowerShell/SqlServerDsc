# Description

The `SqlPermission` DSC resource sets server permissions to a user
(login).

>**Note:** Currently the resource only supports ConnectSql, AlterAnyAvailabilityGroup,
>AlterAnyEndPoint and ViewServerState.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer
  PowerShell module.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlPermission).
