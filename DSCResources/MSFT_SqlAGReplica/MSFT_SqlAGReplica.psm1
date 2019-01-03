Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force

<#
    .SYNOPSIS
        Gets the specified Availability Group Replica from the specified Availability Group.

    .PARAMETER Name
        The name of the availability group replica. For named instances this
        must be in the following format ServerName\InstanceName.

    .PARAMETER AvailabilityGroupName
        The name of the availability group.

    .PARAMETER ServerName
        Hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        Name of the SQL instance to be configured.
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
        $AvailabilityGroupName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    # Connect to the instance
    $serverObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    # Is this node actively hosting the SQL instance?
    $isActiveNode = Test-ActiveNode -ServerObject $serverObject

    # Get the endpoint properties
    $endpoint = $serverObject.Endpoints | Where-Object { $_.EndpointType -eq 'DatabaseMirroring' }
    if ( $endpoint )
    {
        $endpointPort = $endpoint.Protocol.Tcp.ListenerPort
    }

    # Create the return object
    $alwaysOnAvailabilityGroupReplicaResource = @{
        Ensure                        = 'Absent'
        Name                          = ''
        AvailabilityGroupName         = ''
        AvailabilityMode              = ''
        BackupPriority                = ''
        ConnectionModeInPrimaryRole   = ''
        ConnectionModeInSecondaryRole = ''
        FailoverMode                  = ''
        EndpointUrl                   = ''
        IsActiveNode                  = $isActiveNode
        ReadOnlyRoutingConnectionUrl  = ''
        ReadOnlyRoutingList           = @()
        ServerName                    = $ServerName
        InstanceName                  = $InstanceName
        EndpointPort                  = $endpointPort
        EndpointHostName              = $serverObject.NetName
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
            $alwaysOnAvailabilityGroupReplicaResource.ReadOnlyRoutingConnectionUrl = $availabilityGroupReplica.ReadOnlyRoutingConnectionUrl
            $alwaysOnAvailabilityGroupReplicaResource.ReadOnlyRoutingList = $availabilityGroupReplica.ReadOnlyRoutingList
        }
    }

    return $alwaysOnAvailabilityGroupReplicaResource
}

