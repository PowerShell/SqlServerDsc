Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force
<#
    .SYNOPSIS
    This function gets the max degree of parallelism server configuration option.

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
        $SQLServer = $env:COMPUTERNAME
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Getting the max degree of parallelism server configuration option'
        $currentMaxDop = $sqlServerObject.Configuration.MaxDegreeOfParallelism.ConfigValue
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
    This function sets the max degree of parallelism server configuration option.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Ensure
    When set to 'Present' then max degree of parallelism will be set to either the value in parameter MaxDop or dynamically configured when parameter DynamicAlloc is set to $true. 
    When set to 'Absent' max degree of parallelism will be set to 0 which means no limit in number of processors used in parallel plan execution.

    .PARAMETER DynamicAlloc
    If set to $true then max degree of parallelism will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxDop must be set to $null or not be configured.

    .PARAMETER MaxDop
    A numeric value to limit the number of processors used in parallel plan execution.
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
        $SQLServer = $env:COMPUTERNAME,

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc,

        [System.Int32]
        $MaxDop
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Setting the max degree of parallelism server configuration option'
        switch ($Ensure)
        {
            'Present'
            {
                if ($DynamicAlloc)
                {
                    if ($MaxDop)
                    {
                        throw New-TerminatingError -ErrorType MaxDopParamMustBeNull `
                                                   -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                                   -ErrorCategory InvalidArgument  
                    }

                    $targetMaxDop = Get-SqlDscDynamicMaxDop -SqlServerObject $sqlServerObject
                    New-VerboseMessage -Message "Dynamic MaxDop is $targetMaxDop."
                }
                else
                {
                    $targetMaxDop = $MaxDop
                }
            }
            
            'Absent'
            {
                $targetMaxDop = 0
                New-VerboseMessage -Message 'Desired state should be absent - MAXDOP is reset to the default value.'
            }
        }

        try
        {
            $sqlServerObject.Configuration.MaxDegreeOfParallelism.ConfigValue = $targetMaxDop
            $sqlServerObject.Alter()
            New-VerboseMessage -Message "Setting MAXDOP value to $targetMaxDop."
        }
        catch
        {
            throw New-TerminatingError -ErrorType MaxDopSetError `
                                       -FormatArgs @($SQLServer,$SQLInstanceName,$targetMaxDop) `
                                       -ErrorCategory InvalidOperation `
                                       -InnerException $_.Exception
        }
    }
}

<#
    .SYNOPSIS
    This function tests the max degree of parallelism server configuration option.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Ensure
    When set to 'Present' then max degree of parallelism will be set to either the value in parameter MaxDop or dynamically configured when parameter DynamicAlloc is set to $true. 
    When set to 'Absent' max degree of parallelism will be set to 0 which means no limit in number of processors used in parallel plan execution.

    .PARAMETER DynamicAlloc
    If set to $true then max degree of parallelism will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxDop must be set to $null or not be configured.

    .PARAMETER MaxDop
    A numeric value to limit the number of processors used in parallel plan execution.
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
        $SQLServer = $env:COMPUTERNAME,

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc,

        [System.Int32]
        $MaxDop
    )

    Write-Verbose -Message 'Testing the max degree of parallelism server configuration option'
     
    $parameters = @{
        SQLInstanceName = $PSBoundParameters.SQLInstanceName
        SQLServer       = $PSBoundParameters.SQLServer
    }
    
    $currentValues = Get-TargetResource @parameters    
    $getMaxDop = $currentValues.MaxDop
    $isMaxDopInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getMaxDop -ne 0)
            {
                New-VerboseMessage -Message "Current MaxDop is $getMaxDop should be updated to 0"
                $isMaxDopInDesiredState = $false
            }
        }
        'Present'
        {
            if ($DynamicAlloc)
            {
                if ($MaxDop)
                {
                    throw New-TerminatingError -ErrorType MaxDopParamMustBeNull `
                                            -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                            -ErrorCategory InvalidArgument  
                }

                $dynamicMaxDop = Get-SqlDscDynamicMaxDop
                New-VerboseMessage -Message "Dynamic MaxDop is $dynamicMaxDop."

                if ($getMaxDop -ne $dynamicMaxDop)
                {
                    New-VerboseMessage -Message "Current MaxDop is $getMaxDop should be updated to $dynamicMaxDop"
                    $isMaxDopInDesiredState = $false
                }
            }
            else 
            {
                if ($getMaxDop -ne $MaxDop)
                {
                    New-VerboseMessage -Message "Current MaxDop is $getMaxDop should be updated to $MaxDop"
                    $isMaxDopInDesiredState = $false
                }
            }
        }
    }

    $isMaxDopInDesiredState 
}

Export-ModuleMember -Function *-TargetResource
