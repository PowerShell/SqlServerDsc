@{
# Version number of this module.
ModuleVersion = '5.0.0.0'

# ID used to uniquely identify this module
GUID = '74e9ddb5-4cbc-4fa2-a222-2bcfb533fd66'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2014 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module with DSC Resources for deployment and configuration of Microsoft SQL Server.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xSQLServer/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xSQLServer'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '- Improvements how tests are initiated in AppVeyor
  - Removed previous workaround (issue 201) from unit tests.
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
  - The example "SetDatabaseOwner" can now compile, it wrongly had a `DependsOn` in the example.
- Changes to SQLServerRole
  - The examples "AddServerRole" and "RemoveServerRole" can now compile, it wrongly had a `DependsOn` in the example.
- Changes to CONTRIBUTING.md
  - Added section "Tests for examples files"
  - Added section "Tests for style check of Markdown files"
  - Added section "Documentation with Markdown"
  - Added texts to section "Tests"
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
  - Removed the globally defined `$VerbosePreference = Continue` from xSQLServerHelper.
  - Fixed a typo in a variable name in the function New-ListenerADObject.
  - Now Restart-SqlService will correctly show the services it restarts. Also fixed PSSA warnings.'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}




