<!--
    Your feedback and support is greatly appreciated, thanks for contributing!

    ISSUE TITLE:
    Please prefix the issue title with the resource name, i.e.
    'SqlSetup: Short description of my issue'

    ISSUE DESCRIPTION (this template):
    Please provide information regarding your issue under each header below.
    PLEASE KEEP THE HEADERS. Write N/A under any headers that don't apply to your issue.

    You may remove this and the other comments, but again, please keep the headers.

    Note: If you are running the old xSQLServer resource module, then please make sure
    the problem is reproducible in the new SqlServerDsc resource module.

    If you like to contribute more please feel free to read the contributing section
    at https://github.com/PowerShell/SQLServerDsc#contributing.
-->
#### Details of the scenario you tried and the problem that is occurring

#### The DSC configuration that is using the resource (as detailed as possible)
```
<add configuration here>
```

#### Version of the operating system and PowerShell the target node is running
<!--
    To help with this information, please run this command:
    Get-CimInstance -ClassName 'Win32_OperatingSystem' | ft Caption,OSArchitecture,Version,MUILanguages,{$PSVersionTable.PSVersion}
-->

#### SQL Server edition and version the target node is running
<!--
    To help with this information, please run the below commands:
    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'
    $sqlInstance = (Get-ItemProperty -Path $registryPath).InstalledInstances
    $sqlInstance | ForEach-Object -Process {

        $instanceId = (Get-ItemProperty "$registryPath\Instance Names\SQL").$_
        (Get-ItemProperty "$registryPath\$instanceId\Setup") | fl Edition,Version, Language
    }
-->

#### What SQL Server PowerShell modules, and which version, are present on the target node.
<!--
    To help with this information, please run this command:
    Get-Module -Name '*sql*' -ListAvailable | ? Name -ne 'SqlServerDsc' | ft Name,Version,Path
-->

#### Version of the DSC module you're using, or 'dev' if you're using current dev branch
<!--
    To help with this information, please run this command:
    Get-Module -Name 'SqlServerDsc' -ListAvailable | ft Name,Version,Path
-->
