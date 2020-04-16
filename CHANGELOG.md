# Change log for SqlServerDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

## [Unreleased]

### Changed

- SqlServerLogin
  - The parameter `ServerName` is now non-mandatory and defaults to `$env:COMPUTERNAME`
    ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
- SqlServerRole
  - The parameter `ServerName` is now non-mandatory and defaults to `$env:COMPUTERNAME`
    ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
- SqlServiceAccount
  - The parameter `ServerName` is now non-mandatory and defaults to `$env:COMPUTERNAME`
    ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).

## [13.5.0] - 2020-04-12

### Added

- SqlServerLogin
  - Added `DefaultDatabase` parameter ([issue #1474](https://github.com/dsccommunity/SqlServerDsc/issues/1474)).

### Changed

- SqlServerDsc
  - Update the CI pipeline files.
  - Only run CI pipeline on branch `master` when there are changes to files
    inside the `source` folder.
  - Replaced Microsoft-hosted agent (build image) `win1803` with `windows-2019`
    ([issue #1466](https://github.com/dsccommunity/SqlServerDsc/issues/1466)).

### Fixed

- SqlSetup
  - Refresh PowerShell drive list before attempting to resolve `setup.exe` path
    ([issue #1482](https://github.com/dsccommunity/SqlServerDsc/issues/1482)).
- SqlAG
  - Fix hashtables to align with style guideline ([issue #1437](https://github.com/PowerShell/SqlServerDsc/issues/1437)).

## [13.4.0] - 2020-03-18

### Added

- SqlDatabase
  - Added ability to manage the Compatibility Level and Recovery Model of a database

### Changed

- SqlServerDsc
  - Azure Pipelines will no longer trigger on changes to just the CHANGELOG.md
    (when merging to master).
  - The deploy step is no longer run if the Azure DevOps organization URL
    does not contain 'dsccommunity'.
  - Changed the VS Code project settings to trim trailing whitespace for
    markdown files too.

## [13.3.0] - 2020-01-17

### Added

- SqlServerDsc
  - Added continuous delivery with a new CI pipeline.
    - Update build.ps1 from latest template.

### Changed

- SqlServerDsc
  - Add .gitattributes file to checkout file correctly with CRLF.
  - Updated .vscode/analyzersettings.psd1 file to correct use PSSA rules
    and custom rules in VS Code.
  - Fix hashtables to align with style guideline ([issue #1437](https://github.com/dsccommunity/SqlServerDsc/issues/1437)).
  - Updated most examples to remove the need for the variable `$ConfigurationData`,
    and fixed style issues.
  - Ignore commit in `GitVersion.yml` to force the correct initial release.
  - Set a display name on all the jobs and tasks in the CI pipeline.
  - Removing file 'Tests.depend.ps1' as it is no longer required.
- SqlServerMaxDop
  - Fix line endings in code which did not use the correct format.
- SqlAlwaysOnService
  - The integration test has been temporarily disabled because when
    the cluster feature is installed it requires a reboot on the
    Windows Server 2019 build worker.
- SqlDatabaseRole
  - Update unit test to have the correct description on the `Describe`-block
    for the test of `Set-TargetResource`.
- SqlServerRole
  - Add support for nested role membership ([issue #1452](https://github.com/dsccommunity/SqlServerDsc/issues/1452))
  - Removed use of case-sensitive Contains() function when evalutating role membership.
    ([issue #1153](https://github.com/dsccommunity/SqlServerDsc/issues/1153))
  - Refactored mocks and unit tests to increase performance. ([issue #979](https://github.com/dsccommunity/SqlServerDsc/issues/979))

### Fixed

- SqlServerDsc
  - Fixed unit tests to call the function `Invoke-TestSetup` outside the
    try-block.
  - Update GitVersion.yml with the correct regular expression.
  - Fix import statement in all tests, making sure it throws if module
    DscResource.Test cannot be imported.
- SqlAlwaysOnService
  - When failing to enable AlwaysOn the resource should now fail with an
    error ([issue #1190](https://github.com/dsccommunity/SqlServerDsc/issues/1190)).
- SqlAgListener
  - Fix IPv6 addresses failing Test-TargetResource after listener creation.
