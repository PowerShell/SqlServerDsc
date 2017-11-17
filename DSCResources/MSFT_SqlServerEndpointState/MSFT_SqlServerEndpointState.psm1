Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
        Returns the current state of an endpoint.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured.

    .PARAMETER Name
        The name of the endpoint.
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

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    New-VerboseMessage -Message "Getting state of endpoint $Name"

    try
    {
        $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

        $endpointObject = $sqlServerObject.Endpoints[$Name]
        if ($null -ne $endpointObject)
        {
            $currentState = $endpointObject.EndpointState
        }
        else
        {
            throw New-TerminatingError -ErrorType EndpointNotFound -FormatArgs @($Name) -ErrorCategory ObjectNotFound
        }
    }
    catch
    {
        throw New-TerminatingError -ErrorType EndpointErrorVerifyExist -FormatArgs @($Name) -ErrorCategory ObjectNotFound -InnerException $_.Exception
    }

    return @{
        InstanceName = [System.String] $InstanceName
        ServerName   = [System.String] $ServerName
        Name         = [System.String] $Name
        State        = [System.String] $currentState
    }
}

<#
    .SYNOPSIS
        Changes the state of an endpoint.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured.

    .PARAMETER Name
        The name of the endpoint.

    .PARAMETER State
        The state of the endpoint. Valid states are Started, Stopped or Disabled. Default value is 'Started'.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Started', 'Stopped', 'Disabled')]
        [System.String]
        $State = 'Started'
    )

    $parameters = @{
        InstanceName = [System.String] $InstanceName
        ServerName   = [System.String] $ServerName
        Name         = [System.String] $Name
    }

    $getTargetResourceResult = Get-TargetResource @parameters
    if ($null -ne $getTargetResourceResult)
    {
        if ($getTargetResourceResult.State -ne $State)
        {
            New-VerboseMessage -Message ('Changing state of endpoint ''{0}''' -f $Name)

            $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

            $endpointObject = $sqlServerObject.Endpoints[$Name]

            $setEndpointParams = @{
                InputObject = $endpointObject
                State       = $State
            }

            Set-SqlHADREndpoint @setEndpointParams -ErrorAction Stop | Out-Null
        }
        else
        {
            New-VerboseMessage -Message ('Endpoint ''{0}'' state is already correct.' -f $Name)
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
        Tests the state of an endpoint if it is in desired state.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured.

    .PARAMETER Name
        The name of the endpoint.

    .PARAMETER State
        The state of the endpoint. Valid states are Started, Stopped or Disabled. Default value is 'Started'.
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

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Started', 'Stopped', 'Disabled')]
        [System.String]
        $State = 'Started'
    )

    $parameters = @{
        InstanceName = $InstanceName
        ServerName   = $ServerName
        Name         = $Name
    }

    New-VerboseMessage -Message "Testing state $State on endpoint '$Name'"

    $getTargetResourceResult = Get-TargetResource @parameters
    if ($null -ne $getTargetResourceResult)
    {
        $result = $false

        if ($getTargetResourceResult.State -eq $State)
        {
            $result = $true
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -ErrorCategory InvalidResult
    }

    return $result
}

Export-ModuleMember -Function *-TargetResource
