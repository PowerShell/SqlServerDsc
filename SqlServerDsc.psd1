@{
  # Version number of this module.
  moduleVersion = '11.1.0.0'

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
  - Updated the PULL\_REQUEST\_TEMPLATE with an improved task list and modified
    some text to be clearer ([issue 973](https://github.com/PowerShell/SqlServerDsc/issues/973)).
  - Updated the ISSUE_TEMPLATE to hopefully be more intuitive and easier to use.
  - Added information to ISSUE_TEMPLATE that issues must be reproducible in
    SqlServerDsc resource module (if running the older xSQLServer resource module)
    ([issue 1036](https://github.com/PowerShell/SqlServerDsc/issues/1036)).
  - Updated ISSUE_TEMPLATE.md with a note about sensitive information ([issue 1092](https://github.com/PowerShell/SqlServerDsc/issues/1092)).
- Changes to SqlServerLogin
  - [Claudio Spizzi (@claudiospizzi)](https://github.com/claudiospizzi): Fix password
    test fails for nativ sql users ([issue 1048](https://github.com/PowerShell/SqlServerDsc/issues/1048)).
- Changes to SqlSetup
  - [Michael Fyffe (@TraGicCode)](https://github.com/TraGicCode): Clarify usage
    of "SecurityMode" along with adding parameter validations for the only 2
    supported values ([issue 1010](https://github.com/PowerShell/SqlServerDsc/issues/1010)).
  - Now accounts containing "$" will be able to be used for installing
    SQL Server. Although, if the account ends with "$" it is considered a
    Managed Service Account ([issue 1055](https://github.com/PowerShell/SqlServerDsc/issues/1055)).
- Changes to Integration Tests
  - [Michael Fyffe (@TraGicCode)](https://github.com/TraGicCode): Replace xStorage
    dsc resource module with StorageDsc ([issue 1038](https://github.com/PowerShell/SqlServerDsc/issues/1038)).
- Changes to Unit Tests
  - [Michael Fyffe (@TraGicCode)](https://github.com/TraGicCode): Updated
    the following resources unit test template to version 1.2.1
    - SqlAlias ([issue 999](https://github.com/PowerShell/SqlServerDsc/issues/999)).
    - SqlWindowsFirewall ([issue 1089](https://github.com/PowerShell/SqlServerDsc/issues/1089)).

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }













