Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

<#
    .SYNOPSIS
        Gets the specified Availabilty Group.
    
    .PARAMETER Name
        The name of the availability group.

    .PARAMETER SQLServer
        Hostname of the SQL Server to be configured.
    
    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configued.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName
    )
    
    # Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Get the endpoint properties
    $endpoint = $serverObject.Endpoints | Where-Object { $_.EndpointType -eq 'DatabaseMirroring' }
    if ( $endpoint )
    {
        $endpointPort = $endpoint.Protocol.Tcp.ListenerPort
    }
    
    # Get the Availability Group
    $availabilityGroup = $serverObject.AvailabilityGroups[$Name]

    if ( $availabilityGroup )
    {
        # Get all of the properties that can be set using this resource
        $alwaysOnAvailabilityGroupResource = @{
            Name = $Name
            SQLServer = $SQLServer
            SQLInstanceName = $SQLInstanceName
            Ensure = 'Present'
            AutomatedBackupPreference = $availabilityGroup.AutomatedBackupPreference
            AvailabilityMode = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].AvailabilityMode
            BackupPriority = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].BackupPriority
            ConnectionModeInPrimaryRole = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].ConnectionModeInPrimaryRole
            ConnectionModeInSecondaryRole = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].ConnectionModeInSecondaryRole
            FailureConditionLevel = $availabilityGroup.FailureConditionLevel
            FailoverMode = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].FailoverMode
            HealthCheckTimeout = $availabilityGroup.HealthCheckTimeout
            EndpointURL = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].EndpointUrl
            EndpointPort = $endpointPort
            SQLServerNetName = $serverObject.NetName
            Version = $serverObject.Version.Major
        }

        # Add properties that are only present in SQL 2016 or newer
        if ( $serverObject.Version.Major -ge 13 )
        {
            $alwaysOnAvailabilityGroupResource.Add('BasicAvailabilityGroup', $availabilityGroup.BasicAvailabilityGroup)
        }
    }
    else 
    {
        # Return the minimum amount of properties showing that the Availabilty Group is absent
        $alwaysOnAvailabilityGroupResource = @{
            Name = $Name
            SQLServer = $SQLServer
            SQLInstanceName = $SQLInstanceName
            Ensure = 'Absent'
        }
    }

    return $alwaysOnAvailabilityGroupResource
}

