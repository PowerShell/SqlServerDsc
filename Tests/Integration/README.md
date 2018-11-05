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

## SqlSetup

**Run order:** 1

**Depends on:** None

The integration tests will install the following instances and leave them on the
AppVeyor build worker for other integration tests to use.

Instance | Feature | AS server mode | State
--- | --- | --- | ---
DSCSQL2016 | SQLENGINE,AS,CONN,BC,SDK | MULTIDIMENSIONAL | Running
DSCTABULAR | AS,CONN,BC,SDK | TABULAR | Stopped
MSSQLSERVER | SQLENGINE,CONN,BC,SDK | - | Stopped

All running Database Engine instances also have a SQL Server Agent that is started.

The instance DSCSQL2016 support mixed authentication mode.

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

User | Password | Permission | Description
--- | --- | --- | ---
.\SqlInstall | P@ssw0rd1 | Local Windows administrator. Administrator of Database Engine instance DSCSQL2016\*. | Runs Setup for the default instance.
.\SqlAdmin | P@ssw0rd1 | Administrator of all SQL Server instances. |
.\svc-SqlPrimary | yig-C^Equ3 | Local user. | Runs the SQL Server Agent service.
.\svc-SqlAgentPri | yig-C^Equ3 | Local user. | Runs the SQL Server Agent service.
.\svc-SqlSecondary | yig-C^Equ3 | Local user. | Used by other tests, but created here.
.\svc-SqlAgentSec | yig-C^Equ3 | Local user. | Used by other tests.
sa | P@ssw0rd1 | Administrator of the Database Engine instances DSCSQL2016. |

*\* This is due to that the integration tests runs the resource SqlAlwaysOnService
with this user and that means that this user must have permission to access the
properties `IsClustered` and `IsHadrEnable`.*

## SqlAlwaysOnService

**Run order:** 2

**Depends on:** SqlSetup

The integration test will install a loopback adapter named 'ClusterNetwork' with
an IP address of '192.168.40.10'. To be able to activate the AlwaysOn service the
tests creates an Active Directory Detached Cluster with an IP address of
'192.168.40.11' and the cluster will ignore any other static IP addresses.

>**Note:** During the tests the gateway of the loopback adatper named 'ClusterNetwork'
>will be set to '192.168.40.254', because it is a requirement to create the cluster,
>but the gateway will be removed in the last clean up test. Gateway is removed so
>that there will be no conflict with the default gateway.

>*Note:** The Active Directory Detached Cluster is not fully functioning in the
>sense that it cannot start the Name resource in the 'Cluster Group', but it
>starts enough to be able to run integration tests for AlwaysOn service.s

The tests will leave the AlwaysOn service disabled.

## SqlRS

**Run order:** 2

**Depends on:** SqlSetup

The integration tests will install the following instances and leave it on the
AppVeyor build worker for other integration tests to use.

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
- **DatabaseInstanceName:** DSCSQL2016

## SqlDatabaseDefaultLocation

**Run order:** 2

**Depends on:** SqlSetup

The integration test will change the data, log and backup path of instance
**DSCSQL2016** to the following.

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
**DSCSQL2016**.

Login | Type | Password | Permission
--- | --- | --- | ---
DscUser1 | Windows | P@ssw0rd1 | *None*
DscUser2 | Windows | P@ssw0rd1 | *None*
DscUser4 | SQL | P@ssw0rd1 | *None*

> **Note:** Login DscUser3 was create disabled and was used to test removal of
> a login.

## SqlServerRole

**Run order:** 3

**Depends on:** SqlSetup, SqlServerLogin

The integration test will keep the following server roles on the SQL Server instance
**DSCSQL2016**.

Server Role | Members
--- | ---
DscServerRole1 | DscUser1, DscUser2
DscServerRole2 | DscUser4

## SqlScript

**Run order:** 4

**Depends on:** SqlSetup

The integration tests will leave the following logins on the SQL Server instance
**DSCSQL2016**.

Login | Type | Password | Permission
--- | --- | --- | ---
DscAdmin1 | SQL | P@ssw0rd1 | dbcreator

The integration test will change the following server roles on the SQL Server instance
**DSCSQL2016**.

Server Role | Members
--- | ---
dbcreator | DscAdmin1

The integration test will leave the following databases on the SQL Server instance
**DSCSQL2016**.

Database name | Owner
--- | ---
ScriptDatabase1 | $env:COMPUTERNAME\SqlAdmin
ScriptDatabase2 | DscAdmin1

## SqlScriptQuery

**Run order:** 5

**Depends on:** SqlScript

The integration test will leave the following databases on the SQL Server instance
**DSCSQL2016**.

Database name | Owner
--- | ---
ScriptDatabase3 | $env:COMPUTERNAME\SqlAdmin
ScriptDatabase4 | DscAdmin1
