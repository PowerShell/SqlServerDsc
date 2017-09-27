Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'xSQLServerHelper.psm1') `
    -Force

<#
    .SYNOPSIS
        Gets the specified Availability Group.

    .PARAMETER Name
        The name of the availability group.

    .PARAMETER SQLServer
        Hostname of the SQL Server to be configured.

    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configured.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
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

    # Define current version for check compatibility
    $sqlMajorVersion = $serverObject.Version.Major

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
            Name                          = $Name
            SQLServer                     = $SQLServer
            SQLInstanceName               = $SQLInstanceName
            Ensure                        = 'Present'
            AutomatedBackupPreference     = $availabilityGroup.AutomatedBackupPreference
            AvailabilityMode              = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].AvailabilityMode
            BackupPriority                = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].BackupPriority
            ConnectionModeInPrimaryRole   = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].ConnectionModeInPrimaryRole
            ConnectionModeInSecondaryRole = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].ConnectionModeInSecondaryRole
            FailureConditionLevel         = $availabilityGroup.FailureConditionLevel
            FailoverMode                  = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].FailoverMode
            HealthCheckTimeout            = $availabilityGroup.HealthCheckTimeout
            EndpointURL                   = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].EndpointUrl
            EndpointPort                  = $endpointPort
            SQLServerNetName              = $serverObject.NetName
            Version                       = $sqlMajorVersion
        }

        # Add properties that are only present in SQL 2016 or newer
        if ( $sqlMajorVersion -ge 13 )
        {
            $alwaysOnAvailabilityGroupResource.Add('BasicAvailabilityGroup', $availabilityGroup.BasicAvailabilityGroup)
            $alwaysOnAvailabilityGroupResource.Add('DatabaseHealthTrigger', $availabilityGroup.DatabaseHealthTrigger)
            $alwaysOnAvailabilityGroupResource.Add('DtcSupportEnabled', $availabilityGroup.DtcSupportEnabled)
        }
    }
    else
    {
        # Return the minimum amount of properties showing that the Availability Group is absent
        $alwaysOnAvailabilityGroupResource = @{
            Name            = $Name
            SQLServer       = $SQLServer
            SQLInstanceName = $SQLInstanceName
            Ensure          = 'Absent'
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
        Name of the SQL instance to be configured.

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

    .PARAMETER DatabaseHealthTrigger
        Specifies if the option Database Level Health Detection is enabled. This is only available is SQL Server 2016 and later and is ignored when applied to previous versions.

    .PARAMETER DtcSupportEnabled
        Specifies if the option Database DTC Support is enabled. This is only available is SQL Server 2016 and later and is ignored when applied to previous versions. This can't be altered once the Availability Group is created and is ignored if it is the case.

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
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('Primary', 'SecondaryOnly', 'Secondary', 'None')]
        [String]
        $AutomatedBackupPreference = 'None',

        [Parameter()]
        [ValidateSet('AsynchronousCommit', 'SynchronousCommit')]
        [String]
        $AvailabilityMode = 'AsynchronousCommit',

        [Parameter()]
        [ValidateRange(0, 100)]
        [UInt32]
        $BackupPriority = 50,

        [Parameter()]
        [Boolean]
        $BasicAvailabilityGroup,

        [Parameter()]
        [Boolean]
        $DatabaseHealthTrigger,

        [Parameter()]
        [Boolean]
        $DtcSupportEnabled,

        [Parameter()]
        [ValidateSet('AllowAllConnections', 'AllowReadWriteConnections')]
        [String]
        $ConnectionModeInPrimaryRole,

        [Parameter()]
        [ValidateSet('AllowNoConnections', 'AllowReadIntentConnectionsOnly', 'AllowAllConnections')]
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
        [ValidateSet('Automatic', 'Manual')]
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
        throw New-TerminatingError -ErrorType HadrNotEnabled -FormatArgs $Ensure, $SQLInstanceName -ErrorCategory NotImplemented
    }

    # Define current version for check compatibility
    $sqlMajorVersion = $serverObject.Version.Major

    # Get the Availability Group if it exists
    $availabilityGroup = $serverObject.AvailabilityGroups[$Name]

    switch ($Ensure)
    {
        Absent
        {
            # If the AG exists
            if ( $availabilityGroup )
            {
                # If the primary replica is currently on this instance
                if ( $availabilityGroup.PrimaryReplicaServerName -eq $serverObject.DomainInstanceName )
                {
                    try
                    {
                        Remove-SqlAvailabilityGroup -InputObject $availabilityGroup -ErrorAction Stop
                    }
                    catch
                    {
                        throw New-TerminatingError -ErrorType RemoveAvailabilityGroupFailed -FormatArgs $availabilityGroup.Name, $SQLInstanceName -ErrorCategory ResourceUnavailable -InnerException $_.Exception
                    }
                }
                else
                {
                    throw New-TerminatingError -ErrorType InstanceNotPrimaryReplica -FormatArgs $SQLInstanceName, $availabilityGroup.Name -ErrorCategory ResourceUnavailable
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
                throw New-TerminatingError -ErrorType DatabaseMirroringEndpointNotFound -FormatArgs $SQLServer, $SQLInstanceName -ErrorCategory ObjectNotFound
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
                    Name             = $serverObject.DomainInstanceName
                    Version          = $sqlMajorVersion
                    AsTemplate       = $true
                    AvailabilityMode = $AvailabilityMode
                    EndpointUrl      = "TCP://$($EndpointHostName):$($endpoint.Protocol.Tcp.ListenerPort)"
                    FailoverMode     = $FailoverMode
                }

                if ( $BackupPriority )
                {
                    $newReplicaParams.Add('BackupPriority', $BackupPriority)
                }

                if ( $ConnectionModeInPrimaryRole )
                {
                    $newReplicaParams.Add('ConnectionModeInPrimaryRole', $ConnectionModeInPrimaryRole)
                }

                if ( $ConnectionModeInSecondaryRole )
                {
                    $newReplicaParams.Add('ConnectionModeInSecondaryRole', $ConnectionModeInSecondaryRole)
                }

                # Create the new replica object
                try
                {
                    $primaryReplica = New-SqlAvailabilityReplica @newReplicaParams -ErrorAction Stop
                }
                catch
                {
                    throw New-TerminatingError -ErrorType CreateAvailabilityGroupReplicaFailed -FormatArgs $newReplicaParams.Name, $SQLInstanceName -ErrorCategory OperationStopped -InnerException $_.Exception
                }

                # Set up the parameters for the new availability group
                $newAvailabilityGroupParams = @{
                    InputObject         = $serverObject
                    Name                = $Name
                    AvailabilityReplica = $primaryReplica
                }

                if ( $AutomatedBackupPreference )
                {
                    $newAvailabilityGroupParams.Add('AutomatedBackupPreference', $AutomatedBackupPreference)
                }

                if ( $sqlMajorVersion -ge 13 )
                {
                    $newAvailabilityGroupParams.Add('BasicAvailabilityGroup', $BasicAvailabilityGroup)
                    $newAvailabilityGroupParams.Add('DatabaseHealthTrigger', $DatabaseHealthTrigger)
                    $newAvailabilityGroupParams.Add('DtcSupportEnabled', $DtcSupportEnabled)
                }

                if ( $FailureConditionLevel )
                {
                    $newAvailabilityGroupParams.Add('FailureConditionLevel', $FailureConditionLevel)
                }

                if ( $HealthCheckTimeout )
                {
                    $newAvailabilityGroupParams.Add('HealthCheckTimeout', $HealthCheckTimeout)
                }

                # Create the Availability Group
                try
                {
                    New-SqlAvailabilityGroup @newAvailabilityGroupParams -ErrorAction Stop
                }
                catch
                {
                    throw New-TerminatingError -ErrorType CreateAvailabilityGroupFailed -FormatArgs $Name -ErrorCategory OperationStopped -InnerException $_.Exception
                }
            }
            # Otherwise let's check each of the parameters passed and update the Availability Group accordingly
            else
            {
                # Make sure we're communicating with the primary replica
                $primaryServerObject = Get-PrimaryReplicaServerObject -ServerObject $serverObject -AvailabilityGroup $availabilityGroup
                $availabilityGroup = $primaryServerObject.AvailabilityGroups[$Name]

                if ( $AutomatedBackupPreference -ne $availabilityGroup.AutomatedBackupPreference )
                {
                    $availabilityGroup.AutomatedBackupPreference = $AutomatedBackupPreference
                    Update-AvailabilityGroup -AvailabilityGroup $availabilityGroup
                }

                if ( $AvailabilityMode -ne $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].AvailabilityMode )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].AvailabilityMode = $AvailabilityMode
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName]
                }

                if ( $BackupPriority -ne $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].BackupPriority )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].BackupPriority = $BackupPriority
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName]
                }

                if ( ( $sqlMajorVersion -ge 13 ) -and ( $BasicAvailabilityGroup -ne $availabilityGroup.BasicAvailabilityGroup ) )
                {
                    $availabilityGroup.BasicAvailabilityGroup = $BasicAvailabilityGroup
                    Update-AvailabilityGroup -AvailabilityGroup $availabilityGroup
                }

                if ( ( $sqlMajorVersion -ge 13 ) -and ( $DatabaseHealthTrigger -ne $availabilityGroup.DatabaseHealthTrigger ) )
                {
                    $availabilityGroup.DatabaseHealthTrigger = $DatabaseHealthTrigger
                    Update-AvailabilityGroup -AvailabilityGroup $availabilityGroup
                }

                # Make sure ConnectionModeInPrimaryRole has a value in order to avoid false positive matches when the parameter is not defined
                if ( ( -not [string]::IsNullOrEmpty($ConnectionModeInPrimaryRole) ) -and ( $ConnectionModeInPrimaryRole -ne $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].ConnectionModeInPrimaryRole ) )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].ConnectionModeInPrimaryRole = $ConnectionModeInPrimaryRole
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName]
                }

                # Make sure ConnectionModeInSecondaryRole has a value in order to avoid false positive matches when the parameter is not defined
                if ( ( -not [string]::IsNullOrEmpty($ConnectionModeInSecondaryRole) ) -and ( $ConnectionModeInSecondaryRole -ne $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].ConnectionModeInSecondaryRole ) )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].ConnectionModeInSecondaryRole = $ConnectionModeInSecondaryRole
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName]
                }

                # Break out the EndpointUrl properties
                $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].EndpointUrl.Replace('//', '').Split(':')

                if ( $endpoint.Protocol.Tcp.ListenerPort -ne $currentEndpointPort )
                {
                    $newEndpointUrl = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].EndpointUrl.Replace($currentEndpointPort, $endpoint.Protocol.Tcp.ListenerPort)
                    $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName]
                }

                if ( $EndpointHostName -ne $currentEndpointHostName )
                {
                    $newEndpointUrl = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].EndpointUrl.Replace($currentEndpointHostName, $EndpointHostName)
                    $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName]
                }

                if ( $currentEndpointProtocol -ne 'TCP' )
                {
                    $newEndpointUrl = $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].EndpointUrl.Replace($currentEndpointProtocol, 'TCP')
                    $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].EndpointUrl = $newEndpointUrl
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName]
                }

                # Make sure FailureConditionLevel has a value in order to avoid false positive matches when the parameter is not defined
                if ( ( -not [string]::IsNullOrEmpty($FailureConditionLevel) ) -and ( $FailureConditionLevel -ne $availabilityGroup.FailureConditionLevel ) )
                {
                    $availabilityGroup.FailureConditionLevel = $FailureConditionLevel
                    Update-AvailabilityGroup -AvailabilityGroup $availabilityGroup
                }

                if ( $FailoverMode -ne $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].FailoverMode )
                {
                    $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName].FailoverMode = $FailoverMode
                    Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityGroup.AvailabilityReplicas[$serverObject.DomainInstanceName]
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
        Name of the SQL instance to be configured.

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

    .PARAMETER DatabaseHealthTrigger
        Specifies if the option Database Level Health Detection is enabled. This is only available is SQL Server 2016 and later and is ignored when applied to previous versions.

    .PARAMETER DtcSupportEnabled
        Specifies if the option Database DTC Support is enabled. This is only available is SQL Server 2016 and later and is ignored when applied to previous versions.

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
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('Primary', 'SecondaryOnly', 'Secondary', 'None')]
        [String]
        $AutomatedBackupPreference = 'None',

        [Parameter()]
        [ValidateSet('AsynchronousCommit', 'SynchronousCommit')]
        [String]
        $AvailabilityMode = 'AsynchronousCommit',

        [Parameter()]
        [ValidateRange(0, 100)]
        [UInt32]
        $BackupPriority = 50,

        [Parameter()]
        [Boolean]
        $BasicAvailabilityGroup,

        [Parameter()]
        [Boolean]
        $DatabaseHealthTrigger,

        [Parameter()]
        [Boolean]
        $DtcSupportEnabled,

        [Parameter()]
        [ValidateSet('AllowAllConnections', 'AllowReadWriteConnections')]
        [String]
        $ConnectionModeInPrimaryRole,

        [Parameter()]
        [ValidateSet('AllowNoConnections', 'AllowReadIntentConnectionsOnly', 'AllowAllConnections')]
        [String]
        $ConnectionModeInSecondaryRole,

        [Parameter()]
        [String]
        $EndpointHostName,

        [Parameter()]
        [ValidateSet('OnServerDown', 'OnServerUnresponsive', 'OnCriticalServerErrors', 'OnModerateServerErrors', 'OnAnyQualifiedFailureCondition')]
        [String]
        $FailureConditionLevel,

        [Parameter()]
        [ValidateSet('Automatic', 'Manual')]
        [String]
        $FailoverMode = 'Manual',

        [Parameter()]
        [UInt32]
        $HealthCheckTimeout = 30000
    )

    $getTargetResourceParameters = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer       = $SQLServer
        Name            = $Name
    }

    # Assume this will pass. We will determine otherwise later
    $result = $true

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    # Define current version for check compatibility
    $sqlMajorVersion = $getTargetResourceResult.Version

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
                'ConnectionModeInPrimaryRole',
                'ConnectionModeInSecondaryRole',
                'FailureConditionLevel',
                'FailoverMode',
                'HealthCheckTimeout'
            )

            <#
                Add properties compatible with SQL Server 2016 or later versions
                DtcSupportEnabled is enabled at the creation of the Availability Group only, hence it will not be checked in this block
            #>
            if ( $sqlMajorVersion -ge 13 )
            {
                $parametersToCheck += 'BasicAvailabilityGroup'
                $parametersToCheck += 'DatabaseHealthTrigger'
            }

            if ( $getTargetResourceResult.Ensure -eq 'Present' )
            {
                # Use $PSBoundParameters rather than $MyInvocation.MyCommand.Parameters.GetEnumerator()
                # This allows us to only validate the supplied parameters
                # If the parameter is not defined by the configuration, we don't care what
                # it gets set to.
                foreach ( $parameter in $PSBoundParameters.GetEnumerator() )
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
                $currentEndpointProtocol, $currentEndpointHostName, $currentEndpointPort = $getTargetResourceResult.EndpointUrl.Replace('//', '').Split(':')

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
        The Availability Group object that must be altered.
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
        throw New-TerminatingError -ErrorType AlterAvailabilityGroupFailed -FormatArgs $AvailabilityGroup.Name -ErrorCategory OperationStopped -InnerException $_.Exception
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

Export-ModuleMember -Function *-TargetResource
