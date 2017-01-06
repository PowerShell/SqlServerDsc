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

    # Get the AG
    $ag = $serverObject.AvailabilityGroups[$Name]

    if ( $ag )
    {
        # Get all of the properties that can be set using this resource
        $return = @{
            Name = $Name
            SQLServer = $SQLServer
            SQLInstanceName = $SQLInstanceName
            Ensure = 'Present'
            AutomatedBackupPreference = $ag.AutomatedBackupPreference
            AvailabilityMode = $ag.AvailabilityReplicas[$SQLServer].AvailabilityMode
            BackupPriority = $ag.AvailabilityReplicas[$SQLServer].BackupPriority
            ConnectionModeInPrimaryRole = $ag.AvailabilityReplicas[$SQLServer].ConnectionModeInPrimaryRole
            ConnectionModeInSecondaryRole = $ag.AvailabilityReplicas[$SQLServer].ConnectionModeInSecondaryRole
            FailureConditionLevel = $ag.FailureConditionLevel
            FailoverMode = $ag.AvailabilityReplicas[$SQLServer].FailoverMode
            HealthCheckTimeout = $ag.HealthCheckTimeout
        }

        # Add properties that are only present in SQL 2016 or newer
        if ( $serverObject.Version.Major -ge 13 )
        {
            $return.Add('BasicAvailabilityGroup', $ag.BasicAvailabilityGroup)
        }
    }
    else 
    {
        # Return the minimum amount of properties showing that the AG is absent
        $return = @{
            Name = $Name
            SQLServer = $SQLServer
            SQLInstanceName = $SQLInstanceName
            Ensure = 'Absent'
        }
    }

    return $return
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
    Specifies if the availability group should be present or absent.

    .PARAMETER AutomatedBackupPreference
    Specifies the automated backup preference for the availability group.

    .PARAMETER AvailabilityMode
    Specifies the replica availability mode. Default is 'AsynchronousCommit'.

    .PARAMETER BackupPriority
    Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup.

    .PARAMETER BasicAvailabilityGroup
    Specifies the type of availability group.

    .PARAMETER ConnectionModeInPrimaryRole
    Specifies how the availability replica handles connections when in the primary role.

    .PARAMETER ConnectionModeInSecondaryRole
    Specifies how the availability replica handles connections when in the secondary role.

    .PARAMETER EndpointPort
    Specifies the port of the database mirroring endpoint. Default is 5022.

    .PARAMETER FailureConditionLevel
    Specifies the automatic failover behavior of the availability group.

    .PARAMETER HealthCheckTimeout
    Specifies the length of time, in milliseconds, after which AlwaysOn availability groups declare an unresponsive server to be unhealthy.
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,

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
        $BackupPriority,

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
        [ValidateRange(0,65535)]
        [int]
        $EndpointPort = 5022,

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
        $HealthCheckTimeout
    )
    
    Import-SQLPSModule
    
    # Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Determine if HADR is enabled on the instance. If not, throw an error
    if ( -not $serverObject.IsHadrEnabled )
    {
        throw New-TerminatingError -ErrorType HadrNotEnabled -FormatArgs $Ensure,$serverInstance -ErrorCategory NotImplemented
    }

    $version = $serverObject.Version.Major

    # Get the Availabilty Group if it exists
    $ag = $serverObject.AvailabilityGroups[$Name]

    switch ($Ensure)
    {
        Absent
        {
            # If the AG exists
            if ( $ag )
            {
                # If the primary replica is currently on this instance
                if ( $ag.PrimaryReplica -eq $serverObject.NetName )
                {
                    Remove-SqlAvailabilityGroup -InputObject $ag -ErrorAction Stop
                }
                else
                {
                    throw New-TerminatingError -ErrorType InstanceNotPrimaryReplica -FormatArgs $Ensure,$serverInstance -ErrorCategory ResourceUnavailable
                }
            }
        }

        Present
        {
            $clusSvcName = 'NT SERVICE\ClusSvc'
            $ntAuthoritySystemName = 'NT AUTHORITY\SYSTEM'
            $agManagementRoleName = 'AG_Management'
            $agManagementPerms = @('Connect SQL','Alter Any Availability Group','View Server State')
            $clusterPermissionsPresesnt = $false

            $permissionsParams = @{
                SQLServer = $SQLServer
                SQLInstanceName = $SQLInstanceName
                Database = 'master'
                WithResults = $true
            }

            # Using the clusSvc is preferred, so check for it first
            if ( $serverObject.Logins[$clusSvcName] -and -not $clusterPermissionsPresesnt )
            {
                # Get the effective permissions of the cluster service
                $clusSvcEffectPermsQueryClusSvc = "
                    EXECUTE AS LOGIN = '$clusSvcName'
                    SELECT DISTINCT permission_name
                    FROM fn_my_permissions(null,'SERVER')
                    REVERT
                "
                $clusSvcEffectPermsResult = Invoke-Query @permissionsParams -Query $clusSvcEffectPermsQueryClusSvc
                $clusSvcEffectPerms = $clusSvcEffectPermsResult.Tables.Rows.permission_name
                $clusSvcMissingPerms = Compare-Object -ReferenceObject $agManagementPerms -DifferenceObject $clusSvcEffectPerms | 
                                            Where-Object { $_.SideIndicator -ne '=>' } |
                                            Select-Object -ExpandProperty InputObject 
                
                if ( $clusSvcMissingPerms.Count -eq 0 )
                {
                    $clusterPermissionsPresesnt = $true
                }
            }
            
            # If the ClusSvc is not permissioned properly, fall back to NT AUTHORITY\SYSTEM.
            if ( $serverObject.Logins[$ntAuthoritySystemName] -and -not $clusterPermissionsPresesnt )
            {
                # Get the effective permissions of NT AUTHORITY\SYSTEM
                $clusSvcEffectPermsQuerySystem = "
                    EXECUTE AS LOGIN = '$ntAuthoritySystemName'
                    SELECT DISTINCT permission_name
                    FROM fn_my_permissions(null,'SERVER')
                    REVERT
                "
                $systemEffectPermsResult = Invoke-Query @permissionsParams -Query $clusSvcEffectPermsQuerySystem
                $systemEffectPerms = $systemEffectPermsResult.Tables.Rows.permission_name
                $systemSvcMissingPerms = Compare-Object -ReferenceObject $agManagementPerms -DifferenceObject $systemEffectPerms | 
                                            Where-Object { $_.SideIndicator -ne '=>' } |
                                            Select-Object -ExpandProperty InputObject 
                
                if ( $systemSvcMissingPerms.Count -eq 0 )
                {
                    $clusterPermissionsPresesnt = $true
                }
            }

            # If neither 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' have the required permissions, throw an error
            if ( -not $clusterPermissionsPresesnt )
            {
                throw New-TerminatingError -ErrorType ClusterPermissionsMissing -FormatArgs $SQLServer,$SQLInstanceName -ErrorCategory SecurityError
            }            
            
            # If the availability group does not exist, create it
            if ( -not $ag )
            {
                # Set up the parameters to create the AG Replica
                $newReplicaParams = @{
                    Name = $serverObject.NetName
                    Version = $version
                    AsTemplate = $true
                    AvailabilityMode = $AvailabilityMode
                    EndpointUrl = "TCP://$($serverObject.NetName):$EndpointPort"
                    FailoverMode = $FailoverMode
                }

                if ( $BackupPriority ) { $newReplicaParams.Add('BackupPriority',$BackupPriority) }
                if ( $ConnectionModeInPrimaryRole ) { $newReplicaParams.Add('ConnectionModeInPrimaryRole',$ConnectionModeInPrimaryRole) }
                if ( $ConnectionModeInSecondaryRole ) { $newReplicaParams.Add('ConnectionModeInSecondaryRole',$ConnectionModeInSecondaryRole) }

                # Create the new replica object
                try
                {
                    $primaryReplica = New-SqlAvailabilityReplica @newReplicaParams -ErrorAction Stop
                }
                catch
                {
                    throw New-TerminatingError -ErrorType CreateAgReplicaFailed -FormatArgs $Ensure,$serverInstance -ErrorCategory OperationStopped
                }

                # Set up the parameters for the new availability group
                $newAvailabilityGroupParams = @{
                    InputObject = $serverObject
                    Name = $Name
                    AvailabilityReplica = $primaryReplica
                }

                if ( $AutomatedBackupPreference ) { $newAvailabilityGroupParams.Add('AutomatedBackupPreference',$AutomatedBackupPreference) }
                if ( $BasicAvailabilityGroup -and ( $version -ge 13 ) ) { $newAvailabilityGroupParams.Add('BasicAvailabilityGroup',$BasicAvailabilityGroup) }
                if ( $FailureConditionLevel ) { $newAvailabilityGroupParams.Add('FailureConditionLevel',$FailureConditionLevel) }
                if ( $HealthCheckTimeout ) { $newAvailabilityGroupParams.Add('HealthCheckTimeout',$HealthCheckTimeout) }
                
                # Create the Availabilty Group
                try 
                {
                    New-SqlAvailabilityGroup @newAvailabilityGroupParams -ErrorAction Stop
                }
                catch
                {
                    throw New-TerminatingError -ErrorType CreateAvailabilityGroupFailed -FormatArgs $Ensure,$serverInstance -ErrorCategory OperationStopped
                }
            }
            # Otherwise let's check each of the parameters passed and update the AG accordingly
            else
            {                
                if ( $AutomatedBackupPreference -ne $ag.AutomatedBackupPreference )
                {
                    $ag.AutomatedBackupPreference = $AutomatedBackupPreference
                    $ag.Alter()
                }

                if ( $AvailabilityMode -ne $ag.AvailaiblityReplicas[$serverObject.NetName].AvailabilityMode )
                {
                    $ag.AvailaiblityReplicas[$serverObject.NetName].AvailabilityMode = $AvailabilityMode
                    $ag.AvailaiblityReplicas[$serverObject.NetName].Alter()
                }

                if ( $BackupPriority -ne $ag.AvailaiblityReplicas[$serverObject.NetName].BackupPriority )
                {
                    $ag.AvailaiblityReplicas[$serverObject.NetName].AvailabilityMode = $BackupPriority
                    $ag.AvailaiblityReplicas[$serverObject.NetName].Alter()
                }

                if ( $BasicAvailabilityGroup -and ( $version -ge 13 ) -and ( $BasicAvailabilityGroup -ne $ag.BasicAvailabilityGroup ) ) 
                {
                    $ag.BasicAvailabilityGroup = $BasicAvailabilityGroup
                    $ag.Alter()
                }

                if ( $ConnectionModeInPrimaryRole -ne $ag.AvailaiblityReplicas[$serverObject.NetName].ConnectionModeInPrimaryRole )
                {
                    $ag.AvailaiblityReplicas[$serverObject.NetName].AvailabilityMode = $ConnectionModeInPrimaryRole
                    $ag.AvailaiblityReplicas[$serverObject.NetName].Alter()
                }

                if ( $ConnectionModeInSecondaryRole -ne $ag.AvailaiblityReplicas[$serverObject.NetName].ConnectionModeInSecondaryRole )
                {
                    $ag.AvailaiblityReplicas[$serverObject.NetName].AvailabilityMode = $ConnectionModeInSecondaryRole
                    $ag.AvailaiblityReplicas[$serverObject.NetName].Alter()
                }
                
                # Break out the EndpointUrl properties
                $currentEndpointProtocol, $currentEndpointFqdn, $currentEndpointPort = $ag.AvailaiblityReplicas[$serverObject.NetName].EndpointUrl.Replace('//','').Split(':')
                
                # Fix the endpoint port if required
                if ( $EndpointPort -ne $ag.Protocol.Tcp.ListenerPort )
                {
                    $ag.Protocol.Tcp.SetPropertyValue( 'ListenerPort', 'int', $EndpointPort )
                }

                # Fix the enpoint port in the EndpointUrl if required
                if ( $EndpointPort -ne $currentEndpointPort )
                {
                    $newEndpointUrl = $ag.AvailaiblityReplicas[$serverObject.NetName].EndpointUrl.Replace($currentEndpointPort,$EndpointPort)
                    $ag.AvailaiblityReplicas[$serverObject.NetName].Alter()
                }

                if ( $FailureConditionLevel -ne $ag.FailureConditionLevel )
                {
                    $ag.AutomatedBackupPreference = $FailureConditionLevel
                    $ag.Alter()
                }

                if ( $FailoverMode -ne $ag.AvailaiblityReplicas[$serverObject.NetName].FailoverMode )
                {
                    $ag.AvailaiblityReplicas[$serverObject.NetName].AvailabilityMode = $FailoverMode
                    $ag.AvailaiblityReplicas[$serverObject.NetName].Alter()
                }
                
                if ( $HealthCheckTimeout -ne $ag.HealthCheckTimeout )
                {
                    $ag.AutomatedBackupPreference = $HealthCheckTimeout
                    $ag.Alter()
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
    Specifies if the availability group should be present or absent.

    .PARAMETER AutomatedBackupPreference
    Specifies the automated backup preference for the availability group.

    .PARAMETER AvailabilityMode
    Specifies the replica availability mode. Default is 'AsynchronousCommit'.

    .PARAMETER BackupPriority
    Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup.

    .PARAMETER BasicAvailabilityGroup
    Specifies the type of availability group.

    .PARAMETER ConnectionModeInPrimaryRole
    Specifies how the availability replica handles connections when in the primary role.

    .PARAMETER ConnectionModeInSecondaryRole
    Specifies how the availability replica handles connections when in the secondary role.

    .PARAMETER EndpointPort
    Specifies the port of the database mirroring endpoint. Default is 5022.

    .PARAMETER FailureConditionLevel
    Specifies the automatic failover behavior of the availability group.

    .PARAMETER HealthCheckTimeout
    Specifies the length of time, in milliseconds, after which AlwaysOn availability groups declare an unresponsive server to be unhealthy.
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure,

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
        $BackupPriority,

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
        [ValidateRange(0,65535)]
        [int]
        $EndpointPort = 5022,

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
        $HealthCheckTimeout
    )

    $parameters = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer = $SQLServer
        Name = $Name
    }
    
    # Assume this will pass. We will determine otherwise later
    $result = $true

    $state = Get-TargetResource @parameters

    switch ($Ensure)
    {
        'Absent'
        {
            if ( $state.Ensure -eq 'Absent' )
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
            if ( $state.Ensure -eq 'Present' )
            {
                foreach ( $psBoundParameter in $PSBoundParameters.GetEnumerator() )
                {
                    if ( $state.($psBoundParameter.Key) -ne $psBoundParameter.Value )
                    {
                        if ( $psBoundParameter.Key -eq 'BasicAvailabilityGroup' )
                        {
                            # Connect to the instance
                            $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
                            
                            # Move on to the next property if the instance is not at least SQL Server 2016
                            if ( $serverObject.Version.Major -lt 13 )
                            {
                                continue
                            }
                        }
                        
                        New-VerboseMessage -Message "'$($psBoundParameter.Key)' should be '$($psBoundParameter.Value)' but is '$($state.($psBoundParameter.Key))'"
                        
                        $result = $False
                    }
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

Export-ModuleMember -Function *-TargetResource