<#
    .SYNOPSIS
        Creates or removes the availability group to in accordance with the desired state.
    
    .PARAMETER Name
        The name of the availability group.

    .PARAMETER SQLServer
        Hostname of the SQL Server to be configured.
    
    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configued.

    .PARAMETER Ensure
        Specifies if the availability group should be present or absent. Default is Present.

    .PARAMETER AutomatedBackupPreference
        Specifies the automated backup preference for the availability group.

    .PARAMETER AvailabilityMode
        Specifies the replica availability mode. Default is 'AsynchronousCommit'.

    .PARAMETER BackupPriority
        Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup. Default is 50.

    .PARAMETER BasicAvailabilityGroup
        Specifies the type of availability group is Basic. This is only available is SQL Server 2016 and later and is ignored when applied to previous versions.

    .PARAMETER ConnectionModeInPrimaryRole
        Specifies how the availability replica handles connections when in the primary role.

    .PARAMETER ConnectionModeInSecondaryRole
        Specifies how the availability replica handles connections when in the secondary role.

    .PARAMETER EndpointHostName
        Specifies the hostname or IP address of the availability group replica endpoint. Default is the instance network name.

    .PARAMETER FailureConditionLevel
        Specifies the automatic failover behavior of the availability group.

    .PARAMETER HealthCheckTimeout
        Specifies the length of time, in milliseconds, after which AlwaysOn availability groups declare an unresponsive server to be unhealthy. Default is 30,000.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('Primary','SecondaryOnly','Secondary','None')]
        [String]
        $AutomatedBackupPreference = 'None',

        [Parameter()]
        [ValidateSet('AsynchronousCommit','SynchronousCommit')]
        [String]
        $AvailabilityMode = 'AsynchronousCommit',
        
        [Parameter()]
        [ValidateRange(0,100)]
        [UInt32]
        $BackupPriority = 50,

        [Parameter()]
        [bool]
        $BasicAvailabilityGroup,

        [Parameter()]
        [ValidateSet('AllowAllConnections','AllowReadWriteConnections')]
        [String]
        $ConnectionModeInPrimaryRole,

        [Parameter()]
        [ValidateSet('AllowNoConnections','AllowReadIntentConnectionsOnly','AllowAllConnections')]
        [String]
        $ConnectionModeInSecondaryRole,

        [Parameter()]
        [String]
        $EndpointHostName,

        [Parameter()]
        [ValidateSet(
            'OnServerDown',
            'OnServerUnresponsive',
            'OnCriticalServerErrors',
            'OnModerateServerErrors',
            'OnAnyQualifiedFailureCondition'
        )]
        [String]
        $FailureConditionLevel,

        [Parameter()]
        [ValidateSet('Automatic','Manual')]
        [String]
        $FailoverMode = 'Manual',

        [Parameter()]
        [UInt32]
        $HealthCheckTimeout = 30000
    )
    
    Import-SQLPSModule
    
    # Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Determine if HADR is enabled on the instance. If not, throw an error
    if ( -not $serverObject.IsHadrEnabled )
    {
        throw New-TerminatingError -ErrorType HadrNotEnabled -FormatArgs $Ensure,$SQLInstanceName -ErrorCategory NotImplemented
    }

    $version = $serverObject.Version.Major

    # Get the Availabilty Group if it exists
    $availabilityGroup = $serverObject.AvailabilityGroups[$Name]

    switch ($Ensure)
    {
        Absent
        {
            # If the AG exists
            if ( $availabilityGroup )
            {
                # If the primary replica is currently on this instance
                if ( $availabilityGroup.PrimaryReplicaServerName -eq $serverObject.Name )
                {
                    try
                    {
                        Remove-SqlAvailabilityGroup -InputObject $availabilityGroup -ErrorAction Stop
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType RemoveAvailabilityGroupFailed -FormatArgs $availabilityGroup.Name,$SQLInstanceName -ErrorCategory ResourceUnavailable
                    }
                }
                else
                {
                    throw New-TerminatingError -ErrorType InstanceNotPrimaryReplica -FormatArgs $SQLInstanceName,$availabilityGroup.Name -ErrorCategory ResourceUnavailable
                }
            }
        }

        Present
        {
            $clusterServiceName = 'NT SERVICE\ClusSvc'
            $ntAuthoritySystemName = 'NT AUTHORITY\SYSTEM'
            $availabilityGroupManagementRoleName = 'AG_Management'
            $availabilityGroupManagementPerms = @('Connect SQL','Alter Any Availability Group','View Server State')
            $clusterPermissionsPresent = $false

            $permissionsParams = @{
                SQLServer = $SQLServer
                SQLInstanceName = $SQLInstanceName
                Database = 'master'
                WithResults = $true
            }

            foreach ( $loginName in @( $clusterServiceName, $ntAuthoritySystemName ) )
            {
                if ( $serverObject.Logins[$loginName] -and -not $clusterPermissionsPresent )
                {
                    $queryToGetEffectivePermissionsForLogin = "
                        EXECUTE AS LOGIN = '$loginName'
                        SELECT DISTINCT permission_name
                        FROM fn_my_permissions(null,'SERVER')
                        REVERT
                    "

                    $loginEffectivePermissionsResult = Invoke-Query @permissionsParams -Query $queryToGetEffectivePermissionsForLogin
                    $loginEffectivePermissions = $loginEffectivePermissionsResult.Tables.Rows.permission_name

                    if ( $null -ne $loginEffectivePermissions )
                    {
                        $loginMissingPermissions = Compare-Object -ReferenceObject $availabilityGroupManagementPerms -DifferenceObject $loginEffectivePermissions | 
                            Where-Object { $_.SideIndicator -ne '=>' } |
                            Select-Object -ExpandProperty InputObject 
                        
                        if ( $loginMissingPermissions.Count -eq 0 )
                        {
                            $clusterPermissionsPresent = $true
                        }
                        else
                        {
                            switch ( $loginName )
                            {
                                $clusterServiceName
                                {
                                    New-VerboseMessage -Message "The recommended account '$loginName' is missing the following permissions: $( $loginMissingPermissions -join ', ' ). Trying with '$ntAuthoritySystemName'."
                                }

                                $ntAuthoritySystemName
                                {
                                    New-VerboseMessage -Message "'$loginName' is missing the following permissions: $( $loginMissingPermissions -join ', ' )"
                                }
                            }
                        }
                    }
                }
            }

            # If neither 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' have the required permissions, throw an error
            if ( -not $clusterPermissionsPresent )
            {
                throw New-TerminatingError -ErrorType ClusterPermissionsMissing -FormatArgs $SQLServer,$SQLInstanceName -ErrorCategory SecurityError
            }

            $endpoint = $serverObject.Endpoints | Where-Object { $_.EndpointType -eq 'DatabaseMirroring' }
            if ( -not $endpoint )
            {
                throw New-TerminatingError -ErrorType DatabaseMirroringEndpointNotFound -FormatArgs $SQLServer,$SQLInstanceName -ErrorCategory ObjectNotFound
            }

            if ( -not $EndpointHostName )
            {
                $EndpointHostName = $serverObject.NetName
            }
            
            # If the availability group does not exist, create it
            if ( -not $availabilityGroup )
            {

                # Set up the parameters to create the AG Replica
                $newReplicaParams = @{
                    Name = $serverObject.Name
                    Version = $version
                    AsTemplate = $true
                    AvailabilityMode = $AvailabilityMode
                    EndpointUrl = "TCP://$($EndpointHostName):$($endpoint.Protocol.Tcp.ListenerPort)"
                    FailoverMode = $FailoverMode
                }

                if ( $BackupPriority )
                {
                    $newReplicaParams.Add('BackupPriority',$BackupPriority)
                }

                if ( $ConnectionModeInPrimaryRole )
                {
                    $newReplicaParams.Add('ConnectionModeInPrimaryRole',$ConnectionModeInPrimaryRole)
                }
                
                if ( $ConnectionModeInSecondaryRole )
                {
                    $newReplicaParams.Add('ConnectionModeInSecondaryRole',$ConnectionModeInSecondaryRole)
                }

                # Create the new replica object
                try
                {
                    $primaryReplica = New-SqlAvailabilityReplica @newReplicaParams -ErrorAction Stop
                }
                catch
                {
                    throw New-TerminatingError -ErrorType CreateAvailabilityGroupReplicaFailed -FormatArgs $Ensure,$SQLInstanceName -ErrorCategory OperationStopped
                }

                # Set up the parameters for the new availability group
                $newAvailabilityGroupParams = @{
                    InputObject = $serverObject
                    Name = $Name
                    AvailabilityReplica = $primaryReplica
                }

                if ( $AutomatedBackupPreference )
                {
                    $newAvailabilityGroupParams.Add('AutomatedBackupPreference',$AutomatedBackupPreference)
                }
                
                if ( $BasicAvailabilityGroup -and ( $version -ge 13 ) )
                {
                    $newAvailabilityGroupParams.Add('BasicAvailabilityGroup',$BasicAvailabilityGroup)
                }
                
                if ( $FailureConditionLevel )
                {
                    $newAvailabilityGroupParams.Add('FailureConditionLevel',$FailureConditionLevel)
                }
                
                if ( $HealthCheckTimeout )
                {
                    $newAvailabilityGroupParams.Add('HealthCheckTimeout',$HealthCheckTimeout)
                }
                
                # Create the Availabilty Group
                try 
                {
                    New-SqlAvailabilityGroup @newAvailabilityGroupParams -ErrorAction Stop
                }
                catch
                {
                    throw New-TerminatingError -ErrorType CreateAvailabilityGroupFailed -FormatArgs $Name,$_.Exception -ErrorCategory OperationStopped
                }
            }
            # Otherwise let's check each of the parameters passed and update the Availability Group accordingly
            else
            {                
                # Make sure we're communicating with the primary replica
                if ( $availabilityGroup.LocalReplicaRole -ne 'Primary' )
                {
                    $primaryServerObject = Connect-SQL -SQLServer $availabilityGroup.PrimaryReplicaServerName
                    $availabilityGroup = $primaryServerObject.AvailabilityGroups[$Name]
                }
                
                if ( $AutomatedBackupPreference -ne $availabilityGroup.AutomatedBackupPreference )
                {
                    $availabilityGroup.AutomatedBackupPreference = $AutomatedBackupPreference
                    Update-AvailabilityGroup -AvailabilityGroup $availabilityGroup
                }

                if ( $AvailabilityMode -ne $availabilityGroup.AvailabilityReplicas[$serverObject.Name].AvailabilityMode )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.Name].AvailabilityMode = $AvailabilityMode
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.Name]
                }

                if ( $BackupPriority -ne $availabilityGroup.AvailabilityReplicas[$serverObject.Name].BackupPriority )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.Name].BackupPriority = $BackupPriority
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.Name]
                }

                if ( $BasicAvailabilityGroup -and ( $version -ge 13 ) -and ( $BasicAvailabilityGroup -ne $availabilityGroup.BasicAvailabilityGroup ) ) 
                {
                    $availabilityGroup.BasicAvailabilityGroup = $BasicAvailabilityGroup
                    Update-AvailabilityGroup -AvailabilityGroup $availabilityGroup
                }

                # Make sure ConnectionModeInPrimaryRole has a value in order to avoid false positive matches when the parameter is not defined
                if ( ( -not [string]::IsNullOrEmpty($ConnectionModeInPrimaryRole) ) -and ( $ConnectionModeInPrimaryRole -ne $availabilityGroup.AvailabilityReplicas[$serverObject.Name].ConnectionModeInPrimaryRole ) )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.Name].ConnectionModeInPrimaryRole = $ConnectionModeInPrimaryRole
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.Name]
                }

                # Make sure ConnectionModeInSecondaryRole has a value in order to avoid false positive matches when the parameter is not defined
                if ( ( -not [string]::IsNullOrEmpty($ConnectionModeInSecondaryRole) ) -and ( $ConnectionModeInSecondaryRole -ne $availabilityGroup.AvailabilityReplicas[$serverObject.Name].ConnectionModeInSecondaryRole ) )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.Name].ConnectionModeInSecondaryRole = $ConnectionModeInSecondaryRole
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.Name]
                }
                
                # Break out the EndpointUrl properties
                $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].EndpointUrl.Replace('//','').Split(':')

                if ( $endpoint.Protocol.Tcp.ListenerPort -ne $currentEndpointPort )
                {
                    $newEndpointUrl = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].EndpointUrl.Replace($currentEndpointPort,$endpoint.Protocol.Tcp.ListenerPort)
                    $availabilityGroup.AvailabilityReplicas[$serverObject.Name].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.Name]
                }

                if ( $EndpointHostName -ne $currentEndpointHostName )
                {
                    $newEndpointUrl = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].EndpointUrl.Replace($currentEndpointHostName,$EndpointHostName)
                    $availabilityGroup.AvailabilityReplicas[$serverObject.Name].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.Name]
                }

                if ( $currentEndpointProtocol -ne 'TCP' )
                {
                    $newEndpointUrl = $availabilityGroup.AvailabilityReplicas[$serverObject.Name].EndpointUrl.Replace($currentEndpointProtocol,'TCP')
                    $availabilityGroup.AvailabilityReplicas[$serverObject.Name].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.Name]
                }

                # Make sure FailureConditionLevel has a value in order to avoid false positive matches when the parameter is not defined
                if ( ( -not [string]::IsNullOrEmpty($FailureConditionLevel) ) -and ( $FailureConditionLevel -ne $availabilityGroup.FailureConditionLevel ) )
                {
                    $availabilityGroup.FailureConditionLevel = $FailureConditionLevel
                    Update-AvailabilityGroup -AvailabilityGroup $availabilityGroup
                }

                if ( $FailoverMode -ne $availabilityGroup.AvailabilityReplicas[$serverObject.Name].FailoverMode )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.Name].AvailabilityMode = $FailoverMode
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.Name]
                }
                
                if ( $HealthCheckTimeout -ne $availabilityGroup.HealthCheckTimeout )
                {
                    $availabilityGroup.HealthCheckTimeout = $HealthCheckTimeout
                    Update-AvailabilityGroup -AvailabilityGroup $availabilityGroup
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Determines if the availability group is in the desired state.
    
    .PARAMETER Name
        The name of the availability group.

    .PARAMETER SQLServer
        Hostname of the SQL Server to be configured.
    
    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configued.

    .PARAMETER Ensure
        Specifies if the availability group should be present or absent. Default is Present.

    .PARAMETER AutomatedBackupPreference
        Specifies the automated backup preference for the availability group.

    .PARAMETER AvailabilityMode
        Specifies the replica availability mode. Default is 'AsynchronousCommit'.

    .PARAMETER BackupPriority
        Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup. Default is 50.

    .PARAMETER BasicAvailabilityGroup
        Specifies the type of availability group is Basic. This is only available is SQL Server 2016 and later and is ignored when applied to previous versions.

    .PARAMETER ConnectionModeInPrimaryRole
        Specifies how the availability replica handles connections when in the primary role.

    .PARAMETER ConnectionModeInSecondaryRole
        Specifies how the availability replica handles connections when in the secondary role.

    .PARAMETER EndpointHostName
        Specifies the hostname or IP address of the availability group replica endpoint. Default is the instance network name.

    .PARAMETER FailureConditionLevel
        Specifies the automatic failover behavior of the availability group.

    .PARAMETER HealthCheckTimeout
        Specifies the length of time, in milliseconds, after which AlwaysOn availability groups declare an unresponsive server to be unhealthy. Default is 30,000.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('Primary','SecondaryOnly','Secondary','None')]
        [String]
        $AutomatedBackupPreference = 'None',

        [Parameter()]
        [ValidateSet('AsynchronousCommit','SynchronousCommit')]
        [String]
        $AvailabilityMode = 'AsynchronousCommit',
        
        [Parameter()]
        [ValidateRange(0,100)]
        [UInt32]
        $BackupPriority = 50,

        [Parameter()]
        [bool]
        $BasicAvailabilityGroup,

        [Parameter()]
        [ValidateSet('AllowAllConnections','AllowReadWriteConnections')]
        [String]
        $ConnectionModeInPrimaryRole,

        [Parameter()]
        [ValidateSet('AllowNoConnections','AllowReadIntentConnectionsOnly','AllowAllConnections')]
        [String]
        $ConnectionModeInSecondaryRole,

        [Parameter()]
        [String]
        $EndpointHostName,

        [Parameter()]
        [ValidateSet('OnServerDown','OnServerUnresponsive','OnCriticalServerErrors','OnModerateServerErrors','OnAnyQualifiedFailureCondition')]
        [String]
        $FailureConditionLevel,

        [Parameter()]
        [ValidateSet('Automatic','Manual')]
        [String]
        $FailoverMode = 'Manual',

        [Parameter()]
        [UInt32]
        $HealthCheckTimeout = 30000
    )

    $getTargetResourceParameters = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer = $SQLServer
        Name = $Name
    }
    
    # Assume this will pass. We will determine otherwise later
    $result = $true

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    switch ($Ensure)
    {
        'Absent'
        {
            if ( $getTargetResourceResult.Ensure -eq 'Absent' )
            {
                $result = $true
            }
            else
            {
                $result = $false    
            }
        }

        'Present'
        {
            $parametersToCheck = @(
                'Name',
                'SQLServer',
                'SQLInstanceName',
                'Ensure',
                'AutomatedBackupPreference',
                'AvailabilityMode',
                'BackupPriority',
                'BasicAvailabilityGroup',
                'ConnectionModeInPrimaryRole',
                'ConnectionModeInSecondaryRole',
                'FailureConditionLevel',
                'FailoverMode',
                'HealthCheckTimeout'
            )
            
            if ( $getTargetResourceResult.Ensure -eq 'Present' )
            {
                # PsBoundParameters won't work here because it doesn't account for default values
                foreach ( $parameter in $MyInvocation.MyCommand.Parameters.GetEnumerator() )
                {
                    $parameterName = $parameter.Key
                    $parameterValue = Get-Variable -Name $parameterName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
                    
                    # Make sure we don't try to validate a common parameter
                    if ( $parametersToCheck -notcontains $parameterName )
                    {
                        continue
                    }
                    
                    if ( $getTargetResourceResult.($parameterName) -ne $parameterValue )
                    {
                        if ( $parameterName -eq 'BasicAvailabilityGroup' )
                        {                          
                            # Move on to the next property if the instance is not at least SQL Server 2016
                            if ( $getTargetResourceResult.Version -lt 13 )
                            {
                                continue
                            }
                        }
                        
                        New-VerboseMessage -Message "'$($parameterName)' should be '$($parameterValue)' but is '$($getTargetResourceResult.($parameterName))'"
                        
                        $result = $False
                    }
                }

                # Get the Endpoint URL properties
                $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $getTargetResourceResult.EndpointUrl.Replace('//','').Split(':')

                if ( -not $EndpointHostName )
                {
                    $EndpointHostName = $getTargetResourceResult.SQLServerNetName
                }
                
                # Verify the hostname in the endpoint URL is correct
                if ( $EndpointHostName -ne $currentEndpointHostName )
                {
                    New-VerboseMessage -Message "'EndpointHostName' should be '$EndpointHostName' but is '$currentEndpointHostName'"
                    $result = $false
                }

                # Verify the protocol in the endpoint URL is correct
                if ( 'TCP' -ne $currentEndpointProtocol )
                {
                    New-VerboseMessage -Message "'EndpointProtocol' should be 'TCP' but is '$currentEndpointProtocol'"
                    $result = $false
                }

                # Verify the port in the endpoint URL is correct
                if ( $getTargetResourceResult.EndpointPort -ne $currentEndpointPort )
                {
                    New-VerboseMessage -Message "'EndpointPort' should be '$($getTargetResourceResult.EndpointPort)' but is '$currentEndpointPort'"
                    $result = $false
                }
            }
            else
            {
                $result = $false
            }
        }
    }

    return $result
}

<#
    .SYNOPSIS
        Executes the alter method on an Availability Group object.
    
    .PARAMETER AvailabilityGroup
        The Availabilty Group object that must be altered.
#>
function Update-AvailabilityGroup
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
        $AvailabilityGroup
    )

    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $AvailabilityGroup.Alter()
    }
    catch
    {
        throw New-TerminatingError -ErrorType AlterAvailabilityGroupFailed -FormatArgs $AvailabilityGroup.Name -ErrorCategory OperationStopped
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

<#
    .SYNOPSIS
        Executes the alter method on an Availability Group Replica object.
    
    .PARAMETER AvailabilityGroupReplica
        The Availabilty Group Replica object that must be altered.
#>
function Update-AvailabilityGroupReplica
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
        $AvailabilityGroupReplica
    )

    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $AvailabilityGroupReplica.Alter()
    }
    catch
    {
        throw New-TerminatingError -ErrorType AlterAvailabilityGroupReplicaFailed -FormatArgs $AvailabilityGroupReplica.Name -ErrorCategory OperationStopped
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

Export-ModuleMember -Function *-TargetResource
