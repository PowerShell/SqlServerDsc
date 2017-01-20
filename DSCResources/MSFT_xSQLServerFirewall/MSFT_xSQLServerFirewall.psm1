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

    if($InstanceName -eq 'MSSQLSERVER')
    {
        $databaseServiceName = 'MSSQLSERVER'
        $reportServiceName = 'ReportServer'
        $analysisServiceName = 'MSSQLServerOLAPService'
    }
    else
    {
        $databaseServiceName = 'MSSQL${0}' -f $InstanceName
        $reportServiceName = 'ReportServer${0}' -f $InstanceName
        $analysisServiceName = 'MSOLAP${0}' -f $InstanceName
    }

    $integrationServiceName = 'MsDtsServer{0}0' -f $sqlVersion
    $browserServiceName = 'SQLBrowser'

    $ensure = 'Present'
    $featuresInstalled = ''

    $services = Get-Service

    foreach ($currentFeature in $Features.Split(','))
    {
        switch ($currentFeature)
        {
            'SQLENGINE'
            {
                if ($services | Where-Object {$_.Name -eq $databaseServiceName})
                {
                    $featuresInstalled += "$_,"

                    if (Get-FirewallRule `
                            -DisplayName "SQL Server Database Engine instance $InstanceName" `
                            -Application (Join-Path -Path (GetSQLPath -Feature $_ -InstanceName $InstanceName) -ChildPath 'sqlservr.exe'))
                    {
                        $databaseEngineFirewall = $true
                    }
                    else
                    {
                        $databaseEngineFirewall = $false
                        $ensure = 'Absent'
                    }

                    if (Get-FirewallRule -DisplayName 'SQL Server Browser' -Service $browserServiceName)
                    {
                        $browserFirewall = $true
                    }
                    else
                    {
                        $browserFirewall = $false
                        $ensure = 'Absent'
                    }
                }
            }

            'RS'
            {
                if ($services | Where-Object {$_.Name -eq $reportServiceName})
                {
                    $featuresInstalled += "$_,"

                    if (
                        (Get-FirewallRule -DisplayName 'SQL Server Reporting Services 80' -Port 'TCP/80') -and
                        (Get-FirewallRule -DisplayName 'SQL Server Reporting Services 443' -Port 'TCP/443')
                    )
                    {
                        $reportingServicesFirewall = $true
                    }
                    else
                    {
                        $reportingServicesFirewall = $false
                        $ensure = "Absent"
                    }
                }
            }

            'AS'
            {
                if ($services | Where-Object {$_.Name -eq $analysisServiceName})
                {
                    $featuresInstalled += "$_,"

                    if (Get-FirewallRule -DisplayName "SQL Server Analysis Services instance $InstanceName" -Service $analysisServiceName)
                    {
                        $analysisServicesFirewall = $true
                    }
                    else
                    {
                        $analysisServicesFirewall = $false
                        $ensure = 'Absent'
                    }

                    if (Get-FirewallRule -DisplayName 'SQL Server Browser' -Service $browserServiceName)
                    {
                        $browserFirewall = $true
                    }
                    else
                    {
                        $browserFirewall = $false
                        $ensure = "Absent"
                    }
                }
            }

            'IS'
            {
                if ($services | Where-Object {$_.Name -eq $integrationServiceName})
                {
                    $featuresInstalled += "$_,"

                    if ((Get-FirewallRule `
                            -DisplayName 'SQL Server Integration Services Application' `
                            -Application (Join-Path -Path (Join-Path -Path (GetSQLPath -Feature 'IS' -SQLVersion $sqlVersion) -ChildPath 'Binn') -ChildPath 'MsDtsSrvr.exe')
                        ) -and (
                            Get-FirewallRule `
                                -DisplayName "SQL Server Integration Services Port" -Port "TCP/135"
                        )
                    )
                    {
                        $integrationServicesFirewall = $true
                    }
                    else
                    {
                        $integrationServicesFirewall = $false
                        $ensure = 'Absent'
                    }
                }
            }
        }
    }

    $featuresInstalled = $featuresInstalled.Trim(',')

    return @{
        Ensure = $ensure
        SourcePath = $SourcePath
        Features = $featuresInstalled
        InstanceName = $InstanceName
        DatabaseEngineFirewall = $databaseEngineFirewall
        BrowserFirewall = $browserFirewall
        ReportingServicesFirewall = $reportingServicesFirewall
        AnalysisServicesFirewall = $analysisServicesFirewall
        IntegrationServicesFirewall = $integrationServicesFirewall
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

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

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $analysisServiceName = 'MSSQLServerOLAPService'
    }
    else
    {
        $analysisServiceName = 'MSOLAP${0}' -f $InstanceName
    }

    $browserServiceName = 'SQLBrowser'

    $getTargetResourceResult = Get-TargetResource -SourcePath $SourcePath -Features $Features -InstanceName $InstanceName

    foreach ($currentFeature in $getTargetResourceResult.Features.Split(','))
    {
        switch ($currentFeature)
        {
            'SQLENGINE'
            {
                if (-not ($getTargetResourceResult.DatabaseEngineFirewall))
                {
                    $pathToDatabaseEngineExecutable = Join-Path -Path (GetSQLPath -Feature $_ -InstanceName $InstanceName) -ChildPath 'sqlservr.exe'
                    $databaseEngineFirewallRuleDisplayName = "SQL Server Database Engine instance $InstanceName"

                    $databaseEngineFirewallRuleParameters = @{
                        DisplayName = $databaseEngineFirewallRuleDisplayName
                        Application = $pathToDatabaseEngineExecutable
                    }

                    if (-not (Get-FirewallRule @databaseEngineFirewallRuleParameters))
                    {
                        New-FirewallRule @databaseEngineFirewallRuleParameters
                    }
                }

                if (-not ($getTargetResourceResult.BrowserFirewall))
                {
                    $browserFirewallRuleDisplayName = 'SQL Server Browser'

                    $browserFirewallRuleParameters = @{
                        DisplayName = $browserFirewallRuleDisplayName
                        Service = $browserServiceName
                    }

                    if (-not (Get-FirewallRule @browserFirewallRuleParameters))
                    {
                        New-FirewallRule @browserFirewallRuleParameters
                    }
                }
            }

            'RS'
            {
                if (-not ($getTargetResourceResult.ReportingServicesFirewall))
                {
                    $reportingServicesNoSslProtocol = 'TCP'
                    $reportingServicesNoSslLocalPort = '80'
                    $reportingServicesNoSslFirewallRuleDisplayName = 'SQL Server Reporting Services 80'

                    $reportingServicesSslProtocol = 'TCP'
                    $reportingServicesSslLocalPort = '443'
                    $reportingServicesSslFirewallRuleDisplayName = 'SQL Server Reporting Services 443'

                    $reportingServicesNoSslFirewallRuleParameters = @{
                        DisplayName = $reportingServicesNoSslFirewallRuleDisplayName
                        Port = "$reportingServicesNoSslProtocol/$reportingServicesNoSslLocalPort"
                    }

                    if (-not (Get-FirewallRule @reportingServicesNoSslFirewallRuleParameters))
                    {
                        New-FirewallRule @reportingServicesNoSslFirewallRuleParameters
                    }

                    $reportingServicesSslFirewallRuleParameters = @{
                        DisplayName = $reportingServicesSslFirewallRuleDisplayName
                        Port = "$reportingServicesSslProtocol/$reportingServicesSslLocalPort"
                    }

                    if (-not (Get-FirewallRule @reportingServicesSslFirewallRuleParameters))
                    {
                        New-FirewallRule @reportingServicesSslFirewallRuleParameters
                    }
                }
            }

            'AS'
            {
                if (-not ($getTargetResourceResult.AnalysisServicesFirewall))
                {
                    $analysisServicesFirewallRuleDisplayName = "SQL Server Analysis Services instance $InstanceName"

                    $analysisServicesFirewallRuleParameters = @{
                        DisplayName = $analysisServicesFirewallRuleDisplayName
                        Service = $analysisServiceName
                    }

                    if(-not (Get-FirewallRule @analysisServicesFirewallRuleParameters))
                    {
                        New-FirewallRule @analysisServicesFirewallRuleParameters
                    }
                }

                if (-not ($getTargetResourceResult.BrowserFirewall))
                {
                    $browserFirewallRuleDisplayName = 'SQL Server Browser'

                    $browserFirewallRuleParameters = @{
                        DisplayName = $browserFirewallRuleDisplayName
                        Service = $browserServiceName
                    }

                    if (-not (Get-FirewallRule @browserFirewallRuleParameters))
                    {
                        New-FirewallRule @browserFirewallRuleParameters
                    }
                }
            }

            'IS'
            {
                if (!($getTargetResourceResult.IntegrationServicesFirewall))
                {
                    $integrationServicesRuleApplicationDisplayName = 'SQL Server Integration Services Application'
                    $pathToIntegrationServicesExecutable = (Join-Path -Path (Join-Path -Path (GetSQLPath -Feature 'IS' -SQLVersion $sqlVersion) -ChildPath 'Binn') -ChildPath 'MsDtsSrvr.exe')

                    $integrationServicesProtocol = 'TCP'
                    $integrationServicesLocalPort = '135'
                    $integrationServicesFirewallRuleDisplayName = 'SQL Server Integration Services Port'

                    $integrationServicesFirewallRuleApplicationParameters = @{
                        DisplayName = $integrationServicesRuleApplicationDisplayName
                        Application = $pathToIntegrationServicesExecutable
                    }

                    if (-not (Get-FirewallRule @integrationServicesFirewallRuleApplicationParameters))
                    {
                        New-FirewallRule @integrationServicesFirewallRuleApplicationParameters
                    }

                    $integrationServicesFirewallRulePortParameters = @{
                        DisplayName = $integrationServicesFirewallRuleDisplayName
                        Port = "$integrationServicesProtocol/$integrationServicesLocalPort"
                    }

                    if (-not (Get-FirewallRule @integrationServicesFirewallRulePortParameters))
                    {
                        New-FirewallRule @integrationServicesFirewallRulePortParameters
                    }
                }
            }
        }
    }

    if (-not (Test-TargetResource -SourcePath $SourcePath -Features $Features -InstanceName $InstanceName))
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

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

    $getTargetResourceResult = Get-TargetResource -SourcePath $SourcePath -Features $Features -InstanceName $InstanceName

    return ($getTargetResourceResult.Ensure -eq $Ensure)
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
