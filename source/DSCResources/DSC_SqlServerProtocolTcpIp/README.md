# Description

The `SqlProtocolTcpIp` DSC resource manages the TCP/IP
IP address groups for a SQL Server instance.

IP Address groups are added depending on available network cards, see
[Adding or Removing IP Addresses](https://docs.microsoft.com/en-us/sql/tools/configuration-manager/tcp-ip-properties-ip-addresses-tab#adding-or-removing-ip-addresses).
Because of that it is not supported to add or remove IP address groups.

For more information about static and dynamic ports read the article
[TCP/IP Properties (IP Addresses Tab)](https://docs.microsoft.com/en-us/sql/tools/configuration-manager/tcp-ip-properties-ip-addresses-tab).

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer
  PowerShell module.
* To configure a single IP address to listen on multiple ports, the
  TcpIp protocol must also set the **Listen All** property to **No**.
  This can be done with the resource `SqlProtocol` using the
  parameter `ListenOnAllIpAddresses`.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlProtocolTcpIp).
