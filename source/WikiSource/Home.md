# Welcome to the SqlServerDsc wiki

<sup>*SqlServerDsc v#.#.#*</sup>

Here you will find all the information you need to make use of the SqlServerDsc
DSC resources in the latest release. This includes details of the resources
that are available, current capabilities, known issues, and information to
help plan a DSC based implementation of SqlServerDsc.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](../issues) for this repository.

_This wiki is currently updated manually by a maintainer, so there can be_
_some delay before this wiki is updated for the latest release._

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

The SqlServerDsc module requires PowerShell v5.0 or higher.

Optionally the PowerShell Module [_SqlServer_](https://www.powershellgallery.com/packages/SqlServer)
can be installed which then will be used instead of the PowerShell module
_SQLPS_ that is installed with SQL Server.
