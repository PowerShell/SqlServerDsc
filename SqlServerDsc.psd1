@{
  # Version number of this module.
  moduleVersion = '12.1.0.0'

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
  - Add support for validating the code with the DSC ResourceKit
    Script Analyzer rules, both in Visual Studio Code and directly using
    `Invoke-ScriptAnalyzer`.
  - Opt-in for common test "Common Tests - Validate Markdown Links".
  - Updated broken links in `\README.md` and in `\Examples\README.md`
  - Opt-in for common test "Common Tests - Relative Path Length".
  - Updated the Installation section in the README.md.
  - Updated the Contributing section in the README.md after
    [Style Guideline and Best Practices guidelines](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md)
    has merged into one document.
  - To speed up testing in AppVeyor, unit tests are now run in two containers.
  - Adding the PowerShell script `Assert-TestEnvironment.ps1` which
    must be run prior to running any unit tests locally with
    `Invoke-Pester`.
    Read more in the specific contributing guidelines, under the section
    [Unit Tests](https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.mdunit-tests).
- Changes to SqlServerDscHelper
  - Fix style guideline lint errors.
  - Changes to Connect-SQL
    - Adding verbose message in Connect-SQL so it
      now shows the username that is connecting.
  - Changes to Import-SQLPS
    - Fixed so that when importing SQLPS it imports
      using the path (and not the .psd1 file).
    - Fixed so that the verbose message correctly
      shows the name, version and path when importing
      the module SQLPS (it did show correctly for the
      SqlServer module).
- Changes to SqlAg, SqlAGDatabase, and SqlAGReplica examples
  - Included configuration for SqlAlwaysOnService to enable
    HADR on each node to avoid confusion
    ([issue 1182](https://github.com/PowerShell/SqlServerDsc/issues/1182)).
- Changes to SqlServerDatabaseMail
  - Minor update to Ensure parameter description in the README.md.
- Changes to Write-ModuleStubFile.ps1
  - Create aliases for cmdlets in the stubbed module which have aliases
    ([issue 1224](https://github.com/PowerShell/SqlServerDsc/issues/1224)).
    [Dan Reist (@randomnote1)](https://github.com/randomnote1)
  - Use a string builder to build the function stubs.
  - Fixed formatting issues for the function to work with modules other
    than SqlServer.
- New DSC resource SqlServerSecureConnection
  - New resource to configure a SQL Server instance for encrypted SQL
    connections.
- Changes to SqlAlwaysOnService
  - Updated integration tests to use NetworkingDsc
    ([issue 1129](https://github.com/PowerShell/SqlServerDsc/issues/1129)).
- Changes to SqlServiceAccount
  - Fix unit tests that didn"t mock some of the calls. It no longer fail
    when a SQL Server installation is not present on the node running the
    unit test ([issue 983](https://github.com/PowerShell/SqlServerDsc/issues/983)).

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }


















