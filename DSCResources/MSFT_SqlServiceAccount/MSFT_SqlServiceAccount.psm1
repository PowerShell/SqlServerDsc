Import-Module -Name (Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1')

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlServiceAccount'

<#
    .SYNOPSIS
        Gets the service account for the specified instance.

    .PARAMETER ServerName
        Host name of the SQL Server to manage.

    .PARAMETER InstanceName
        Name of the SQL instance.

    .PARAMETER ServiceType
        Type of service to be managed. Must be one of the following:
        DatabaseEngine, SQLServerAgent, Search, IntegrationServices, AnalysisServices, ReportingServices, SQLServerBrowser, NotificationServices.

    .PARAMETER ServiceAccount
        ** Not used in this function **
         Credential of the service account that should be used.

    .PARAMETER VersionNumber
        ** Only used when specifying IntegrationServices **
        Version number of IntegrationServices.

    .EXAMPLE
        Get-TargetResource -ServerName $env:COMPUTERNAME -InstanceName MSSQLSERVER -ServiceType DatabaseEngine -ServiceAccount $account
        Get-TargetResource -ServerName $env:COMPUTERNAME -InstanceName MSSQLSERVER -ServiceType IntegrationServices -ServiceAccount $account -VersionNumber 130
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseEngine', 'SQLServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String]
        $ServiceType,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter(Mandatory=$false)]
        [System.String]
        $VersionNumber
    )

    # Get the SMO Service object instance
    $serviceObject = Get-ServiceObject -ServerName $ServerName -InstanceName $InstanceName -ServiceType $ServiceType -VersionNumber $VersionNumber

    # If no service was found, throw an exception
    if (-not $serviceObject)
    {
        $errorMessage = $script:localizedData.ServiceNotFound -f $ServiceType, $ServerName, $InstanceName
        New-ObjectNotFoundException -Message $errorMessage
    }

    # Local accounts will start with a '.'
    # Replace a domain of '.' with the value for $ServerName
    $serviceAccountName = $serviceObject.ServiceAccount -ireplace '^([\.])\\(.*)$', "$ServerName\`$2"

    # Return a hash table with the service information
    return @{
        ServerName         = $ServerName
        InstanceName       = $InstanceName
        ServiceType        = $serviceObject.Type
        ServiceAccountName = $serviceAccountName
    }
}

<#
    .SYNOPSIS
        Tests whether the specified instance's service account is correctly configured.

    .PARAMETER ServerName
        Host name of the SQL Server to manage.

    .PARAMETER InstanceName
        Name of the SQL instance.

    .PARAMETER ServiceType
        Type of service to be managed. Must be one of the following:
        DatabaseEngine, SQLServerAgent, Search, IntegrationServices, AnalysisServices, ReportingServices, SQLServerBrowser, NotificationServices.

    .PARAMETER ServiceAccount
        Credential of the service account that should be used.

    .PARAMETER RestartService
        Determines whether the service is automatically restarted when a change
        to the configuration was needed.

    .PARAMETER Force
        Forces the service account to be updated.

    .PARAMETER VersionNumber
        Version number of IntegrationServices

    .EXAMPLE
        Test-TargetResource -ServerName $env:COMPUTERNAME -InstanceName MSSQLSERVER -ServiceType DatabaseEngine -ServiceAccount $account
        Test-TargetResource -ServerName $env:COMPUTERNAME -InstanceName MSSQLSERVER -SerticeType IntegrationServices -ServiceAccount $account -VersionNumber 130

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseEngine', 'SQLServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String]
        $ServiceType,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter()]
        [System.Boolean]
        $RestartService,

        [Parameter()]
        [System.Boolean]
        $Force,

        [Parameter()]
        [System.String]
        $VersionNumber
    )

    if ($Force)
    {
        New-VerboseMessage -Message $script:localizedData.ForceServiceAccountUpdate
        return $false
    }

    # Get the current state
    $currentState = Get-TargetResource -ServerName $ServerName -InstanceName $InstanceName -ServiceType $ServiceType -ServiceAccount $ServiceAccount -VersionNumber $VersionNumber
    New-VerboseMessage -Message ($script:localizedData.CurrentServiceAccount -f $currentState.ServiceAccountName, $ServerName, $InstanceName)

    return ($currentState.ServiceAccountName -ieq $ServiceAccount.UserName)
}

