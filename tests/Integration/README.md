# Integration tests for SqlServerDsc

For it to be easier to write integration tests for a resource that depends on
other resources, this will list the run order of the integration tests that keep
their configuration on the AppVeyor build worker. For example, the integration
test for SqlAlwaysOnService enables and then disables the AlwaysOn functionality,
so that integration test are not listed.

If an integration test should use one or more of these previous integration test
configurations then the run order for the new integration tests should be set to
a higher run order number than the highest run order of the dependent integration
tests.

**Below are the integration tests listed in the run order, and with the dependency
to each other. Dependencies are made to speed up the testing.**

## SqlSetup

**Run order:** 1

**Depends on:** None

The integration tests will install the following instances and leave them on the
AppVeyor build worker for other integration tests to use.

Instance | Feature | AS server mode | State
--- | --- | --- | ---
DSCSQLTEST | SQLENGINE,AS,CONN,BC,SDK | MULTIDIMENSIONAL | Running
DSCTABULAR | AS,CONN,BC,SDK | TABULAR | Stopped
MSSQLSERVER | SQLENGINE,CONN,BC,SDK | - | Stopped

All running Database Engine instances also have a SQL Server Agent that is started.

The instance DSCSQLTEST support mixed authentication mode, and will have
both Named Pipes and TCP/IP protocol enabled.

>**Note:** Some services are stopped to save memory on the build worker. See the
>column *State*.

### Properties for all instances

- **Collation:** Finnish\_Swedish\_CI\_AS
- **InstallSharedDir:** C:\Program Files\Microsoft SQL Server
- **InstallSharedWOWDir:** C:\Program Files (x86)\Microsoft SQL Server

### Users

The following local users are created on the AppVeyor build worker and can
be used by other integration tests.

> Note: User account names was kept to a maximum of 15 characters.

<!-- markdownlint-disable MD013 -->
User | Password | Permission | Description
--- | --- | --- | ---
.\SqlInstall | P@ssw0rd1 | Local Windows administrator. Administrator of Database Engine instance DSCSQLTEST\*. | Runs Setup for the default instance.
.\SqlAdmin | P@ssw0rd1 | Administrator of all SQL Server instances. |
.\svc-SqlPrimary | yig-C^Equ3 | Local user. | Runs the SQL Server Agent service.
.\svc-SqlAgentPri | yig-C^Equ3 | Local user. | Runs the SQL Server Agent service.
.\svc-SqlSecondary | yig-C^Equ3 | Local user. | Used by other tests, but created here.
.\svc-SqlAgentSec | yig-C^Equ3 | Local user. | Used by other tests.
sa | P@ssw0rd1 | Administrator of the Database Engine instances DSCSQLTEST. |
<!-- markdownlint-enable MD013 -->

*\* This is due to that the integration tests runs the resource SqlAlwaysOnService
with this user and that means that this user must have permission to access the
properties `IsClustered` and `IsHadrEnable`.*

## SqlRSSetup

**Run order:** 2

**Depends on:** SqlSetup (for the local installation account)

The integration tests will install (or upgrade) a Microsoft SQL Server
2017 Reporting Services instance and leave it on the AppVeyor build worker
for other integration tests to use.

>**NOTE:** Uninstall is not tested, because when upgrading the existing
>Microsoft SQL Server Reporting Services instance it requires a restart,
>that prevents uninstall until the node is restarted. AppVeyor build
>workers are not allowed to be restarted during testing phase.

Instance |  State
--- | ---
SSRS | Stopped

>**Note:** The Reporting Services instance is not configured after it is
>installed or upgraded, but if there are already an instance of Reporting
>Services installed on the build worker, it could have been configured.
>Other integration tests need to take that into consideration.

### Properties for the instance SSRS

- **InstanceName:** SSRS
- **CurrentVersion:** ^14.0.6981.38291 (depends on the version downloaded)
- **ErrorDumpDirectory:** C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles
- **LogPath:** C:\Users\appveyor\AppData\Local\Temp\SSRS
- **InstallFolder:** C:\Program Files\Microsoft SQL Server Reporting Services
- **ServiceName:** SQLServerReportingServices
- **Edition:** Developer

