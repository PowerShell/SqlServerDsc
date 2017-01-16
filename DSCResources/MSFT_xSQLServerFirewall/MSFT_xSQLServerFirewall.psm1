$script:currentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Import-Module -Name (Join-Path -Path (Split-Path -Path (Split-Path -Path $script:currentPath -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [System.String]
        $SourcePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $Features,

        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential
    )

    $InstanceName = $InstanceName.ToUpper()

    $SourcePath = [Environment]::ExpandEnvironmentVariables($SourcePath)

    if ($SourceCredential)
    {
        $newSmbMappingParameters = @{
            RemotePath = $SourcePath
            UserName = "$($SourceCredential.GetNetworkCredential().Domain)\$($SourceCredential.GetNetworkCredential().UserName)"
            Password = $($SourceCredential.GetNetworkCredential().Password)
        }

        $null = New-SmbMapping @newSmbMappingParameters
    }

    $pathToSetupExecutable = Join-Path -Path $SourcePath -ChildPath 'setup.exe'

    New-VerboseMessage -Message "Using path: $pathToSetupExecutable"

    $sqlVersion = Get-SqlMajorVersion -Path $pathToSetupExecutable

    if ($SourceCredential)
    {
        Remove-SmbMapping -RemotePath $SourcePath -Force
    }

    if($InstanceName -eq "MSSQLSERVER")
    {
        $DBServiceName = "MSSQLSERVER"
        $AgtServiceName = "SQLSERVERAGENT"
        $FTServiceName = "MSSQLFDLauncher"
        $RSServiceName = "ReportServer"
        $ASServiceName = "MSSQLServerOLAPService"
    }
    else
    {
        $DBServiceName = "MSSQL`$$InstanceName"
        $AgtServiceName = "SQLAgent`$$InstanceName"
        $FTServiceName = "MSSQLFDLauncher`$$InstanceName"
        $RSServiceName = "ReportServer`$$InstanceName"
        $ASServiceName = "MSOLAP`$$InstanceName"
    }

    $ISServiceName = "MsDtsServer" + $SQLVersion + "0"

    $Ensure = "Present"
    $Services = Get-Service
    $FeaturesInstalled = ""
    foreach($Feature in $Features.Split(","))
    {
        switch($Feature)
        {
            "SQLENGINE"
            {
                if($Services | Where-Object {$_.Name -eq $DBServiceName})
                {
                    $FeaturesInstalled += "SQLENGINE,"
                    if(Get-FirewallRule -DisplayName ("SQL Server Database Engine instance " + $InstanceName) -Application ((GetSQLPath -Feature "SQLENGINE" -InstanceName $InstanceName) + "\sqlservr.exe"))
                    {
                        $DatabaseEngineFirewall = $true
                    }
                    else
                    {
                        $DatabaseEngineFirewall = $false
                        $Ensure = "Absent"
                    }
                    if(Get-FirewallRule -DisplayName "SQL Server Browser" -Service "SQLBrowser")
                    {
                        $BrowserFirewall = $true
                    }
                    else
                    {
                        $BrowserFirewall = $false
                        $Ensure = "Absent"
                    }
                }
            }

            "RS"
            {
                if($Services | Where-Object {$_.Name -eq $RSServiceName})
                {
                    $FeaturesInstalled += "RS,"
                    if((Get-FirewallRule -DisplayName "SQL Server Reporting Services 80" -Port "TCP/80") -and (Get-FirewallRule -DisplayName "SQL Server Reporting Services 443" -Port "TCP/443"))
                    {
                        $ReportingServicesFirewall = $true
                    }
                    else
                    {
                        $ReportingServicesFirewall = $false
                        $Ensure = "Absent"
                    }
                }
            }

            "AS"
            {
                if($Services | Where-Object {$_.Name -eq $ASServiceName})
                {
                    $FeaturesInstalled += "AS,"
                    if(Get-FirewallRule -DisplayName "SQL Server Analysis Services instance $InstanceName" -Service $ASServiceName)
                    {
                        $AnalysisServicesFirewall = $true
                    }
                    else
                    {
                        $AnalysisServicesFirewall = $false
                        $Ensure = "Absent"
                    }
                    if(Get-FirewallRule -DisplayName "SQL Server Browser" -Service "SQLBrowser")
                    {
                        $BrowserFirewall = $true
                    }
                    else
                    {
                        $BrowserFirewall = $false
                        $Ensure = "Absent"
                    }
                }
            }

            "IS"
            {
                if($Services | Where-Object {$_.Name -eq $ISServiceName})
                {                    $FeaturesInstalled += "IS,"
                    if((Get-FirewallRule -DisplayName "SQL Server Integration Services Application" -Application ((GetSQLPath -Feature "IS" -SQLVersion $SQLVersion) + "Binn\MsDtsSrvr.exe")) -and (Get-FirewallRule -DisplayName "SQL Server Integration Services Port" -Port "TCP/135"))
                    {
                        $IntegrationServicesFirewall = $true
                    }
                    else
                    {
                        $IntegrationServicesFirewall = $false
                        $Ensure = "Absent"
                    }
                }
            }
        }
    }

    $FeaturesInstalled = $FeaturesInstalled.Trim(",")

    $returnValue = @{
        Ensure = $Ensure
        SourcePath = $SourcePath
        Features = $FeaturesInstalled
        InstanceName = $InstanceName
        DatabaseEngineFirewall = $DatabaseEngineFirewall
        BrowserFirewall = $BrowserFirewall
        ReportingServicesFirewall = $ReportingServicesFirewall
        AnalysisServicesFirewall = $AnalysisServicesFirewall
        IntegrationServicesFirewall = $IntegrationServicesFirewall
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [System.String]
        $SourcePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $Features,

        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential
    )

    $InstanceName = $InstanceName.ToUpper()

    $SourcePath = [Environment]::ExpandEnvironmentVariables($SourcePath)

    if ($SourceCredential)
    {
        $newSmbMappingParameters = @{
            RemotePath = $SourcePath
            UserName = "$($SourceCredential.GetNetworkCredential().Domain)\$($SourceCredential.GetNetworkCredential().UserName)"
            Password = $($SourceCredential.GetNetworkCredential().Password)
        }

        $null = New-SmbMapping @newSmbMappingParameters
    }

    $path = Join-Path -Path $SourcePath -ChildPath 'setup.exe'

    New-VerboseMessage -Message "Using path: $path"

    $sqlVersion = Get-SqlMajorVersion -Path $path

    if ($SourceCredential)
    {
        Remove-SmbMapping -RemotePath $SourcePath -Force
    }

    if($InstanceName -eq "MSSQLSERVER")
    {
        $DBServiceName = "MSSQLSERVER"
        $AgtServiceName = "SQLSERVERAGENT"
        $FTServiceName = "MSSQLFDLauncher"
        $RSServiceName = "ReportServer"
        $ASServiceName = "MSSQLServerOLAPService"
    }
    else
    {
        $DBServiceName = "MSSQL`$$InstanceName"
        $AgtServiceName = "SQLAgent`$$InstanceName"
        $FTServiceName = "MSSQLFDLauncher`$$InstanceName"
        $RSServiceName = "ReportServer`$$InstanceName"
        $ASServiceName = "MSOLAP`$$InstanceName"
    }
    $ISServiceName = "MsDtsServer" + $SQLVersion + "0"

    $SQLData = Get-TargetResource -SourcePath $SourcePath -Features $Features -InstanceName $InstanceName

    foreach($Feature in $SQLData.Features.Split(","))
    {
        switch($Feature)
        {
            "SQLENGINE"
            {
                if(!($SQLData.DatabaseEngineFirewall)){
                    if(!(Get-FirewallRule -DisplayName ("SQL Server Database Engine instance " + $InstanceName) -Application ((GetSQLPath -Feature "SQLENGINE" -InstanceName $InstanceName) + "\sqlservr.exe")))
                    {
                        New-FirewallRule -DisplayName ("SQL Server Database Engine instance " + $InstanceName) -Application ((GetSQLPath -Feature "SQLENGINE" -InstanceName $InstanceName) + "\sqlservr.exe")
                    }
                }
                if(!($SQLData.BrowserFirewall)){
                    if(!(Get-FirewallRule -DisplayName "SQL Server Browser" -Service "SQLBrowser"))
                    {
                        New-FirewallRule -DisplayName "SQL Server Browser" -Service "SQLBrowser"
                    }
                }
            }
            "RS"
            {
                if(!($SQLData.ReportingServicesFirewall)){
                    if(!(Get-FirewallRule -DisplayName "SQL Server Reporting Services 80" -Port "TCP/80"))
                    {
                        New-FirewallRule -DisplayName "SQL Server Reporting Services 80" -Port "TCP/80"
                    }
                    if(!(Get-FirewallRule -DisplayName "SQL Server Reporting Services 443" -Port "TCP/443"))
                    {
                        New-FirewallRule -DisplayName "SQL Server Reporting Services 443" -Port "TCP/443"
                    }
                }
            }
            "AS"
            {
                if(!($SQLData.AnalysisServicesFirewall)){
                    if(!(Get-FirewallRule -DisplayName "SQL Server Analysis Services instance $InstanceName" -Service $ASServiceName))
                    {
                        New-FirewallRule -DisplayName "SQL Server Analysis Services instance $InstanceName" -Service $ASServiceName
                    }
                }
                if(!($SQLData.BrowserFirewall)){
                    if(!(Get-FirewallRule -DisplayName "SQL Server Browser" -Service "SQLBrowser"))
                    {
                        New-FirewallRule -DisplayName "SQL Server Browser" -Service "SQLBrowser"
                    }
                }
            }
            "IS"
            {
                if(!($SQLData.IntegrationServicesFirewall)){
                    if(!(Get-FirewallRule -DisplayName "SQL Server Integration Services Application" -Application ((GetSQLPath -Feature "IS" -SQLVersion $SQLVersion) + "Binn\MsDtsSrvr.exe")))
                    {
                        New-FirewallRule -DisplayName "SQL Server Integration Services Application" -Application ((GetSQLPath -Feature "IS" -SQLVersion $SQLVersion) + "Binn\MsDtsSrvr.exe")
                    }
                    if(!(Get-FirewallRule -DisplayName "SQL Server Integration Services Port" -Port "TCP/135"))
                    {
                        New-FirewallRule -DisplayName "SQL Server Integration Services Port" -Port "TCP/135"
                    }
                }
            }
        }
    }

    if(!(Test-TargetResource -SourcePath $SourcePath -Features $Features -InstanceName $InstanceName))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [System.String]
        $SourcePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $Features,

        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential
    )

    $result = ((Get-TargetResource -SourcePath $SourcePath -Features $Features -InstanceName $InstanceName).Ensure -eq $Ensure)

    $result
}

