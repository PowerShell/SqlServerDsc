# Description

The `SqlDatabasePermission` DSC resource is used to grant, deny or revoke
permissions for a user in a database. For more information about permissions,
please read the article [Permissions (Database Engine)](https://docs.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine).

>**Note:** When revoking permission with PermissionState 'GrantWithGrant', both the
>grantee and _all the other users the grantee has granted the same permission to_,
>will also get their permission revoked.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabasePermission).
