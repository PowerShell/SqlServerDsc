# xSQLServer

[![Build status](https://ci.appveyor.com/api/projects/status/mxn453y284eab8li/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xsqlserver/branch/master)

The **xSQLServer** module contains DSC resources for deployment and configuration of SQL Server.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing

Regardless of the way you want to contribute we are tremendously happy to have you here.

There are several ways you can contribute. You can submit an issue to report a bug. You can submit an issue to request an improvment. You can take part in discussions for issues. You can review pull requests and comment on other contributors changes.
You can also improve the resources and tests, or even create new resources, by sending in pull requests yourself.

* If you want to submit an issue or take part in discussions, please browse the list of [issues](https://github.com/PowerShell/xSQLServer/issues). Please check out [Contributing to the DSC Resource Kit](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md) on how to work with issues.
* If you want to review pull requests, please first check out the [Review Pull Request guidelines](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md#reviewing-pull-requests), and the browse the list of [pull requests](https://github.com/PowerShell/xSQLServer/pulls) and look for those pull requests with label 'needs review'.
* If you want to improve the resources or tests, or create a new resource, then please check out the follwing guidelines.
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

The minimum PowerShell version required is 4.0, which ships in Windows 8.1 or Windows Server 2012 R2 (or higher versions). But PowerShell 4.0 can also be installed on Windows Server 2008 R2.
The preferred version is PowerShell 5.0 or higher, which ships with Windows 10 or Windows Server 2016.

## Examples

You can review the [Examples](/Examples) directory in the xSQLServer module for some general use scenarios for all of the resources that are in the module.

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

* [**xSQLAOGroupEnsure**](#xsqlaogroupensure) resource to ensure availability group is present or absent
* [**xSQLAOGroupJoin**](#xsqlaogroupjoin) resource to join a replica to an existing availability group
* [**xSQLDatabaseRecoveryModel**](#xsqldatabaserecoverymodel) resource to manage database recovery model
* [**xSQLServerAlias**](#xsqlserveralias) resource to manage SQL Server client Aliases
* [**xSQLServerAlwaysOnService**](#xsqlserveralwaysonservice) resource to enable always on on a SQL Server
* [**xSQLServerAvailabilityGroupListener**](#xsqlserveravailabilitygrouplistener) Create or remove an availability group listener.
* [**xSQLServerConfiguration**](#xsqlserverconfiguration) resource to manage [SQL Server Configuration Options](https://msdn.microsoft.com/en-us/library/ms189631.aspx)
* [**xSQLServerDatabase**](#xsqlserverdatabase) resource to manage ensure database is present or absent
* [**xSQLServerDatabaseRole**](#xsqlserverdatabaserole) resource to manage SQL database roles
* [**xSQLServerDatabaseOwner**](#xsqlserverdatabaseowner) resource to manage SQL database owners
* [**xSQLServerDatabasePermissions**](#xsqlserverdatabasepermissions) resource to manage SQL database permissions
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

* **Ensure**: (Key) Determines whether the availability group should be added or removed.
* **AvailabilityGroupName** (Key) Name for availability group.
* **AvailabilityGroupNameListener** Listener name for availability group.
* **AvailabilityGroupNameIP** List of IP addresses associated with listener.
* **AvailabilityGroupSubMask** Network subnetmask for listener.
* **AvailabilityGroupPort** Port availability group should listen on.
* **ReadableSecondary** Mode secondaries should operate under (None, ReadOnly, ReadIntent).
* **AutoBackupPreference** Where backups should be backed up from (Primary, Secondary).
* **BackupPriority** The percentage weight for backup prority (default 50).
* **EndPointPort** The TCP port for the SQL AG Endpoint (default 5022).
* **SQLServer**: The SQL Server for the database.
* **SQLInstance**: The SQL instance for the database.
* **SetupCredential**: (Required) Credential to be used to Grant Permissions on SQL Server, set this to $null to use Windows Authentication.

### xSQLAOGroupJoin

* **Ensure**: (key) If the replica should be joined ('Present') to the Availability Group or not joined ('Absent') to the Availability Group.
* **AvailabilityGroupName** (key) The name Availability Group to join.
* **SQLServer**: Name of the SQL server to be configured.
* **SQLInstanceName**: Name of the SQL instance to be configured.
* **SetupCredential**: (Required) Credential to be used to Grant Permissions in SQL.

### xSQLDatabaseRecoveryModel

* **DatabaseName**: (key) The SQL database name
* **SQLServerInstance**: (Required) The SQL server and instance
* **RecoveryModel**: (Required) Recovery Model (Full, Simple, BulkLogged)

### xSQLServerAlias

* **Ensure**: Determines whether the alias should be added or removed. Default value is 'Present'
* **Name**: (Key) The name of Alias (e.g. svr01\inst01).
* **ServerName**: (Key) The SQL Server you are aliasing (the netbios name or FQDN).
* **Protocol**: Protocol to use when connecting. Valid values are 'TCP' or 'NP' (Named Pipes). Default value is 'TCP'.
* **TCPPort**: The TCP port SQL is listening on. Only used when protocol is set to 'TCP'. Default value is port 1433.
* **UseDynamicTcpPort**: The UseDynamicTcpPort specify that the Net-Library will determine the port dynamically. The port specified in Port number will not be used. Default value is '$false'.
* **PipeName**: (Read) Named Pipes path from the Get-TargetResource method.

### xSQLServerAlwaysOnService

* **Ensure**: (Required) An enumerated value that describes if SQL server should have AlwaysOn property present or absent.
* **SQLServer**: (Key) The hostname of the SQL Server to be configured.
* **SQLInstance**: (Key) Name of the SQL instance to be configured.
* **RestartTimeout**: The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.

### xSQLServerAvailabilityGroupListener

*This resource requires that the CNO has been delegated the right `Create computer object` on the organizational unit (OU) in which the CNO resides.*

* **InstanceName** The SQL Server instance name of the primary replica.
* **NodeName** The host name or FQDN of the primary replica.
* **Ensure** If the availability group listener should be present or absent.
* **Name** The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).
* **AvailabilityGroup** The name of the availability group to which the availability group listener is or will be connected.
* **IpAddress** The IP address used for the availability group listener, in the format 192.168.10.45/255.255.252.0. If using DCHP, set to the first IP-address of the DHCP subnet, in the format 192.168.8.1/255.255.252.0. Must be valid in the cluster-allowed IP range.
* **Port** The port used for the availability group listener.
* **DHCP** If DHCP should be used for the availability group listener instead of static IP address.

### xSQLServerConfiguration

* **SQLServer**: (Key) The hostname of the SQL Server to be configured
* **SQLInstanceName**: (Write) Name of the SQL instance to be configured. Default is 'MSSQLSERVER'
* **OptionName**: (Key) The name of the SQL configuration option to be checked. For all possible values reference [MSDN](https://msdn.microsoft.com/en-us/library/ms189631.aspx) or run sp_configure.
* **OptionValue**: (Required) The desired value of the SQL configuration option
* **RestartService**: Determines whether the instance should be restarted after updating the configuration option
* **RestartTimeout**: The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.

### xSQLServerDatabase

* **Database**: (key) Database to be created or dropped
* **Ensure**: (Default = 'Present') An enumerated value that describes if Database is to be present or absent.
* **SQLServer**: (key) The SQL Server for the database
* **SQLInstance**: (key) The SQL instance for the database

### xSQLServerDatabaseRole

* **Ensure**: If 'Present' (the default value) then the login (user) will be added to the role(s). If 'Absent' then the login (user) will be removed from the role(s).
* **Name**: (Key) The name of the login that will become a member, or removed as a member, of the role(s).
* **SQLServer**: (Key) The SQL server on which the instance exist.
* **SQLInstanceName**: (Key) The SQL instance in which the database exist.
* **Database**: (Key) The database in which the login (user) and role(s) exist.
* **Role**: One or more roles to which the login (user) will be added or removed.

### xSQLServerDatabaseOwner

* **Database**: (Key) The SQL Database
* **Name**: (Required) The name of the SQL login for the owner
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database

### xSQLServerDatabasePermissions

* **Database**: (Key) The SQL Database
* **Name**: (Required) The name of permissions for the SQL database
* **Permissions**: (Required) The set of Permissions for the SQL database
* **SQLServer**: The SQL Server for the database
* **SQLInstanceName**: The SQL instance for the database

### xSQLServerEndpoint

* **EndPointName**: Name for endpoint to be created on SQL Server
* **Ensure**: (key) An enumerated value that describes if endpoint is to be present or absent on SQL Server
* **Port**: Port Endpoint should listen on
* **AuthorizedUser**:  User who should have connect ability to endpoint
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database

### xSQLServerEndpointPermission

* **InstanceName** The SQL Server instance name.
* **NodeName** The host name or FQDN.
* **Ensure** If the permission should be present or absent.
* **Name** The name of the endpoint.
* **Principal** The login to which permission will be set.
* **Permission** The permission to set for the login. Valid value for permission are only CONNECT.

### xSQLServerEndpointState

* **InstanceName** The SQL Server instance name.
* **NodeName** The host name or FQDN.
* **Name** The name of the endpoint.
* **State** The state of the endpoint. Valid states are Started, Stopped or Disabled.

### xSQLServerFailoverClusterSetup

* **Action**: (Key) { Prepare | Complete }
* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **SetupCredential**: (Required) Credential to be used to perform the installation.
* **SourceCredential**: Credential to be used to access SourcePath
* **SuppressReboot**: Suppresses reboot
* **ForceReboot**: Forces Reboot
* **Features**: (Required) SQL features to be installed.
* **InstanceName**: (Key) SQL instance to be installed.
* **InstanceID**: SQL instance ID, if different from InstanceName.
* **PID**: Product key for licensed installations.
* **UpdateEnabled**: Enabled updates during installation.
* **UpdateSource**: Source of updates to be applied during installation.
* **SQMReporting**: Enable customer experience reporting.
* **ErrorReporting**: Enable error reporting.
* **FailoverClusterGroup**: Name of the resource group to be used for the SQL Server failover cluster.
* **FailoverClusterNetworkName**: (Required) Network name for the SQL Server failover cluster.
* **FailoverClusterIPAddress**: IPv4 address for the SQL Server failover cluster.
* **InstallSharedDir**: Installation path for shared SQL files.
* **InstallSharedWOWDir**: Installation path for x86 shared SQL files.
* **InstanceDir**: Installation path for SQL instance files.
* **SQLSvcAccount**: Service account for the SQL service.
* **SQLSvcAccountUsername**: Output user name for the SQL service.
* **AgtSvcAccount**: Service account for the SQL Agent service.
* **AgtSvcAccountUsername**: Output user name for the SQL Agent service.
* **SQLCollation**: Collation for SQL.
* **SQLSysAdminAccounts**: Array of accounts to be made SQL administrators.
* **SecurityMode**: SQL security mode.
* **SAPwd**: SA password, if SecurityMode=SQL.
* **InstallSQLDataDir**: Root path for SQL database files.
* **SQLUserDBDir**: Path for SQL database files.
* **SQLUserDBLogDir**: Path for SQL log files.
* **SQLTempDBDir**: Path for SQL TempDB files.
* **SQLTempDBLogDir**: Path for SQL TempDB log files.
* **SQLBackupDir**: Path for SQL backup files.
* **ASSvcAccount**: Service account for Analysis Services service.
* **ASSvcAccountUsername**: Output user name for the Analysis Services service.
* **ASCollation**: Collation for Analysis Services.
* **ASSysAdminAccounts**: Array of accounts to be made Analysis Services admins.
* **ASDataDir**: Path for Analysis Services data files.
* **ASLogDir**: Path for Analysis Services log files.
* **ASBackupDir**: Path for Analysis Services backup files.
* **ASTempDir**: Path for Analysis Services temp files.
* **ASConfigDir**: Path for Analysis Services config.
* **ISSvcAccount**: Service account for Integration Services service.
* **ISSvcAccountUsername**: Output user name for the Integration Services service.
* **ISFileSystemFolder**: File system folder for Integration Services.

### xSQLServerFirewall

* **Ensure**: (Key) Ensures that SQL firewall rules are **Present** or **Absent** on the machine.
* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **Features**: (Key) SQL features to enable firewall rules for.
* **InstanceName**: (Key) SQL instance to enable firewall rules for.
* **DatabaseEngineFirewall**: Is the firewall rule for the Database Engine enabled?
* **BrowserFirewall**: Is the firewall rule for the Browser enabled?
* **ReportingServicesFirewall**: Is the firewall rule for Reporting Services enabled?
* **AnalysisServicesFirewall**: Is the firewall rule for Analysis Services enabled?
* **IntegrationServicesFirewall**: Is the firewall rule for the Integration Services enabled?

### xSQLServerLogin

* **Ensure**: If the values should be present or absent. Valid values are 'Present' or 'Absent'.
* **Name**: (Key) The name of the SQL login. If LoginType is 'WindowsUser' or 'WindowsGroup' then provide the name in the format DOMAIN\name.
* **LoginCredential**: If LoginType is 'SqlLogin' then a PSCredential is needed for the password to the login.
* **LoginType**: The SQL login type. Valid values are 'SqlLogin', 'WindowsUser' or 'WindowsGroup'.
* **SQLServer**: (Key) The SQL Server for the login.
* **SQLInstanceName**: (Key) The SQL instance for the login.

### xSQLServerMaxDop

* **Ensure**: An enumerated value that describes if Min and Max memory is configured
* **DyamicAlloc**: Flag to indicate if MaxDop is dynamically configured
* **MaxDop**: Numeric value to configure MaxDop to
* **SQLServer**: The SQL Server where to set MaxDop
* **SQLInstance** (Key): The SQL instance where to set MaxDop

### xSQLServerMemory

* **Ensure**: An enumerated value that describes if Min and Max memory is configured
* **DyamicAlloc**: (key) Flag to indicate if Memory is dynamically configured
* **MinMemory**: Minimum memory value to set SQL Server memory to
* **MaxMemory**: Maximum memory value to set SQL Server memory to
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: (key) The SQL instance for the database

### xSQLServerNetwork

* **InstanceName**: (Key) name of SQL Server instance for which network will be configured.
* **ProtocolName**: (Required) Name of network protocol to be configured. Only tcp is currently supported.
* **IsEnabled**: Enables/Disables network protocol.
* **TCPDynamicPorts**: 0 if Dynamic ports should be used otherwise empty.
* **TCPPort**: Custom TCP port.
* **RestartService**: If true will restart SQL Service instance service after update. Default false.

### xSQLServerPermission

* **InstanceName** The SQL Server instance name.
* **NodeName** The host name or FQDN.
* **Ensure** If the permission should be present or absent.
* **Principal** The login to which permission will be set.
* **Permission** The permission to set for the login. Valid values are AlterAnyAvailabilityGroup, ViewServerState or AlterAnyEndPoint.

### xSQLServerRole

* **Name**: (Key) Name of the SQL Login to create
* **Ensure**: If the values should be present or absent. Valid values are 'Present' or 'Absent'.
* **ServerRole**: Type of SQL role to add.(bulkadmin, dbcreator, diskadmin, processadmin , public, securityadmin, serveradmin , setupadmin, sysadmin)
* **SQLServer**: SQL Server where login should be created
* **SQLInstance**: (Key) SQL Instance for the login

### xSQLServerReplication

* **InstanceName**: (Key) SQL Server instance name where replication distribution will be configured.
* **Ensure**: (Default = 'Present') 'Present' will configure replication, 'Absent' will disable replication.
* **DistributorMode**: (Required), 'Local' - Instance will be configured as it's own distributor, 'Remote' - Instace will be configure with remote distributor (remote distributor needs to be already configured for distribution).
* **AdminLinkCredentials**: (Required) - AdminLink password to be used when setting up publisher distributor relationship.
* **DistributionDBName**: (Default = 'distribution') distribution database name. If DistributionMode='Local' this will be created, if 'Remote' needs to match distribution database on remote distributor.
* **RemoteDistributor**: (Required if DistributionMode='Remote') SQL Server network name that will be used as distributor for local instance.
* **WorkingDirectory**: (Required) Publisher working directory.
* **UseTrustedConnection**: (Default = $true) Publisher security mode.
* **UninstallWithForce**: (Default = $true) Force flag for uninstall procedure

### xSQLServerRSConfig

* **InstanceName**: (Key) Name of the SQL Server Reporting Services instance to be configured.
* **RSSQLServer**: (Required) Name of the SQL Server to host the Reporting Service database.
* **RSSQLInstanceName**: (Required) Name of the SQL Server instance to host the Reporting Service database.
* **SQLAdminCredential**: (Required) Credential to be used to perform the configuration.
* **IsInitialized**: Output is the Reporting Services instance initialized.

### xSQLServerRSSecureConnectionLevel

* **InstanceName**: (Key) SQL instance to set secure connection level for.
* **SecureConnectionLevel**: (Key) SQL Server Reporting Service secure connection level.
* **Credential**: (Required) Credential with administrative permissions to the SQL instance.

### xSQLServerScript

_Note: There is a known problem running this resource using PowerShell 4.0. See [issue #273](https://github.com/PowerShell/xSQLServer/issues/273) for more information._

* **ServerInstance**: (Key) The name of an instance of the Database Engine. For a default instance, only specify the computer name. For a named instances, use the format ComputerName\\InstanceName.
* **SetFilePath**: (Key) Path to the T-SQL file that will perform Set action.
* **GetFilePath**: (Key) Path to the T-SQL file that will perform Get action. Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.
* **TestFilePath**: (Key) Path to the T-SQL file that will perform Test action. Any script that does not throw an error or returns null is evaluated to true. The cmdlet Invoke-SqlCmd treats T-SQL Print statements as verbose text, and will not cause the test to return false.
* **Credential**: The credentials to authenticate with, using SQL Authentication. To authenticate using Windows Authentication, assign the credentials to the built-in parameter `PsDscRunAsCredential`. If both parameters `Credential` and `PsDscRunAsCredential` are not assigned, then SYSTEM account will be used to authenticate using Windows Authentication.
* **Variable**: Specifies, as a string array, a sqlcmd scripting variable for use in the sqlcmd script, and sets a value for the variable. Use a Windows PowerShell array to specify multiple variables and their values. For more information how to use this, please go to the help documentation for [Invoke-Sqlcmd](https://technet.microsoft.com/en-us/library/mt683370.aspx).
* **GetResult**: (Read) Contains the values returned from the T-SQL script provided in the parameter `GetFilePath` when cmdlet Get-DscConfiguration is run.

### xSQLServerSetup

* **SourcePath**: (Required) The path to the root of the source files for installation. I.e and UNC path to a shared resource.
* **SourceFolder**: Folder within the source path containing the source files for installation. Default value is 'Source'.
* **SetupCredential**: (Required) Credential to be used to perform the installation.
* **SourceCredential**: Credentials used to access the path set in the parameter `SourcePath` and `SourceFolder`. Using this parameter will trigger a copy of the installation media to a temp folder on the target node. Setup will then be started from the temp folder on the target node. For any subsequent calls to the resource, the parameter `SourceCredential` is used to evaluate what major version the file 'setup.exe' has in the path set, again, by the parameter `SourcePath` and `SourceFolder`. To know how the temp folder is evaluated please read the online documentation for [System.IO.Path.GetTempPath()](https://msdn.microsoft.com/en-us/library/system.io.path.gettemppath(v=vs.110).aspx).
* **SuppressReboot**: Suppresses reboot.
* **ForceReboot**: Forces reboot.
* **Features**: (Key) SQL features to be installed.
* **InstanceName**: (Key) SQL instance to be installed.
* **InstanceID**: SQL instance ID, if different from InstanceName.
* **PID**: Product key for licensed installations.
* **UpdateEnabled**: Enabled updates during installation.
* **UpdateSource**: Path to the source of updates to be applied during installation.
* **SQMReporting**: Enable customer experience reporting.
* **ErrorReporting**: Enable error reporting.
* **InstallSharedDir**: Installation path for shared SQL files.
* **InstallSharedWOWDir**: Installation path for x86 shared SQL files.
* **InstanceDir**: Installation path for SQL instance files.
* **SQLSvcAccount**: Service account for the SQL service.
* **SQLSvcAccountUsername**: (Read) Output user name for the SQL service.
* **AgtSvcAccount**: Service account for the SQL Agent service.
* **AgtSvcAccountUsername**: (Read) Output user name for the SQL Agent service.
* **SQLCollation**: Collation for SQL.
* **SQLSysAdminAccounts**: Array of accounts to be made SQL administrators.
* **SecurityMode**: Security mode to apply to the SQL Server instance.
* **SAPwd**: SA password, if SecurityMode is set to 'SQL'.
* **InstallSQLDataDir**: Root path for SQL database files.
* **SQLUserDBDir**: Path for SQL database files.
* **SQLUserDBLogDir**: Path for SQL log files.
* **SQLTempDBDir**: Path for SQL TempDB files.
* **SQLTempDBLogDir**: Path for SQL TempDB log files.
* **SQLBackupDir**: Path for SQL backup files.
* **FTSvcAccount**: Service account for the Full Text service.
* **FTSvcAccountUsername**: (Read) Output username for the Full Text service.
* **RSSvcAccount**: Service account for Reporting Services service.
* **RSSvcAccountUsername**: (Read) Output username for the Reporting Services service.
* **ASSvcAccount**: Service account for Analysis Services service.
* **ASSvcAccountUsername**: (Read) Output username for the Analysis Services service.
* **ASCollation**: Collation for Analysis Services.
* **ASSysAdminAccounts**: Array of accounts to be made Analysis Services admins.
* **ASDataDir**: Path for Analysis Services data files.
* **ASLogDir**: Path for Analysis Services log files.
* **ASBackupDir**: Path for Analysis Services backup files.
* **ASTempDir**: Path for Analysis Services temp files.
* **ASConfigDir**: Path for Analysis Services config.
* **ISSvcAccount**: Service account for Integration Services service.
* **ISSvcAccountUsername**: (Read) Output user name for the Integration Services service.
* **BrowserSvcStartupType**: Specifies the startup mode for SQL Server Browser service. Valid values are 'Automatic', 'Disabled' or 'Manual'.

### xWaitforAvailabilityGroup

* **Name**:  (key) Name for availability group
* **RetryIntervalSec**: Interval to check for availability group
* **RetryCount**: Maximum number of retries to check availability group creation
