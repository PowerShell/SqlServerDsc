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

    .PARAMETER Ensure
    This is The Ensure Set to 'present' to specificy that the MAXDOP should be configured.

    .PARAMETER DynamicAlloc
    This is the boolean DynamicAlloc to configure automatically the MAXDOP configuration option

    .PARAMETER DynamicAlloc
    This is the numeric MaxDop to specify the value of the MAXDOP configuration option
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

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        Write-Verbose -Message 'Getting the max degree of parallelism Server Configuration Option'
        $currentMaxDop = $sql.Configuration.MaxDegreeOfParallelism.ConfigValue

        if ($DynamicAlloc)
        {
            if ($MaxDop)
            {
                Write-Warning -Message 'MaxDop paramater must be null if DynamicAlloc set to true'
                throw New-TerminatingError -ErrorType ParameterConflict `
                                           -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                           -ErrorCategory InvalidArgument  
            }

            $dynamicMaxDop = Get-SqlDscDynamicMaxDop -SqlServerObject $sql
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

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MaxDop
    )

    $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($sql)
    {
        Write-Verbose -Message 'Setting the max degree of parallelism Server Configuration Option'
        switch ($Ensure)
        {
            "Present"
            {
                if ($DynamicAlloc)
                {
                    if ($MaxDop)
                    {
                        Write-Warning -Message 'MaxDop paramater must be null if DynamicAlloc set to true'
                        throw New-TerminatingError -ErrorType ParameterConflict `
                                                   -FormatArgs @( $SQLServer,$SQLInstanceName ) `
                                                   -ErrorCategory InvalidArgument  
                    }

                    $targetMaxDop = Get-SqlDscDynamicMaxDop -SqlServerObject $sql
                    New-VerboseMessage -Message "Dynamic MaxDop is $targetMaxDop."
                }
                else
                {
                    $targetMaxDop = $MaxDop
                }
            }
            
            "Absent"
            {
                $targetMaxDop = 0
                New-VerboseMessage -Message 'Ensure is absent - MAXDOP reset to default value'
            }
        }

        try
        {
            $sql.Configuration.MaxDegreeOfParallelism.ConfigValue = $targetMaxDop
            $sql.Alter()
            New-VerboseMessage -Message "Set MaxDop to $targetMaxDop"
        }
        catch
        {
            throw New-TerminatingError -ErrorType MaxDopGetError `
                                       -FormatArgs @($SQLServer,$SQLInstanceName,$targetMaxDop) `
                                       -ErrorCategory InvalidOperation `
                                       -InnerException $_.Exception
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

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MaxDop
    )

    Write-Verbose -Message 'Testing the max degree of parallelism Server Configuration Option'
     
    $currentValues = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.Ensure = $Ensure
    return Test-SQLDscParameterState -CurrentValues $CurrentValues `
                                     -DesiredValues $PSBoundParameters `
                                     -ValuesToCheck @('Ensure')
}

Export-ModuleMember -Function *-TargetResource
