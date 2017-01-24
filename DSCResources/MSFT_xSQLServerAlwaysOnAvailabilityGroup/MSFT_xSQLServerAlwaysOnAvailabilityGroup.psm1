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
            AvailabilityMode = $ag.AvailabilityReplicas[$serverObject.Name].AvailabilityMode
            BackupPriority = $ag.AvailabilityReplicas[$serverObject.Name].BackupPriority
            ConnectionModeInPrimaryRole = $ag.AvailabilityReplicas[$serverObject.Name].ConnectionModeInPrimaryRole
            ConnectionModeInSecondaryRole = $ag.AvailabilityReplicas[$serverObject.Name].ConnectionModeInSecondaryRole
            FailureConditionLevel = $ag.FailureConditionLevel
            FailoverMode = $ag.AvailabilityReplicas[$serverObject.Name].FailoverMode
            HealthCheckTimeout = $ag.HealthCheckTimeout
            EndpointURL = $ag.AvailabilityReplicas[$serverObject.Name].EndpointUrl
            EndpointPort = $endpointPort
            SQLServerNetName = $serverObject.NetName
            Version = $serverObject.Version.Major
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
    Specifies if the availability group should be present or absent. Default is Present.

    .PARAMETER AutomatedBackupPreference
    Specifies the automated backup preference for the availability group.

    .PARAMETER AvailabilityMode
    Specifies the replica availability mode. Default is 'AsynchronousCommit'.

    .PARAMETER BackupPriority
    Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup. Default is 50.

    .PARAMETER BasicAvailabilityGroup
    Specifies the type of availability group.

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
    $ag = $serverObject.AvailabilityGroups[$Name]

    switch ($Ensure)
    {
        Absent
        {
            # If the AG exists
            if ( $ag )
            {
                # If the primary replica is currently on this instance
                if ( $ag.PrimaryReplicaServerName -eq $serverObject.Name )
                {
                    try
                    {
                        Remove-SqlAvailabilityGroup -InputObject $ag -ErrorAction Stop
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType RemoveAvailabilityGroupFailed -FormatArgs $ag.Name,$SQLInstanceName -ErrorCategory ResourceUnavailable
                    }
                }
                else
                {
                    throw New-TerminatingError -ErrorType InstanceNotPrimaryReplica -FormatArgs $SQLInstanceName,$ag.Name -ErrorCategory ResourceUnavailable
                }
            }
        }

        Present
        {
            $clusSvcName = 'NT SERVICE\ClusSvc'
            $ntAuthoritySystemName = 'NT AUTHORITY\SYSTEM'
            $agManagementRoleName = 'AG_Management'
            $agManagementPerms = @('Connect SQL','Alter Any Availability Group','View Server State')
            $clusterPermissionsPresent = $false

            $permissionsParams = @{
                SQLServer = $SQLServer
                SQLInstanceName = $SQLInstanceName
                Database = 'master'
                WithResults = $true
            }

            # Using the clusSvc is preferred, so check for it first
            if ( $serverObject.Logins[$clusSvcName] -and -not $clusterPermissionsPresent )
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

                if ( $clusSvcEffectPerms -ne $null )
                {
                    $clusSvcMissingPerms = Compare-Object -ReferenceObject $agManagementPerms -DifferenceObject $clusSvcEffectPerms | 
                        Where-Object { $_.SideIndicator -ne '=>' } |
                        Select-Object -ExpandProperty InputObject 
                    
                    if ( $clusSvcMissingPerms.Count -eq 0 )
                    {
                        $clusterPermissionsPresent = $true
                    }
                    else
                    {
                        New-VerboseMessage -Message "'$clusSvcName' is missing the following permissions: $( $clusSvcMissingPerms -join ', ' )"
                    }
                }
            }
            
            # If the ClusSvc is not permissioned properly, fall back to NT AUTHORITY\SYSTEM.
            if ( $serverObject.Logins[$ntAuthoritySystemName] -and -not $clusterPermissionsPresent )
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
                if ( $systemEffectPerms -ne $null )
                {
                    $systemSvcMissingPerms = Compare-Object -ReferenceObject $agManagementPerms -DifferenceObject $systemEffectPerms | 
                                                Where-Object { $_.SideIndicator -ne '=>' } |
                                                Select-Object -ExpandProperty InputObject 
                    
                    if ( $systemSvcMissingPerms.Count -eq 0 )
                    {
                        $clusterPermissionsPresent = $true
                    }
                    else
                    {
                        New-VerboseMessage -Message "'$ntAuthoritySystemName' is missing the following permissions: $( $systemSvcMissingPerms -join ', ' )"
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
            if ( -not $ag )
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
                    throw New-TerminatingError -ErrorType CreateAgReplicaFailed -FormatArgs $Ensure,$SQLInstanceName -ErrorCategory OperationStopped
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
                    throw New-TerminatingError -ErrorType CreateAvailabilityGroupFailed -FormatArgs $Name,$_.Exception -ErrorCategory OperationStopped
                }
            }
            # Otherwise let's check each of the parameters passed and update the AG accordingly
            else
            {                
                # Make sure we're communicating with the primary replica
                if ( $ag.LocalReplicaRole -ne 'Primary' )
                {
                    $primaryServerObject = Connect-SQL -SQLServer $ag.PrimaryReplicaServerName
                    $ag = $primaryServerObject.AvailabilityGroups[$Name]
                }
                
                if ( $AutomatedBackupPreference -ne $ag.AutomatedBackupPreference )
                {
                    $ag.AutomatedBackupPreference = $AutomatedBackupPreference
                    Update-AvailabilityGroup -AvailabilityGroup $ag
                }

                if ( $AvailabilityMode -ne $ag.AvailabilityReplicas[$serverObject.Name].AvailabilityMode )
                {
                    $ag.AvailabilityReplicas[$serverObject.Name].AvailabilityMode = $AvailabilityMode
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $ag.AvailabilityReplicas[$serverObject.Name]
                }

                if ( $BackupPriority -ne $ag.AvailabilityReplicas[$serverObject.Name].BackupPriority )
                {
                    $ag.AvailabilityReplicas[$serverObject.Name].AvailabilityMode = $BackupPriority
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $ag.AvailabilityReplicas[$serverObject.Name]
                }

                if ( $BasicAvailabilityGroup -and ( $version -ge 13 ) -and ( $BasicAvailabilityGroup -ne $ag.BasicAvailabilityGroup ) ) 
                {
                    $ag.BasicAvailabilityGroup = $BasicAvailabilityGroup
                    Update-AvailabilityGroup -AvailabilityGroup $ag
                }

                if ( ( -not [string]::IsNullOrEmpty($ConnectionModeInPrimaryRole) ) -and ( $ConnectionModeInPrimaryRole -ne $ag.AvailabilityReplicas[$serverObject.Name].ConnectionModeInPrimaryRole ) )
                {
                    $ag.AvailabilityReplicas[$serverObject.Name].ConnectionModeInPrimaryRole = $ConnectionModeInPrimaryRole
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $ag.AvailabilityReplicas[$serverObject.Name]
                }

                if ( ( -not [string]::IsNullOrEmpty($ConnectionModeInSecondaryRole) ) -and ( $ConnectionModeInSecondaryRole -ne $ag.AvailabilityReplicas[$serverObject.Name].ConnectionModeInSecondaryRole ) )
                {
                    $ag.AvailabilityReplicas[$serverObject.Name].ConnectionModeInSecondaryRole = $ConnectionModeInSecondaryRole
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $ag.AvailabilityReplicas[$serverObject.Name]
                }
                
                # Break out the EndpointUrl properties
                $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $ag.AvailabilityReplicas[$serverObject.Name].EndpointUrl.Replace('//','').Split(':')

                if ( $endpoint.Protocol.Tcp.ListenerPort -ne $currentEndpointPort )
                {
                    $newEndpointUrl = $ag.AvailabilityReplicas[$serverObject.Name].EndpointUrl.Replace($currentEndpointPort,$endpoint.Protocol.Tcp.ListenerPort)
                    $ag.AvailabilityReplicas[$serverObject.Name].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $ag.AvailabilityReplicas[$serverObject.Name]
                }

                if ( $EndpointHostName -ne $currentEndpointHostName )
                {
                    $newEndpointUrl = $ag.AvailabilityReplicas[$serverObject.Name].EndpointUrl.Replace($currentEndpointHostName,$EndpointHostName)
                    $ag.AvailabilityReplicas[$serverObject.Name].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $ag.AvailabilityReplicas[$serverObject.Name]
                }

                if ( $currentEndpointProtocol -ne 'TCP' )
                {
                    $newEndpointUrl = $ag.AvailabilityReplicas[$serverObject.Name].EndpointUrl.Replace($currentEndpointProtocol,'TCP')
                    $ag.AvailabilityReplicas[$serverObject.Name].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $ag.AvailabilityReplicas[$serverObject.Name]
                }

                if ( ( -not [string]::IsNullOrEmpty($FailureConditionLevel) ) -and ( $FailureConditionLevel -ne $ag.FailureConditionLevel ) )
                {
                    $ag.FailureConditionLevel = $FailureConditionLevel
                    Update-AvailabilityGroup -AvailabilityGroup $ag
                }

                if ( $FailoverMode -ne $ag.AvailabilityReplicas[$serverObject.Name].FailoverMode )
                {
                    $ag.AvailabilityReplicas[$serverObject.Name].AvailabilityMode = $FailoverMode
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $ag.AvailabilityReplicas[$serverObject.Name]
                }
                
                if ( $HealthCheckTimeout -ne $ag.HealthCheckTimeout )
                {
                    $ag.HealthCheckTimeout = $HealthCheckTimeout
                    Update-AvailabilityGroup -AvailabilityGroup $ag
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
    Specifies the type of availability group.

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
            
            if ( $state.Ensure -eq 'Present' )
            {
                foreach ( $psBoundParameter in $PSBoundParameters.GetEnumerator() )
                {
                    # Make sure we don't try to validate a common parameter
                    if ( $parametersToCheck -notcontains $psBoundParameter.Key )
                    {
                        continue
                    }
                    
                    if ( $state.($psBoundParameter.Key) -ne $psBoundParameter.Value )
                    {
                        if ( $psBoundParameter.Key -eq 'BasicAvailabilityGroup' )
                        {                          
                            # Move on to the next property if the instance is not at least SQL Server 2016
                            if ( $state.Version -lt 13 )
                            {
                                continue
                            }
                        }
                        
                        New-VerboseMessage -Message "'$($psBoundParameter.Key)' should be '$($psBoundParameter.Value)' but is '$($state.($psBoundParameter.Key))'"
                        
                        $result = $False
                    }
                }

                # Get the Endpoint URL properties
                $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $state.EndpointUrl.Replace('//','').Split(':')

                if ( -not $EndpointHostName )
                {
                    $EndpointHostName = $state.SQLServerNetName
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
                if ( $state.EndpointPort -ne $currentEndpointPort )
                {
                    New-VerboseMessage -Message "'EndpointPort' should be '$($state.EndpointPort)' but is '$currentEndpointPort'"
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
