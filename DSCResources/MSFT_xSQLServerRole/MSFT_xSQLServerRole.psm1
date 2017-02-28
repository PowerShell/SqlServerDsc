Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force
<#
    .SYNOPSIS
    This function gets the sql server role properties.
    
    .PARAMETER ServerRole
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
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRole,

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
    $ensure = 'Absent'

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Getting SQL Server role $ServerRole properties."
        if ($sqlServerRoleObject = $sqlServerObject.Roles[$ServerRole])
        {
            $membersInRole = $sqlServerRoleObject.EnumMemberNames()
            $ensure = "Present"
        }
    }

    $returnValue = @{
        Ensure          = $ensure
        Members         = $membersInRole
        ServerRole      = $ServerRole
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
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

    .PARAMETER ServerRole
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Members,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] 
        $MembersToInclude,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRole,

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
        Write-Verbose -Message "Setting SQL Server role $ServerRole properties."
        
        switch ($Ensure)
        {
            'Absent'
            {
                try 
                {
                    $sqlServerRoleObjectToDrop = $sqlServerObject.Roles[$ServerRole]
                    if ($sqlServerRoleObjectToDrop)
                    {
                        Write-Verbose -Message "Deleting to SQL the server role $ServerRole"
                        $sqlServerRoleObjectToDrop.Drop()
                        New-VerboseMessage -Message "Dropped server role $ServerRole"
                    }
                }
                catch
                {
                    throw New-TerminatingError -ErrorType DropServerRoleSetError `
                                               -FormatArgs @($SQLServer,$SQLInstanceName,$ServerRole) `
                                               -ErrorCategory InvalidOperation `
                                               -InnerException $_.Exception
                }
            }
            
            'Present'
            {              
                if ($null -eq $sqlServerObject.Roles[$ServerRole])
                {
                    try
                    {
                        $sqlServerRoleObjectToCreate = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $sqlServerObject,$ServerRole
                        if ($sqlServerRoleObjectToCreate)
                        {
                            Write-Verbose -Message "Adding to SQL the server role $ServerRole"
                            $sqlServerRoleObjectToCreate.Create()
                            New-VerboseMessage -Message "Created server role $ServerRole"
                        }
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType CreateServerRoleSetError `
                                                   -FormatArgs @($SQLServer,$SQLInstanceName,$ServerRole) `
                                                   -ErrorCategory InvalidOperation `
                                                   -InnerException $_.Exception
                    }
                }

                $memberNamesInRoleObject = $sqlServerObject.Roles[$ServerRole].EnumMemberNames()

                if ($Members)
                {
                    if ($MembersToInclude -or $MembersToExclude)
                    {
                        throw New-TerminatingError -ErrorType MembersToIncludeAndExcludeParamMustBeNull `
                                                   -FormatArgs @($SQLServer,$SQLInstanceName) `
                                                   -ErrorCategory InvalidArgument  
                    }

                    $missingMembers = (Compare-Object -ReferenceObject $Members -DifferenceObject $memberNamesInRoleObject).InputObject

                    foreach ($missingMember in $missingMembers)
                    {
                        if ( -not ($sqlServerObject.Logins[$missingMember]) )
                        {
                            throw New-TerminatingError -ErrorType LoginNotFound `
                                                       -FormatArgs @($missingMember, $SQLServer, $SQLInstanceName) `
                                                       -ErrorCategory ObjectNotFound
                        }

                        try
                        {
                            Write-Verbose -Message "Adding SQL login $missingMember in role $ServerRole"
                            $sqlServerObject.Roles[$ServerRole].AddMember($missingMember)
                            New-VerboseMessage -Message "SQL Role $ServerRole for $missingMember, successfullly added"
                        }
                        catch
                        {
                            throw New-TerminatingError -ErrorType AddMemberServerRoleSetError `
                                                        -FormatArgs @($SQLServer,$SQLInstanceName,$ServerRole,$missingMember) `
                                                        -ErrorCategory InvalidOperation `
                                                        -InnerException $_.Exception
                        }
                    }
                }
                
                if($MembersToInclude)
                {
                    foreach ($memberToInclude in $MembersToInclude)
                    {
                        if ( -not ($sqlServerObject.Logins[$memberToInclude]) )
                        {
                            throw New-TerminatingError -ErrorType LoginNotFound `
                                                       -FormatArgs @($memberToInclude, $SQLServer, $SQLInstanceName) `
                                                       -ErrorCategory ObjectNotFound
                        }

                        try
                        {
                            Write-Verbose -Message "Adding SQL login $memberToInclude in role $ServerRole"
                            $sqlServerObject.Roles[$ServerRole].AddMember($memberToInclude)
                            New-VerboseMessage -Message "SQL Role $ServerRole for $memberToInclude, successfullly added"
                        }
                        catch
                        {
                            throw New-TerminatingError -ErrorType AddMemberServerRoleSetError `
                                                        -FormatArgs @($SQLServer,$SQLInstanceName,$ServerRole,$memberToInclude) `
                                                        -ErrorCategory InvalidOperation `
                                                        -InnerException $_.Exception
                        }
                    }
                }

                if($MembersToExclude)
                {
                    foreach ($memberToExclude in $MembersToExclude)
                    {
                        if ( -not ($sqlServerObject.Logins[$memberToExclude]) )
                        {
                            throw New-TerminatingError -ErrorType LoginNotFound `
                                                       -FormatArgs @($memberToExclude, $SQLServer, $SQLInstanceName) `
                                                       -ErrorCategory ObjectNotFound
                        }

                        try
                        {
                            Write-Verbose -Message "Deleting SQL login $memberToExclude from role $ServerRole"
                            $sqlServerObject.Roles[$ServerRole].DropMember($memberToExclude)
                            New-VerboseMessage -Message "SQL Role $ServerRole for $memberToExclude, successfullly dropped"
                        }
                        catch
                        {
                            throw New-TerminatingError -ErrorType DropMemberServerRoleSetError `
                                                        -FormatArgs @($SQLServer,$SQLInstanceName,$ServerRole,$memberToExclude) `
                                                        -ErrorCategory InvalidOperation `
                                                        -InnerException $_.Exception
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

    .PARAMETER ServerRole
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Members,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] 
        $MembersToInclude,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRole,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName
    )

    Write-Verbose -Message "Testing SQL Server role $ServerRole properties."
    
    $getTargetResourceParameters = @{
        SQLInstanceName = $PSBoundParameters.SQLInstanceName
        SQLServer       = $PSBoundParameters.SQLServer
        ServerRole      = $PSBoundParameters.ServerRole
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters    
    $isServerRoleInDesiredState = $true
    
    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                New-VerboseMessage -Message "Ensure is set to Absent. The existing role $ServerRole should be dropped"
                $isServerRoleInDesiredState = $false
            }
        }
        
        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                New-VerboseMessage -Message "Ensure is set to Present. The missing role $ServerRole should be added"
                $isServerRoleInDesiredState = $false
            }
            else
            {
                if ($Members)
                {
                    if ($MembersToInclude -or $MembersToExclude)
                    {
                        throw New-TerminatingError -ErrorType MembersToIncludeAndExcludeParamMustBeNull `
                                                   -FormatArgs @($SQLServer,$SQLInstanceName) `
                                                   -ErrorCategory InvalidArgument  
                    }

                    if ( $null -ne (Compare-Object -ReferenceObject $getTargetResourceResult.Members -DifferenceObject $Members))
                    {
                        New-VerboseMessage -Message "The desired members are not present in server role $ServerRole"
                        $isServerRoleInDesiredState = $false
                    }
                }

                if($MembersToInclude)
                {
                    foreach ($memberToInclude in $MembersToInclude)
                    {
                        if ( -not ($getTargetResourceResult.Members.Contains($memberToInclude)))
                        {
                            New-VerboseMessage -Message "The included members are not present in server role $ServerRole"
                            $isServerRoleInDesiredState = $false
                        }
                    }
                }

                if($MembersToExclude)
                {
                    foreach ($memberToExclude in $MembersToExclude)
                    {
                        if ($getTargetResourceResult.Members.Contains($MembersToExclude))
                        {
                            New-VerboseMessage -Message "The excluded members are present in server role $ServerRole"
                            $isServerRoleInDesiredState = $false
                        }
                    }
                }
            }
        }
    }

    $isServerRoleInDesiredState
}

Export-ModuleMember -Function *-TargetResource
