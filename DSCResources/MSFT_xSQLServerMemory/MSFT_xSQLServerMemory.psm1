Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1') -Force

<#
    .SYNOPSIS
    This function gets the min and max memory of server configuration option.

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
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Getting the min and max of memory server configuration option'
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
    This function sets the min and max memory of server configuration option.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
    
    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the min and max memory should be configured.

    .PARAMETER DynamicAlloc
    If set to $true then max memory will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxMemory and MinMemory must be set to $null or not be configured.

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
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MinMemory,

        [System.Int32]
        $MaxMemory
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Setting the min and max of memory server configuration option'
        switch ($Ensure)
        {
            'Present'
            {
                if ($DynamicAlloc)
                {
                    if ($MinMemory -and $MaxMemory)
                    {
                        throw New-TerminatingError -ErrorType 'MinMaxMemoryParamMustBeNull' `
                                                   -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                                   -ErrorCategory InvalidArgument  
                    }

                    $MaxMemory = Get-SqlDscDynamicMaxMemory
                    $MinMemory = 128
                    New-VerboseMessage -Message "Dynamic MaxMemory is $MaxMemory."
                }
                else
                {
                    if (-not $MaxMemory)
                    {
                        throw New-TerminatingError -ErrorType 'MaxMemoryParamMustBeNotNull' `
                                                   -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                                   -ErrorCategory InvalidArgument  
                    }
                }
            }
            
            'Absent'
            {
                $MaxMemory = 2147483647
                $MinMemory = 0
                New-VerboseMessage -Message 'Ensure is absent - Min and Max Memory reset to default value'
            }
        }

        try
        {
            $sqlServerObject.Configuration.MaxServerMemory.ConfigValue = $MaxMemory
            $sqlServerObject.Configuration.MinServerMemory.ConfigValue = $MinMemory
            $sqlServerObject.Alter()
            New-VerboseMessage -Message "SQL Server Memory has been capped to $MaxMemory. MinMemory set to $MinMemory."
        }
        catch
        {
            throw New-TerminatingError -ErrorType ServerMemorySetError `
                                       -FormatArgs @($SQLServer,$SQLInstanceName) `
                                       -ErrorCategory InvalidOperation `
                                       -InnerException $_.Exception
        }
    }
}

<#
    .SYNOPSIS
    This function tests the min and max memory of server configuration option.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.
    
    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the min and max memory should be configured.

    .PARAMETER DynamicAlloc
    If set to $true then max memory will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxMemory and MinMemory must be set to $null or not be configured.

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
        $MinMemory,

        [System.Int32]
        $MaxMemory
    )

    Write-Verbose -Message 'Testing the max degree of parallelism server configuration option'  
    $currentValues = Get-TargetResource @PSBoundParameters
    $getMinMemory = $currentValues.MinMemory
    $getMaxMemory = $currentValues.MaxMemory
    $isServerMemoryInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getMaxMemory -ne 2147483647)
            {
                New-VerboseMessage -Message "Current Max Memory is $getMaxMemory. Expected 2147483647"
                $isServerMemoryInDesiredState = $false
            }

            if ($getMinMemory -ne 0)
            {
                New-VerboseMessage -Message "Current Min Memory is $getMinMemory. Expected 0"
                $isServerMemoryInDesiredState = $false
            }
        }

        'Present'
        {
            if ($DynamicAlloc)
            {
                if ($MinMemory -and $MaxMemory)
                {
                    throw New-TerminatingError -ErrorType 'MinMaxMemoryParamMustBeNull' `
                                               -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                               -ErrorCategory InvalidArgument  
                }

                $MaxMemory = Get-SqlDscDynamicMaxMemory
                $MinMemory = 128
            }

            if ($MaxMemory -ne $getMaxMemory)
            {
                New-VerboseMessage -Message "Current Max Memory is $getMaxMemory, expected $MaxMemory"
                $isServerMemoryInDesiredState = $false
            }

            if ($MinMemory -ne $getMinMemory)
            {
                New-VerboseMessage -Message "Current Min Memory is $getMinMemory, expected $MinMemory"
                $isServerMemoryInDesiredState = $false
            }
        }
    }

    return $isServerMemoryInDesiredState
}

Export-ModuleMember -Function *-TargetResource
