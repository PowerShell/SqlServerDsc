$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SqlServerDsc.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SqlServerDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'DSC_SqlServerAuditSpecification'

<#
    .SYNOPSIS
        Returns the current state of the server audit specification.

    .PARAMETER Name
        Specifies the name of the server audit specification to be added or removed.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the server audit specification exist.

    .NOTES
        DO NOT CHANGE THE CAPITALS IN THE PARAMETERS! These are used to find the
        places to insert an underscore, see function Get-DatabaseObjectNameFromPSParamName
        for more information.
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

    Write-Verbose -Message (
        $script:localizedData.RetrievingAuditSpecificationInformation -f
        $Name,
        $ServerName,
        $InstanceName
    )

    $returnValue = @{
        Ensure                                = 'Absent'
        Name                                  = $Name
        ServerName                            = $ServerName
        InstanceName                          = $InstanceName
        AuditName                             = ''
        ApplicationRoleChangePasswordGroup    = $false
        AuditChangeGroup                      = $false
        BackupRestoreGroup                    = $false
        BrokerLoginGroup                      = $false
        DatabaseChangeGroup                   = $false
        DatabaseLogoutGroup                   = $false
        DatabaseMirroringLoginGroup           = $false
        DatabaseObjectAccessGroup             = $false
        DatabaseObjectChangeGroup             = $false
        DatabaseObjectOwnershipChangeGroup    = $false
        DatabaseObjectPermissionChangeGroup   = $false
        DatabaseOperationGroup                = $false
        DatabaseOwnershipChangeGroup          = $false
        DatabasePermissionChangeGroup         = $false
        DatabasePrincipalChangeGroup          = $false
        DatabasePrincipalImpersonationGroup   = $false
        DatabaseRoleMemberChangeGroup         = $false
        DbccGroup                             = $false
        FailedDatabaseAuthenticationGroup     = $false
        FailedLoginGroup                      = $false
        FulltextGroup                         = $false
        LoginChangePasswordGroup              = $false
        LogoutGroup                           = $false
        SchemaObjectAccessGroup               = $false
        SchemaObjectChangeGroup               = $false
        SchemaObjectOwnershipChangeGroup      = $false
        SchemaObjectPermissionChangeGroup     = $false
        ServerObjectChangeGroup               = $false
        ServerObjectOwnershipChangeGroup      = $false
        ServerObjectPermissionChangeGroup     = $false
        ServerOperationGroup                  = $false
        ServerPermissionChangeGroup           = $false
        ServerPrincipalChangeGroup            = $false
        ServerPrincipalImpersonationGroup     = $false
        ServerRoleMemberChangeGroup           = $false
        ServerStateChangeGroup                = $false
        SuccessfulDatabaseAuthenticationGroup = $false
        SuccessfulLoginGroup                  = $false
        TraceChangeGroup                      = $false
        UserChangePasswordGroup               = $false
        UserDefinedAuditGroup                 = $false
        TransactionGroup                      = $false
        Enabled                               = $false
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    # Default parameters for the cmdlet Invoke-Query used throughout.
    $invokeQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = 'MASTER'
    }

    $DataSetAudit = Invoke-Query @invokeQueryParameters -WithResults -Query (
        'Select
            s.server_specification_id,
            s.is_state_enabled,
            a.name as auditName
        FROM sys.server_audits AS a
        JOIN sys.server_audit_specifications AS s
            ON a.audit_guid = s.audit_guid
        where s.name = ''{0}''' -f
        $Name)

    if ($null -ne $DataSetAudit -and $DataSetAudit.Tables[0].Rows.Count -gt 0)
    {
        Write-Verbose -Message (
            $script:localizedData.AuditSpecificationExist -f $Name, $ServerName, $InstanceName
        )

        $dataSetRow = $DataSetAudit.Tables[0].Rows[0]

        $DataSetAuditSpecification = Invoke-Query @invokeQueryParameters -WithResults -Query (
            'Select audit_action_name
                from sys.server_audit_specification_details
                where server_specification_id = {0}' -f
            $dataSetRow.server_specification_id)

        #this should always happen!!!!!
        if ($null -ne $DataSetAuditSpecification -and $DataSetAuditSpecification.Tables.Count -gt 0)
        {
            $resultSet = Convert-ToHashTable -DataTable $DataSetAuditSpecification.Tables[0]

            $returnValue['Ensure'] = 'Present'
            $returnValue['AuditName'] = $dataSetRow.auditName
            $returnValue['ApplicationRoleChangePasswordGroup'] = $resultSet['APPLICATION_ROLE_CHANGE_PASSWORD_GROUP']
            $returnValue['AuditChangeGroup'] = $resultSet['AUDIT_CHANGE_GROUP']
            $returnValue['BackupRestoreGroup'] = $resultSet['BACKUP_RESTORE_GROUP']
            $returnValue['BrokerLoginGroup'] = $resultSet['BROKER_LOGIN_GROUP']
            $returnValue['DatabaseChangeGroup'] = $resultSet['DATABASE_CHANGE_GROUP']
            $returnValue['DatabaseLogoutGroup'] = $resultSet['DATABASE_LOGOUT_GROUP']
            $returnValue['DatabaseMirroringLoginGroup'] = $resultSet['DATABASE_MIRRORING_LOGIN_GROUP']
            $returnValue['DatabaseObjectAccessGroup'] = $resultSet['DATABASE_OBJECT_ACCESS_GROUP']
            $returnValue['DatabaseObjectChangeGroup'] = $resultSet['DATABASE_OBJECT_CHANGE_GROUP']
            $returnValue['DatabaseObjectOwnershipChangeGroup'] = $resultSet['DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP']
            $returnValue['DatabaseObjectPermissionChangeGroup'] = $resultSet['DATABASE_OBJECT_PERMISSION_CHANGE_GROUP']
            $returnValue['DatabaseOperationGroup'] = $resultSet['DATABASE_OPERATION_GROUP']
            $returnValue['DatabaseOwnershipChangeGroup'] = $resultSet['DATABASE_OWNERSHIP_CHANGE_GROUP']
            $returnValue['DatabasePermissionChangeGroup'] = $resultSet['DATABASE_PERMISSION_CHANGE_GROUP']
            $returnValue['DatabasePrincipalChangeGroup'] = $resultSet['DATABASE_PRINCIPAL_CHANGE_GROUP']
            $returnValue['DatabasePrincipalImpersonationGroup'] = $resultSet['DATABASE_PRINCIPAL_IMPERSONATION_GROUP']
            $returnValue['DatabaseRoleMemberChangeGroup'] = $resultSet['DATABASE_ROLE_MEMBER_CHANGE_GROUP']
            $returnValue['DbccGroup'] = $resultSet['DBCC_GROUP']
            $returnValue['FailedDatabaseAuthenticationGroup'] = $resultSet['FAILED_DATABASE_AUTHENTICATION_GROUP']
            $returnValue['FailedLoginGroup'] = $resultSet['FAILED_LOGIN_GROUP']
            $returnValue['FulltextGroup'] = $resultSet['FULLTEXT_GROUP']
            $returnValue['LoginChangePasswordGroup'] = $resultSet['LOGIN_CHANGE_PASSWORD_GROUP']
            $returnValue['LogoutGroup'] = $resultSet['LOGOUT_GROUP']
            $returnValue['SchemaObjectAccessGroup'] = $resultSet['SCHEMA_OBJECT_ACCESS_GROUP']
            $returnValue['SchemaObjectChangeGroup'] = $resultSet['SCHEMA_OBJECT_CHANGE_GROUP']
            $returnValue['SchemaObjectOwnershipChangeGroup'] = $resultSet['SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP']
            $returnValue['SchemaObjectPermissionChangeGroup'] = $resultSet['SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP']
            $returnValue['ServerObjectChangeGroup'] = $resultSet['SERVER_OBJECT_CHANGE_GROUP']
            $returnValue['ServerObjectOwnershipChangeGroup'] = $resultSet['SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP']
            $returnValue['ServerObjectPermissionChangeGroup'] = $resultSet['SERVER_OBJECT_PERMISSION_CHANGE_GROUP']
            $returnValue['ServerOperationGroup'] = $resultSet['SERVER_OPERATION_GROUP']
            $returnValue['ServerPermissionChangeGroup'] = $resultSet['SERVER_PERMISSION_CHANGE_GROUP']
            $returnValue['ServerPrincipalChangeGroup'] = $resultSet['SERVER_PRINCIPAL_CHANGE_GROUP']
            $returnValue['ServerPrincipalImpersonationGroup'] = $resultSet['SERVER_PRINCIPAL_IMPERSONATION_GROUP']
            $returnValue['ServerRoleMemberChangeGroup'] = $resultSet['SERVER_ROLE_MEMBER_CHANGE_GROUP']
            $returnValue['ServerStateChangeGroup'] = $resultSet['SERVER_STATE_CHANGE_GROUP']
            $returnValue['SuccessfulDatabaseAuthenticationGroup'] = $resultSet['SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP']
            $returnValue['SuccessfulLoginGroup'] = $resultSet['SUCCESSFUL_LOGIN_GROUP']
            $returnValue['TraceChangeGroup'] = $resultSet['TRACE_CHANGE_GROUP']
            $returnValue['UserChangePasswordGroup'] = $resultSet['USER_CHANGE_PASSWORD_GROUP']
            $returnValue['UserDefinedAuditGroup'] = $resultSet['USER_DEFINED_AUDIT_GROUP']
            $returnValue['TransactionGroup'] = $resultSet['TRANSACTION_GROUP']
            $returnValue['Enabled'] = $dataSetRow.is_state_enabled
        }
    }
    return $returnValue
}

<#
    .SYNOPSIS
        Creates, removes or updates a server audit specification to it's desired state.

    .PARAMETER Name
        Specifies the name of the server audit specification to be added or removed.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the server audit specification exist.

    .PARAMETER Ensure
        Specifies if the server audit specification should be present or absent.
        If 'Present' then the server audit specification will be added to the instance
        and, if needed, the server audit specification will be updated. If 'Absent'
        then the server audit specification will be removed from the instance.
        Defaults to 'Present'.

    .PARAMETER AuditName
        Specifies the audit that should be used to store the server audit specification
        events.

    .PARAMETER Enabled
        Specifies if the server audit specification should be enabled or disabled.

    .PARAMETER ApplicationRoleChangePasswordGroup
        Specifies if this audit specification should be on or off

    .PARAMETER AuditChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER BackupRestoreGroup
        Specifies if this audit specification should be on or off

    .PARAMETER BrokerLoginGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseLogoutGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseMirroringLoginGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseObjectAccessGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseObjectChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseObjectOwnershipChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseObjectPermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseOperationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseOwnershipChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabasePermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabasePrincipalChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabasePrincipalImpersonationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseRoleMemberChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DbccGroup
        Specifies if this audit specification should be on or off

    .PARAMETER FailedDatabaseAuthenticationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER FailedLoginGroup
        Specifies if this audit specification should be on or off

    .PARAMETER FulltextGroup
        Specifies if this audit specification should be on or off

    .PARAMETER LoginChangePasswordGroup
        Specifies if this audit specification should be on or off

    .PARAMETER LogoutGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SchemaObjectAccessGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SchemaObjectChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SchemaObjectOwnershipChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SchemaObjectPermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerObjectChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerObjectOwnershipChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerObjectPermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerOperationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerPermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerPrincipalChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerPrincipalImpersonationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerRoleMemberChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerStateChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SuccessfulDatabaseAuthenticationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SuccessfulLoginGroup
        Specifies if this audit specification should be on or off

    .PARAMETER TraceChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER UserChangePasswordGroup
        Specifies if this audit specification should be on or off

    .PARAMETER UserDefinedAuditGroup
        Specifies if this audit specification should be on or off

    .PARAMETER TransactionGroup
        Specifies if this audit specification should be on or off
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
        [System.String]
        $AuditName,

        [Parameter()]
        [System.Boolean]
        $ApplicationRoleChangePasswordGroup = $false,

        [Parameter()]
        [System.Boolean]
        $AuditChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $BackupRestoreGroup = $false,

        [Parameter()]
        [System.Boolean]
        $BrokerLoginGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseLogoutGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseMirroringLoginGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseObjectAccessGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseObjectChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseObjectOwnershipChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseObjectPermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseOperationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseOwnershipChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabasePermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabasePrincipalChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabasePrincipalImpersonationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseRoleMemberChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DbccGroup = $false,

        [Parameter()]
        [System.Boolean]
        $FailedDatabaseAuthenticationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $FailedLoginGroup = $false,

        [Parameter()]
        [System.Boolean]
        $FulltextGroup = $false,

        [Parameter()]
        [System.Boolean]
        $LoginChangePasswordGroup = $false,

        [Parameter()]
        [System.Boolean]
        $LogoutGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SchemaObjectAccessGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SchemaObjectChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SchemaObjectOwnershipChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SchemaObjectPermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerObjectChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerObjectOwnershipChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerObjectPermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerOperationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerPermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerPrincipalChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerPrincipalImpersonationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerRoleMemberChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerStateChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SuccessfulDatabaseAuthenticationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SuccessfulLoginGroup = $false,

        [Parameter()]
        [System.Boolean]
        $TraceChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $UserChangePasswordGroup = $false,

        [Parameter()]
        [System.Boolean]
        $UserDefinedAuditGroup = $false,

        [Parameter()]
        [System.Boolean]
        $TransactionGroup = $false,

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
        $script:localizedData.SetAuditSpecification -f $Name, $ServerName, $InstanceName
    )

    $TargetResourceParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Name         = $Name
    }

    # Get-TargetResource will also help us to test if the database exist.
    $getTargetResourceResult = Get-TargetResource @TargetResourceParameters

    # Default parameters for the cmdlet Invoke-Query used throughout.
    $invokeQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = 'MASTER'
    }

    $desiredValues = @{ } + $PSBoundParameters

    $auditSpecificationAddDropString = Get-AuditSpecificationMutationString -CurrentValues $getTargetResourceResult -DesiredValues $desiredValues
    Write-Verbose -Message $(
        Get-AuditSpecificationMutationString -CurrentValues $getTargetResourceResult -DesiredValues $desiredValues
    )

    $recreateAudit = $false

    if ($getTargetResourceResult.Ensure -eq $Ensure)
    {
        if ($Ensure -eq 'Present')
        {
            # Update, if needed.
            Write-Verbose -Message (
                $script:localizedData.CreateAuditSpecification -f $Name, $serverName, $instanceName
            )

            Disable-AuditSpecification -ServerName $serverName -Name $Name -InstanceName $instanceName

            try
            {
                Invoke-Query @invokeQueryParameters -Query (
                    'ALTER SERVER AUDIT SPECIFICATION [{0}] FOR SERVER AUDIT [{1}] {2}' -f
                    $Name,
                    $AuditName,
                    $auditSpecificationAddDropString
                )
            }
            catch
            {
                #If something went wrong, try to recreate te resource.
                $recreateAudit = $true

                $errorMessage = $script:localizedData.FailedUpdateAuditSpecification -f $Name, $serverName, $instanceName
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }

            if ($Enabled -eq $true)
            {
                Enable-AuditSpecification -ServerName $serverName -Name $Name -InstanceName $instanceName
            }
        }
    }

    # Throw if not opt-in to re-create server audit specification.
    if ($recreateAudit -and -not $Force)
    {
        $errorMessage = $script:localizedData.ForceNotEnabled
        New-InvalidOperationException -Message $errorMessage
    }

    if (($Ensure -eq 'Absent' -and $getTargetResourceResult.Ensure -ne $Ensure) -or $recreateAudit)
    {
        Write-Verbose -Message (
            $script:localizedData.DropAuditSpecification -f $Name, $serverName, $instanceName
        )

        Disable-AuditSpecification -ServerName $serverName -Name $Name -InstanceName $instanceName

        # Drop the server audit.
        try
        {
            Invoke-Query @invokeQueryParameters -Query (
                'DROP SERVER AUDIT SPECIFICATION [{0}];' -f $Name
            )
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedDropAuditSpecification -f $Name, $serverName, $instanceName
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }

    <#
        This evaluation is made to handle creation and re-creation of a database
        user to minimize the logic when the user has a different user type, or
        when there are restrictions on altering an existing database user.
    #>
    if (($Ensure -eq 'Present' -and $getTargetResourceResult.Ensure -ne $Ensure) -or $recreateAudit)
    {
        Write-Verbose -Message (
            $script:localizedData.CreateAuditSpecification -f $Name, $serverName, $instanceName
        )

        try
        {
            #when target audit already has an audit specification, graceful abort.
            #only one audit spec for each audit per database/server can exist.
            $DataSetAudit = Invoke-Query @invokeQueryParameters -WithResults -Query (
                'select sas.name from
                    sys.server_audits sa inner join
                    sys.server_audit_specifications sas
                        on sa.audit_guid = sas.audit_guid
                 where sa.name = ''{0}''' -f
                $AuditName)
            if ($null -eq $DataSetAudit -or $DataSetAudit.Tables[0].Rows.Count -gt 0)
            {
                $errorMessage = $script:localizedData.AuditAlreadyInUse -f
                $AuditName,
                $Name,
                $serverName,
                $instanceName,
                $DataSetAudit.Tables[0].Rows[0]
                New-InvalidOperationException -Message $errorMessage #-ErrorRecord $_
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedCreateAuditSpecification -f $Name, $serverName, $instanceName
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }

        # Create, if needed and posible.
        try
        {
            Invoke-Query @invokeQueryParameters -Query (
                'CREATE SERVER AUDIT SPECIFICATION [{0}] FOR SERVER AUDIT [{1}] {2}' -f
                $Name,
                $AuditName,
                $auditSpecificationAddDropString)

            if ($Enabled -eq $true)
            {
                Enable-AuditSpecification -ServerName $serverName -Name $Name -InstanceName $instanceName
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedCreateAuditSpecification -f $Name, $serverName, $instanceName
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
    }
}



