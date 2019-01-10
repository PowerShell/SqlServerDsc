@{
  # Version number of this module.
  moduleVersion = '12.2.0.0'

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
  - During testing in AppVeyor the Build Worker is restarted in the install
    step to make sure the are no residual changes left from a previous SQL
    Server install on the Build Worker done by the AppVeyor Team
    ([issue 1260](https://github.com/PowerShell/SqlServerDsc/issues/1260)).
  - Code cleanup: Change parameter names of Connect-SQL to align with resources.
  - Updated README.md in the Examples folder.
    - Added a link to the new xADObjectPermissionEntry examples in
      ActiveDirectory, fixed a broken link and a typo.
      [Adam Rush (@adamrushuk)](https://github.com/adamrushuk)
- Change to SqlServerLogin so it doesn"t check properties for absent logins.
  - Fix for ([issue 1096](https://github.com/PowerShell/SqlServerDsc/issues/1096))

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }



















