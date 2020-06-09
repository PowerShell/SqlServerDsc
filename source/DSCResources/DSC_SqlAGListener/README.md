# Description

The `SqlAGListener` DSC resource is used to configure the listener
for an Always On Availability Group.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer
  PowerShell module.
* Requires that the Cluster name Object (CNO) has been delegated the right
  _Create Computer Object_ in the organizational unit (OU) in which the
  Cluster Name Object (CNO) resides.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlAGListener).
