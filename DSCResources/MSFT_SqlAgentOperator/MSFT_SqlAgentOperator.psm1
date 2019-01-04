Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
    -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlAgentOperator'

<#
    .SYNOPSIS
    This function gets the SQL Agent Operator.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of the SQL Agent operator to configure.

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
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $EmailAddress
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.GetSqlAgents
        )
        # Check operator exists
        $sqlOperatorObject = $($sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Name})
        if ($sqlOperatorObject)
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAgentPresent `
                    -f $Name
            )
            $Ensure = 'Present'
            $SqlOperatorEmail = $sqlOperatorObject.EmailAddress
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAgentAbsent `
                    -f $Name
            )
            $Ensure = 'Absent'
            $SqlOperatorEmail = $EmailAddress
        }
    }

    $returnValue = @{
        Name         = $Name
        Ensure       = $Ensure
        ServerName   = $ServerName
        InstanceName = $InstanceName
        EmailAddress = $SqlOperatorEmail
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function sets the SQL Agent Operator.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of the SQL Agent operator to configure.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $EmailAddress
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        switch ($Ensure)
        {
            'Present'
            {
                $sqlOperatorObject = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Name}

                if ($sqlOperatorObject)
                {
                    if ($PSBoundParameters.ContainsKey('EmailAddress')) {
                        try
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdatingSqlAgentOperator `
                                    -f $Name
                            )
                            $sqlOperatorObject.EmailAddress = $EmailAddress
                            $sqlOperatorObject.Alter()
                        }
                        catch
                        {
                            throw New-TerminatingError -ErrorType UpdateOperatorSetError `
                                -FormatArgs @($ServerName, $InstanceName, $Name, $EmailAddress) `
                                -ErrorCategory InvalidOperation `
                                -InnerException $_.Exception
                        }
                    }
                }
                else
                {
                    try
                    {
                        $sqlOperatorObjectToCreate = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.Operator -ArgumentList $sqlServerObject.JobServer, $Name

                        if ($sqlOperatorObjectToCreate)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.AddSqlAgentOperator `
                                    -f $Name
                            )
                            if ($PSBoundParameters.ContainsKey('EmailAddress')) {
                                Write-Verbose -Message (
                                    $script:localizedData.UpdateEmailAddress `
                                        -f $EmailAddress, $Name
                                )
                                $sqlOperatorObjectToCreate.EmailAddress = $EmailAddress
                            }
                            $sqlOperatorObjectToCreate.Create()
                        }
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType CreateOperatorSetError `
                            -FormatArgs @($Name, $ServerName, $InstanceName) `
                            -ErrorCategory InvalidOperation `
                            -InnerException $_.Exception
                    }
                }
            }

            'Absent'
            {
                try
                {
                    $sqlOperatorObjectToDrop = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Name}
                    if ($sqlOperatorObjectToDrop)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DeleteSqlAgentOperator `
                                -f $Name
                        )
                        $sqlOperatorObjectToDrop.Drop()
                    }
                }
                catch
                {
                    throw New-TerminatingError -ErrorType DropOperatorSetError `
                        -FormatArgs @($Name, $ServerName, $InstanceName) `
                        -ErrorCategory InvalidOperation `
                        -InnerException $_.Exception
                }
            }
        }
    }
}

<#
    .SYNOPSIS
    This function tests the SQL Agent Operator.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of the SQL Agent operator to configure.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $EmailAddress
    )

    Write-Verbose -Message (
        $script:localizedData.TestSqlAgentOperator `
            -f $Name
    )

    $getTargetResourceResult = Get-TargetResource @PSBoundParameters
    $isOperatorInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                New-VerboseMessage -Message (
                    $script:localizedData.SqlAgentOperatorExistsButShouldNot `
                        -f $name
                )
                $isOperatorInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                New-VerboseMessage -Message (
                    $script:localizedData.SqlAgentOperatorDoesNotExistButShould `
                        -f $name
                )
                $isOperatorInDesiredState = $false
            }
            elseif ($getTargetResourceResult.EmailAddress -ne $EmailAddress -and $PSBoundParameters.ContainsKey('EmailAddress'))
            {
                New-VerboseMessage -Message (
                    $script:localizedData.SqlAgentOperatorExistsButEmailWrong `
                        -f $name
                )
                $isOperatorInDesiredState = $false
            }
        }
    }
    $isOperatorInDesiredState
}

Export-ModuleMember -Function *-TargetResource
