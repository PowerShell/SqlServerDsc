Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

<#
    .SYNOPSIS
        Gets the specified Availabilty Group Replica from the specified Availabilty Group.
    
    .PARAMETER Name
        The name of the availability group replica.

    .PARAMETER AvailabilityGroupName
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

        [parameter(Mandatory = $true)]
        [String]
        $AvailabilityGroupName,
        
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

    # Create the return object
    $alwaysOnAvailabilityGroupReplicaResource = @{
        Ensure = 'Absent'
        Name = ''
        AvailabilityGroupName = ''
        AvailabilityMode = ''
        BackupPriority = ''
        ConnectionModeInPrimaryRole = ''
        ConnectionModeInSecondaryRole = ''
        FailoverMode = ''
        EndpointUrl = ''
        ReadOnlyConnectionUrl = ''
        ReadOnlyRoutingList = @()
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
        EndpointPort = $endpointPort
        SQLServerNetName = $serverObject.NetName
    }

    # Get the availability group
    $availabilityGroup = $serverObject.AvailabilityGroups[$AvailabilityGroupName]
    
    if ( $availabilityGroup )
    {
        # Add the Availability Group name to the results
        $alwaysOnAvailabilityGroupReplicaResource.AvailabilityGroupName = $availabilityGroup.Name
        
        # Try to find the replica
        $availabilityGroupReplica = $availabilityGroup.AvailabilityReplicas[$Name]

        if ( $availabilityGroupReplica )
        {
            # Add the Availability Group Replica properties to the results
            $alwaysOnAvailabilityGroupReplicaResource.Ensure = 'Present'
            $alwaysOnAvailabilityGroupReplicaResource.Name = $availabilityGroupReplica.Name
            $alwaysOnAvailabilityGroupReplicaResource.AvailabilityMode = $availabilityGroupReplica.AvailabilityMode
            $alwaysOnAvailabilityGroupReplicaResource.BackupPriority = $availabilityGroupReplica.BackupPriority
            $alwaysOnAvailabilityGroupReplicaResource.ConnectionModeInPrimaryRole = $availabilityGroupReplica.ConnectionModeInPrimaryRole
            $alwaysOnAvailabilityGroupReplicaResource.ConnectionModeInSecondaryRole = $availabilityGroupReplica.ConnectionModeInSecondaryRole
            $alwaysOnAvailabilityGroupReplicaResource.FailoverMode = $availabilityGroupReplica.FailoverMode
            $alwaysOnAvailabilityGroupReplicaResource.EndpointUrl = $availabilityGroupReplica.EndpointUrl
            $alwaysOnAvailabilityGroupReplicaResource.ReadOnlyConnectionUrl = $availabilityGroupReplica.ReadOnlyConnectionUrl
            $alwaysOnAvailabilityGroupReplicaResource.ReadOnlyRoutingList = $availabilityGroupReplica.ReadOnlyRoutingList
        }
    }

    return $alwaysOnAvailabilityGroupReplicaResource
}

