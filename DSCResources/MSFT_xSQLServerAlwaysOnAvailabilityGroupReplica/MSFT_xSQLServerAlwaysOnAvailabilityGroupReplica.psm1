Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

<#
    .SYNOPSIS
    Gets the specified Availabilty Group Replica from the specified Availabilty Group.
    
    .PARAMETER Name
    The name of the availability group replica.

    .PARAMETER AvailabilityGroupName
    The name of the availability group.

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured.
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [String]
        $AvailabilityGroupName,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName
    )
    
    # Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
}

<#
    .SYNOPSIS
    Creates or removes the availability group replica in accordance with the desired state.
    
    .PARAMETER Name
    The name of the availability group replica.

    .PARAMETER AvailabilityGroupName
    The name of the availability group.

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured.
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued.

    .PARAMETER Ensure
    Specifies if the availability group replica should be present or absent. Default is Present.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [String]
        $AvailabilityGroupName,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )
    
    Import-SQLPSModule
    
    # Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
}

<#
    .SYNOPSIS
    Determines if the availability group replica is in the desired state.
    
    .PARAMETER Name
    The name of the availability group replica.

    .PARAMETER AvailabilityGroupName
    The name of the availability group.

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured.
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued.

    .PARAMETER Ensure
    Specifies if the availability group should be present or absent. Default is Present.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [String]
        $AvailabilityGroupName,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )
}

Export-ModuleMember -Function *-TargetResource