Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1') -Force

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the RecoveryModel should be configured.

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [ValidateSet('Full','Simple','BulkLogged')]
        [System.String]
        $RecoveryModel = 'Full',

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    
    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        Write-Verbose -Message "Getting RecoveryModel of SQL database '$Name'"
        $sqlDatabase = $sql.Databases
        
        if ($sqlDatabase)
        {
            if ($sqlDatabase[$Name])
            {
                $getSqlDatabasePermission = $sqlDatabase[$Name].RecoveryModel
                New-VerboseMessage -Message "RecoveryModel of SQL Database name $Name is $getSqlDatabasePermission"
                if ($getSqlDatabasePermission -eq $RecoveryModel)
                {
                    $Ensure = 'Present'
                }
                else
                {
                    $Ensure = 'Absent'
                }
            }
            else
            {
                New-VerboseMessage -Message "SQL Database name $Name does not exist"
                $getSqlDatabasePermission = $RecoveryModel
                $Ensure = 'Absent'
            }
        }
        else
        {
            New-WarningMessage -Message 'Failed getting SQL databases'
            $getSqlDatabasePermission = $RecoveryModel
            $Ensure = 'Absent'
        }
    }
    
    $returnValue = @{
        Ensure          = $Ensure
        Name            = $Name
        RecoveryModel   = $getSqlDatabasePermission
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the RecoveryModel should be configured.

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [ValidateSet('Full','Simple','BulkLogged')]
        [System.String]
        $RecoveryModel = 'Full',

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
 
     $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sql)
    {
        $sqlDatabase = $Sql.Databases[$Name]
        if ($sqlDatabase)
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message "Setting database '$Name' with RecoveryModel '$RecoveryModel'"
                if($sqlDatabase.RecoveryModel -ne $RecoveryModel)
                {
                    $sqlDatabase.RecoveryModel = $RecoveryModel
                    $sqlDatabase.Alter()
                    New-VerboseMessage -Message "Database $Name recovery model is changed to $RecoveryModel."
                } 
            }
        }
        else
        {
            New-VerboseMessage -Message "SQL Database name $Name does not exist"
        }
    }
}

<#
    .SYNOPSIS
    This function gets all Key properties defined in the resource schema file

    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the RecoveryModel should be configured.

    .PARAMETER Database
    This is the SQL database

    .PARAMETER RecoveryModel
    This is the RecoveryModel of the SQL database

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [ValidateSet('Full','Simple','BulkLogged')]
        [System.String]
        $RecoveryModel = 'Full',

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message "Testing RecoveryModel of database '$Name'"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SQLDscParameterState -CurrentValues $CurrentValues `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @('Ensure','Name','RecoveryModel')
}

Export-ModuleMember -Function *-TargetResource