<#
    .SYNOPSIS
        Sets the SQL Server service account to the desired state.

    .PARAMETER ServerName
        Host name of the SQL Server to manage.

    .PARAMETER InstanceName
        Name of the SQL instance.

    .PARAMETER ServiceType
        Type of service to be managed. Must be one of the following:
        DatabaseEngine, SQLServerAgent, Search, IntegrationServices, AnalysisServices, ReportingServices, SQLServerBrowser, NotificationServices.

    .PARAMETER ServiceAccount
        Credential of the service account that should be used.

    .PARAMETER RestartService
        Determines whether the service is automatically restarted when a change
        to the configuration was needed.

    .PARAMETER Force
        Forces the service account to be updated.

    .PARAMETER VersionNumber
        Version number of IntegrationServices

    .EXAMPLE
        Set-TargetResource -ServerName $env:COMPUTERNAME -InstanceName MSSQLSERVER -ServiceType DatabaseEngine -ServiceAccount $account
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseEngine', 'SQLServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String]
        $ServiceType,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter()]
        [System.Boolean]
        $RestartService,

        [Parameter()]
        [System.Boolean]
        $Force,

        [Parameter()]
        [System.String]
        $VersionNumber
    )

    # Get the Service object
    $serviceObject = Get-ServiceObject -ServerName $ServerName -InstanceName $InstanceName -ServiceType $ServiceType -VersionNumber $VersionNumber

    # If no service was found, throw an exception
    if (-not $serviceObject)
    {
        $errorMessage = $script:localizedData.ServiceNotFound -f $ServiceType, $ServerName, $InstanceName
        New-ObjectNotFoundException -Message $errorMessage
    }

    try
    {
        New-VerboseMessage -Message ($script:localizedData.UpdatingServiceAccount -f $ServiceAccount.UserName, $serviceObject.Name)
        $account = Get-ServiceAccount -ServiceAccount $ServiceAccount
        $serviceObject.SetServiceAccount($account.UserName, $account.Password)
    }
    catch
    {
        $errorMessage = $script:localizedData.SetServiceAccountFailed -f $ServerName, $InstanceName, $_.Message
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    if ($RestartService)
    {
        New-VerboseMessage -Message ($script:localizedData.RestartingService -f $InstanceName)
        Restart-SqlService -SQLServer $ServerName -SQLInstanceName $InstanceName
    }
}

<#
    .SYNOPSIS
        Gets an SMO Service object instance for the requested service and type.

    .PARAMETER ServerName
        Host name of the SQL Server to manage.

    .PARAMETER InstanceName
        Name of the SQL instance.

    .PARAMETER ServiceType
        Type of service to be managed. Must be one of the following:
        DatabaseEngine, SQLServerAgent, Search, IntegrationServices, AnalysisServices, ReportingServices, SQLServerBrowser, NotificationServices.
    
    .PARAMETER VersionNumber
        Version number of IntegrationServices.

    .EXAMPLE
        Get-ServiceObject -ServerName $env:COMPUTERNAME -InstanceName MSSQLSERVER -ServiceType DatabaseEngine
        Get-ServiceObject -ServerName $env:COMPUTERNAME -InstanceName MSSQLSERVER -ServiceType IntegrationServices -VersionNumber 130
#>
function Get-ServiceObject
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseEngine', 'SQLServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String]
        $ServiceType,

        [Parameter(Mandatory = $false)]
        [System.String]
        $VersionNumber
    )

    # Check to see if Integration services was specified, but no version specified
    if (($ServiceType -eq "IntegrationServices") -and ([String]::IsNullOrEmpty($VersionNumber)))
    {
        $errorMessage = $script:localizedData.UnknownServiceType -f $ServiceType
        New-InvalidArgumentException -Message $errorMessage -ArgumentName 'VersionNumber'        
    }

    # Load the SMO libraries
    Import-SQLPSModule

    $verboseMessage = $script:localizedData.ConnectingToWmi -f $ServerName
    New-VerboseMessage -Message $verboseMessage

    # Connect to SQL WMI
    $managedComputer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer -ArgumentList $ServerName

    # Get the service name for the specified instance and type
    $serviceNameFilter = Get-SqlServiceName -InstanceName $InstanceName -ServiceType $ServiceType

    # Check the service type and append version number if IntegrationServices
    if ($ServiceType -eq "IntegrationServices")
    {
        # Append version number
        $serviceNameFilter = $serviceNameFilter + $VersionNumber
    }

    # Get the Service object for the specified instance/type
    $serviceObject = $managedComputer.Services | Where-Object -FilterScript {
        $_.Name -eq "$serviceNameFilter"
    }

    return $serviceObject
}

