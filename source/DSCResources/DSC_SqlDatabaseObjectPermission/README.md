# Description

The `SqlDatabaseObjectPermission` DSC resource manage the permissions
of database objects in a database for a SQL Server instance.

For more information about permission names that can be managed, see the
property names of the [ObjectPermissionSet](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.objectpermissionset#properties) class.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the
  SqlServer PowerShell module.
