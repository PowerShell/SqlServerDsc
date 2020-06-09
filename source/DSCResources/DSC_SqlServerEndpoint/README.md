# Description

The `SqlEndpoint` DSC resource is used to create an endpoint. Currently
it only supports creating a database mirror endpoint. A database mirror
endpoint can be used by AlwaysOn.

>Note: The endpoint will be started after creation, but will not be enforced
>unless the the parameter `State` is specified.
>To set connect permission to the endpoint, please use
>the resource [**SqlEndpointPermission**](#sqlendpointpermission).

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.

## Security Requirements

* The built-in parameter PsDscRunAsCredential must be set to the credentials of
  an account with the permission to create and alter endpoints.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlEndpoint).
