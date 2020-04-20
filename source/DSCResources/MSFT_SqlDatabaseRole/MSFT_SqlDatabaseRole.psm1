$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SqlServerDsc.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SqlServerDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlDatabaseRole'

<#
    .SYNOPSIS
        Returns the current state of the database role along with its membership.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies name of the database in which the role should be configured.

    .PARAMETER RoleName
        Specifies the name of the database role to be added or removed.

    .PARAMETER Members
        Specifies the members the database role should have. Existing members not included in this parameter will be
        removed.

    .PARAMETER MembersToInclude
        Specifies members the database role should include. Existing members will be left alone.

    .PARAMETER MembersToExclude
        Specifies members the database role should exclude.
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
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RoleName,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude
    )

    Write-Verbose -Message (
        $script:localizedData.GetDatabaseRoleProperties -f $RoleName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    if ($sqlServerObject)
    {
        $membersInDesiredState = $true
        $roleStatus = 'Absent'

        # Check if database exists.
        if (-not ($sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]))
        {
            $errorMessage = $script:localizedData.DatabaseNotFound -f $DatabaseName
            New-ObjectNotFoundException -Message $errorMessage
        }

        if ($sqlDatabaseRoleObject = $sqlDatabaseObject.Roles[$RoleName])
        {
            try
            {
                [System.String[]] $roleMembers = $sqlDatabaseRoleObject.EnumMembers()
            }
            catch
            {
                $errorMessage = $script:localizedData.EnumDatabaseRoleMemberNamesError -f $RoleName, $DatabaseName
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }

            if ($Members)
            {
                if ($MembersToInclude -or $MembersToExclude)
                {
                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull
                    New-InvalidOperationException -Message $errorMessage
                }

                if ($null -ne (Compare-Object -ReferenceObject $roleMembers -DifferenceObject $Members))
                {
                    Write-Verbose -Message (
                        $script:localizedData.DesiredMembersNotPresent -f $RoleName, $DatabaseName
                    )
                    $membersInDesiredState = $false
                }
            }
            else
            {
                if ($MembersToInclude)
                {
                    foreach ($memberName in $MembersToInclude)
                    {
                        if (-not ($memberName -in $roleMembers))
                        {
                            Write-Verbose -Message (
                                $script:localizedData.MemberNotPresent -f $memberName, $RoleName, $DatabaseName
                            )
                            $membersInDesiredState = $false
                        }
                    }
                }

                if ($MembersToExclude)
                {
                    foreach ($memberName in $MembersToExclude)
                    {
                        if ($memberName -in $roleMembers)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.MemberPresent -f $memberName, $RoleName, $DatabaseName
                            )
                            $membersInDesiredState = $false
                        }
                    }
                }
            }

            $roleStatus = 'Present'
        }
    }

    $returnValue = @{
        ServerName            = $ServerName
        InstanceName          = $InstanceName
        DatabaseName          = $DatabaseName
        RoleName              = $RoleName
        Members               = $roleMembers
        MembersToInclude      = $MembersToInclude
        MembersToExclude      = $MembersToExclude
        MembersInDesiredState = $membersInDesiredState
        Ensure                = $roleStatus
    }

    $returnValue
}

<#
    .SYNOPSIS
        Adds the role to the database and sets role membership when Ensure is set to 'Present'. When Ensure is set to
        'Absent' the role is removed from the database.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies name of the database in which the role should be configured.

    .PARAMETER RoleName
        Specifies the name of the database role to be added or removed.

    .PARAMETER Members
        Specifies the members the database role should have. Existing members not included in this parameter will be
        removed.

    .PARAMETER MembersToInclude
        Specifies members the database role should include. Existing members will be left alone.

    .PARAMETER MembersToExclude
        Specifies members the database role should exclude.

    .PARAMETER Ensure
        Specifies the desired state of the role.
