$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

Import-Module -Name $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

<#
.SYNOPSIS

This function gets all Key properties defined in the resource schema file

.PARAMETER Ensure

This is The Ensure Set to 'present' to specificy that the permission should be configured.

.PARAMETER Database

This is the SQL database

.PARAMETER Name

This is the name of the SQL login for the permission set

.PARAMETER PermissionState

This is the state of permission set. Valid values are 'Grant' or 'Deny'

.PARAMETER Permissions

This is a list boolean that set of permissions for the SQL database

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
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        $getSqlDatabasePermission = Get-SqlDatabasePermission -SQL $sql `
                                                              -Name $Name `
                                                              -Database $Database `
                                                              -PermissionState $PermissionState
        
        if ($getSqlDatabasePermission)
        {
            $comparePermissions = Compare-Object -ReferenceObject $Permissions `
                                                 -DifferenceObject $getSqlDatabasePermission
            if ($null -eq $comparePermissions)
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
            $Ensure = 'Absent'
        }
    }
    else
    {
        $null = $getSqlDatabasePermission
        $Ensure = 'Absent'
    }
    
    $returnValue = @{
        Ensure          = $Ensure
        Database        = $Database
        Name            = $Name
        PermissionState = $PermissionState
        Permissions     = $getSqlDatabasePermission
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}

<#
.SYNOPSIS

This function sets all Key properties defined in the resource schema file

.PARAMETER Ensure

This is The Ensure Set to 'present' to specificy that the permission should be configured.

.PARAMETER Database

This is the SQL database

.PARAMETER Name

This is the name of the SQL login for the permission set

.PARAMETER PermissionState

This is the state of permission set. Valid values are 'Grant' or 'Deny'

.PARAMETER Permissions

This is a list boolean that set of permissions for the SQL database

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
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sql)
    {
        if ($Ensure -eq 'Present')
        {
            Add-SqlDatabasePermission -SQL $sql `
                                      -Name $Name `
                                      -Database $Database `
                                      -PermissionState $PermissionState `
                                      -Permissions $Permissions
            New-VerboseMessage -Message "$PermissionState - SQL Permissions for $Name, successfullly added in $Database"
        }
        else
        {
            Remove-SqlDatabasePermission -SQL $sql `
                                         -Name $Name `
                                         -Database $Database `
                                         -PermissionState $PermissionState `
                                         -Permissions $Permissions
            New-VerboseMessage -Message "$PermissionState - SQL Permissions for $Name, successfullly removed in $Database"
        }
    }
}

<#
.SYNOPSIS

This function tests all Key properties defined in the resource schema file

.PARAMETER Ensure

This is The Ensure Set to 'present' to specificy that the permission should be configured.

.PARAMETER Database

This is the SQL database

.PARAMETER Name

This is the name of the SQL login for the permission set

.PARAMETER PermissionState

This is the state of permission set. Valid values are 'Grant' or 'Deny'

.PARAMETER Permissions

This is a list boolean that set of permissions for the SQL database

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
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    Write-Verbose -Message "Testing permissions of database '$Database' for login '$Name'"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SQLDscParameterState -CurrentValues $CurrentValues `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @('Name', 'Ensure', 'PermissionState', 'Permissions')
}

Export-ModuleMember -Function *-TargetResource
