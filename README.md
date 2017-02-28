# xSQLServer

The **xSQLServer** module contains DSC resources for deployment and configuration of SQL Server.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/mxn453y284eab8li/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xsqlserver/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xSQLServer/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xSQLServer>)

This is the branch containing the latest release - no contributions should be made directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/mxn453y284eab8li/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xsqlserver/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xSQLServer/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xSQLServer)

This is the development branch to which contributions should be proposed by contributors as pull requests. This development branch will periodically be merged to the master branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Regardless of the way you want to contribute we are tremendously happy to have you here.

There are several ways you can contribute. You can submit an issue to report a bug. You can submit an issue to request an improvment. You can take part in discussions for issues. You can review pull requests and comment on other contributors changes.
You can also improve the resources and tests, or even create new resources, by sending in pull requests yourself.

* If you want to submit an issue or take part in discussions, please browse the list of [issues](https://github.com/PowerShell/xSQLServer/issues). Please check out [Contributing to the DSC Resource Kit](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md) on how to work with issues.
* If you want to review pull requests, please first check out the [Review Pull Request guidelines](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md#reviewing-pull-requests), and the browse the list of [pull requests](https://github.com/PowerShell/xSQLServer/pulls) and look for those pull requests with label 'needs review'.
* If you want to improve the resources or tests, or create a new resource, then please check out the following guidelines.
  * The [Contributing to the DSC Resource Kit](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md) guidelines.
  * The specific [Contributing to xSQLServer](https://github.com/PowerShell/xSQLServer/blob/dev/CONTRIBUTING.md) guidelines.
  * The common [Style Guidelines](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md).
  * The common [Best Practices](https://github.com/PowerShell/DscResources/blob/master/BestPractices.md) guidelines.
  * The common [Testing Guidelines](https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md).
  * If you are new to GitHub (and git), then please check out [Getting Started with GitHub](https://github.com/PowerShell/DscResources/blob/master/GettingStartedWithGitHub.md).
  * If you are new to Pester and writing test, then please check out [Getting started with Pester](https://github.com/PowerShell/DscResources/blob/master/GettingStartedWithPester.md).

If you need any help along the way, don't be afraid to ask. We are here for each other.

## Installation

To manually install the module, download the source code and unzip the contents of the '\Modules\xSQLServer' directory to the '$env:ProgramFiles\WindowsPowerShell\Modules' folder.

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0) run the following command:

```powershell
Find-Module -Name xSQLServer -Repository PSGallery | Install-Module
```

To confirm installation, run the below command and ensure you see the SQL Server DSC resources available:

```powershell
Get-DscResource -Module xSQLServer
```

## Requirements

The minimum Windows Management Framework (PowerShell) version required is 4.0, which ships in Windows 8.1 or Windows Server 2012 R2 (or higher versions). But Windows Management Framework (PowerShell) 4.0 can also be installed on Windows Server 2008 R2.
The preferred Windows Management Framework (PowerShell) version is 5.0 or higher, which ships with Windows 10 or Windows Server 2016, but can also be installed on Windows 7 SP1, Windows 8.1, Windows Server 2008 R2 SP1, Windows Server 2012 and Windows Server 2012 R2.

## Examples

You can review the [Examples](/Examples) directory in the xSQLServer module for some general use scenarios for all of the resources that are in the module.

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

* [**xSQLAOGroupEnsure**](#xsqlaogroupensure) resource to ensure availability group is present or absent
* [**xSQLAOGroupJoin**](#xsqlaogroupjoin) resource to join a replica to an existing availability group
* [**xSQLServerAlias**](#xsqlserveralias) resource to manage SQL Server client Aliases
* [**xSQLServerAlwaysOnAvailabilityGroup**](#xsqlserveralwaysonavailabilitygroup) resource to ensure an availability group is present or absent.
* [**xSQLServerAlwaysOnService**](#xsqlserveralwaysonservice) resource to enable always on on a SQL Server
* [**xSQLServerAvailabilityGroupListener**](#xsqlserveravailabilitygrouplistener) Create or remove an availability group listener.
* [**xSQLServerConfiguration**](#xsqlserverconfiguration) resource to manage [SQL Server Configuration Options](https://msdn.microsoft.com/en-us/library/ms189631.aspx)
* [**xSQLServerDatabase**](#xsqlserverdatabase) resource to manage ensure database is present or absent
* [**xSQLServerDatabaseOwner**](#xsqlserverdatabaseowner) resource to manage SQL database owners
* [**xSQLServerDatabasePermission**](#xsqlserverdatabasepermission) resource to manage SQL database permissions
* [**xSQLServerDatabaseRecoveryModel**](#xsqlserverdatabaserecoverymodel) resource to manage database recovery model
* [**xSQLServerDatabaseRole**](#xsqlserverdatabaserole) resource to manage SQL database roles
* [**xSQLServerEndpoint**](#xsqlserverendpoint) resource to ensure database endpoint is present or absent
* [**xSQLServerEndpointPermission**](#xsqlserverendpointpermission) Grant or revoke permission on the endpoint.
* [**xSQLServerEndpointState**](#xsqlserverendpointstate) Change state of the endpoint.
* [**xSQLServerFailoverClusterSetup**](#xsqlserverfailoverclustersetup) installs SQL Server failover cluster instances.
* [**xSQLServerFirewall**](#xsqlserverfirewall) configures firewall settings to allow remote access to a SQL Server instance.
* [**xSQLServerLogin**](#xsqlserverlogin) resource to manage SQL logins
* [**xSQLServerMaxDop**](#xsqlservermaxdop) resource to manage MaxDegree of Parallelism for SQL Server
* [**xSQLServerMemory**](#xsqlservermemory) resource to manage Memory for SQL Server
* [**xSQLServerNetwork**](#xsqlservernetwork) resource to manage SQL Server Network Protocols
* [**xSQLServerPermission**](#xsqlserverpermission) Grant or revoke permission on the SQL Server.
* [**xSQLServerRole**](#xsqlserverrole) resource to manage SQL server roles
* [**xSQLServerReplication**](#xsqlserverreplication) resource to manage SQL Replication distribution and publishing.
* [**xSQLServerRSConfig**](#xsqlserverrsconfig) configures SQL Server Reporting Services to use a database engine in another instance.
* [**xSQLServerRSSecureConnectionLevel**](#xsqlserverrssecureconnectionlevel) sets the secure connection level for SQL Server Reporting Services.
* [**xSQLServerScript**](#xsqlserverscript) resource to extend DSCs Get/Set/Test functionality to T-SQL
* [**xSQLServerSetup**](#xsqlserversetup) installs a standalone SQL Server instance
* [**xWaitForAvailabilityGroup**](#xwaitforavailabilitygroup) resource to wait till availability group is created on primary server

### xSQLAOGroupEnsure

No description.

**This resource is deprecated.** The functionality of this resource has been replaced with * [**xSQLServerAlwaysOnAvailabilityGroup**](#xsqlserveralwaysonavailabilitygroup). Please do not use this resource for new development efforts.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the Active Directory module.

#### Security Requirements

* The credentials provided in the parameter `SetupCredential` must have the right **Create Computer Object** in the origanization unit (OU) in which the Cluster Name Object (CNO) resides.

#### Parameters

* **[String] Ensure** _(Key)_: Determines whether the availability group should be added or removed. { Present | Absent }.
* **[String] AvailabilityGroupName**_(Key)_: Name for availability group.
* **[String] AvailabilityGroupNameListener** _(Write)_: Listener name for availability group.
* **[String[]] AvailabilityGroupNameIP** _(Write)_: List of IP addresses associated with listener.
* **[String[]] AvailabilityGroupSubMask** _(Write)_: Network subnetmask for listener.
* **[Unint32] AvailabilityGroupPort** _(Write)_: Port availability group should listen on.
* **[String] ReadableSecondary** _(Write)_: Mode secondaries should operate under (None, ReadOnly, ReadIntent). { None | *ReadOnly* | ReadIntent }.
* **[String] AutoBackupPreference** _(Write)_: Where backups should be backed up from (Primary, Secondary). { *Primary* | Secondary }.
* **[Uint32] BackupPriority** _(Write)_: The percentage weight for backup prority (default 50).
* **[Uint32] EndPointPort** _(Write)_: The TCP port for the SQL AG Endpoint (default 5022).
* **[String] SQLServer** _(Write)_: The SQL Server for the database.
* **[String] SQLInstance** _(Write)_: The SQL instance for the database.
* **[PSCredential] SetupCredential** _(Required)_: Credential to be used to Grant Permissions on SQL Server, set this to $null to use Windows Authentication.

#### Examples

None.

### xSQLAOGroupJoin

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine2012 or later.

#### Parameters

* **[String] Ensure** _(Key)_: If the replica should be joined ('Present') to the Availability Group or not joined ('Absent') to the Availability Group. { Present | Absent }.
* **[String] AvailabilityGroupName** _(Key)_: The name Availability Group to join.
* **[String] SQLServer** _(Write)_: Name of the SQL server to be configured.
* **[String] SQLInstanceName** _(Write)_: Name of the SQL instance to be configured.
* **[PSCredential] SetupCredential** _(Required)_: Credential to be used to Grant Permissions in SQL.

#### Examples

None.

### xSQLServerAlias

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **[String] Name** _(Key)_: The name of Alias (e.g. svr01\inst01).
* **[String] ServerName** _(Key)_: The SQL Server you are aliasing (the netbios name or FQDN).
* **[String] Ensure** _(Write)_: Determines whether the alias should be added or removed. Default value is 'Present'. { *Present* | Absent }.
* **[String] Protocol** _(Write)_: Protocol to use when connecting. Valid values are 'TCP' or 'NP' (Named Pipes). Default value is 'TCP'. { *TCP* | NP }.
* **[Uint16] TCPPort** _(Write)_: The TCP port SQL is listening on. Only used when protocol is set to 'TCP'. Default value is port 1433.
* **[Boolean] UseDynamicTcpPort** _(Write)_: The UseDynamicTcpPort specify that the Net-Library will determine the port dynamically. The port specified in Port number will not be used. Default value is '$false'.

#### Read-Only Properties from Get-TargetResource

* **[String] PipeName** _(Read)_: Named Pipes path from the Get-TargetResource method.

#### Examples

* [Add an SQL Server alias](/Examples/Resources/xSQLServerAlias/1-AddSQLServerAlias.ps1)
* [Remove an SQL Server alias](/Examples/Resources/xSQLServerAlias/2-RemoveSQLServerAlias.ps1)

### xSQLServerAlwaysOnAvailabilityGroup

This resource is used to create, remove, and update an Always On Availability Group. It will also manage the Availability Group replica on the specified node.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' must have the 'Connect SQL', 'Alter Any Availability Group', and 'View Server State' permissions.

#### Parameters

* **Name** _(Key)_: The name of the availability group.
* **SQLServer** _(Required)_: Hostname of the SQL Server to be configured.
* **SQLInstanceName** _(Key)_: Name of the SQL instance to be configued.
* **Ensure** _(Write)_: Specifies if the availability group should be present or absent. Default is Present. { *Present* | Absent }
* **AutomatedBackupPreference** _(Write)_: Specifies the automated backup preference for the availability group. Default is None. { Primary | SecondaryOnly | Secondary | *None* }
* **AvailabilityMode** _(Write)_: Specifies the replica availability mode. Default is 'AsynchronousCommit'. { *AsynchronousCommit* | SynchronousCommit }
* **BackupPriority** _(Write)_: Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are: integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup. Default is 50.
* **BasicAvailabilityGroup** _(Write)_: Specifies the type of availability group is Basic. This is only available is SQL Server 2016 and later and is ignored when applied to previous versions.
* **ConnectionModeInPrimaryRole** _(Write)_: Specifies how the availability replica handles connections when in the primary role. { AllowAllConnections | AllowReadWriteConnections }
* **ConnectionModeInSecondaryRole** _(Write)_: Specifies how the availability replica handles connections when in the secondary role. { AllowNoConnections | AllowReadIntentConnectionsOnly | AllowAllConnections }
* **EndpointHostName** _(Write)_: Specifies the hostname or IP address of the availability group replica endpoint. Default is the instance network name.
* **FailureConditionLevel** _(Write)_: Specifies the automatic failover behavior of the availability group. { OnServerDown | OnServerUnresponsive | OnCriticalServerErrors | OnModerateServerErrors | OnAnyQualifiedFailureCondition }
* **FailoverMode** _(Write)_: Specifies the failover mode. Default is 'Manual'. { Automatic | *Manual* }
* **HealthCheckTimeout** _(Write)_: Specifies the length of time, in milliseconds, after which AlwaysOn availability groups declare an unresponsive server to be unhealthy. Default is 30000.

#### Examples

* [Add a SQL Server Always On Availability Group](/Examples/Resources/xSQLServerAlwaysOnAvailabilityGroup/1-CreateAvailabilityGroup.ps1)
* [Remove a SQL Server Always On Availability Group](/Examples/Resources/xSQLServerAlwaysOnAvailabilityGroup/2-RemoveAvailabilityGroup.ps1)

### xSQLServerAlwaysOnService

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.

#### Parameters

* **[String] SQLServer** _(Key)_: The hostname of the SQL Server to be configured.
* **[String] SQLInstance** _(Key)_: Name of the SQL instance to be configured.
* **[String] Ensure** _(Required)_: An enumerated value that describes if SQL server should have AlwaysOn property present or absent. { Present | Absent }.
* **[Sint32] RestartTimeout** _(Write)_: The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.

#### Examples

None.

### xSQLServerAvailabilityGroupListener

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer PowerShell module.
* Requires that the Cluster name Object (CNO) has been delegated the right _Create Computer Object_ in the organizational unit (OU) in which the Cluster Name Object (CNO) resides.

#### Parameters

* **[String] InstanceName** _(Key)_: The SQL Server instance name of the primary replica.
* **[String] AvailabilityGroup** _(Key)_: The name of the availability group to which the availability group listener is or will be connected.
* **[String] NodeName** _(Write)_: The host name or FQDN of the primary replica.
* **[String] Ensure** _(Write)_: If the availability group listener should be present or absent. { Present | Absent }.
* **[String] Name** _(Write)_: The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).
* **[String[]] IpAddress** _(Write)_: The IP address used for the availability group listener, in the format 192.168.10.45/255.255.252.0. If using DCHP, set to the first IP-address of the DHCP subnet, in the format 192.168.8.1/255.255.252.0. Must be valid in the cluster-allowed IP range.
* **[Uint16] Port** _(Write)_: The port used for the availability group listener.
* **[Boolean] DHCP** _(Write)_: If DHCP should be used for the availability group listener instead of static IP address.

#### Examples

None.

### xSQLServerConfiguration

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] SQLServer** _(Key)_: The hostname of the SQL Server to be configured.
* **[String] SQLInstanceName** _(Key)_: Name of the SQL instance to be configured.
* **[String] OptionName** _(Key)_: The name of the SQL configuration option to be checked. For all possible values reference [MSDN](https://msdn.microsoft.com/en-us/library/ms189631.aspx) or run sp_configure.
* **[Sint32] OptionValue** _(Required)_: The desired value of the SQL configuration option.
* **[Boolean] RestartService** _(Write)_: Determines whether the instance should be restarted after updating the configuration option.
* **[Sint32] RestartTimeout** _(Write)_: The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.

#### Examples

None.

### xSQLServerDatabase

This resource is used to create or delete a database. For more information about database, please read:

* [Create a Database](https://msdn.microsoft.com/en-us/library/ms186312.aspx).
* [Delete a Database](https://msdn.microsoft.com/en-us/library/ms177419.aspx).

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] SQLServer** _(Key)_: The host name of the SQL Server to be configured.
* **[String] SQLInstance** _(Key)_: The name of the SQL instance to be configured.
* **[String] Name** _(Key)_: The name of database to be created or dropped.
* **[String] Ensure** _(Write)_: When set to 'Present', the database will be created. When set to 'Absent', the database will be dropped. { *Present* | Absent }.

#### Examples

* [Create a Database](/Examples/Resources/xSQLServerDatabase/1-CreateDatabase.ps1)
* [Delete a database](/Examples/Resources/xSQLServerDatabase/2-DeleteDatabase.ps1)

### xSQLServerDatabaseOwner

This resource is used to configure the owner of a database.
For more information about database owner, please read the article [Changing the Database Owner](https://technet.microsoft.com/en-us/library/ms190909.aspx).

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] Database** _(Key)_: The name of database to be configured.
* **[String] Name** _(Required)_: The name of the login that will become a owner of the desired sql database.
* **[String] SQLServer** _(Write)_: The host name of the SQL Server to be configured.
* **[String] SQLInstance** _(Write)_: The name of the SQL instance to be configured.

#### Examples

* [Set database owner](/Examples/Resources/xSQLServerDatabaseOwner/1-SetDatabaseOwner.ps1)

### xSQLServerDatabasePermission

This resource is used to grant, deny or revoke permissions for a user in a database.
For more information about permissions, please read the article [Permissions (Database Engine)](https://msdn.microsoft.com/en-us/library/ms191291.aspx).

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] Ensure** _(Write)_: If the permission should be granted (Present) or revoked (Absent). { Present | Absent }.
* **[String] Database** _(Key)_: The name of the database.
* **[String] Name** _(Key)_: The name of the user that should be granted or denied the permission.
* **[String[]] Permissions** _(Required)_: The permissions to be granted or denied for the user in the database. Valid permissions can be found in the article [SQL Server Permissions](https://msdn.microsoft.com/en-us/library/ms191291.aspx#Anchor_3).
* **[String] PermissionState** _(Key)_: The state of the permission. { Grant | Deny }.
* **[String] SQLServer** _(Key)_: The host name of the SQL Server to be configured. Default values is 'env:COMPUTERNAME'.
* **[String] SQLInstanceName** _(Key)_: The name of the SQL instance to be configured. Default value is 'MSSQLSERVER'.

#### Examples

* [Grant Database Permission](/Examples/Resources/xSQLServerDatabasePermission/1-GrantDatabasePermissions.ps1)
* [Revoke Database Permission](/Examples/Resources/xSQLServerDatabasePermission/2-RevokeDatabasePermissions.ps1)
* [Deny Database Permission](/Examples/Resources/xSQLServerDatabasePermission/3-DenyDatabasePermissions.ps1)

### xSQLServerDatabaseRecoveryModel

This resource set the recovery model for a database. The recovery model controls how transactions are logged, whether the transaction log requires (and allows) backing up, and what kinds of restore operations are available.
Three recovery models exist: full, simple, and bulk-logged.
Read more about recovery model in this article [View or Change the Recovery Model of a Database](https://msdn.microsoft.com/en-us/library/ms189272.aspx)

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] Name** _(Key)_: The SQL database name.
* **[String] SQLServer** _(Key)_: The host name of the SQL Server to be configured.
* **[String] SQLInstanceName** _(Key)_: The name of the SQL instance to be configured.
* **[String] RecoveryModel** _(Required)_: The recovery model to use for the database. { Full | Simple | BulkLogged }.

#### Examples

* [Set the RecoveryModel of a database](/Examples/Resources/xSQLServerDatabaseRecoveryModel/1-SetDatabaseRecoveryModel.ps1)

### xSQLServerDatabaseRole

This resource is used to add or remove role for a login in a database.
Read more about database role in this article [CREATE ROLE (Transact-SQL)](https://msdn.microsoft.com/en-us/library/ms187936.aspx)

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] Name** _(Key)_: The name of the login that will become a member, or removed as a member, of the role(s).
* **[String] SQLServer** _(Key)_: The host name of the SQL Server to be configured.
* **[String] SQLInstanceName** _(Key)_: The name of the SQL instance to be configured.
* **[String] Database** _(Key)_: The database in which the login (user) and role(s) exist.
* **[String] Ensure** _(Write)_: If 'Present' (the default value) then the login (user) will be added to the role(s). If 'Absent' then the login (user) will be removed from the role(s). { *Present* | Absent }.
* **[String[]] Role**_(Required): One or more roles to which the login (user) will be added or removed.

#### Examples

* [Add Role of a database](/Examples/Resources/xSQLServerDatabaseRole/1-AddDatabaseRole.ps1)
* [Remove Role of a database](/Examples/Resources/xSQLServerDatabaseRole/2-RemoveDatabaseRole.ps1)

### xSQLServerEndpoint

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Security Requirements

* The built-in parameter `PsDscRunAsCredential` must be set to the credentials of an account with the permission to enumerate logins, create the endpoint, and alter the permission on an endpoint.

#### Parameters

* **[String] EndPointName** _(Key)_: Name for endpoint to be created on SQL Server
* **[String] Ensure** _(Write)_: An enumerated value that describes if endpoint is to be present or absent on SQL Server. { Present | Absent }.
* **[Uint32] Port** _(Write)_: Port Endpoint should listen on
* **[String] AuthorizedUser** _(Write)_:  User who should have connect ability to endpoint
* **[String] SQLServer** _(Write)_: The SQL Server for the database
* **[String] SQLInstance** _(Write)_: The SQL instance for the database

#### Examples

None.

### xSQLServerEndpointPermission

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer PowerShell module.

#### Parameters

* **[String] InstanceName** _(Key)_: The SQL Server instance name.
* **[String] NodeName** _(Required)_: The host name or FQDN.
* **[String] Ensure** _(Write)_: If the permission should be present or absent. { Present | Absent }.
* **[String] Name** _(Required)_: The name of the endpoint.
* **[String] Principal** _(Key)_: The login to which permission will be set.
* **[String] Permission** _(Write)_: The permission to set for the login. Valid value for permission are only CONNECT. { Connect }.

#### Examples

None.

### xSQLServerEndpointState

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer PowerShell module.

#### Parameters

* **[String] InstanceName** _(Key)_: The SQL Server instance name.
* **[String] NodeName** _(Required)_: The host name or FQDN.
* **[String] Name** _(Required)_: The name of the endpoint.
* **[String] State** _(Write)_: The state of the endpoint. Valid states are Started, Stopped or Disabled. { Started | Stopped | Disabled }.

#### Examples

None.

### xSQLServerFailoverClusterSetup

**This resource is deprecated.** The functionality of this resource has been merged with [xSQLServerSetup](#xsqlserversetup). Please do not use this resource for new development efforts.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 R2 or later.

#### Parameters

* **[String] Action** _(Key)_: Prepare or Complete. { Prepare | Complete }.
* **[String] InstanceName** _(Key)_: SQL instance to be installed.
* **[String] Features** _(Required)_: SQL features to be installed.
* **[PSCredential] SetupCredential** _(Required)_: Credential to be used to perform the installation.
* **[String] FailoverClusterNetworkName** _(Required)_: Network name for the SQL Server failover cluster.
* **[PSCredential] SQLSvcAccount** _(Required)_: Service account for the SQL service.
* **[String] SourcePath** _(Write)_: UNC path to the root of the source files for installation.
* **[String] SourceFolder** _(Write)_: Folder within the source path containing the source files for installation.
* **[PSCredential] SourceCredential** _(Write)_: Credential to be used to access SourcePath
* **[Boolean] SuppressReboot** _(Write)_: Suppresses reboot
* **[Boolean] ForceReboot** _(Write)_: Forces Reboot
* **[String] InstanceID** _(Write)_: SQL instance ID, if different from InstanceName.
* **[String] PID** _(Write)_: Product key for licensed installations.
* **[String] UpdateEnabled** _(Write)_: Enabled updates during installation.
* **[String] UpdateSource** _(Write)_: Source of updates to be applied during installation.
* **[String] SQMReporting** _(Write)_: Enable customer experience reporting.
* **[String] ErrorReporting** _(Write)_: Enable error reporting.
* **[String] FailoverClusterGroup** _(Write)_: Name of the resource group to be used for the SQL Server failover cluster.
* **[String] FailoverClusterIPAddress** _(Write)_: IPv4 address for the SQL Server failover cluster.
* **[String] InstallSharedDir** _(Write)_: Installation path for shared SQL files.
* **[String] InstallSharedWOWDir** _(Write)_: Installation path for x86 shared SQL files.
* **[String] InstanceDir** _(Write)_: Installation path for SQL instance files.
* **[PSCredential] AgtSvcAccount** _(Write)_: Service account for the SQL Agent service.
* **[String] SQLCollation** _(Write)_: Collation for SQL.
* **[String[]] SQLSysAdminAccounts** _(Write)_: Array of accounts to be made SQL administrators.
* **[String] SecurityMode** _(Write)_: SQL security mode.
* **[PSCredential] SAPwd** _(Write)_: SA password, if SecurityMode=SQL.
* **[String] InstallSQLDataDir** _(Write)_: Root path for SQL database files.
* **[String] SQLUserDBDir** _(Write)_: Path for SQL database files.
* **[String] SQLUserDBLogDir** _(Write)_: Path for SQL log files.
* **[String] SQLTempDBDir** _(Write)_: Path for SQL TempDB files.
* **[String] SQLTempDBLogDir** _(Write)_: Path for SQL TempDB log files.
* **[String] SQLBackupDir** _(Write)_: Path for SQL backup files.
* **[PSCredential] ASSvcAccount** _(Write)_: Service account for Analysis Services service.
* **[String] ASCollation** _(Write)_: Collation for Analysis Services.
* **[String[]] ASSysAdminAccounts** _(Write)_: Array of accounts to be made Analysis Services admins.
* **[String] ASDataDir** _(Write)_: Path for Analysis Services data files.
* **[String] ASLogDir** _(Write)_: Path for Analysis Services log files.
* **[String] ASBackupDir** _(Write)_: Path for Analysis Services backup files.
* **[String] ASTempDir** _(Write)_: Path for Analysis Services temp files.
* **[String] ASConfigDir** _(Write)_: Path for Analysis Services config.
* **[PSCredential] ISSvcAccount** _(Write)_: Service account for Integration Services service.
* **[String] ISFileSystemFolder** _(Write)_: File system folder for Integration Services.

#### Read-Only Properties from Get-TargetResource

* **[String] SQLSvcAccountUsername** _(Read)_: Output user name for the SQL service.
* **[String] AgtSvcAccountUsername** _(Read)_: Output user name for the SQL Agent service.
* **[String] ASSvcAccountUsername** _(Read)_: Output user name for the Analysis Services service.
* **[String] ISSvcAccountUsername** _(Read)_: Output user name for the Integration Services service.

#### Examples

None.

### xSQLServerFirewall

This will set default firewall rules for the supported features. Currently the features supported are Database Engine,
Analysis Services, SQL Browser, SQL Reporting Services and Integration Services.

#### Firewall rules

##### Default rules for default instance

| Feature | Component | Enable Firewall Rule | Firewall Name |
| --- | --- | --- | --- |
| SQLENGINE | Database Engine | Application: sqlservr.exe | SQL Server Database Engine instance MSSQLSERVER |
| SQLENGINE | Database Engine | Service: SQLBrowser | SQL Server Browser |
| AS | Analysis Services | Service: MSSQLServerOLAPService | SQL Server Analysis Services instance MSSQLSERVER |
| AS | Analysis Services | Service: SQLBrowser | SQL Server Browser |
| RS | Reporting Services | Port: tcp/80 | SQL Server Reporting Services 80 |
| RS | Reporting Services | Port: tcp/443 | SQL Server Reporting Services 443 |
| IS | Integration Services | Application: MsDtsSrvr.exe | SQL Server Integration Services Application |
| IS | Integration Services | Port: tcp/135 | SQL Server Integration Services Port |

##### Default rules for named instance

| Feature | Component | Enable Firewall Rule | Firewall Name |
| --- | --- | --- | --- |
| SQLENGINE | Database Engine | Application: sqlservr.exe | SQL Server Database Engine instance \<NAMED_INSTANCE\> |
| SQLENGINE | Database Engine | Service: SQLBrowser | SQL Server Browser |
| AS | Analysis Services | Service: MSOLAP$INSTANCE | | SQL Server Analysis Services instance \<NAMED_INSTANCE\> |
| AS | Analysis Services | Service: SQLBrowser | SQL Server Browser |
| RS | Reporting Services | Port: tcp/80 | SQL Server Reporting Services 80 |
| RS | Reporting Services | Port: tcp/443 | SQL Server Reporting Services 443 |
| IS | Integration Services | Application: MsDtsSrvr.exe | SQL Server Integration Services Application |
| IS | Integration Services | Port: tcp/135 | SQL Server Integration Services Port |

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **[String] Features** _(Key)_: SQL features to enable firewall rules for.
* **[String] InstanceName** _(Key)_: SQL instance to enable firewall rules for.
* **[String] Ensure** _(Write)_: Ensures that SQL firewall rules are **Present** or **Absent** on the machine. { *Present* | Absent }.
* **[String] SourcePath** _(Write)_: UNC path to the root of the source files for installation.
* **[String] SourceCredential** _(Write)_: Credentials used to access the path set in the parameter 'SourcePath'. This parmeter is optional either if built-in parameter 'PsDscRunAsCredential' is used, or if the source path can be access using the SYSTEM account.

#### Read-Only Properties from Get-TargetResource

* **[Boolean] DatabaseEngineFirewall** _(Read)_: Is the firewall rule for the Database Engine enabled?
* **[Boolean] BrowserFirewall** _(Read)_: Is the firewall rule for the Browser enabled?
* **[Boolean] ReportingServicesFirewall** _(Read)_: Is the firewall rule for Reporting Services enabled?
* **[Boolean] AnalysisServicesFirewall** _(Read)_: Is the firewall rule for Analysis Services enabled?
* **[Boolean] IntegrationServicesFirewall** _(Read)_: Is the firewall rule for the Integration Services enabled?

#### Examples

* [Create inbound firewall rules](/Examples/Resources/xSQLServerFirewall/1-CreateInboundFirewallRules.ps1)
* [Remove inbound firewall rules](/Examples/Resources/xSQLServerFirewall/2-RemoveInboundFirewallRules.ps1)

### xSQLServerLogin

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] SQLServer** _(Key)_:The hostname of the SQL Server to be configured.
* **[String] SQLInstanceName** _(Key)_: Name of the SQL instance to be configured.
* **[String] Name** _(Key)_: The name of the login.
* **[String] Ensure** _(Write)_: The specified login is Present or Absent. { *Present* | Absent }.
* **[PSCredential] LoginCredential** _(Write)_: If LoginType is 'SqlLogin' then a PSCredential is needed for the password to the login.
* **[String] LoginType** _(Write)_: The type of login to be created. If LoginType is 'WindowsUser' or 'WindowsGroup' then provide the name in the format DOMAIN\name. Default is WindowsUser. Unsupported login types are Certificate, AsymmetricKey, ExternalUser, and ExternalGroup. {SqlLogin | WindowsUser | WindowsGroup }
* **[Boolean] LoginMustChangePassword** _(Write)_: Specifies if the login is required to have its password change on the next login. Only applies to SQL Logins. Default is $true.
* **[Boolean] LoginPasswordExpirationEnabled** _(Write)_: Specifies if the login password is required to expire in accordance to the operating system security policy. Only applies to SQL Logins. Default is $true.
* **[Boolean] LoginPasswordPolicyEnforced** _(Write)_: Specifies if the login password is required to conform to the password policy specified in the system security policy. Only applies to SQL Logins. Default is $true.

#### Examples

None.

### xSQLServerMaxDop

This resource set the max degree of parallelism server configuration option.
The max degree of parallelism option is used to limit the number of processors to use in parallel plan execution.
Read more about max degree of parallelism in this article [Configure the max degree of parallelism Server Configuration Option](https://msdn.microsoft.com/en-us/library/ms189094.aspx)

#### Formula for dynamically allocating max degree of parallelism

* If the number of configured NUMA nodes configured in SQL Server equals 1, then max degree of parallelism is calculated using number of cores divided in 2 (numberOfCores / 2), then rounded up to the next integer (3.5 > 4).
* If the number of cores configured in SQL Server are greater than or equal to 8 cores then max degree of parallelism will be set to 8.
* If the number of configured NUMA nodes configured in SQL Server is greater than 2 and thenumber of cores are less than 8 then max degree of parallelism will be set to the number of cores.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] SQLInstance** (Key): The name of the SQL instance to be configured.
* **[String] SQLServer** _(Write)_: The host name of the SQL Server to be configured. Default value is *env:COMPUTERNAME*.
* **[String] Ensure** _(Write)_: When set to 'Present' then max degree of parallelism will be set to either the value in parameter MaxDop or dynamically configured when parameter DynamicAlloc is set to $true. When set to 'Absent' max degree of parallelism will be set to 0 which means no limit in number of processors used in parallel plan execution. { *Present* | Absent }.
* **[Boolean] DynamicAlloc** _(Write)_: If set to $true then max degree of parallelism will be dynamically configured. When this is set parameter is set to $true, the parameter MaxDop must be set to $null or not be configured.
* **[Sint32] MaxDop** _(Write)_: A numeric value to limit the number of processors used in parallel plan execution.

#### Examples

* [Set SQLServerMaxDop to 1](/Examples/Resources/xSQLServerMaxDop/1-SetMaxDopToOne.ps1)
* [Set SQLServerMaxDop to Auto](/Examples/Resources/xSQLServerMaxDop/2-SetMaxDopToAuto.ps1)
* [Set SQLServerMaxDop to Default](/Examples/Resources/xSQLServerMaxDop/3-SetMaxDopToDefault.ps1)

### xSQLServerMemory

This resource sets the minimum server memory and maximum server memory configuration option.
That means it sets the minimum and the maximum amount of memory, in MB, in the buffer pool used by the instance of SQL Server
The default setting for minimum server memory is 0, and the default setting for maximum server memory is 2147483647 MB.
Read more about minimum server memory and maximum server memory in this article [Server Memory Server Configuration Options](https://msdn.microsoft.com/en-us/library/ms178067.aspx).

#### Formula for dynamically allocating maximum memory

The formula is based on the [SQL Max Memory Calculator](http://sqlmax.chuvash.eu/) website. The website code is in the sql-max GitHub repository maintained by [@mirontoli](https://github.com/mirontoli).
The dynamic maximum memory (in MB) is calculate with this formula:
SQL Max Memory = TotalPhysicalMemory - (NumOfSQLThreads\*ThreadStackSize) - (1024\*CEILING(NumOfCores/4)) - OSReservedMemory.

* **NumOfSQLThreads**
  * If the number of cores is less than or equal to 4, the number of SQL threads is set to: 256 + (NumberOfCores - 4) \* 8.
  * If the number of cores is greater than 4, the number of SQL threads is set to: 0 (zero).
* **ThreadStackSize**
  * If the architecture of windows server is x86, the size of thread stack is 1MB.
  * If the architecture of windows server is x64, the size of thread stack is 2MB.
  * If the architecture of windows server is IA64, the size of thread stack is 4MB.
* **OSReservedMemory**
  * If the total physical memory is less than or equal to 20GB, the percentage of reserved memory for OS is 20% of total physical memory.
  * If the total physical memory is greater than 20GB, the percentage of reserved memory for OS is 12.5% of total physical memory.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] SQLInstance** _(Key)_: The name of the SQL instance to be configured.
* **[String] SQLServer** _(Write)_: The host name of the SQL Server to be configured. Default value is *$env:COMPUTERNAME*.
* **[Boolean] DyamicAlloc** _(Write)_: If set to $true then max memory will be dynamically configured. When this is set parameter is set to $true, the parameter MaxMemory must be set to $null or not be configured. Default value is *$false*.
* **[String] Ensure** _(Write)_: When set to 'Present' then min and max memory will be set to either the value in parameter MinMemory and MaxMemory or dynamically configured when parameter DynamicAlloc is set to $true. When set to 'Absent' min and max memory will be set to default values. { *Present* | Absent }.
* **[Sint32] MinMemory** _(Write)_: Minimum amount of memory, in MB, in the buffer pool used by the instance of SQL Server.
* **[Sint32] MaxMemory** _(Write)_: Maximum amount of memory, in MB, in the buffer pool used by the instance of SQL Server.

#### Examples

* [Set SQLServerMaxMemory to 12GB](/Examples/Resources/xSQLServerMemory/1-SetMaxMemoryTo12GB.ps1)
* [Set SQLServerMaxMemory to Auto](/Examples/Resources/xSQLServerMemory/2-SetMaxMemoryToAuto.ps1)
* [Set SQLServerMinMemory to 2GB and SQLServerMaxMemory to Auto](/Examples/Resources/xSQLServerMemory/3-SetMinMemoryToFixedValueAndMaxMemoryToAuto.ps1)
* [Set SQLServerMaxMemory to Default](/Examples/Resources/xSQLServerMemory/3-SetMaxMemoryToDefault.ps1)

### xSQLServerNetwork

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] InstanceName** _(Key)_: name of SQL Server instance for which network will be configured.
* **[String] ProtocolName** _(Required)_: Name of network protocol to be configured. Only tcp is currently supported. { tcp }.
* **[Boolean] IsEnabled** _(Write)_: Enables/Disables network protocol.
* **[String] TCPDynamicPorts** _(Write)_: 0 if Dynamic ports should be used otherwise empty. { 0 }.
* **[String] TCPPort** _(Write)_: Custom TCP port.
* **[Boolean] RestartService** _(Write)_: If true will restart SQL Service instance service after update. Default false.

#### Examples

None.

### xSQLServerPermission

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer PowerShell module.

#### Parameters

* **[String] InstanceName** _(Key)_: The SQL Server instance name.
* **[String] NodeName** _(Required)_: The host name or FQDN.
* **[String] Principal** _(Required)_: The login to which permission will be set.
* **[String] Ensure** _(Write)_: If the permission should be present or absent. { Present | Absent }.
* **[String[]] Permission** _(Write)_: The permission to set for the login. Valid values are AlterAnyAvailabilityGroup, ViewServerState or AlterAnyEndPoint. { AlterAnyAvailabilityGroup | AlterAnyEndPoint | ViewServerState }.

#### Examples

None.

### xSQLServerReplication

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server 2008 or later.

#### Parameters

* **[String] InstanceName** _(Key)_: SQL Server instance name where replication distribution will be configured.
* **[String] Ensure** _(Write)_: (Default = 'Present') 'Present' will configure replication, 'Absent' will disable replication.
* **[String] DistributorMode** _(Required)_: 'Local' - Instance will be configured as it's own distributor, 'Remote' - Instace will be configure with remote distributor (remote distributor needs to be already configured for distribution).
* **[PSCredentials] AdminLinkCredentials** _(Required)_: - AdminLink password to be used when setting up publisher distributor relationship.
* **[String] DistributionDBName** _(Write)_: (Default = 'distribution') distribution database name. If DistributionMode='Local' this will be created, if 'Remote' needs to match distribution database on remote distributor.
* **[String] RemoteDistributor** _(Write)_: (Required if DistributionMode='Remote') SQL Server network name that will be used as distributor for local instance.
* **[String] WorkingDirectory** _(Required)_: Publisher working directory.
* **[Boolean] UseTrustedConnection** _(Write)_: (Default = $true) Publisher security mode.
* **[Boolean] UninstallWithForce** _(Write)_: (Default = $true) Force flag for uninstall procedure

#### Examples

None.

### xSQLServerRole

This resource is used to create or delete a server role and manage members of this role. For more information about server role, please read:

* [Create a Server Role](https://msdn.microsoft.com/en-us/library/ee677627.aspx)
* [Server-Level Roles](https://msdn.microsoft.com/en-us/library/ms188659.aspx)

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2008 or later.

#### Parameters

* **[String] Ensure** _(Write)_: An enumerated value that describes if the server role is added (Present) or dropped (Absent). { *Present* | Absent }.
* **[String[]] Members** _(Write)_: The members the server role should have.
* **[String[]] MembersToInclude** _(Write)_: The members the server role should include.
* **[String[]] MembersToExclude** _(Write)_: The members the server role should exclude.
* **[String] ServerRole** _(Key)_: The name of of SQL role to add or remove.
* **[String] SQLServer** _(Key)_: The host name of the SQL Server to be configured.
* **[String] SQLInstanceName** _(Key)_: The name of the SQL instance to be configured.

#### Examples

* [Add server role](/Examples/Resources/xSQLServerRole/1-AddServerRole.ps1)
* [Remove server role](/Examples/Resources/xSQLServerRole/2-RemoveServerRole.ps1)
* [Add members to server role](/Examples/Resources/xSQLServerRole/3-AddMembersToServerRole.ps1)
* [Members to include in server role](/Examples/Resources/xSQLServerRole/4-MembersToIncludeInServerRole.ps1)
* [Members to exclude from server role](/Examples/Resources/xSQLServerRole/5-MembersToExcludeInServerRole.ps1)

### xSQLServerRSConfig

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Reporting Services 2008 or later.

#### Parameters

* **[String] InstanceName** _(Key)_: Name of the SQL Server Reporting Services instance to be configured.
* **[String] RSSQLServer** _(Required)_: Name of the SQL Server to host the Reporting Service database.
* **[String] RSSQLInstanceName** _(Required)_: Name of the SQL Server instance to host the Reporting Service database.
* **[PSCredential] SQLAdminCredential** _(Required)_: Credential to be used to perform the configuration.

#### Read-Only Properties from Get-TargetResource

* **[Read] IsInitialized** _(Read)_: Output is the Reporting Services instance initialized.

#### Examples

None.

### xSQLServerRSSecureConnectionLevel

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Reporting Services 2008 or later.

#### Parameters

* **[String] InstanceName** _(Key)_: SQL instance to set secure connection level for.
* **[Uint16] SecureConnectionLevel** _(Key)_: SQL Server Reporting Service secure connection level.
* **[PSCredential] SQLAdminCredential** _(Required)_: Credential with administrative permissions to the SQL instance.

#### Examples

None.

### xSQLServerScript

Provides the means to run a user generated T-SQL script on the SQL Server instance. Three scripts are required; Get T-SQL script, Set T-SQL script and the Test T-SQL script.

| T-SQL Script | Description |
| ---  | --- |
| Get  | The Get T-SQL script is used to query the status when running the cmdlet Get-DscConfiguration, and the result can be found in the property `GetResult`. |
| Test | The Test T-SQL script is used to test if the desired state is met. If Test T-SQL raises an error or returns any value other than 'null' the test fails, thus the Set T-SQL script is run. |
| Set  | The Set T-SQL script performs the actual change when Test T-SQL script fails. |

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server 2008 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer PowerShell module.

_Note: There is a known problem running this resource using PowerShell 4.0. See [issue #273](https://github.com/PowerShell/xSQLServer/issues/273) for more information._

#### Parameters

* **[String] ServerInstance** _(Key)_: The name of an instance of the Database Engine. For a default instance, only specify the computer name. For a named instances, use the format ComputerName\\InstanceName.
* **[String] SetFilePath** _(Key)_: Path to the T-SQL file that will perform Set action.
* **[String] GetFilePath** _(Key)_: Path to the T-SQL file that will perform Get action. Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.
* **[String] TestFilePath** _(Key)_: Path to the T-SQL file that will perform Test action. Any script that does not throw an error or returns null is evaluated to true. The cmdlet Invoke-SqlCmd treats T-SQL Print statements as verbose text, and will not cause the test to return false.
* **[PSCredential] Credential** _(Write)_: The credentials to authenticate with, using SQL Authentication. To authenticate using Windows Authentication, assign the credentials to the built-in parameter `PsDscRunAsCredential`. If both parameters `Credential` and `PsDscRunAsCredential` are not assigned, then SYSTEM account will be used to authenticate using Windows Authentication.
* **[String[]] Variable** _(Write)_: Specifies, as a string array, a sqlcmd scripting variable for use in the sqlcmd script, and sets a value for the variable. Use a Windows PowerShell array to specify multiple variables and their values. For more information how to use this, please go to the help documentation for [Invoke-Sqlcmd](https://technet.microsoft.com/en-us/library/mt683370.aspx).

#### Read-Only Properties from Get-TargetResource

* **GetResult** _(Read)_: Contains the values returned from the T-SQL script provided in the parameter `GetFilePath` when cmdlet Get-DscConfiguration is run.

#### Examples

* [Run a script using SQL Authentication](/Examples/Resources/xSQLServerScript/1-RunScriptUsingSQLAuthentication.ps1)
* [Run a script using Windows Authentication](/Examples/Resources/xSQLServerScript/2-RunScriptUsingWindowsAuthentication.ps1)

### xSQLServerSetup

Installs SQL Server on the target node.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* For configurations that utilize the 'InstallFailoverCluster' action, the following parameters are required (beyond those required for the standalone installation). See the article [Install SQL Server from the Command Prompt](https://msdn.microsoft.com/en-us/library/ms144259.aspx) under the section [Failover Cluster Parameters](https://msdn.microsoft.com/en-us/library/ms144259.aspx#Anchor_8) for more information.
  * InstanceName (can be MSSQLSERVER if you want to install a default clustered instance).
  * FailoverClusterNetworkName
  * FailoverClusterIPAddress
  * _When installing Database Engine._
    * InstallSQLDataDir
    * AgtSvcAccount
    * SQLSvcAccount
    * SQLSysAdminAccounts
  * _When installing Analysis Services._
    * ASSysAdminAccounts
    * AsSvcAccount

#### Parameters

* **[String] Action** _(Write)_: The action to be performed. Defaults to 'Install'. *Note: AddNode is not currently functional.* { _Install_ | InstallFailoverCluster | AddNode | PrepareFailoverCluster | CompleteFailoverCluster }
* **[String] InstanceName** _(Key)_: SQL instance to be installed.
* **[PSCredential] SetupCredential** _(Required)_: Credential to be used to perform the installation.
* **[String] SourcePath** _(Write)_: The path to the root of the source files for installation. I.e and UNC path to a shared resource. Environment variables can be used in the path.
* **[PSCredential] SourceCredential** _(Write)_: Credentials used to access the path set in the parameter `SourcePath`. Using this parameter will trigger a copy of the installation media to a temp folder on the target node. Setup will then be started from the temp folder on the target node. For any subsequent calls to the resource, the parameter `SourceCredential` is used to evaluate what major version the file 'setup.exe' has in the path set, again, by the parameter `SourcePath`. To know how the temp folder is evaluated please read the online documentation for [System.IO.Path.GetTempPath()](https://msdn.microsoft.com/en-us/library/system.io.path.gettemppath(v=vs.110).aspx). If the path, that is assigned to parameter `SourcePath`, contains a leaf folder, for example '\\server\share\folder', then that leaf folder will be used as the name of the temporary folder. If the path, that is assigned to parameter `SourcePath`, does not have a leaf folder, for example '\\server\share', then a unique guid will be used as the name of the temporary folder.
* **[Boolean] SuppressReboot** _(Write)_: Suppresses reboot.
* **[Boolean] ForceReboot** _(Write)_: Forces reboot.
* **[String] Features** _(Write)_: SQL features to be installed.
* **[String] InstanceID** _(Write)_: SQL instance ID, if different from InstanceName.
* **[String] ProductKey** _(Write)_: Product key for licensed installations.
* **[String] UpdateEnabled** _(Write)_: Enabled updates during installation.
* **[String] UpdateSource** _(Write)_: Path to the source of updates to be applied during installation.
* **[String] SQMReporting** _(Write)_: Enable customer experience reporting.
* **[String] ErrorReporting** _(Write)_: Enable error reporting.
* **[String] InstallSharedDir** _(Write)_: Installation path for shared SQL files.
* **[String] InstallSharedWOWDir** _(Write)_: Installation path for x86 shared SQL files.
* **[String] InstanceDir** _(Write)_: Installation path for SQL instance files.
* **[PSCredential] SQLSvcAccount** _(Write)_: Service account for the SQL service.
* **[PSCredential] AgtSvcAccount** _(Write)_: Service account for the SQL Agent service.
* **[String] SQLCollation** _(Write)_: Collation for SQL.
* **[String[]] SQLSysAdminAccounts** _(Write)_: Array of accounts to be made SQL administrators.
* **[String] SecurityMode** _(Write)_: Security mode to apply to the SQL Server instance.
* **[PSCredential] SAPwd** _(Write)_: SA password, if SecurityMode is set to 'SQL'.
* **[String] InstallSQLDataDir** _(Write)_: Root path for SQL database files.
* **[String] SQLUserDBDir** _(Write)_: Path for SQL database files.
* **[String] SQLUserDBLogDir** _(Write)_: Path for SQL log files.
* **[String] SQLTempDBDir** _(Write)_: Path for SQL TempDB files.
* **[String] SQLTempDBLogDir** _(Write)_: Path for SQL TempDB log files.
* **[String] SQLBackupDir** _(Write)_: Path for SQL backup files.
* **[PSCredential] FTSvcAccount** _(Write)_: Service account for the Full Text service.
* **[PSCredential] RSSvcAccount** _(Write)_: Service account for Reporting Services service.
* **[PSCredential] ASSvcAccount** _(Write)_: Service account for Analysis Services service.
* **[String] ASCollation** _(Write)_: Collation for Analysis Services.
* **[String[]] ASSysAdminAccounts** _(Write)_: Array of accounts to be made Analysis Services admins.
* **[String] ASDataDir** _(Write)_: Path for Analysis Services data files.
* **[String] ASLogDir** _(Write)_: Path for Analysis Services log files.
* **[String] ASBackupDir** _(Write)_: Path for Analysis Services backup files.
* **[String] ASTempDir** _(Write)_: Path for Analysis Services temp files.
* **[String] ASConfigDir** _(Write)_: Path for Analysis Services config.
* **[PSCredential] ISSvcAccount** _(Write)_: Service account for Integration Services service.
* **[String] BrowserSvcStartupType** _(Write)_: Specifies the startup mode for SQL Server Browser service. { Automatic | Disabled | 'Manual' }
* **[String] FailoverClusterGroupName** _(Write)_: The name of the resource group to create for the clustered SQL Server instance. Default is 'SQL Server (_InstanceName_)'.
* **[String[]]FailoverClusterIPAddress** _(Write)_: Array of IP Addresses to be assigned to the clustered SQL Server instance. IP addresses must be in [dotted-decimal notation](https://en.wikipedia.org/wiki/Dot-decimal_notation), for example ````10.0.0.100````. If no IP address is specified, uses 'DEFAULT' for this setup parameter.
* **[String] FailoverClusterNetworkName** _(Write)_: Host name to be assigned to the clustered SQL Server instance.

#### Read-Only Properties from Get-TargetResource

* **SQLSvcAccountUsername** _(Read)_: Output user name for the SQL service.
* **AgtSvcAccountUsername** _(Read)_: Output user name for the SQL Agent service.
* **FTSvcAccountUsername** _(Read)_: Output username for the Full Text service.
* **RSSvcAccountUsername** _(Read)_: Output username for the Reporting Services service.
* **ASSvcAccountUsername** _(Read)_: Output username for the Analysis Services service.
* **ISSvcAccountUsername** _(Read)_: Output user name for the Integration Services service.

#### Examples

None.

### xWaitforAvailabilityGroup

No description.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.

#### Parameters

* **[String] Name** _(Key)_: Name for availability group
* **[Uint64] RetryIntervalSec** _(Write)_: Interval to check for availability group
* **[Uint32] RetryCount** _(Write)_: Maximum number of retries to check availability group creation

#### Read-Only Properties from Get-TargetResource

None.

#### Examples

None.
