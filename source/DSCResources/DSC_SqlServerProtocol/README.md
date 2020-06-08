# Description

The `SqlProtocol` DSC resource manage the SQL Server protocols
for a SQL Server instance.

For more information about protocol properties look at the following articles:

* [TCP/IP Properties (Protocols Tab)](https://docs.microsoft.com/en-us/sql/tools/configuration-manager/tcp-ip-properties-protocols-tab).
* [Shared Memory Properties](https://docs.microsoft.com/en-us/sql/tools/configuration-manager/shared-memory-properties).
* [Named Pipes Properties](https://docs.microsoft.com/en-us/sql/tools/configuration-manager/named-pipes-properties).

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer
  PowerShell module.
* If a protocol is disabled that prevents the cmdlet `Restart-SqlService` to
  contact the instance to evaluate if it is a cluster then the parameter
  `SuppressRestart` must be used to override the restart. Same if a protocol
  is enabled that was previously disabled and no other protocol allows
  connecting to the instance then the parameter `SuppressRestart` must also
  be used.
* When connecting to a Failover Cluster where the account `SYSTEM` does
  not have access then the correct credential must be provided in
  the built-in parameter `PSDscRunAsCredential`. If not the following error
  can appear; `An internal error occurred`.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlProtocol).
