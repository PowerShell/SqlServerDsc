@{
# Version number of this module.
ModuleVersion = '8.2.0.0'

# ID used to uniquely identify this module
GUID = '74e9ddb5-4cbc-4fa2-a222-2bcfb533fd66'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2017 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module with DSC Resources for deployment and configuration of Microsoft SQL Server.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

RequiredAssemblies = @()

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
        ReleaseNotes = '- Changes to xSQLServer
  - Updated appveyor.yml so that integration tests run in order and so that
    the SQLPS module folders are renamed to not disturb the units test, but
    can be renamed back by the integration tests xSQLServerSetup so that the
    integration tests can run successfully
    ([issue 774](https://github.com/PowerShell/xFailOverCluster/issues/774)).
  - Changed so the maximum version to be installed is 4.0.6.0, when running unit
    tests in AppVeyor. Quick fix until we can resolve the unit tests (see
    [issue 807](https://github.com/PowerShell/xFailOverCluster/issues/807)).
  - Moved the code block, that contains workarounds in appveyor.yml, so it is run
    during the install phase instead of the test phase.
  - Fix problem with tests breaking with Pester 4.0.7 ([issue 807](https://github.com/PowerShell/xFailOverCluster/issues/807)).
- Changes to xSQLServerHelper
  - Changes to Connect-SQL and Import-SQLPSModule
    - Now it correctly loads the correct assemblies when SqlServer module is
      present ([issue 649](https://github.com/PowerShell/xFailOverCluster/issues/649)).
    - Now SQLPS module will be correctly loaded (discovered) after installation
      of SQL Server. Previously resources depending on SQLPS module could fail
      because SQLPS was not found after installation because the PSModulePath
      environment variable in the (LCM) PowerShell session did not contain the new
      module path.
  - Added new helper function "Test-ClusterPermissions" ([issue 446](https://github.com/PowerShell/xSQLServer/issues/446)).
- Changes to xSQLServerSetup
  - Fixed an issue with trailing slashes in the "UpdateSource" property
    ([issue 720](https://github.com/PowerShell/xSQLServer/issues/720)).
  - Fixed so that the integration test renames back the SQLPS module folders if
    they was renamed by AppVeyor (in the appveyor.yml file)
    ([issue 774](https://github.com/PowerShell/xFailOverCluster/issues/774)).
  - Fixed so integration test does not write warnings when SQLPS module is loaded
    ([issue 798](https://github.com/PowerShell/xFailOverCluster/issues/798)).
  - Changes to integration tests.
    - Moved the configuration block from the MSFT\_xSQLServerSetup.Integration.Tests.ps1
      to the MSFT\_xSQLServerSetup.config.ps1 to align with the other integration
      test. And also get most of the configuration in one place.
    - Changed the tests so that the local SqlInstall account is added as a member
      of the local administrators group.
    - Changed the tests so that the local SqlInstall account is added as a member
      of the system administrators in SQL Server (Database Engine) - needed for the
      xSQLServerAlwaysOnService integration tests.
    - Changed so that only one of the Modules-folder for the SQLPS PowerShell module
      for SQL Server 2016 is renamed back so it can be used with the integration
      tests. There was an issue when more than one SQLPS module was present (see
      more information in [issue 806](https://github.com/PowerShell/xFailOverCluster/issues/806)).
    - Fixed wrong variable name for SQL service credential. It was using the
      integration test variable name instead of the parameter name.
    - Added ErrorAction "Stop" to the cmdlet Start-DscConfiguration
      ([issue 824](https://github.com/PowerShell/xSQLServer/issues/824)).
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Change the check of the values entered as parameter for
    BasicAvailabilityGroup. It is a boolean, hence it was not possible to
    disable the feature.
  - Add possibility to enable/disable the feature DatabaseHealthTrigger
    (SQL Server 2016 or later only).
  - Add possibility to enable the feature DtcSupportEnabled (SQL Server 2016 or
    later only). The feature currently can"t be altered once the Availability
    Group is created.
  - Use the new helper function "Test-ClusterPermissions".
  - Refactored the unit tests to allow them to be more user friendly.
    Added the following read-only properties to the schema ([issue 476](https://github.com/PowerShell/xSQLServer/issues/476))
    - EndpointPort
    - EndpointURL
    - SQLServerNetName
    - Version
  - Use the Get-PrimaryReplicaServerObject helper function
- Changes to xSQLServerAlwaysOnAvailabilityGroupReplica
  - Fixed the formatting for the AvailabilityGroupNotFound error.
  - Added the following read-only properties to the schema ([issue 477](https://github.com/PowerShell/xSQLServer/issues/477))
    - EndpointPort
    - EndpointURL
  - Use the new helper function "Test-ClusterPermissions".
  - Use the Get-PrimaryReplicaServerObject helper function
- Changes to xSQLServerHelper
  - Fixed Connect-SQL by ensuring the Status property returns "Online" prior to
    returning the SQL Server object ([issue 333](https://github.com/PowerShell/xSQLServer/issues/333)).
- Changes to xSQLServerRole
  - Running Get-DscConfiguration no longer throws an error saying property
    Members is not an array ([issue 790](https://github.com/PowerShell/xSQLServer/issues/790)).
- Changes to xSQLServerMaxDop
  - Fixed error where Measure-Object cmdlet would fail claiming it could not
    find the specified property ([issue 801](https://github.com/PowerShell/xSQLServer/issues/801))
- Changes to xSQLServerAlwaysOnService
  - Added integration test ([issue 736](https://github.com/PowerShell/xSQLServer/issues/736)).
    - Added ErrorAction "Stop" to the cmdlet Start-DscConfiguration
      ([issue 824](https://github.com/PowerShell/xSQLServer/issues/824)).
- Changes to SMO.cs
  - Added default properties to the Server class
    - AvailabilityGroups
    - Databases
    - EndpointCollection
  - Added a new overload to the Login class
  - Added default properties to the AvailabilityReplicas class
    - AvailabilityDatabases
    - AvailabilityReplicas
- Added new resource xSQLServerAccount ([issue 706](https://github.com/PowerShell/xSQLServer/issues/706))
  - Added localization support for all strings
  - Added examples for usage
- Changes to SqlRS
  - No longer returns a null value from Test-TargetResource when Reporting
    Services has not been initialized ([issue 822](https://github.com/PowerShell/xSQLServer/issues/822)).
  - Fixed so that when two Reporting Services are installed for the same major
    version the resource does not throw an error ([issue 819](https://github.com/PowerShell/xSQLServer/issues/819)).
  - Now the resource will restart the Reporting Services service after
    initializing ([issue 592](https://github.com/PowerShell/xSQLServer/issues/592)).
    This will enable the Reports site to work.
  - Added integration test ([issue 753](https://github.com/PowerShell/xSQLServer/issues/753)).
  - Added support for configuring URL reservations and virtual directory names
    ([issue 570](https://github.com/PowerShell/xSQLServer/issues/570))

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}
