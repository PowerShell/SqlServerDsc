$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL database permissions

# NOTE: This resource requires WMF5 and PsDscRunAsCredential

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
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
            $comparePermissions = Compare-Object -ReferenceObject $Permissions `                                                 -DifferenceObject $getSqlDatabasePermission
            if ($null -eq $comparePermissions)
            {
                $Ensure = "Present"
            }
            else
            {
                $Ensure = "Absent"
            }
        }
        else 
        {
            $Ensure = "Absent"
        }
    }
    else
    {
        $null = $getSqlDatabasePermission
        $Ensure = "Absent"
    }
    
    $returnValue = @{
        Ensure = $Ensure
        Database = $Database
        Name = $Name
        PermissionState = $PermissionState
        Permissions = $getSqlDatabasePermission
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sql)
    {
        if ($Ensure -eq "Present")
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


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    Write-Verbose -Message "Testing service application '$Name'"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SQLDscParameterState -CurrentValues $CurrentValues `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @("Name", "Ensure", "PermissionState", "Permissions")
}

Export-ModuleMember -Function *-TargetResource
