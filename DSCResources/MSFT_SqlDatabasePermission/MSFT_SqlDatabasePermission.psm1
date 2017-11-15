Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
    Returns the current permissions for the user in the database

    .PARAMETER Database
    This is the SQL database

    .PARAMETER Name
    This is the name of the SQL login for the permission set

    .PARAMETER PermissionState
    This is the state of permission set. Valid values are 'Grant' or 'Deny'

    .PARAMETER Permissions
    This is a list that represents a SQL Server set of database permissions

    .PARAMETER ServerName
    This is the SQL Server for the database

    .PARAMETER InstanceName
    This is the SQL instance for the database
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'GrantWithGrant')]
        [System.String]
        $PermissionState,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Permissions,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Getting permissions for user $Name in database $Database"
        $currentEnsure = 'Absent'

        if ($sqlDatabaseObject = $sqlServerObject.Databases[$Database])
        {
            if ($sqlServerObject.Logins[$Name])
            {
                # Initialize variable permission
                [System.String[]] $getSqlDatabasePermissionResult = @()

                try
                {
                    $databasePermissionInfo = $sqlDatabaseObject.EnumDatabasePermissions($Name) | Where-Object -FilterScript {
                        $_.PermissionState -eq $PermissionState
                    }

                    foreach ($currentDatabasePermissionInfo in $databasePermissionInfo)
                    {
                        $permissionProperty = ($currentDatabasePermissionInfo.PermissionType | Get-Member -MemberType Property).Name

                        foreach ($currentPermissionProperty in $permissionProperty)
                        {
                            if ($currentDatabasePermissionInfo.PermissionType."$currentPermissionProperty")
                            {
                                $getSqlDatabasePermissionResult += $currentPermissionProperty
                            }
                        }
                    }
                }
                catch
                {
                    throw New-TerminatingError -ErrorType FailedToEnumDatabasePermissions `
                        -FormatArgs @($Name, $Database, $ServerName, $InstanceName) `
                        -ErrorCategory InvalidOperation `
                        -InnerException $_.Exception
                }

            }
            else
            {
                throw New-TerminatingError -ErrorType LoginNotFound `
                    -FormatArgs @($Name, $ServerName, $InstanceName) `
                    -ErrorCategory ObjectNotFound `
                    -InnerException $_.Exception
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType NoDatabase `
                -FormatArgs @($Database, $ServerName, $InstanceName) `
                -ErrorCategory InvalidResult `
                -InnerException $_.Exception
        }

        if ($getSqlDatabasePermissionResult)
        {
            $resultOfPermissionCompare = Compare-Object -ReferenceObject $Permissions `
                -DifferenceObject $getSqlDatabasePermissionResult
            if ($null -eq $resultOfPermissionCompare)
            {
                $currentEnsure = 'Present'
            }
        }
    }

    $returnValue = @{
        Ensure          = $currentEnsure
        Database        = $Database
        Name            = $Name
        PermissionState = $PermissionState
        Permissions     = $getSqlDatabasePermissionResult
        ServerName      = $ServerName
        InstanceName    = $InstanceName
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

    .PARAMETER ServerName
    This is the SQL Server for the database

    .PARAMETER InstanceName
    This is the SQL instance for the database
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'GrantWithGrant')]
        [System.String]
        $PermissionState,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Permissions,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName = 'MSSQLSERVER'
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Setting permissions of database $Database for login $Name"

        if ($sqlDatabaseObject = $sqlServerObject.Databases[$Database])
        {
            if ($sqlServerObject.Logins[$Name])
            {
                if ( -not ($sqlDatabaseObject.Users[$Name]))
                {
                    try
                    {
                        New-VerboseMessage -Message "Adding SQL login $Name as a user of database $Database"
                        $sqlDatabaseUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList ($sqlDatabaseObject, $Name)
                        $sqlDatabaseUser.Login = $Name
                        $sqlDatabaseUser.Create()
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType AddLoginDatabaseSetError `
                            -FormatArgs @($ServerName, $InstanceName, $Name, $Database) `
                            -ErrorCategory InvalidOperation `
                            -InnerException $_.Exception
                    }
                }

                if ($sqlDatabaseObject.Users[$Name])
                {
                    try
                    {
                        $permissionSet = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabasePermissionSet

                        foreach ($permission in $permissions)
                        {
                            $permissionSet."$permission" = $true
                        }

                        switch ($Ensure)
                        {
                            'Present'
                            {
                                New-VerboseMessage -Message ('{0} the permissions ''{1}'' to the database {2} on the server {3}\{4}' `
                                        -f $PermissionState, ($Permissions -join ','), $Database, $ServerName, $InstanceName)

                                switch ($PermissionState)
                                {
                                    'GrantWithGrant'
                                    {
                                        $sqlDatabaseObject.Grant($permissionSet, $Name, $true)
                                    }

                                    'Grant'
                                    {
                                        $sqlDatabaseObject.Grant($permissionSet, $Name)
                                    }

                                    'Deny'
                                    {
                                        $sqlDatabaseObject.Deny($permissionSet, $Name)
                                    }
                                }
                            }

                            'Absent'
                            {
                                New-VerboseMessage -Message ('Revoking {0} permissions {1} to the database {2} on the server {3}\{4}' `
                                        -f $PermissionState, ($Permissions -join ','), $Database, $ServerName, $InstanceName)

                                if ($PermissionState -eq 'GrantWithGrant')
                                {
                                    $sqlDatabaseObject.Revoke($permissionSet, $Name, $false, $true)
                                }
                                else
                                {
                                    $sqlDatabaseObject.Revoke($permissionSet, $Name)
                                }
                            }
                        }
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType FailedToSetPermissionDatabase `
                            -FormatArgs @($Name, $Database, $ServerName, $InstanceName) `
                            -ErrorCategory InvalidOperation `
                            -InnerException $_.Exception
                    }
                }
            }
            else
            {
                throw New-TerminatingError -ErrorType LoginNotFound `
                    -FormatArgs @($Name, $ServerName, $InstanceName) `
                    -ErrorCategory ObjectNotFound `
                    -InnerException $_.Exception
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType NoDatabase `
                -FormatArgs @($Database, $ServerName, $InstanceName) `
                -ErrorCategory InvalidResult `
                -InnerException $_.Exception
        }
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

    .PARAMETER ServerName
    This is the SQL Server for the database

    .PARAMETER InstanceName
    This is the SQL instance for the database
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'GrantWithGrant')]
        [System.String]
        $PermissionState,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Permissions,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName = 'MSSQLSERVER'
    )

    Write-Verbose -Message "Testing permissions for user $Name in database $Database."
    $getTargetResourceParameters = @{
        InstanceName    = $PSBoundParameters.InstanceName
        ServerName      = $PSBoundParameters.ServerName
        Database        = $PSBoundParameters.Database
        Name            = $PSBoundParameters.Name
        PermissionState = $PSBoundParameters.PermissionState
        Permissions     = $PSBoundParameters.Permissions
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    <#
        There is no need to evaluate the parameter Permissions here.
        In the Get-TargetResource function there is a test to verify if Permissions is in
        desired state. If the permissions are correct, then Get-TargetResource will return
        the value 'Present' for the Ensure parameter, otherwise Ensure will have the value
        'Absent'.
    #>
    return Test-SQLDscParameterState -CurrentValues $getTargetResourceResult `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('Name', 'Ensure', 'PermissionState')
}

Export-ModuleMember -Function *-TargetResource
