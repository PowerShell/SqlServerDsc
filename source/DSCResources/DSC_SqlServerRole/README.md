# Description

The `SqlRole` DSC resource is used to create a server role, when
`Ensure` is set to `'Present'`, or remove a server role, when `Ensure`
is set to `'Absent'`. The resource also manages members in both built-in
and user created server roles.

For more information about server roles, please read the below articles.

* [Create a Server Role](https://msdn.microsoft.com/en-us/library/ee677627.aspx)
* [Server-Level Roles](https://msdn.microsoft.com/en-us/library/ms188659.aspx)

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlRole).
