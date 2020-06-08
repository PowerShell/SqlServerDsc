# Description

The `SqlRS` DSC resource initializes and configures SQL Reporting Services
server.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Reporting Services 20012 or later.
* To use parameter `UseSSL` target machine must be running SQL Server Reporting
  Services 2012 or later.
* If `PsDscRunAsCredential` common parameter is used to run the resource, the
  specified credential must have permissions to connect to the SQL Server instance
  specified in `DatabaseServerName` and `DatabaseInstanceName`, and have permission
  to create the Reporting Services databases.

## Known issues

* This resource does not currently have full SSL support, please see
  [issue #587](https://github.com/dsccommunity/SqlServerDsc/issues/587) for more
  information.

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlRS).

## Known error messages

### Error: The parameter is incorrect (HRESULT:-2147024809)

This is for example caused by trying to add an URL with the wrong format
i.e. 'htp://+:80'.

### Error: The Url has already been reserved (HRESULT:-2147220932)

This is caused when the URL is already reserved. For example when 'http://+:80'
already exist.

### Error: Cannot create a file when that file already exists (HRESULT:-2147024713)

This is caused when trying to add another URL using the same protocol. For example
when trying to add 'http://+:443' when 'http://+:80' already exist.
