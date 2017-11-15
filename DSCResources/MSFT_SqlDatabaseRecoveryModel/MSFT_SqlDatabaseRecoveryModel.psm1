Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER ServerName
    This is a the SQL Server for the database

    .PARAMETER InstanceName
    This is a the SQL instance for the database
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Full', 'Simple', 'BulkLogged')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RecoveryModel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Getting RecoveryModel of SQL database '$Name'"
        $sqlDatabaseObject = $sqlServerObject.Databases[$Name]

        if ($sqlDatabaseObject)
        {
            $sqlDatabaseRecoveryModel = $sqlDatabaseObject.RecoveryModel
            New-VerboseMessage -Message "The current recovery model used by database $Name is '$sqlDatabaseRecoveryModel'"
        }
        else
        {
            throw New-TerminatingError -ErrorType NoDatabase `
                -FormatArgs @($Name, $ServerName, $InstanceName) `
                -ErrorCategory InvalidResult
        }
    }

    $returnValue = @{
        Name          = $Name
        RecoveryModel = $sqlDatabaseRecoveryModel
        ServerName    = $ServerName
        InstanceName  = $InstanceName
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER ServerName
    This is a the SQL Server for the database

    .PARAMETER InstanceName
    This is a the SQL instance for the database
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Full', 'Simple', 'BulkLogged')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RecoveryModel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Setting RecoveryModel of SQL database '$Name'"
        $sqlDatabaseObject = $sqlServerObject.Databases[$Name]

        if ($sqlDatabaseObject)
        {
            if ($sqlDatabaseObject.RecoveryModel -ne $RecoveryModel)
            {
                $sqlDatabaseObject.RecoveryModel = $RecoveryModel
                $sqlDatabaseObject.Alter()
                New-VerboseMessage -Message "The recovery model for the database $Name is changed to '$RecoveryModel'."
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType NoDatabase `
                -FormatArgs @($Name, $ServerName, $InstanceName) `
                -ErrorCategory InvalidResult
        }
    }
}

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER ServerName
    This is a the SQL Server for the database

    .PARAMETER InstanceName
    This is a the SQL instance for the database
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Full', 'Simple', 'BulkLogged')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RecoveryModel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    Write-Verbose -Message "Testing RecoveryModel of database '$Name'"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SQLDscParameterState -CurrentValues $currentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('Name', 'RecoveryModel')
}

Export-ModuleMember -Function *-TargetResource
