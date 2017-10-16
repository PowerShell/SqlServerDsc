# Load Localization Data
Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot `
                                                -ChildPath 'DscResources') `
                               -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'xSQLServerHelper' -ScriptRoot $PSScriptRoot

<#
    .SYNOPSIS
        Connect to a SQL Server Database Engine and return the server object.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting.
        If this is not provided then the current user will be used to connect to the SQL Server Database Engine instance.
#>
function Connect-SQL
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNull()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [ValidateNotNull()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )

    Import-SQLPSModule

    if ($SQLInstanceName -eq 'MSSQLSERVER')
    {
        $databaseEngineInstance = $SQLServer
    }
    else
    {
        $databaseEngineInstance = "$SQLServer\$SQLInstanceName"
    }

    if ($SetupCredential)
    {
        $sql = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
        $sql.ConnectionContext.ConnectAsUser = $true
        $sql.ConnectionContext.ConnectAsUserPassword = $SetupCredential.GetNetworkCredential().Password
        $sql.ConnectionContext.ConnectAsUserName = $SetupCredential.GetNetworkCredential().UserName
        $sql.ConnectionContext.ServerInstance = $databaseEngineInstance
        $sql.ConnectionContext.Connect()
    }
    else
    {
        $sql = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $databaseEngineInstance
    }

    if ( $sql.Status -match '^Online$' )
    {
        Write-Verbose -Message ($script:localizedData.ConnectedToDatabaseEngineInstance -f $databaseEngineInstance) -Verbose
        return $sql
    }
    else
    {
        $errorMessage = $script:localizedData.FailedToConnectToDatabaseEngineInstance -f $databaseEngineInstance
        New-InvalidOperationException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Connect to a SQL Server Analysis Service and return the server object.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Analysis Service instance to connect to.

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting.
        If this is not provided then the current user will be used to connect to the SQL Server Analysis Service instance.
#>
function Connect-SQLAnalysis
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SetupCredential
    )

    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.AnalysisServices')

    if ($SQLInstanceName -eq 'MSSQLSERVER')
    {
        $analysisServiceInstance = $SQLServer
    }
    else
    {
        $analysisServiceInstance = "$SQLServer\$SQLInstanceName"
    }

    if ($SetupCredential)
    {
        $userName = $SetupCredential.GetNetworkCredential().UserName
        $password = $SetupCredential.GetNetworkCredential().Password

        $analysisServicesDataSource = "Data Source=$analysisServiceInstance;User ID=$userName;Password=$password"
    }
    else
    {
        $analysisServicesDataSource = "Data Source=$analysisServiceInstance"
    }

    try
    {
        $analysisServicesObject = New-Object -TypeName Microsoft.AnalysisServices.Server
        if ($analysisServicesObject)
        {
            $analysisServicesObject.Connect($analysisServicesDataSource)
        }
        else
        {
            $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance
            New-InvalidOperationException -Message $errorMessage
        }

        Write-Verbose -Message ($script:localizedData.ConnectedToAnalysisServicesInstance -f $analysisServiceInstance) -Verbose
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    return $analysisServicesObject
}

<#
    .SYNOPSIS
        Creates a new application domain and loads the assemblies Microsoft.SqlServer.Smo
        for the correct SQL Server major version.

        An isolated application domain is used to load version specific assemblies, this needed
        if there is multiple versions of SQL server in the same configuration. So that a newer
        version of SQL is not using an older version of the assembly, or vice verse.

        This should be unloaded using the helper function Unregister-SqlAssemblies or
        using [System.AppDomain]::Unload($applicationDomainObject).

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance name to get the major SQL version from.

    .PARAMETER ApplicationDomain
        An optional System.AppDomain object to load the assembly into.

    .OUTPUTS
        System.AppDomain. Returns the application domain object with SQL SMO loaded.
