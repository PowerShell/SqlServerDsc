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
  - Updated Pester syntax to v4
  - Fixes broken links to issues in the CHANGELOG.md.
- Changes to xSQLServerDatabase
  - Added parameter to specify collation for a database to be different from server
    collation ([issue 767](https://github.com/PowerShell/xSQLServer/issues/767)).
  - Fixed unit tests for Get-TargetResource to ensure correctly testing return
    values ([issue 849](https://github.com/PowerShell/xSQLServer/issues/849))
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Refactored the unit tests to allow them to be more user friendly and to test
    additional SQLServer variations.
    - Each test will utilize the Import-SQLModuleStub to ensure the correct
      module is loaded ([issue 784](https://github.com/PowerShell/xSQLServer/issues/784)).
  - Fixed an issue when setting the SQLServer parameter to a Fully Qualified
    Domain Name (FQDN) ([issue 468](https://github.com/PowerShell/xSQLServer/issues/468)).
  - Fixed the logic so that if a parameter is not supplied to the resource, the
    resource will not attempt to apply the defaults on subsequent checks
    ([issue 517](https://github.com/PowerShell/xSQLServer/issues/517)).
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node
    is the active host of the SQL Server instance ([issue 868](https://github.com/PowerShell/xSQLServer/issues/868)).
- Changes to xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node
    is the active host of the SQL Server instance ([issue 869](https://github.com/PowerShell/xSQLServer/issues/869)).
- Changes to xSQLServerAlwaysOnAvailabilityGroupReplica
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node is
    the active host of the SQL Server instance ([issue 870](https://github.com/PowerShell/xSQLServer/issues/870)).
- Added the CommonTestHelper.psm1 to store common testing functions.
  - Added the Import-SQLModuleStub function to ensure the correct version of the
    module stubs are loaded ([issue 784](https://github.com/PowerShell/xSQLServer/issues/784)).
- Changes to xSQLServerMemory
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node
    is the active host of the SQL Server instance ([issue 867](https://github.com/PowerShell/xSQLServer/issues/867)).
- Changes to xSQLServerNetwork
  - BREAKING CHANGE: Renamed parameter TcpDynamicPorts to TcpDynamicPort and
    changed type to Boolean ([issue 534](https://github.com/PowerShell/xSQLServer/issues/534)).
  - Resolved issue when switching from dynamic to static port.
    configuration ([issue 534](https://github.com/PowerShell/xSQLServer/issues/534)).
  - Added localization (en-US) for all strings in resource and unit tests
    ([issue 618](https://github.com/PowerShell/xSQLServer/issues/618)).
  - Updated examples to reflect new parameters.
- Changes to xSQLServerRSConfig
  - Added examples
- Added resource
  - xSQLServerDatabaseDefaultLocation
    ([issue 656](https://github.com/PowerShell/xSQLServer/issues/656))
- Changes to xSQLServerEndpointPermission
  - Fixed a problem when running the tests locally in a PowerShell console it
    would ask for parameters ([issue 897](https://github.com/PowerShell/xSQLServer/issues/897)).
- Changes to xSQLServerAvailabilityGroupListener
  - Fixed a problem when running the tests locally in a PowerShell console it
    would ask for parameters ([issue 897](https://github.com/PowerShell/xSQLServer/issues/897)).
- Changes to xSQLServerMaxDop
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node
    is the active host of the SQL Server instance ([issue 882](https://github.com/PowerShell/xSQLServer/issues/882)).
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











