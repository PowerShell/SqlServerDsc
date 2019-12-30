# Change log for SqlServerDsc

## Unreleased

- Changes to SqlServerDsc
  - Add .gitattributes file to checkout file correctly with CRLF.
  - Updated .vscode/analyzersettings.psd1 file to correct use PSSA rules
    and custom rules in VS Code.
  - Fix hashtables to align with style guideline ([issue #1437](https://github.com/PowerShell/SqlServerDsc/issues/1437)).
- Changes to SqlServerMaxDop
  - Fix line endings in code which did not use the correct format.
- Changes to SqlServerRole
  - Add support for nested role membership
  - Removed use of case-sensitive Contains() when evalutating role membership.
    ([issue #1153](https://github.com/dsccommunity/SqlServerDsc/issues/1153))
  - Update unit tests to template 1.2.4
  - Refactored mocks and unit tests to increase performance. ([issue #979](https://github.com/dsccommunity/SqlServerDsc/issues/979))

## 13.2.0.0

- Changes to SqlServerDsc
  - Fix keywords to lower-case to align with guideline.
  - Fix keywords to have space before a parenthesis to align with guideline.
  - Fix typo in SqlSetup strings ([issue #1419](https://github.com/PowerShell/SqlServerDsc/issues/1419)).

## 13.1.0.0

- Changes to SqlServerDsc
  - New DSC resource SqlAgentFailsafe
  - New DSC resource SqlDatabaseUser ([issue #846](https://github.com/PowerShell/SqlServerDsc/issues/846)).
    - Adds ability to create database users with more fine-grained control,
      e.g. re-mapping of orphaned logins or a different login. Supports
      creating a user with or without login name, and database users mapped
      to a certificate or asymmetric key.
  - Changes to helper function Invoke-Query
    - Fixes issues in [issue #1355](https://github.com/PowerShell/SqlServerDsc/issues/1355).
    - Works together with Connect-SQL now.
    - Parameters now match that of Connect-SQL ([issue #1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
    - Can now pass in credentials.
    - Can now pass in 'Microsoft.SqlServer.Management.Smo.Server' object.
    - Can also pipe in 'Microsoft.SqlServer.Management.Smo.Server' object.
    - Can pipe Connect-SQL | Invoke-Query.
    - Added default values to Invoke-Query.
    - Now it will output verbose messages of the query that is run, so it
      not as quiet of what it is doing when a user asks for verbose output
      ([issue #1404](https://github.com/PowerShell/SqlServerDsc/issues/1404)).
    - It is possible to redact text in the verbose output by providing
      strings in the new parameter `RedactText`.
  - Minor style fixes in unit tests.
  - Changes to helper function Connect-SQL
    - When impersonating WindowsUser credential use the NetworkCredential UserName.
    - Added additional verbose logging.
    - Connect-SQL now uses parameter sets to more intuitive evaluate that
      the correct parameters are used in different scenarios
      ([issue #1403](https://github.com/PowerShell/SqlServerDsc/issues/1403)).
  - Changes to helper function Connect-SQLAnalysis
    - Parameters now match that of Connect-SQL ([issue #1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Restart-SqlService
    - Parameters now match that of Connect-SQL ([issue #1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Restart-ReportingServicesService
    - Parameters now match that of Connect-SQL ([issue #1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Split-FullSqlInstanceName
    - Parameters and function name changed to use correct casing.
  - Changes to helper function Get-SqlInstanceMajorVersion
    - Parameters now match that of Connect-SQL ([issue #1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Test-LoginEffectivePermissions
    - Parameters now match that of Connect-SQL ([issue #1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Test-AvailabilityReplicaSeedingModeAutomatic
    - Parameters now match that of Connect-SQL ([issue #1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
- Changes to SqlServerSecureConnection
  - Forced $Thumbprint to lowercase to fix [issue #1350](https://github.com/PowerShell/SqlServerDsc/issues/1350).
  - Add parameter SuppressRestart with default value false.
    This allows users to suppress restarts after changes have been made.
    Changes will not take effect until the service has been restarted.
- Changes to SqlSetup
  - Correct minor style violation [issue #1387](https://github.com/PowerShell/SqlServerDsc/issues/1387).
- Changes to SqlDatabase
  - Get-TargetResource now correctly return `$null` for the collation property
    when the database does not exist ([issue #1395](https://github.com/PowerShell/SqlServerDsc/issues/1395)).
  - No longer enforces the collation property if the Collation parameter
    is not part of the configuration ([issue #1396](https://github.com/PowerShell/SqlServerDsc/issues/1396)).
  - Updated resource description in README.md
  - Fix examples to use `PsDscRunAsCredential` ([issue #760](https://github.com/PowerShell/SqlServerDsc/issues/760)).
  - Added integration tests ([issue #739](https://github.com/PowerShell/SqlServerDsc/issues/739)).
  - Updated unit tests to the latest template ([issue #1068](https://github.com/PowerShell/SqlServerDsc/issues/1068)).

## 13.0.0.0

- Changes to SqlServerDsc
  - Added SqlAgentAlert resource.
  - Opt-in to the common test 'Common Test - Validation Localization'.
  - Opt-in to the common test 'Common Test - Flagged Script Analyzer Rules'
    ([issue #1101](https://github.com/PowerShell/SqlServerDsc/issues/1101)).
  - Removed the helper function `New-TerminatingError`, `New-WarningMessage`
    and `New-VerboseMessage` in favor of the the new
    [localization helper functions](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#localization).
  - Combine DscResource.LocalizationHelper and DscResource.Common into
    SqlServerDsc.Common ([issue #1357](https://github.com/PowerShell/SqlServerDsc/issues/1357)).
  - Update Assert-TestEnvironment.ps1 to not error if strict mode is enabled
    and there are no missing dependencies ([issue #1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).
- Changes to SqlServerDsc.Common
  - Added StatementTimeout to function 'Connect-SQL' with default 600 seconds (10mins).
  - Added StatementTimeout to function 'Invoke-Query' with default 600 seconds (10mins)
    ([issue #1358](https://github.com/PowerShell/SqlServerDsc/issues/1358)).
  - Changes to helper function Connect-SQL
    - The function now make it more clear that when using the parameter
      `SetupCredential` is impersonates that user, and by default it does
      not impersonates a user but uses the credential that the resource
      is run as (for example the built-in credential parameter
      `PsDscRunAsCredential`). [@kungfu71186](https://github.com/kungfu71186)
    - Added parameter alias `-DatabaseCredential` for the parameter
      `-SetupCredential`. [@kungfu71186](https://github.com/kungfu71186)
- Changes to SqlAG
  - Added en-US localization.
- Changes to SqlAGReplica
  - Added en-US localization.
  - Improved verbose message output when creating availability group replica,
    removing a availability group replica, and joining the availability
    group replica to the availability group.
- Changes to SqlAlwaysOnService
  - Now outputs the correct verbose message when restarting the service.
- Changes to SqlServerMemory
  - Now outputs the correct verbose messages when calculating the dynamic
    memory, and when limiting maximum memory.
- Changes to SqlServerRole
  - Now outputs the correct verbose message when the members of a role is
    not in desired state.
- Changes to SqlAgentOperator
  - Fix minor issue that when unable to connect to an instance. Instead
    of showing a message saying that connect failed another unrelated
    error message could have been shown, because of an error in the code.
  - Fix typo in test it block.
- Changes to SqlDatabaseRole
  - BREAKING CHANGE: Refactored to enable creation/deletion of the database role
    itself as well as management of the role members. *Note that the resource no
    longer adds database users.* ([issue #845](https://github.com/PowerShell/SqlServerDsc/issues/845),
    [issue #847](https://github.com/PowerShell/SqlServerDsc/issues/847),
    [issue #1252](https://github.com/PowerShell/SqlServerDsc/issues/1252),
    [issue #1339](https://github.com/PowerShell/SqlServerDsc/issues/1339)).
    [Paul Shamus @pshamus](https://github.com/pshamus)
- Changes to SqlSetup
  - Add an Action type of 'Upgrade'. This will ask setup to do a version
    upgrade where possible ([issue #1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).
  - Fix an error when testing for DQS installation ([issue #1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).
  - Changed the logic of how default value of FailoverClusterGroupName is
    set since that was preventing the resource to be able to be debugged
    ([issue #448](https://github.com/PowerShell/SqlServerDsc/issues/448)).
  - Added RSInstallMode parameter ([issue #1163](https://github.com/PowerShell/SqlServerDsc/issues/1163)).
- Changes to SqlWindowsFirewall
  - Where a version upgrade has changed paths for a database engine, the
    existing firewall rule for that instance will be updated rather than
    another one created ([issue #1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).
    Other firewall rules can be fixed to work in the same way later.
- Changes to SqlAGDatabase
  - Added new parameter 'ReplaceExisting' with default false.
    This allows forced restores when a database already exists on secondary.
  - Added StatementTimeout to Invoke-Query to fix Issue#1358
  - Fix issue where calling Get would return an error because the database
    name list may have been returned as a string instead of as a string array
    ([issue #1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).

## 12.5.0.0

- Changes to SqlServerSecureConnection
  - Updated README and added example for SqlServerSecureConnection,
    instructing users to use the 'SYSTEM' service account instead of
    'LocalSystem'.
- Changes to SqlScript
  - Correctly passes the `$VerbosePreference` to the helper function
    `Invoke-SqlScript` so that `PRINT` statements is outputted correctly
    when verbose output is requested, e.g
    `Start-DscConfiguration -Verbose`.
  - Added en-US localization ([issue #624](https://github.com/PowerShell/SqlServerDsc/issues/624)).
  - Added additional unit tests for code coverage.
- Changes to SqlScriptQuery
  - Correctly passes the `$VerbosePreference` to the helper function
    `Invoke-SqlScript` so that `PRINT` statements is outputted correctly
    when verbose output is requested, e.g
    `Start-DscConfiguration -Verbose`.
  - Added en-US localization.
  - Added additional unit tests for code coverage.
- Changes to SqlSetup
  - Concatenated Robocopy localization strings ([issue #694](https://github.com/PowerShell/SqlServerDsc/issues/694)).
  - Made the error message more descriptive when the Set-TargetResource
    function calls the Test-TargetResource function to verify the desired
    state.
- Changes to SqlWaitForAG
  - Added en-US localization ([issue #625](https://github.com/PowerShell/SqlServerDsc/issues/625)).
- Changes to SqlServerPermission
  - Added en-US localization ([issue #619](https://github.com/PowerShell/SqlServerDsc/issues/619)).
- Changes to SqlServerMemory
  - Added en-US localization ([issue #617](https://github.com/PowerShell/SqlServerDsc/issues/617)).
  - No longer will the resource set the MinMemory value if it was provided
    in a configuration that also set the `Ensure` parameter to 'Absent'
    ([issue #1329](https://github.com/PowerShell/SqlServerDsc/issues/1329)).
  - Refactored unit tests to simplify them add add slightly more code
    coverage.
- Changes to SqlServerMaxDop
  - Added en-US localization ([issue #616](https://github.com/PowerShell/SqlServerDsc/issues/616)).
- Changes to SqlRS
  - Reporting Services are restarted after changing settings, unless
    `$SuppressRestart` parameter is set ([issue #1331](https://github.com/PowerShell/SqlServerDsc/issues/1331)).
    `$SuppressRestart` will also prevent Reporting Services restart after initialization.
  - Fixed one of the error handling to use localization, and made the
    error message more descriptive when the Set-TargetResource function
    calls the Test-TargetResource function to verify the desired
    state. *This was done prior to adding full en-US localization.*
  - Fixed ([issue #1258](https://github.com/PowerShell/SqlServerDsc/issues/1258)).
    When initializing Reporting Services, there is no need to execute `InitializeReportServer`
    CIM method, since executing `SetDatabaseConnection` CIM method initializes
    Reporting Services.
  - [issue #864](https://github.com/PowerShell/SqlServerDsc/issues/864) SqlRs
    can now initialise SSRS 2017 instances
- Changes to SqlServerLogin
  - Added en-US localization ([issue #615](https://github.com/PowerShell/SqlServerDsc/issues/615)).
  - Added unit tests to improved code coverage.
- Changes to SqlWindowsFirewall
  - Added en-US localization ([issue #614](https://github.com/PowerShell/SqlServerDsc/issues/614)).
- Changes to SqlServerEndpoint
  - Added en-US localization ([issue #611](https://github.com/PowerShell/SqlServerDsc/issues/611)).
- Changes to SqlServerEndpointPermission
  - Added en-US localization ([issue #612](https://github.com/PowerShell/SqlServerDsc/issues/612)).
- Changes to SqlServerEndpointState
  - Added en-US localization ([issue #613](https://github.com/PowerShell/SqlServerDsc/issues/613)).
- Changes to SqlDatabaseRole
  - Added en-US localization ([issue #610](https://github.com/PowerShell/SqlServerDsc/issues/610)).
- Changes to SqlDatabaseRecoveryModel
  - Added en-US localization ([issue #609](https://github.com/PowerShell/SqlServerDsc/issues/609)).
- Changes to SqlDatabasePermission
  - Added en-US localization ([issue #608](https://github.com/PowerShell/SqlServerDsc/issues/608)).
- Changes to SqlDatabaseOwner
  - Added en-US localization ([issue #607](https://github.com/PowerShell/SqlServerDsc/issues/607)).
- Changes to SqlDatabase
  - Added en-US localization ([issue #606](https://github.com/PowerShell/SqlServerDsc/issues/606)).
- Changes to SqlAGListener
  - Added en-US localization ([issue #604](https://github.com/PowerShell/SqlServerDsc/issues/604)).
- Changes to SqlAlwaysOnService
  - Added en-US localization ([issue #603](https://github.com/PowerShell/SqlServerDsc/issues/608)).
- Changes to SqlAlias
  - Added en-US localization ([issue #602](https://github.com/PowerShell/SqlServerDsc/issues/602)).
  - Removed ShouldProcess for the code, since it has no purpose in a DSC
    resource ([issue #242](https://github.com/PowerShell/SqlServerDsc/issues/242)).
- Changes to SqlServerReplication
  - Added en-US localization ([issue #620](https://github.com/PowerShell/SqlServerDsc/issues/620)).
  - Refactored Get-TargetResource slightly so it provide better verbose
    messages.

## 12.4.0.0

- Changes to SqlServerDsc
  - Added new resources.
    - SqlRSSetup
  - Added helper module DscResource.Common from the repository
    DscResource.Template.
    - Moved all helper functions from SqlServerDscHelper.psm1 to DscResource.Common.
    - Renamed Test-SqlDscParameterState to Test-DscParameterState.
    - New-TerminatingError error text for a missing localized message now matches
      the output even if the "missing localized message" localized message is
      also missing.
  - Added helper module DscResource.LocalizationHelper from the repository
    DscResource.Template, this replaces the helper module CommonResourceHelper.psm1.
  - Cleaned up unit tests, mostly around loading cmdlet stubs and loading
    classes stubs, but also some tests that were using some odd variants.
  - Fix all integration tests according to issue [PowerShell/DscResource.Template#14](https://github.com/PowerShell/DscResource.Template/issues/14).
- Changes to SqlServerMemory
  - Updated Cim Class to Win32_ComputerSystem (instead of Win32_PhysicalMemory)
    because the correct memory size was not being detected correctly on Azure VMs
    ([issue #914](https://github.com/PowerShell/SqlServerDsc/issues/914)).
- Changes to SqlSetup
  - Split integration tests into two jobs, one for running integration tests
    for SQL Server 2016 and another for running integration test for
    SQL Server 2017 ([issue #858](https://github.com/PowerShell/SqlServerDsc/issues/858)).
  - Localized messages for Master Data Services no longer start and end with
    single quote.
  - When installing features a verbose message is written if a feature is found
    to already be installed. It no longer quietly removes the feature from the
    `/FEATURES` argument.
  - Cleaned up a bit in the tests, removed excessive piping.
  - Fixed minor typo in examples.
  - A new optional parameter `FeatureFlag` parameter was added to control
    breaking changes. Functionality added under a feature flag can be
    toggled on or off, and could be changed later to be the default.
    This way we can also make more of the new functionalities the default
    in the same breaking change release ([issue #1105](https://github.com/PowerShell/SqlServerDsc/issues/1105)).
  - Added a new way of detecting if the shared feature CONN (Client Tools
    Connectivity, and SQL Client Connectivity SDK), BC (Client Tools
    Backwards Compatibility), and SDK (Client Tools SDK) is installed or
    not. The new functionality is used when the parameter `FeatureFlag`
    is set to `'DetectionSharedFeatures'` ([issue #1105](https://github.com/PowerShell/SqlServerDsc/issues/1105)).
  - Added a new helper function `Get-InstalledSharedFeatures` to move out
    some of the code from the `Get-TargetResource` to make unit testing
    easier and faster.
  - Changed the logic of 'Build the argument string to be passed to setup' to
    not quote the value if root directory is specified
    ([issue #1254](https://github.com/PowerShell/SqlServerDsc/issues/1254)).
  - Moved some resource specific helper functions to the new helper module
    DscResource.Common so they can be shared with the new resource SqlRSSetup.
  - Improved verbose messages in Test-TargetResource function to more
    clearly tell if features are already installed or not.
  - Refactored unit tests for the functions Test-TargetResource and
    Set-TargetResource to improve testing speed.
  - Modified the Test-TargetResource and Set-TargetResource to not be
    case-sensitive when comparing feature names. *This was handled
    correctly in real-world scenarios, but failed when running the unit
    tests (and testing casing).*
- Changes to SqlAGDatabase
  - Fix MatchDatabaseOwner to check for CONTROL SERVER, IMPERSONATE LOGIN, or
    CONTROL LOGIN permission in addition to IMPERSONATE ANY LOGIN.
  - Update and fix MatchDatabaseOwner help text.
- Changes to SqlAG
  - Updated documentation on the behaviour of defaults as they only apply when
    creating a group.
- Changes to SqlAGReplica
  - AvailabilityMode, BackupPriority, and FailoverMode defaults only apply when
    creating a replica not when making changes to an existing replica. Explicit
    parameters will still change existing replicas ([issue #1244](https://github.com/PowerShell/SqlServerDsc/issues/1244)).
  - ReadOnlyRoutingList now gets updated without throwing an error on the first
    run ([issue #518](https://github.com/PowerShell/SqlServerDsc/issues/518)).
  - Test-Resource fixed to report whether ReadOnlyRoutingList desired state
    has been reached correctly ([issue #1305](https://github.com/PowerShell/SqlServerDsc/issues/1305)).
- Changes to SqlDatabaseDefaultLocation
  - No longer does the Test-TargetResource fail on the second test run
    when the backup file path was changed, and the path was ending with
    a backslash ([issue #1307](https://github.com/PowerShell/SqlServerDsc/issues/1307)).

## 12.3.0.0

- Changes to SqlServerDsc
  - Reverting the change that was made as part of the
    [issue #1260](https://github.com/PowerShell/SqlServerDsc/issues/1260)
    in the previous release, as it only mitigated the issue, it did not
    solve the issue.
  - Removed the container testing since that broke the integration tests,
    possible due to using excessive amount of memory on the AppVeyor build
    worker. This will make the unit tests to take a bit longer to run
    ([issue #1260](https://github.com/PowerShell/SqlServerDsc/issues/1260)).
  - The unit tests and the integration tests are now run in two separate
    build workers in AppVeyor. One build worker runs the integration tests,
    while a second build worker runs the unit tests. The build workers runs
    in parallel on paid accounts, but sequentially on free accounts
    ([issue #1260](https://github.com/PowerShell/SqlServerDsc/issues/1260)).
  - Clean up error handling in some of the integration tests that was
    part of a workaround for a bug in Pester. The bug is resolved, and
    the error handling is not again built into Pester.
  - Speeding up the AppVeyor tests by splitting the common tests in a
    separate build job.
  - Updated the appveyor.yml to have the correct build step, and also
    correct run the build step only in one of the jobs.
  - Update integration tests to use the new integration test template.
  - Added SqlAgentOperator resource.
- Changes to SqlServiceAccount
  - Fixed Get-ServiceObject when searching for Integration Services service.
    Unlike the rest of SQL Server services, the Integration Services service
    cannot be instanced, however you can have multiple versions installed.
    Get-Service object would return the correct service name that you
    are looking for, but it appends the version number at the end. Added
    parameter VersionNumber so the search would return the correct
    service name.
  - Added code to allow for using Managed Service Accounts.
  - Now the correct service type string value is returned by the function
    `Get-TargetResource`. Previously one value was passed in as a parameter
    (e.g. `DatabaseEngine`), but a different string value as returned
    (e.g. `SqlServer`). Now `Get-TargetResource` return the same values
    that can be passed as values in the parameter `ServiceType`
    ([issue #981](https://github.com/PowerShell/SqlServerDsc/issues/981)).
- Changes to SqlServerLogin
  - Fixed issue in Test-TargetResource to valid password on disabled accounts
    ([issue #915](https://github.com/PowerShell/SqlServerDsc/issues/915)).
  - Now when adding a login of type SqlLogin, and the SQL Server login mode
    is set to `'Integrated'`, an error is correctly thrown
    ([issue #1179](https://github.com/PowerShell/SqlServerDsc/issues/1179)).
- Changes to SqlSetup
  - Updated the integration test to stop the named instance while installing
    the other instances to mitigate
    [issue #1260](https://github.com/PowerShell/SqlServerDsc/issues/1260).
  - Add parameters to configure the Tempdb files during the installation of
    the instance. The new parameters are SqlTempdbFileCount, SqlTempdbFileSize,
    SqlTempdbFileGrowth, SqlTempdbLogFileSize and SqlTempdbLogFileGrowth
    ([issue #1167](https://github.com/PowerShell/SqlServerDsc/issues/1167)).
- Changes to SqlServerEndpoint
  - Add the optional parameter Owner. The default owner remains the login used
    for the creation of the endpoint
    ([issue #1251](https://github.com/PowerShell/SqlServerDsc/issues/1251)).
    [Maxime Daniou (@mdaniou)](https://github.com/mdaniou)
  - Add integration tests
    ([issue #744](https://github.com/PowerShell/SqlServerDsc/issues/744)).
    [Maxime Daniou (@mdaniou)](https://github.com/mdaniou)

## 12.2.0.0

- Changes to SqlServerDsc
  - During testing in AppVeyor the Build Worker is restarted in the install
    step to make sure the are no residual changes left from a previous SQL
    Server install on the Build Worker done by the AppVeyor Team
    ([issue #1260](https://github.com/PowerShell/SqlServerDsc/issues/1260)).
  - Code cleanup: Change parameter names of Connect-SQL to align with resources.
  - Updated README.md in the Examples folder.
    - Added a link to the new xADObjectPermissionEntry examples in
      ActiveDirectory, fixed a broken link and a typo.
      [Adam Rush (@adamrushuk)](https://github.com/adamrushuk)
- Change to SqlServerLogin so it doesn't check properties for absent logins.
  - Fix for ([issue #1096](https://github.com/PowerShell/SqlServerDsc/issues/1096))

## 12.1.0.0

- Changes to SqlServerDsc
  - Add support for validating the code with the DSC ResourceKit
    Script Analyzer rules, both in Visual Studio Code and directly using
    `Invoke-ScriptAnalyzer`.
  - Opt-in for common test "Common Tests - Validate Markdown Links".
  - Updated broken links in `\README.md` and in `\Examples\README.md`
  - Opt-in for common test 'Common Tests - Relative Path Length'.
  - Updated the Installation section in the README.md.
  - Updated the Contributing section in the README.md after
    [Style Guideline and Best Practices guidelines](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md)
    has merged into one document.
  - To speed up testing in AppVeyor, unit tests are now run in two containers.
  - Adding the PowerShell script `Assert-TestEnvironment.ps1` which
    must be run prior to running any unit tests locally with
    `Invoke-Pester`.
    Read more in the specific contributing guidelines, under the section
    [Unit Tests](https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#unit-tests).
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
    ([issue #1182](https://github.com/PowerShell/SqlServerDsc/issues/1182)).
- Changes to SqlServerDatabaseMail
  - Minor update to Ensure parameter description in the README.md.
- Changes to Write-ModuleStubFile.ps1
  - Create aliases for cmdlets in the stubbed module which have aliases
    ([issue #1224](https://github.com/PowerShell/SqlServerDsc/issues/1224)).
    [Dan Reist (@randomnote1)](https://github.com/randomnote1)
  - Use a string builder to build the function stubs.
  - Fixed formatting issues for the function to work with modules other
    than SqlServer.
- New DSC resource SqlServerSecureConnection
  - New resource to configure a SQL Server instance for encrypted SQL
    connections.
- Changes to SqlAlwaysOnService
  - Updated integration tests to use NetworkingDsc
    ([issue #1129](https://github.com/PowerShell/SqlServerDsc/issues/1129)).
- Changes to SqlServiceAccount
  - Fix unit tests that didn't mock some of the calls. It no longer fail
    when a SQL Server installation is not present on the node running the
    unit test ([issue #983](https://github.com/PowerShell/SqlServerDsc/issues/983)).

## 12.0.0.0

- Changes to SqlServerDatabaseMail
  - DisplayName is now properly treated as display name
    for the originating email address ([issue #1200](https://github.com/PowerShell/SqlServerDsc/issue/1200)).
    [Nick Reilingh (@NReilingh)](https://github.com/NReilingh)
    - DisplayName property now defaults to email address instead of server name.
    - Minor improvements to documentation.
- Changes to SqlAGDatabase
  - Corrected reference to "PsDscRunAsAccount" in documentation
    ([issue #1199](https://github.com/PowerShell/SqlServerDsc/issues/1199)).
    [Nick Reilingh (@NReilingh)](https://github.com/NReilingh)
- Changes to SqlDatabaseOwner
  - BREAKING CHANGE: Support multiple instances on the same node.
    The parameter InstanceName is now Key and cannot be omitted
    ([issue #1197](https://github.com/PowerShell/SqlServerDsc/issues/1197)).
- Changes to SqlSetup
  - Added new parameters to allow to define the startup types for the Sql Engine
    service, the Agent service, the Analysis service and the Integration Service.
    The new optional parameters are respectively SqlSvcStartupType, AgtSvcStartupType,
    AsSvcStartupType, IsSvcStartupType and RsSvcStartupType ([issue #1165](https://github.com/PowerShell/SqlServerDsc/issues/1165).
    [Maxime Daniou (@mdaniou)](https://github.com/mdaniou)

## 11.4.0.0

- Changes to SqlServerDsc
  - Updated helper function Restart-SqlService to have to new optional parameters
    `SkipClusterCheck` and `SkipWaitForOnline`. This was to support more aspects
    of the resource SqlServerNetwork.
  - Updated helper function `Import-SQLPSModule`
    - To only import module if the
      module does not exist in the session.
    - To always import the latest version of 'SqlServer' or 'SQLPS' module, if
      more than one version exist on the target node. It will still prefer to
      use 'SqlServer' module.
  - Updated all the examples and integration tests to not use
    `PSDscAllowPlainTextPassword`, so examples using credentials or
    passwords by default are secure.
- Changes to SqlAlwaysOnService
  - Integration tests was updated to handle new IPv6 addresses on the AppVeyor
    build worker ([issue #1155](https://github.com/PowerShell/SqlServerDsc/issues/1155)).
- Changes to SqlServerNetwork
  - Refactor SqlServerNetwork to not load assembly from GAC ([issue #1151](https://github.com/PowerShell/SqlServerDsc/issues/1151)).
  - The resource now supports restarting the SQL Server service when both
    enabling and disabling the protocol.
  - Added integration tests for this resource
    ([issue #751](https://github.com/PowerShell/SqlServerDsc/issues/751)).
- Changes to SqlAG
  - Removed excess `Import-SQLPSModule` call.
- Changes to SqlSetup
  - Now after a successful install the "SQL PowerShell module" is reevaluated and
    forced to be reimported into the session. This is to support that a never
    version of SQL Server was installed side-by-side so that SQLPS module should
    be used instead.

## 11.3.0.0

- Changes to SqlServerDsc
  - Moved decoration for integration test to resolve a breaking change in
    DscResource.Tests.
  - Activated the GitHub App Stale on the GitHub repository.
  - Added a CODE\_OF\_CONDUCT.md with the same content as in the README.md
    [issue #939](https://github.com/PowerShell/SqlServerDsc/issues/939).
  - New resources:
    - Added SqlScriptQueryResource. [Chase Wilson (@chasewilson)](https://github.com/chasewilson)
  - Fix for issue #779 [Paul Kelly (@prkelly)](https://github.com/prkelly)

## 11.2.0.0

- Changes to SqlServerDsc
  - Added new test helper functions in the CommonTestHelpers module. These are used
    by the integration tests.
    - **New-IntegrationLoopbackAdapter:** Installs the PowerShell module
      'LoopbackAdapter' from PowerShell Gallery and creates a new network
      loopback adapter.
    - **Remove-IntegrationLoopbackAdapter:** Removes a new network loopback adapter.
    - **Get-NetIPAddressNetwork:** Returns the IP network address from an IPv4 address
      and prefix length.
  - Enabled PSSA rule violations to fail build in the CI environment.
  - Renamed SqlServerDsc.psd1 to be consistent
    ([issue #1116](https://github.com/PowerShell/SqlServerDsc/issues/1116)).
    [Glenn Sarti (@glennsarti)](https://github.com/glennsarti)
- Changes to Unit Tests
  - Updated
    the following resources unit test template to version 1.2.1
    - SqlWaitForAG ([issue #1088](https://github.com/PowerShell/SqlServerDsc/issues/1088)).
      [Michael Fyffe (@TraGicCode)](https://github.com/TraGicCode)
- Changes to SqlAlwaysOnService
  - Updated the integration tests to use a loopback adapter to be less intrusive
    in the build worker environment.
  - Minor code cleanup in integration test, fixed the scope on variable.
- Changes to SqlSetup
  - Updated the integration tests to stop some services after each integration test.
    This is to save memory on the AppVeyor build worker.
  - Updated the integration tests to use a SQL Server 2016 Service Pack 1.
  - Fixed Script Analyzer rule error.
- Changes to SqlRS
  - Updated the integration tests to stop the Reporting Services service after
    the integration test. This is to save memory on the AppVeyor build worker.
  - The helper function `Restart-ReportingServicesService` should no longer timeout
    when restarting the service ([issue #1114](https://github.com/PowerShell/SqlServerDsc/issues/1114)).
- Changes to SqlServiceAccount
  - Updated the integration tests to stop some services after each integration test.
    This is to save memory on the AppVeyor build worker.
- Changes to SqlServerDatabaseMail
  - Fixed Script Analyzer rule error.

## 11.1.0.0

- Changes to SqlServerDsc
  - Updated the PULL\_REQUEST\_TEMPLATE with an improved task list and modified
    some text to be clearer ([issue #973](https://github.com/PowerShell/SqlServerDsc/issues/973)).
  - Updated the ISSUE_TEMPLATE to hopefully be more intuitive and easier to use.
  - Added information to ISSUE_TEMPLATE that issues must be reproducible in
    SqlServerDsc resource module (if running the older xSQLServer resource module)
    ([issue #1036](https://github.com/PowerShell/SqlServerDsc/issues/1036)).
  - Updated ISSUE_TEMPLATE.md with a note about sensitive information ([issue #1092](https://github.com/PowerShell/SqlServerDsc/issues/1092)).
- Changes to SqlServerLogin
  - [Claudio Spizzi (@claudiospizzi)](https://github.com/claudiospizzi): Fix password
    test fails for nativ sql users ([issue #1048](https://github.com/PowerShell/SqlServerDsc/issues/1048)).
- Changes to SqlSetup
  - [Michael Fyffe (@TraGicCode)](https://github.com/TraGicCode): Clarify usage
    of 'SecurityMode' along with adding parameter validations for the only 2
    supported values ([issue #1010](https://github.com/PowerShell/SqlServerDsc/issues/1010)).
  - Now accounts containing '$' will be able to be used for installing
    SQL Server. Although, if the account ends with '$' it is considered a
    Managed Service Account ([issue #1055](https://github.com/PowerShell/SqlServerDsc/issues/1055)).
- Changes to Integration Tests
  - [Michael Fyffe (@TraGicCode)](https://github.com/TraGicCode): Replace xStorage
    dsc resource module with StorageDsc ([issue #1038](https://github.com/PowerShell/SqlServerDsc/issues/1038)).
- Changes to Unit Tests
  - [Michael Fyffe (@TraGicCode)](https://github.com/TraGicCode): Updated
    the following resources unit test template to version 1.2.1
    - SqlAlias ([issue #999](https://github.com/PowerShell/SqlServerDsc/issues/999)).
    - SqlWindowsFirewall ([issue #1089](https://github.com/PowerShell/SqlServerDsc/issues/1089)).

## 11.0.0.0

- Changes to SqlServerDsc
  - BREAKING CHANGE: Resource SqlRSSecureConnectionLevel was remove
    ([issue #990](https://github.com/PowerShell/SqlServerDsc/issues/990)).
    The parameter that was set using that resource has been merged into resource
    SqlRS as the parameter UseSsl. The UseSsl parameter is of type boolean. This
    change was made because from SQL Server 2008 R2 this value is made an on/off
    switch. Read more in the article [ConfigurationSetting Method - SetSecureConnectionLevel](https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setsecureconnectionlevel).
  - Updated so that named parameters are used for New-Object cmdlet. This was
    done to follow the style guideline.
  - Updated manifest and license to reflect the new year
    ([issue #965](https://github.com/PowerShell/SqlServerDsc/issues/965)).
  - Added a README.md under Tests\Integration to help contributors to write
    integration tests.
  - Added 'Integration tests' section in the CONTRIBUTING.md.
  - The complete examples were removed. They were no longer accurate and some
    referenced resources that no longer exist. Accurate examples can be found
    in each specific resource example folder. Examples for installing Failover Cluster
    can be found in the resource examples folders in the xFailOverCluster
    resource module ([issue #462](https://github.com/PowerShell/SqlServerDsc/issues/462)).
  - A README.md was created under the Examples folder to be used as reference how
    to install certain scenarios ([issue #462](https://github.com/PowerShell/SqlServerDsc/issues/462)).
  - Removed the local specific common test for compiling examples in this repository
    and instead opted-in for the common test in the 'DscResource.Tests' repository
    ([issue #669](https://github.com/PowerShell/SqlServerDsc/issues/669)).
  - Added new resource SqlServerDatabaseMail for configuring SQL Server
    Database Mail ([issue #155](https://github.com/PowerShell/SqlServerDsc/issues/155)).
  - Updated the helper function Test-SQLDscParameterState to handle the
    data type UInt16.
  - Fixed typo in SqlServerDscCommon.Tests.
  - Updated README.md with known issue section for each resource.
  - Resources that did not have a description in the README.md now has one.
  - Resources that missed links to the examples in the README.md now has those
    links.
  - Style changes in all examples, removing type [System.Management.Automation.Credential()]
    from credential parameters ([issue #1003](https://github.com/PowerShell/SqlServerDsc/issues/1003)),
    and renamed the credential parameter so it is not using abbreviation.
  - Updated the security token for AppVeyor status badge in README.md. When we
    renamed the repository the security token was changed
    ([issue #1012](https://github.com/PowerShell/SqlServerDsc/issues/1012)).
  - Now the helper function Restart-SqlService, after restarting the SQL Server
    service, does not return until it can connect to the SQL Server instance, and
    the instance returns status 'Online' ([issue #1008](https://github.com/PowerShell/SqlServerDsc/issues/1008)).
    If it fails to connect within the timeout period (defaults to 120 seconds) it
    throws an error.
  - Fixed typo in comment-base help for helper function Test-AvailabilityReplicaSeedingModeAutomatic.
  - Style cleanup in helper functions and tests.
- Changes to SqlAG
  - Fixed typos in tests.
  - Style cleanup in code and tests.
- Changes to SqlAGDatabase
  - Style cleanup in code and tests.
- Changes to SqlAGListener
  - Fixed typo in comment-based help.
  - Style cleanup in code and tests.
- Changes to SqlAGReplica
  - Minor code style cleanup. Removed unused variable and instead piped the cmdlet
    Join-SqlAvailabilityGroup to Out-Null.
  - Fixed minor typos in comment-based help.
  - Fixed minor typos in comment.
  - Style cleanup in code and tests.
  - Updated description for parameter Name in README.md and in comment-based help
    ([issue #1034](https://github.com/PowerShell/SqlServerDsc/issues/1034)).
- Changes to SqlAlias
  - Fixed issue where exception was thrown if reg keys did not exist
    ([issue #949](https://github.com/PowerShell/SqlServerDsc/issues/949)).
  - Style cleanup in tests.
- Changes to SqlAlwaysOnService
  - Refactor integration tests slightly to improve run time performance
    ([issue #1001](https://github.com/PowerShell/SqlServerDsc/issues/1001)).
  - Style cleanup in code and tests.
- Changes to SqlDatabase
  - Fix minor Script Analyzer warning.
- Changes to SqlDatabaseDefaultLocation
  - Refactor integration tests slightly to improve run time performance
    ([issue #1001](https://github.com/PowerShell/SqlServerDsc/issues/1001)).
  - Minor style cleanup of code in tests.
- Changes to SqlDatabaseRole
  - Style cleanup in tests.
- Changes to SqlRS
  - Replaced Get-WmiObject with Get-CimInstance to fix Script Analyzer warnings
    ([issue #264](https://github.com/PowerShell/SqlServerDsc/issues/264)).
  - Refactored the resource to use Invoke-CimMethod.
  - Added parameter UseSsl which when set to $true forces connections to the
    Reporting Services to use SSL when connecting ([issue #990](https://github.com/PowerShell/SqlServerDsc/issues/990)).
  - Added complete example for SqlRS (based on the integration tests)
    ([issue #634](https://github.com/PowerShell/SqlServerDsc/issues/634)).
  - Refactor integration tests slightly to improve run time performance
    ([issue #1001](https://github.com/PowerShell/SqlServerDsc/issues/1001)).
  - Style cleanup in code and tests.
- Changes to SqlScript
  - Style cleanup in tests.
  - Updated examples.
  - Added integration tests.
  - Fixed minor typos in comment-based help.
  - Added new example based on integration test.
- Changes to SqlServerConfiguration
  - Fixed minor typos in comment-based help.
  - Now the verbose message say what option is changing and to what value
    ([issue #1014](https://github.com/PowerShell/SqlServerDsc/issues/1014)).
  - Changed the RestartTimeout parameter from type SInt32 to type UInt32.
  - Added localization ([issue #605](https://github.com/PowerShell/SqlServerDsc/issues/605)).
  - Style cleanup in code and tests.
- Changes to SqlServerEndpoint
  - Updated README.md with links to the examples
    ([issue #504](https://github.com/PowerShell/SqlServerDsc/issues/504)).
  - Style cleanup in tests.
- Changes to SqlServerLogin
  - Added integration tests ([issue #748](https://github.com/PowerShell/SqlServerDsc/issues/748)).
  - Minor code style cleanup.
  - Removed unused variable and instead piped the helper function Connect-SQL to
    Out-Null.
  - Style cleanup in tests.
- Changes to SqlServerMaxDop
  - Minor style changes in the helper function Get-SqlDscDynamicMaxDop.
- Changes to SqlServerMemory
  - Style cleanup in code and tests.
- Changes to SqlServerPermission
  - Fixed minor typos in comment-based help.
  - Style cleanup in code.
- Changes to SqlServerReplication
  - Fixed minor typos in verbose messages.
  - Style cleanup in tests.
- Changes to SqlServerNetwork
  - Added sysadmin account parameter usage to the examples.
- Changes to SqlServerReplication
  - Fix Script Analyzer warning ([issue #263](https://github.com/PowerShell/SqlServerDsc/issues/263)).
- Changes to SqlServerRole
  - Added localization ([issue #621](https://github.com/PowerShell/SqlServerDsc/issues/621)).
  - Added integration tests ([issue #756](https://github.com/PowerShell/SqlServerDsc/issues/756)).
  - Updated example to add two server roles in the same configuration.
  - Style cleanup in tests.
- Changes to SqlServiceAccount
  - Default services are now properly detected
    ([issue #930](https://github.com/PowerShell/SqlServerDsc/issues/930)).
  - Made the description of parameter RestartService more descriptive
    ([issue #960](https://github.com/PowerShell/SqlServerDsc/issues/960)).
  - Added a read-only parameter ServiceAccountName so that the service account
    name is correctly returned as a string ([issue #982](https://github.com/PowerShell/SqlServerDsc/issues/982)).
  - Added integration tests ([issue #980](https://github.com/PowerShell/SqlServerDsc/issues/980)).
  - The timing issue that the resource returned before SQL Server service was
    actually restarted has been solved by a change in the helper function
    Restart-SqlService ([issue #1008](https://github.com/PowerShell/SqlServerDsc/issues/1008)).
    Now Restart-SqlService waits for the instance to return status 'Online' or
    throws an error saying it failed to connect within the timeout period.
  - Style cleanup in code and tests.
- Changes to SqlSetup
  - Added parameter `ASServerMode` to support installing Analysis Services in
    Multidimensional mode, Tabular mode and PowerPivot mode
    ([issue #388](https://github.com/PowerShell/SqlServerDsc/issues/388)).
  - Added integration tests for testing Analysis Services Multidimensional mode
    and Tabular mode.
  - Cleaned up integration tests.
  - Added integration tests for installing a default instance of Database Engine.
  - Refactor integration tests slightly to improve run time performance
    ([issue #1001](https://github.com/PowerShell/SqlServerDsc/issues/1001)).
  - Added PSSA rule 'PSUseDeclaredVarsMoreThanAssignments' override in the
    function Set-TargetResource for the variable $global:DSCMachineStatus.
  - Style cleanup in code and tests.
- Changes to SqlWaitForAG
  - Style cleanup in code.
- Changes to SqlWindowsFirewall
  - Fixed minor typos in comment-based help.
  - Style cleanup in code.

## 10.0.0.0

- BREAKING CHANGE: Resource module has been renamed to SqlServerDsc
  ([issue #916](https://github.com/PowerShell/SqlServerDsc/issues/916)).
- BREAKING CHANGE: Significant rename to reduce length of resource names
  - See [issue #851](https://github.com/PowerShell/SqlServerDsc/issues/851) for a
    complete table mapping rename changes.
  - Impact to all resources.
- Changes to CONTRIBUTING.md
  - Added details to the naming convention used in SqlServerDsc.
- Changes to SqlServerDsc
  - The examples in the root of the Examples folder are obsolete. A note was
    added to the comment-based help in each example stating it is obsolete.
    This is a temporary measure until they are replaced
    ([issue #904](https://github.com/PowerShell/SqlServerDsc/issues/904)).
  - Added new common test (regression test) for validating the long path
    issue for compiling resources in Azure Automation.
  - Fix resources in alphabetical order in README.md ([issue #908](https://github.com/PowerShell/SqlServerDsc/issues/908)).
- Changes to SqlAG
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
  - BREAKING CHANGE: The read-only property SQLServerNetName was removed in favor
    of EndpointHostName ([issue #924](https://github.com/PowerShell/SqlServerDsc/issues/924)).
    Get-TargetResource will now return the value of property [NetName](https://technet.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.server.netname(v=sql.105).aspx)
    for the property EndpointHostName.
- Changes to SqlAGDatabase
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
  - Changed the Get-MatchingDatabaseNames function to be case insensitive when
    matching database names ([issue #912](https://github.com/PowerShell/SqlServerDsc/issues/912)).
- Changes to SqlAGListener
  - BREAKING CHANGE: Parameter NodeName has been renamed to ServerName
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlAGReplica
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
  - BREAKING CHANGE: Parameters PrimaryReplicaSQLServer and PrimaryReplicaSQLInstanceName
    has been renamed to PrimaryReplicaServerName and PrimaryReplicaInstanceName
    respectively ([issue #922](https://github.com/PowerShell/SqlServerDsc/issues/922)).
  - BREAKING CHANGE: The read-only property SQLServerNetName was removed in favor
    of EndpointHostName ([issue #924](https://github.com/PowerShell/SqlServerDsc/issues/924)).
    Get-TargetResource will now return the value of property [NetName](https://technet.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.server.netname(v=sql.105).aspx)
    for the property EndpointHostName.
- Changes to SqlAlwaysOnService
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabase
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes SqlDatabaseDefaultLocation
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabaseOwner
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabasePermission
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabaseRecoveryModel
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabaseRole
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlRS
  - BREAKING CHANGE: Parameters RSSQLServer and RSSQLInstanceName has been renamed
    to DatabaseServerName and DatabaseInstanceName respectively
    ([issue #923](https://github.com/PowerShell/SqlServerDsc/issues/923)).
- Changes to SqlServerConfiguration
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerEndpoint
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerEndpointPermission
  - BREAKING CHANGE: Parameter NodeName has been renamed to ServerName
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
  - Now the examples files have a shorter name so that resources will not fail
    to compile in Azure Automation ([issue #934](https://github.com/PowerShell/SqlServerDsc/issues/934)).
- Changes to SqlServerEndpointState
  - BREAKING CHANGE: Parameter NodeName has been renamed to ServerName
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerLogin
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerMaxDop
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerMemory
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerNetwork
  - BREAKING CHANGE: Parameters SQLServer has been renamed to ServerName
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerPermission
  - BREAKING CHANGE: Parameter NodeName has been renamed to ServerName
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerRole
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerServiceAccount
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue #308](https://github.com/PowerShell/SqlServerDsc/issues/308)).

## 9.0.0.0

- Changes to xSQLServer
  - Updated Pester syntax to v4
  - Fixes broken links to issues in the CHANGELOG.md.
- Changes to xSQLServerDatabase
  - Added parameter to specify collation for a database to be different from server
    collation ([issue #767](https://github.com/PowerShell/xSQLServer/issues/767)).
  - Fixed unit tests for Get-TargetResource to ensure correctly testing return
    values ([issue #849](https://github.com/PowerShell/xSQLServer/issues/849))
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Refactored the unit tests to allow them to be more user friendly and to test
    additional SQLServer variations.
    - Each test will utilize the Import-SQLModuleStub to ensure the correct
      module is loaded ([issue #784](https://github.com/PowerShell/xSQLServer/issues/784)).
  - Fixed an issue when setting the SQLServer parameter to a Fully Qualified
    Domain Name (FQDN) ([issue #468](https://github.com/PowerShell/xSQLServer/issues/468)).
  - Fixed the logic so that if a parameter is not supplied to the resource, the
    resource will not attempt to apply the defaults on subsequent checks
    ([issue #517](https://github.com/PowerShell/xSQLServer/issues/517)).
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node
    is the active host of the SQL Server instance ([issue #868](https://github.com/PowerShell/xSQLServer/issues/868)).
- Changes to xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node
    is the active host of the SQL Server instance ([issue #869](https://github.com/PowerShell/xSQLServer/issues/869)).
- Changes to xSQLServerAlwaysOnAvailabilityGroupReplica
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node is
    the active host of the SQL Server instance ([issue #870](https://github.com/PowerShell/xSQLServer/issues/870)).
- Added the CommonTestHelper.psm1 to store common testing functions.
  - Added the Import-SQLModuleStub function to ensure the correct version of the
    module stubs are loaded ([issue #784](https://github.com/PowerShell/xSQLServer/issues/784)).
- Changes to xSQLServerMemory
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node
    is the active host of the SQL Server instance ([issue #867](https://github.com/PowerShell/xSQLServer/issues/867)).
- Changes to xSQLServerNetwork
  - BREAKING CHANGE: Renamed parameter TcpDynamicPorts to TcpDynamicPort and
    changed type to Boolean ([issue #534](https://github.com/PowerShell/xSQLServer/issues/534)).
  - Resolved issue when switching from dynamic to static port.
    configuration ([issue #534](https://github.com/PowerShell/xSQLServer/issues/534)).
  - Added localization (en-US) for all strings in resource and unit tests
    ([issue #618](https://github.com/PowerShell/xSQLServer/issues/618)).
  - Updated examples to reflect new parameters.
- Changes to xSQLServerRSConfig
  - Added examples
- Added resource
  - xSQLServerDatabaseDefaultLocation
    ([issue #656](https://github.com/PowerShell/xSQLServer/issues/656))
- Changes to xSQLServerEndpointPermission
  - Fixed a problem when running the tests locally in a PowerShell console it
    would ask for parameters ([issue #897](https://github.com/PowerShell/xSQLServer/issues/897)).
- Changes to xSQLServerAvailabilityGroupListener
  - Fixed a problem when running the tests locally in a PowerShell console it
    would ask for parameters ([issue #897](https://github.com/PowerShell/xSQLServer/issues/897)).
- Changes to xSQLServerMaxDop
  - Made the resource cluster aware. When ProcessOnlyOnActiveNode is specified,
    the resource will only determine if a change is needed if the target node
    is the active host of the SQL Server instance ([issue #882](https://github.com/PowerShell/xSQLServer/issues/882)).

## 8.2.0.0

- Changes to xSQLServer
  - Updated appveyor.yml so that integration tests run in order and so that
    the SQLPS module folders are renamed to not disturb the units test, but
    can be renamed back by the integration tests xSQLServerSetup so that the
    integration tests can run successfully
    ([issue #774](https://github.com/PowerShell/xSQLServer/issues/774)).
  - Changed so the maximum version to be installed is 4.0.6.0, when running unit
    tests in AppVeyor. Quick fix until we can resolve the unit tests (see
    [issue #807](https://github.com/PowerShell/xSQLServer/issues/807)).
  - Moved the code block, that contains workarounds in appveyor.yml, so it is run
    during the install phase instead of the test phase.
  - Fix problem with tests breaking with Pester 4.0.7 ([issue #807](https://github.com/PowerShell/xSQLServer/issues/807)).
- Changes to xSQLServerHelper
  - Changes to Connect-SQL and Import-SQLPSModule
    - Now it correctly loads the correct assemblies when SqlServer module is
      present ([issue #649](https://github.com/PowerShell/xSQLServer/issues/649)).
    - Now SQLPS module will be correctly loaded (discovered) after installation
      of SQL Server. Previously resources depending on SQLPS module could fail
      because SQLPS was not found after installation because the PSModulePath
      environment variable in the (LCM) PowerShell session did not contain the new
      module path.
  - Added new helper function "Test-ClusterPermissions" ([issue #446](https://github.com/PowerShell/xSQLServer/issues/446)).
- Changes to xSQLServerSetup
  - Fixed an issue with trailing slashes in the 'UpdateSource' property
    ([issue #720](https://github.com/PowerShell/xSQLServer/issues/720)).
  - Fixed so that the integration test renames back the SQLPS module folders if
    they was renamed by AppVeyor (in the appveyor.yml file)
    ([issue #774](https://github.com/PowerShell/xSQLServer/issues/774)).
  - Fixed so integration test does not write warnings when SQLPS module is loaded
    ([issue #798](https://github.com/PowerShell/xSQLServer/issues/798)).
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
      more information in [issue #806](https://github.com/PowerShell/xSQLServer/issues/806)).
    - Fixed wrong variable name for SQL service credential. It was using the
      integration test variable name instead of the parameter name.
    - Added ErrorAction 'Stop' to the cmdlet Start-DscConfiguration
      ([issue #824](https://github.com/PowerShell/xSQLServer/issues/824)).
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Change the check of the values entered as parameter for
    BasicAvailabilityGroup. It is a boolean, hence it was not possible to
    disable the feature.
  - Add possibility to enable/disable the feature DatabaseHealthTrigger
    (SQL Server 2016 or later only).
  - Add possibility to enable the feature DtcSupportEnabled (SQL Server 2016 or
    later only). The feature currently can't be altered once the Availability
    Group is created.
  - Use the new helper function "Test-ClusterPermissions".
  - Refactored the unit tests to allow them to be more user friendly.
  - Added the following read-only properties to the schema ([issue #476](https://github.com/PowerShell/xSQLServer/issues/476))
    - EndpointPort
    - EndpointURL
    - SQLServerNetName
    - Version
  - Use the Get-PrimaryReplicaServerObject helper function.
- Changes to xSQLServerAlwaysOnAvailabilityGroupReplica
  - Fixed the formatting for the AvailabilityGroupNotFound error.
  - Added the following read-only properties to the schema ([issue #477](https://github.com/PowerShell/xSQLServer/issues/477))
    - EndpointPort
    - EndpointURL
  - Use the new helper function "Test-ClusterPermissions".
  - Use the Get-PrimaryReplicaServerObject helper function
- Changes to xSQLServerHelper
  - Fixed Connect-SQL by ensuring the Status property returns 'Online' prior to
    returning the SQL Server object ([issue #333](https://github.com/PowerShell/xSQLServer/issues/333)).
- Changes to xSQLServerRole
  - Running Get-DscConfiguration no longer throws an error saying property
    Members is not an array ([issue #790](https://github.com/PowerShell/xSQLServer/issues/790)).
- Changes to xSQLServerMaxDop
  - Fixed error where Measure-Object cmdlet would fail claiming it could not
    find the specified property ([issue #801](https://github.com/PowerShell/xSQLServer/issues/801))
- Changes to xSQLServerAlwaysOnService
  - Added integration test ([issue #736](https://github.com/PowerShell/xSQLServer/issues/736)).
    - Added ErrorAction 'Stop' to the cmdlet Start-DscConfiguration
      ([issue #824](https://github.com/PowerShell/xSQLServer/issues/824)).
- Changes to SMO.cs
  - Added default properties to the Server class
    - AvailabilityGroups
    - Databases
    - EndpointCollection
  - Added a new overload to the Login class
  - Added default properties to the AvailabilityReplicas class
    - AvailabilityDatabases
    - AvailabilityReplicas
- Added new resource xSQLServerAccount ([issue #706](https://github.com/PowerShell/xSQLServer/issues/706))
  - Added localization support for all strings
  - Added examples for usage
- Changes to xSQLServerRSConfig
  - No longer returns a null value from Test-TargetResource when Reporting
    Services has not been initialized ([issue #822](https://github.com/PowerShell/xSQLServer/issues/822)).
  - Fixed so that when two Reporting Services are installed for the same major
    version the resource does not throw an error ([issue #819](https://github.com/PowerShell/xSQLServer/issues/819)).
  - Now the resource will restart the Reporting Services service after
    initializing ([issue #592](https://github.com/PowerShell/xSQLServer/issues/592)).
    This will enable the Reports site to work.
  - Added integration test ([issue #753](https://github.com/PowerShell/xSQLServer/issues/753)).
  - Added support for configuring URL reservations and virtual directory names
    ([issue #570](https://github.com/PowerShell/xSQLServer/issues/570))
- Added resource
  - xSQLServerDatabaseDefaultLocation
    ([issue #656](https://github.com/PowerShell/xSQLServer/issues/656))

## 8.1.0.0

- Changes to xSQLServer
  - Added back .markdownlint.json so that lint rule MD013 is enforced.
  - Change the module to use the image 'Visual Studio 2017' as the build worker
    image for AppVeyor (issue #685).
  - Minor style change in CommonResourceHelper. Added missing [Parameter()] on
    three parameters.
  - Minor style changes to the unit tests for CommonResourceHelper.
  - Changes to xSQLServerHelper
    - Added Swedish localization ([issue #695](https://github.com/PowerShell/xSQLServer/issues/695)).
  - Opt-in for module files common tests ([issue #702](https://github.com/PowerShell/xSQLServer/issues/702)).
    - Removed Byte Order Mark (BOM) from the files; CommonResourceHelper.psm1,
      MSFT\_xSQLServerAvailabilityGroupListener.psm1, MSFT\_xSQLServerConfiguration.psm1,
      MSFT\_xSQLServerEndpointPermission.psm1, MSFT\_xSQLServerEndpointState.psm1,
      MSFT\_xSQLServerNetwork.psm1, MSFT\_xSQLServerPermission.psm1,
      MSFT\_xSQLServerReplication.psm1, MSFT\_xSQLServerScript.psm1,
      SQLPSStub.psm1, SQLServerStub.psm1.
  - Opt-in for script files common tests ([issue #707](https://github.com/PowerShell/xSQLServer/issues/707)).
    - Removed Byte Order Mark (BOM) from the files; DSCClusterSqlBuild.ps1,
      DSCFCISqlBuild.ps1, DSCSqlBuild.ps1, DSCSQLBuildEncrypted.ps1,
      SQLPush_SingleServer.ps1, 1-AddAvailabilityGroupListenerWithSameNameAsVCO.ps1,
      2-AddAvailabilityGroupListenerWithDifferentNameAsVCO.ps1,
      3-RemoveAvailabilityGroupListenerWithSameNameAsVCO.ps1,
      4-RemoveAvailabilityGroupListenerWithDifferentNameAsVCO.ps1,
      5-AddAvailabilityGroupListenerUsingDHCPWithDefaultServerSubnet.ps1,
      6-AddAvailabilityGroupListenerUsingDHCPWithSpecificSubnet.ps1,
      2-ConfigureInstanceToEnablePriorityBoost.ps1, 1-CreateEndpointWithDefaultValues.ps1,
      2-CreateEndpointWithSpecificPortAndIPAddress.ps1, 3-RemoveEndpoint.ps1,
      1-AddConnectPermission.ps1, 2-RemoveConnectPermission.ps1,
      3-AddConnectPermissionToAlwaysOnPrimaryAndSecondaryReplicaEachWithDifferentSqlServiceAccounts.ps1,
      4-RemoveConnectPermissionToAlwaysOnPrimaryAndSecondaryReplicaEachWithDifferentSqlServiceAccounts.ps1,
      1-MakeSureEndpointIsStarted.ps1, 2-MakeSureEndpointIsStopped.ps1,
      1-EnableTcpIpWithStaticPort.ps1, 2-EnableTcpIpWithDynamicPort.ps1,
      1-AddServerPermissionForLogin.ps1, 2-RemoveServerPermissionForLogin.ps1,
      1-ConfigureInstanceAsDistributor.ps1, 2-ConfigureInstanceAsPublisher.ps1,
      1-WaitForASingleClusterGroup.ps1, 2-WaitForMultipleClusterGroups.ps1.
  - Updated year to 2017 in license file ([issue #711](https://github.com/PowerShell/xSQLServer/issues/711)).
  - Code style clean-up throughout the module to align against the Style Guideline.
  - Fixed typos and the use of wrong parameters in unit tests which was found
    after release of new version of Pester ([issue #773](https://github.com/PowerShell/xSQLServer/issues/773)).
- Changes to xSQLServerAlwaysOnService
  - Added resource description in README.md.
  - Updated parameters descriptions in comment-based help, schema.mof and README.md.
  - Changed the datatype of the parameter to UInt32 so the same datatype is used
    in both the Get-/Test-/Set-TargetResource functions as in the schema.mof
    (issue #688).
  - Added read-only property IsHadrEnabled to schema.mof and the README.md
    (issue #687).
  - Minor cleanup of code.
  - Added examples (issue #633)
    - 1-EnableAlwaysOn.ps1
    - 2-DisableAlwaysOn.ps1
  - Fixed PS Script Analyzer errors ([issue #724](https://github.com/PowerShell/xSQLServer/issues/724))
  - Casting the result of the property IsHadrEnabled to [System.Boolean] so that
    $null is never returned, which resulted in an exception ([issue #763](https://github.com/PowerShell/xSQLServer/issues/763)).
- Changes to xSQLServerDatabasePermission
  - Fixed PS Script Analyzer errors ([issue #725](https://github.com/PowerShell/xSQLServer/issues/725))
- Changes to xSQLServerScript
  - Fixed PS Script Analyzer errors ([issue #728](https://github.com/PowerShell/xSQLServer/issues/728))
- Changes to xSQLServerSetup
  - Added Swedish localization ([issue #695](https://github.com/PowerShell/xSQLServer/issues/695)).
  - Now Get-TargetResource correctly returns an array for property ASSysAdminAccounts,
    and no longer throws an error when there is just one Analysis Services
    administrator (issue #691).
  - Added a simple integration test ([issue #709](https://github.com/PowerShell/xSQLServer/issues/709)).
  - Fixed PS Script Analyzer errors ([issue #729](https://github.com/PowerShell/xSQLServer/issues/729))

## 8.0.0.0

- BREAKING CHANGE: The module now requires WMF 5.
  - This is required for class-based resources
- Added new resource
  - xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
  - Added localization support for all strings.
  - Refactored as a MOF based resource due to challenges with Pester and testing
    in Powershell 5.
- Changes to xSQLServer
  - BREAKING CHANGE: xSQLServer does no longer try to support WMF 4.0 (PowerShell
    4.0) (issue #574). Minimum supported version of WMF is now 5.0 (PowerShell 5.0).
  - BREAKING CHANGE: Removed deprecated resource xSQLAOGroupJoin (issue #457).
  - BREAKING CHANGE: Removed deprecated resource xSQLAOGroupEnsure (issue #456).
  - BREAKING CHANGE: Removed deprecated resource xSQLServerFailoverClusterSetup
    (issue #336).
  - Updated PULL\_REQUEST\_TEMPLATE adding comment block around text. Also
    rearranged and updated texts (issue #572).
  - Added common helper functions for HQRM localization, and added tests for the
    helper functions.
    - Get-LocalizedData
    - New-InvalidResultException
    - New-ObjectNotFoundException
    - New-InvalidOperationException
    - New-InvalidArgumentException
  - Updated CONTRIBUTING.md describing the new localization helper functions.
  - Fixed typos in xSQLServer.strings.psd1
  - Fixed CodeCov badge links in README.md so that they point to the correct branch.
  - Added VS Code workspace settings file with formatting settings matching the
    Style Guideline (issue #645). That will make it possible inside VS Code to press
    SHIFT+ALT+F, or press F1 and choose 'Format document' in the list. The
    PowerShell code will then be formatted according to the Style Guideline
    (although maybe not complete, but would help a long way).
    - Removed powershell.codeFormatting.alignPropertyValuePairs setting since
      it does not align with the style guideline.
    - Added powershell.codeFormatting.preset with a value of 'Custom' so that
      workspace formatting settings are honored (issue #665).
  - Fixed lint error MD013 and MD036 in README.md.
  - Updated .markdownlint.json to enable rule MD013 and MD036 to enforce those
    lint markdown rules in the common tests.
  - Fixed lint error MD013 in CHANGELOG.md.
  - Fixed lint error MD013 in CONTRIBUTING.md.
  - Added code block around types in README.md.
  - Updated copyright information in xSQLServer.psd1.
  - Opt-in for markdown common tests (issue #668).
    - The old markdown tests has been removed.
- Changes to xSQLServerHelper
  - Removed helper function Grant-ServerPerms because the deprecated resource that
    was using it was removed.
  - Removed helper function Grant-CNOPerms because the deprecated resource that
    was using it was removed.
  - Removed helper function New-ListenerADObject because the deprecated resource
    that was using it was removed.
  - Added tests for those helper functions that did not have tests.
  - Test-SQLDscParameterState helper function can now correctly pass a CimInstance
    as DesiredValue.
  - Test-SQLDscParameterState helper function will now output a warning message
    if the value type of a desired value is not supported.
  - Added localization to helper functions (issue #641).
    - Resolved the issue when using Write-Verbose in helper functions discussed
      in #641 where Write-Verbose wouldn't write out verbose messages unless using
      parameter Verbose.
    - Moved localization strings from xSQLServer.strings.psd1 to
      xSQLServerHelper.strings.psd1.
- Changes to xSQLServerSetup
  - BREAKING CHANGE: Replaced StartWin32Process helper function with the cmdlet
    Start-Process (issue #41, #93 and #126).
  - BREAKING CHANGE: The parameter SetupCredential has been removed since it is
    no longer needed. This is because the resource now support the built-in
    PsDscRunAsCredential.
  - BREAKING CHANGE: Now the resource supports using built-in PsDscRunAsCredential.
    If PsDscRunAsCredential is set, that username will be used as the first system
    administrator.
  - BREAKING CHANGE: If the parameter PsDscRunAsCredential are not assigned any
    credentials then the resource will start the setup process as the SYSTEM account.
    When installing as the SYSTEM account, then parameter SQLSysAdminAccounts and
    ASSysAdminAccounts must be specified when installing feature Database Engine
    and Analysis Services respectively.
  - When setup exits with the exit code 3010 a warning message is written to console
    telling that setup finished successfully, but a reboot is required (partly fixes
    issue #565).
  - When setup exits with an exit code other than 0 or 3010 a warning message is
    written to console telling that setup finished with an error (partly fixes
    issue #580).
  - Added a new parameter SetupProcessTimeout which defaults to 7200 seconds (2
    hours). If the setup process has not finished before the timeout value in
    SetupProcessTimeout an error will be thrown (issue #566).
  - Updated all examples to match the removal of SetupCredential.
  - Updated (removed) severe known issues in README.md for resource xSQLServerSetup.
  - Now all major version uses the same identifier to evaluate InstallSharedDir
    and InstallSharedWOWDir (issue #420).
  - Now setup arguments that contain no value will be ignored, for example when
    InstallSharedDir and
    InstallSharedWOWDir path is already present on the target node, because of a
    previous installation (issue #639).
  - Updated Get-TargetResource to correctly detect BOL, Conn, BC and other tools
    when they are installed without SQLENGINE (issue #591).
  - Now it can detect Documentation Components correctly after the change in
    issue #591 (issue #628)
  - Fixed bug that prevented Get-DscConfiguration from running without error. The
    return hash table fails if the $clusteredSqlIpAddress variable is not used.
    The schema expects a string array but it is initialized as just a null string,
    causing it to fail on Get-DscConfiguration (issue #393).
  - Added localization support for all strings.
  - Added a test to test some error handling for cluster installations.
  - Added support for MDS feature install (issue #486)
    - Fixed localization support for MDS feature (issue #671).
- Changes to xSQLServerRSConfig
  - BREAKING CHANGE: Removed `$SQLAdminCredential` parameter. Use common parameter
    `PsDscRunAsCredential` (WMF 5.0+) to run the resource under different credentials.
    `PsDscRunAsCredential` Windows account must be a sysadmin on SQL Server (issue
    #568).
  - In addition, the resource no longer uses `Invoke-Command` cmdlet that was used
    to impersonate the Windows user specified by `$SQLAdminCredential`. The call
    also needed CredSSP authentication to be enabled and configured on the target
    node, which complicated deployments in non-domain scenarios. Using
    `PsDscRunAsCredential` solves this problems for us.
  - Fixed virtual directory creation for SQL Server 2016 (issue #569).
  - Added unit tests (issue #295).
- Changes to xSQLServerDatabase
  - Changed the readme, SQLInstance should have been SQLInstanceName.
- Changes to xSQLServerScript
  - Fixed bug with schema and variable mismatch for the Credential/Username parameter
    in the return statement (issue #661).
  - Optional QueryTimeout parameter to specify sql script query execution timeout.
    Fixes issue #597
- Changes to xSQLServerAlwaysOnService
  - Fixed typos in localization strings and in tests.
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Now it utilize the value of 'FailoverMode' to set the 'FailoverMode' property
    of the Availability Group instead of wrongly using the 'AvailabilityMode'
    property of the Availability Group.

## 7.1.0.0

- Changes to xSQLServerMemory
  - Changed the way SQLServer parameter is passed from Test-TargetResource to
    Get-TargetResource so that the default value isn't lost (issue #576).
  - Added condition to unit tests for when no SQLServer parameter is set.
- Changes to xSQLServerMaxDop
  - Changed the way SQLServer parameter is passed from Test-TargetResource to
    Get-TargetResource so that the default value isn't lost (issue #576).
  - Added condition to unit tests for when no SQLServer parameter is set.
- Changes to xWaitForAvailabilityGroup
  - Updated README.md with a description for the resources and revised the parameter
    descriptions.
  - The default value for RetryIntervalSec is now 20 seconds and the default value
    for RetryCount is now 30 times (issue #505).
  - Cleaned up code and fixed PSSA rules warnings (issue #268).
  - Added unit tests (issue #297).
  - Added descriptive text to README.md that the account that runs the resource
    must have permission to run the cmdlet Get-ClusterGroup (issue #307).
  - Added read-only parameter GroupExist which will return $true if the cluster
    role/group exist, otherwise it returns $false (issue #510).
  - Added examples.
- Changes to xSQLServerPermission
  - Cleaned up code, removed SupportsShouldProcess and fixed PSSA rules warnings
    (issue #241 and issue #262).
  - It is now possible to add permissions to two or more logins on the same instance
    (issue #526).
  - The parameter NodeName is no longer mandatory and has now the default value
    of $env:COMPUTERNAME.
  - The parameter Ensure now has a default value of 'Present'.
  - Updated README.md with a description for the resources and revised the parameter
    descriptions.
  - Removed dependency of SQLPS provider (issue #482).
  - Added ConnectSql permission. Now that permission can also be granted or revoked.
  - Updated note in resource description to also mention ConnectSql permission.
- Changes to xSQLServerHelper module
  - Removed helper function Get-SQLPSInstance and Get-SQLPSInstanceName because
    there is no resource using it any longer.
  - Added four new helper functions.
    - Register-SqlSmo, Register-SqlWmiManagement and Unregister-SqlAssemblies to
      handle the creation on the application domain and loading and unloading of
      the SMO and SqlWmiManagement assemblies.
    - Get-SqlInstanceMajorVersion to get the major SQL version for a specific instance.
  - Fixed typos in comment-based help
- Changes to xSQLServer
  - Fixed typos in markdown files; CHANGELOG, CONTRIBUTING, README and ISSUE_TEMPLATE.
  - Fixed typos in schema.mof files (and README.md).
  - Updated some parameter description in schema.mof files on those that was found
    was not equal to README.md.
- Changes to xSQLServerAlwaysOnService
  - Get-TargetResource should no longer fail silently with error 'Index operation
    failed; the array index evaluated to null.' (issue #519). Now if the
    Server.IsHadrEnabled property return neither $true or $false the
    Get-TargetResource function will throw an error.
- Changes to xSQLServerSetUp
  - Updated xSQLServerSetup Module Get-Resource method to fix (issue #516 and #490).
  - Added change to detect DQ, DQC, BOL, SDK features. Now the function
    Test-TargetResource returns true after calling set for DQ, DQC, BOL, SDK
    features (issue #516 and #490).
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Updated to return the exception raised when an error is thrown.
- Changes to xSQLServerAlwaysOnAvailabilityGroupReplica
  - Updated to return the exception raised when an error is thrown.
  - Updated parameter description for parameter Name, so that it says it must be
    in the format SQLServer\InstanceName for named instance (issue #548).
- Changes to xSQLServerLogin
  - Added an optional boolean parameter Disabled. It can be used to enable/disable
    existing logins or create disabled logins (new logins are created as enabled
    by default).
- Changes to xSQLServerDatabaseRole
  - Updated variable passed to Microsoft.SqlServer.Management.Smo.User constructor
    to fix issue #530
- Changes to xSQLServerNetwork
  - Added optional parameter SQLServer with default value of $env:COMPUTERNAME
    (issue #528).
  - Added optional parameter RestartTimeout with default value of 120 seconds.
  - Now the resource supports restarting a sql server in a cluster (issue #527
    and issue #455).
  - Now the resource allows to set the parameter TcpDynamicPorts to a blank value
    (partly fixes issue #534). Setting a blank value for parameter TcpDynamicPorts
    together with a value for parameter TcpPort means that static port will be used.
  - Now the resource will not call Alter() in the Set-TargetResource when there
    is no change necessary (issue #537).
  - Updated example 1-EnableTcpIpOnCustomStaticPort.
  - Added unit tests (issue #294).
  - Refactored some of the code, cleaned up the rest and fixed PSSA rules warnings
    (issue #261).
  - If parameter TcpDynamicPort is set to '0' at the same time as TcpPort is set
    the resource will now throw an error (issue #535).
  - Added examples (issue #536).
  - When TcpDynamicPorts is set to '0' the Test-TargetResource function will no
    longer fail each time (issue #564).
- Changes to xSQLServerRSConfig
  - Replaced sqlcmd.exe usages with Invoke-Sqlcmd calls (issue #567).
- Changes to xSQLServerDatabasePermission
  - Fixed code style, updated README.md and removed *-SqlDatabasePermission functions
    from xSQLServerHelper.psm1.
  - Added the option 'GrantWithGrant' with gives the user grant rights, together
    with the ability to grant others the same right.
  - Now the resource can revoke permission correctly (issue #454). When revoking
    'GrantWithGrant', both the grantee and all the other users the grantee has
    granted the same permission to, will also get their permission revoked.
  - Updated tests to cover Revoke().
- Changes to xSQLServerHelper
  - The missing helper function ('Test-SPDSCObjectHasProperty'), that was referenced
    in the helper function Test-SQLDscParameterState, is now incorporated into
    Test-SQLDscParameterState (issue #589).

## 7.0.0.0

- Examples
  - xSQLServerDatabaseRole
    - 1-AddDatabaseRole.ps1
    - 2-RemoveDatabaseRole.ps1
  - xSQLServerRole
    - 3-AddMembersToServerRole.ps1
    - 4-MembersToIncludeInServerRole.ps1
    - 5-MembersToExcludeInServerRole.ps1
  - xSQLServerSetup
    - 1-InstallDefaultInstanceSingleServer.ps1
    - 2-InstallNamedInstanceSingleServer.ps1
    - 3-InstallNamedInstanceSingleServerFromUncPathUsingSourceCredential.ps1
    - 4-InstallNamedInstanceInFailoverClusterFirstNode.ps1
    - 5-InstallNamedInstanceInFailoverClusterSecondNode.ps1
  - xSQLServerReplication
    - 1-ConfigureInstanceAsDistributor.ps1
    - 2-ConfigureInstanceAsPublisher.ps1
  - xSQLServerNetwork
    - 1-EnableTcpIpOnCustomStaticPort.ps1
  - xSQLServerAvailabilityGroupListener
    - 1-AddAvailabilityGroupListenerWithSameNameAsVCO.ps1
    - 2-AddAvailabilityGroupListenerWithDifferentNameAsVCO.ps1
    - 3-RemoveAvailabilityGroupListenerWithSameNameAsVCO.ps1
    - 4-RemoveAvailabilityGroupListenerWithDifferentNameAsVCO.ps1
    - 5-AddAvailabilityGroupListenerUsingDHCPWithDefaultServerSubnet.ps1
    - 6-AddAvailabilityGroupListenerUsingDHCPWithSpecificSubnet.ps1
  - xSQLServerEndpointPermission
    - 1-AddConnectPermission.ps1
    - 2-RemoveConnectPermission.ps1
    - 3-AddConnectPermissionToAlwaysOnPrimaryAndSecondaryReplicaEachWithDifferentSqlServiceAccounts.ps1
    - 4-RemoveConnectPermissionToAlwaysOnPrimaryAndSecondaryReplicaEachWithDifferentSqlServiceAccounts.ps1
  - xSQLServerPermission
    - 1-AddServerPermissionForLogin.ps1
    - 2-RemoveServerPermissionForLogin.ps1
  - xSQLServerEndpointState
    - 1-MakeSureEndpointIsStarted.ps1
    - 2-MakeSureEndpointIsStopped.ps1
  - xSQLServerConfiguration
    - 1-ConfigureTwoInstancesOnTheSameServerToEnableClr.ps1
    - 2-ConfigureInstanceToEnablePriorityBoost.ps1
  - xSQLServerEndpoint
    - 1-CreateEndpointWithDefaultValues.ps1
    - 2-CreateEndpointWithSpecificPortAndIPAddress.ps1
    - 3-RemoveEndpoint.ps1
- Changes to xSQLServerDatabaseRole
  - Fixed code style, added updated parameter descriptions to schema.mof and README.md.
- Changes to xSQLServer
  - Raised the CodeCov target to 70% which is the minimum and required target for
    HQRM resource.
- Changes to xSQLServerRole
  - **BREAKING CHANGE: The resource has been reworked in it's entirely.** Below
    is what has changed.
    - The mandatory parameters now also include ServerRoleName.
    - The ServerRole parameter was before an array of server roles, now this parameter
      is renamed to ServerRoleName and can only be set to one server role.
      - ServerRoleName are no longer limited to built-in server roles. To add members
        to a built-in server role, set ServerRoleName to the name of the built-in
        server role.
      - The ServerRoleName will be created when Ensure is set to 'Present' (if it
        does not already exist), or removed if Ensure is set to 'Absent'.
    - Three new parameters are added; Members, MembersToInclude and MembersToExclude.
      - Members can be set to one or more logins, and those will _replace all_ the
        memberships in the server role.
      - MembersToInclude and MembersToExclude can be set to one or more logins that
        will add or remove memberships, respectively, in the server role. MembersToInclude
        and MembersToExclude _can not_ be used at the same time as parameter Members.
        But both MembersToInclude and MembersToExclude can be used together at the
        same time.
- Changes to xSQLServerSetup
  - Added a note to the README.md saying that it is not possible to add or remove
    features from a SQL Server failover cluster (issue #433).
  - Changed so that it reports false if the desired state is not correct (issue #432).
    - Added a test to make sure we always return false if a SQL Server failover
      cluster is missing features.
  - Helper function Connect-SQLAnalysis
    - Now has correct error handling, and throw does not used the unknown named
      parameter '-Message' (issue #436)
    - Added tests for Connect-SQLAnalysis
    - Changed to localized error messages.
    - Minor changes to error handling.
  - This adds better support for Addnode (issue #369).
  - Now it skips cluster validation för add node (issue #442).
  - Now it ignores parameters that are not allowed for action Addnode (issue #441).
  - Added support for vNext CTP 1.4 (issue #472).
- Added new resource
  - xSQLServerAlwaysOnAvailabilityGroupReplica
- Changes to xSQLServerDatabaseRecoveryModel
  - Fixed code style, removed SQLServerDatabaseRecoveryModel functions from xSQLServerHelper.
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Fixed the permissions check loop so that it exits the loop after the function
    determines the required permissions are in place.
- Changes to xSQLServerAvailabilityGroupListener
  - Removed the dependency of SQLPS provider (issue #460).
  - Cleaned up code.
  - Added test for more coverage.
  - Fixed PSSA rule warnings (issue #255).
  - Parameter Ensure now defaults to 'Present' (issue #450).
- Changes to xSQLServerFirewall
  - Now it will correctly create rules when the resource is used for two or more
    instances on the same server (issue #461).
- Changes to xSQLServerEndpointPermission
  - Added description to the README.md
  - Cleaned up code (issue #257 and issue #231)
  - Now the default value for Ensure is 'Present'.
  - Removed dependency of SQLPS provider (issue #483).
  - Refactored tests so they use less code.
- Changes to README.md
  - Adding deprecated tag to xSQLServerFailoverClusterSetup, xSQLAOGroupEnsure and
    xSQLAOGroupJoin in README.md so it it more clear that these resources has been
    replaced by xSQLServerSetup, xSQLServerAlwaysOnAvailabilityGroup and
    xSQLServerAlwaysOnAvailabilityGroupReplica respectively.
- Changes to xSQLServerEndpoint
  - BREAKING CHANGE: Now SQLInstanceName is mandatory, and is a key, so
    SQLInstanceName has no longer a default value (issue #279).
  - BREAKING CHANGE: Parameter AuthorizedUser has been removed (issue #466,
    issue #275 and issue #80). Connect permissions can be set using the resource
    xSQLServerEndpointPermission.
  - Optional parameter IpAddress has been added. Default is to listen on any
    valid IP-address. (issue #232)
  - Parameter Port now has a default value of 5022.
  - Parameter Ensure now defaults to 'Present'.
  - Resource now supports changing IP address and changing port.
  - Added unit tests (issue #289)
  - Added examples.
- Changes to xSQLServerEndpointState
  - Cleaned up code, removed SupportsShouldProcess and fixed PSSA rules warnings
    (issue #258 and issue #230).
  - Now the default value for the parameter State is 'Started'.
  - Updated README.md with a description for the resources and revised the
    parameter descriptions.
  - Removed dependency of SQLPS provider (issue #481).
  - The parameter NodeName is no longer mandatory and has now the default value
    of $env:COMPUTERNAME.
  - The parameter Name is now a key so it is now possible to change the state on
    more than one endpoint on the same instance. _Note: The resource still only
    supports Database Mirror endpoints at this time._
- Changes to xSQLServerHelper module
  - Removing helper function Get-SQLAlwaysOnEndpoint because there is no resource
    using it any longer.
  - BREAKING CHANGE: Changed helper function Import-SQLPSModule to support SqlServer
    module (issue #91). The SqlServer module is the preferred module so if it is
    found it will be used, and if not found an attempt will be done to load SQLPS
    module instead.
- Changes to xSQLServerScript
  - Updated tests for this resource, because they failed when Import-SQLPSModule
    was updated.

## 6.0.0.0

- Changes to xSQLServerConfiguration
  - BREAKING CHANGE: The parameter SQLInstanceName is now mandatory.
  - Resource can now be used to define the configuration of two or more different
    DB instances on the same server.
- Changes to xSQLServerRole
  - xSQLServerRole now correctly reports that the desired state is present when
    the login is already a member of the server roles.
- Added new resources
  - xSQLServerAlwaysOnAvailabilityGroup
- Changes to xSQLServerSetup
  - Properly checks for use of SQLSysAdminAccounts parameter in $PSBoundParameters.
    The test now also properly evaluates the setup argument for SQLSysAdminAccounts.
  - xSQLServerSetup should now function correctly for the InstallFailoverCluster
    action, and also supports cluster shared volumes. Note that the AddNode action
    is not currently working.
  - It now detects that feature Client Connectivity Tools (CONN) and Client
    Connectivity Backwards Compatibility Tools (BC) is installed.
  - Now it can correctly determine the right cluster when only parameter
    InstallSQLDataDir is assigned a path (issue #401).
  - Now the only mandatory path parameter is InstallSQLDataDir when installing
    Database Engine (issue #400).
  - It now can handle mandatory parameters, and are not using wildcard to find
    the variables containing paths (issue #394).
  - Changed so that instead of connection to localhost it is using $env:COMPUTERNAME
    as the host name to which it connects. And for cluster installation it uses
    the parameter FailoverClusterNetworkName as the host name to which it connects
    (issue #407).
  - When called with Action = 'PrepareFailoverCluster', the SQLSysAdminAccounts
    and FailoverClusterGroup parameters are no longer passed to the setup process
    (issues #410 and 411).
  - Solved the problem that InstanceDir and InstallSQLDataDir could not be set to
    just a qualifier, i.e 'E:' (issue #418). All paths (except SourcePath) can now
    be set to just the qualifier.
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
  - BREAKING CHANGE: The mandatory parameter now include SQLInstanceName. The
    DynamicAlloc parameter is no longer mandatory
- Changes to xSQLServerDatabase
  - When the system is not in desired state the Test-TargetResource will now output
    verbose messages saying so.
- Changes to xSQLServerDatabaseOwner
  - Fixed code style, added updated parameter descriptions to schema.mof and README.md.

## 5.0.0.0

- Improvements how tests are initiated in AppVeyor
  - Removed previous workaround (issue #201) from unit tests.
  - Changes in appveyor.yml so that SQL modules are removed before common test is
    run.
  - Now the deploy step are no longer failing when merging code into Dev. Neither
    is the deploy step failing if a contributor had AppVeyor connected to the fork
    of xSQLServer and pushing code to the fork.
- Changes to README.md
  - Changed the contributing section to help new contributors.
  - Added links for each resource so it is easier to navigate to the parameter list
    for each resource.
  - Moved the list of resources in alphabetical order.
  - Moved each resource parameter list into alphabetical order.
  - Removed old text mentioning System Center.
  - Now the correct product name is written in the installation section, and a typo
    was also fixed.
  - Fixed a typo in the Requirements section.
  - Added link to Examples folder in the Examples section.
  - Change the layout of the README.md to closer match the one of PSDscResources
  - Added more detailed text explaining what operating systems WMF5.0 can be installed
    on.
  - Verified all resource schema files with the README.md and fixed some errors
    (descriptions was not verified).
  - Added security requirements section for resource xSQLServerEndpoint and
    xSQLAOGroupEnsure.
- Changes to xSQLServerSetup
  - The resource no longer uses Win32_Product WMI class when evaluating if
    SQL Server Management Studio is installed. See article
    [kb974524](https://support.microsoft.com/en-us/kb/974524) for more information.
  - Now it uses CIM cmdlets to get information from WMI classes.
  - Resolved all of the PSScriptAnalyzer warnings that was triggered in the common
    tests.
  - Improvement for service accounts to enable support for Managed Service Accounts
    as well as other nt authority accounts
  - Changes to the helper function Copy-ItemWithRoboCopy
    - Robocopy is now started using Start-Process and the error handling has been
      improved.
    - Robocopy now removes files at the destination path if they no longer exists
      at the source.
    - Robocopy copies using unbuffered I/O when available (recommended for large
      files).
  - Added a more descriptive text for the parameter `SourceCredential` to further
    explain how the parameter work.
  - BREAKING CHANGE: Removed parameter SourceFolder.
  - BREAKING CHANGE: Removed default value "$PSScriptRoot\..\..\" from parameter
    SourcePath.
  - Old code, that no longer filled any function, has been replaced.
    - Function `ResolvePath` has been replaced with
      `[Environment]::ExpandEnvironmentVariables($SourcePath)` so that environment
      variables still can be used in Source Path.
    - Function `NetUse` has been replaced with `New-SmbMapping` and
      `Remove-SmbMapping`.
  - Renamed function `GetSQLVersion` to `Get-SqlMajorVersion`.
  - BREAKING CHANGE: Renamed parameter PID to ProductKey to avoid collision with
    automatic variable $PID
- Changes to xSQLServerScript
  - All credential parameters now also has the type
    [System.Management.Automation.Credential()] to better work with PowerShell 4.0.
  - It is now possible to configure two instances on the same node, with the same
    script.
  - Added to the description text for the parameter `Credential` describing how
    to authenticate using Windows Authentication.
  - Added examples to show how to authenticate using either SQL or Windows
    authentication.
  - A recent issue showed that there is a known problem running this resource
    using PowerShell 4.0. For more information, see [issue #273](https://github.com/PowerShell/xSQLServer/issues/273)
- Changes to xSQLServerFirewall
  - BREAKING CHANGE: Removed parameter SourceFolder.
  - BREAKING CHANGE: Removed default value "$PSScriptRoot\..\..\" from parameter
    SourcePath.
  - Old code, that no longer filled any function, has been replaced.
    - Function `ResolvePath` has been replaced with
     `[Environment]::ExpandEnvironmentVariables($SourcePath)` so that environment
    variables still can be used in Source Path.
  - Adding new optional parameter SourceCredential that can be used to authenticate
    against SourcePath.
  - Solved PSSA rules errors in the code.
  - Get-TargetResource no longer return $true when no products was installed.
- Changes to the unit test for resource
  - xSQLServerSetup
    - Added test coverage for helper function Copy-ItemWithRoboCopy
- Changes to xSQLServerLogin
  - Removed ShouldProcess statements
  - Added the ability to enforce password policies on SQL logins
- Added common test (xSQLServerCommon.Tests) for xSQLServer module
  - Now all markdown files will be style checked when tests are running in AppVeyor
    after sending in a pull request.
  - Now all [Examples](/Examples/Resources) will be tested by compiling to a .mof
    file after sending in a pull request.
- Changes to xSQLServerDatabaseOwner
  - The example 'SetDatabaseOwner' can now compile, it wrongly had a `DependsOn`
    in the example.
- Changes to SQLServerRole
  - The examples 'AddServerRole' and 'RemoveServerRole' can now compile, it wrongly
    had a `DependsOn` in the example.
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
  - BREAKING CHANGE: Renamed xSQLDatabaseRecoveryModel to
    xSQLServerDatabaseRecoveryModel to align with naming convention.
  - BREAKING CHANGE: The mandatory parameters now include SQLServer, and
    SQLInstanceName.
- Changes to xSQLServerDatabasePermission
  - BREAKING CHANGE: Renamed xSQLServerDatabasePermissions to
    xSQLServerDatabasePermission to align with naming convention.
  - BREAKING CHANGE: The mandatory parameters now include PermissionState,
    SQLServer, and SQLInstanceName.
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
  - File xPDT.xml was removed since it was not used by any resources, and did not
    provide any value to the module.
- Changes xSQLServerHelper module
  - Removed the globally defined `$VerbosePreference = 'Continue'` from xSQLServerHelper.
  - Fixed a typo in a variable name in the function New-ListenerADObject.
  - Now Restart-SqlService will correctly show the services it restarts. Also
    fixed PSSA warnings.

## 4.0.0.0

- Fixes in xSQLServerConfiguration
  - Added support for clustered SQL instances.
  - BREAKING CHANGE: Updated parameters to align with other resources
    (SQLServer / SQLInstanceName).
  - Updated code to utilize CIM rather than WMI.
- Added tests for resources
  - xSQLServerConfiguration
  - xSQLServerSetup
  - xSQLServerDatabaseRole
  - xSQLAOGroupJoin
  - xSQLServerHelper and moved the existing tests for Restart-SqlService to it.
  - xSQLServerAlwaysOnService
- Fixes in xSQLAOGroupJoin
  - Availability Group name now appears in the error message for a failed.
    Availability Group join attempt.
  - Get-TargetResource now works with Get-DscConfiguration.
- Fixes in xSQLServerRole
  - Updated Ensure parameter to 'Present' default value.
  - Renamed helper functions *-SqlServerRole to *-SqlServerRoleMember.
- Changes to xSQLAlias
  - Add UseDynamicTcpPort parameter for option "Dynamically determine port".
  - Change Get-WmiObject to Get-CimInstance in Resource and associated pester file.
- Added CHANGELOG.md file.
- Added issue template file (ISSUE\_TEMPLATE.md) for 'New Issue' and pull request
  template file (PULL\_REQUEST\_TEMPLATE.md) for 'New Pull Request'.
- Add Contributing.md file.
- Changes to xSQLServerSetup
  - Now `Features` parameter is case-insensitive.
- BREAKING CHANGE: Removed xSQLServerPowerPlan from this module. The resource has
  been moved to [xComputerManagement](https://github.com/PowerShell/xComputerManagement)
  and is now called xPowerPlan.
- Changes and enhancements in xSQLServerDatabaseRole
  - BREAKING CHANGE: Fixed so the same user can now be added to a role in one or
    more databases, and/or one or more instances. Now the parameters `SQLServer`
    and `SQLInstanceName` are mandatory.
  - Enhanced so the same user can now be added to more than one role
- BREAKING CHANGE: Renamed xSQLAlias to xSQLServerAlias to align with naming convention.
- Changes to xSQLServerAlwaysOnService
  - Added RestartTimeout parameter
  - Fixed bug where the SQL Agent service did not get restarted after the
    IsHadrEnabled property was set.
  - BREAKING CHANGE: The mandatory parameters now include Ensure, SQLServer, and
    SQLInstanceName. SQLServer and SQLInstanceName are keys which will be used to
    uniquely identify the resource which allows AlwaysOn to be enabled on multiple
    instances on the same machine.
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
  - Now the resource will throw 'Not supported' when IP is changed between Static
    and DHCP.
  - Fixed an issue where sometimes the listener wasn't removed.
  - Fixed the issue when trying to add a static IP to a listener was ignored.
- Fix in xSQLServerDatabase
  - Fixed so dropping a database no longer throws an error
  - BREAKING CHANGE: Fixed an issue where it was not possible to add the same
    database to two instances on the same server.
  - BREAKING CHANGE: The name of the parameter Database has changed. It is now
    called Name.
- Fixes in xSQLAOGroupEnsure
  - Added parameters to New-ListenerADObject to allow usage of a named instance.
  - pass setup credential correctly
- Changes to xSQLServerLogin
  - Fixed an issue when dropping logins.
  - BREAKING CHANGE: Fixed an issue where it was not possible to add the same
    login to two instances on the same server.
- Changes to xSQLServerMaxDop
  - BREAKING CHANGE: Made SQLInstance parameter a key so that multiple instances
    on the same server can be configured

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
    - New-TerminatingError - *added optional parameter `InnerException` to be able
    to give the user more information in the returned message*

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

- Added new resource xSQLServerDatabase that allows adding an empty database to
  a server

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
  - Corrected bug in GetFirstItemPropertyValue to correctly handle registry keys
    with only one value.
  - Added support for SQL Server
  - 2008 R2 installation
  - Removed default values for parameters, to avoid compatibility issues and setup
    errors
  - Added Replication sub feature detection
  - Added setup parameter BrowserSvcStartupType
  - Change SourceFolder to Source to allow for multi version Support
  - Add Source Credential for accessing source files
  - Add Parameters for SQL Server configuration
  - Add Parameters to SuppressReboot or ForceReboot
- xSQLServerFirewall
  - Removed default values for parameters, to avoid compatibility issues
  - Updated firewall rule name to not use 2012 version, since package supports 2008,
    2012 and 2014 versions
  - Additional of SQLHelper Function and error handling
  - Change SourceFolder to Source to allow for multi version Support
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
  - Change SourceFolder to Source to allow for multi version Support
  - Add Parameters to SuppressReboot or ForceReboot
- Examples
  - Updated example files to use correct DebugMode parameter value ForceModuleImport,
    this is not boolean in WMF 5.0 RTM
  - Added xSQLServerNetwork example

## 1.3.0.0

- xSqlServerSetup
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