<#
    .SYNOPSIS
        Determines if the server audit specification is in desired state.

    .PARAMETER Name
        Specifies the name of the server audit specification to be added or removed.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the server audit specification exist.

    .PARAMETER Ensure
        Specifies if the server audit specification should be present or absent.
        If 'Present' then the server audit specification will be added to the instance
        and, if needed, the server audit specification will be updated. If 'Absent'
        then the server audit specification will be removed from the instance.
        Defaults to 'Present'.

    .PARAMETER AuditName
        Specifies the audit that should be used to store the server audit specification
        events.

    .PARAMETER Enabled
        Specifies if the server audit specification should be enabled or disabled.

    .PARAMETER ApplicationRoleChangePasswordGroup
        Specifies if this audit specification should be on or off

    .PARAMETER AuditChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER BackupRestoreGroup
        Specifies if this audit specification should be on or off

    .PARAMETER BrokerLoginGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseLogoutGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseMirroringLoginGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseObjectAccessGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseObjectChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseObjectOwnershipChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseObjectPermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseOperationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseOwnershipChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabasePermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabasePrincipalChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabasePrincipalImpersonationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DatabaseRoleMemberChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER DbccGroup
        Specifies if this audit specification should be on or off

    .PARAMETER FailedDatabaseAuthenticationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER FailedLoginGroup
        Specifies if this audit specification should be on or off

    .PARAMETER FulltextGroup
        Specifies if this audit specification should be on or off

    .PARAMETER LoginChangePasswordGroup
        Specifies if this audit specification should be on or off

    .PARAMETER LogoutGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SchemaObjectAccessGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SchemaObjectChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SchemaObjectOwnershipChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SchemaObjectPermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerObjectChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerObjectOwnershipChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerObjectPermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerOperationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerPermissionChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerPrincipalChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerPrincipalImpersonationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerRoleMemberChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER ServerStateChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SuccessfulDatabaseAuthenticationGroup
        Specifies if this audit specification should be on or off

    .PARAMETER SuccessfulLoginGroup
        Specifies if this audit specification should be on or off

    .PARAMETER TraceChangeGroup
        Specifies if this audit specification should be on or off

    .PARAMETER UserChangePasswordGroup
        Specifies if this audit specification should be on or off

    .PARAMETER UserDefinedAuditGroup
        Specifies if this audit specification should be on or off

    .PARAMETER TransactionGroup
        Specifies if this audit specification should be on or off
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
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
        [System.String]
        $AuditName,

        [Parameter()]
        [System.Boolean]
        $ApplicationRoleChangePasswordGroup = $false,

        [Parameter()]
        [System.Boolean]
        $AuditChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $BackupRestoreGroup = $false,

        [Parameter()]
        [System.Boolean]
        $BrokerLoginGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseLogoutGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseMirroringLoginGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseObjectAccessGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseObjectChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseObjectOwnershipChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseObjectPermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseOperationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseOwnershipChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabasePermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabasePrincipalChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabasePrincipalImpersonationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DatabaseRoleMemberChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $DbccGroup = $false,

        [Parameter()]
        [System.Boolean]
        $FailedDatabaseAuthenticationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $FailedLoginGroup = $false,

        [Parameter()]
        [System.Boolean]
        $FulltextGroup = $false,

        [Parameter()]
        [System.Boolean]
        $LoginChangePasswordGroup = $false,

        [Parameter()]
        [System.Boolean]
        $LogoutGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SchemaObjectAccessGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SchemaObjectChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SchemaObjectOwnershipChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SchemaObjectPermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerObjectChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerObjectOwnershipChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerObjectPermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerOperationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerPermissionChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerPrincipalChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerPrincipalImpersonationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerRoleMemberChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $ServerStateChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SuccessfulDatabaseAuthenticationGroup = $false,

        [Parameter()]
        [System.Boolean]
        $SuccessfulLoginGroup = $false,

        [Parameter()]
        [System.Boolean]
        $TraceChangeGroup = $false,

        [Parameter()]
        [System.Boolean]
        $UserChangePasswordGroup = $false,

        [Parameter()]
        [System.Boolean]
        $UserDefinedAuditGroup = $false,

        [Parameter()]
        [System.Boolean]
        $TransactionGroup = $false,

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
        $script:localizedData.EvaluateAuditSpecification -f $Name, $ServerName, $InstanceName
    )

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
                'Ensure'
                'AuditName'
                'ApplicationRoleChangePasswordGroup'
                'AuditChangeGroup'
                'BackupRestoreGroup'
                'BrokerLoginGroup'
                'DatabaseChangeGroup'
                'DatabaseLogoutGroup'
                'DatabaseMirroringLoginGroup'
                'DatabaseObjectAccessGroup'
                'DatabaseObjectChangeGroup'
                'DatabaseObjectOwnershipChangeGroup'
                'DatabaseObjectPermissionChangeGroup'
                'DatabaseOperationGroup'
                'DatabaseOwnershipChangeGroup'
                'DatabasePermissionChangeGroup'
                'DatabasePrincipalChangeGroup'
                'DatabasePrincipalImpersonationGroup'
                'DatabaseRoleMemberChangeGroup'
                'DbccGroup'
                'FailedDatabaseAuthenticationGroup'
                'FailedLoginGroup'
                'FulltextGroup'
                'LoginChangePasswordGroup'
                'LogoutGroup'
                'SchemaObjectAccessGroup'
                'SchemaObjectChangeGroup'
                'SchemaObjectOwnershipChangeGroup'
                'SchemaObjectPermissionChangeGroup'
                'ServerObjectChangeGroup'
                'ServerObjectOwnershipChangeGroup'
                'ServerObjectPermissionChangeGroup'
                'ServerOperationGroup'
                'ServerPermissionChangeGroup'
                'ServerPrincipalChangeGroup'
                'ServerPrincipalImpersonationGroup'
                'ServerRoleMemberChangeGroup'
                'ServerStateChangeGroup'
                'SuccessfulDatabaseAuthenticationGroup'
                'SuccessfulLoginGroup'
                'TraceChangeGroup'
                'UserChangePasswordGroup'
                'UserDefinedAuditGroup'
                'TransactionGroup'
                'Enabled'
            )
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
        Converts a datatable to a HashTable

    .PARAMETER DataTable
        The datatable to be converted to a hashtable.
        The datatable can have one or two columns.
        When the datatable has one column, the hashtable wil use $true as value for the second collomn.
