Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1') -Force

<#
    .SYNOPSIS
    This function gets the value of the min and max memory server configuration option.

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
        $SQLInstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Getting the value for minimum and maximum SQL server memory.'
        $minMemory = $sqlServerObject.Configuration.MinServerMemory.ConfigValue
        $maxMemory = $sqlServerObject.Configuration.MaxServerMemory.ConfigValue
    }

    $returnValue = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer       = $SQLServer
        MinMemory       = $minMemory
        MaxMemory       = $maxMemory
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function sets the value for the min and max memory server configuration option.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
    
    .PARAMETER Ensure
    When set to 'Present' then min and max memory will be set to either the value in parameter MinMemory and MaxMemory or dynamically configured when parameter DynamicAlloc is set to $true.
    When set to 'Absent' min and max memory will be set to default values.

    .PARAMETER DynamicAlloc
    If set to $true then max memory will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxMemory must be set to $null or not be configured.

    .PARAMETER MinMemory
    This is the minimum amount of memory, in MB, in the buffer pool used by the instance of SQL Server.

    .PARAMETER MaxMemory
    This is the maximum amount of memory, in MB, in the buffer pool used by the instance of SQL Server.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $DynamicAlloc = $false,

        [Parameter()]
        [System.Int32]
        $MinMemory,
        
        [Parameter()]
        [System.Int32]
        $MaxMemory
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Setting the minimum and maximum memory used by the instance.'
        switch ($Ensure)
        {
            'Present'
            {
                if ($DynamicAlloc)
                {
                    if ($MaxMemory)
                    {
                        throw New-TerminatingError -ErrorType 'MaxMemoryParamMustBeNull' `
                                                   -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                                   -ErrorCategory InvalidArgument  
                    }

                    $MaxMemory = Get-SqlDscDynamicMaxMemory
                    New-VerboseMessage -Message "Dynamic MaxMemory is $MaxMemory."
                }
                else
                {
                    if (-not $MaxMemory)
                    {
                        throw New-TerminatingError -ErrorType 'MaxMemoryParamMustNotBeNull' `
                                                   -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                                   -ErrorCategory InvalidArgument  
                    }
                }
            }
            
            'Absent'
            {
                $MaxMemory = 2147483647
                $MinMemory = 0
                New-VerboseMessage -Message ('Ensure is set to absent. so minimum and maximum server memory') + `
                                            ('values used by the instance are reset to the default values.')
            }
        }

        try
        {
            $sqlServerObject.Configuration.MaxServerMemory.ConfigValue = $MaxMemory
            $sqlServerObject.Configuration.MinServerMemory.ConfigValue = $MinMemory
            $sqlServerObject.Alter()
            New-VerboseMessage -Message "SQL Server Memory has been capped to $MaxMemory. Minimum server memory set to $MinMemory."
        }
        catch
        {
            throw New-TerminatingError -ErrorType 'ServerMemorySetError' `
                                       -FormatArgs @($SQLServer,$SQLInstanceName) `
                                       -ErrorCategory InvalidOperation `
                                       -InnerException $_.Exception
        }
    }
}

