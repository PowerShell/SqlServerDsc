$script:currentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Import-Module -Name (Join-Path -Path (Split-Path -Path (Split-Path -Path $script:currentPath -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1')

<#
    .SYNOPSIS
        Returns the current joined state of the Availability Group.

    .PARAMETER Ensure
        If the replica should be joined ('Present') to the Availability Group or not joined ('Absent') to the Availability Group.

    .PARAMETER AvailabilityGroupName
        The name Availability Group to join.

    .PARAMETER SQLServer
        Name of the SQL server to be configured.

    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configured.

    .PARAMETER SetupCredential
        Credential to be used to Grant Permissions in SQL.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupName,

        [Parameter()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [System.String]
        $SQLInstanceName= 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -SetupCredential $SetupCredential
    
    if (Test-TargetResource @PSBoundParameters)
    {
        $ensure = 'Present'
    }
    else 
    {
        $ensure = 'Absent'
    } 

    return @{
        Ensure = $ensure
        AvailabilityGroupName = $sql.AvailabilityGroups[$AvailabilityGroupName].Name
        AvailabilityGroupNameListener = $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityGroupListeners.Name
        AvailabilityGroupNameIP = $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityGroupListeners.AvailabilityGroupListenerIPAddresses.IPAddress
        AvailabilityGroupSubMask =  $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityGroupListeners.AvailabilityGroupListenerIPAddresses.SubnetMask
        AvailabilityGroupPort =  $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityGroupListeners.PortNumber
        AvailabilityGroupNameDatabase = $sql.AvailabilityGroups[$AvailabilityGroupName].AvailabilityDatabases.Name
        BackupDirectory = ""
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }
}

<#
    .SYNOPSIS
        Join the node to the the Availability Group.

    .PARAMETER Ensure
        If the replica should be joined ('Present') to the Availability Group or not joined ('Absent') to the Availability Group.

    .PARAMETER AvailabilityGroupName
        The name Availability Group to join.

    .PARAMETER SQLServer
        Name of the SQL server to be configured.

    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configured.

    .PARAMETER SetupCredential
        Credential to be used to Grant Permissions in SQL.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupName,

        [Parameter()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [System.String]
        $SQLInstanceName= 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )

    Initialize-SqlServerAssemblies

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -SetupCredential $SetupCredential
    Grant-ServerPerms -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -AuthorizedUser "NT AUTHORITY\SYSTEM" -SetupCredential $SetupCredential
        
    try
    {
        $sql.JoinAvailabilityGroup($AvailabilityGroupName)
        New-VerboseMessage -Message "Joined $SQLServer\$SQLInstanceName to $AvailabilityGroupName"       
    }
    catch
    {
        throw "Unable to Join $AvailabilityGroupName on $SQLServer\$SQLInstanceName"
    }
}

<#
    .SYNOPSIS
        Test if the node is joined to the Availability Group.

    .PARAMETER Ensure
        If the replica should be joined ('Present') to the Availability Group or not joined ('Absent') to the Availability Group.

    .PARAMETER AvailabilityGroupName
        The name Availability Group to join.

    .PARAMETER SQLServer
        Name of the SQL server to be configured.

    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configured.

    .PARAMETER SetupCredential
        Credential to be used to Grant Permissions in SQL.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupName,

        [Parameter()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [System.String]
        $SQLInstanceName= 'MSSQLSERVER',

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -SetupCredential $SetupCredential

    $returnValue = $false

    switch ($Ensure)
    {
        'Present'
        {
            $availabilityGroupPresent = $sql.AvailabilityGroups.Contains($AvailabilityGroupName)

            if ($availabilityGroupPresent)
            {
                $returnValue = $true
            }
        }

        "Absent"
        {
            $availabilityGroupPresent = $sql.AvailabilityGroups.Contains($AvailabilityGroupName)

            if (!$availabilityGroupPresent)
            {
                $returnValue = $true
            }
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Loads the needed assemblies for the resource to be able to use methods.
#>
function Initialize-SqlServerAssemblies
{
    param ()

    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
    $null = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended")
}

Export-ModuleMember -Function *-TargetResource