#>
function Convert-ToHashTable
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [system.Data.DataTable]
        $DataTable
    )
    $resultSet = @{ }
    foreach ($Item in $DataTable)
    {
        if ($DataTable.Columns.Count -eq 1)
        {
            $resultSet.Add($Item[0], $true)
        }
        if ($DataSet.Columns.Count -eq 2)
        {
            $resultSet.Add($Item[0], $Item[1])
        }
    }
    return $resultSet
}

<#
    .SYNOPSIS
        Disables a server audit specification.

    .PARAMETER Name
        Specifies the name of the server audit specification to be disabled.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the audit exist.
#>
function Disable-AuditSpecification
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
    Write-Verbose -Message (
        $script:localizedData.DisableAuditSpecification -f $Name, $serverName, $instanceName
    )

    $invokeQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = 'MASTER'
    }

    Invoke-Query @invokeQueryParameters -Query (
        'ALTER SERVER AUDIT SPECIFICATION [{0}] WITH (STATE = OFF);' -f $Name
    )
}

<#
    .SYNOPSIS
        Enables a server audit specification.

    .PARAMETER Name
        Specifies the name of the server audit specification to be enabled.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server on which the instance exist.

    .PARAMETER InstanceName
        Specifies the SQL instance in which the audit exist.
#>
function Enable-AuditSpecification
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
    Write-Verbose -Message (
        $script:localizedData.EnableAuditSpecification -f $Name, $serverName, $instanceName
    )

    $invokeQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = 'MASTER'
    }

    Invoke-Query @invokeQueryParameters -Query (
        'ALTER SERVER AUDIT SPECIFICATION [{0}] WITH (STATE = ON);' -f $Name
    )
}

