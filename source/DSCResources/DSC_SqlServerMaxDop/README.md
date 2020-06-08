# Description

The `SqlMaxDop` DSC resource set the max degree of parallelism server
configuration option. The max degree of parallelism option is used to limit
the number of processors to use in parallel plan execution. Read more about
max degree of parallelism in this article
[Configure the max degree of parallelism Server Configuration Option](https://msdn.microsoft.com/en-us/library/ms189094.aspx)

## Formula for dynamically allocating max degree of parallelism

* If the number of configured NUMA nodes configured in SQL Server equals 1, then
  max degree of parallelism is calculated using number of cores divided in 2
  (numberOfCores / 2), then rounded up to the next integer (3.5 > 4).
* If the number of cores configured in SQL Server are greater than or equal to
  8 cores then max degree of parallelism will be set to 8.
* If the number of configured NUMA nodes configured in SQL Server is greater than
  2 and the number of cores are less than 8 then max degree of parallelism will
  be set to the number of cores.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlMaxDop).
