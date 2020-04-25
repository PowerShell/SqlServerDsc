$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SqlServerDsc.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SqlServerDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'DSC_SqlServerAudit'


<#
    .SYNOPSIS
        Returns the current state of the audit on a server.

    .PARAMETER Name
        Specifies the name of the server audit to be added or removed.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exists.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the audit exists.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    Write-Verbose -Message (
        $script:localizedData.RetrievingAuditInfo -f $Name, $ServerName
    )

    $returnValue = @{
        Ensure               = 'Absent'
        Name                 = $Name
        ServerName           = $ServerName
        InstanceName         = $InstanceName
        DestinationType      = $null
        FilePath             = $null
        Filter               = $null
        MaximumFiles         = $null
        MaximumFileSize      = $null
        MaximumFileSizeUnit  = $null
        MaximumRolloverFiles = $null
        OnFailure            = $null
        QueueDelay           = $null
        ReserveDiskSpace     = $null
        Enabled              = $false
    }

    # Check if database exists.
    $sqlServerAuditObject = $sqlServerObject.Audits[$Name]

    if ($sqlServerAuditObject)
    {
        Write-Verbose -Message (
            $script:localizedData.AuditExist -f $Name, $ServerName
        )

        $returnValue['Ensure'] = 'Present'
        $returnValue['DestinationType'] = $sqlServerAuditObject.DestinationType
        $returnValue['FilePath'] = $sqlServerAuditObject.FilePath
        $returnValue['MaximumFiles'] = $sqlServerAuditObject.MaximumFiles
        $returnValue['MaximumFileSize'] = $sqlServerAuditObject.MaximumFileSize
        $returnValue['MaximumFileSizeUnit'] = $sqlServerAuditObject.MaximumFileSizeUnit
        $returnValue['MaximumRolloverFiles'] = $sqlServerAuditObject.MaximumRolloverFiles
        $returnValue['ReserveDiskSpace'] = $sqlServerAuditObject.ReserveDiskSpace
        $returnValue['Filter'] = $sqlServerAuditObject.Filter
        $returnValue['OnFailure'] = $sqlServerAuditObject.OnFailure
        $returnValue['QueueDelay'] = $sqlServerAuditObject.QueueDelay
        $returnValue['Enabled'] = $sqlServerAuditObject.Enabled
    }

    return $returnValue
}