#>
function Register-SqlSmo
{
    [CmdletBinding()]
    [OutputType([System.AppDomain])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.AppDomain]
        $ApplicationDomain
    )

    $sqlMajorVersion = Get-SqlInstanceMajorVersion -SQLInstanceName $SQLInstanceName

    Write-Verbose -Message ($script:localizedData.SqlMajorVersion -f $sqlMajorVersion) -Verbose

    if ( -not $ApplicationDomain )
    {
        $applicationDomainName = $MyInvocation.MyCommand.ModuleName
        Write-Verbose -Message ($script:localizedData.CreatingApplicationDomain -f $applicationDomainName) -Verbose
        $applicationDomainObject = [System.AppDomain]::CreateDomain($applicationDomainName)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.ReusingApplicationDomain -f $ApplicationDomain.FriendlyName) -Verbose
        $applicationDomainObject = $ApplicationDomain
    }

    $sqlSmoAssemblyName = "Microsoft.SqlServer.Smo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
    Write-Verbose -Message ($script:localizedData.LoadingAssembly -f $sqlSmoAssemblyName) -Verbose
    $applicationDomainObject.Load($sqlSmoAssemblyName) | Out-Null

    return $applicationDomainObject
}

<#
    .SYNOPSIS
        Creates a new application domain and loads the assemblies Microsoft.SqlServer.Smo and
        Microsoft.SqlServer.SqlWmiManagement for the correct SQL Server major version.

        An isolated application domain is used to load version specific assemblies, this needed
        if there is multiple versions of SQL server in the same configuration. So that a newer
        version of SQL is not using an older version of the assembly, or vice verse.

        This should be unloaded using the helper function Unregister-SqlAssemblies or
        using [System.AppDomain]::Unload($applicationDomainObject) preferably in a finally block.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance name to get the major SQL version from.

    .PARAMETER ApplicationDomain
        An optional System.AppDomain object to load the assembly into.

    .OUTPUTS
        System.AppDomain. Returns the application domain object with SQL WMI Management loaded.
#>
function Register-SqlWmiManagement
{
    [CmdletBinding()]
    [OutputType([System.AppDomain])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [Parameter()]
        [ValidateNotNull()]
        [System.AppDomain]
        $ApplicationDomain
    )

    $sqlMajorVersion = Get-SqlInstanceMajorVersion -SQLInstanceName $SQLInstanceName
    Write-Verbose -Message ($script:localizedData.SqlMajorVersion -f $sqlMajorVersion) -Verbose

    <#
        Must register Microsoft.SqlServer.Smo first because that is a
        dependency of Microsoft.SqlServer.SqlWmiManagement.
    #>
    if (-not $ApplicationDomain)
    {
        $applicationDomainObject = Register-SqlSmo -SQLInstanceName $SQLInstanceName
    }
    # Returns zero (0) objects if the assembly is not found
    elseif (-not ($ApplicationDomain.GetAssemblies().FullName -match 'Microsoft.SqlServer.Smo'))
    {
        $applicationDomainObject = Register-SqlSmo -SQLInstanceName $SQLInstanceName -ApplicationDomain $ApplicationDomain
    }

    $sqlSqlWmiManagementAssemblyName = "Microsoft.SqlServer.SqlWmiManagement, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
    Write-Verbose -Message ($script:localizedData.LoadingAssembly -f $sqlSqlWmiManagementAssemblyName) -Verbose
    $applicationDomainObject.Load($sqlSqlWmiManagementAssemblyName) | Out-Null

    return $applicationDomainObject
}

<#
    .SYNOPSIS
        Unloads all assemblies in an application domain. It unloads the application domain.

    .PARAMETER ApplicationDomain
        System.AppDomain object containing the SQL assemblies to unload.
#>
function Unregister-SqlAssemblies
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.AppDomain]
        $ApplicationDomain
    )

    Write-Verbose -Message ($script:localizedData.UnloadingApplicationDomain -f $ApplicationDomain.FriendlyName) -Verbose
    [System.AppDomain]::Unload($ApplicationDomain)
}

<#
    .SYNOPSIS
        Returns the major SQL version for the specific instance.

    .PARAMETER SQLInstanceName
        String containing the name of the SQL instance to be configured. Default value is 'MSSQLSERVER'.

    .OUTPUTS
        System.UInt16. Returns the SQL Server major version number.