<#
    .SYNOPSIS
    This function tests the value for the min and max memory server configuration option.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
    
    .PARAMETER Ensure
    When set to 'Present' then min and max memory will be set to either the value in parameter MinMemory and MaxMemory or dynamically configured when parameter DynamicAlloc is set to $true.
    When set to 'Absent' min and max memory will be set to default values.

    .PARAMETER DynamicAlloc
    If set to $true then max memory will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxMemory must be set to $null or not be configured.

    .PARAMETER MinMemory
    This is the minimum amount of memory, in MB, in the buffer pool used by the instance of SQL Server.

    .PARAMETER MaxMemory
    This is the maximum amount of memory, in MB, in the buffer pool used by the instance of SQL Server.
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
        $SQLInstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $DynamicAlloc = $false,

        [Parameter()]
        [System.Int32]
        $MinMemory,

        [Parameter()]
        [System.Int32]
        $MaxMemory
    )

    Write-Verbose -Message 'Testing the min and max of memory server configuration option'  

    $getTargetResourceParameters = @{
        SQLInstanceName = $PSBoundParameters.SQLInstanceName
        SQLServer       = $PSBoundParameters.SQLServer
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    
    $currentMinMemory = $getTargetResourceResult.MinMemory
    $currentMaxMemory = $getTargetResourceResult.MaxMemory
    $isServerMemoryInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($currentMaxMemory -ne 2147483647)
            {
                New-VerboseMessage -Message "Current maximum server memory is $currentMaxMemory. Expected 2147483647"
                $isServerMemoryInDesiredState = $false
            }

            if ($currentMinMemory -ne 0)
            {
                New-VerboseMessage -Message "Current minimum server memory is $currentMinMemory. Expected 0"
                $isServerMemoryInDesiredState = $false
            }
        }

        'Present'
        {
            if ($DynamicAlloc)
            {
                if ($MaxMemory)
                {
                    throw New-TerminatingError -ErrorType 'MaxMemoryParamMustBeNull' `
                                               -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                               -ErrorCategory InvalidArgument  
                }

                $MaxMemory = Get-SqlDscDynamicMaxMemory
                New-VerboseMessage -Message "Dynamic MaxMemory is $MaxMemory."
            }

            if ($MaxMemory -ne $currentMaxMemory)
            {
                New-VerboseMessage -Message "Current maximum server memory is $currentMaxMemory, expected $MaxMemory"
                $isServerMemoryInDesiredState = $false
            }

            if ($MinMemory -ne $currentMinMemory)
            {
                New-VerboseMessage -Message "Current minimum server memory is $currentMinMemory, expected $MinMemory"
                $isServerMemoryInDesiredState = $false
            }
        }
    }

    return $isServerMemoryInDesiredState
}

<#
    .SYNOPSIS
    This cmdlet is used to return the Dynamic MaxMemory of a SQL Instance
#>
function Get-SqlDscDynamicMaxMemory
{
    try
    {
        $physicalMemory = ((Get-CimInstance -ClassName Win32_PhysicalMemory).Capacity | Measure-Object -Sum).Sum
        $physicalMemoryMB = [Math]::round($physicalMemory / 1MB)
        
        # Find how much to save for OS: 20% of total ram for under 15GB / 12.5% for over 20GB
        if ($physicalMemoryMB -ge 20480)
        {
            $osMemReserved = [Math]::round((0.125 * $physicalMemoryMB))
        }
        else
        {
            $osMemReserved = [Math]::round((0.2 * $physicalMemoryMB))
        }

        $cimInstanceProc = Get-CimInstance -ClassName Win32_Processor
        $numCores = (Measure-Object -InputObject $cimInstanceProc -Property NumberOfCores -Sum).Sum

        # Find Number of SQL Threads = 256 + (NumofProcesors - 4) * 8
        if ($numCores -ge 4)
        {
            $numOfSQLThreads = 256 + ($numCores - 4) * 8
        }
        else
        {
            $numOfSQLThreads = 0
        }

        $osArchitecture = (Get-CimInstance -ClassName Win32_operatingsystem).OSArchitecture
        
        # Find ThreadStackSize 1MB x86/ 2MB x64/ 4MB IA64
        if ($osArchitecture -eq '32-bit')
        {
            $ThreadStackSize = 1
        }
        elseif ($osArchitecture -eq '64-bit')
        {
            $ThreadStackSize = 2
        }
        else
        {
            $ThreadStackSize = 4
        }

        $maxMemory = $physicalMemoryMB - $osMemReserved - ($numOfSQLThreads * $ThreadStackSize) - (1024 * [System.Math]::Ceiling($numCores / 4))
    }
    catch
    {
        throw New-TerminatingError -ErrorType 'ErrorGetDynamicMaxMemory' `
                                   -ErrorCategory InvalidOperation `
                                   -InnerException $_.Exception
    }

    $maxMemory
}

Export-ModuleMember -Function *-TargetResource
