Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
    This function gets the sql database.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of database to be created or dropped.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Collation
    The name of the SQL collation to use for the new database.
    Defaults to server collation.
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
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Collation
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        $sqlDatabaseCollation = $sqlServerObject.Collation
        Write-Verbose -Message 'Getting SQL Databases'
        # Check database exists
        $sqlDatabaseObject = $sqlServerObject.Databases[$Name]

        if ($sqlDatabaseObject)
        {
            Write-Verbose -Message "SQL Database name $Name is present"
            $Ensure = 'Present'
            $sqlDatabaseCollation = $sqlDatabaseObject.Collation
        }
        else
        {
            Write-Verbose -Message "SQL Database name $Name is absent"
            $Ensure = 'Absent'
        }
    }

    $returnValue = @{
        Name         = $Name
        Ensure       = $Ensure
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Collation    = $sqlDatabaseCollation
    }

    $returnValue
}

<#
    .SYNOPSIS
    This function create or delete a database in the SQL Server instance provided.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of database to be created or dropped.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Collation
    The name of the SQL collation to use for the new database.
    Defaults to server collation.
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
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Collation
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        if ($Ensure -eq 'Present')
        {
            if (-not $PSBoundParameters.ContainsKey('Collation'))
            {
                $Collation = $sqlServerObject.Collation
            }
            elseif ($Collation -notin $sqlServerObject.EnumCollations().Name)
            {
                throw New-TerminatingError -ErrorType InvalidCollationError `
                    -FormatArgs @($ServerName, $InstanceName, $Name, $Collation) `
                    -ErrorCategory InvalidOperation
            }

            $sqlDatabaseObject = $sqlServerObject.Databases[$Name]

            if ($sqlDatabaseObject)
            {
                try
                {
                    Write-Verbose -Message "Updating the database $Name with specified settings."
                    $sqlDatabaseObject.Collation = $Collation
                    $sqlDatabaseObject.Alter()
                    New-VerboseMessage -Message "Updated Database $Name."
                }
                catch
                {
                    throw New-TerminatingError -ErrorType UpdateDatabaseSetError `
                        -FormatArgs @($ServerName, $InstanceName, $Name) `
                        -ErrorCategory InvalidOperation `
                        -InnerException $_.Exception
                }
            }
            else
            {
                try
                {
                    $sqlDatabaseObjectToCreate = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $sqlServerObject, $Name
                    if ($sqlDatabaseObjectToCreate)
                    {
                        Write-Verbose -Message "Adding to SQL the database $Name."
                        $sqlDatabaseObjectToCreate.Collation = $Collation
                        $sqlDatabaseObjectToCreate.Create()
                        New-VerboseMessage -Message "Created Database $Name."
                    }
                }
                catch
                {
                    throw New-TerminatingError -ErrorType CreateDatabaseSetError `
                        -FormatArgs @($ServerName, $InstanceName, $Name) `
                        -ErrorCategory InvalidOperation `
                        -InnerException $_.Exception
                }
            }
        }
        else
        {
            try
            {
                $sqlDatabaseObjectToDrop = $sqlServerObject.Databases[$Name]
                if ($sqlDatabaseObjectToDrop)
                {
                    Write-Verbose -Message "Deleting to SQL the database $Name."
                    $sqlDatabaseObjectToDrop.Drop()
                    New-VerboseMessage -Message "Dropped Database $Name."
                }
            }
            catch
            {
                throw New-TerminatingError -ErrorType DropDatabaseSetError `
                    -FormatArgs @($ServerName, $InstanceName, $Name) `
                    -ErrorCategory InvalidOperation `
                    -InnerException $_.Exception
            }
        }
    }
}

<#
    .SYNOPSIS
    This function tests if the sql database is already created or dropped.

    .PARAMETER Ensure
    When set to 'Present', the database will be created.
    When set to 'Absent', the database will be dropped.

    .PARAMETER Name
    The name of database to be created or dropped.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER Collation
    The name of the SQL collation to use for the new database.
    Defaults to server collation.
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
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Collation
    )

    Write-Verbose -Message "Checking if database named $Name is present or absent"

    $getTargetResourceResult = Get-TargetResource @PSBoundParameters
    $isDatabaseInDesiredState = $true

    if (-not $PSBoundParameters.ContainsKey('Collation'))
    {
        $Collation = $getTargetResourceResult.Collation
    }

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                New-VerboseMessage -Message "Ensure is set to Absent. The database $Name should be dropped"
                $isDatabaseInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                New-VerboseMessage -Message "Ensure is set to Present. The database $Name should be created"
                $isDatabaseInDesiredState = $false
            }
            elseif ($getTargetResourceResult.Collation -ne $Collation)
            {
                New-VerboseMessage -Message 'Database exist but has the wrong collation.'
                $isDatabaseInDesiredState = $false
            }
        }
    }

    $isDatabaseInDesiredState
}

Export-ModuleMember -Function *-TargetResource