<#
    .SYNOPSIS
        Converts the parameter name to the equivalent database object name.

    .PARAMETER InString
        Specifies the name of the parameter to be converted to a server policy string.

    .EXAMPLE
        $strKey = 'AuditChangeGroup'
        $ret = Get-DatabaseObjectNameFromPSParamName -InString $strKey
        $ret
        Should return 'AUDIT_CHANGE_GROUP' in $ret

    .NOTES
        Trough this function the capital letters in Get- Test- and Set-TargetResource
        parameters get converted, e.g. FulltextGroup and AuditChangeGroup to
        FULLTEXT_GROUP and AUDIT_CHANGE_GROUP.
        This is the naming of audit specification within SQL Server.

        DO NOT CHANGE THE CAPITALS IN THE PARAMETERS!
        These are used to find the places to insert an underscore.
#>
function Get-DatabaseObjectNameFromPSParamName
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InString
    )
    return ($InString -creplace '([A-Z\W_]|\d+)(?<![a-z])', '_$&').ToString().Remove(0, 1).ToUpper()
}

<#
    .SYNOPSIS
        Builds a ADD/DROP string for all the needed changes of the database audit specification

    .PARAMETER $CurrentValues
        Specifies the hashtable containing the current settings. Usualy this should be the output of Get-TargetResource

    .PARAMETER $DesiredValues
        Specifies the hashtable containing the desired settings. Usualy this should be all of the input parameters of Set-TargetResource.
