# Description

The `SqlSecureConnection` DSC resource Configures SQL connections
to be encrypted. Read more about encrypted connections in this article
[Enable Encrypted Connections](https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/enable-encrypted-connections-to-the-database-engine).

>**Note:** The 'LocalSystem' service account will return a connection
>error, even though the connection has been successful. In that case,
>the 'SYSTEM' service account can be used.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* You must have a Certificate that is trusted and issued for
   `ServerAuthentication`.
* The name of the Certificate must be the fully qualified domain name (FQDN)
   of the computer.
* The Certificate must be installed in the LocalMachine Personal store.
* If `PsDscRunAsCredential` common parameter is used to run the resource, the
  specified credential must have permissions to connect to the SQL Server instance
  specified in `InstanceName`.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlSecureConnection).