### Users

<!-- markdownlint-disable MD013 -->
User | Password | Description
--- | --- | --- | ---
.\SqlInstall | P@ssw0rd1 | The Reporting Services instance is installed using this account.
<!-- markdownlint-enable MD013 -->

## SqlAlwaysOnService

*This integration test has been temporarily disabled because when*
*the cluster feature is installed it requires a reboot.*

**Run order:** 2

**Depends on:** SqlSetup

The integration test will install a loopback adapter named 'ClusterNetwork' with
an IP address of '192.168.40.10'. To be able to activate the AlwaysOn service the
tests creates an Active Directory Detached Cluster with an IP address of
'192.168.40.11' and the cluster will ignore any other static IP addresses.

<!-- markdownlint-disable MD028 -->
>**Note:** During the tests the gateway of the loopback adapter named 'ClusterNetwork'
>will be set to '192.168.40.254', because it is a requirement to create the cluster,
>but the gateway will be removed in the last clean up test. Gateway is removed so
>that there will be no conflict with the default gateway.

>**Note:** The Active Directory Detached Cluster is not fully functioning in the
>sense that it cannot start the Name resource in the 'Cluster Group', but it
>starts enough to be able to run integration tests for AlwaysOn service.s
<!-- markdownlint-enable MD028 -->

The tests will leave the AlwaysOn service disabled.

## SqlDatabase

**Run order:** 2

**Depends on:** SqlSetup

The integration test will leave a database for other integration tests to
use.

Database | Collation
--- | --- | ---
Database1 | Finnish_Swedish_CI_AS

## SqlDatabaseDefaultLocation

**Run order:** 2

**Depends on:** SqlSetup

The integration test will change the data, log and backup path of instance
**DSCSQLTEST** to the following.

Data | Log | Backup
--- | --- | ---
C:\SQLData | C:\SQLLog | C:\Backups

## SqlServerLogin

**Run order:** 2

**Depends on:** SqlSetup

The integration tests will leave the following local Windows users on the build
worker.

Username | Password | Permission
--- | --- | ---
DscUser1 | P@ssw0rd1 | Local user
DscUser2 | P@ssw0rd1 | Local user
DscUser3 | P@ssw0rd1 | Local user

The integration tests will leave the following local Windows groups on the build
worker.

Username | Members | Member of | Permission
--- | --- | --- | ---
DscSqlUsers1 | DscUser1, DscUser2 | *None* | *None*

The integration tests will leave the following logins on the SQL Server instance
**DSCSQLTEST**.

Login | Type | Password | Permission
--- | --- | --- | ---
`$env:COMPUTERNAME`\DscUser1 | Windows User | See above | *None*
`$env:COMPUTERNAME`\DscUser2 | Windows User | See above | *None*
DscUser4 | SQL | P@ssw0rd1 | *None*
`$env:COMPUTERNAME`\DscSqlUsers1 | Windows Group | -- | *None*

>**Note:** The `$env:COMPUTERNAME` is reference to the build workers computer
>name. The SQL login could for example be 'APPVYR-WIN\DscUser1'.

## SqlAgentAlert

**Run order:** 2

**Depends on:** SqlSetup

*The integration tests will clean up and not leave anything on the build
worker.*

## SqlAgentOperator

**Run order:** 2

**Depends on:** SqlSetup

*The integration tests will clean up and not leave anything on the build
worker.*

## SqlServerDatabaseMail

**Run order:** 2

**Depends on:** SqlSetup

*The integration tests will clean up and not leave anything on the build
worker.*

## SqlServerEndpoint

**Run order:** 2

**Depends on:** SqlSetup

*The integration tests will clean up and not leave anything on the build
worker.*

## SqlServerNetwork

**Run order:** 2

**Depends on:** SqlSetup

*The integration tests will clean up and not leave anything on the build
worker.*

## SqlServiceAccount

**Run order:** 2

**Depends on:** SqlSetup

*The integration tests will clean up and not leave anything on the build
worker.*

