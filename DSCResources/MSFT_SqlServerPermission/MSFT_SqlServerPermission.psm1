Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
        Returns the current state of the permissions for the principal (login).

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured.

    .PARAMETER Principal
        The login to which permission will be set.

    .PARAMETER Permission
        The permission to set for the login. Valid values are AlterAnyAvailabilityGroup, ViewServerState or AlterAnyEndPoint.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal,

        [Parameter()]
        [ValidateSet('ConnectSql', 'AlterAnyAvailabilityGroup', 'ViewServerState', 'AlterAnyEndPoint')]
        [System.String[]]
        $Permission
    )

    New-VerboseMessage -Message "Enumerating permissions for $Principal"

    try
    {
        $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

        # Gets a set of permissions granted based on the desired permissions in $Permission
        $desiredPermissionSet = Get-SQLServerPermissionSet -Permission $Permission
        $grantedPermissionSet = $sqlServerObject.EnumServerPermissions( $Principal, $desiredPermissionSet ) |
            Where-Object { $_.PermissionState -eq 'Grant' }

        if ($null -ne $grantedPermissionSet)
        {
            $concatenatedGrantedPermissionSet = Get-SQLServerPermissionSet -PermissionSet $grantedPermissionSet.PermissionType

            # Compare desired and granted permissions based on the permissions properties from $Permission.
            if (-not (Compare-Object -ReferenceObject $desiredPermissionSet -DifferenceObject $concatenatedGrantedPermissionSet -Property $Permission))
            {
                $ensure = 'Present'
            }
            else
            {
                $ensure = 'Absent'
            }

            # Return granted permissions as a string array.
            $grantedPermission = Get-SQLPermission -ServerPermissionSet $concatenatedGrantedPermissionSet
        }
        else
        {
            $ensure = 'Absent'
            $grantedPermission = ''
        }
    }
    catch
    {
        throw New-TerminatingError -ErrorType PermissionGetError -FormatArgs @($Principal) -ErrorCategory InvalidOperation -InnerException $_.Exception
    }

    return @{
        InstanceName = [System.String] $InstanceName
        ServerName   = [System.String] $ServerName
        Ensure       = [System.String] $ensure
        Principal    = [System.String] $Principal
        Permission   = [System.String[]] $grantedPermission
    }
}

<#
    .SYNOPSIS
        Grants or revokes the permission for the the principal (login).

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured.

    .PARAMETER Ensure
        If the permission should be present or absent. Default value is 'Present'.

    .PARAMETER Principal
        The login to which permission will be set.

    .PARAMETER Permission
        The permission to set for the login. Valid values are AlterAnyAvailabilityGroup, ViewServerState or AlterAnyEndPoint.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal,

        [Parameter()]
        [ValidateSet('ConnectSql', 'AlterAnyAvailabilityGroup', 'ViewServerState', 'AlterAnyEndPoint')]
        [System.String[]]
        $Permission
    )

    $getTargetResourceParameters = @{
        InstanceName = [System.String] $InstanceName
        ServerName   = [System.String] $ServerName
        Principal    = [System.String] $Principal
        Permission   = [System.String[]] $Permission
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    if ($getTargetResourceResult.Ensure -ne $Ensure)
    {
        try
        {
            $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

            $permissionSet = Get-SQLServerPermissionSet -Permission $Permission

            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message ('Grant permission for ''{0}''' -f $Principal)

                $sqlServerObject.Grant($permissionSet, $Principal)
            }
            else
            {
                Write-Verbose -Message ('Revoke permission for ''{0}''' -f $Principal)

                $sqlServerObject.Revoke($permissionSet, $Principal)
            }
        }
        catch
        {
            throw New-TerminatingError -ErrorType ChangingPermissionFailed -FormatArgs @($Principal) -ErrorCategory InvalidOperation -InnerException $_.Exception
        }
    }
    else
    {
        New-VerboseMessage -Message "State is already $Ensure"
    }
}

<#
    .SYNOPSIS
        Tests if the principal (login) has the desired permissions.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured.

    .PARAMETER Ensure
        If the permission should be present or absent. Default value is 'Present'.

    .PARAMETER Principal
        The login to which permission will be set.

    .PARAMETER Permission
        The permission to set for the login. Valid values are AlterAnyAvailabilityGroup, ViewServerState or AlterAnyEndPoint.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal,

        [Parameter()]
        [ValidateSet('ConnectSql', 'AlterAnyAvailabilityGroup', 'ViewServerState', 'AlterAnyEndPoint')]
        [System.String[]]
        $Permission
    )

    $getTargetResourceParameters = @{
        InstanceName = $InstanceName
        ServerName   = $ServerName
        Principal    = $Principal
        Permission   = $Permission
    }

    New-VerboseMessage -Message "Verifying permissions for $Principal"

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    return $getTargetResourceResult.Ensure -eq $Ensure
}

<#
    .SYNOPSIS
       Takes a Microsoft.SqlServer.Management.Smo.ServerPermissionSet object which will be
       enumerated and returned as a string array.

    .PARAMETER ServerPermissionSet
        A PermissionSet object which should be enumerated.
#>
function Get-SQLPermission
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
        [ValidateNotNullOrEmpty()]
        $ServerPermissionSet
    )

    [System.String[]] $permissionArray = @()

    foreach ($property in $($ServerPermissionSet | Get-Member -Type Property))
    {
        if ($ServerPermissionSet.$($property.Name))
        {
            $permissionArray += $property.Name
        }
    }

    return $permissionArray
}

<#
    .SYNOPSIS
       Takes either an array of strings or an array of Microsoft.SqlServer.Management.Smo.ServerPermissionSet objects which
       will be enumerated and concatenated to a single Microsoft.SqlServer.Management.Smo.ServerPermissionSet object.

    .PARAMETER Permission
        An array of strings which should be concatenated to a single Microsoft.SqlServer.Management.Smo.ServerPermissionSet object.

    .PARAMETER ServerPermissionSet
        An array of Microsoft.SqlServer.Management.Smo.ServerPermissionSet objects which should be concatenated to a single
        Microsoft.SqlServer.Management.Smo.ServerPermissionSet object.
#>
function Get-SQLServerPermissionSet
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Permission')]
        [System.String[]]
        [ValidateNotNullOrEmpty()]
        $Permission,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServerPermissionSet')]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet[]]
        [ValidateNotNullOrEmpty()]
        $PermissionSet
    )

    if ($Permission)
    {
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] $concatenatedPermissionSet = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerPermissionSet

        foreach ($currentPermission in $Permission)
        {
            $concatenatedPermissionSet.$($currentPermission) = $true
        }
    }
    else
    {
        $concatenatedPermissionSet = Merge-SQLPermissionSet -Object $PermissionSet
    }

    return $concatenatedPermissionSet
}

<#
    .SYNOPSIS
       Merges an array of any PermissionSet objects into a single PermissionSet.

       The though with this helper function si it can be used for any permission set object
       because all inherits from Microsoft.SqlServer.Management.Smo.PermissionSetBase.

    .PARAMETER Object
        An array of strings which should be concatenated to a single PermissionSet object.
#>
function Merge-SQLPermissionSet
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $Object
    )

    $baseObject = New-Object -TypeName ($Object[0].GetType())

    foreach ($currentObject in $Object)
    {
        foreach ($Property in $($currentObject | Get-Member -Type Property))
        {
            if ($currentObject.$($Property.Name))
            {
                $baseObject.$($Property.Name) = $currentObject.$($Property.Name)
            }
        }
    }

    return $baseObject
}

Export-ModuleMember -Function *-TargetResource
