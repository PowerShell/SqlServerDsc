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

            $reportServerVirtualDirectory = $reportingServicesConfiguration.VirtualDirectoryReportServer
            $reportsVirtualDirectory = $reportingServicesConfiguration.VirtualDirectoryReportManager

            $reservedUrls = $reportingServicesConfiguration.ListReservedUrls()

            $reportServerReservedUrl = @()
            $reportsReservedUrl = @()

            for ( $i = 0; $i -lt $reservedUrls.Application.Count; ++$i )
            {
                if ( $reservedUrls.Application[$i] -eq "ReportServerWebService" )
                {
                    $reportServerReservedUrl += $reservedUrls.UrlString[$i]
                }

                if ( $reservedUrls.Application[$i] -eq $reportsApplicationName )
                {
                    $reportsReservedUrl += $reservedUrls.UrlString[$i]
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
        ReportServerVirtualDirectory = $reportServerVirtualDirectory
        ReportsVirtualDirectory = $reportsVirtualDirectory
        ReportServerReservedUrl = $reportServerReservedUrl
        ReportsReservedUrl = $reportsReservedUrl
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

    .PARAMETER ReportServerVirtualDirectory
    Report Server Web Service virtual directory. Optional.

    .PARAMETER ReportsVirtualDirectory
    Report Manager/Report Web App virtual directory name. Optional.

    .PARAMETER ReportServerReservedUrl
    Report Server URL reservations. Optional. If not specified, "http://+:80" URL reservation will be used.

    .PARAMETER ReportsReservedUrl
    Report Manager/Report Web App URL reservations. Optional. If not specified, "http://+:80" URL reservation will be used.
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

        [Parameter()]
        [System.String]
        $ReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $ReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [Parameter()]
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
            if ( [string]::IsNullOrEmpty($ReportServerVirtualDirectory) )
            {
                $ReportServerVirtualDirectory = 'ReportServer'
            }

            if ( [string]::IsNullOrEmpty($ReportsVirtualDirectory) )
            {
                $ReportsVirtualDirectory = 'Reports'
            }

            $reportingServicesServiceName = 'ReportServer'
            $reportingServicesDatabaseName = 'ReportServer'
        }
        else
        {
            if ( [string]::IsNullOrEmpty($ReportServerVirtualDirectory) )
            {
                $ReportServerVirtualDirectory = "ReportServer_$InstanceName"
            }

            if ( [string]::IsNullOrEmpty($ReportsVirtualDirectory) )
            {
                $ReportsVirtualDirectory = "Reports_$InstanceName"
            }

            $reportingServicesServiceName = "ReportServer`$$InstanceName"
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

        if ( -not $reportingServicesConfiguration.IsInitialized )
        {
            New-VerboseMessage -Message "Initializing Reporting Services on $RSSQLServer\$RSSQLInstanceName."

            if ( $null -ne $ReportServerReservedUrl )
            {
                $ReportServerReservedUrl = @('http://+:80')
            }

            if ( $null -ne $ReportsReservedUrl )
            {
                $ReportsReservedUrl = @('http://+:80')
            }

            if ( $reportingServicesConfiguration.VirtualDirectoryReportServer -ne $ReportServerVirtualDirectory )
            {
                New-VerboseMessage -Message "Setting report server virtual directory on $RSSQLServer\$RSSQLInstanceName to $ReportServerVirtualDirectory."
                $null = $reportingServicesConfiguration.SetVirtualDirectory('ReportServerWebService',$ReportServerVirtualDirectory,$language)
                $ReportServerReservedUrl | ForEach-Object {
                    New-VerboseMessage -Message "Adding report server URL reservation on $RSSQLServer\$RSSQLInstanceName`: $_."
                    $null = $reportingServicesConfiguration.ReserveURL('ReportServerWebService',$_,$language)
                }
            }

            if ( $reportingServicesConfiguration.VirtualDirectoryReportManager -ne $ReportsVirtualDirectory )
            {
                New-VerboseMessage -Message "Setting reports virtual directory on $RSSQLServer\$RSSQLInstanceName to $ReportServerVirtualDirectory."
                $null = $reportingServicesConfiguration.SetVirtualDirectory($reportsApplicationName,$ReportsVirtualDirectory,$language)
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

            $null = $reportingServicesConfiguration.SetDatabaseConnection($reportingServicesConnection,$reportingServicesDatabaseName,2,'','')
            $null = $reportingServicesConfiguration.InitializeReportServer($reportingServicesConfiguration.InstallationID)

            Restart-ReportingServicesService -SQLInstanceName $InstanceName
        }
        else
        {
            $currentConfig = Get-TargetResource @PSBoundParameters

            if ( ![string]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory) )
            {
                New-VerboseMessage -Message "Setting report server virtual directory on $RSSQLServer\$RSSQLInstanceName to $ReportServerVirtualDirectory."

                <#
                    to change a virtual directory, we first need to remove all URL reservations,
                    change the virtual directory and re-add URL reservations
                #>
                $currentConfig.ReportServerReservedUrl | ForEach-Object { $null = $reportingServicesConfiguration.RemoveURL('ReportServerWebService',$_,$language) }
                $reportingServicesConfiguration.SetVirtualDirectory('ReportServerWebService',$ReportServerVirtualDirectory,$language)
                $currentConfig.ReportServerReservedUrl | ForEach-Object { $null = $reportingServicesConfiguration.ReserveURL('ReportServerWebService',$_,$language) }
            }

            if ( ![string]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory) )
            {
                New-VerboseMessage -Message "Setting reports virtual directory on $RSSQLServer\$RSSQLInstanceName to $ReportServerVirtualDirectory."

                <#
                    to change a virtual directory, we first need to remove all URL reservations,
                    change the virtual directory and re-add URL reservations
                #>
                $currentConfig.ReportsReservedUrl | ForEach-Object { $null = $reportingServicesConfiguration.RemoveURL($reportsApplicationName,$_,$language) }
                $reportingServicesConfiguration.SetVirtualDirectory($reportsApplicationName,$ReportsVirtualDirectory,$language)
                $currentConfig.ReportsReservedUrl | ForEach-Object { $null = $reportingServicesConfiguration.ReserveURL($reportsApplicationName,$_,$language) }
            }

            $reportServerReservedUrlDifference = Compare-Object -ReferenceObject $currentConfig.ReportServerReservedUrl -DifferenceObject $ReportServerReservedUrl
            if ( ($null -ne $ReportServerReservedUrl) -and ($null -ne $reportServerReservedUrlDifference) )
            {
                $currentConfig.ReportServerReservedUrl | ForEach-Object {
                    $null = $reportingServicesConfiguration.RemoveURL('ReportServerWebService',$_,$language)
                }

                $ReportServerReservedUrl | ForEach-Object {
                    New-VerboseMessage -Message "Adding report server URL reservation on $RSSQLServer\$RSSQLInstanceName`: $_."
                    $null = $reportingServicesConfiguration.ReserveURL('ReportServerWebService',$_,$language)
                }
            }

            $reportsReservedUrlDifference = Compare-Object -ReferenceObject $currentConfig.ReportsReservedUrl -DifferenceObject $ReportsReservedUrl
            if ( ($null -ne $ReportsReservedUrl) -and ($null -ne $reportsReservedUrlDifference) )
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

    .PARAMETER ReportServerVirtualDirectory
    Report Server Web Service virtual directory. Optional.

    .PARAMETER ReportsVirtualDirectory
    Report Manager/Report Web App virtual directory name. Optional.

    .PARAMETER ReportServerReservedUrl
    Report Server URL reservations. Optional. If not specified, "http://+:80" URL reservation will be used.

    .PARAMETER ReportsReservedUrl
    Report Manager/Report Web App URL reservations. Optional. If not specified, "http://+:80" URL reservation will be used.
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

        [Parameter()]
        [System.String]
        $ReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $ReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [Parameter()]
        [System.String[]]
        $ReportsReservedUrl
    )

    $result = $true

    $currentConfig = Get-TargetResource @PSBoundParameters

    if ( -not $currentConfig.IsInitialized )
    {
        New-VerboseMessage -Message "Reporting services $RSSQLServer\$RSSQLInstanceName are not initialized."
        $result = $false
    }

    if ( ![string]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory) )
    {
        New-VerboseMessage -Message "Report server virtual directory on $RSSQLServer\$RSSQLInstanceName is $($currentConfig.ReportServerVirtualDir), should be $ReportServerVirtualDirectory."
        $result = $false
    }

    if ( ![string]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory) )
    {
        New-VerboseMessage -Message "Reports virtual directory on $RSSQLServer\$RSSQLInstanceName is $($currentConfig.ReportsVirtualDir), should be $ReportsVirtualDirectory."
        $result = $false
    }

    $reportServerReservedUrlDifference = Compare-Object -ReferenceObject $currentConfig.ReportServerReservedUrl -DifferenceObject $ReportServerReservedUrl
    if ( ($null -ne $ReportServerReservedUrl) -and ($null -ne $reportServerReservedUrlDifference) )
    {
        New-VerboseMessage -Message "Report server reserved URLs on $RSSQLServer\$RSSQLInstanceName are $($currentConfig.ReportServerReservedUrl -join ', '), should be $($ReportServerReservedUrl -join ', ')."
        $result = $false
    }

    $reportsReservedUrlDifference = Compare-Object -ReferenceObject $currentConfig.ReportsReservedUrl -DifferenceObject $ReportsReservedUrl
    if ( ($null -ne $ReportsReservedUrl) -and ($null -ne $reportsReservedUrlDifference) )
    {
        New-VerboseMessage -Message "Reports reserved URLs on $RSSQLServer\$RSSQLInstanceName are $($currentConfig.ReportsReservedUrl -join ', ')), should be $($ReportsReservedUrl -join ', ')."
        $result = $false
    }

    $result
}

Export-ModuleMember -Function *-TargetResource
