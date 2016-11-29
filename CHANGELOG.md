# Change log for xSQLServer

## Unreleased

- Fixes in xSQLServerConfiguration
  - Added support for clustered SQL instances
  - BREAKING CHANGE: Updated parameters to align with other resources (SQLServer / SQLInstanceName)
  - Updated code to utilize CIM rather than WMI
- Added tests for resources
  - xSQLServerConfiguration
  - xSQLServerSetup
  - xSQLServerDatabaseRole
  - xSQLAOGroupJoin
  - xSQLServerHelper and moved the existing tests for Restart-SqlService to it.
  - xSQLServerAlwaysOnService
- Fixes in xSQLAOGroupJoin
  - Availability Group name now appears in the error message for a failed Availability Group join attempt.
  - Get-TargetResource now works with Get-DscConfiguration
- Fixes in xSQLServerRole
  - Updated Ensure parameter to 'Present' default value
  - Renamed helper functions *-SqlServerRole to *-SqlServerRoleMember
- Changes to xSQLAlias
  - Add UseDynamicTcpPort parameter for option "Dynamically determine port"
  - Change Get-WmiObject to Get-CimInstance in Resource and associated pester file
- Added CHANGELOG.md file
- Added issue template file (ISSUE_TEMPLATE.md) for 'New Issue' and pull request template file (PULL_REQUEST_TEMPLATE.md) for 'New Pull Request'
- Add Contributing.md file
- Changes to xSQLServerSetup
  - Now `Features` parameter is case-insensitive.
