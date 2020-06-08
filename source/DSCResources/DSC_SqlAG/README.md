# Description

The `SqlAG` DSC resource is used to create, remove, and update an Always On
Availability Group. It will also manage the Availability Group replica on the
specified node.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' must have the 'Connect SQL',
  'Alter Any Availability Group', and 'View Server State' permissions.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlAG).
