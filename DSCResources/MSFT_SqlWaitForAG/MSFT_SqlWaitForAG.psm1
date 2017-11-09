Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force

<#
    .SYNOPSIS
        Returns the cluster role/group that is waiting to be created,
        along with the time and number of times to wait.

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group.
        Default value is 20 seconds.
        When the cluster role/group has been found the resource will wait for this amount of time once
        more before returning.

    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error. Default values is 30 times.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 20,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    $clusterGroupFound = $false

    $clusterGroup = Get-ClusterGroup -Name $Name -ErrorAction SilentlyContinue
    if ($null -ne $clusterGroup)
    {
        $clusterGroupFound = $true
    }

    return @{
        Name             = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
        GroupExist       = $clusterGroupFound
    }
}

<#
    .SYNOPSIS
        Waits for a cluster role/group to be created

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group.
        Default value is 20 seconds.
        When the cluster role/group has been found the resource will wait for this amount of time once
        more before returning.

    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error. Default values is 30 times.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 20,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    New-VerboseMessage -Message "Checking for cluster group $Name. Will try for a total of $($RetryIntervalSec*$RetryCount) seconds."

    $getTargetResourceParameters = @{
        Name             = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
    }

    for ($forLoopCount = 0; $forLoopCount -lt $RetryCount; $forLoopCount++)
    {
        $clusterGroupFound = (Get-TargetResource @getTargetResourceParameters).GroupExist
        if ($clusterGroupFound)
        {
            New-VerboseMessage -Message "Found cluster group $Name. Will sleep for another $RetryIntervalSec seconds before continuing."
            Start-Sleep -Seconds $RetryIntervalSec
            break
        }

        New-VerboseMessage -Message "Cluster group $Name not found. Will retry again after $RetryIntervalSec sec"
        Start-Sleep -Seconds $RetryIntervalSec
    }

    if (-not $clusterGroupFound)
    {
        throw "Cluster group $Name not found after $RetryCount attempts with $RetryIntervalSec sec interval"
    }
}

<#
    .SYNOPSIS
        Tests if the cluster role/group has been created.

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group.
        Default value is 20 seconds.
        When the cluster role/group has been found the resource will wait for this amount of time once
        more before returning.

    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error. Default values is 30 times.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 20,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 30
    )

    New-VerboseMessage -Message "Testing for cluster group $Name."

    $getTargetResourceParameters = @{
        Name             = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
    }

    $clusterGroupFound = (Get-TargetResource @getTargetResourceParameters).GroupExist
    if ($clusterGroupFound)
    {
        New-VerboseMessage -Message "Found cluster group $Name"
    }
    else
    {
        New-VerboseMessage -Message "Cluster group $Name not found"
    }

    return $clusterGroupFound
}

Export-ModuleMember -Function *-TargetResource
