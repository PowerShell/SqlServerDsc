Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force
<#
    .SYNOPSIS
    This function gets the max degree of parallelism Server Configuration Option

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        Write-Verbose -Message 'Getting the max degree of parallelism Server Configuration Option'
        $currentMaxDop = $sql.Configuration.MaxDegreeOfParallelism.ConfigValue

        if ($currentMaxDop)
        {
             New-VerboseMessage -Message "MaxDop is $currentMaxDop"
        }
    }

    $returnValue = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer       = $SQLServer
        MaxDop          = $currentMaxDop
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function sets the max degree of parallelism Server Configuration Option

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database

    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the MAXDOP should be configured.

    .PARAMETER DynamicAlloc
    This is the boolean DynamicAlloc to configure automatically the MAXDOP configuration option

    .PARAMETER DynamicAlloc
    This is the numeric MaxDop to specify the value of the MAXDOP configuration option
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MaxDop = 0
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        Write-Verbose -Message 'Setting the max degree of parallelism Server Configuration Option'
        switch ($Ensure)
        {
            "Present"
            {
                if ($DynamicAlloc -eq $true)
                {
                    $MaxDop = Get-SqlDscDynamicMaxDop $sql
                }
            }
            
            "Absent"
            {
                $MaxDop = 0
            }
        }

        try
        {
            $sql.Configuration.MaxDegreeOfParallelism.ConfigValue = $MaxDop
            $sql.alter()
            New-VerboseMessage -Message "Set MaxDop to $MaxDop"
        }
        catch
        {
            New-VerboseMessage -Message "Failed setting MaxDop to $MaxDop"
        }
    }
}

<#
    .SYNOPSIS
    This function tests the max degree of parallelism Server Configuration Option

    .PARAMETER SQLServer
    This is a the SQL Server for the database

    .PARAMETER SQLInstanceName
    This is a the SQL instance for the database

    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the MAXDOP should be configured.

    .PARAMETER DynamicAlloc
    This is the boolean DynamicAlloc to configure automatically the MAXDOP configuration option

    .PARAMETER DynamicAlloc
    This is the numeric MaxDop to specify the value of the MAXDOP configuration option
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MaxDop = 0
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        Write-Verbose -Message 'Testing the max degree of parallelism Server Configuration Option'
        $currentMaxDop = $sql.Configuration.MaxDegreeOfParallelism.ConfigValue

        switch ($Ensure)
        {
            "Present"
            {
                if ($DynamicAlloc -eq $true)
                {
                    $MaxDop = Get-SqlDscDynamicMaxDop $sql
                    New-VerboseMessage -Message "Dynamic MaxDop is $MaxDop."
                }

                if ($currentMaxDop -eq $MaxDop)
                {
                    New-VerboseMessage -Message "Current MaxDop is at Requested value $MaxDop."
                    return $true
                }
                else 
                {
                    New-VerboseMessage -Message "Current MaxDop is $currentMaxDop should be updated to $MaxDop"
                    return $false
                }
            }

            "Absent"
            {
                if ($currentMaxDop -eq 0)
                {
                    New-VerboseMessage -Message "Current MaxDop is at Requested value 0."
                    return $true
                }
                else 
                {
                    New-VerboseMessage -Message "Current MaxDop is $currentMaxDop should be updated to 0"
                    return $false
                }
            }
        }
    }
}

Export-ModuleMember -Function *-TargetResource