<#
    .SYNOPSIS
        Creates or removes the availability group replica in accordance with the desired state.
    
    .PARAMETER Name
        The name of the availability group replica.

    .PARAMETER AvailabilityGroupName
        The name of the availability group.

    .PARAMETER SQLServer
        Hostname of the SQL Server to be configured.
    
    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configued.

    .PARAMETER PrimaryReplicaSQLServer
        Hostname of the SQL Server where the primary replica lives.
    
    .PARAMETER PrimaryReplicaSQLInstanceName
        Name of the SQL instance where the primary replica lives.

    .PARAMETER Ensure
        Specifies if the availability group should be present or absent. Default is Present.

    .PARAMETER AvailabilityMode
        Specifies the replica availability mode. Default is 'AsynchronousCommit'.

    .PARAMETER BackupPriority
        Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup. Default is 50.

    .PARAMETER ConnectionModeInPrimaryRole
        Specifies how the availability replica handles connections when in the primary role.

    .PARAMETER ConnectionModeInSecondaryRole
        Specifies how the availability replica handles connections when in the secondary role.

    .PARAMETER EndpointHostName
        Specifies the hostname or IP address of the availability group replica endpoint. Default is the instance network name.

    .PARAMETER FailoverMode
        Specifies the failover mode. Default is Manual.
    
    .PARAMETER ReadOnlyRoutingConnectionUrl
        Specifies the fully-qualified domain name (FQDN) and port to use when routing to the replica for read only connections.

    .PARAMETER ReadOnlyRoutingList
        Specifies an ordered list of replica server names that represent the probe sequence for connection director to use when redirecting read-only connections through this availability replica. This parameter applies if the availability replica is the current primary replica of the availability group.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [String]
        $AvailabilityGroupName,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter()]
        [String]
        $PrimaryReplicaSQLServer,

        [Parameter()]
        [String]
        $PrimaryReplicaSQLInstanceName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('AsynchronousCommit','SynchronousCommit')]
        [String]
        $AvailabilityMode = 'AsynchronousCommit',

        [Parameter()]
        [ValidateRange(0,100)]
        [UInt32]
        $BackupPriority = 50,

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
        [ValidateSet('Automatic','Manual')]
        [String]
        $FailoverMode = 'Manual',

        [Parameter()]
        [String]
        $ReadOnlyRoutingConnectionUrl,

        [Parameter()]
        [String[]]
        $ReadOnlyRoutingList
    )
    
    Import-SQLPSModule
    
    # Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    # Determine if HADR is enabled on the instance. If not, throw an error
    if ( -not $serverObject.IsHadrEnabled )
    {
        throw New-TerminatingError -ErrorType HadrNotEnabled -FormatArgs $Ensure,$SQLInstanceName -ErrorCategory NotImplemented
    }

    # Get the Availabilty Group if it exists
    $availabilityGroup = $serverObject.AvailabilityGroups[$AvailabilityGroupName]

    switch ( $Ensure )
    {
        Absent
        {
            if ( $availabilityGroup )
            {
                $availabilityGroupReplica = $availabilityGroup.AvailabilityGroupReplicas[$Name]

                if ( $availabilityGroupReplica )
                {
                    # Make sure the primary replica is not the replica we're trying to remove
                    if ( $availabilityGroup.PrimaryReplicaServerName -ne $Name )
                    {
                        try
                        {
                            Remove-SqlAvailabilityReplica -InputObject $availabilityGroupReplica -Confirm:$true -ErrorAction Stop
                        }
                        catch
                        {
                            throw New-TerminatingError -ErrorType RemoveAvailabilityGroupReplicaFailed -FormatArgs $Name, $SQLInstanceName -ErrorCategory ResourceUnavailable
                        }
                    }
                    else
                    {
                        throw New-TerminatingError -ErrorType InstanceIsPrimaryReplica -FormatArgs $Name, $SQLInstanceName -ErrorCategory ResourceUnavailable
                    }
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
                if ( $serverObject.Logins[$loginName] )
                {
                    if ( -not $clusterPermissionsPresent )
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
                else
                {
                    switch ( $loginName )
                    {
                        $clusterServiceName
                        {
                            New-VerboseMessage -Message "The recommended login '$loginName' does not exist. Trying with '$ntAuthoritySystemName'."
                        }

                        $ntAuthoritySystemName
                        {
                            New-VerboseMessage -Message "The login '$loginName' does not exist."
                        }
                    }
                }
            }

            # If neither 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' have the required permissions, throw an error.
            if ( -not $clusterPermissionsPresent )
            {
                throw New-TerminatingError -ErrorType ClusterPermissionsMissing -FormatArgs $SQLServer,$SQLInstanceName -ErrorCategory SecurityError
            }

            # Make sure a database mirroring endpoint exists.
            $endpoint = $serverObject.Endpoints | Where-Object { $_.EndpointType -eq 'DatabaseMirroring' }
            if ( -not $endpoint )
            {
                throw New-TerminatingError -ErrorType DatabaseMirroringEndpointNotFound -FormatArgs $SQLServer,$SQLInstanceName -ErrorCategory ObjectNotFound
            }

            # If a hostname for the endpoint was not specified, define it now.
            if ( -not $EndpointHostName )
            {
                $EndpointHostName = $serverObject.NetName
            }
            
            # Determine if the Availabilty Group exists on the instance
            if ( $availabilityGroup )
            {
                # Make sure the replia exists on the instance. If the availability group exists, the replica should exist.
                $availabilityGroupReplica = $availabilityGroup.AvailabilityReplicas[$Name]
                if ( $availabilityGroupReplica )
                {
                    if ( $AvailabilityMode -ne $availabilityGroupReplica.AvailabilityMode )
                    {
                        $availabilityGroupReplica.AvailabilityMode = $AvailabilityMode
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    if ( $BackupPriority -ne $availabilityGroupReplica.BackupPriority )
                    {
                        $availabilityGroupReplica.BackupPriority = $BackupPriority
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    # Make sure ConnectionModeInPrimaryRole has a value in order to avoid false positive matches when the parameter is not defined
                    if ( ( -not [string]::IsNullOrEmpty($ConnectionModeInPrimaryRole) ) -and ( $ConnectionModeInPrimaryRole -ne $availabilityGroupReplica.ConnectionModeInPrimaryRole ) )
                    {
                        $availabilityGroupReplica.ConnectionModeInPrimaryRole = $ConnectionModeInPrimaryRole
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    # Make sure ConnectionModeInSecondaryRole has a value in order to avoid false positive matches when the parameter is not defined
                    if ( ( -not [string]::IsNullOrEmpty($ConnectionModeInSecondaryRole) ) -and ( $ConnectionModeInSecondaryRole -ne $availabilityGroupReplica.ConnectionModeInSecondaryRole ) )
                    {
                        $availabilityGroupReplica.ConnectionModeInSecondaryRole = $ConnectionModeInSecondaryRole
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    # Break out the EndpointUrl properties
                    $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $availabilityGroupReplica.EndpointUrl.Replace('//','').Split(':')

                    if ( $endpoint.Protocol.Tcp.ListenerPort -ne $currentEndpointPort )
                    {
                        $newEndpointUrl = availabilityGroupReplica.EndpointUrl.Replace($currentEndpointPort,$endpoint.Protocol.Tcp.ListenerPort)
                        $availabilityGroupReplica.EndpointUrl = $newEndpointUrl
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    if ( $EndpointHostName -ne $currentEndpointHostName )
                    {
                        $newEndpointUrl = $availabilityGroupReplica.EndpointUrl.Replace($currentEndpointHostName,$EndpointHostName)
                        $availabilityGroupReplica.EndpointUrl = $newEndpointUrl
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    if ( $currentEndpointProtocol -ne 'TCP' )
                    {
                        $newEndpointUrl = $availabilityGroupReplica.EndpointUrl.Replace($currentEndpointProtocol,'TCP')
                        $availabilityGroupReplica.EndpointUrl = $newEndpointUrl
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    if ( $FailoverMode -ne $availabilityGroupReplica.FailoverMode )
                    {
                        $availabilityGroupReplica.FailoverMode = $FailoverMode
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    if ( $ReadOnlyRoutingConnectionUrl -ne $availabilityGroupReplica.ReadOnlyRoutingConnectionUrl )
                    {
                        $availabilityGroupReplica.ReadOnlyRoutingConnectionUrl = $ReadOnlyRoutingConnectionUrl
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    if ( $ReadOnlyRoutingList -ne $availabilityGroupReplica.ReadOnlyRoutingList )
                    {
                        $availabilityGroupReplica.ReadOnlyRoutingList = $ReadOnlyRoutingList
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }
                }
                else
                {
                    throw New-TerminatingError -ErrorType ReplicaNotFound -FormatArgs $Name,$SQLInstanceName -ErrorCategory ResourceUnavailable
                }
            }
            else
            {
                # Connect to the instance that is supposed to house the primary replica
                $primaryReplicaServerObject = Connect-SQL -SQLServer $PrimaryReplicaSQLServer -SQLInstanceName $PrimaryReplicaSQLInstanceName

                # Verify the Availability Group exists on the supplied primary replica
                $primaryReplicaAvailabilityGroup = $primaryReplicaServerObject.AvailabilityGroups[$AvailabilityGroupName]
                if ( $primaryReplicaAvailabilityGroup )
                {
                    # Make sure the instance defined as the primary replica in the parameters is actually the primary replica
                    if ( $primaryReplicaAvailabilityGroup.LocalReplicaRole -ne 'Primary' )
                    {
                        New-VerboseMessage -Message "The instance '$PrimaryReplicaSQLInstanceName' is not currently the primary replica. Connecting to '$($primaryReplicaAvailabilityGroup.PrimaryReplicaServerName)'."
                        
                        $primaryReplicaServerObject = Connect-SQL -SQLServer $primaryReplicaAvailabilityGroup.PrimaryReplicaServerName
                        $primaryReplicaAvailabilityGroup = $primaryReplicaServerObject.AvailabilityGroups[$AvailabilityGroupName]
                    }

                    ################# EndpointUrl ########################

                    $newAvailabilityGroupReplicaParams = @{
                        Name = $Name
                        InputObject = $primaryReplicaAvailabilityGroup
                        AvailabilityMode = $AvailabilityMode
                        EndpointUrl = $EndpointUrl
                        FailoverMode = $FailoverMode
                        Verbose = $false
                    }

                    if ( $BackupPriority )
                    {
                        $newAvailabilityGroupReplicaParams.Add('BackupPriority',$BackupPriority)
                    }

                    if ( $ConnectionModeInPrimaryRole )
                    {
                        $newAvailabilityGroupReplicaParams.Add('ConnectionModeInPrimaryRole',$ConnectionModeInPrimaryRole)
                    }

                    if ( $ConnectionModeInSecondaryRole )
                    {
                        $newAvailabilityGroupReplicaParams.Add('ConnectionModeInSecondaryRole',$ConnectionModeInSecondaryRole)
                    }
                    
                    if ( $ReadOnlyRoutingConnectionUrl )
                    {
                        $newAvailabilityGroupReplicaParams.Add('ReadOnlyConnectionUrl',$ReadOnlyRoutingConnectionUrl)
                    }

                    if ( $ReadOnlyRoutingList )
                    {
                        $newAvailabilityGroupReplicaParams.Add('ReadOnlyRoutingList',$ReadOnlyRoutingList)
                    }
                    
                    # Create the Availability Group Replica
                    try
                    {
                        $availabilityGroupReplica = New-SqlAvailabilityReplica @newAvailabilityReplicaParams
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType CreateAvailabilityGroupReplicaFailed -FormatArgs $Name,$SQLInstanceName -ErrorCategory OperationStopped
                    }

                    # Join the Availability Group Replica to the Availability Group
                    try
                    {
                        $joinAvailabilityGroupResults = Join-SqlAvailabilityGroup -Name $Name -InputObject $serverObject
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType JoinAvailabilityGroupFailed -FormatArgs $Name,$SQLInstanceName -ErrorCategory OperationStopped
                    }
                }
                # The Availability Group doesn't exist on the primary replica
                else
                {
                    throw New-TerminatingError -ErrorType AvailabilityGroupNotFound -FormatArgs $Name,$PrimaryReplicaSQLInstanceName -ErrorCategory ResourceUnavailable
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Determines if the availability group replica is in the desired state.
    
    .PARAMETER Name
        The name of the availability group replica.

    .PARAMETER AvailabilityGroupName
        The name of the availability group.

    .PARAMETER SQLServer
        Hostname of the SQL Server to be configured.
    
    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configued.
    
    .PARAMETER PrimaryReplicaSQLServer
        Hostname of the SQL Server where the primary replica lives.
    
    .PARAMETER PrimaryReplicaSQLInstanceName
        Name of the SQL instance where the primary replica lives.

    .PARAMETER Ensure
        Specifies if the availability group should be present or absent. Default is Present.

    .PARAMETER AvailabilityMode
        Specifies the replica availability mode. Default is 'AsynchronousCommit'.

    .PARAMETER BackupPriority
        Specifies the desired priority of the replicas in performing backups. The acceptable values for this parameter are integers from 0 through 100. Of the set of replicas which are online and available, the replica that has the highest priority performs the backup. Default is 50.

    .PARAMETER ConnectionModeInPrimaryRole
        Specifies how the availability replica handles connections when in the primary role.

    .PARAMETER ConnectionModeInSecondaryRole
        Specifies how the availability replica handles connections when in the secondary role.

    .PARAMETER EndpointHostName
        Specifies the hostname or IP address of the availability group replica endpoint. Default is the instance network name.

    .PARAMETER FailoverMode
        Specifies the failover mode. Default is Manual.
    
    .PARAMETER ReadOnlyRoutingConnectionUrl
        Specifies the fully-qualified domain name (FQDN) and port to use when routing to the replica for read only connections.

    .PARAMETER ReadOnlyRoutingList
        Specifies an ordered list of replica server names that represent the probe sequence for connection director to use when redirecting read-only connections through this availability replica. This parameter applies if the availability replica is the current primary replica of the availability group.
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

        [parameter(Mandatory = $true)]
        [String]
        $AvailabilityGroupName,
        
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLInstanceName,

        [Parameter()]
        [String]
        $PrimaryReplicaSQLServer,

        [Parameter()]
        [String]
        $PrimaryReplicaSQLInstanceName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('AsynchronousCommit','SynchronousCommit')]
        [String]
        $AvailabilityMode = 'AsynchronousCommit',

        [Parameter()]
        [ValidateRange(0,100)]
        [UInt32]
        $BackupPriority = 50,

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
        [ValidateSet('Automatic','Manual')]
        [String]
        $FailoverMode = 'Manual',

        [Parameter()]
        [String]
        $ReadOnlyRoutingConnectionUrl,

        [Parameter()]
        [String[]]
        $ReadOnlyRoutingList
    )

    $getTargetResourceParameters = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer = $SQLServer
        Name = $Name
        AvailabilityGroupName = $AvailabilityGroupName
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
                'AvailabilityGroupName',
                'SQLServer',
                'SQLInstanceName',
                'Ensure',
                'AvailabilityMode',
                'BackupPriority',
                'ConnectionModeInPrimaryRole',
                'ConnectionModeInSecondaryRole',
                'FailoverMode',
                'ReadOnlyRoutingConnectionUrl',
                'ReadOnlyRoutingList'
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
