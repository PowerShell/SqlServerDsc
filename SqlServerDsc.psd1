@{
  # Version number of this module.
  moduleVersion = '11.4.0.0'

  # ID used to uniquely identify this module
  GUID = '693ee082-ed36-45a7-b490-88b07c86b42f'

  # Author of this module
  Author = 'Microsoft Corporation'

  # Company or vendor of this module
  CompanyName = 'Microsoft Corporation'

  # Copyright statement for this module
  Copyright = '(c) 2018 Microsoft Corporation. All rights reserved.'

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
          LicenseUri = 'https://github.com/PowerShell/SqlServerDsc/blob/master/LICENSE'

          # A URL to the main website for this project.
          ProjectUri = 'https://github.com/PowerShell/SqlServerDsc'

          # A URL to an icon representing this module.
          # IconUri = ''

          # ReleaseNotes of this module
        ReleaseNotes = '- Changes to SqlServerDsc
  - Updated helper function Restart-SqlService to have to new optional parameters
    `SkipClusterCheck` and `SkipWaitForOnline`. This was to support more aspects
    of the resource SqlServerNetwork.
  - Updated helper function `Import-SQLPSModule`
    - To only import module if the
      module does not exist in the session.
    - To always import the latest version of "SqlServer" or "SQLPS" module, if
      more than one version exist on the target node. It will still prefer to
      use "SqlServer" module.
  - Updated all the examples and integration tests to not use
    `PSDscAllowPlainTextPassword`, so examples using credentials or
    passwords by default are secure.
- Changes to SqlAlwaysOnService
  - Integration tests was updated to handle new IPv6 addresses on the AppVeyor
    build worker ([issue 1155](https://github.com/PowerShell/SqlServerDsc/issues/1155)).
- Changes to SqlServerNetwork
  - Refactor SqlServerNetwork to not load assembly from GAC ([issue 1151](https://github.com/PowerShell/SqlServerDsc/issues/1151)).
  - The resource now supports restarting the SQL Server service when both
    enabling and disabling the protocol.
  - Added integration tests for this resource
    ([issue 751](https://github.com/PowerShell/SqlServerDsc/issues/751)).
- Changes to SqlAG
  - Removed excess `Import-SQLPSModule` call.
- Changes to SqlSetup
  - Now after a successful install the "SQL PowerShell module" is reevaluated and
    forced to be reimported into the session. This is to support that a never
    version of SQL Server was installed side-by-side so that SQLPS module should
    be used instead.

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }
















