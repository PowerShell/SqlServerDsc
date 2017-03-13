Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1') -Force

<#
    .SYNOPSIS
    Returns the current permissions for the user in the database

    .PARAMETER Ensure
    This is The Ensure if the permission should be granted (Present) or revoked (Absent)
    Not used in Get-TargetResource

    .PARAMETER Database
    This is the SQL database

    .PARAMETER Name
    This is the name of the SQL login for the permission set

    .PARAMETER PermissionState
    This is the state of permission set. Valid values are 'Grant' or 'Deny'

    .PARAMETER Permissions
    This is a list that represents a SQL Server set of database permissions

    .PARAMETER SQLServer
    This is the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is the SQL instance for the database
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

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Getting permissions for user '$Name' in database '$Database'"
        $getSqlDatabasePermissionResult = Get-SqlDatabasePermission -SqlServerObject $sqlServerObject `
                                                                    -Name $Name `
                                                                    -Database $Database `
                                                                    -PermissionState $PermissionState
        
        if ($getSqlDatabasePermissionResult)
        {
            $resultOfPermissionCompare = Compare-Object -ReferenceObject $Permissions `
                                                        -DifferenceObject $getSqlDatabasePermissionResult
            if ($null -eq $resultOfPermissionCompare)
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
        throw New-TerminatingError -ErrorType ConnectSQLError `
                                   -FormatArgs @($SQLServer,$SQLInstanceName) `
                                   -ErrorCategory InvalidOperation
    }
    
    $returnValue = @{
        Ensure          = $Ensure
        Database        = $Database
        Name            = $Name
        PermissionState = $PermissionState
        Permissions     = $getSqlDatabasePermissionResult
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}

<#
    .SYNOPSIS
    Sets the permissions for the user in the database.

    .PARAMETER Ensure
    This is The Ensure if the permission should be granted (Present) or revoked (Absent)

    .PARAMETER Database
    This is the SQL database

    .PARAMETER Name
    This is the name of the SQL login for the permission set

    .PARAMETER PermissionState
    This is the state of permission set. Valid values are 'Grant' or 'Deny'

    .PARAMETER Permissions
    This is a list that represents a SQL Server set of database permissions

    .PARAMETER SQLServer
    This is the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is the SQL instance for the database
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

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sqlServerObject)
    {
        Write-Verbose -Message "Setting permissions of database '$Database' for login '$Name'"

        if ($Ensure -eq 'Present')
        {
            Add-SqlDatabasePermission -SqlServerObject $sqlServerObject `
                                      -Name $Name `
                                      -Database $Database `
                                      -PermissionState $PermissionState `
                                      -Permissions $Permissions
            
            New-VerboseMessage -Message "$PermissionState - SQL Permissions for $Name, successfullly added in $Database"
        }
        else
        {
            Remove-SqlDatabasePermission -SqlServerObject $sqlServerObject `
                                         -Name $Name `
                                         -Database $Database `
                                         -PermissionState $PermissionState `
                                         -Permissions $Permissions
            
            New-VerboseMessage -Message "$PermissionState - SQL Permissions for $Name, successfullly removed in $Database"
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType ConnectSQLError `
                                   -FormatArgs @($SQLServer,$SQLInstanceName) `
                                   -ErrorCategory InvalidOperation
    }
}

