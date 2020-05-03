# Change log for SqlServerDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

## [Unreleased]

### Removed

- SqlServerDsc
  - BREAKING CHANGE: Removed resource _SqlServerNetwork_. The functionality
    is now covered by the resources _SqlServerProtocol_ and _SqlServerProtocolTcpIp_.

### Added

- SqlServerDsc
  - Added new resource SqlServerProtocol ([issue #1377](https://github.com/dsccommunity/SqlServerDsc/issues/1377)).
  - Added new resource SqlServerProtocolTcpIp ([issue #1378](https://github.com/dsccommunity/SqlServerDsc/issues/1378)).
- SqlSetup
  - A read only property `IsClustered` was added that can be used to determine
    if the instance is clustered.
  - Added the properties `NpEnabled` and `TcpEnabled` ([issue #1161](https://github.com/dsccommunity/SqlServerDsc/issues/1161)).
- SqlServerDsc.Common
  - The helper function `Restart-SqlService` was improved to handle Failover
    Clusters better. Now the SQL Server service will only be taken offline
    and back online again if the service is online to begin with.
  - The helper function `Restart-SqlServer` learned the new parameter
    `OwnerNode`. The parameter `OwnerNode` takes an array of Cluster node
    names. Using this parameter the cluster group will only be taken
    offline and back online if the cluster group owner is one specified
    in this parameter.

### Changed

- SqlServerDsc
  - Changed all resource prefixes from `MSFT_` to `DSC_` ([issue #1496](https://github.com/dsccommunity/SqlServerDsc/issues/1496)).
  - All resources are now using the common module DscResource.Common.
  - When a PR is labelled with 'ready for merge' it is no longer being
    marked as stale if the PR is not merged for 30 days (for example it is
    dependent on something else) ([issue #1504](https://github.com/dsccommunity/SqlServerDsc/issues/1504)).
  - Updated the CI pipeline to use latest version of the module ModuleBuilder.
  - Changed to use the property `NuGetVersionV2` from GitVersion in the
    CI pipeline.
- SqlAlwaysOnService
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlDatabase
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlDatabaseDefaultLocation
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlDatabaseOwner
  - BREAKING CHANGE: Database changed to DatabaseName for consistency with
    other modules ([issue #1484](https://github.com/dsccommunity/SqlServerDsc/issues/1484)).
- SqlDatabasePermission
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
  - BREAKING CHANGE: Database changed to DatabaseName for consistency with
    other modules ([issue #1484](https://github.com/dsccommunity/SqlServerDsc/issues/1484)).
- SqlDatabaseRecoveryModel
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlDatabaseRole
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
  - BREAKING CHANGE: Database changed to DatabaseName for consistency with
    other modules ([issue #1484](https://github.com/dsccommunity/SqlServerDsc/issues/1484)).
- SqlDatabaseUser
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlServerConfiguration
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlServerDatabaseMail
  - Normalize parameter descriptive text for default values.
- SqlServerEndpoint
  - Normalize parameter descriptive text for default values.
- SqlServerEndpointPermission
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlServerLogin
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlServerRole
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.
- SqlServiceAccount
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory and
    defaults to `$env:COMPUTERNAME` ([issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
  - Normalize parameter descriptive text for default values.

### Fixed

- SqlServerDsc
  - The regular expression for `minor-version-bump-message` in the file
    `GitVersion.yml` was changed to only raise minor version when the
    commit message contain the word `add`, `adds`, `minor`, `feature`,
    or `features`.
  - Now code coverage is reported to Codecov, and a codecov.yml was added.
  - Updated to support DscResource.Common v0.7.1.
- SqlSetup
  - The property `SqlTempdbLogFileGrowth` and `SqlTempdbFileGrowth` now returns
    the correct values. Previously the value of the growth was wrongly
    divided by 1KB even if the value was in percent. Now the value for growth
    is the sum of the average of MB and average of the percentage.
  - The function `Get-TargetResource` was changed so that the property
    `SQLTempDBDir` will now return the database `tempdb`'s property
    `PrimaryFilePath`.
  - BREAKING CHANGE: Logic that was under feature flag `DetectionSharedFeatures`
    was made the default and old logic that was used to detect shared features
    was removed ([issue #1290](https://github.com/dsccommunity/SqlServerDsc/issues/1290)).
    This was implemented because the previous implementation did not work
    fully with SQL Server 2017.
  - Much of the code was refactored into units (functions) to be easier to test.
    Due to the size of the code the unit tests ran for an abnormal long time,
    after this refactoring the unit tests runs much quicker.
- README.md
  - Changed to point to CONTRIBUTING.md on master branch to avoid "404 Page not found"
    ([issue #1508](https://github.com/dsccommunity/SqlServerDsc/issues/1508)).
- SqlAlias
  - BREAKING CHANGE: The parameter `ServerName` is now non-mandatory to
    prevent ping-pong behavior ([issue #1502](https://github.com/dsccommunity/SqlServerDsc/issues/1502)).
    The `ServerName` is not returned as an empty string when the protocol is
    Named Pipes.
- SqlRs
  - Fix typo in the schema parameter `SuppressRestart` description
    and in the parameter description in the `README.md`.
- SqlSetup
  - Update integration tests to correctly detect sysadmins because of changes
    to the build worker.
- SqlAgentAlert
  - The parameter `ServerName` now throws when passing an empty string or
    null value (part of [issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
- SqlAgentFailsafe
  - The parameter `ServerName` now throws when passing an empty string or
    null value (part of [issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
- SqlAgentOperator
  - The parameter `ServerName` now throws when passing an empty string or
    null value (part of [issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
- SqlServerDatabaseMail
  - The parameter `ServerName` now throws when passing an empty string or
    null value (part of [issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
- SqlServerEndpoint
  - The parameter `ServerName` now throws when passing an empty string or
    null value (part of [issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
- SqlServerEndpointState
  - The parameter `ServerName` now throws when passing an empty string or
    null value (part of [issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).
- SqlServerPermission
  - The parameter `ServerName` now throws when passing an empty string or
    null value (part of [issue #319](https://github.com/dsccommunity/SqlServerDsc/issues/319)).

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
