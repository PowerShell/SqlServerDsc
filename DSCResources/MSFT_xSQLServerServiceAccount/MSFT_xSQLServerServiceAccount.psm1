Import-Module -Name (Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1')

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_xSQLServerServiceAccount'

New-VerboseMessage -Message $script:localizedData.LoadingAssemblies
$null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')
$null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.WmiEnum')

<#
    .SYNOPSIS
    Gets the service account for the specified instance

    .PARAMETER ServiceName
    Name of the SQL Server service
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [String]
        $ServiceName = 'MSSQLSERVER'
    )

    $managedComputer = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $SQLServer
    $serviceObject = $managedComputer.Services | Where-Object { $_.Name -ieq $ServiceName }

    if (-not $serviceObject)
    {
        $errorMessage = $script:localizedData.InvalidServiceName -f $ServiceName
        New-InvalidArgument -Message $errorMessage -ArgumentName 'ServiceName'
    }

    return @{
        ServiceName = $ServiceName
        ServiceAccount = $serviceObject.ServiceAccount
    }
}

<#
    .SYNOPSIS
    Tests whether the specified instance's service account is correctly configured.

    .PARAMETER SQLServer
    Host name of the SQL Server to manage

    .PARAMETER SQLInstanceName
    Name of the SQL instance.

    .PARAMETER ServiceType
    Type of service to be managed. Must be one of the following:
    SqlServer, SqlAgent, Search, SqlServerIntegrationService, AnalysisServer, ReportServer, SqlBrowser, NotificationServer

    .PARAMETER ServiceAccount
    Credential of the service account that should be used.

    .PARAMETER RestartService
    Determines whether the service is automatically restarted

    .PARAMETER Force
    Forces the service account to be updated.

    .EXAMPLE
    Test-TargetResource -SQLServer $env:COMPUTERNAME -SQLInstaneName MSSQLSERVER -ServiceType SqlServer -ServiceAccount $account

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Paramter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Paramter(Mandatory = $true)]
        [ValidateSet('SqlServer','SqlAgent','Search','SqlServerIntegrationService','AnalysisServer','ReportServer','SqlBrowser','NotificationServer')]
        [String]
        $ServiceType,

        [Paramter(Mandatory = $true)]
        [PSCredential]
        $ServiceAccount,

        [Boolean]
        $RestartService,

        [Boolean]
        $Force
    )

    if ($Force)
    {
        New-VerboseMessage -Message $script:localizedData.ForceServiceAccountUpdate
        return $false
    }

    # Determine the service name
    $serviceName = Resolve-ServiceName -SQLInstanceName $SQLInstanceName -ServiceType $ServiceType

    # Get the current state
    $currentState = Get-TargetResource -ServiceName $serviceName
    New-VerboseMessage -Message ($script:localizedData.CurrentServiceAccount -f $currentState.ServiceAccount)

    return ($currentState.ServiceAccount -ieq $ServiceAccount.UserName)
}

<#
    .SYNOPSIS
    Sets the SQL Server service account to the desired state.

    .PARAMETER SQLServer
    Host name of the SQL Server to manage

    .PARAMETER SQLInstanceName
    Name of the SQL instance.

    .PARAMETER ServiceType
    Type of service to be managed. Must be one of the following:
    SqlServer, SqlAgent, Search, SqlServerIntegrationService, AnalysisServer, ReportServer, SqlBrowser, NotificationServer

    .PARAMETER ServiceAccount
    Credential of the service account that should be used.

    .PARAMETER RestartService
    Determines whether the service is automatically restarted

    .PARAMETER Force
    Forces the service account to be updated.

    .EXAMPLE
    Set-TargetResource -SQLServer $env:COMPUTERNAME -SQLInstaneName MSSQLSERVER -ServiceType SqlServer -ServiceAccount $account
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Paramter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Paramter(Mandatory = $true)]
        [ValidateSet('SqlServer','SqlAgent','Search','SqlServerIntegrationService','AnalysisServer','ReportServer','SqlBrowser','NotificationServer')]
        [String]
        $ServiceType,

        [Paramter(Mandatory = $true)]
        [PSCredential]
        $ServiceAccount,

        [Boolean]
        $RestartService,

        [Boolean]
        $Force
    )

    $serviceName = Resolve-ServiceName -SQLInstanceName $SQLInstanceName -ServiceType $ServiceType

    New-VerboseMessage -Message $script:localizedData.ConnectingToWmi
    $managedComputer = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
    $serviceObject = $managedComputer.Services | Where-Object { $_.Name -ieq $serviceName }

    try
    {
        New-VerboseMessage -Message ($script:localizedData.UpdatingServiceAccount -f $ServiceAccount.UserName)
        $serviceObject.SetServiceAccount($ServiceAccount.UserName, $ServiceAccount.GetNetworkCredential().Password)
    }
    catch
    {
        throw $_
    }

    if ($RestartService)
    {
        New-VerboseMessage -Message ($script:localizedData.RestartingService -f $serviceName)
        Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }
}

<#
    .SYNOPSIS
    Converts an ID to a ManagedServiceType

    .PARAMETER Id
    Integer identifying the ManagedServiceType

    .EXAMPLE
    $typeId = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services\SQL Server\' -Name Type
    ConvertTo-ManagedServiceType -Id $typeId
#>
function ConvertTo-ManagedServiceType
{
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Int]
        $Id
    )

    switch ($Id)
    {
        1 { $enumValue = 'SqlServer' }
        2 { $enumValue = 'SqlAgent' }
        3 { $enumValue = 'Search' }
        4 { $enumValue = 'SqlServerIntegrationService' }
        5 { $enumValue = 'AnalysisServer' }
        6 { $enumValue = 'ReportServer' }
        7 { $enumValue = 'SqlBrowser' }
        8 { $enumValue = 'NotificationServer' }
        9 { $enumValue = 'Search' }
        default
        {
            $errorMessage = $script:localizedData.InvalidServiceTypeId -f $Id
            New-InvalidArgumentException -Message $errorMessage -ArgumentName 'Id'
        }
    }

    return ($enumValue -as [Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType])
}

<#
    .SYNOPSIS
    Gets the name of a service based on the type and instance name

    .PARAMETER SQLInstanceName
    The name of the SQL Server instance

    .PARAMETER ServiceType
    Type of service this instance supports.

    .EXAMPLE
    Resolve-ServiceName -SQLInstanceName Accounting -ServiceType SqlServer

    Will resovlve the service name for a SQL Server instance named "Accounting"

#>
function Resolve-ServiceName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('SqlServer','SqlAgent','Search','SqlServerIntegrationService','AnalysisServer','ReportServer','SqlBrowser','NotificationServer')]
        [String]
        $ServiceType
    )

    # Get the service naming information from the registry
    $serviceNamingScheme = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services' |
        Where-Object { (ConvertTo-ManagedServiceType -Id $_.GetVaue('Type')) -ieq $ServiceType } |
        Get-ItemProperty -Name Type, Name, LName

    # Default instance uses the default service name!
    if ($SQLInstanceName -ieq 'MSSQLSERVER')
    {
        return "$($serviceNamingScheme.Name)"
    }
    else
    {
        return "$($serviceNamingScheme.LName)$SQLInstanceName"
    }
}
