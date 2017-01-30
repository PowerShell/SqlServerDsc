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
        $availabilityGroupReplica = $availabilityGroup.AvailabilityGroupReplicas[$Name]

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
    
    .PARAMETER ReadOnlyRoutingUrl
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
        $ReadOnlyRoutingUrl,

        [Parameter()]
        [String[]]
        $ReadOnlyRoutingList
    )
    
    Import-SQLPSModule
    
    # Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
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
    
    .PARAMETER ReadOnlyRoutingUrl
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
        $ReadOnlyRoutingUrl,

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
                'ReadOnlyRoutingUrl',
                'ReadOnlyRoutingList'
            )
            
            if ( $getTargetResourceResult.Ensure -eq 'Present' )
            {
                foreach ( $psBoundParameter in $PSBoundParameters.GetEnumerator() )
                {
                    # Make sure we don't try to validate a common parameter
                    if ( $parametersToCheck -notcontains $psBoundParameter.Key )
                    {
                        continue
                    }
                    
                    if ( $getTargetResourceResult.($psBoundParameter.Key) -ne $psBoundParameter.Value )
                    {
                        if ( $psBoundParameter.Key -eq 'BasicAvailabilityGroup' )
                        {                          
                            # Move on to the next property if the instance is not at least SQL Server 2016
                            if ( $getTargetResourceResult.Version -lt 13 )
                            {
                                continue
                            }
                        }
                        
                        New-VerboseMessage -Message "'$($psBoundParameter.Key)' should be '$($psBoundParameter.Value)' but is '$($getTargetResourceResult.($psBoundParameter.Key))'"
                        
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

Export-ModuleMember -Function *-TargetResource