<#
    .SYNOPSIS
        sets the server audit in desired state.

    .PARAMETER Name
        Specifies the name of the audit to be tested.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance where the audit should be tested.

    .PARAMETER DestinationType
        Specifies the location where the audit should write to.
        This can be File, SecurityLog or ApplicationLog.

    .PARAMETER FilePath
        Specifies the location where te log files wil be placed.

    .PARAMETER MaximumFiles
        Specifies the number of files on disk.

    .PARAMETER MaximumFileSize
        Specifies the maximum file size in units by parameter MaximumFileSizeUnit.

    .PARAMETER MaximumFileSizeUnit
        Specifies the unit that is used for the file size. this can be KB, MB or GB.

    .PARAMETER MaximumRolloverFiles
        Specifies the amount of files on disk before SQL Server starts reusing
        the files.

    .PARAMETER OnFailure
        Specifies what should happen when writing events to the store fails.
        This can be CONTINUE, FAIL_OPERATION or SHUTDOWN.

    .PARAMETER QueueDelay
        Specifies the maximum delay before a event is writen to the store.
        When set to low this could impact server performance.
        When set to high events could be missing when a server crashes.

    .PARAMETER ReserveDiskSpace
        Specifies if the needed file space should be reserved. only needed
        when writing to a file log.

    .PARAMETER Enabled
        Specifies if the audit should be enabled. Defaults to $false.

    .PARAMETER Ensure
        Specifies if the server audit should be present or absent. If 'Present'
        then the audit will be added to the server and, if needed, the audit
        will be updated. If 'Absent' then the audit will be removed from
        the server. Defaults to 'Present'.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('File', 'SecurityLog', 'ApplicationLog')]
        [System.String]
        $DestinationType = 'SecurityLog',

        [Parameter()]
        [System.String]
        $FilePath,

        [Parameter()]
        [System.String]
        $Filter,

        [Parameter()]
        [System.UInt32]
        $MaximumFiles,

        [Parameter()]
        [System.UInt32]
        $MaximumFileSize = 10,

        [Parameter()]
        [ValidateSet('KB', 'MB', 'GB')]
        [System.String]
        $MaximumFileSizeUnit = 'MB',

        [Parameter()]
        [System.UInt32]
        $MaximumRolloverFiles,

        [Parameter()]
        [ValidateSet('CONTINUE', 'FAIL_OPERATION', 'SHUTDOWN')]
        [System.String]
        $OnFailure = 'CONTINUE',

        [Parameter()]
        [System.UInt32]
        $QueueDelay = 1000,

        [Parameter()]
        [System.Boolean]
        $ReserveDiskSpace = $false,

        [Parameter()]
        [System.Boolean]
        $Enabled = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $Force = $false
    )

    Write-Verbose -Message (
        $script:localizedData.SetAudit -f $Name, $ServerName, $InstanceName
    )

    #sanitize user input.
    if (($MaximumFiles) -and ($MaximumRolloverFiles))
    {
        $errorMessage = $script:localizedData.ImpossibleFileCombination
        New-InvalidOperationException -Message $errorMessage
    }
    if ($FilePath)
    {
        $FilePath = $FilePath.Trimend('\') + '\'

        #Test if audit file location exists, and create if it does not.
        if (-not (Test-Path -Path $FilePath))
        {
            Write-Verbose -Message (
                $script:localizedData.CreateFolder -f $FilePath.Trimend('\')
            )
            New-Item -ItemType directory -Path $FilePath.Trimend('\')
        }
    }

    #parameters for the TargetResource cmdlet.
    $getTargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Name         = $Name
    }

    # Get-TargetResource will also help us to test if the audit exist.
    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    # Default parameters for the cmdlet Invoke-Query used throughout.
    $invokeQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = 'MASTER'
    }

    $recreateAudit = $false

    if ($getTargetResourceResult.Ensure -eq $Ensure)
    {
        if ($Ensure -eq 'Present')
        {
            # Update Audit properties, if needed drop and recreate.
            if ($DestinationType -eq $getTargetResourceResult.DestinationType)
            {
                switch ($DestinationType)
                {
                    'File'
                    {
                        $strReserveDiskSpace = 'OFF'
                        if ($ReserveDiskSpace)
                        {
                            $strReserveDiskSpace = 'ON'
                        }

                        $strFiles = ''
                        if ($MaximumFiles)
                        {
                            $strFiles = 'MAX_FILES = {0},' -f $MaximumFiles
                        }
                        if ($MaximumRolloverFiles)
                        {
                            $strFiles = 'MAX_ROLLOVER_FILES = {0},' -f $MaximumRolloverFiles
                        }

                        $target = 'FILE (
                                FILEPATH = N''{0}'',
                                MAXSIZE = {1} {2},
                                {3}
                                RESERVE_DISK_SPACE = {4} )' -f
                        $FilePath,
                        $MaximumFileSize,
                        $MaximumFileSizeUnit,
                        $strFiles,
                        $strReserveDiskSpace
                    }

                    'SecurityLog'
                    {
                        $target = 'SECURITY_LOG'
                    }

                    'ApplicationLog'
                    {
                        $target = 'APPLICATION_LOG'
                    }
                }

                $withPart = 'QUEUE_DELAY = {0},
                             ON_FAILURE = {1}' -f
                $QueueDelay,
                $OnFailure

                $ServerAuditParameters = @{
                    ServerName   = $ServerName
                    InstanceName = $InstanceName
                    Name         = $Name
                    Action       = 'ALTER'
                    Target       = $target
                    WithPart     = $withPart
                }

                #if curent audit state is enabled, disable it before edit.
                if ($getTargetResourceResult.Enabled -eq $true)
                {
                    Disable-Audit -Name $Name -ServerName $ServerName -InstanceName $InstanceName
                }

                try
                {
                    Set-ServerAudit @ServerAuditParameters
                }
                catch
                {
                    $errorMessage = $script:localizedData.FailedUpdateAudit -f $Name, $ServerName, $InstanceName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
                #if audit state was disabled for edit, Re-enable it.
                if ($getTargetResourceResult.Enabled -eq $true)
                {
                    Enable-Audit -Name $Name -ServerName $ServerName -InstanceName $InstanceName
                }
            }
            else
            {
                <#
                        Current server audit has a diferent storage type, the
                        server audit needs to be re-created.
                    #>
                Write-Verbose -Message (
                    $script:localizedData.ChangingAuditDestinationType -f
                    $Name,
                    $getTargetResourceResult.DestinationType,
                    $DestinationType,
                    $ServerName,
                    $InstanceName
                )

                $recreateAudit = $true
            }

        }
    }

    # Throw if not opt-in to re-create database user.
    if ($recreateAudit -and -not $Force)
    {
        $errorMessage = $script:localizedData.ForceNotEnabled
        New-InvalidOperationException -Message $errorMessage
    }

    if (($Ensure -eq 'Absent' -and $getTargetResourceResult.Ensure -ne $Ensure) -or $recreateAudit)
    {
        # Drop the server audit.
        try
        {
            Write-Verbose -Message (
                $script:localizedData.DropAudit -f $Name, $serverName, $instanceName
            )

            #if curent audit state is enabled, disable it before removal.
            if ($getTargetResourceResult.Enabled -eq $true)
            {
                Disable-Audit -Name $Name -ServerName $ServerName -InstanceName $InstanceName
            }

            Invoke-Query @invokeQueryParameters -Query (
                'DROP SERVER AUDIT [{0}];' -f $Name
            )
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedDropAudit -f $Name, $ServerName, $InstanceName
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }

    <#
        This evaluation is made to handle creation and re-creation of a server
        audit to minimize the logic when the user has a different storage type, or
        when there are restrictions on altering an existing audit.
    #>
    if (($Ensure -eq 'Present' -and $getTargetResourceResult.Ensure -ne $Ensure) -or $recreateAudit)
    {
        # Create the audit.
        Write-Verbose -Message (
            $script:localizedData.CreateAudit -f $Name, $ServerName, $InstanceName
        )

        switch ($DestinationType)
        {
            'File'
            {
                $strReserveDiskSpace = 'OFF'
                if ($ReserveDiskSpace)
                {
                    $strReserveDiskSpace = 'ON'
                }

                $strFiles = ''
                if ($MaximumFiles)
                {
                    $strFiles = 'MAX_FILES = {0},' -f $MaximumFiles
                }
                if ($MaximumRolloverFiles)
                {
                    $strFiles = 'MAX_ROLLOVER_FILES = {0},' -f $MaximumRolloverFiles
                }

                $target = 'FILE (
                        FILEPATH = N''{0}'',
                        MAXSIZE = {1} {2},
                        {3}
                        RESERVE_DISK_SPACE = {4} )' -f
                $FilePath,
                $MaximumFileSize,
                $MaximumFileSizeUnit,
                $strFiles,
                $strReserveDiskSpace
            }

            'SecurityLog'
            {
                $target = 'SECURITY_LOG'
            }

            'ApplicationLog'
            {
                $target = 'APPLICATION_LOG'
            }
        }

        $withPart = 'QUEUE_DELAY = {0},
                    ON_FAILURE = {1}' -f
        $QueueDelay,
        $OnFailure

        $ServerAuditParameters = @{
            ServerName   = $ServerName
            InstanceName = $InstanceName
            Name         = $Name
            Action       = 'CREATE'
            Target       = $target
            WithPart     = $withPart
        }

        try
        {
            Set-ServerAudit @ServerAuditParameters
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedCreateAudit -f $Name, $ServerName, $InstanceName
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }

    if ($Ensure -eq 'Present' -and $getTargetResourceResult.Filter -ne $Filter)
    {
        try
        {
            Write-Verbose -Message (
                $script:localizedData.AddFilter -f $Filter, $Name, $serverName, $instanceName
            )

            #if curent audit state is enabled, disable it before setting filter.
            if ($getTargetResourceResult.Enabled -eq $true)
            {
                Disable-Audit -Name $Name -ServerName $ServerName -InstanceName $InstanceName
            }

            if ($null -ne $Filter -and $Filter -ne '')
            {
                Invoke-Query @invokeQueryParameters -Query (
                    'ALTER SERVER AUDIT [{0}] WHERE {1};' -f $Name, $Filter
                )
            }
            else
            {
                Invoke-Query @invokeQueryParameters -Query (
                    'ALTER SERVER AUDIT [{0}] REMOVE WHERE;' -f $Name
                )
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedAddFilter -f $Filter, $Name, $ServerName, $InstanceName
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }

    if ($Ensure -eq 'Present' -and $getTargetResourceResult.Enabled -ne $Enabled)
    {
        if ($Enabled -eq $true)
        {
            Enable-Audit -Name $Name -ServerName $ServerName -InstanceName $InstanceName
        }
        else
        {
            Disable-Audit -Name $Name -ServerName $ServerName -InstanceName $InstanceName
        }
    }
}

<#
    .SYNOPSIS
        Determines if the server audit is in desired state.

    .PARAMETER Name
        Specifies the name of the audit to be tested.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance where the audit should be tested.

    .PARAMETER DestinationType
        Specifies the location where the audit should write to.
        This can be File, SecurityLog or ApplicationLog.

    .PARAMETER FilePath
        Specifies the location where te log files wil be placed.

    .PARAMETER MaximumFiles
        Specifies the number of files on disk.

    .PARAMETER MaximumFileSize
        Specifies the maximum file size in units by parameter MaximumFileSizeUnit.

    .PARAMETER MaximumFileSizeUnit
        Specifies the unit that is used for the file size. this can be KB, MB or GB.

    .PARAMETER MaximumRolloverFiles
        Specifies the amount of files on disk before SQL Server starts reusing
        the files.

     .PARAMETER OnFailure
        Specifies what should happen when writing events to the store fails.
        This can be CONTINUE, FAIL_OPERATION or SHUTDOWN.

     .PARAMETER QueueDelay
        Specifies the maximum delay before a event is writen to the store.
        When set to low this could impact server performance.
        When set to high events could be missing when a server crashes.

     .PARAMETER ReserveDiskSpace
        Specifies if the needed file space should be reserved. only needed
        when writing to a file log.

     .PARAMETER Enabled
        Specifies if the audit should be enabled. Defaults to $false.

    .PARAMETER Ensure
        Specifies if the server audit should be present or absent. If 'Present'
        then the audit will be added to the server and, if needed, the audit
        will be updated. If 'Absent' then the audit will be removed from
        the server. Defaults to 'Present'.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('File', 'SecurityLog', 'ApplicationLog')]
        [System.String]
        $DestinationType = 'SecurityLog',

        [Parameter()]
        [System.String]
        $FilePath,

        [Parameter()]
        [System.String]
        $Filter,

        [Parameter()]
        [System.UInt32]
        $MaximumFiles = 10,

        [Parameter()]
        [System.UInt32]
        $MaximumFileSize = 10,

        [Parameter()]
        [ValidateSet('KB', 'MB', 'GB')]
        [System.String]
        $MaximumFileSizeUnit = 'MB',

        [Parameter()]
        [System.UInt32]
        $MaximumRolloverFiles = '10',

        [Parameter()]
        [ValidateSet('CONTINUE', 'FAIL_OPERATION', 'SHUTDOWN')]
        [System.String]
        $OnFailure = 'CONTINUE',

        [Parameter()]
        [System.UInt32]
        $QueueDelay = 1000,

        [Parameter()]
        [System.Boolean]
        $ReserveDiskSpace = $false,

        [Parameter()]
        [System.Boolean]
        $Enabled = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $Force = $false
    )

    Write-Verbose -Message (
        $script:localizedData.EvaluateAudit -f $Name, $ServerName, $InstanceName
    )

    #sanitize user input.
    if ($FilePath)
    {
        $FilePath = $FilePath.Trimend('\') + '\'
        $PSBoundParameters['FilePath'] = $FilePath.Trimend('\') + '\'
    }

    $TargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Name         = $Name
    }

    # Get-TargetResource will also help us to test if the audit exist.
    $getTargetResourceResult = Get-TargetResource @TargetResourceParameters

    if ($getTargetResourceResult.Ensure -eq $Ensure)
    {
        if ($Ensure -eq 'Present')
        {
            <#
                Make sure default values are part of desired values if the user did
                not specify them in the configuration.
            #>
            $desiredValues = @{ } + $PSBoundParameters
            $desiredValues['Ensure'] = $Ensure

            $testTargetResourceReturnValue = Test-DscParameterState -CurrentValues $getTargetResourceResult `
                -DesiredValues $desiredValues `
                -ValuesToCheck @(
                'FilePath'
                'MaximumFileSize'
                'MaximumFileSizeUnit'
                'QueueDelay'
                'OnFailure'
                'Enabled'
                'Ensure'
                'DestinationType'
                'MaximumFiles'
                'MaximumRolloverFiles'
                'ReserveDiskSpace'
                'Filter'
            )
            <#
                WORKAROUND for possible bug?
                Test-DscParameterState does not see if a parameter is removed as parameter
                but still exists in the DSC resource.

                When in desired state do some aditional tests.
                When not in desired state, aditional testing is not needed.
            #>
            if ($testTargetResourceReturnValue)
            {
                if ($getTargetResourceResult.Filter -ne $Filter)
                {
                    $testTargetResourceReturnValue = $false
                }
            }
        }
        else
        {
            $testTargetResourceReturnValue = $true
        }
    }
    else
    {
        $testTargetResourceReturnValue = $false
    }

    if ($testTargetResourceReturnValue)
    {
        Write-Verbose -Message $script:localizedData.InDesiredState
    }
    else
    {
        Write-Verbose -Message $script:localizedData.NotInDesiredState
    }

    return $testTargetResourceReturnValue
}

<#
    .SYNOPSIS
        Disables a server audit.

    .PARAMETER Name
        Specifies the name of the server audit to be disabled.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the audit exist.
#>
function Disable-Audit
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $invokeQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = 'MASTER'
    }

    Invoke-Query @invokeQueryParameters -Query (
        'ALTER SERVER AUDIT [{0}] WITH (STATE = OFF);' -f $Name
    )
}

