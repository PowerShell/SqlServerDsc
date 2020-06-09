# Description

The `SqlWaitForAG` DSC resource will wait for a cluster role/group to be
created. This is used to wait for an Availability Group to create the
cluster role/group in the cluster.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the Failover Cluster PowerShell module.

## Security Requirements

* The account running this resource must have permission in the cluster to be able
  to run the cmdlet Get-ClusterGroup.

## Known issues

* This resource evaluates if the Windows Failover Cluster role/group
  has been created. But the Windows Failover Cluster role/group is created
  before the Availability Group is in a ready state. When the Windows Failover
  Cluster role/group is found the resource will wait for one more time
  according to the value of `RetryIntervalSec` before returning. There is
  currently no check to validate that the Availability Group was successfully
  created and is in a ready state. A workaround is instead use [`WaitForAny`](https://docs.microsoft.com/en-us/powershell/scripting/dsc/reference/resources/windows/waitforanyresource?view=powershell-7)
  resource. This is being tracked in [issue #1569](https://github.com/dsccommunity/SqlServerDsc/issues/1569).

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlWaitForAG).
