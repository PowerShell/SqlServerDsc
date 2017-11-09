# Load Common Code
Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
    Gets the current value of a SQL configuration option

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured

    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER OptionName
    The name of the SQL configuration option to be checked

    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    *** Not used in this function ***
    Determines whether the instance should be restarted after updating the configuration option.

    .PARAMETER RestartTimeout
    *** Not used in this function ***
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [Int32]
        $OptionValue,

        [Parameter()]
        [Boolean]
        $RestartService = $false,

        [Parameter()]
        [Int32]
        $RestartTimeout = 120
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    ## get the configuration option
    $option = $sql.Configuration.Properties | Where-Object { $_.DisplayName -eq $OptionName }

    if (!$option)
    {
        throw New-TerminatingError -ErrorType "ConfigurationOptionNotFound" -FormatArgs $OptionName -ErrorCategory InvalidArgument
    }

    return @{
        SqlServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
        OptionName      = $option.DisplayName
        OptionValue     = $option.ConfigValue
        RestartService  = $RestartService
        RestartTimeout  = $RestartTimeout
    }
}

<#
    .SYNOPSIS
    Sets the value of a SQL configuration option

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured

    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER OptionName
    The name of the SQL configuration option to be set

    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    Determines whether the instance should be restarted after updating the configuration option

    .PARAMETER RestartTimeout
    The length of time, in seconds, to wait for the service to restart. Default is 120 seconds.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [Int32]
        $OptionValue,

        [Parameter()]
        [Boolean]
        $RestartService = $false,

        [Parameter()]
        [Int32]
        $RestartTimeout = 120
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    ## get the configuration option
    $option = $sql.Configuration.Properties | Where-Object { $_.DisplayName -eq $OptionName }

    if (!$option)
    {
        throw New-TerminatingError -ErrorType "ConfigurationOptionNotFound" -FormatArgs $OptionName -ErrorCategory InvalidArgument
    }

    $option.ConfigValue = $OptionValue
    $sql.Configuration.Alter()

    if ($option.IsDynamic -eq $true)
    {
        New-VerboseMessage -Message 'Configuration option has been updated.'
    }
    elseif (($option.IsDynamic -eq $false) -and ($RestartService -eq $true))
    {
        New-VerboseMessage -Message 'Configuration option has been updated, restarting instance...'
        Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -Timeout $RestartTimeout
    }
    else
    {
        New-WarningMessage -WarningType 'ConfigurationRestartRequired' -FormatArgs $OptionName
    }
}

<#
    .SYNOPSIS
    Determines whether a SQL configuration option value is properly set

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured

    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER OptionName
    The name of the SQL configuration option to be tested

    .PARAMETER OptionValue
    The desired value of the SQL configuration option

    .PARAMETER RestartService
    *** Not used in this function ***
    Determines whether the instance should be restarted after updating the configuration option

    .PARAMETER RestartTimeout
    *** Not used in this function ***
    The length of time, in seconds, to wait for the service to restart.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [String]
        $OptionName,

        [Parameter(Mandatory = $true)]
        [Int32]
        $OptionValue,

        [Parameter()]
        [Boolean]
        $RestartService = $false,

        [Parameter()]
        [Int32]
        $RestartTimeout = 120
    )

    ## Get the current state of the configuration item
    $state = Get-TargetResource @PSBoundParameters

    ## return whether the value matches the desired state
    return ($state.OptionValue -eq $OptionValue)
}

Export-ModuleMember -Function *-TargetResource
