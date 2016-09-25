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
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

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
        $getSqlDatabasePermission = Get-SqlDatabasePermission -SQL $sql -Name $Name -Database $Database
    }
    else
    {
        $null = $Permissions
    }
    
    $returnValue = @{
        Database = $Database
        Name = $Name
        Permissions = $Permissions
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
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

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
        Set-SqlDatabasePermission -SQL $sql -Name $Name -Database $Database -Permissions $Permissions
    }

    if (!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    $SQLDatabasePermissions = (Get-TargetResource @PSBoundParameters).Permissions

    $result = $true
    foreach ($Permission in $Permissions)
    {
        if ($SQLDatabasePermissions -notcontains $Permission)
        {
            Write-Verbose "Failed test for permission $Permission"
            $result = $false
        }
    }
    
    $result
}


Export-ModuleMember -Function *-TargetResource
