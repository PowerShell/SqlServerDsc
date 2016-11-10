$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

Import-Module -Name $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRole,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        Write-Verbose "Getting SQL Server roles for $Name on SQL Server $SQLServer."
        $confirmSqlServerRole = Confirm-SqlServerRoleMember -SQL $sql -LoginName $Name -ServerRole $ServerRole
        if ($confirmSqlServerRole)
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

    $returnValue = @{
        Ensure          = $Ensure
        Name            = $Name
        ServerRole      = $ServerRole
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }
    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRole,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        if ($Ensure -eq 'Present')
        {
            Add-SqlServerRoleMember -SQL $sql -LoginName $Name -ServerRole $ServerRole
            New-VerboseMessage -Message "SQL Roles for $Name, successfullly added"
        }
        else
        {
            Remove-SqlServerRoleMember -SQL $sql -LoginName $Name -ServerRole $ServerRole
            New-VerboseMessage -Message "SQL Roles for $Name, successfullly removed"
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRole,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    Write-Verbose -Message "Testing SQL roles for login $Name"
     
    $currentValues = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.Ensure = $Ensure
    return Test-SQLDscParameterState -CurrentValues $CurrentValues `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @('Name', 
                                                      'ServerRole',
                                                      'Ensure')
}

Export-ModuleMember -Function *-TargetResource

