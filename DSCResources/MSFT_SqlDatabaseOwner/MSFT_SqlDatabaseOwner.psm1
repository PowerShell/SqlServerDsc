Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDSCHelper.psm1') `
    -Force
<#
    .SYNOPSIS
    This function gets the owner of the desired sql database.

    .PARAMETER Database
    The name of database to be configured.

    .PARAMETER Name
    The name of the login that will become a owner of the desired sql database.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    Write-Verbose -Message "Getting owner of database $Database"
    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        # Check database exists
        if ( -not ($sqlDatabaseObject = $sqlServerObject.Databases[$Database]) )
        {
            throw New-TerminatingError -ErrorType NoDatabase `
                -FormatArgs @($Database, $SQLServer, $SQLInstanceName) `
                -ErrorCategory ObjectNotFound
        }

        try
        {
            $sqlDatabaseOwner = $sqlDatabaseObject.Owner
            New-VerboseMessage -Message "Owner for SQL Database name $Database is $sqlDatabaseOwner"
        }
        catch
        {
            throw New-TerminatingError -ErrorType FailedToGetOwnerDatabase `
                -FormatArgs @($Database, $SQLServer, $SQLInstanceName) `
                -ErrorCategory InvalidOperation
        }
    }

    $returnValue = @{
        Database        = $Database
        Name            = $sqlDatabaseOwner
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function sets the owner of the desired sql database.

    .PARAMETER Database
    The name of database to be configured.

    .PARAMETER Name
    The name of the login that will become a owner of the desired sql database.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    Write-Verbose -Message "Setting owner $Name of database $Database"
    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        # Check database exists
        if ( -not ($sqlDatabaseObject = $sqlServerObject.Databases[$Database]) )
        {
            throw New-TerminatingError -ErrorType NoDatabase -FormatArgs @($Database, $SQLServer, $SQLInstanceName) -ErrorCategory ObjectNotFound
        }

        # Check login exists
        if ( -not ($sqlServerObject.Logins[$Name]) )
        {
            throw New-TerminatingError -ErrorType LoginNotFound -FormatArgs @($Name, $SQLServer, $SQLInstanceName) -ErrorCategory ObjectNotFound
        }

        try
        {
            $sqlDatabaseObject.SetOwner($Name)
            New-VerboseMessage -Message "Owner of SQL Database name $Database is now $Name"
        }
        catch
        {
            throw New-TerminatingError -ErrorType FailedToSetOwnerDatabase `
                -FormatArgs @($Name, $Database, $SQLServer, $SQLInstanceName) `
                -ErrorCategory InvalidOperation `
                -InnerException $_.Exception
        }
    }
}

<#
    .SYNOPSIS
    This function tests the owner of the desired sql database.

    .PARAMETER Database
    The name of database to be configured.

    .PARAMETER Name
    The name of the login that will become a owner of the desired sql database.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    Write-Verbose -Message "Testing owner $Name of database $Database"

    $currentValues = Get-TargetResource @PSBoundParameters
    return Test-SQLDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('Name', 'Database')
}

Export-ModuleMember -Function *-TargetResource
