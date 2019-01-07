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
    Specifies if the SQL Agent Operator should be present or absent. Default is Present

    .PARAMETER Name
    The name of the SQL Agent Operator.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER EmailAddress
    The email address to be used for the SQL Agent Operator.
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
        $Name,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $EmailAddress
    )

    $returnValue = @{
        Name         = $null
        Ensure       = 'Absent'
        ServerName   = $ServerName
        InstanceName = $InstanceName
        EmailAddress = $null
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.GetSqlAgents
        )
        # Check operator exists
        $sqlOperatorObject = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Name}
        if ($sqlOperatorObject)
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAgentPresent `
                    -f $Name
            )
            $returnValue['Ensure'] = 'Present'
            $returnValue['Name'] = $sqlOperatorObject.Name
            $returnValue['EmailAddress'] = $sqlOperatorObject.EmailAddress
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAgentAbsent `
                    -f $Name
            )
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType ConnectServerFailed `
            -FormatArgs @($ServerName, $InstanceName) `
            -ErrorCategory ConnectionError
    }

    return $returnValue
}

<#
    .SYNOPSIS
    This function sets the SQL Agent Operator.

    .PARAMETER Ensure
    Specifies if the SQL Agent Operator should be present or absent. Default is Present

    .PARAMETER Name
    The name of the SQL Agent Operator.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER EmailAddress
    The email address to be used for the SQL Agent Operator.
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

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $EmailAddress
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        switch ($Ensure)
        {
            'Present'
            {
                $sqlOperatorObject = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Name}

                if ($sqlOperatorObject)
                {
                    if ($PSBoundParameters.ContainsKey('EmailAddress'))
                    {
                        try
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdateEmailAddress `
                                    -f $Name, $EmailAddress
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
                            if ($PSBoundParameters.ContainsKey('EmailAddress'))
                            {
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
    else
    {
        throw New-TerminatingError -ErrorType ConnectServerFailed `
            -FormatArgs @($ServerName, $InstanceName) `
            -ErrorCategory ConnectionError
    }
}

<#
    .SYNOPSIS
    This function tests the SQL Agent Operator.

    .PARAMETER Ensure
    Specifies if the SQL Agent Operator should be present or absent. Default is Present

    .PARAMETER Name
    The name of the SQL Agent Operator.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER EmailAddress
    The email address to be used for the SQL Agent Operator.
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

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $EmailAddress
    )

    Write-Verbose -Message (
        $script:localizedData.TestSqlAgentOperator `
            -f $Name
    )

    $getTargetResourceParameters = @{
        Name           = $Name
        ServerName     = $ServerName
        InstanceName   = $InstanceName
        EmailAddress   = $EmailAddress
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
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
            if ($getTargetResourceResult.EmailAddress -ne $EmailAddress -and $PSBoundParameters.ContainsKey('EmailAddress'))
            {
                New-VerboseMessage -Message (
                    $script:localizedData.SqlAgentOperatorExistsButEmailWrong `
                        -f $name, $getTargetResourceResult.EmailAddress, $EmailAddress
                )
                $isOperatorInDesiredState = $false
            }
            elseif ($getTargetResourceResult.Ensure -ne 'Present')
            {
                New-VerboseMessage -Message (
                    $script:localizedData.SqlAgentOperatorDoesNotExistButShould `
                        -f $name
                )
                $isOperatorInDesiredState = $false
            }
        }
    }
    $isOperatorInDesiredState
}

Export-ModuleMember -Function *-TargetResource