<#
    .SYNOPSIS
        Converts the project's standard SQL Service types to the appropriate ManagedServiceType value

    .PARAMETER ServiceType
        Type of service to be managed. Must be one of the following:
        DatabaseEngine, SQLServerAgent, Search, IntegrationServices, AnalysisServices, ReportingServices, SQLServerBrowser, NotificationServices.

    .EXAMPLE
        ConvertTo-ManagedServiceType -ServiceType 'DatabaseEngine'
#>
function ConvertTo-ManagedServiceType
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseEngine', 'SQLServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String]
        $ServiceType
    )

    # Map the project-specific ServiceType to a valid value from the ManagedServiceType enumeration
    switch ($ServiceType)
    {
        'DatabaseEngine'
        {
            $serviceTypeValue = 'SqlServer'
        }

        'SQLServerAgent'
        {
            $serviceTypeValue = 'SqlAgent'
        }

        'Search'
        {
            $serviceTypeValue = 'Search'
        }

        'IntegrationServices'
        {
            $serviceTypeValue = 'SqlServerIntegrationService'
        }

        'AnalysisServices'
        {
            $serviceTypeValue = 'AnalysisServer'
        }

        'ReportingServices'
        {
            $serviceTypeValue = 'ReportServer'
        }

        'SQLServerBrowser'
        {
            $serviceTypeValue = 'SqlBrowser'
        }

        'NotificationServices'
        {
            $serviceTypeValue = 'NotificationServer'
        }
    }

    return $serviceTypeValue -as [Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType]
}

<#
    .SYNOPSIS
        Gets the name of a service based on the instance name and type.

    .PARAMETER InstanceName
        Name of the SQL instance.

    .PARAMETER ServiceType
        Type of service to be named. Must be one of the following:
        DatabaseEngine, SQLServerAgent, Search, IntegrationServices, AnalysisServices, ReportingServices, SQLServerBrowser, NotificationServices.

    .PARAMETER VersionNumber
        Version number of IntegrationServices.

    .EXAMPLE
        Get-SqlServiceName -InstanceName 'MSSQLSERVER' -ServiceType ReportingServices
#>
function Get-SqlServiceName
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseEngine', 'SQLServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String]
        $ServiceType
    )

    # Base path in the registry for service name definitions
    $serviceRegistryKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services'

    # The value grabbed varies for a named vs default instance
    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $propertyName = 'Name'
        $returnValue = '{0}'
    }
    else
    {
        $propertyName = 'LName'
        $returnValue = '{0}{1}'
    }

    # Map the specified type to a ManagedServiceType
    $managedServiceType = ConvertTo-ManagedServiceType -ServiceType $ServiceType

    # Get the required naming property
    $serviceTypeDefinition = Get-ChildItem -Path $serviceRegistryKey | Where-Object -FilterScript {
        $_.GetValue('Type') -eq ($managedServiceType -as [int])
    }

    # Ensure we got a service definition
    if ($serviceTypeDefinition)
    {
        # Multiple definitions found (thank you SQL Server Reporting Services!)
        if ($serviceTypeDefinition.Count -gt 0)
        {
            $serviceNamingScheme = $serviceTypeDefinition | ForEach-Object -Process {
                $_.GetValue($propertyName)
            } | Select-Object -Unique
        }
        else
        {
            $serviceNamingScheme = $serviceTypeDefinition.GetValue($propertyName)
        }
    }
    else
    {
        $errorMessage = $script:localizedData.UnknownServiceType -f $ServiceType
        New-InvalidArgumentException -Message $errorMessage -ArgumentName 'ServiceType'
    }

    if ([System.String]::IsNullOrEmpty($serviceNamingScheme))
    {
        $errorMessage = $script:localizedData.NotInstanceAware -f $ServiceType
        New-InvalidResultException -Message $errorMessage
    }

    # Build the name of the service and return it
    return ($returnValue -f $serviceNamingScheme, $InstanceName)
}

