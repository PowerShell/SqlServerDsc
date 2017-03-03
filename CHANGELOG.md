# Change log for xSQLServer

## Unreleased

- Examples
  - xSQLServerDatabaseRole
    - 1-AddDatabaseRole.ps1
    - 2-RemoveDatabaseRole.ps1
  - xSQLServerRole, add examples:
    - 3-AddMembersToServerRole.ps1
    - 4-MembersToIncludeInServerRole.ps1
    - 5-MembersToExcludeInServerRole.ps1
- Changes to xSQLServerDatabaseRole
  - Fixed code style, added updated parameter descriptions to schema.mof and README.md.
- Changes to xSQLServer
  - Raised the CodeCov target to 70% which is the minimum and required target for HQRM resource.
- Changes to xSQLServerRole
  - **BREAKING CHANGE: The resource has been reworked in it's entirely.** Below is what has changed.
    - The mandatory parameters now also include ServerRoleName.
    - The ServerRole parameter was before an array of server roles, now this parameter is renamed to ServerRoleName and can only be set to one server role.
      - ServerRoleName are no longer limited to built-in server roles. To add members to a built-in server role, set ServerRoleName to the name of the built-in server role.
      - The ServerRoleName will be created when Ensure is set to 'Present' (if it does not already exist), or removed if Ensure is set to 'Absent'.
    - Three new parameters are added; Members, MembersToInclude and MembersToExclude.
      - Members can be set to one or more logins, and those will _replace all_ the memberships in the server role.
      - MembersToInclude and MembersToExclude can be set to one or more logins that will add or remove memberships, respectively, in the server role. MembersToInclude and MembersToExclude _can not_ be used at the same time as parameter Members. But both MembersToInclude and MembersToExclude can be used together at the same time.
