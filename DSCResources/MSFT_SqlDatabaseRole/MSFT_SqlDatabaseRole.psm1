Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force

<#
    .SYNOPSIS
    Returns the current state of the user memberships in the role(s).

    .PARAMETER Ensure
    Specifies the desired state of the membership of the role(s).

    .PARAMETER Name
    Specifies the name of the login that evaluated if it is member of the role(s).

    .PARAMETER ServerName
    Specifies the SQL server on which the instance exist.

    .PARAMETER InstanceName
    Specifies the SQL instance in which the database exist.

    .PARAMETER Database
    Specifies the database in which the login (user) and role(s) exist.

    .PARAMETER Role
    Specifies one or more roles to which the login (user) will be evaluated if it should be added or removed.
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
        $Name,

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
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Role
    )

    Write-Verbose -Message "Getting SQL Database role for $Name"

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        # Check database exists
        if ( -not ($sqlDatabaseObject = $sqlServerObject.Databases[$Database]) )
        {
            throw New-TerminatingError -ErrorType NoDatabase `
                -FormatArgs @($Database, $ServerName, $InstanceName) `
                -ErrorCategory ObjectNotFound
        }

        # Check role exists
        foreach ($currentRole in $Role)
        {
            if ( -not ($sqlDatabaseObject.Roles[$currentRole]) )
            {
                throw New-TerminatingError -ErrorType RoleNotFound `
                    -FormatArgs @($currentRole, $Database, $ServerName, $InstanceName) `
                    -ErrorCategory ObjectNotFound
            }
        }

        # Check login exists
        if ( -not ($sqlServerObject.Logins[$Name]) )
        {
            throw New-TerminatingError -ErrorType LoginNotFound `
                -FormatArgs @($Name, $ServerName, $InstanceName) `
                -ErrorCategory ObjectNotFound
        }

        $ensure = 'Absent'
        $grantedRole = @()

        if ($sqlDatabaseUser = $sqlDatabaseObject.Users[$Name] )
        {
            foreach ($currentRole in $Role)
            {
                if ($sqlDatabaseUser.IsMember($currentRole))
                {
                    New-VerboseMessage -Message ("The login '$Name' is a member of the role '$currentRole' on the " + `
                            "database '$Database', on the instance $ServerName\$InstanceName")

                    $grantedRole += $currentRole
                }
                else
                {
                    New-VerboseMessage -Message ("The login '$Name' is not a member of the role '$currentRole' on the " + `
                            "database '$Database', on the instance $ServerName\$InstanceName")
                }
            }

            if ( -not (Compare-Object -ReferenceObject $Role -DifferenceObject $grantedRole) )
            {
                $ensure = 'Present'
            }
        }
        else
        {
            New-VerboseMessage -Message ("The login '$Name' is not a user of the database " + `
                    "'$Database' on the instance $ServerName\$InstanceName")
        }
    }

    $returnValue = @{
        Ensure       = $ensure
        Name         = $Name
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = $Database
        Role         = $grantedRole
    }

    $returnValue
}

<#
    .SYNOPSIS
    Adds the login (user) to each of the provided roles when Ensure is set to 'Present'.
    When Ensure is set to 'Absent' the login (user) will be removed from each of the provided roles.
    If the login does not exist as a user in the database, then the user will be created in the database using the login.

    .PARAMETER Ensure
    Specifies the desired state of the membership of the role(s).

    .PARAMETER Name
    Specifies the name of the login that evaluated if it is member of the role(s), if it is not it will be added.
    If the login does not exist as a user, a user will be created using the login.

    .PARAMETER ServerName
    Specifies the SQL server on which the instance exist.

    .PARAMETER InstanceName
    Specifies the SQL instance in which the database exist.

    .PARAMETER Database
    Specifies the database in which the login (user) and role(s) exist.

    .PARAMETER Role
    Specifies one or more roles to which the login (user) will be added or removed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

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
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Role
    )

    Write-Verbose -Message "Setting SQL Database role for $Name"

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        $sqlDatabaseObject = $sqlServerObject.Databases[$Database]

        switch ($Ensure)
        {
            'Present'
            {
                # Adding database user if it does not exist.
                if ( -not ($sqlDatabaseObject.Users[$Name]) )
                {
                    try
                    {
                        New-VerboseMessage -Message ("Adding the login '$Name' as a user of the database " + `
                                "'$Database', on the instance $ServerName\$InstanceName")

                        $sqlDatabaseUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User `
                            -ArgumentList $sqlDatabaseObject, $Name
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

                # Adding database user to the role.
                foreach ($currentRole in $Role)
                {
                    try
                    {
                        New-VerboseMessage -Message ("Adding the login '$Name' to the role '$currentRole' on the " + `
                                "database '$Database', on the instance $ServerName\$InstanceName")

                        $sqlDatabaseRole = $sqlDatabaseObject.Roles[$currentRole]
                        $sqlDatabaseRole.AddMember($Name)
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType AddMemberDatabaseSetError `
                            -FormatArgs @($ServerName, $InstanceName, $Name, $Role, $Database) `
                            -ErrorCategory InvalidOperation `
                            -InnerException $_.Exception
                    }
                }
            }

            'Absent'
            {
                try
                {
                    foreach ($currentRole in $Role)
                    {
                        New-VerboseMessage -Message ("Removing the login '$Name' to the role '$currentRole' on the " + `
                                "database '$Database', on the instance $ServerName\$InstanceName")

                        $sqlDatabaseRole = $sqlDatabaseObject.Roles[$currentRole]
                        $sqlDatabaseRole.DropMember($Name)
                    }
                }
                catch
                {
                    throw New-TerminatingError -ErrorType DropMemberDatabaseSetError `
                        -FormatArgs @($ServerName, $InstanceName, $Name, $Role, $Database) `
                        -ErrorCategory InvalidOperation `
                        -InnerException $_.Exception
                }
            }
        }
    }
}

<#
    .SYNOPSIS
    Tests if the login (user) has the desired state in each of the provided roles.

    .PARAMETER Ensure
    Specifies the desired state of the membership of the role(s).

    .PARAMETER Name
    Specifies the name of the login that evaluated if it is member of the role(s).

    .PARAMETER ServerName
    Specifies the SQL server on which the instance exist.

    .PARAMETER InstanceName
    Specifies the SQL instance in which the database exist.

    .PARAMETER Database
    Specifies the database in which the login (user) and role(s) exist.

    .PARAMETER Role
    Specifies one or more roles to which the login (user) will be tested if it should added or removed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

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
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Role
    )

    Write-Verbose -Message "Testing SQL Database role for $Name"

    $getTargetResourceParameters = @{
        InstanceName = $PSBoundParameters.InstanceName
        ServerName   = $PSBoundParameters.ServerName
        Role         = $PSBoundParameters.Role
        Database     = $PSBoundParameters.Database
        Name         = $PSBoundParameters.Name
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $isDatabaseRoleInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                New-VerboseMessage -Message "Ensure is set to Absent. The existing role for $Name should be dropped"
                $isDatabaseRoleInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                New-VerboseMessage -Message "Ensure is set to Present. The missing role for $Name should be added"
                $isDatabaseRoleInDesiredState = $false
            }
        }
    }

    $isDatabaseRoleInDesiredState
}

Export-ModuleMember -Function *-TargetResource
