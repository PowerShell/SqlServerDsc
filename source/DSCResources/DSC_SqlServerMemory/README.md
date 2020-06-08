# Description

The `SqlMemory` DSC resource sets the minimum server memory and
maximum server memory configuration option. That means it sets the minimum
and the maximum amount of memory, in MB, in the buffer pool used by the
instance of SQL Server The default setting for minimum server memory is 0,
and the default setting for maximum server memory is 2147483647 MB. Read
more about minimum server memory and maximum server memory in this article
[Server Memory Server Configuration Options](https://msdn.microsoft.com/en-us/library/ms178067.aspx).

## Formula for dynamically allocating maximum memory

The formula is based on the [SQL Max Memory Calculator](http://sqlmax.chuvash.eu/)
website. This was inspired from the repository [sql-max](https://github.com/mirontoli/sql-max)
maintained by [@mirontoli](https://github.com/mirontoli).

### Formula

The dynamic maximum memory (in MB) is calculate with this formula:

```powershell
TotalPhysicalMemory - (NumOfSQLThreads * ThreadStackSize) - (1024 * CEILING(NumOfCores / 4)) - OSReservedMemory
```

#### NumOfSQLThreads

* If the number of cores is less than or equal to 4, the number of SQL threads
  is set to: 256 + (NumberOfCores - 4) \* 8.
* If the number of cores is greater than 4, the number of SQL threads is set
  to: 0 (zero).

#### ThreadStackSize

* If the architecture of windows server is x86, the size of thread stack is 1MB.
* If the architecture of windows server is x64, the size of thread stack is 2MB.
* If the architecture of windows server is IA64, the size of thread stack is 4MB.

#### OSReservedMemory

* If the total physical memory is less than or equal to 20GB, the percentage of
  reserved memory for OS is 20% of total physical memory.
* If the total physical memory is greater than 20GB, the percentage of reserved
  memory for OS is 12.5% of total physical memory.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlMemory).
