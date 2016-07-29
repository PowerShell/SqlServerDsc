
# xSQLServer

The **xSQLServer** module contains DSC resources for deployment and configuration of SQL Server in a way that is fully compliant with the requirements of System Center.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


## Resources

* **xSQLServerSetup** installs a standalone SQL Server instance
* **xSQLServerFirewall** configures firewall settings to allow remote access to a SQL Server instance.
* **xSQLServerRSSecureConnectionLevel** sets the secure connection level for SQL Server Reporting Services.
* **xSQLServerFailoverClusterSetup** installs SQL Server failover cluster instances.
* **xSQLServerRSConfig** configures SQL Server Reporting Services to use a database engine in another instance.
* **xSQLServerLogin** resource to manage SQL logins
* **xSQLServerDatabaseRole** resource to manage SQL database roles
* **xSQLServerDatabasePermissions** resource to manage SQL database permissions
* **xSQLServerDatabaseOwner** resource to manage SQL database owners
* **xSQLDatabaseRecoveryModel** resource to manage database recovery model
* **xSQLServerMaxDop** resource to manage MaxDegree of Parallelism for SQL Server
* **xSQLServerMemory** resource to manage Memory for SQL Server
* **xSQLServerPowerPlan** resource to manage windows powerplan on SQL Server
* **xSQLServerNetwork** resource to manage SQL Server Network Protocols
* **xSQLServerDatabase** resource to manage ensure database is present or absent
* **xSQLAOGroupEnsure** resource to ensure availability group is present or absent
* **xSQLAOGroupJoin** resource to join a replica to an existing availability group
* **xSQLServerAlwaysOnService** resource to enable always on on a SQL Server
* **xSQLServerEndpoint** resource to ensure database endpoint is present or absent
* **xWaitForAvailabilityGroup** resource to wait till availability group is created on primary server
* **xSQLServerConfiguration** resource to manage [SQL Server Configuration Options](https://msdn.microsoft.com/en-us/library/ms189631.aspx)
* **xSQLAlias** resource to manage SQL Server client Aliases

### xSQLServerSetup

* **SourcePath**: (Required) UNC path to the root of the source files for installation.
* **SourceFolder**: Folder within the source path containing the source files for installation.
* **SetupCredential**: (Required) Credential to be used to perform the installation.
* **SourceCredential**: Credential used to access SourcePath
* **SuppressReboot**: Suppresses reboot
* **ForceReboot**: Forces Reboot
* **Features**: (Key) SQL features to be installed.
* **InstanceName**: (Key) SQL instance to be installed.
* **InstanceID**: SQL instance ID, if different from InstanceName.
* **PID**: Product key for licensed installations.
* **UpdateEnabled**: Enabled updates during installation.
* **UpdateSource**: Source of updates to be applied during installation.
* **SQMReporting**: Enable customer experience reporting.
* **ErrorReporting**: Enable error reporting.
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
* **FTSvcAccount**: Service account for the Full Text service.
* **FTSvcAccountUsername**: Output username for the Full Text service.
* **RSSvcAccount**: Service account for Reporting Services service.
* **RSSvcAccountUsername**: Output username for the Reporting Services service.
* **ASSvcAccount**: Service account for Analysis Services service.
* **ASSvcAccountUsername**: Output username for the Analysis Services service.
* **ASCollation**: Collation for Analysis Services.
* **ASSysAdminAccounts**: Array of accounts to be made Analysis Services admins.
* **ASDataDir**: Path for Analysis Services data files.
* **ASLogDir**: Path for Analysis Services log files.
* **ASBackupDir**: Path for Analysis Services backup files.
* **ASTempDir**: Path for Analysis Services temp files.
* **ASConfigDir**: Path for Analysis Services config.
* **ISSvcAccount**: Service account for Integration Services service.
* **ISSvcAccountUsername**: Output user name for the Integration Services service.

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

### xSQLServerRSSecureConnectionLevel

* **InstanceName**: (Key) SQL instance to set secure connection level for.
* **SecureConnectionLevel**: (Key) SQL Server Reporting Service secure connection level.
* **Credential**: (Required) Credential with administrative permissions to the SQL instance.

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

### xSQLServerRSConfig

* **InstanceName**: (Key) Name of the SQL Server Reporting Services instance to be configured.
* **RSSQLServer**: (Required) Name of the SQL Server to host the Reporting Service database.
* **RSSQLInstanceName**: (Required) Name of the SQL Server instance to host the Reporting Service database.
* **SQLAdminCredential**: (Required) Credential to be used to perform the configuration.
* **IsInitialized**: Output is the Reporting Services instance initialized.

### xSQLServerLogin
* **Name**: (Key) Name of the SQL Login to create
* **LoginCredential**: PowerShell Credential for the SQL Login to be created
* **LoginType**: Type of SQL login to create.(SQL, WindowsUser, WindowsGroup)
* **SQLServer**: SQL Server where login should be created
* **SQLInstance**: SQL Instance for the login

### xSQLServerDatabaseRole
* **Name**: (Key) Name of the SQL Login or the role on the database
* **SQLServer**: The SQL Server for the database
* **SQLInstanceName**: The SQL Instance for the database
* **Database**: The SQL Database for the role
* **Role**: The SQL role for the database

###xSQLServerDatabasePermissions
* **Database**: (Key) The SQL Database
* **Name**: (Required) The name of permissions for the SQL database
* **Permissions**: (Required) The set of Permissions for the SQL database
* **SQLServer**: The SQL Server for the database
* **SQLInstanceName**: The SQL instance for the database

###xSQLServerDatabaseOwner
* **Database**: (Key) The SQL Database
* **Name**: (Required) The name of the SQL login for the owner
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database

###xSQLDatabaseRecoveryModel
* **DatabaseName**: (key) The SQL database name
* **SQLServerInstance**: (Required) The SQL server and instance
* **RecoveryModel**: (Required) Recovery Model (Full, Simple, BulkLogged)

###xSQLServerMaxDop
* **Ensure**: (key) An enumerated value that describes if Min and Max memory is configured
* **DyamicAlloc**: (key) Flag to indicate if MaxDop is dynamically configured
* **MaxDop**: Numeric value to configure MaxDop to
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database

###xSQLServerMemory
* **Ensure**: (key) An enumerated value that describes if Min and Max memory is configured
* **DyamicAlloc**: (key) Flag to indicate if Memory is dynamically configured
* **MinMemory**: Minimum memory value to set SQL Server memory to
* **MaxMemory**: Maximum memory value to set SQL Server memory to
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database

###xSQLServerPowerPlan
* **Ensure**: (key) An enumerated value that describes if Min and Max memory is configured

### xSQLServerNetwork
* **InstanceName**: (Key) name of SQL Server instance for which network will be configured.
* **ProtocolName**: (Required) Name of network protocol to be configured. Only tcp is currently supported.
* **IsEnabled**: Enables/Disables network protocol.
* **TCPDynamicPorts**: 0 if Dynamic ports should be used otherwise empty.
* **TCPPort**: Custom TCP port.
* **RestartService**: If true will restart SQL Service instance service after update. Default false.

###xSQLServerDatabase
* **Database**: (key) Database to be created or dropped
* **Ensure**: An enumerated value that describes if Database is to be present or absent.
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database 

###xSQLAOGroupEnsure
* **Ensure**: (key) An enumerated value that describes if Availability Group is to be present or absent.
* **AvailabilityGroupName** (key) Name for availability group
* **AvailabilityGroupNameListener** Listener name for availability group
* **AvailabilityGroupNameIP** List of IP addresses associated with listener
* **AvailabilityGroupSubMask** Network subnetmask for listener
* **AvailabilityGroupPort** Port availability group should listen on
* **ReadableSecondary** Mode secondaries should operate under (None, ReadOnly, ReadIntent)
* **AutoBackupPreference** Where backups should be backed up from (Primary,Secondary)
* **BackupPriority** The percentage weight for backup prority (default 50)
* **EndPointPort** The TCP port for the SQL AG Endpoint (default 5022)
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database
* **SetupCredential**: (Required) Credential to be used to Grant Permissions on SQL Server

###xSQLServerAOJoin
* **Ensure**: (key) An enumerated value that describes if Replica is to be present or absent from availability group
* **AvailabilityGroupName** (key) Name for availability group
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database
* **SetupCredential**: (Required) Credential to be used to Grant Permissions on SQL Server

###xSQLServerAlwaysOnService
* **Ensure**: (key) An enumerated value that describes if SQL server should have AlwaysOn property present or absent.
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database

###xSQLServerEndpoint
* **EndPointName**: Name for endpoint to be created on SQL Server
* **Ensure**: (key) An enumerated value that describes if endpoint is to be present or absent on SQL Server
* **Port**: Port Endpoint should listen on
* **AuthorizedUser**:  User who should have connect ability to endpoint
* **SQLServer**: The SQL Server for the database
* **SQLInstance**: The SQL instance for the database 

###xWaitforAvailabilityGroup
* **Name**:  (key) Name for availability group
* **RetryIntervalSec**: Interval to check for availability group
* **RetryCount**: Maximum number of retries to check availability group creation

###xSQLServerConfiguration
* **InstanceName**: (Key) name of SQL Server instance for which configuration options will be configured.
* **OptionName**: (Key) SQL Server option name. For all possible values reference [MSDN](https://msdn.microsoft.com/en-us/library/ms189631.aspx) or run sp_configure.
* **OptionValue**: (Required) SQL Server option value to be set.
* **RestartService**: Default false. If true will restart SQL Service instance service after update.

### xSqlAlias
 
 * **Name**: The name of Alias (e.g. svr01\inst01).
 * **ServerName**: The name of real SQL server.
 * **Protocol**: The protocol of either tcp or np (named pipes).
 * **RetryCount**: Maximum number of retries to check HA group existency.
 * **TCPPort**: The tcp port of the instance.
## Versions

### Unreleased
* Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.
* Added Support for SQL Server 2016
* Pester Tests for xSQLAOGroupEnsure and xSQLAlias
* Correction on xSQLAOGroupEnsure to pass Setup Credential Correctly
* xSQLAOGroupEnsure
   - Fixed spelling mistake in AutoBackupPreference property
   - Added BackupPriority property

* Resources Added
	* xSQLAlias	
	
### 1.7.0.0
* Resources Added
  - xSQLServerConfiguration

### 1.6.0.0

* Resources Added
  - xSQLAOGroupEnsure
  - xSQLAOGroupJoin
  - xWaitForAvailabilityGroup
  - xSQLServerEndPoint
  - xSQLServerAlwaysOnService
* xSQLServerHelper
    - added functions 
        - Connect-SQL
        - New-VerboseMessage
        - Grant-ServerPerms
        - Grant-CNOPerms
        - New-ListenerADObject
* xSQLDatabaseRecoveryModel
    - Updated Verbose statements to use new function New-VerboseMessage
* xSQLServerDatabase
    - Updated Verbose statements to use new function New-VerboseMessage
    - Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerDatabaseOwner
    - Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerDatabasePermissions
    - Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerDatabaseRole
    - Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerLogin
    - Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerMaxDop
    - Updated Verbose statements to use new function New-VerboseMessage
    - Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerMemory
    - Updated Verbose statements to use new function New-VerboseMessage
    - Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerPowerPlan
    - Updated Verbose statements to use new function New-VerboseMessage
* Examples
    - Added xSQLServerConfiguration resource example

### 1.5.0.0

* Added new resource xSQLServerDatabase that allows adding an empty database to a server

### 1.4.0.0

* Resources Added
  - xSQLDatabaseRecoveryModeAdded
  - xSQLServerDatabaseOwner
  - xSQLServerDatabasePermissions
  - xSQLServerDatabaseRole
  - xSQLServerLogin
  - xSQLServerMaxDop
  - xSQLServerMemory
  - xSQLServerPowerPlan
  - xSQLServerDatabase
* xSQLServerSetup:
  - Corrected bug in GetFirstItemPropertyValue to correctly handle registry keys with only one value.
  - Added support for SQL Server 
  - 2008 R2 installation
  - Removed default values for parameters, to avoid compatibility issues and setup errors
  - Added Replication sub feature detection
  - Added setup parameter BrowserSvcStartupType
  - Change SourceFolder to Source to allow for multiversion Support
  - Add Source Credential for accessing source files
  - Add Parameters for SQL Server configuration
  - Add Parameters to SuppressReboot or ForceReboot
* xSQLServerFirewall
  - Removed default values for parameters, to avoid compatibility issues
  - Updated firewall rule name to not use 2012 version, since package supports 2008, 2012 and 2014 versions
  - Additional of SQLHelper Function and error handling
  - Change SourceFolder to Source to allow for multiversion Support
* xSQLServerNetwork
  - Added new resource that configures network settings.
  - Currently supports only tcp network protocol
  - Allows to enable and disable network protocol for specified instance service
  - Allows to set custom or dynamic port values
* xSQLServerRSSecureConnectionLevel
  - Additional of SQLHelper Function and error handling
* xSqlServerRSConfig
* xSQLServerFailoverClusterSetup
  - Additional of SQLHelper Function and error handling
  - Change SourceFolder to Source to allow for multiversion Support
  - Add Parameters to SuppressReboot or ForceReboot 
* Examples
  - Updated example files to use correct DebugMode parameter value ForceModuleImport, this is not boolean in WMF 5.0 RTM
  - Added xSQLServerNetwork example

### 1.3.0.0

* xSqlServerSetup: 
    - Make Features case-insensitive.

### 1.2.1.0

* Increased timeout for setup process to start to 60 seconds.

### 1.2.0.0

* Updated release with the following new resources 
    - xSQLServerFailoverClusterSetup
    - xSQLServerRSConfig

### 1.1.0.0

* Initial release with the following resources 
    - xSQLServerSetup
    - xSQLServerFirewall
    - xSQLServerRSSecureConnectionLevel

## Examples

Examples for use of this resource can be found with the System Center resources, such as **xSCVMM**, **xSCSMA**, and **xSCOM**.


