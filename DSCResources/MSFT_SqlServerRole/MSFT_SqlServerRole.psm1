Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
    This function gets the sql server role properties.

    .PARAMETER Members
    The members the server role should have.

    .PARAMETER MembersToInclude
    The members the server role should include.

    .PARAMETER MembersToExclude
    The members the server role should exclude.

    .PARAMETER ServerRoleName
    The name of server role to be created or dropped.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    $ensure = 'Present'

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Getting properties of SQL Server role '$ServerRoleName'."
        if ($sqlServerRoleObject = $sqlServerObject.Roles[$ServerRoleName])
        {
            try
            {
                [System.String[]] $membersInRole = $sqlServerRoleObject.EnumMemberNames()
            }
            catch
            {
                throw New-TerminatingError -ErrorType EnumMemberNamesServerRoleGetError `
                    -FormatArgs @($SQLServer, $SQLInstanceName, $ServerRoleName) `
                    -ErrorCategory InvalidOperation `
                    -InnerException $_.Exception
            }

            if ($Members)
            {
                if ($MembersToInclude -or $MembersToExclude)
                {
                    throw New-TerminatingError -ErrorType MembersToIncludeAndExcludeParamMustBeNull `
                        -FormatArgs @($SQLServer, $SQLInstanceName) `
                        -ErrorCategory InvalidArgument
                }

                if ( $null -ne (Compare-Object -ReferenceObject $membersInRole -DifferenceObject $Members))
                {
                    New-VerboseMessage -Message "The desired members are not present in server role $ServerRoleName"
                    $ensure = 'Absent'
                }
            }
            else
            {
                if ($MembersToInclude)
                {
                    foreach ($memberToInclude in $MembersToInclude)
                    {
                        if ( -not ($membersInRole.Contains($memberToInclude)))
                        {
                            New-VerboseMessage -Message "The included members are not present in server role $ServerRoleName"
                            $ensure = 'Absent'
                        }
                    }
                }

                if ($MembersToExclude)
                {
                    foreach ($memberToExclude in $MembersToExclude)
                    {
                        if ($membersInRole.Contains($memberToExclude))
                        {
                            New-VerboseMessage -Message "The excluded members are present in server role $ServerRoleName"
                            $ensure = 'Absent'
                        }
                    }
                }
            }
        }
        else
        {
            $ensure = 'Absent'
        }
    }

    $returnValue = @{
        Ensure           = $ensure
        Members          = $membersInRole
        MembersToInclude = $MembersToInclude
        MembersToExclude = $MembersToExclude
        ServerRoleName   = $ServerRoleName
        SQLServer        = $SQLServer
        SQLInstanceName  = $SQLInstanceName
    }
    $returnValue
}

<#
    .SYNOPSIS
    This function sets the sql server role properties.

    .PARAMETER Ensure
    When set to 'Present', the server role will be created.
    When set to 'Absent', the server role will be dropped.

    .PARAMETER Members
    The members the server role should have.

    .PARAMETER MembersToInclude
    The members the server role should include.

    .PARAMETER MembersToExclude
    The members the server role should exclude.

    .PARAMETER ServerRoleName
    The name of server role to be created or dropped.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Setting properties of SQL Server role '$ServerRoleName'."

        switch ($Ensure)
        {
            'Absent'
            {
                try
                {
                    $sqlServerRoleObjectToDrop = $sqlServerObject.Roles[$ServerRoleName]
                    if ($sqlServerRoleObjectToDrop)
                    {
                        Write-Verbose -Message "Trying to drop the SQL Server role '$ServerRoleName'."
                        $sqlServerRoleObjectToDrop.Drop()
                        New-VerboseMessage -Message "Dropped the SQL Server role '$ServerRoleName'."
                    }
                }
                catch
                {
                    throw New-TerminatingError -ErrorType DropServerRoleSetError `
                        -FormatArgs @($SQLServer, $SQLInstanceName, $ServerRoleName) `
                        -ErrorCategory InvalidOperation `
                        -InnerException $_.Exception
                }
            }

            'Present'
            {
                if ($null -eq $sqlServerObject.Roles[$ServerRoleName])
                {
                    try
                    {
                        $sqlServerRoleObjectToCreate = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerRole `
                            -ArgumentList $sqlServerObject, $ServerRoleName
                        if ($sqlServerRoleObjectToCreate)
                        {
                            Write-Verbose -Message "Creating the SQL Server role '$ServerRoleName'."
                            $sqlServerRoleObjectToCreate.Create()
                            New-VerboseMessage -Message "Created the SQL Server role '$ServerRoleName'."
                        }
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType CreateServerRoleSetError `
                            -FormatArgs @($SQLServer, $SQLInstanceName, $ServerRoleName) `
                            -ErrorCategory InvalidOperation `
                            -InnerException $_.Exception
                    }
                }

                if ($Members)
                {
                    if ($MembersToInclude -or $MembersToExclude)
                    {
                        throw New-TerminatingError -ErrorType MembersToIncludeAndExcludeParamMustBeNull `
                            -FormatArgs @($SQLServer, $SQLInstanceName) `
                            -ErrorCategory InvalidArgument
                    }

                    $memberNamesInRoleObject = $sqlServerObject.Roles[$ServerRoleName].EnumMemberNames()

                    foreach ($memberName in $memberNamesInRoleObject)
                    {
                        if ( -not ($Members.Contains($memberName)))
                        {
                            Remove-SqlDscServerRoleMember -SqlServerObject $sqlServerObject `
                                -LoginName $memberName `
                                -ServerRoleName $ServerRoleName
                        }
                    }

                    foreach ($memberToAdd in $Members)
                    {
                        if ( -not ($memberNamesInRoleObject.Contains($memberToAdd)))
                        {
                            Add-SqlDscServerRoleMember -SqlServerObject $sqlServerObject `
                                -LoginName $memberToAdd `
                                -ServerRoleName $ServerRoleName
                        }
                    }
                }
                else
                {
                    if ($MembersToInclude)
                    {
                        $memberNamesInRoleObject = $sqlServerObject.Roles[$ServerRoleName].EnumMemberNames()

                        foreach ($memberToInclude in $MembersToInclude)
                        {
                            if ( -not ($memberNamesInRoleObject.Contains($memberToInclude)))
                            {
                                Add-SqlDscServerRoleMember -SqlServerObject $sqlServerObject `
                                    -LoginName $memberToInclude `
                                    -ServerRoleName $ServerRoleName
                            }
                        }
                    }

                    if ($MembersToExclude)
                    {
                        $memberNamesInRoleObject = $sqlServerObject.Roles[$ServerRoleName].EnumMemberNames()

                        foreach ($memberToExclude in $MembersToExclude)
                        {
                            if ($memberNamesInRoleObject.Contains($memberToExclude))
                            {
                                Remove-SqlDscServerRoleMember -SqlServerObject $sqlServerObject `
                                    -LoginName $memberToExclude `
                                    -ServerRoleName $ServerRoleName
                            }
                        }
                    }
                }
            }
        }
    }
}