#>
function Get-SqlInstanceMajorVersion
{
    [CmdletBinding()]
    [OutputType([System.UInt16])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    $sqlVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\Setup").Version

    if (-not $sqlVersion)
    {
        $errorMessage = $script:localizedData.SqlServerVersionIsInvalid -f $SQLInstanceName
        New-InvalidResultException -Message $errorMessage
    }

    [System.UInt16] $sqlMajorVersionNumber = $sqlVersion.Split('.')[0]

    return $sqlMajorVersionNumber
}

<#
    .SYNOPSIS
        Returns a localized error message.

        This helper function is obsolete, should use new helper functions.
        https://github.com/PowerShell/xSQLServer/blob/dev/CONTRIBUTING.md#localization
        https://github.com/PowerShell/xSQLServer/blob/dev/DSCResources/CommonResourceHelper.psm1

        Strings in this function has not been localized since this helper function should be removed
        when all resources has moved over to the new localization,

    .PARAMETER ErrorType
        String containing the key of the localized error message.

    .PARAMETER FormatArgs
        Collection of strings to replace format objects in the error message.

    .PARAMETER ErrorCategory
        The category to use for the error message. Default value is 'OperationStopped'.
        Valid values are a value from the enumeration System.Management.Automation.ErrorCategory.

    .PARAMETER TargetObject
        The object that was being operated on when the error occurred.

    .PARAMETER InnerException
        Exception object that was thrown when the error occurred, which will be added to the final error message.
#>
function New-TerminatingError
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorType,

        [Parameter(Mandatory = $false)]
        [String[]]
        $FormatArgs,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::OperationStopped,

        [Parameter(Mandatory = $false)]
        [Object]
        $TargetObject = $null,

        [Parameter(Mandatory = $false)]
        [System.Exception]
        $InnerException = $null
    )

    $errorMessage = $script:localizedData.$ErrorType

    if(!$errorMessage)
    {
        $errorMessage = ($script:localizedData.NoKeyFound -f $ErrorType)

        if(!$errorMessage)
        {
            $errorMessage = ("No Localization key found for key: {0}" -f $ErrorType)
        }
    }

    $errorMessage = ($errorMessage -f $FormatArgs)

    if( $InnerException )
    {
        $errorMessage += " InnerException: $($InnerException.Message)"
    }

    $callStack = Get-PSCallStack

    # Get Name of calling script
    if($callStack[1] -and $callStack[1].ScriptName)
    {
        $scriptPath = $callStack[1].ScriptName

        $callingScriptName = $scriptPath.Split('\')[-1].Split('.')[0]

        $errorId = "$callingScriptName.$ErrorType"
    }
    else
    {
        $errorId = $ErrorType
    }

    Write-Verbose -Message "$($script:localizedData.$ErrorType -f $FormatArgs) | ErrorType: $errorId"

    $exception = New-Object System.Exception $errorMessage, $InnerException
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $ErrorCategory, $TargetObject

    return $errorRecord
}

<#
    .SYNOPSIS
        Displays a localized warning message.

        This helper function is obsolete, should use Write-Warning together with individual resource
        localization strings.
        https://github.com/PowerShell/xSQLServer/blob/dev/CONTRIBUTING.md#localization

        Strings in this function has not been localized since this helper function should be removed
        when all resources has moved over to the new localization,

    .PARAMETER WarningType
        String containing the key of the localized warning message.

    .PARAMETER FormatArgs
        Collection of strings to replace format objects in warning message.
#>
function New-WarningMessage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $WarningType,

        [String[]]
        $FormatArgs
    )

    ## Attempt to get the string from the localized data
    $warningMessage = $script:localizedData.$WarningType

    ## Ensure there is a message present in the localization file
    if (!$warningMessage)
    {
        $errorParams = @{
            ErrorType = 'NoKeyFound'
            FormatArgs = $WarningType
            ErrorCategory = 'InvalidArgument'
            TargetObject = 'New-WarningMessage'
        }

        ## Raise an error indicating the localization data is not present
        throw New-TerminatingError @errorParams
    }

    ## Apply formatting
    $warningMessage = $warningMessage -f $FormatArgs

    ## Write the message as a warning
    Write-Warning -Message $warningMessage
}

<#
    .SYNOPSIS
    Displays a standardized verbose message.

    This helper function is obsolete, should use Write-Verbose together with individual resource
    localization strings.
    https://github.com/PowerShell/xSQLServer/blob/dev/CONTRIBUTING.md#localization

    Strings in this function has not been localized since this helper function should be removed
    when all resources has moved over to the new localization,

    .PARAMETER Message
    String containing the key of the localized warning message.
