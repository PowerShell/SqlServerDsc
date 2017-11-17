Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
    This function gets the max degree of parallelism server configuration option.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
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
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    # Is this node actively hosting the SQL instance?
    $isActiveNode = Test-ActiveNode -ServerObject $sqlServerObject

    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Getting the max degree of parallelism server configuration option'
        $currentMaxDop = $sqlServerObject.Configuration.MaxDegreeOfParallelism.ConfigValue
    }

    $returnValue = @{
        InstanceName = $InstanceName
        ServerName   = $ServerName
        MaxDop       = $currentMaxDop
        IsActiveNode = $isActiveNode
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function sets the max degree of parallelism server configuration option.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Ensure
    When set to 'Present' then max degree of parallelism will be set to either the value in parameter MaxDop or dynamically configured when parameter DynamicAlloc is set to $true.
    When set to 'Absent' max degree of parallelism will be set to 0 which means no limit in number of processors used in parallel plan execution.

    .PARAMETER DynamicAlloc
    If set to $true then max degree of parallelism will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxDop must be set to $null or not be configured.

    .PARAMETER MaxDop
    A numeric value to limit the number of processors used in parallel plan execution.

    .PARAMETER ProcessOnlyOnActiveNode
    Specifies that the resource will only determine if a change is needed if the target node is the active host of the SQL Server Instance.
    Not used in Set-TargetResource.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $DynamicAlloc,

        [Parameter()]
        [System.Int32]
        $MaxDop,

        [Parameter()]
        [System.Boolean]
        $ProcessOnlyOnActiveNode
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

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
                            -FormatArgs @( $ServerName, $InstanceName ) `
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
                -FormatArgs @($ServerName, $InstanceName, $targetMaxDop) `
                -ErrorCategory InvalidOperation `
                -InnerException $_.Exception
        }
    }
}

<#
    .SYNOPSIS
    This function tests the max degree of parallelism server configuration option.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Ensure
    When set to 'Present' then max degree of parallelism will be set to either the value in parameter MaxDop or dynamically configured when parameter DynamicAlloc is set to $true.
    When set to 'Absent' max degree of parallelism will be set to 0 which means no limit in number of processors used in parallel plan execution.

    .PARAMETER DynamicAlloc
    If set to $true then max degree of parallelism will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxDop must be set to $null or not be configured.

    .PARAMETER MaxDop
    A numeric value to limit the number of processors used in parallel plan execution.

    .PARAMETER ProcessOnlyOnActiveNode
    Specifies that the resource will only determine if a change is needed if the target node is the active host of the SQL Server Instance.
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
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $DynamicAlloc,

        [Parameter()]
        [System.Int32]
        $MaxDop,

        [Parameter()]
        [System.Boolean]
        $ProcessOnlyOnActiveNode
    )

    Write-Verbose -Message 'Testing the max degree of parallelism server configuration option'

    $parameters = @{
        InstanceName = $InstanceName
        ServerName   = $ServerName
    }

    $currentValues = Get-TargetResource @parameters

    $getMaxDop = $currentValues.MaxDop
    $isMaxDopInDesiredState = $true

    <#
        If this is supposed to process only the active node, and this is not the
        active node, don't bother evaluating the test.
    #>
    if ( $ProcessOnlyOnActiveNode -and -not $getTargetResourceResult.IsActiveNode )
    {
        New-VerboseMessage -Message ( 'The node "{0}" is not actively hosting the instance "{1}". Exiting the test.' -f $env:COMPUTERNAME, $InstanceName )
        return $isMaxDopInDesiredState
    }

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
                        -FormatArgs @( $ServerName, $InstanceName ) `
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

<#
    .SYNOPSIS
    This cmdlet is used to return the dynamic max degree of parallelism
#>
function Get-SqlDscDynamicMaxDop
{
    $cimInstanceProc = Get-CimInstance -ClassName Win32_Processor

    # init variables
    $numProcs = 0
    $numCores = 0

    # Loop through returned objects
    foreach ($processor in $cimInstanceProc)
    {
        # increment number of processors
        $numProcs += $processor.NumberOfLogicalProcessors

        # increment number of cores
        $numCores += $processor.NumberOfCores
    }


    if ($numProcs -eq 1)
    {
        $dynamicMaxDop = [Math]::Round($numCores / 2, [System.MidpointRounding]::AwayFromZero)
    }
    elseif ($numCores -ge 8)
    {
        $dynamicMaxDop = 8
    }
    else
    {
        $dynamicMaxDop = $numCores
    }

    $dynamicMaxDop
}

Export-ModuleMember -Function *-TargetResource