<#
    .SYNOPSIS
    This function tests the sql server role properties.

    .PARAMETER Ensure
    When set to 'Present', the server role will be created.
    When set to 'Absent', the server role will be dropped.

    .PARAMETER Members
    The members the server role should have.

    .PARAMETER MembersToInclude
    The members the server role should include.

    .PARAMETER MembersToExclude
    The members the server role should exclude.

    .PARAMETER ServerRoleName
    The name of server role to be created or dropped.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
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
        $Ensure = 'Present',

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName
    )

    Write-Verbose -Message "Testing SQL Server role $ServerRoleName properties."

    $getTargetResourceParameters = @{
        SQLInstanceName  = $PSBoundParameters.SQLInstanceName
        SQLServer        = $PSBoundParameters.SQLServer
        ServerRoleName   = $PSBoundParameters.ServerRoleName
        Members          = $PSBoundParameters.Members
        MembersToInclude = $PSBoundParameters.MembersToInclude
        MembersToExclude = $PSBoundParameters.MembersToExclude
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    $isServerRoleInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                New-VerboseMessage -Message "Ensure is set to Absent. The existing role $ServerRoleName should be dropped"
                $isServerRoleInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                New-VerboseMessage -Message ("Ensure is set to Present. The missing role $ServerRoleName " + `
                        "should be added or members are not correctly configured")
                $isServerRoleInDesiredState = $false
            }
        }
    }

    $isServerRoleInDesiredState
}

<#
    .SYNOPSIS
        Add a user to a server role in the SQL Server instance provided.

    .PARAMETER SqlServerObject
        An object returned from Connect-SQL function.

    .PARAMETER LoginName
        String containing the login (user) which should be added as a member to the server role.

    .PARAMETER ServerRoleName
        String containing the name of the server role which the user will be added as a member to.
#>
function Add-SqlDscServerRoleMember
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
        $LoginName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName
    )

    if ( -not ($SqlServerObject.Logins[$LoginName]) )
    {
        throw New-TerminatingError -ErrorType LoginNotFound `
            -FormatArgs @($LoginName, $SQLServer, $SQLInstanceName) `
            -ErrorCategory ObjectNotFound
    }

    try
    {
        Write-Verbose -Message "Adding SQL login $LoginName in role $ServerRoleName"
        $SqlServerObject.Roles[$ServerRoleName].AddMember($LoginName)
        New-VerboseMessage -Message "SQL Role $ServerRoleName for $LoginName, successfullly added"
    }
    catch
    {
        throw New-TerminatingError -ErrorType AddMemberServerRoleSetError `
            -FormatArgs @($SQLServer, $SQLInstanceName, $ServerRoleName, $LoginName) `
            -ErrorCategory InvalidOperation `
            -InnerException $_.Exception
    }
}

<#
    .SYNOPSIS
        Remove a user in a server role in the SQL Server instance provided.

    .PARAMETER SqlServerObject
        An object returned from Connect-SQL function.

    .PARAMETER LoginName
        String containing the login (user) which should be removed as a member in the server role.

    .PARAMETER ServerRoleName
        String containing the name of the server role for which the user will be removed as a member.
#>
function Remove-SqlDscServerRoleMember
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
        $LoginName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName
    )

    if ( -not ($SqlServerObject.Logins[$LoginName]) )
    {
        throw New-TerminatingError -ErrorType LoginNotFound `
            -FormatArgs @($LoginName, $SQLServer, $SQLInstanceName) `
            -ErrorCategory ObjectNotFound
    }

    try
    {
        Write-Verbose -Message "Removing SQL login $LoginName from role $ServerRoleName"
        $SqlServerObject.Roles[$ServerRoleName].DropMember($LoginName)
        New-VerboseMessage -Message "SQL Role $ServerRoleName for $LoginName, successfullly dropped"
    }
    catch
    {
        throw New-TerminatingError -ErrorType DropMemberServerRoleSetError `
            -FormatArgs @($SQLServer, $SQLInstanceName, $ServerRoleName, $LoginName) `
            -ErrorCategory InvalidOperation `
            -InnerException $_.Exception
    }
}

Export-ModuleMember -Function *-TargetResource