- Changes to xSQLServerSetup
  - Added a note to the README.md saying that it is not possible to add or remove features from a SQL Server failover cluster (issue #433).
  - Changed so that it reports false if the desired state is not correct (issue #432).
    - Added a test to make sure we always return false if a SQL Server failover cluster is missing features.
  - Helper function Connect-SQLAnalysis
    - Now has correct error handling, and throw does not used the unknown named parameter '-Message' (issue #436)
    - Added tests for Connect-SQLAnalysis
    - Changed to localized error messages.
    - Minor changes to error handling.

## 6.0.0.0

- Changes to xSQLServerConfiguration
  - BREAKING CHANGE: The parameter SQLInstanceName is now mandatory.
  - Resource can now be used to define the configuration of two or more different DB instances on the same server.
- Changes to xSQLServerRole
  - xSQLServerRole now correctly reports that the desired state is present when the login is already a member of the server roles.
- Added new resources
  - xSQLServerAlwaysOnAvailabilityGroup
  - xSQLServerAlwaysOnAvailabilityGroupReplica
- Changes to xSQLServerSetup
  - Properly checks for use of SQLSysAdminAccounts parameter in $PSBoundParameters. The test now also properly evaluates the setup argument for SQLSysAdminAccounts.
  - xSQLServerSetup should now function correctly for the InstallFailoverCluster action, and also supports cluster shared volumes. Note that the AddNode action is not currently working.
  - It now detects that feature Client Connectivity Tools (CONN) and Client Connectivity Backwards Compatibility Tools (BC) is installed.
  - Now it can correctly determine the right cluster when only parameter InstallSQLDataDir is assigned a path (issue #401).
  - Now the only mandatory path parameter is InstallSQLDataDir when installing Database Engine (issue #400).
  - It now can handle mandatory parameters, and are not using wildcards to find the variables containing paths (issue #394).
  - Changed so that instead of connection to localhost it is using $env:COMPUTERNAME as the host name to which it connects. And for cluster installation it uses the parameter FailoverClusterNetworkName as the host name to which it connects (issue #407).
  - When called with Action = 'PrepareFailoverCluster', the SQLSysAdminAccounts and FailoverClusterGroup parameters are no longer passed to the setup process (issues #410 and 411).
  - Solved the problem that InstanceDir and InstallSQLDataDir could not be set to just a qualifier, i.e 'E:' (issue #418). All paths (except SourcePath) can now be set to just the qualifier.
- Enables CodeCov.io code coverage reporting.
- Added badge for CodeCov.io to README.md.
- Examples
  - xSQLServerMaxDop
    - 1-SetMaxDopToOne.ps1
    - 2-SetMaxDopToAuto.ps1
    - 3-SetMaxDopToDefault.ps1
  - xSQLServerMemory
    - 1-SetMaxMemoryTo12GB.ps1
    - 2-SetMaxMemoryToAuto.ps1
    - 3-SetMinMaxMemoryToAuto.ps1
    - 4-SetMaxMemoryToDefault.ps1
  - xSQLServerDatabase
    - 1-CreateDatabase.ps1
    - 2-DeleteDatabase.ps1
- Added tests for resources
  - xSQLServerMaxDop
  - xSQLServerMemory
- Changes to xSQLServerMemory
  - BREAKING CHANGE: The mandatory parameter now include SQLInstanceName. The DynamicAlloc parameter is no longer mandatory
- Changes to xSQLServerDatabase
  - When the system is not in desired state the Test-TargetResource will now output verbose messages saying so.
- Changes to xSQLServerDatabaseOwner
  - Fixed code style, added updated parameter descriptions to schema.mof and README.md.

## 5.0.0.0

- Improvements how tests are initiated in AppVeyor
  - Removed previous workaround (issue #201) from unit tests.
  - Changes in appveyor.yml so that SQL modules are removed before common test is run.
  - Now the deploy step are no longer failing when merging code into Dev. Neither is the deploy step failing if a contributor had AppVeyor connected to the fork of xSQLServer and pushing code to the fork.
- Changes to README.md
  - Changed the contributing section to help new contributors.
  - Added links for each resource so it is easier to navigate to the parameter list for each resource.
  - Moved the list of resources in alphabetical order.
  - Moved each resource parameter list into alphabetical order.
  - Removed old text mentioning System Center.
  - Now the correct product name is written in the installation section, and a typo was also fixed.
  - Fixed a typo in the Requirements section.
  - Added link to Examples folder in the Examples section.
  - Change the layout of the README.md to closer match the one of PSDscResources
  - Added more detailed text explaining what operating systemes WMF5.0 can be installed on.
  - Verified all resource schema files with the README.md and fixed some errors (descriptions was not verified).
  - Added security requirements section for resource xSQLServerEndpoint and xSQLAOGroupEnsure.
- Changes to xSQLServerSetup
  - The resource no longer uses Win32_Product WMI class when evaluating if SQL Server Management Studio is installed. See article [kb974524](https://support.microsoft.com/en-us/kb/974524) for more information.
  - Now it uses CIM cmdlets to get information from WMI classes.
  - Resolved all of the PSScriptAnalyzer warnings that was triggered in the common tests.
  - Improvement for service accounts to enable support for Managed Service Accounts as well as other nt authority accounts
  - Changes to the helper function Copy-ItemWithRoboCopy
    - Robocopy is now started using Start-Process and the error handling has been improved.
    - Robocopy now removes files at the destination path if they no longer exists at the source.
    - Robocopy copies using unbuffered I/O when available (recommended for large files).
  - Added a more descriptive text for the parameter `SourceCredential` to further explain how the parameter work.
  - BREAKING CHANGE: Removed parameter SourceFolder.
  - BREAKING CHANGE: Removed default value "$PSScriptRoot\..\..\" from parameter SourcePath.
  - Old code, that no longer filled any function, has been replaced.
      - Function `ResolvePath` has been replaced with `[Environment]::ExpandEnvironmentVariables($SourcePath)` so that environment variables still can be used in Source Path.
      - Function `NetUse` has been replaced with `New-SmbMapping` and `Remove-SmbMapping`.
  - Renamed function `GetSQLVersion` to `Get-SqlMajorVersion`.
  - BREAKING CHANGE: Renamed parameter PID to ProductKey to avoid collision with automatic variable $PID
- Changes to xSQLServerScript
  - All credential parameters now also has the type [System.Management.Automation.Credential()] to better work with PowerShell 4.0.
  - It is now possible to configure two instances on the same node, with the same script.
  - Added to the description text for the parameter `Credential` describing how to authenticate using Windows Authentication.
  - Added examples to show how to authenticate using either SQL or Windows authentication.
  - A recent issue showed that there is a known problem running this resource using PowerShell 4.0. For more information, see [issue #273](https://github.com/PowerShell/xSQLServer/issues/273)
- Changes to xSQLServerFirewall
  - BREAKING CHANGE: Removed parameter SourceFolder.
  - BREAKING CHANGE: Removed default value "$PSScriptRoot\..\..\" from parameter SourcePath.
  - Old code, that no longer filled any function, has been replaced.
    - Function `ResolvePath` has been replaced with `[Environment]::ExpandEnvironmentVariables($SourcePath)` so that environment variables still can be used in Source Path.
  - Adding new optional parameter SourceCredential that can be used to authenticate against SourcePath.
  - Solved PSSA rules errors in the code.
  - Get-TargetResource no longer return $true when no products was installed.
- Changes to the unit test for resource
  - xSQLServerSetup
    - Added test coverage for helper function Copy-ItemWithRoboCopy
- Changes to xSQLServerLogin
  - Removed ShouldProcess statements
  - Added the ability to enforce password policies on SQL logins
- Added common test (xSQLServerCommon.Tests) for xSQLServer module
  - Now all markdown files will be style checked when tests are running in AppVeyor after sending in a pull request.
  - Now all [Examples](/Examples/Resources) will be tested by compiling to a .mof file after sending in a pull request.
- Changes to xSQLServerDatabaseOwner
  - The example 'SetDatabaseOwner' can now compile, it wrongly had a `DependsOn` in the example.
- Changes to SQLServerRole
  - The examples 'AddServerRole' and 'RemoveServerRole' can now compile, it wrongly had a `DependsOn` in the example.
- Changes to CONTRIBUTING.md
  - Added section 'Tests for examples files'
  - Added section 'Tests for style check of Markdown files'
  - Added section 'Documentation with Markdown'
  - Added texts to section 'Tests'
- Changes to xSQLServerHelper
  - added functions
    - Get-SqlDatabaseRecoveryModel
    - Set-SqlDatabaseRecoveryModel
- Examples
  - xSQLServerDatabaseRecoveryModel
    - 1-SetDatabaseRecoveryModel.ps1
  - xSQLServerDatabasePermission
    - 1-GrantDatabasePermissions.ps1
    - 2-RevokeDatabasePermissions.ps1
    - 3-DenyDatabasePermissions.ps1
  - xSQLServerFirewall
    - 1-CreateInboundFirewallRules
    - 2-RemoveInboundFirewallRules
- Added tests for resources
  - xSQLServerDatabaseRecoveryModel
  - xSQLServerDatabasePermissions
  - xSQLServerFirewall
- Changes to xSQLServerDatabaseRecoveryModel
  - BREAKING CHANGE: Renamed xSQLDatabaseRecoveryModel to xSQLServerDatabaseRecoveryModel to align wíth naming convention.
  - BREAKING CHANGE: The mandatory parameters now include SQLServer, and SQLInstanceName.
- Changes to xSQLServerDatabasePermission
  - BREAKING CHANGE: Renamed xSQLServerDatabasePermissions to xSQLServerDatabasePermission to align wíth naming convention.
  - BREAKING CHANGE: The mandatory parameters now include PermissionState, SQLServer, and SQLInstanceName.
- Added support for clustered installations to xSQLServerSetup
  - Migrated relevant code from xSQLServerFailoverClusterSetup
  - Removed Get-WmiObject usage
  - Clustered storage mapping now supports asymmetric cluster storage
  - Added support for multi-subnet clusters
  - Added localized error messages for cluster object mapping
  - Updated README.md to reflect new parameters
- Updated description for xSQLServerFailoverClusterSetup to indicate it is deprecated.
- xPDT helper module
  - Function GetxPDTVariable was removed since it no longer was used by any resources.
  - File xPDT.xml was removed since it was not used by any resources, and did not provide any value to the module.
- Changes xSQLServerHelper moduled
  - Removed the globally defined `$VerbosePreference = 'Continue'` from xSQLServerHelper.
  - Fixed a typo in a variable name in the function New-ListenerADObject.
  - Now Restart-SqlService will correctly show the services it restarts. Also fixed PSSA warnings.

## 4.0.0.0

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
  - BREAKING CHANGE: The mandatory parameters now include Ensure, SQLServer, and SQLInstanceName. SQLServer and SQLInstanceName are keys which will be used to uniquely identify the resource which allows AlwaysOn to be enabled on multiple instances on the same machine.
- Moved Restart-SqlService from MSFT_xSQLServerConfiguration.psm1 to xSQLServerHelper.psm1.

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