#>

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
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
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RoleName,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.SetDatabaseRoleProperties -f $RoleName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    if ($sqlServerObject)
    {
        $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]

        switch ($Ensure)
        {
            'Absent'
            {
                try
                {
                    $sqlDatabaseRoleObjectToDrop = $sqlDatabaseObject.Roles[$RoleName]
                    if ($sqlDatabaseRoleObjectToDrop)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DropDatabaseRole -f $RoleName, $DatabaseName
                        )
                        $sqlDatabaseRoleObjectToDrop.Drop()
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.DropDatabaseRoleError -f $RoleName, $DatabaseName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }

            'Present'
            {
                if ($null -eq $sqlDatabaseObject.Roles[$RoleName])
                {
                    try
                    {
                        $newRoleObjectParams = @{
                            TypeName     = 'Microsoft.SqlServer.Management.Smo.DatabaseRole'
                            ArgumentList = @($sqlDatabaseObject, $RoleName)
                        }
                        $sqlDatabaseRoleObject = New-Object @newRoleObjectParams
                        if ($sqlDatabaseRoleObject)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.CreateDatabaseRole -f $RoleName, $DatabaseName
                            )
                            $sqlDatabaseRoleObject.Create()
                        }
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.CreateDatabaseRoleError -f $RoleName, $DatabaseName
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }

                if ($Members)
                {
                    if ($MembersToInclude -or $MembersToExclude)
                    {
                        $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull
                        New-InvalidOperationException -Message $errorMessage
                    }

                    $roleMembers = $sqlDatabaseObject.Roles[$RoleName].EnumMembers()
                    foreach ($memberName in $roleMembers)
                    {
                        if (-not ($memberName -in $Members))
                        {
                            $removeMemberParams = @{
                                SqlDatabaseObject = $sqlDatabaseObject
                                RoleName          = $RoleName
                                MemberName        = $memberName
                            }
                            Remove-SqlDscDatabaseRoleMember @removeMemberParams
                        }
                    }

                    $roleMembers = $sqlDatabaseObject.Roles[$RoleName].EnumMembers()
                    foreach ($memberName in $Members)
                    {
                        if (-not ($memberName -in $roleMembers))
                        {
                            $addMemberParams = @{
                                SqlDatabaseObject = $sqlDatabaseObject
                                RoleName          = $RoleName
                                MemberName        = $memberName
                            }
                            Add-SqlDscDatabaseRoleMember @addMemberParams
                        }
                    }
                }
                else
                {
                    if ($MembersToInclude)
                    {
                        $roleMembers = $sqlDatabaseObject.Roles[$RoleName].EnumMembers()
                        foreach ($memberName in $MembersToInclude)
                        {
                            if (-not ($memberName -in $roleMembers))
                            {
                                $addMemberParams = @{
                                    SqlDatabaseObject = $sqlDatabaseObject
                                    RoleName          = $RoleName
                                    MemberName        = $memberName
                                }
                                Add-SqlDscDatabaseRoleMember @addMemberParams
                            }
                        }
                    }

                    if ($MembersToExclude)
                    {
                        $roleMembers = $sqlDatabaseObject.Roles[$RoleName].EnumMembers()
                        foreach ($memberName in $MembersToExclude)
                        {
                            if ($memberName -in $roleMembers)
                            {
                                $removeMemberParams = @{
                                    SqlDatabaseObject = $sqlDatabaseObject
                                    RoleName          = $RoleName
                                    MemberName        = $memberName
                                }
                                Remove-SqlDscDatabaseRoleMember @removeMemberParams
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
        Tests the current state of the database role along with its membership.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies name of the database in which the role should be configured.

    .PARAMETER RoleName
        Specifies the name of the database role to be added or removed.

    .PARAMETER Members
        Specifies the members the database role should have. Existing members not included in this parameter will be
        removed.

    .PARAMETER MembersToInclude
        Specifies members the database role should include. Existing members will be left alone.

    .PARAMETER MembersToExclude
        Specifies members the database role should exclude.

    .PARAMETER Ensure
        Specifies the desired state of the role.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
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
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RoleName,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.TestDatabaseRoleProperties -f $RoleName
    )

    $getTargetResourceParameters = @{
        ServerName       = $PSBoundParameters.ServerName
        InstanceName     = $PSBoundParameters.InstanceName
        DatabaseName     = $PSBoundParameters.DatabaseName
        RoleName         = $PSBoundParameters.RoleName
        Members          = $PSBoundParameters.Members
        MembersToInclude = $PSBoundParameters.MembersToInclude
        MembersToExclude = $PSBoundParameters.MembersToExclude
    }
    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    $isDatabaseRoleInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                Write-Verbose -Message (
                    $script:localizedData.EnsureIsAbsent -f $RoleName
                )
                $isDatabaseRoleInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present' -or $getTargetResourceResult.MembersInDesiredState -eq $false)
            {
                Write-Verbose -Message (
                    $script:localizedData.EnsureIsPresent -f $RoleName
                )
                $isDatabaseRoleInDesiredState = $false
            }
        }
    }

    $isDatabaseRoleInDesiredState
}

<#
    .SYNOPSIS
        Adds a member to a database role in the SQL Server instance provided.

    .PARAMETER SqlDatabaseObject
        A database object.

    .PARAMETER RoleName
        String containing the name of the database role to add the member to.

    .PARAMETER MemberName
        String containing the name of the member which should be added to the database role.
#>
function Add-SqlDscDatabaseRoleMember
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlDatabaseObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RoleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MemberName
    )

    $databaseName = $SqlDatabaseObject.Name

    if (-not ($SqlDatabaseObject.Roles[$MemberName] -or $SqlDatabaseObject.Users[$MemberName]))
    {
        $errorMessage = $script:localizedData.DatabaseRoleOrUserNotFound -f $MemberName, $databaseName
        New-ObjectNotFoundException -Message $errorMessage
    }

    try
    {
        Write-Verbose -Message (
            $script:localizedData.AddDatabaseRoleMember -f $MemberName, $RoleName, $databaseName
        )
        $SqlDatabaseObject.Roles[$RoleName].AddMember($MemberName)
    }
    catch
    {
        $errorMessage = $script:localizedData.AddDatabaseRoleMemberError -f $MemberName, $RoleName, $databaseName
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Removes a member from a database role in the SQL Server instance provided.

    .PARAMETER SqlDatabaseObject
        A database object.

    .PARAMETER RoleName
        String containing the name of the database role to remove the member from.

    .PARAMETER MemberName
        String containing the name of the member which should be removed from the database role.
#>
function Remove-SqlDscDatabaseRoleMember
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlDatabaseObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RoleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MemberName
    )

    $databaseName = $SqlDatabaseObject.Name

    try
    {
        Write-Verbose -Message (
            $script:localizedData.DropDatabaseRoleMember -f $MemberName, $RoleName, $databaseName
        )
        $SqlDatabaseObject.Roles[$RoleName].DropMember($MemberName)
    }
    catch
    {
        $errorMessage = $script:localizedData.DropDatabaseRoleMemberError -f $MemberName, $RoleName, $databaseName
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

Export-ModuleMember -Function *-TargetResource
