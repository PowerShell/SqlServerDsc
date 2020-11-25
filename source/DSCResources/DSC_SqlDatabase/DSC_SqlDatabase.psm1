$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

$script:supportedCompatibilityLevels = @{
    8  = @('Version80')
    9  = @('Version80', 'Version90')
    10 = @('Version80', 'Version90', 'Version100')
    11 = @('Version90', 'Version100', 'Version110')
    12 = @('Version100', 'Version110', 'Version120')
    13 = @('Version100', 'Version110', 'Version120', 'Version130')
    14 = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140')
    15 = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150')
}

<#
    .SYNOPSIS
        This function gets the sql database.

    .PARAMETER Ensure
        When set to 'Present', the database will be created.
        When set to 'Absent', the database will be dropped.

    .PARAMETER Name
      The name of database to be created or dropped.

    .PARAMETER ServerName
       The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
       The name of the SQL instance to be configured.

    .PARAMETER Collation
        The name of the SQL collation to use for the new database.
        Default value is server collation.
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
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.GetDatabase -f $Name, $InstanceName
    )

    $returnValue = @{
        Name               = $Name
        Ensure             = 'Absent'
        ServerName         = $ServerName
        InstanceName       = $InstanceName
        Collation          = $null
        CompatibilityLevel = $null
        RecoveryModel      = $null
        OwnerName          = $null
        SnapshotIsolation  = $null
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        # Check database exists
        $sqlDatabaseObject = $sqlServerObject.Databases[$Name]

        if ($sqlDatabaseObject)
        {
            $returnValue['Ensure'] = 'Present'
            $returnValue['Collation'] = $sqlDatabaseObject.Collation
            $returnValue['CompatibilityLevel'] = $sqlDatabaseObject.CompatibilityLevel
            $returnValue['RecoveryModel'] = $sqlDatabaseObject.RecoveryModel
            $returnValue['OwnerName'] = $sqlDatabaseObject.Owner
            $returnValue['SnapshotIsolation'] = $sqlDatabaseObject.SnapshotIsolationState -eq 'Enabled'

            Write-Verbose -Message (
                $script:localizedData.DatabasePresent -f $Name
            )
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.DatabaseAbsent -f $Name
            )
        }
    }

    return $returnValue
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
       The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
       The name of the SQL instance to be configured.

    .PARAMETER Collation
        The name of the SQL collation to use for the new database.
        Default value is server collation.

    .PARAMETER CompatibilityLevel
        The version of the SQL compatibility level to use for the new database.
        Default value is server version.

    .PARAMETER RecoveryModel
        The recovery model to be used for the new database.
        Default value is Full.

    .PARAMETER OwnerName
        Specifies the name of the login that should be the owner of the database.

    .PARAMETER SnapshotIsolation
        Specifics whether snapshot isolation should be enabled for the new database.
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
        $Collation,

        [Parameter()]
        [ValidateSet('Version80', 'Version90', 'Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150')]
        [System.String]
        $CompatibilityLevel,

        [Parameter()]
        [ValidateSet('Simple', 'Full', 'BulkLogged')]
        [System.String]
        $RecoveryModel,

        [Parameter()]
        [System.String]
        $OwnerName,

        [Parameter()]
        [System.Boolean]
        $SnapshotIsolation
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
        {
            # Verify that a correct compatibility level is specified.
            if ($CompatibilityLevel -notin $supportedCompatibilityLevels.$($sqlServerObject.VersionMajor))
            {
                $errorMessage = $script:localizedData.InvalidCompatibilityLevel -f $CompatibilityLevel, $InstanceName

                New-ObjectNotFoundException -Message $errorMessage
            }
        }

        if ($PSBoundParameters.ContainsKey('Collation'))
        {
            # Verify that the correct collation is used.
            if ($Collation -notin $sqlServerObject.EnumCollations().Name)
            {
                $errorMessage = $script:localizedData.InvalidCollation -f $Collation, $InstanceName

                New-ObjectNotFoundException -Message $errorMessage
            }
        }

        if ($Ensure -eq 'Present')
        {
            $sqlDatabaseObject = $sqlServerObject.Databases[$Name]

            if ($sqlDatabaseObject)
            {
                Write-Verbose -Message (
                    $script:localizedData.SetDatabase -f $Name, $InstanceName
                )

                $wasUpdate = $false

                if ($PSBoundParameters.ContainsKey('Collation'))
                {
                    Write-Verbose -Message (
                        $script:localizedData.UpdatingCollation -f $Collation
                    )

                    $sqlDatabaseObject.Collation = $Collation

                    $wasUpdate = $true
                }

                if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
                {
                    Write-Verbose -Message (
                        $script:localizedData.UpdatingCompatibilityLevel -f $CompatibilityLevel
                    )

                    $sqlDatabaseObject.CompatibilityLevel = $CompatibilityLevel

                    $wasUpdate = $true
                }

                if ($PSBoundParameters.ContainsKey('RecoveryModel'))
                {
                    Write-Verbose -Message (
                        $script:localizedData.UpdatingRecoveryModel -f $RecoveryModel
                    )

                    $sqlDatabaseObject.RecoveryModel = $RecoveryModel

                    $wasUpdate = $true
                }

                if ($PSBoundParameters.ContainsKey('OwnerName'))
                {
                    Write-Verbose -Message (
                        $script:localizedData.UpdatingOwner -f $OwnerName
                    )

                    try
                    {
                        $sqlDatabaseObject.SetOwner($OwnerName)
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.FailedToUpdateOwner -f $OwnerName, $Name

                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }

                    $wasUpdate = $true
                }

                if ($PSBoundParameters.ContainsKey('SnapshotIsolation'))
                {
                    Write-Verbose -Message (
                        $script:localizedData.UpdatingSnapshotIsolation -f $SnapshotIsolation
                    )

                    try
                    {
                        $sqlDatabaseObject.SetSnapshotIsolation($SnapshotIsolation)
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.FailedToUpdateSnapshotIsolation -f $SnapshotIsolation, $Name

                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }

                try
                {
                    if ($wasUpdate)
                    {
                        $sqlDatabaseObject.Alter()
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.FailedToUpdateDatabase -f $Name

                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
            else
            {
                try
                {
                    $sqlDatabaseObjectToCreate = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList $sqlServerObject, $Name

                    if ($sqlDatabaseObjectToCreate)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.CreateDatabase -f $Name
                        )

                        if ($PSBoundParameters.ContainsKey('RecoveryModel'))
                        {
                            $sqlDatabaseObjectToCreate.RecoveryModel = $RecoveryModel
                        }

                        if ($PSBoundParameters.ContainsKey('Collation'))
                        {
                            $sqlDatabaseObjectToCreate.Collation = $Collation
                        }

                        if ($PSBoundParameters.ContainsKey('CompatibilityLevel'))
                        {
                            $sqlDatabaseObjectToCreate.CompatibilityLevel = $CompatibilityLevel
                        }

                        $sqlDatabaseObjectToCreate.Create()

                        <#
                            This must be run after the object is created because
                            the owner property is read-only and the method cannot
                            be call until the object has been created.
                        #>
                        if ($PSBoundParameters.ContainsKey('OwnerName'))
                        {
                            $sqlDatabaseObjectToCreate.SetOwner($OwnerName)
                        }
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.FailedToCreateDatabase -f $Name

                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
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
                    Write-Verbose -Message (
                        $script:localizedData.DropDatabase -f $Name
                    )

                    $sqlDatabaseObjectToDrop.Drop()
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.FailedToDropDatabase -f $Name

                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
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
       The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER Collation
        The name of the SQL collation to use for the new database.
        Default value is server collation.

    .PARAMETER CompatibilityLevel
        The version of the SQL compatibility level to use for the new database.
        Default value is server version.

    .PARAMETER RecoveryModel
        The recovery model to be used for the new database.
        Default value is Full.

    .PARAMETER OwnerName
        Specifies the name of the login that should be the owner of the database.
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
        $Collation,

        [Parameter()]
        [ValidateSet('Version80', 'Version90', 'Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150')]
        [System.String]
        $CompatibilityLevel,

        [Parameter()]
        [ValidateSet('Simple', 'Full', 'BulkLogged')]
        [System.String]
        $RecoveryModel,

        [Parameter()]
        [System.String]
        $OwnerName,

        [Parameter()]
        [System.Boolean]
        $SnapshotIsolation
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration -f $Name, $InstanceName
    )

    $getTargetResourceParameters = @{
        Name         = $Name
        ServerName   = $ServerName
        InstanceName = $InstanceName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $isDatabaseInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                Write-Verbose -Message (
                    $script:localizedData.NotInDesiredStateAbsent -f $Name
                )

                $isDatabaseInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                Write-Verbose -Message (
                    $script:localizedData.NotInDesiredStatePresent -f $Name
                )

                $isDatabaseInDesiredState = $false
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('Collation') -and $getTargetResourceResult.Collation -ne $Collation)
                {
                    Write-Verbose -Message (
                        $script:localizedData.CollationWrong -f $Name, $getTargetResourceResult.Collation, $Collation
                    )

                    $isDatabaseInDesiredState = $false
                }

                if ($PSBoundParameters.ContainsKey('CompatibilityLevel') -and $getTargetResourceResult.CompatibilityLevel -ne $CompatibilityLevel)
                {
                    Write-Verbose -Message (
                        $script:localizedData.CompatibilityLevelWrong -f $Name, $getTargetResourceResult.CompatibilityLevel, $CompatibilityLevel
                    )

                    $isDatabaseInDesiredState = $false
                }

                if ($PSBoundParameters.ContainsKey('RecoveryModel') -and $getTargetResourceResult.RecoveryModel -ne $RecoveryModel)
                {
                    Write-Verbose -Message (
                        $script:localizedData.RecoveryModelWrong -f $Name, $getTargetResourceResult.RecoveryModel, $RecoveryModel
                    )

                    $isDatabaseInDesiredState = $false
                }

                if ($PSBoundParameters.ContainsKey('OwnerName') -and $getTargetResourceResult.OwnerName -ne $OwnerName)
                {
                    Write-Verbose -Message (
                        $script:localizedData.OwnerNameWrong -f $Name, $getTargetResourceResult.OwnerName, $OwnerName
                    )

                    $isDatabaseInDesiredState = $false
                }

                if ($PSBoundParameters.ContainsKey('SnapshotIsolation') -and $getTargetResourceResult.SnapshotIsolation -ne $SnapshotIsolation)
                {
                    Write-Verbose -Message (
                        $script:localizedData.SnapshotIsolationWrong -f $Name, $getTargetResourceResult.SnapshotIsolation, $SnapshotIsolation
                    )

                    $isDatabaseInDesiredState = $false
                }
            }
        }
    }

    return $isDatabaseInDesiredState
}

Export-ModuleMember -Function *-TargetResource
