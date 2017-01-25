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

    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the MAXDOP should be configured.

    .PARAMETER DynamicAlloc
    If set to $true then max degree of parallelism will be dynamically configured.
    When this is set parameter is set to $true, the parameter MaxDop must be set to $null or not be configured.

    .PARAMETER MaxDop
    A numeric value to limit the number of processors used in parallel plan execution.
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
        $SQLServer,

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MaxDop
    )

    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Getting the max degree of parallelism server configuration option'
        $currentMaxDop = $sqlServerObject.Configuration.MaxDegreeOfParallelism.ConfigValue

        if ($DynamicAlloc)
        {
            if ($MaxDop)
            {
                throw New-TerminatingError -ErrorType 'MaxDopParamMustBeNull' `
                                           -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                           -ErrorCategory InvalidArgument  
            }

            $dynamicMaxDop = Get-SqlDscDynamicMaxDop -SqlServerObject $sqlServerObject
            New-VerboseMessage -Message "Dynamic MaxDop is $dynamicMaxDop."

            if ($currentMaxDop -eq $dynamicMaxDop)
            {
                New-VerboseMessage -Message "Current MaxDop is at Requested value $dynamicMaxDop."
                $currentEnsure = 'Present'
            }
            else 
            {
                New-VerboseMessage -Message "Current MaxDop is $currentMaxDop should be updated to $dynamicMaxDop"
                $currentEnsure = 'Absent'
            }
        }
        else 
        {
            if ($currentMaxDop -eq $MaxDop)
            {
                New-VerboseMessage -Message "Current MaxDop is at Requested value $MaxDop."
                $currentEnsure = 'Present'
            }
            else 
            {
                New-VerboseMessage -Message "Current MaxDop is $currentMaxDop should be updated to $MaxDop"
                $currentEnsure = 'Absent'
            }
        }
    }
    else
    {
        $currentEnsure = 'Absent'
    }

    $returnValue = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer       = $SQLServer
        Ensure          = $currentEnsure
        DynamicAlloc    = $DynamicAlloc
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
    This is The Ensure Set to 'present' to specificy that the MAXDOP should be configured.

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
        $SQLServer,

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

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
                        throw New-TerminatingError -ErrorType 'MaxDopParamMustBeNull' `
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
                New-VerboseMessage -Message 'Ensure is absent - MAXDOP reset to default value'
            }
        }

        try
        {
            $sqlServerObject.Configuration.MaxDegreeOfParallelism.ConfigValue = $targetMaxDop
            $sqlServerObject.Alter()
            New-VerboseMessage -Message "Set MaxDop to $targetMaxDop"
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
    This is The Ensure Set to 'present' to specificy that the MAXDOP should be configured.

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
        $SQLServer,

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MaxDop
    )

    Write-Verbose -Message 'Testing the max degree of parallelism server configuration option'
     
    $currentValues = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.Ensure = $Ensure
    return Test-SQLDscParameterState -CurrentValues $CurrentValues `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @('Ensure')
}

Export-ModuleMember -Function *-TargetResource