function GetSQLPath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Feature,

        [String]
        $InstanceName,

        [String]
        $SQLVersion
    )

    if(($Feature -eq "SQLENGINE") -or ($Feature -eq "AS"))
    {
        switch($Feature)
        {
            "SQLENGINE"
            {
                $RegSubKey = "SQL"
            }
            "AS"
            {
                $RegSubKey = "OLAP"
            }
        }
        $RegKey = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\$RegSubKey" -Name $InstanceName).$InstanceName
        $Path = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$RegKey\setup" -Name "SQLBinRoot")."SQLBinRoot"
    }

    if($Feature -eq "IS")
    {
        $Path = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $SQLVersion + "0\DTS\setup") -Name "SQLPath")."SQLPath"
    }

    return $Path
}

function Get-FirewallRule
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $DisplayName,

        [String]
        $Application,

        [String]
        $Service,

        [String]
        $Port
    )

    $Return = $false
    if($FirewallRule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue)
    {
        if(($FirewallRule.Enabled) -and ($FirewallRule.Profile -eq "Any") -and ($FirewallRule.Direction -eq "Inbound"))
        {
            if($PSBoundParameters.ContainsKey("Application"))
            {
                if($FirewallApplicationFilter = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule -ErrorAction SilentlyContinue)
                {
                    if($FirewallApplicationFilter.Program -eq $Application)
                    {
                        $Return = $true
                    }
                }
            }
            if($PSBoundParameters.ContainsKey("Service"))
            {
                if($FirewallServiceFilter = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule -ErrorAction SilentlyContinue)
                {
                    if($FirewallServiceFilter.Service -eq $Service)
                    {
                        $Return = $true
                    }
                }
            }
            if($PSBoundParameters.ContainsKey("Port"))
            {
                if($FirewallPortFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule -ErrorAction SilentlyContinue)
                {
                    if(($FirewallPortFilter.Protocol -eq $Port.Split("/")[0]) -and ($FirewallPortFilter.LocalPort -eq $Port.Split("/")[1]))
                    {
                        $Return = $true
                    }
                }
            }
        }
    }
    return $Return
}

function New-FirewallRule
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $DisplayName,

        [String]
        $Application,

        [String]
        $Service,

        [String]
        $Port
    )

    if($PSBoundParameters.ContainsKey("Application"))
    {
        New-NetFirewallRule -DisplayName $DisplayName -Enabled True -Profile Any -Direction Inbound -Program $Application
    }
    if($PSBoundParameters.ContainsKey("Service"))
    {
        New-NetFirewallRule -DisplayName $DisplayName -Enabled True -Profile Any -Direction Inbound -Service $Service
    }
    if($PSBoundParameters.ContainsKey("Port"))
    {
        New-NetFirewallRule -DisplayName $DisplayName -Enabled True -Profile Any -Direction Inbound -Protocol $Port.Split("/")[0] -LocalPort $Port.Split("/")[1]
    }
}

<#
    .SYNOPSIS
        Returns the SQL Server major version from the setup.exe executable provided in the Path parameter.

    .PARAMETER Path
        String containing the path to the SQL Server setup.exe executable.
#>
function Get-SqlMajorVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Path
    )

    (Get-Item -Path $Path).VersionInfo.ProductVersion.Split('.')[0]
}

Export-ModuleMember -Function *-TargetResource