<#
    .SYNOPSIS
        Enables a server audit.

    .PARAMETER Name
        Specifies the name of the server audit to enabled.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the audit exist.
#>
function Enable-Audit
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $invokeQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = 'MASTER'
    }

    Invoke-Query @invokeQueryParameters -Query (
        'ALTER SERVER AUDIT [{0}] WITH (STATE = ON);' -f $Name
    )
}

<#
    .SYNOPSIS
        Creates an server audit. Alters if already exists.

    .PARAMETER Name
        Specifies the name of the server audit to be added or removed.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the database exist.

    .PARAMETER Action
        Specifies if the audit should be created or altered.

    .PARAMETER Target
        Specifies if the target is the securityLog, the applicationLog or a File Log.
        When a File log it also should contain al the file information.

    .PARAMETER WithPart
        Specifies what should go in the WITH part of the audit query.
#>
function Set-ServerAudit
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('CREATE', 'ALTER')]
        [System.String]
        $Action,

        [Parameter()]
        [System.String]
        $Target,

        [Parameter()]
        [System.String]
        $WithPart
    )

    $invokeQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = 'MASTER'
    }

    Invoke-Query @invokeQueryParameters -Query (
        '{0} SERVER AUDIT [{1}] TO {2}
        WITH (
            {3}
        );' -f
        $Action,
        $Name,
        $Target,
        $WithPart
    )
}

Export-ModuleMember -Function *-TargetResource
