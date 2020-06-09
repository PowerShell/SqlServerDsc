# Description

The `SqlWaitForAG` DSC resource will wait for a cluster role/group to be
created. This is used to wait for an Availability Group to create the
cluster role/group in the cluster.

>Note: This only evaluates if the cluster role/group has been created and
>when it is found it will wait for RetryIntervalSec one last time before
>returning. There is currently no check to validate that the Availability
>Group was successfully created or that it has finished creating the
>Availability Group.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the Failover Cluster PowerShell module.

## Security Requirements

* The account running this resource must have permission in the cluster to be able
  to run the cmdlet Get-ClusterGroup.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlWaitForAG).