#>
function New-VerboseMessage
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([System.String])]
    Param
    (
        [Parameter(Mandatory=$true)]
        $Message
    )
    Write-Verbose -Message ((Get-Date -format yyyy-MM-dd_HH-mm-ss) + ": $Message") -Verbose
}

<#
    .SYNOPSIS
        This method is used to compare current and desired values for any DSC resource.

    .PARAMETER CurrentValues
        This is hash table of the current values that are applied to the resource.

    .PARAMETER DesiredValues
        This is a PSBoundParametersDictionary of the desired values for the resource.

    .PARAMETER ValuesToCheck
        This is a list of which properties in the desired values list should be checked.
        If this is empty then all values in DesiredValues are checked.
#>
function Test-SQLDscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [Object]
        $DesiredValues,

        [Parameter()]
        [Array]
        $ValuesToCheck
    )

    $returnValue = $true

    if (($DesiredValues.GetType().Name -ne 'HashTable') `
        -and ($DesiredValues.GetType().Name -ne 'CimInstance') `
        -and ($DesiredValues.GetType().Name -ne 'PSBoundParametersDictionary'))
    {
        $errorMessage = $script:localizedData.PropertyTypeInvalidForDesiredValues -f $($DesiredValues.GetType().Name)
        New-InvalidArgumentException -ArgumentName 'DesiredValues' -Message $errorMessage
    }

    if (($DesiredValues.GetType().Name -eq 'CimInstance') -and ($null -eq $ValuesToCheck))
    {
        $errorMessage = $script:localizedData.PropertyTypeInvalidForValuesToCheck
        New-InvalidArgumentException -ArgumentName 'ValuesToCheck' -Message $errorMessage
    }

    if (($null -eq $ValuesToCheck) -or ($ValuesToCheck.Count -lt 1))
    {
        $keyList = $DesiredValues.Keys
    }
    else
    {
        $keyList = $ValuesToCheck
    }

    $keyList | ForEach-Object -Process {
        if (($_ -ne 'Verbose'))
        {
            if (($CurrentValues.ContainsKey($_) -eq $false) `
            -or ($CurrentValues.$_ -ne $DesiredValues.$_) `
            -or (($DesiredValues.GetType().Name -ne 'CimInstance' -and $DesiredValues.ContainsKey($_) -eq $true) -and ($null -ne $DesiredValues.$_ -and $DesiredValues.$_.GetType().IsArray)))
            {
                if ($DesiredValues.GetType().Name -eq 'HashTable' -or `
                    $DesiredValues.GetType().Name -eq 'PSBoundParametersDictionary')
                {
                    $checkDesiredValue = $DesiredValues.ContainsKey($_)
                }
                else
                {
                    # If DesiredValue is a CimInstance.
                    $checkDesiredValue = $false
                    if (([System.Boolean]($DesiredValues.PSObject.Properties.Name -contains $_)) -eq $true)
                    {
                        if ($null -ne $DesiredValues.$_)
                        {
                            $checkDesiredValue = $true
                        }
                    }
                }

                if ($checkDesiredValue)
                {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    if ($desiredType.IsArray -eq $true)
                    {
                        if (($CurrentValues.ContainsKey($fieldName) -eq $false) `
                        -or ($null -eq $CurrentValues.$fieldName))
                        {
                            Write-Verbose -Message ($script:localizedData.PropertyValidationError -f $fieldName) -Verbose

                            $returnValue = $false
                        }
                        else
                        {
                            $arrayCompare = Compare-Object -ReferenceObject $CurrentValues.$fieldName `
                                                           -DifferenceObject $DesiredValues.$fieldName
                            if ($null -ne $arrayCompare)
                            {
                                Write-Verbose -Message ($script:localizedData.PropertiesDoesNotMatch -f $fieldName) -Verbose

                                $arrayCompare | ForEach-Object -Process {
                                    Write-Verbose -Message ($script:localizedData.PropertyThatDoesNotMatch -f $_.InputObject, $_.SideIndicator) -Verbose
                                }

                                $returnValue = $false
                            }
                        }
                    }
                    else
                    {
                        switch ($desiredType.Name)
                        {
                            'String' {
                                if (-not [System.String]::IsNullOrEmpty($CurrentValues.$fieldName) -or `
                                    -not [System.String]::IsNullOrEmpty($DesiredValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            'Int32' {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            'Int16' {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            default {
                                Write-Warning -Message ($script:localizedData.UnableToCompareProperty `
                                    -f $fieldName, $desiredType.Name)

                                $returnValue = $false
                            }
                        }
                    }
                }
            }
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Imports the module SQLPS in a standardized way.
#>
function Import-SQLPSModule
{
    [CmdletBinding()]
    param()

    $module = (Get-Module -FullyQualifiedName 'SqlServer' -ListAvailable).Name
    if ($module)
    {
        Write-Verbose -Message ($script:localizedData.PreferredModuleFound) -Verbose
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.PreferredModuleNotFound) -Verbose

        <#
            After installing SQL Server the current PowerShell session doesn't know about the new path
            that was added for the SQLPS module.
            This reloads PowerShell session environment variable PSModulePath to make sure it contains
            all paths.
        #>
        $env:PSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')

        $module = (Get-Module -FullyQualifiedName 'SQLPS' -ListAvailable).Name
    }

    if ($module)
    {
        try
        {
            Write-Debug -Message ($script:localizedData.DebugMessagePushingLocation)
            Push-Location

            Write-Verbose -Message ($script:localizedData.ImportingPowerShellModule -f $module) -Verbose

            <#
                SQLPS has unapproved verbs, disable checking to ignore Warnings.
                Suppressing verbose so all cmdlet is not listed.
            #>
            Import-Module -Name $module -DisableNameChecking -Verbose:$False -ErrorAction Stop

            Write-Debug -Message ($script:localizedData.DebugMessageImportedPowerShellModule -f $module)
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedToImportPowerShellSqlModule -f $module
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
        finally
        {
            Write-Debug -Message ($script:localizedData.DebugMessagePoppingLocation)
            Pop-Location
        }
    }
    else
    {
        $errorMessage = $script:localizedData.PowerShellSqlModuleNotFound
        New-InvalidOperationException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
    Restarts a SQL Server instance and associated services

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured

    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configured. Default is 'MSSQLSERVER'

    .PARAMETER Timeout
    Timeout value for restarting the SQL services. The default value is 120 seconds.

    .EXAMPLE
    Restart-SqlService -SQLServer localhost

    .EXAMPLE
    Restart-SqlService -SQLServer localhost -SQLInstanceName 'NamedInstance'

    .EXAMPLE
    Restart-SqlService -SQLServer CLU01 -Timeout 300
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [Int32]
        $Timeout = 120
    )

    ## Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($serverObject.IsClustered)
    {
        # Get the cluster resources
        Write-Verbose -Message ($script:localizedData.GetSqlServerClusterResources) -Verbose
        $sqlService = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Resource -Filter "Type = 'SQL Server'" |
                        Where-Object -FilterScript { $_.PrivateProperties.InstanceName -eq $serverObject.ServiceName }

        Write-Verbose -Message ($script:localizedData.GetSqlAgentClusterResource) -Verbose
        $agentService = $sqlService | Get-CimAssociatedInstance -ResultClassName MSCluster_Resource |
                            Where-Object -FilterScript { ($_.Type -eq 'SQL Server Agent') -and ($_.State -eq 2) }

        # Build a listing of resources being acted upon
        $resourceNames = @($sqlService.Name, ($agentService | Select-Object -ExpandProperty Name)) -join ","

        # Stop the SQL Server and dependent resources
        Write-Verbose -Message ($script:localizedData.BringClusterResourcesOffline -f $resourceNames) -Verbose
        $sqlService | Invoke-CimMethod -MethodName TakeOffline -Arguments @{ Timeout = $Timeout }

        # Start the SQL server resource
        Write-Verbose -Message ($script:localizedData.BringSqlServerClusterResourcesOnline) -Verbose
        $sqlService | Invoke-CimMethod -MethodName BringOnline -Arguments @{ Timeout = $Timeout }

        # Start the SQL Agent resource
        if ($agentService)
        {
            Write-Verbose -Message ($script:localizedData.BringSqlServerAgentClusterResourcesOnline) -Verbose
            $agentService | Invoke-CimMethod -MethodName BringOnline -Arguments @{ Timeout = $Timeout }
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.GetServiceInformation -f 'SQL Server') -Verbose
        $sqlService = Get-Service -DisplayName "SQL Server ($($serverObject.ServiceName))"

        <#
            Get all dependent services that are running.
            There are scenarios where an automatic service is stopped and should not be restarted automatically.
        #>
        $agentService = $sqlService.DependentServices | Where-Object -FilterScript { $_.Status -eq 'Running' }

        # Restart the SQL Server service
        Write-Verbose -Message ($script:localizedData.RestartService -f 'SQL Server') -Verbose
        $sqlService | Restart-Service -Force

        # Start dependent services
        $agentService | ForEach-Object {
            Write-Verbose -Message ($script:localizedData.StartingDependentService -f $_.DisplayName) -Verbose
            $_ | Start-Service
        }
    }
}

<#
    .SYNOPSIS
    Restarts a Reporting Services instance and associated services

    .PARAMETER SQLInstanceName
    Name of the instance to be restarted. Default is 'MSSQLSERVER'
    (the default instance).
#>
function Restart-ReportingServicesService
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $ServiceName = 'ReportServer'

    if (-not ($SQLInstanceName -eq 'MSSQLSERVER'))
    {
        $ServiceName += '${0}' -f $SQLInstanceName
    }

    Write-Verbose -Message ($script:localizedData.GetServiceInformation -f 'Reporting Services') -Verbose
    $reportingServicesService = Get-Service -Name $ServiceName

    <#
        Get all dependent services that are running.
        There are scenarios where an automatic service is stopped and should
        not be restarted automatically.
    #>
    $dependentService = $reportingServicesService.DependentServices | Where-Object -FilterScript {
        $_.Status -eq 'Running'
    }

    Write-Verbose -Message ($script:localizedData.RestartService -f 'Reporting Services') -Verbose
    $reportingServicesService | Restart-Service -Force

    # Start dependent services
    $dependentService | ForEach-Object {
        Write-Verbose -Message ($script:localizedData.StartingDependentService -f $_.DisplayName) -Verbose
        $_ | Start-Service
    }
}

<#
    .SYNOPSIS
    Executes a query on the specified database.

    .PARAMETER SQLServer
    The hostname of the server that hosts the SQL instance.

    .PARAMETER SQLInstanceName
    The name of the SQL instance that hosts the database.

    .PARAMETER Database
    Specify the name of the database to execute the query on.

    .PARAMETER Query
    The query string to execute.

    .PARAMETER WithResults
    Specifies if the query should return results.

    .EXAMPLE
    Invoke-Query -SQLServer Server1 -SQLInstanceName MSSQLSERVER -Database master -Query 'SELECT name FROM sys.databases' -WithResults

    .EXAMPLE
    Invoke-Query -SQLServer Server1 -SQLInstanceName MSSQLSERVER -Database master -Query 'RESTORE DATABASE [NorthWinds] WITH RECOVERY'
#>
function Invoke-Query
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter()]
        [Switch]
        $WithResults
    )

    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ( $WithResults )
    {
        try
        {
            $result = $serverObject.Databases[$Database].ExecuteWithResults($Query)
        }
        catch
        {
            $errorMessage = $script:localizedData.ExecuteQueryWithResultsFailed -f $Database
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }
    else
    {
        try
        {
            $serverObject.Databases[$Database].ExecuteNonQuery($Query)
        }
        catch
        {
            $errorMessage = $script:localizedData.ExecuteNonQueryFailed -f $Database
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }

    return $result
}

<#
    .SYNOPSIS
        Executes the alter method on an Availability Group Replica object.

    .PARAMETER AvailabilityGroupReplica
        The Availability Group Replica object that must be altered.
#>
function Update-AvailabilityGroupReplica
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
        $AvailabilityGroupReplica
    )

    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $AvailabilityGroupReplica.Alter()
    }
    catch
    {
        $errorMessage = $script:localizedData.AlterAvailabilityGroupReplicaFailed -f $AvailabilityGroupReplica.Name
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

function Test-LoginEffectivePermissions
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $true)]
        [string[]]
        $Permissions
    )

    # Assume the permissions are not present
    $permissionsPresent = $false

    $invokeQueryParameters = @{
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
        Database = 'master'
        WithResults = $true
    }

    $queryToGetEffectivePermissionsForLogin = "
        EXECUTE AS LOGIN = '$LoginName'
        SELECT DISTINCT permission_name
        FROM fn_my_permissions(null,'SERVER')
        REVERT
    "

    Write-Verbose -Message ($script:localizedData.GetEffectivePermissionForLogin -f $LoginName, $sqlInstanceName) -Verbose

    $loginEffectivePermissionsResult = Invoke-Query @invokeQueryParameters -Query $queryToGetEffectivePermissionsForLogin
    $loginEffectivePermissions = $loginEffectivePermissionsResult.Tables.Rows.permission_name

    if ( $null -ne $loginEffectivePermissions )
    {
        $loginMissingPermissions = Compare-Object -ReferenceObject $Permissions -DifferenceObject $loginEffectivePermissions |
            Where-Object -FilterScript { $_.SideIndicator -ne '=>' } |
            Select-Object -ExpandProperty InputObject

        if ( $loginMissingPermissions.Count -eq 0 )
        {
            $permissionsPresent = $true
        }
    }

    return $permissionsPresent
}

<#
    .SYNOPSIS
        Determine if the seeding mode of the specified availability group is automatic.

    .PARAMETER SQLServer
        The hostname of the server that hosts the SQL instance.

    .PARAMETER SQLInstanceName
        The name of the SQL instance that hosts the availability group.

    .PARAMETER AvailabilityGroupName
        The name of the availability group to check.

    .PARAMETER AvailabilityReplicaName
        The name of the availabilitiy replica to check.
#>
function Test-AvailabilityReplicaSeedingModeAutomatic
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AvailabilityGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AvailabilityReplicaName
    )

    # Assume automatic seeding is disabled by default
    $availabilityReplicaSeedingModeAutomatic = $false

    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Only check the seeding mode if this is SQL 2016 or newer
    if ( $serverObject.Version -ge 13 )
    {
        $invokeQueryParams = @{
            SQLServer = $SQLServer
            SQLInstanceName = $SQLInstanceName
            Database = 'master'
            WithResults = $true
        }

        $queryToGetSeedingMode = "
            SELECT seeding_mode_desc
            FROM sys.availability_replicas ar
            INNER JOIN sys.availability_groups ag ON ar.group_id = ag.group_id
            WHERE ag.name = '$AvailabilityGroupName'
                AND ar.replica_server_name = '$AvailabilityReplicaName'
        "
        $seedingModeResults = Invoke-Query @invokeQueryParams -Query $queryToGetSeedingMode
        $seedingMode = $seedingModeResults.Tables.Rows.seeding_mode_desc

        if ( $seedingMode -eq 'Automatic' )
        {
            $availabilityReplicaSeedingModeAutomatic = $true
        }
    }

    return $availabilityReplicaSeedingModeAutomatic
}

<#
    .SYNOPSIS
        Get the server object of the primary replica of the specified availability group.

    .PARAMETER ServerObject
        The current server object connection.

    .PARAMETER AvailabilityGroup
        The availability group object used to find the primary replica server name.
#>
function Get-PrimaryReplicaServerObject
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
        $AvailabilityGroup
    )

    $primaryReplicaServerObject = $serverObject

    # Determine if we're connected to the primary replica
    if ( ( $AvailabilityGroup.PrimaryReplicaServerName -ne $serverObject.DomainInstanceName ) -and ( -not [System.String]::IsNullOrEmpty($AvailabilityGroup.PrimaryReplicaServerName) ) )
    {
        $primaryReplicaServerObject = Connect-SQL -SQLServer $AvailabilityGroup.PrimaryReplicaServerName
    }

    return $primaryReplicaServerObject
}

<#
    .SYNOPSIS
        Determine if the current login has impersonate permissions

    .PARAMETER ServerObject
        The server object on which to perform the test.
#>
function Test-ImpersonatePermissions
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )

    $testLoginEffectivePermissionsParams = @{
        SQLServer = $ServerObject.ComputerNamePhysicalNetBIOS
        SQLInstanceName = $ServerObject.ServiceName
        LoginName = $ServerObject.ConnectionContext.TrueLogin
        Permissions = @('IMPERSONATE ANY LOGIN')
    }

    $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

    if ( -not $impersonatePermissionsPresent )
    {
        New-VerboseMessage -Message ( 'The login "{0}" does not have impersonate permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName )
    }

    return $impersonatePermissionsPresent
}

<#
    .SYNOPSIS
        Takes a SQL Instance name in the format of 'Server\Instance' and splits it into a hash table prepared to be passed into Connect-SQL.

    .PARAMETER FullSQLInstanceName
        The full SQL instance name string to be split.

    .OUTPUTS
        Hashtable with the properties SQLServer and SQLInstanceName.
#>
function Split-FullSQLInstanceName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $FullSQLInstanceName
    )

    $sqlServer,$sqlInstanceName = $FullSQLInstanceName.Split('\')

    if ( [System.String]::IsNullOrEmpty($sqlInstanceName) )
    {
        $sqlInstanceName = 'MSSQLSERVER'
    }

    return @{
        SQLServer = $sqlServer
        SQLInstanceName = $sqlInstanceName
    }
}

<#
    .SYNOPSIS
        Determine if the cluster has the required permissions to the supplied server.

    .PARAMETER ServerObject
        The server object on which to perform the test.
#>
function Test-ClusterPermissions
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )

    $clusterServiceName = 'NT SERVICE\ClusSvc'
    $ntAuthoritySystemName = 'NT AUTHORITY\SYSTEM'
    $availabilityGroupManagementPerms = @('Connect SQL', 'Alter Any Availability Group', 'View Server State')
    $clusterPermissionsPresent = $false

    # Retrieve the SQL Server and Instance name from the server object
    $sqlServer = $ServerObject.NetName
    $sqlInstanceName = $ServerObject.ServiceName

    foreach ( $loginName in @( $clusterServiceName, $ntAuthoritySystemName ) )
    {
        if ( $ServerObject.Logins[$loginName] -and -not $clusterPermissionsPresent )
        {
            $testLoginEffectivePermissionsParams = @{
                SQLServer       = $sqlServer
                SQLInstanceName = $sqlInstanceName
                LoginName       = $loginName
                Permissions     = $availabilityGroupManagementPerms
            }

            $clusterPermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

            if ( -not $clusterPermissionsPresent )
            {
                switch ( $loginName )
                {
                    $clusterServiceName
                    {
                        Write-Verbose -Message ( $script:localizedData.ClusterLoginMissingRecommendedPermissions -f $loginName,( $availabilityGroupManagementPerms -join ', ' ) ) -Verbose
                    }

                    $ntAuthoritySystemName
                    {
                        Write-Verbose -Message ( $script:localizedData.ClusterLoginMissingPermissions -f $loginName,( $availabilityGroupManagementPerms -join ', ' ) ) -Verbose
                    }
                }
            }
            else
            {
                Write-Verbose -Message ( $script:localizedData.ClusterLoginPermissionsPresent -f $loginName ) -Verbose
            }
        }
        elseif ( -not $clusterPermissionsPresent )
        {
            switch ( $loginName )
            {
                $clusterServiceName
                {
                    Write-Verbose -Message ($script:localizedData.ClusterLoginMissingRecommendedPermissions -f $loginName,"Trying with '$ntAuthoritySystemName'.") -Verbose
                }

                $ntAuthoritySystemName
                {
                    Write-Verbose -Message ( $script:localizedData.ClusterLoginMissing -f $loginName,'' ) -Verbose
                }
            }
        }
    }

    # If neither 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' have the required permissions, throw an error.
    if ( -not $clusterPermissionsPresent )
    {
        throw ($script:localizedData.ClusterPermissionsMissing -f $sqlServer,$sqlInstanceName )
    }

    return $clusterPermissionsPresent
}

<#
    .SYNOPSIS
        Determine if the current node is hosting the instance.

    .PARAMETER ServerObject
        The server object on which to perform the test.
#>
function Test-ActiveNode
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )

    $result = $false

    # Determine if this is a failover cluster instance (FCI)
    if ( $serverObject.IsMemberOfWsfcCluster )
    {
        # If the current node name is the same as the name the instances is
        # running on, then this is the active node
        $result = $serverObject.ComputerNamePhysicalNetBIOS -eq $env:COMPUTERNAME
    }
    else
    {
        # This is a standalone instance, therefore the node will always host
        # the instance.
        $result = $true
    }

    return $result
}
