# Contributing to SqlServerDsc

If you are keen to make SqlServerDsc better, why not consider contributing your work
to the project? Every little change helps us make a better resource for everyone
to use, and we would love to have contributions from the community.

## Core contribution guidelines

We follow all of the standard contribution guidelines for DSC resources
[outlined in DscResources repository](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md),
so please review these as a baseline for contributing.

## SqlServerDsc specific guidelines

### Automatic formatting with VS Code

There is a VS Code workspace settings file within this project with formatting
settings matching the style guideline. That will make it possible inside VS Code
to press SHIFT+ALT+F, or press F1 and choose 'Format document' in the list. The
PowerShell code will then be formatted according to the Style Guideline
(although maybe not complete, but would help a long way).

### SQL Server products supported by resources

Any resource should be able to target at least all SQL Server versions that are
currently supported by Microsoft (also those in extended support).
Unless the functionality that the resource targets does not exist in a certain
SQL Server version.
There can also be other limitations that restrict the resource from targeting all
supported versions.

Those SQL Server products that are still supported can be listed at the
[Microsoft life cycle site](https://support.microsoft.com/en-us/lifecycle/search?alpha=SQL%20Server).

### Naming convention

<Module Identifier>[<Component>][<Action>]<Scope>{<Feature> | <Property>}

#### mof-based resource

All mof-based resource (with Get/Set/Test-TargetResource) should be prefixed with
'MSFT\_SqlServer'. I.e. MSFT\_SqlServerConfiguration

Please note that not all places should contain the prefix 'MSFT\_'.

##### Folder and file structure

Please note that for the examples folder we don't use the 'MSFT\_' prefix on the
resource folders.
This is to make those folders more user friendly, to resemble the name the user
would use in the configuration file.

```Text
DSCResources/MSFT_SqlServerConfiguration/MSFT_SqlServerConfiguration.psm1
DSCResources/MSFT_SqlServerConfiguration/MSFT_SqlServerConfiguration.schema.mof
DSCResources/MSFT_SqlServerConfiguration/en-US/MSFT_SqlServerConfiguration.strings.psd1

Tests/Unit/MSFT_SqlServerConfiguration.Tests.ps1

Examples/Resources/SqlServerConfiguration/1-AddConfigurationOption.ps1
Examples/Resources/SqlServerConfiguration/2-RemoveConfigurationOption.ps1
```

##### Schema mof file

Please note that the `FriendlyName` in the schema mof file should not contain the
prefix `MSFT\_`.

```powershell
[ClassVersion("1.0.0.0"), FriendlyName("SqlServerConfiguration")]
class MSFT_SqlServerConfiguration : OMI_BaseResource
{
    # Properties removed for readability.
};
```

#### Composite or class-based resource

Any composite (with a Configuration) or class-based resources should be prefixed
with just 'Sql'

### Localization

#### HQRM localization

These should replace the old localization helper function whenever possible.

In each resource folder there should be, at least, a localization folder for
english language 'en-US'.
In the 'en-US' (and any other language folder) there should be a file named
'MSFT_ResourceName.strings.psd1', i.e.
'MSFT_SqlSetup.strings.psd1'.
At the top of each resource the localized strings should be loaded, see the helper
function `Get-LocalizedData` for more information on how this is done.

The localized string file should contain the following (beside the localization
strings)

```powershell
# Localized resources for SqlSetup

ConvertFrom-StringData @'
    InstallingUsingPathMessage = Installing using path '{0}'.
'@
```

This is an example of how to write localized verbose messages.

```powershell
Write-Verbose -Message ($script:localizedData.InstallingUsingPathMessage -f $path)
```

This is an example of how to write localized warning messages.

```powershell
Write-Warning -Message `
    ($script:localizedData.InstallationReportedProblemMessage -f $path)
```

This is an example of how to throw localized error messages. The helper functions
`New-InvalidArgumentException` and `New-InvalidOperationException` (see below) should
preferably be used whenever possible.

```powershell
throw ($script:localizedData.InstallationFailedMessage -f $Path, $processId)
```

##### Helper functions

There are also five helper functions to simplify localization.

###### New-InvalidArgumentException

```powershell
<#
    .SYNOPSIS
        Creates and throws an invalid argument exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
```

This can be used in code like this.

```powershell
if ( -not $resultOfEvaluation )
{
    $errorMessage = `
        $script:localizedData.ActionCannotBeUsedInThisContextMessage `
            -f $Action, $Parameter

    New-InvalidArgumentException -ArgumentName 'Action' -Message $errorMessage
}
```

###### New-InvalidOperationException

```powershell
<#
    .SYNOPSIS
        Creates and throws an invalid operation exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating
        error
#>
```

This can be used in code like this.

```powershell
try
{
    Start-Process @startProcessArguments
}
catch
{
    $errorMessage = $script:localizedData.InstallationFailedMessage -f $Path, $processId
    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
}

```

###### New-ObjectNotFoundException

```powershell
<#
    .SYNOPSIS
        Creates and throws an object not found exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating
        error
#>
```

This can be used in code like this.

```powershell
try
{
    Get-ChildItem -Path $path
}
catch
{
    $errorMessage = $script:localizedData.PathNotFoundMessage -f $path
    New-ObjectNotFoundException -Message $errorMessage -ErrorRecord $_
}

```

###### New-InvalidResultException

```powershell
<#
    .SYNOPSIS
        Creates and throws an invalid result exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating
        error
#>
```

This can be used in code like this.

```powershell
try
{
    $numberOfObjects = Get-ChildItem -Path $path
    if ($numberOfObjects -eq 0)
    {
        throw 'To few files.'
    }
}
catch
{
    $errorMessage = $script:localizedData.TooFewFilesMessage -f $path
    New-InvalidResultException -Message $errorMessage -ErrorRecord $_
}

```

###### Get-LocalizedData

```powershell
<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the
        localized string file.
#>
```

This should be used at the top of each resource like this.

```powershell
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlSetup'
```

#### Old localization helper function

To be able to support localization we have added wrappers for the cmdlets
`Write-Verbose` and `Write-Warning`, and also for creating a terminating error
message.
The localized strings are placed in a file named 'SqlServerDscHelper.strings.psd1'
which are located in each language folder in the root of the module. For English
language strings the folder is ['en-US'](https://github.com/PowerShell/SqlServerDsc/blob/dev/en-US).

##### New-TerminatingError

Throws a localized error message using Throw. The parameter ErrorType takes the
message type for which it will get the localized message string.

##### New-VerboseMessage

Writes a localized verbose message using Write-Verbose. The parameter ErrorType
takes the message type for which it will get the localized message string.

##### New-WarningMessage

Writes a localized warning message using Write-Warning. The parameter ErrorType
takes the message type for which it will get the localized message string.

### Helper functions

Helper functions or wrapper functions that are used by the resource can preferably
be placed in the resource module file. If the functions are of a type that could
be used by more than
one resource, then the functions can also be placed in the common
[SqlServerDscHelper.psm1](https://github.com/PowerShell/SqlServerDsc/blob/dev/SqlServerDscHelper.psm1)
module file.

### Tests

For a review of a Pull Request (PR) to start, all tests must pass without error.
If you need help to figure why some test don't pass, just write a comment in the
Pull Request (PR), or submit an issue, and somebody will come along and assist.

To run all tests manually run the following.

```powershell
Install-Module Pester
cd '<path to cloned repository>\Tests'
Invoke-Pester
```

#### Tests for style check of Markdown files

When sending in a Pull Request (PR) a style check will be performed on all Markdown
files, and if the tests find any error the build will fail.
See the section [Documentation with Markdown](#documentation-with-markdown) how
these errors kan be found before sending in the PR.

The Markdown tests can be run locally if the packet manager 'npm' is available.
To have npm available you need to install [node.js](https://nodejs.org/en/download/).
If 'npm' is not available, a warning text will print and the rest of the tests
will continue run.

#### Tests for examples files

When sending in a Pull Request (PR) all example files will be tested so they can
be compiled to a .mof file. If the tests find any errors the build will fail.
Before the test runs in AppVeyor the module will be copied to the first path of
`$env:PSModulePath`.
To run this test locally, make sure you have the SqlServerDsc module
deployed to a path where it can be used.
See `$env:PSModulePath` to view the existing paths.

#### Using SMO stub classes

There are [stub classes](https://github.com/PowerShell/SqlServerDsc/blob/dev/Tests/Unit/Stubs/SMO.cs)
for the SMO classes which can be used and improved on when creating tests where
SMO classes are used in the code being tested.

#### AppVeyor

AppVeyor is the platform where the tests is run when sending in a Pull Request (PR).
All tests are run on a clean AppVeyor build worker for each push to the Pull
Request (PR).
The tests that are run on the build worker are common tests, unit tests and
integration tests (with some limitations).

### Documentation with Markdown

If using Visual Studio Code to edit Markdown files it can be a good idea to install
the markdownlint extension. It will help to do style checking.
The file [.markdownlint.json](/.markdownlint.json) is prepared with a default set
of rules which will automatically be used by the extension.
