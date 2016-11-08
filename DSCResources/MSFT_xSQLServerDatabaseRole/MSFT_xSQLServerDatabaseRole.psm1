$script:currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $($script:currentPath)"

Import-Module $script:currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Role
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        # Check database exists
        if ( !($sqlDatabase = $sql.Databases[$Database]) )
        {
            throw New-TerminatingError -ErrorType NoDatabase -FormatArgs @($Database, $SQLServer, $SQLInstanceName) -ErrorCategory ObjectNotFound
        }

        # Check role exists
        foreach ($currentRole in $Role)
        {
            if( !($sqlDatabase.Roles[$currentRole]) )
            {
                throw New-TerminatingError -ErrorType RoleNotFound -FormatArgs @($currentRole, $Database, $SQLServer, $SQLInstanceName) -ErrorCategory ObjectNotFound
            }
        }

        # Check login exists
        if ( !($sql.Logins[$Name]) )
        {
            throw New-TerminatingError -ErrorType LoginNotFound -FormatArgs @($Name, $SQLServer, $SQLInstanceName) -ErrorCategory ObjectNotFound
        }

        $Ensure = 'Absent'
        $grantedRole = @()

        if ($sqlDatabaseUser = $sqlDatabase.Users[$Name] )
        {
            foreach ($currentRole in $Role)
            {
                if ($sqlDatabaseUser.IsMember($currentRole))
                {
                    New-VerboseMessage -Message "The login '$Name' is a member of the role '$currentRole' on the database '$Database', on the instance $SQLServer\$SQLInstanceName"
                    
                    $grantedRole += $currentRole
                }
                else
                {
                    New-VerboseMessage -Message "The login '$Name' is not a member of the role '$currentRole' on the database '$Database', on the instance $SQLServer\$SQLInstanceName"
                }
            }

            if ( !(Compare-Object -ReferenceObject $Role -DifferenceObject $grantedRole) )
            {
                $Ensure = 'Present'
            }
        }
        else
        {
            New-VerboseMessage -Message "The login '$Name' is not a user of the database '$Database' on the instance $SQLServer\$SQLInstanceName"
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NotConnectedToInstance -FormatArgs @($SQLServer, $SQLInstanceName) -ErrorCategory InvalidResult
    }

    $returnValue = @{
        Ensure = $Ensure
        Name = $Name
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
        Database = $Database
        Role = $grantedRole
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Role
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        $sqlDatabase = $sql.Databases[ $Database ]
        
        switch ($Ensure)
        {
            'Present'
            {
                # Adding database user if it does not exist.
                if ( !($sqlDatabase.Users[$Name]) )
                {
                    try
                    {
                        New-VerboseMessage -Message "Adding the login '$Name' as a user of the database '$Database', on the instance $SQLServer\$SQLInstanceName"

                        $sqlDatabaseUser = New-Object Microsoft.SqlServer.Management.Smo.User $SQLDatabase, $Name
                        $sqlDatabaseUser.Login = $Name
                        $sqlDatabaseUser.Create()
                    }
                    catch
                    {
                        "Failed adding the login '$Name' as a user of the database '$Database', on the instance $SQLServer\$SQLInstanceName"

                        throw $_
                    }
                }

                # Adding database user to the role.
                foreach ($currentRole in $Role) 
                {
                    try
                    {
                        New-VerboseMessage -Message "Adding the login '$Name' to the role '$currentRole' on the database '$Database', on the instance $SQLServer\$SQLInstanceName"

                        $sqlDatabaseRole = $sqlDatabase.Roles[$currentRole]
                        $sqlDatabaseRole.AddMember($Name)
                    }
                    catch
                    {
                        New-VerboseMessage -Message "Failed adding the login '$Name' to the role '$currentRole' on the database '$Database', on the instance $SQLServer\$SQLInstanceName"

                        throw $_
                    }
                }
            }

            'Absent'
            {
                try
                {
                    foreach ($currentRole in $Role) 
                    {
                        New-VerboseMessage -Message "Removing the login '$Name' to the role '$currentRole' on the database '$Database', on the instance $SQLServer\$SQLInstanceName"

                        $sqlDatabaseRole = $sqlDatabase.Roles[$currentRole]
                        $sqlDatabaseRole.DropMember($Name)
                    }
                }
                catch
                {
                    New-VerboseMessage -Message "Failed removing the login '$Name' from the role '$Role' on the database '$Database', on the instance $SQLServer\$SQLInstanceName"

                    throw $_
                }
            }
        }
    }

    if ( !(Test-TargetResource @PSBoundParameters) )
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Role
    )

    return (((Get-TargetResource @PSBoundParameters).Ensure) -eq $Ensure)
}

Export-ModuleMember -Function *-TargetResource