#>
function Get-AuditSpecificationMutationString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DesiredValues
    )
    $resultString = ''
    $CurrentValues.GetEnumerator() | ForEach-Object {
        if ($null -eq $_.Value -or $_.Value -eq '')
        {
            $val = 'False'
        }
        else
        {
            $val = $_.Value
        }
        $resultString += Test-SingleRow -CurrentKey $_.Key -CurrentValue $val -DesiredValues $DesiredValues
    }
    return $resultString.TrimEnd(',')
}

<#
    .SYNOPSIS
        Builds a ADD/DROP string for all the needed changes of the database audit specification

    .PARAMETER $CurrentKey
        Specifies the current Key to be checked against the hash DesiredValues.

    .PARAMETER $CurrentValue
        Specifies the current Value to be checked against the hash DesiredValues.

    .PARAMETER $DesiredValues
        Specifies the hashtable containing the desired settings. Usualy this should be all of the input parameters of Set-TargetResource.
#>
function Test-SingleRow
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $CurrentKey,

        [Parameter(Mandatory = $true)]
        [String]
        $CurrentValue,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DesiredValues
    )

    $return = ''

    if ($CurrentKey -ne 'Name' -and
        $CurrentKey -ne 'ServerName' -and
        $CurrentKey -ne 'InstanceName' -and
        $CurrentKey -ne 'AuditName' -and
        $CurrentKey -ne 'Enabled' -and
        $CurrentKey -ne 'Ensure' -and
        $CurrentKey -ne 'Force')
    {
        if ($null -eq $DesiredValues.$CurrentKey)
        {
            $desiredValue = 'False'
        }
        else
        {
            $desiredValue = $DesiredValues.$CurrentKey
        }

        #When not equal
        if ($CurrentValue -ne $desiredValue)
        {
            $DatabaseCompatibleKeyString = Get-DatabaseObjectNameFromPSParamName -InString $CurrentKey

            if ($desiredValue -eq 'True')
            {
                #When desired, add it.
                $return = 'ADD ({0}),' -f $DatabaseCompatibleKeyString
            }
            else
            {
                #When not wanted, drop it.
                $return = 'DROP ({0}),' -f $DatabaseCompatibleKeyString
            }
        }
    }

    return $return
}

Export-ModuleMember -Function *-TargetResource