<#
    .SYNOPSIS
        Creates or removes the availability group replica in accordance with the desired state.

    .PARAMETER Name
        The name of the availability group replica. For named instances this
        must be in the following format ServerName\InstanceName.

    .PARAMETER AvailabilityGroupName
        The name of the availability group.

    .PARAMETER ServerName
        Hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        Name of the SQL instance to be configured.

    .PARAMETER PrimaryReplicaServerName
        Hostname of the SQL Server where the primary replica is expected to be active. If the primary replica is not found here, the resource will attempt to find the host that holds the primary replica and connect to it.

    .PARAMETER PrimaryReplicaInstanceName
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
        Specifies the hostname or IP address of the availability group replica endpoint. Default is the instance network name which is set in the code because the value can only be determined when connected to the SQL Instance.

    .PARAMETER FailoverMode
        Specifies the failover mode. Default is Manual.

    .PARAMETER ReadOnlyRoutingConnectionUrl
        Specifies the fully-qualified domain name (FQDN) and port to use when routing to the replica for read only connections.

    .PARAMETER ReadOnlyRoutingList
        Specifies an ordered list of replica server names that represent the probe sequence for connection director to use when redirecting read-only connections through this availability replica. This parameter applies if the availability replica is the current primary replica of the availability group.

    .PARAMETER ProcessOnlyOnActiveNode
        Specifies that the resource will only determine if a change is needed if the target node is the active host of the SQL Server Instance.
        Not used in Set-TargetResource.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $PrimaryReplicaServerName,

        [Parameter()]
        [System.String]
        $PrimaryReplicaInstanceName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('AsynchronousCommit', 'SynchronousCommit')]
        [System.String]
        $AvailabilityMode = 'AsynchronousCommit',

        [Parameter()]
        [ValidateRange(0, 100)]
        [System.UInt32]
        $BackupPriority = 50,

        [Parameter()]
        [ValidateSet('AllowAllConnections', 'AllowReadWriteConnections')]
        [System.String]
        $ConnectionModeInPrimaryRole,

        [Parameter()]
        [ValidateSet('AllowNoConnections', 'AllowReadIntentConnectionsOnly', 'AllowAllConnections')]
        [System.String]
        $ConnectionModeInSecondaryRole,

        [Parameter()]
        [System.String]
        $EndpointHostName,

        [Parameter()]
        [ValidateSet('Automatic', 'Manual')]
        [System.String]
        $FailoverMode = 'Manual',

        [Parameter()]
        [System.String]
        $ReadOnlyRoutingConnectionUrl,

        [Parameter()]
        [System.String[]]
        $ReadOnlyRoutingList,

        [Parameter()]
        [System.Boolean]
        $ProcessOnlyOnActiveNode
    )

    Import-SQLPSModule

    # Connect to the instance
    $serverObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    # Determine if HADR is enabled on the instance. If not, throw an error
    if ( -not $serverObject.IsHadrEnabled )
    {
        throw New-TerminatingError -ErrorType HadrNotEnabled -FormatArgs $Ensure, $InstanceName -ErrorCategory NotImplemented
    }

    # Get the Availability Group if it exists
    $availabilityGroup = $serverObject.AvailabilityGroups[$AvailabilityGroupName]

    # Make sure we're communicating with the primary replica in order to make changes to the replica
    if ( $availabilityGroup )
    {
        while ( $availabilityGroup.LocalReplicaRole -ne 'Primary' )
        {
            $primaryServerObject = Get-PrimaryReplicaServerObject -ServerObject $serverObject -AvailabilityGroup $availabilityGroup
            $availabilityGroup = $primaryServerObject.AvailabilityGroups[$AvailabilityGroupName]
        }
    }

    switch ( $Ensure )
    {
        Absent
        {
            if ( $availabilityGroup )
            {
                $availabilityGroupReplica = $availabilityGroup.AvailabilityReplicas[$Name]

                if ( $availabilityGroupReplica )
                {
                    try
                    {
                        Remove-SqlAvailabilityReplica -InputObject $availabilityGroupReplica -Confirm:$false -ErrorAction Stop
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType RemoveAvailabilityGroupReplicaFailed -FormatArgs $Name -ErrorCategory ResourceUnavailable -InnerException $_.Exception
                    }
                }
            }
        }

        Present
        {
            # Ensure the appropriate cluster permissions are present
            Test-ClusterPermissions -ServerObject $serverObject

            # Make sure a database mirroring endpoint exists.
            $endpoint = $serverObject.Endpoints | Where-Object { $_.EndpointType -eq 'DatabaseMirroring' }
            if ( -not $endpoint )
            {
                throw New-TerminatingError -ErrorType DatabaseMirroringEndpointNotFound -FormatArgs $ServerName, $InstanceName -ErrorCategory ObjectNotFound
            }

            # If a hostname for the endpoint was not specified, define it now.
            if ( -not $EndpointHostName )
            {
                $EndpointHostName = $serverObject.NetName
            }

            # Get the endpoint port
            $endpointPort = $endpoint.Protocol.Tcp.ListenerPort

            # Determine if the Availability Group exists on the instance
            if ( $availabilityGroup )
            {
                # Make sure the replica exists on the instance. If the availability group exists, the replica should exist.
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
                    if ( ( -not [System.String]::IsNullOrEmpty($ConnectionModeInPrimaryRole) ) -and ( $ConnectionModeInPrimaryRole -ne $availabilityGroupReplica.ConnectionModeInPrimaryRole ) )
                    {
                        $availabilityGroupReplica.ConnectionModeInPrimaryRole = $ConnectionModeInPrimaryRole
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    # Make sure ConnectionModeInSecondaryRole has a value in order to avoid false positive matches when the parameter is not defined
                    if ( ( -not [System.String]::IsNullOrEmpty($ConnectionModeInSecondaryRole) ) -and ( $ConnectionModeInSecondaryRole -ne $availabilityGroupReplica.ConnectionModeInSecondaryRole ) )
                    {
                        $availabilityGroupReplica.ConnectionModeInSecondaryRole = $ConnectionModeInSecondaryRole
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    # Break out the EndpointUrl properties
                    $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $availabilityGroupReplica.EndpointUrl.Replace('//', '').Split(':')

                    if ( $endpoint.Protocol.Tcp.ListenerPort -ne $currentEndpointPort )
                    {
                        $newEndpointUrl = $availabilityGroupReplica.EndpointUrl.Replace($currentEndpointPort, $endpoint.Protocol.Tcp.ListenerPort)
                        $availabilityGroupReplica.EndpointUrl = $newEndpointUrl
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    if ( $EndpointHostName -ne $currentEndpointHostName )
                    {
                        $newEndpointUrl = $availabilityGroupReplica.EndpointUrl.Replace($currentEndpointHostName, $EndpointHostName)
                        $availabilityGroupReplica.EndpointUrl = $newEndpointUrl
                        Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroupReplica
                    }

                    if ( $currentEndpointProtocol -ne 'TCP' )
                    {
                        $newEndpointUrl = $availabilityGroupReplica.EndpointUrl.Replace($currentEndpointProtocol, 'TCP')
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
                    throw New-TerminatingError -ErrorType ReplicaNotFound -FormatArgs $Name, $InstanceName -ErrorCategory ResourceUnavailable
                }
            }
            else
            {
                # Connect to the instance that is supposed to house the primary replica
                $primaryReplicaServerObject = Connect-SQL -ServerName $PrimaryReplicaServerName -InstanceName $PrimaryReplicaInstanceName

                # Verify the Availability Group exists on the supplied primary replica
                $primaryReplicaAvailabilityGroup = $primaryReplicaServerObject.AvailabilityGroups[$AvailabilityGroupName]
                if ( $primaryReplicaAvailabilityGroup )
                {
                    # Make sure the instance defined as the primary replica in the parameters is actually the primary replica
                    $primaryReplicaServerObject = Get-PrimaryReplicaServerObject -ServerObject $primaryReplicaServerObject -AvailabilityGroup $primaryReplicaAvailabilityGroup
                    $availabilityGroup = $primaryReplicaServerObject.AvailabilityGroups[$AvailabilityGroupName]

                    # Build the endpoint URL
                    $endpointUrl = "TCP://$($EndpointHostName):$($endpointPort)"

                    $newAvailabilityGroupReplicaParams = @{
                        Name             = $Name
                        InputObject      = $primaryReplicaAvailabilityGroup
                        AvailabilityMode = $AvailabilityMode
                        EndpointUrl      = $endpointUrl
                        FailoverMode     = $FailoverMode
                        Verbose          = $false
                    }

                    if ( $BackupPriority )
                    {
                        $newAvailabilityGroupReplicaParams.Add('BackupPriority', $BackupPriority)
                    }

                    if ( $ConnectionModeInPrimaryRole )
                    {
                        $newAvailabilityGroupReplicaParams.Add('ConnectionModeInPrimaryRole', $ConnectionModeInPrimaryRole)
                    }

                    if ( $ConnectionModeInSecondaryRole )
                    {
                        $newAvailabilityGroupReplicaParams.Add('ConnectionModeInSecondaryRole', $ConnectionModeInSecondaryRole)
                    }

                    if ( $ReadOnlyRoutingConnectionUrl )
                    {
                        $newAvailabilityGroupReplicaParams.Add('ReadOnlyRoutingConnectionUrl', $ReadOnlyRoutingConnectionUrl)
                    }

                    if ( $ReadOnlyRoutingList )
                    {
                        $newAvailabilityGroupReplicaParams.Add('ReadOnlyRoutingList', $ReadOnlyRoutingList)
                    }

                    # Create the Availability Group Replica
                    try
                    {
                        $availabilityGroupReplica = New-SqlAvailabilityReplica @newAvailabilityGroupReplicaParams
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType CreateAvailabilityGroupReplicaFailed -FormatArgs $Name, $InstanceName -ErrorCategory OperationStopped -InnerException $_.Exception
                    }

                    # Join the Availability Group Replica to the Availability Group
                    try
                    {
                        Join-SqlAvailabilityGroup -Name $AvailabilityGroupName -InputObject $serverObject | Out-Null
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType JoinAvailabilityGroupFailed -FormatArgs $Name -ErrorCategory OperationStopped -InnerException $_.Exception
                    }
                }
                # The Availability Group doesn't exist on the primary replica
                else
                {
                    throw New-TerminatingError -ErrorType AvailabilityGroupNotFound -FormatArgs $AvailabilityGroupName, $PrimaryReplicaInstanceName -ErrorCategory ResourceUnavailable
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Determines if the availability group replica is in the desired state.

    .PARAMETER Name
        The name of the availability group replica. For named instances this
        must be in the following format ServerName\InstanceName.

    .PARAMETER AvailabilityGroupName
        The name of the availability group.

    .PARAMETER ServerName
        Hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        Name of the SQL instance to be configured.

    .PARAMETER PrimaryReplicaServerName
        Hostname of the SQL Server where the primary replica is expected to be active. If the primary replica is not found here, the resource will attempt to find the host that holds the primary replica and connect to it.

    .PARAMETER PrimaryReplicaInstanceName
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
        Specifies the hostname or IP address of the availability group replica endpoint. Default is the instance network name which is set in the code because the value can only be determined when connected to the SQL Instance.

    .PARAMETER FailoverMode
        Specifies the failover mode. Default is Manual.

    .PARAMETER ReadOnlyRoutingConnectionUrl
        Specifies the fully-qualified domain name (FQDN) and port to use when routing to the replica for read only connections.

    .PARAMETER ReadOnlyRoutingList
        Specifies an ordered list of replica server names that represent the probe sequence for connection director to use when redirecting read-only connections through this availability replica. This parameter applies if the availability replica is the current primary replica of the availability group.

    .PARAMETER ProcessOnlyOnActiveNode
        Specifies that the resource will only determine if a change is needed if the target node is the active host of the SQL Server Instance.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $PrimaryReplicaServerName,

        [Parameter()]
        [System.String]
        $PrimaryReplicaInstanceName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('AsynchronousCommit', 'SynchronousCommit')]
        [System.String]
        $AvailabilityMode = 'AsynchronousCommit',

        [Parameter()]
        [ValidateRange(0, 100)]
        [System.UInt32]
        $BackupPriority = 50,

        [Parameter()]
        [ValidateSet('AllowAllConnections', 'AllowReadWriteConnections')]
        [System.String]
        $ConnectionModeInPrimaryRole,

        [Parameter()]
        [ValidateSet('AllowNoConnections', 'AllowReadIntentConnectionsOnly', 'AllowAllConnections')]
        [System.String]
        $ConnectionModeInSecondaryRole,

        [Parameter()]
        [System.String]
        $EndpointHostName,

        [Parameter()]
        [ValidateSet('Automatic', 'Manual')]
        [System.String]
        $FailoverMode = 'Manual',

        [Parameter()]
        [System.String]
        $ReadOnlyRoutingConnectionUrl,

        [Parameter()]
        [System.String[]]
        $ReadOnlyRoutingList,

        [Parameter()]
        [System.Boolean]
        $ProcessOnlyOnActiveNode
    )

    $getTargetResourceParameters = @{
        InstanceName          = $InstanceName
        ServerName            = $ServerName
        Name                  = $Name
        AvailabilityGroupName = $AvailabilityGroupName
    }

    # Assume this will pass. We will determine otherwise later
    $result = $true

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    <#
        If this is supposed to process only the active node, and this is not the
        active node, don't bother evaluating the test.
    #>
    if ( $ProcessOnlyOnActiveNode -and -not $getTargetResourceResult.IsActiveNode )
    {
        # Use localization if the resource has been converted
        New-VerboseMessage -Message ( 'The node "{0}" is not actively hosting the instance "{1}". Exiting the test.' -f $env:COMPUTERNAME, $InstanceName )
        return $result
    }

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
                'ServerName',
                'InstanceName',
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
                    if ( $parametersToCheck -contains $parameterName )
                    {
                        # If the parameter is Null, a value wasn't provided
                        if ( -not [System.String]::IsNullOrEmpty($parameterValue) )
                        {
                            if ( $getTargetResourceResult.($parameterName) -ne $parameterValue )
                            {
                                New-VerboseMessage -Message "'$($parameterName)' should be '$($parameterValue)' but is '$($getTargetResourceResult.($parameterName))'"

                                $result = $false
                            }
                        }
                    }
                }

                # Get the Endpoint URL properties
                $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $getTargetResourceResult.EndpointUrl.Replace('//', '').Split(':')

                if ( -not $EndpointHostName )
                {
                    $EndpointHostName = $getTargetResourceResult.EndpointHostName
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