<#
    .SYNOPSIS
    Tests if the permissions is set for the user in the database

    .PARAMETER Ensure
    This is The Ensure if the permission should be granted (Present) or revoked (Absent)

    .PARAMETER Database
    This is the SQL database

    .PARAMETER Name
    This is the name of the SQL login for the permission set

    .PARAMETER PermissionState
    This is the state of permission set. Valid values are 'Grant' or 'Deny'

    .PARAMETER Permissions
    This is a list that represents a SQL Server set of database permissions

    .PARAMETER SQLServer
    This is the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is the SQL instance for the database
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

    Write-Verbose -Message "Evaluating permissions for user '$Name' in database '$Database'."

    $getTargetResourceResult = Get-TargetResource @PSBoundParameters

    return Test-SQLDscParameterState -CurrentValues $getTargetResourceResult `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @('Name', 'Ensure', 'PermissionState', 'Permissions')
}

<#
    .SYNOPSIS
    This cmdlet is used to return the permission for a user in a database

    .PARAMETER SqlServerObject
    This is the Server object returned by Connect-SQL

    .PARAMETER Name
    This is the name of the user to get the current permissions for

    .PARAMETER Database
    This is the name of the SQL database

    .PARAMETER PermissionState
    If the permission should be granted or denied. Valid values are Grant or Deny
#>
function Get-SqlDatabasePermission
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PermissionState
    )

    Write-Verbose -Message 'Evaluating database and login.'
    $sqlDatabase = $SqlServerObject.Databases[$Database]
    $sqlLogin = $SqlServerObject.Logins[$Name]
    $sqlInstanceName = $SqlServerObject.InstanceName
    $sqlServer = $SqlServerObject.ComputerNamePhysicalNetBIOS

    # Initialize variable permission
    [System.String[]] $permission = @()

    if ($sqlDatabase)
    {
        if ($sqlLogin)
        {
            Write-Verbose -Message "Getting permissions for user '$Name' in database '$Database'."

            $databasePermissionInfo = $sqlDatabase.EnumDatabasePermissions($Name)
            $databasePermissionInfo = $databasePermissionInfo | Where-Object -FilterScript {
                $_.PermissionState -eq $PermissionState
            }

            foreach ($currentDatabasePermissionInfo in $databasePermissionInfo)
            {
                $permissionProperty = ($currentDatabasePermissionInfo.PermissionType | Get-Member -MemberType Property).Name
                foreach ($currentPermissionProperty in $permissionProperty)
                {
                    if ($currentDatabasePermissionInfo.PermissionType."$currentPermissionProperty")
                    {
                        $permission += $currentPermissionProperty
                    }
                }
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType LoginNotFound `
                                       -FormatArgs @($Name,$sqlServer,$sqlInstanceName) `
                                       -ErrorCategory ObjectNotFound
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NoDatabase `
                                   -FormatArgs @($Database,$sqlServer,$sqlInstanceName) `
                                   -ErrorCategory InvalidResult
    }

    $permission
}

<#
    .SYNOPSIS
    This cmdlet is used to grant or deny permissions for a user in a database

    .PARAMETER SqlServerObject
    This is the Server object returned by Connect-SQL

    .PARAMETER Name
    This is the name of the user to get the current permissions for

    .PARAMETER Database
    This is the name of the SQL database

    .PARAMETER PermissionState
    If the permission should be granted or denied. Valid values are Grant or Deny

    .PARAMETER Permissions
    The permissions to be granted or denied for the user in the database.
    Valid permissions can be found in the article SQL Server Permissions:
    https://msdn.microsoft.com/en-us/library/ms191291.aspx#SQL Server Permissions
#>
function Add-SqlDatabasePermission
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Permissions
    )

    Write-Verbose -Message 'Evaluating database and login.'
    $sqlDatabase = $SqlServerObject.Databases[$Database]
    $sqlLogin = $SqlServerObject.Logins[$Name]
    $sqlInstanceName = $SqlServerObject.InstanceName
    $sqlServer = $SqlServerObject.ComputerNamePhysicalNetBIOS

    if ($sqlDatabase)
    {
        if ($sqlLogin)
        {
            if (!$sqlDatabase.Users[$Name])
            {
                try
                {
                    Write-Verbose -Message ("Adding SQL login $Name as a user of database " + `
                                            "$Database on $sqlServer\$sqlInstanceName")
                    $sqlDatabaseUser = New-Object Microsoft.SqlServer.Management.Smo.User $sqlDatabase,$Name
                    $sqlDatabaseUser.Login = $Name
                    $sqlDatabaseUser.Create()
                }
                catch
                {
                    Write-Verbose -Message ("Failed adding SQL login $Name as a user of " + `
                                            "database $Database on $sqlServer\$sqlInstanceName")
                }
            }

            if ($sqlDatabase.Users[$Name])
            {
                try
                {
                    Write-Verbose -Message ("$PermissionState the permissions '$Permissions' to the " + `
                                            "database '$Database' on the server $sqlServer$sqlInstanceName")
                    $permissionSet = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabasePermissionSet

                    foreach ($permission in $permissions)
                    {
                        $permissionSet."$permission" = $true
                    }

                    switch ($PermissionState)
                    {
                        'Grant'
                        {
                            $sqlDatabase.Grant($permissionSet,$Name)
                        }

                        'Deny'
                        {
                            $sqlDatabase.Deny($permissionSet,$Name)
                        }
                    }
                }
                catch
                {
                    Write-Verbose -Message ("Failed setting SQL login $Name to permissions $permissions " + `
                                            "on database $Database on $sqlServer\$sqlInstanceName")
                }
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType LoginNotFound `
                                       -FormatArgs @($Name,$sqlServer,$sqlInstanceName) `
                                       -ErrorCategory ObjectNotFound
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NoDatabase `
                                   -FormatArgs @($Database,$sqlServer,$sqlInstanceName) `
                                   -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    This cmdlet is used to remove (revoke) permissions for a user in a database

    .PARAMETER SqlServerObject
    This is the Server object returned by Connect-SQL.

    .PARAMETER Name
    This is the name of the user for which permissions will be removed (revoked)

    .PARAMETER Database
    This is the name of the SQL database

    .PARAMETER PermissionState
    f the permission that should be removed was granted or denied. Valid values are Grant or Deny

    .PARAMETER Permissions
    The permissions to be remove (revoked) for the user in the database.
    Valid permissions can be found in the article SQL Server Permissions:
    https://msdn.microsoft.com/en-us/library/ms191291.aspx#SQL Server Permissions.
#>
function Remove-SqlDatabasePermission
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant','Deny')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Permissions
    )

    Write-Verbose -Message 'Evaluating database and login'
    $sqlDatabase = $SqlServerObject.Databases[$Database]
    $sqlLogin = $SqlServerObject.Logins[$Name]
    $sqlInstanceName = $SqlServerObject.InstanceName
    $sqlServer = $SqlServerObject.ComputerNamePhysicalNetBIOS

    if ($sqlDatabase)
    {
        if ($sqlLogin)
        {
            if (!$sqlDatabase.Users[$Name])
            {
                try
                {
                    Write-Verbose -Message ("Adding SQL login $Name as a user of database " + `
                                            "$Database on $sqlServer\$sqlInstanceName")
                    $sqlDatabaseUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User `
                                                  -ArgumentList $sqlDatabase,$Name
                    $sqlDatabaseUser.Login = $Name
                    $sqlDatabaseUser.Create()
                }
                catch
                {
                    Write-Verbose -Message ("Failed adding SQL login $Name as a user of " + `
                                            "database $Database on $sqlServer\$sqlInstanceName")
                }
            }

            if ($sqlDatabase.Users[$Name])
            {
                try
                {
                    Write-Verbose -Message ("Revoking $PermissionState permissions '$Permissions' to the " + `
                                            "database '$Database' on the server $sqlServer$sqlInstanceName")
                    $permissionSet = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabasePermissionSet

                    foreach ($permission in $permissions)
                    {
                        $permissionSet."$permission" = $false
                    }

                    switch ($PermissionState)
                    {
                        'Grant'
                        {
                            $sqlDatabase.Grant($permissionSet,$Name)
                        }

                        'Deny'
                        {
                            $sqlDatabase.Deny($permissionSet,$Name)
                        }
                    }
                }
                catch
                {
                    Write-Verbose -Message ("Failed removing SQL login $Name to permissions $permissions " + `
                                            "on database $Database on $sqlServer\$sqlInstanceName")
                }
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType LoginNotFound `
                                       -FormatArgs @($Name,$sqlServer,$sqlInstanceName) `
                                       -ErrorCategory ObjectNotFound
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NoDatabase `
                                   -FormatArgs @($Database,$sqlServer,$sqlInstanceName) `
                                   -ErrorCategory InvalidResult
    }
}

Export-ModuleMember -Function *-TargetResource
