$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

<#
    .SYNOPSIS
        Returns the cluster role/group that is waiting to be created,
        along with the time and number of times to wait.

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group. Default values is 20 seconds.

    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error. Default values is 30 times.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [UInt64] $RetryIntervalSec = 20,
        [UInt32] $RetryCount = 30
    )

    @{
        Name = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
    }
}

<#
    .SYNOPSIS
        Waits for a cluster role/group to be created

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group. Default values is 20 seconds.

    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error. Default values is 30 times.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.UInt64]
        $RetryIntervalSec = 20,

        [System.UInt32]
        $RetryCount = 30
    )

    $AGFound = $false
    New-VerboseMessage -Message "Checking for Availaibilty Group $Name. Will try for a total of $($RetryIntervalSec*$RetryCount) seconds."

    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        try
        {
            $clusterGroup = Get-ClusterGroup -Name $Name -ErrorAction Ignore

            if ($clusterGroup -ne $null)
            {
                New-VerboseMessage -Message "Found Availability Group $Name"
                $AGFound = $true
                Start-Sleep -Seconds $RetryIntervalSec
                break;
            }

        }
        catch
        {
             New-VerboseMessage -Message "Availability Group $Name not found. Will retry again after $RetryIntervalSec sec"
        }

        New-VerboseMessage -Message "Availability Group $Name not found. Will retry again after $RetryIntervalSec sec"
        Start-Sleep -Seconds $RetryIntervalSec
    }

    if (! $AGFound)
    {
        throw "Availability Group $Name not found after $count attempts with $RetryIntervalSec sec interval"
        Exit
    }


}

<#
    .SYNOPSIS
        Tests if the cluster role/group has been created.

    .PARAMETER Name
        Name of the cluster role/group to look for (normally the same as the Availability Group name).

    .PARAMETER RetryIntervalSec
        The interval, in seconds, to check for the presence of the cluster role/group. Default values is 20 seconds.

    .PARAMETER RetryCount
        Maximum number of retries until the resource will timeout and throw an error. Default values is 30 times.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.UInt64]
        $RetryIntervalSec = 20,

        [System.UInt32]
        $RetryCount = 30
    )

    New-VerboseMessage -Message "Checking for Availability Group $Name ..."

    try
    {

        $clusterGroup = Get-ClusterGroup -Name $Name -ErrorAction Ignore

        if ($clusterGroup -eq $null)
        {
            New-VerboseMessage -Message "Availability Group $Name not found"
            $false
        }
        else
        {
            New-VerboseMessage -Message "Found Availabilty Group $Name"
            $true
        }
    }
    catch
    {
        New-VerboseMessage -Message "Availability Group $Name not found"
        $false
    }
}


Export-ModuleMember -Function *-TargetResource

