Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'xSQLServerHelper.psm1') `
    -Force

<#
    .SYNOPSIS
    Gets the SQL Reporting Services initialization status.

    .PARAMETER InstanceName
    Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER RSSQLServer
    Name of the SQL Server to host the Reporting Service database.

    .PARAMETER RSSQLInstanceName
    Name of the SQL Server instance to host the Reporting Service database.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName,

        [parameter()]
        [System.String]
        $ReportServerVirtualDir,

        [parameter()]
        [System.String]
        $ReportsVirtualDir,

        [parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [parameter()]
        [System.String[]]
        $ReportsReservedUrl
    )

    $instanceNamesRegistryKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

    if ( Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName -ErrorAction SilentlyContinue )
    {
        $instanceId = (Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName).$InstanceName
        $sqlVersion = [System.Int32]((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup" -Name 'Version').Version).Split('.')[0]

        $reportingServicesConfiguration = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$InstanceName\v$sqlVersion\Admin"
        $reportingServicesConfiguration = $reportingServicesConfiguration | Where-Object -FilterScript {
            $_.InstanceName -eq $InstanceName
        }

        if ( $reportingServicesConfiguration.DatabaseServerName.Contains('\') )
        {
            $RSSQLServer = $reportingServicesConfiguration.DatabaseServerName.Split('\')[0]
            $RSSQLInstanceName = $reportingServicesConfiguration.DatabaseServerName.Split('\')[1]
        }
        else
        {
            $RSSQLServer = $reportingServicesConfiguration.DatabaseServerName
            $RSSQLInstanceName = 'MSSQLSERVER'
        }

        $isInitialized = $reportingServicesConfiguration.IsInitialized

        if ( $isInitialized )
        {
            <#
                SSRS Web Portal application name changed in SQL Server 2016
                https://docs.microsoft.com/en-us/sql/reporting-services/breaking-changes-in-sql-server-reporting-services-in-sql-server-2016
            #>
            if ( $sqlVersion -ge 13 )
            {
                $reportsApplicationName = 'ReportServerWebApp'
            }
            else
            {
                $reportsApplicationName = 'ReportManager'
            }

            $ReportServerVirtualDir = $reportingServicesConfiguration.VirtualDirectoryReportServer
            $ReportsVirtualDir = $reportingServicesConfiguration.VirtualDirectoryReportManager

            $reservedUrls = $reportingServicesConfiguration.ListReservedUrls()

            $ReportServerReservedUrl = @()
            $ReportsReservedUrl = @()

            for ( $i = 0; $i -lt $reservedUrls.Application.Count; ++$i )
            {
                if ( $reservedUrls.Application[$i] -eq "ReportServerWebService" )
                {
                    $ReportServerReservedUrl += $reservedUrls.UrlString[$i]
                }

                if ( $reservedUrls.Application[$i] -eq $reportsApplicationName )
                {
                    $ReportsReservedUrl += $reservedUrls.UrlString[$i]
                }
            }
        }
        else
        {
            <#
                Make sure the value returned is false, if the value returned was
                either empty, $null or $false. Fic for issue #822.
            #>
            [System.Boolean] $isInitialized = $false
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType SSRSNotFound -FormatArgs @($InstanceName) -ErrorCategory ObjectNotFound
    }

    $returnValue = @{
        InstanceName      = $InstanceName
        RSSQLServer       = $RSSQLServer
        RSSQLInstanceName = $RSSQLInstanceName
        ReportServerVirtualDir = $ReportServerVirtualDir
        ReportsVirtualDir = $ReportsVirtualDir
        ReportServerReservedUrl = $ReportServerReservedUrl
        ReportsReservedUrl = $ReportsReservedUrl
        IsInitialized = $isInitialized
    }

    $returnValue
}

<#
    .SYNOPSIS
    Initializes SQL Reporting Services.

    .PARAMETER InstanceName
    Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER RSSQLServer
    Name of the SQL Server to host the Reporting Service database.

    .PARAMETER RSSQLInstanceName
    Name of the SQL Server instance to host the Reporting Service database.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName,

        [parameter()]
        [System.String]
        $ReportServerVirtualDir,

        [parameter()]
        [System.String]
        $ReportsVirtualDir,

        [parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [parameter()]
        [System.String[]]
        $ReportsReservedUrl
    )

    $instanceNamesRegistryKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

    if ( Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName -ErrorAction SilentlyContinue )
    {
        $instanceId = (Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName).$InstanceName
        $sqlVersion = [System.Int32]((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup" -Name 'Version').Version).Split('.')[0]

        if ( $InstanceName -eq 'MSSQLSERVER' )
        {
            $reportingServicesServiceName = "ReportServer"
            if([string]::IsNullOrEmpty($ReportServerVirtualDir)) { $ReportServerVirtualDir = "ReportServer" }
            if([string]::IsNullOrEmpty($ReportsVirtualDir)) { $ReportsVirtualDir = "Reports" }
            $reportingServicesDatabaseName = "ReportServer"
        }
        else
        {
            $reportingServicesServiceName = "ReportServer`$$InstanceName"
            if([string]::IsNullOrEmpty($ReportServerVirtualDir)) { $ReportServerVirtualDir = "ReportServer_$InstanceName" }
            if([string]::IsNullOrEmpty($ReportsVirtualDir)) { $ReportsVirtualDir = "Reports_$InstanceName" }
            $reportingServicesDatabaseName = "ReportServer`$$InstanceName"
        }

        if ( $RSSQLInstanceName -eq 'MSSQLSERVER' )
        {
            $reportingServicesConnection = $RSSQLServer
        }
        else
        {
            $reportingServicesConnection = "$RSSQLServer\$RSSQLInstanceName"
        }

        $language = (Get-WMIObject -Class Win32_OperatingSystem -Namespace root/cimv2 -ErrorAction SilentlyContinue).OSLanguage
        $reportingServicesConfiguration = Get-WmiObject -Class MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$InstanceName\v$sqlVersion\Admin"
        $reportingServicesConfiguration = $reportingServicesConfiguration | Where-Object -FilterScript {
            $_.InstanceName -eq $InstanceName
        }

        <#
            SSRS Web Portal application name changed in SQL Server 2016
            https://docs.microsoft.com/en-us/sql/reporting-services/breaking-changes-in-sql-server-reporting-services-in-sql-server-2016
        #>
        if ($sqlVersion -ge 13)
        {
            $reportsApplicationName = 'ReportServerWebApp'
        }
        else
        {
            $reportsApplicationName = 'ReportManager'
        }

        if(!$reportingServicesConfiguration.IsInitialized)
        {
            New-VerboseMessage -Message "Initializing Reporting Services on $RSSQLServer\$RSSQLInstanceName."

            if ( $ReportServerReservedUrl -eq $null )
            {
                $ReportServerReservedUrl = @("http://+:80")
            }

            if ( $ReportsReservedUrl -eq $null )
            {
                $ReportsReservedUrl = @("http://+:80")
            }

            if ( $reportingServicesConfiguration.VirtualDirectoryReportServer -ne $ReportServerVirtualDir )
            {
                New-VerboseMessage -Message "Setting report server virtual directory on $RSSQLServer\$RSSQLInstanceName to $ReportServerVirtualDir."
                $null = $reportingServicesConfiguration.SetVirtualDirectory("ReportServerWebService",$ReportServerVirtualDir,$language)
                $ReportServerReservedUrl | ForEach-Object {
                    New-VerboseMessage -Message "Adding report server URL reservation on $RSSQLServer\$RSSQLInstanceName`: $_."
                    $null = $reportingServicesConfiguration.ReserveURL("ReportServerWebService",$_,$language)
                }
            }

            if ( $reportingServicesConfiguration.VirtualDirectoryReportManager -ne $ReportsVirtualDir )
            {
                New-VerboseMessage -Message "Setting reports virtual directory on $RSSQLServer\$RSSQLInstanceName to $ReportServerVirtualDir."
                $null = $reportingServicesConfiguration.SetVirtualDirectory($reportsApplicationName,$ReportsVirtualDir,$language)
                $ReportsReservedUrl | ForEach-Object {
                    New-VerboseMessage -Message "Adding reports URL reservation on $RSSQLServer\$RSSQLInstanceName`: $_."
                    $null = $reportingServicesConfiguration.ReserveURL($reportsApplicationName,$_,$language)
                }
            }
            $reportingServicesDatabaseScript = $reportingServicesConfiguration.GenerateDatabaseCreationScript($reportingServicesDatabaseName,$language,$false)

            # Determine RS service account
            $reportingServicesServiceAccountUserName = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $reportingServicesServiceName}).StartName
            $reportingServicesDatabaseRightsScript = $reportingServicesConfiguration.GenerateDatabaseRightsScript($reportingServicesServiceAccountUserName,$reportingServicesDatabaseName,$false,$true)

            <#
                Import-SQLPSModule cmdlet will import SQLPS (SQL 2012/14) or SqlServer module (SQL 2016),
                and if importing SQLPS, change directory back to the original one, since SQLPS changes the
                current directory to SQLSERVER:\ on import.
            #>
            Import-SQLPSModule
            Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseScript.Script
            Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseRightsScript.Script

            $null = $reportingServicesConfiguration.SetDatabaseConnection($reportingServicesConnection,$reportingServicesDatabaseName,2,"","")
            $null = $reportingServicesConfiguration.InitializeReportServer($reportingServicesConfiguration.InstallationID)

            Restart-ReportingServicesService -SQLInstanceName $InstanceName
        }
        else
        {
            $currentConfig = Get-TargetResource @PSBoundParameters

            if (![string]::IsNullOrEmpty($ReportServerVirtualDir) -and ($ReportServerVirtualDir -ne $currentConfig.ReportServerVirtualDir) )
            {
                New-VerboseMessage -Message "Setting report server virtual directory on $RSSQLServer\$RSSQLInstanceName to $ReportServerVirtualDir."

                <#
                    to change a virtual directory, we first need to remove all URL reservations,
                    change the virtual directory and re-add URL reservations
                #>
                $currentConfig.ReportServerReservedUrl | ForEach-Object { $null = $reportingServicesConfiguration.RemoveURL("ReportServerWebService",$_,$language) }
                $reportingServicesConfiguration.SetVirtualDirectory("ReportServerWebService",$ReportServerVirtualDir,$language)
                $currentConfig.ReportServerReservedUrl | ForEach-Object { $null = $reportingServicesConfiguration.ReserveURL("ReportServerWebService",$_,$language) }
            }

            if (![string]::IsNullOrEmpty($ReportsVirtualDir) -and ($ReportsVirtualDir -ne $currentConfig.ReportsVirtualDir) )
            {
                New-VerboseMessage -Message "Setting reports virtual directory on $RSSQLServer\$RSSQLInstanceName to $ReportServerVirtualDir."

                <#
                    to change a virtual directory, we first need to remove all URL reservations,
                    change the virtual directory and re-add URL reservations
                #>
                $currentConfig.ReportsReservedUrl | ForEach-Object { $null = $reportingServicesConfiguration.RemoveURL($reportsApplicationName,$_,$language) }
                $reportingServicesConfiguration.SetVirtualDirectory($reportsApplicationName,$ReportsVirtualDir,$language)
                $currentConfig.ReportsReservedUrl | ForEach-Object { $null = $reportingServicesConfiguration.ReserveURL($reportsApplicationName,$_,$language) }
            }

            if ( ($ReportServerReservedUrl -ne $null) -and ((Compare-Object -ReferenceObject $currentConfig.ReportServerReservedUrl -DifferenceObject $ReportServerReservedUrl) -ne $null) )
            {
                $currentConfig.ReportServerReservedUrl | ForEach-Object {
                    $null = $reportingServicesConfiguration.RemoveURL("ReportServerWebService",$_,$language)
                }

                $ReportServerReservedUrl | ForEach-Object {
                    New-VerboseMessage -Message "Adding report server URL reservation on $RSSQLServer\$RSSQLInstanceName`: $_."
                    $null = $reportingServicesConfiguration.ReserveURL("ReportServerWebService",$_,$language)
                }
            }

            if ( ($ReportsReservedUrl -ne $null) -and ((Compare-Object -ReferenceObject $currentConfig.ReportsReservedUrl -DifferenceObject $ReportsReservedUrl) -ne $null) )
            {
                $currentConfig.ReportsReservedUrl | ForEach-Object {
                    $null = $reportingServicesConfiguration.RemoveURL($reportsApplicationName,$_,$language)
                }

                $ReportsReservedUrl | ForEach-Object {
                    New-VerboseMessage -Message "Adding reports URL reservation on $RSSQLServer\$RSSQLInstanceName`: $_."
                    $null = $reportingServicesConfiguration.ReserveURL($reportsApplicationName,$_,$language)
                }
            }
        }
    }

    if ( !(Test-TargetResource @PSBoundParameters) )
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    Tests the SQL Reporting Services initialization status.

    .PARAMETER InstanceName
    Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER RSSQLServer
    Name of the SQL Server to host the Reporting Service database.

    .PARAMETER RSSQLInstanceName
    Name of the SQL Server instance to host the Reporting Service database.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $RSSQLInstanceName,

        [parameter()]
        [System.String]
        $ReportServerVirtualDir,

        [parameter()]
        [System.String]
        $ReportsVirtualDir,

        [parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [parameter()]
        [System.String[]]
        $ReportsReservedUrl
    )

    $result = $true

    $currentConfig = Get-TargetResource @PSBoundParameters

    if ( !$currentConfig.IsInitialized )
    {
        New-VerboseMessage -Message "Reporting services $RSSQLServer\$RSSQLInstanceName are not initialized."
        $result = $false
    }

    if ( ![string]::IsNullOrEmpty($ReportServerVirtualDir) -and ($ReportServerVirtualDir -ne $currentConfig.ReportServerVirtualDir) )
    {
        New-VerboseMessage -Message "Report server virtual directory on $RSSQLServer\$RSSQLInstanceName is $($currentConfig.ReportServerVirtualDir), should be $ReportServerVirtualDir."
        $result = $false
    }

    if ( ![string]::IsNullOrEmpty($ReportsVirtualDir) -and ($ReportsVirtualDir -ne $currentConfig.ReportsVirtualDir) )
    {
        New-VerboseMessage -Message "Reports virtual directory on $RSSQLServer\$RSSQLInstanceName is $($currentConfig.ReportsVirtualDir), should be $ReportsVirtualDir."
        $result = $false
    }

    if ( ($ReportServerReservedUrl -ne $null) -and ((Compare-Object -ReferenceObject $currentConfig.ReportServerReservedUrl -DifferenceObject $ReportServerReservedUrl) -ne $null) )
    {
        New-VerboseMessage -Message "Report server reserved URLs on $RSSQLServer\$RSSQLInstanceName are $($currentConfig.ReportServerReservedUrl -join ', '), should be $($ReportServerReservedUrl -join ', ')."
        $result = $false
    }

    if ( ($ReportsReservedUrl -ne $null) -and ((Compare-Object -ReferenceObject $currentConfig.ReportsReservedUrl -DifferenceObject $ReportsReservedUrl) -ne $null) )
    {
        New-VerboseMessage -Message "Reports reserved URLs on $RSSQLServer\$RSSQLInstanceName are $($currentConfig.ReportsReservedUrl -join ', ')), should be $($ReportsReservedUrl -join ', ')."
        $result = $false
    }

    $result
}

Export-ModuleMember -Function *-TargetResource
