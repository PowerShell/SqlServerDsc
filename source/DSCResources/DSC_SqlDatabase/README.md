# Description

The `SqlDatabase` DSC resource is used to create or delete a database.
For more information about SQL Server databases, please read the following
articles [Create a Database](https://docs.microsoft.com/en-us/sql/relational-databases/databases/create-a-database)
and [Delete a Database](https://docs.microsoft.com/en-us/sql/relational-databases/databases/delete-a-database).

This resource sets the recovery model for a database. The recovery model controls
how transactions are logged, whether the transaction log requires (and allows)
backing up, and what kinds of restore operations are available. Three recovery
models exist: full, simple, and bulk-logged. Read more about recovery model in
the article [View or Change the Recovery Model of a Database](https://msdn.microsoft.com/en-us/library/ms189272.aspx).

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Valid values per SQL Server version for the parameter `CompatibilityLevel`
  can be found in the article [ALTER DATABASE (Transact-SQL) Compatibility Level](https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql-compatibility-level).

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabase).
