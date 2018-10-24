Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
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
        Write-Verbose -Message 'Getting SQL Agent Operators'
        # Check operator exists
        $sqlOperatorObject = $($sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Name})
        if ($sqlOperatorObject)
        {
            Write-Verbose -Message "SQL Agent Operator $Name is present"
            $Ensure = 'Present'
            $SqlOperatorEmail = $sqlOperatorObject.EmailAddress
        }
        else
        {
            Write-Verbose -Message "SQL Database name $Name is absent"
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
                $sqlOperatorObject = $sqlServerObject.JobServer.Operators[$Name]

                if ($sqlOperatorObject)
                {
                    if ($PSBoundParameters.ContainsKey('EmailAddress')) {
                        try
                        {
                            Write-Verbose -Message "Updating SQL Agent Operator $Name with specified settings."
                            $sqlOperatorObject.EmailAddress = $EmailAddress
                            $sqlOperatorObject.Alter()
                            New-VerboseMessage -Message "Updated SQL Agent Operator $Name."
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
                            write-host "trying to create $name"
                            Write-Verbose -Message "Adding SQL Agent Operator $Name."
                            if ($PSBoundParameters.ContainsKey('EmailAddress')) {
                                Write-Verbose -Message "Setting email address to $EmailAddress"
                                $sqlOperatorObjectToCreate.EmailAddress = $EmailAddress
                            }
                            New-VerboseMessage -Message "Created SQL Agent Operator $Name."
                            $sqlOperatorObjectToCreate.Create()
                        }
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType CreateOperatorSetError `
                            -FormatArgs @($ServerName, $InstanceName, $Name) `
                            -ErrorCategory InvalidOperation `
                            -InnerException $_.Exception
                    }
                }
            }

            'Absent'
            {
                try
                {
                    $sqlOperatorObjectToDrop = $sqlServerObject.JobServer.Operators[$Name]
                    if ($sqlOperatorObjectToDrop)
                    {
                        Write-Verbose -Message "Deleting SQL Agent Operator $Name."
                        $sqlOperatorObjectToDrop.Drop()
                        New-VerboseMessage -Message "Dropped SQL Agent Operator $Name."
                    }
                }
                catch
                {
                    throw New-TerminatingError -ErrorType DropOperatorSetError `
                        -FormatArgs @($ServerName, $InstanceName, $Name) `
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

    Write-Verbose -Message "Checking if SQL Agent Operator $Name is present of absent"

    $getTargetResourceResult = Get-TargetResource @PSBoundParameters
    $isOperatorInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                New-VerboseMessage -Message "Ensure is set to Absent. The SQL Agent Operator $Name should be dropped"
                $isOperatorInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                New-VerboseMessage -Message "Ensure is set to Present. The SQL Agent Operator $Name should be created"
                $isOperatorInDesiredState = $false
            }
            elseif ($getTargetResourceResult.EmailAddress -ne $EmailAddress -and $PSBoundParameters.ContainsKey('EmailAddress'))
            {
                New-VerboseMessage -Message "SQL Agent Operator $Name exists but has the wrong email address"
                $isOperatorInDesiredState = $false
            }
        }
    }
    $isOperatorInDesiredState
}

Export-ModuleMember -Function *-TargetResource