## SqlRS

**Run order:** 3

**Depends on:** SqlSetup, SqlRSSetup

When running integration tests for SQL Server 2016 the integration tests
will install the following instances and leave it on the AppVeyor build
worker for other integration tests to use.
When running integration tests for SQL Server 2017 the Reporting Services
instance installed by the resource SqlRSSetup is started, and then stopped
again after the integration tests has run.

Instance | Feature | Description
--- | --- | ---
DSCRS2016 | RS | The Reporting Services is initialized, and in a working state.

>**Note:** The Reporting Services service is stopped to save memory on the build
>worker.

### Properties for the instance

- **Collation:** Finnish\_Swedish\_CI\_AS
- **InstallSharedDir:** C:\Program Files\Microsoft SQL Server
- **InstallSharedWOWDir:** C:\Program Files (x86)\Microsoft SQL Server
- **DatabaseServerName:** `$env:COMPUTERNAME`
- **DatabaseInstanceName:** DSCSQLTEST

## SqlServerRole

**Run order:** 3

**Depends on:** SqlSetup, SqlServerLogin

The integration test will keep the following server roles on the SQL Server instance
**DSCSQLTEST**.

Server Role | Members
--- | ---
DscServerRole1 | DscUser1, DscUser2
DscServerRole2 | DscUser4

## SqlDatabaseUser

**Run order:** 3

**Depends on:** SqlSetup, SqlServerLogin, SqlDatabase

The integration test will leave these database users for other integration tests
to use.

**Database name:** Database1

Name | Type | LoginType | Login | Certificate | Asymmetric Key
--- | --- | --- | --- | --- | ---
User1 | Login | WindowsUser | `$env:COMPUTERNAME`\DscUser1 | - | -
User2 | Login | SqlLogin | DscUser4 | - | -
User3 | NoLogin | SqlLogin | - | - | -
User5 | Certificate | Certificate | - | Certificate1 | -
User6 | AsymmetricKey | AsymmetricKey | - | - | AsymmetricKey1

>**Note:** The `$env:COMPUTERNAME` is reference to the build workers computer
>name. The SQL login could for example be 'APPVYR-WIN\DscUser1'.

The integration test will leave this database certificate for other integration
tests to use.

**Database name:** Database1

Name | Subject | Password
--- | --- | ---
Certificate1 | SqlServerDsc Integration Test | P@ssw0rd1

The integration test will leave this database asymmetric key for other integration
tests to use.

**Database name:** Database1

Name | Algorithm | Password
--- | --- | ---
AsymmetricKey1 | RSA_2048 | P@ssw0rd1

## SqlScript

**Run order:** 4

**Depends on:** SqlSetup

The integration tests will leave the following logins on the SQL Server instance
**DSCSQLTEST**.

Login | Type | Password | Permission
--- | --- | --- | ---
DscAdmin1 | SQL | P@ssw0rd1 | dbcreator

The integration test will change the following server roles on the SQL Server instance
**DSCSQLTEST**.

Server Role | Members
--- | ---
dbcreator | DscAdmin1

The integration test will leave the following databases on the SQL Server instance
**DSCSQLTEST**.

Database name | Owner
--- | ---
ScriptDatabase1 | $env:COMPUTERNAME\SqlAdmin
ScriptDatabase2 | DscAdmin1

## SqlScriptQuery

**Run order:** 5

**Depends on:** SqlScript

The integration test will leave the following databases on the SQL Server instance
**DSCSQLTEST**.

Database name | Owner
--- | ---
ScriptDatabase3 | $env:COMPUTERNAME\SqlAdmin
ScriptDatabase4 | DscAdmin1

## SqlServerSecureConnection

**Run order:** 5

**Depends on:** SqlSetup

*The integration tests will clean up and not leave anything on the build
worker.*

## SqlServerProtocol

**Run order:** 6

**Depends on:** SqlSetup

Depends that the instance `DSCSQLTEST` have the Named Pipes protocol
enabled (SqlSetup is run with `NpEnabled = $true`).

*The integration tests will clean up and not leave anything on the build
worker.*
