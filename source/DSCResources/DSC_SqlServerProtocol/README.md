# Description

The `SqlServerProtocol` DSC resource manage the SQL Server protocols
for a SQL Server instance.

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
