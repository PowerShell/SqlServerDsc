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

    .PARAMETER Name
        The name of the endpoint.

    .PARAMETER Principal
        The login to which permission will be set.
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal
    )

    try
    {
        $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

        $endpointObject = $sqlServerObject.Endpoints[$Name]
        if ( $null -ne $endpointObject )
        {
            New-VerboseMessage -Message "Enumerating permissions for endpoint $Name"

            $permissionSet = New-Object -Property @{ Connect = $True } -TypeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet

            $endpointPermission = $endpointObject.EnumObjectPermissions( $permissionSet ) | Where-Object { $_.PermissionState -eq "Grant" -and $_.Grantee -eq $Principal }
            if ($endpointPermission.Count -ne 0)
            {
                $Ensure = 'Present'
                $Permission = 'CONNECT'
            }
            else
            {
                $Ensure = 'Absent'
                $Permission = ''
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType EndpointNotFound -FormatArgs @($Name) -ErrorCategory ObjectNotFound
        }
    }
    catch
    {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -FormatArgs @($Name) -ErrorCategory ObjectNotFound -InnerException $_.Exception
    }

    return @{
        InstanceName = [System.String] $InstanceName
        ServerName   = [System.String] $ServerName
        Ensure       = [System.String] $Ensure
        Name         = [System.String] $Name
        Principal    = [System.String] $Principal
        Permission   = [System.String] $Permission
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

    .PARAMETER Name
        The name of the endpoint.

    .PARAMETER Permission
        The permission to set for the login. Valid value for permission are only CONNECT.

    .PARAMETER Principal
        The permission to set for the login.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal,

        [Parameter()]
        [ValidateSet('CONNECT')]
        [System.String]
        $Permission
    )

    $parameters = @{
        InstanceName = [System.String] $InstanceName
        ServerName   = [System.String] $ServerName
        Name         = [System.String] $Name
        Principal    = [System.String] $Principal
    }

    $getTargetResourceResult = Get-TargetResource @parameters
    if ($getTargetResourceResult.Ensure -ne $Ensure)
    {
        $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

        $endpointObject = $sqlServerObject.Endpoints[$Name]
        if ($null -ne $endpointObject)
        {
            $permissionSet = New-Object -Property @{ Connect = $True } -TypeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet

            if ($Ensure -eq 'Present')
            {
                New-VerboseMessage -Message "Grant permission to $Principal on endpoint $Name"

                $endpointObject.Grant($permissionSet, $Principal)
            }
            else
            {
                New-VerboseMessage -Message "Revoke permission to $Principal on endpoint $Name"
                $endpointObject.Revoke($permissionSet, $Principal)
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType EndpointNotFound -FormatArgs @($Name) -ErrorCategory ObjectNotFound
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

    .PARAMETER Name
        The name of the endpoint.

    .PARAMETER Permission
        The permission to set for the login. Valid value for permission are only CONNECT.

    .PARAMETER Principal
        The permission to set for the login.
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal,

        [Parameter()]
        [ValidateSet('CONNECT')]
        [System.String]
        $Permission
    )

    $parameters = @{
        InstanceName = [System.String] $InstanceName
        ServerName   = [System.String] $ServerName
        Name         = [System.String] $Name
        Principal    = [System.String] $Principal
    }

    New-VerboseMessage -Message "Testing state of endpoint permission for $Principal"

    $getTargetResourceResult = Get-TargetResource @parameters

    return $getTargetResourceResult.Ensure -eq $Ensure
}

Export-ModuleMember -Function *-TargetResource