- BREAKING CHANGE: Removed xSQLServerPowerPlan from this module. The resource has been moved to [xComputerManagement](https://github.com/PowerShell/xComputerManagement) and is now called xPowerPlan.
- Changes and enhancements in xSQLServerDatabaseRole
  - BREAKING CHANGE: Fixed so the same user can now be added to a role in one or more databases, and/or one or more instances. Now the parameters `SQLServer` and `SQLInstanceName` are mandatory.
  - Enhanced so the same user can now be added to more than one role
- BREAKING CHANGE: Renamed xSQLAlias to xSQLServerAlias to align wíth naming convention.
- Changes to xSQLServerAlwaysOnService
  - Added RestartTimeout parameter
  - Fixed bug where the SQL Agent service did not get restarted after the IsHadrEnabled property was set.
- Moved Restart-SqlService from MSFT_xSQLServerConfiguration.psm1 to xSQLServerHelper.psm1.
- Created unit tests for xSQLServerHelper.psm1 and moved the existing tests for Restart-SqlService to it.
- Created unit tests for xSQLServerAlwaysOnService

## 3.0.0.0

- xSQLServerHelper
  - added functions
    - Test-SQLDscParameterState
    - Get-SqlDatabaseOwner
    - Set-SqlDatabaseOwner
- Examples
  - xSQLServerDatabaseOwner
    - 1-SetDatabaseOwner.ps1
- Added tests for resources
  - MSFT_xSQLServerDatabaseOwner

## 2.0.0.0

- Added resources
  - xSQLServerReplication
  - xSQLServerScript
  - xSQLAlias
  - xSQLServerRole
- Added tests for resources
  - xSQLServerPermission
  - xSQLServerEndpointState
  - xSQLServerEndpointPermission
  - xSQLServerAvailabilityGroupListener
  - xSQLServerLogin
  - xSQLAOGroupEnsure
  - xSQLAlias
  - xSQLServerRole
- Fixes in xSQLServerAvailabilityGroupListener
  - In one case the Get-method did not report that DHCP was configured.
  - Now the resource will throw 'Not supported' when IP is changed between Static and DHCP.
  - Fixed an issue where sometimes the listener wasn't removed.
  - Fixed the issue when trying to add a static IP to a listener was ignored.
- Fix in xSQLServerDatabase
  - Fixed so dropping a database no longer throws an error
  - BREAKING CHANGE: Fixed an issue where it was not possible to add the same database to two instances on the same server.
  - BREAKING CHANGE: The name of the parameter Database has changed. It is now called Name.
- Fixes in xSQLAOGroupEnsure
  - Added parameters to New-ListenerADObject to allow usage of a named instance.
  - pass setup credential correctly
- Changes to xSQLServerLogin
  - Fixed an issue when dropping logins.
  - BREAKING CHANGE: Fixed an issue where it was not possible to add the same login to two instances on the same server.
- Changes to xSQLServerMaxDop
  - BREAKING CHANGE: Made SQLInstance parameter a key so that multiple instances on the same server can be configured

## 1.8.0.0

- Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.
- Added Support for SQL Server 2016
- xSQLAOGroupEnsure
  - Fixed spelling mistake in AutoBackupPreference property
  - Added BackupPriority property
- Added resources
  - xSQLServerPermission
  - xSQLServerEndpointState
  - xSQLServerEndpointPermission
  - xSQLServerAvailabilityGroupListener
- xSQLServerHelper
  - added functions
    - Import-SQLPSModule
    - Get-SQLPSInstanceName
    - Get-SQLPSInstance
    - Get-SQLAlwaysOnEndpoint
  - modified functions
    - New-TerminatingError - *added optional parameter `InnerException` to be able to give the user more information in the returned message*

## 1.7.0.0

- Resources Added
  - xSQLServerConfiguration

## 1.6.0.0

- Resources Added
  - xSQLAOGroupEnsure
  - xSQLAOGroupJoin
  - xWaitForAvailabilityGroup
  - xSQLServerEndPoint
  - xSQLServerAlwaysOnService
- xSQLServerHelper
  - added functions
    - Connect-SQL
    - New-VerboseMessage
    - Grant-ServerPerms
    - Grant-CNOPerms
    - New-ListenerADObject
- xSQLDatabaseRecoveryModel
    - Updated Verbose statements to use new function New-VerboseMessage
- xSQLServerDatabase
    - Updated Verbose statements to use new function New-VerboseMessage
    - Removed ConnectSQL function and replaced with new Connect-SQL function
- xSQLServerDatabaseOwner
    - Removed ConnectSQL function and replaced with new Connect-SQL function
- xSQLServerDatabasePermissions
    - Removed ConnectSQL function and replaced with new Connect-SQL function
- xSQLServerDatabaseRole
    - Removed ConnectSQL function and replaced with new Connect-SQL function
- xSQLServerLogin
    - Removed ConnectSQL function and replaced with new Connect-SQL function
- xSQLServerMaxDop
    - Updated Verbose statements to use new function New-VerboseMessage
    - Removed ConnectSQL function and replaced with new Connect-SQL function
- xSQLServerMemory
    - Updated Verbose statements to use new function New-VerboseMessage
    - Removed ConnectSQL function and replaced with new Connect-SQL function
- xSQLServerPowerPlan
    - Updated Verbose statements to use new function New-VerboseMessage
- Examples
    - Added xSQLServerConfiguration resource example

## 1.5.0.0

- Added new resource xSQLServerDatabase that allows adding an empty database to a server

## 1.4.0.0

- Resources Added
  - xSQLDatabaseRecoveryModeAdded
  - xSQLServerDatabaseOwner
  - xSQLServerDatabasePermissions
  - xSQLServerDatabaseRole
  - xSQLServerLogin
  - xSQLServerMaxDop
  - xSQLServerMemory
  - xSQLServerPowerPlan
  - xSQLServerDatabase
- xSQLServerSetup:
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
- xSQLServerFirewall
  - Removed default values for parameters, to avoid compatibility issues
  - Updated firewall rule name to not use 2012 version, since package supports 2008, 2012 and 2014 versions
  - Additional of SQLHelper Function and error handling
  - Change SourceFolder to Source to allow for multiversion Support
- xSQLServerNetwork
  - Added new resource that configures network settings.
  - Currently supports only tcp network protocol
  - Allows to enable and disable network protocol for specified instance service
  - Allows to set custom or dynamic port values
- xSQLServerRSSecureConnectionLevel
  - Additional of SQLHelper Function and error handling
- xSqlServerRSConfig
- xSQLServerFailoverClusterSetup
  - Additional of SQLHelper Function and error handling
  - Change SourceFolder to Source to allow for multiversion Support
  - Add Parameters to SuppressReboot or ForceReboot
- Examples
  - Updated example files to use correct DebugMode parameter value ForceModuleImport, this is not boolean in WMF 5.0 RTM
  - Added xSQLServerNetwork example

## 1.3.0.0

- xSqlServerSetus
  - Make Features case-insensitive.

## 1.2.1.0

- Increased timeout for setup process to start to 60 seconds.

## 1.2.0.0

- Updated release with the following new resources
  - xSQLServerFailoverClusterSetup
  - xSQLServerRSConfig

## 1.1.0.0

- Initial release with the following resources
  - xSQLServerSetup
  - xSQLServerFirewall
  - xSQLServerRSSecureConnectionLevel
