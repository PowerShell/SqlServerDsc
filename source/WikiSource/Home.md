# Welcome to the SqlServerDsc wiki

<sup>*SqlServerDsc v#.#.#*</sup>

Here you will find all the information you need to make use of the SqlServerDsc
DSC resources in the latest release. This includes details of the resources
that are available, current capabilities, known issues, and information to
help plan a DSC based implementation of SqlServerDsc.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.com/dsccommunity/SqlServerDsc/issues)
for this repository.

## Deprecated resources

The documentation, examples, unit test, and integration tests have been removed
for these deprecated resources. These resources will be removed
in a future release.

- SqlDatabaseOwner _(replaced by a property in [**SqlDatabase**](sqldatabase))_.
- SqlDatabaseRecoveryModel _(replaced by a property in [**SqlDatabase**](sqldatabase))_.
- SqlServerEndpointState _(replaced by a property in [**SqlEndpoint**](sqlendpoint))_.
- SqlServerNetwork _(replaced by [**SqlProtocol**](sqlprotocol) and_
  _[**SqlProtocolTcpIp**](sqlprotocoltcpip))_.

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name SqlServerDsc -Repository PSGallery
```

- Download SqlServerDsc from the [PowerShell Gallery](https://www.powershellgallery.com/packages/SqlServerDsc)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

To confirm installation, run the below command and ensure you see the SqlServerDsc
DSC resources available:

```powershell
Get-DscResource -Module SqlServerDsc
```

## Prerequisites

The minimum Windows Management Framework (PowerShell) version required is 5.0
or higher, which ships with Windows 10 or Windows Server 2016,
but can also be installed on Windows 7 SP1, Windows 8.1, Windows Server 2012,
and Windows Server 2012 R2.

Optionally the PowerShell Module [_SqlServer_](https://www.powershellgallery.com/packages/SqlServer)
can be installed which then will be used instead of the PowerShell module
_SQLPS_ that is installed with SQL Server.

## Change log

A full list of changes in each version can be found in the [change log](https://github.com/dsccommunity/SqlServerDsc/blob/main/CHANGELOG.md).
