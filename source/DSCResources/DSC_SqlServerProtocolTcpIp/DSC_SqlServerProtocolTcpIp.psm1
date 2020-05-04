$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the SQL Server TCP/IP protocol for the
        specified SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value is
        $env:COMPUTERNAME.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the services
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $returnValue = @{
        InstanceName           = $InstanceName
        ProtocolName           = $ProtocolName
        ServerName             = $ServerName
        SuppressRestart        = $SuppressRestart
        RestartTimeout         = $RestartTimeout
        Enabled                = $false
        ListenOnAllIpAddresses = $false
        KeepAlive              = 0
        PipeName               = $null
        HasMultiIPAddresses    = $false
    }

    $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

    Write-Verbose -Message (
        $script:localizedData.GetCurrentState -f $protocolNameProperties.DisplayName, $InstanceName, $ServerName
    )

    Import-SQLPSModule

    <#
        Must connect to the local machine name because $ServerName can point
        to a cluster instance or availability group listener.
    #>
    $getServerProtocolObjectParameters = @{
        ServerName   = $env:COMPUTERNAME
        Instance     = $InstanceName
        ProtocolName = $ProtocolName
    }

    $serverProtocolProperties = Get-ServerProtocolObject @getServerProtocolObjectParameters

    if ($serverProtocolProperties)
    {
        # Properties that exist on all protocols.
        $returnValue.Enabled = $serverProtocolProperties.IsEnabled
        $returnValue.HasMultiIPAddresses = $serverProtocolProperties.HasMultiIPAddresses

        # Get individual protocol properties.
        switch ($ProtocolName)
        {
            'TcpIp'
            {
                $returnValue.ListenOnAllIpAddresses = $serverProtocolProperties.ProtocolProperties['ListenOnAllIPs'].Value
                $returnValue.KeepAlive = $serverProtocolProperties.ProtocolProperties['KeepAlive'].Value
            }

            'NamedPipes'
            {
                $returnValue.PipeName = $serverProtocolProperties.ProtocolProperties['PipeName'].Value
            }

            'SharedMemory'
            {
                <#
                    Left blank intentionally. There are no individual protocol
                    properties for the protocol Shared Memory.
                #>
            }
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the desired state of the SQL Server TCP/IP protocol for the specified
        SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value is
        $env:COMPUTERNAME.

    .PARAMETER Enabled
        Specified if the IP address group should be enabled or disabled. Only used if
        the IP address group is not set to 'IPAll'. If not specified, the existing
        value will not be changed.

    .PARAMETER IPAddress
        Specifies the IP address for the IP adress group. Only used if the IP address
        group is not set to 'IPAll'. If not specified, the existing value will not be
        changed.

    .PARAMETER TcpDynamicPort
        Specifies whether the SQL Server instance should use a dynamic port. Value
        will be ignored if TcpPort is set to a non-empty string. If not specified,
        the existing value will not be changed.

    .PARAMETER TcpPort
        Specifies the TCP port(s) that SQL Server should be listening on. If the
        IP address should listen on more than one port, list all ports as a string
        value with the port numbers separated with a comma, e.g. '1433,1500,1501'.
        This parameter is limited to 2047 characters. If not specified, the existing
        value will not be changed.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the services
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.Boolean]
        $TcpDynamicPort,

        [Parameter()]
        [System.String]
        $TcpPort,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

    <#
        Compare the current state against the desired state. Calling this will
        also import the necessary module to later call Get-ServerProtocolObject
        which uses the SMO class ManagedComputer.
    #>
    $propertyState = Compare-TargetResourceState @PSBoundParameters

    # Get all properties that are not in desired state.
    $propertiesNotInDesiredState = $propertyState.Where( { -not $_.InDesiredState })

    if ($propertiesNotInDesiredState.Count -gt 0)
    {
        Write-Verbose -Message (
            $script:localizedData.SetDesiredState -f $protocolNameProperties.DisplayName, $InstanceName
        )

        <#
            Must connect to the local machine name because $ServerName can point
            to a cluster instance or availability group listener.
        #>
        $getServerProtocolObjectParameters = @{
            ServerName   = $env:COMPUTERNAME
            Instance     = $InstanceName
            ProtocolName = $ProtocolName
        }

        $serverProtocolProperties = Get-ServerProtocolObject @getServerProtocolObjectParameters

        if ($serverProtocolProperties)
        {
            $isRestartNeeded = $false

            # Check if Enable property need updating.
            if ($propertiesNotInDesiredState.Where( { $_.ParameterName -eq 'Enabled' }))
            {
                $serverProtocolProperties.IsEnabled = $Enabled

                if ($Enabled)
                {
                    Write-Verbose -Message (
                        $script:localizedData.ProtocolHasBeenEnabled -f $protocolNameProperties.DisplayName, $InstanceName
                    )
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.ProtocolHasBeenDisabled -f $protocolNameProperties.DisplayName, $InstanceName
                    )
                }

                $isRestartNeeded = $true
            }

            # Set individual protocol properties.
            switch ($ProtocolName)
            {
                'TcpIp'
                {
                    # Check if ListenOnAllIpAddresses property need updating.
                    if ($propertiesNotInDesiredState.Where( { $_.ParameterName -eq 'ListenOnAllIpAddresses' }))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.ParameterHasBeenSetToNewValue -f 'ListenOnAllIpAddresses', $protocolNameProperties.DisplayName, $ListenOnAllIpAddresses
                        )

                        $serverProtocolProperties.ProtocolProperties['ListenOnAllIPs'].Value = $ListenOnAllIpAddresses
                    }

                    # Check if KeepAlive property need updating.
                    if ($propertiesNotInDesiredState.Where( { $_.ParameterName -eq 'KeepAlive' }))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.ParameterHasBeenSetToNewValue -f 'KeepAlive', $protocolNameProperties.DisplayName, $KeepAlive
                        )

                        $serverProtocolProperties.ProtocolProperties['KeepAlive'].Value = $KeepAlive
                    }
                }

                'NamedPipes'
                {
                    # Check if PipeName property need updating.
                    if ($propertiesNotInDesiredState.Where( { $_.ParameterName -eq 'PipeName' }))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.ParameterHasBeenSetToNewValue -f 'PipeName', $protocolNameProperties.DisplayName, $PipeName
                        )

                        $serverProtocolProperties.ProtocolProperties['PipeName'].Value = $PipeName
                    }
                }

                'SharedMemory'
                {
                    <#
                        Left blank intentionally. There are no individual protocol
                        properties for the protocol Shared Memory.
                    #>
                }
            }

            $serverProtocolProperties.Alter()
        }

        if (-not $SuppressRestart -and $isRestartNeeded)
        {
            $restartSqlServiceParameters = @{
                ServerName   = $ServerName
                InstanceName = $InstanceName
                Timeout      = $RestartTimeout
                OwnerNode    = $env:COMPUTERNAME
            }

            Restart-SqlService @restartSqlServiceParameters
        }
        elseif ($isRestartNeeded)
        {
            Write-Warning -Message $script:localizedData.RestartSuppressed
        }
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.ProtocolIsInDesiredState -f $protocolNameProperties.DisplayName, $InstanceName
        )
    }
}

<#
    .SYNOPSIS
        Determines the desired state of the SQL Server TCP/IP protocol for the
        specified SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value is
        $env:COMPUTERNAME.

    .PARAMETER Enabled
        Specified if the IP address group should be enabled or disabled. Only used if
        the IP address group is not set to 'IPAll'. If not specified, the existing
        value will not be changed.

    .PARAMETER IPAddress
        Specifies the IP address for the IP adress group. Only used if the IP address
        group is not set to 'IPAll'. If not specified, the existing value will not be
        changed.

    .PARAMETER TcpDynamicPort
        Specifies whether the SQL Server instance should use a dynamic port. Value
        will be ignored if TcpPort is set to a non-empty string. If not specified,
        the existing value will not be changed.

    .PARAMETER TcpPort
        Specifies the TCP port(s) that SQL Server should be listening on. If the
        IP address should listen on more than one port, list all ports as a string
        value with the port numbers separated with a comma, e.g. '1433,1500,1501'.
        This parameter is limited to 2047 characters. If not specified, the existing
        value will not be changed.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the services
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.Boolean]
        $TcpDynamicPort,

        [Parameter()]
        [System.String]
        $TcpPort,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

    Write-Verbose -Message (
        $script:localizedData.TestDesiredState -f $protocolNameProperties.DisplayName, $InstanceName, $ServerName
    )

    $propertyState = Compare-TargetResourceState @PSBoundParameters


    if ($false -in $propertyState.InDesiredState)
    {
        $testTargetResourceReturnValue = $false

        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState -f $protocolNameProperties.DisplayName, $InstanceName
        )
    }
    else
    {
        $testTargetResourceReturnValue = $true

        Write-Verbose -Message (
            $script:localizedData.InDesiredState -f $protocolNameProperties.DisplayName, $InstanceName
        )
    }

    return $testTargetResourceReturnValue
}

<#
    .SYNOPSIS
        Compares the properties in the current state with the properties of the
        desired state and returns a hashtable with the comparison result.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value is
        $env:COMPUTERNAME.

    .PARAMETER Enabled
        Specified if the IP address group should be enabled or disabled. Only used if
        the IP address group is not set to 'IPAll'. If not specified, the existing
        value will not be changed.

    .PARAMETER IPAddress
        Specifies the IP address for the IP adress group. Only used if the IP address
        group is not set to 'IPAll'. If not specified, the existing value will not be
        changed.

    .PARAMETER TcpDynamicPort
        Specifies whether the SQL Server instance should use a dynamic port. Value
        will be ignored if TcpPort is set to a non-empty string. If not specified,
        the existing value will not be changed.

    .PARAMETER TcpPort
        Specifies the TCP port(s) that SQL Server should be listening on. If the
        IP address should listen on more than one port, list all ports as a string
        value with the port numbers separated with a comma, e.g. '1433,1500,1501'.
        This parameter is limited to 2047 characters. If not specified, the existing
        value will not be changed.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the services
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.
#>
function Compare-TargetResourceState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.Boolean]
        $TcpDynamicPort,

        [Parameter()]
        [System.String]
        $TcpPort,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    if ($ProtocolName -eq 'SharedMemory')
    {
        <#
            If the protocol is Shared Memory, assert that no other individual
            protocol properties are passed.
        #>
        $assertBoundParameterParameters = @{
            BoundParameterList     = $PSBoundParameters
            <#
                Since SharedMemory does not have any individual properties this
                mandatory property is being used to compare against.
            #>
            MutuallyExclusiveList1 = @(
                'ProtocolName'
            )
            # These must not be passed for Shared Memory.
            MutuallyExclusiveList2 = @(
                'KeepAlive'
                'ListenOnAllIpAddresses'
                'PipeName'
            )
        }
    }
    else
    {
        <#
            If the protocol is set to TCP/IP or Named Pipes, assert that one or
            more of their individual protocol properties are not passed together.
        #>
        $assertBoundParameterParameters = @{
            BoundParameterList     = $PSBoundParameters
            # Individual properties for TCP/IP.
            MutuallyExclusiveList1 = @(
                'KeepAlive'
                'ListenOnAllIpAddresses'
            )
            # Individual properties for Named Pipes.
            MutuallyExclusiveList2 = @(
                'PipeName'
            )
        }
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        InstanceName    = $InstanceName
        ProtocolName    = $ProtocolName
        ServerName      = $ServerName
        SuppressRestart = $SuppressRestart
        RestartTimeout  = $RestartTimeout
    }

    <#
        We remove any parameters not passed by $PSBoundParameters so that
        Get-TargetResource can also evaluate $PSBoundParameters correctly.

        Need the @() around the Keys property to get a new array to enumerate.
    #>
    @($getTargetResourceParameters.Keys) | ForEach-Object {
        if (-not $PSBoundParameters.ContainsKey($_))
        {
            $getTargetResourceParameters.Remove($_)
        }
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $propertiesToEvaluate = @(
        'Enabled'
    )

    # Get individual protocol properties to evaluate.
    switch ($ProtocolName)
    {
        'TcpIp'
        {
            $propertiesToEvaluate += 'ListenOnAllIpAddresses'
            $propertiesToEvaluate += 'KeepAlive'
        }

        'NamedPipes'
        {
            $propertiesToEvaluate += 'PipeName'
        }

        'SharedMemory'
        {
            <#
                Left blank intentionally. There are no individual protocol
                properties for the protocol Shared Memory.
            #>
        }
    }

    $compareTargetResourceStateParameters = @{
        CurrentValues = $getTargetResourceResult
        DesiredValues = $PSBoundParameters
        Properties    = $propertiesToEvaluate
    }

    return Compare-ResourcePropertyState @compareTargetResourceStateParameters
}

<#
    .SYNOPSIS
        Get static name properties of he specified protocol.

    .PARAMETER ProtocolName
        Specifies the name of network protocol to return name properties for.
        Possible values are 'TcpIp', 'NamedPipes', or 'ShareMemory'.

    .NOTES
        The static values returned matches the values returned by the class
        ServerProtocol. The property DisplayName could potentially be localized
        while the property Name must be exactly like it is returned by the
        class ServerProtocol, with the correct casing.

#>
function Get-ProtocolNameProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName
    )

    $protocolNameProperties = @{ }

    switch ($ProtocolName)
    {
        'TcpIp'
        {
            $protocolNameProperties.DisplayName = 'TCP/IP'
            $protocolNameProperties.Name = 'Tcp'
        }

        'NamedPipes'
        {
            $protocolNameProperties.DisplayName = 'Named Pipes'
            $protocolNameProperties.Name = 'Np'
        }

        'SharedMemory'
        {
            $protocolNameProperties.DisplayName = 'Shared Memory'
            $protocolNameProperties.Name = 'Sm'
        }
    }

    return $protocolNameProperties
}

<#
    .SYNOPSIS
        Returns the ServerProtocol object for the specified SQL Server instance
        and protocol name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to connect to.

    .PARAMETER ProtocolName
        Specifies the name of network protocol to be configured. Possible values
        are 'TcpIp', 'NamedPipes', or 'ShareMemory'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to connect to.

    .NOTES
        The class Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol is
        returned by this function.
#>
function Get-ServerProtocolObject
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName
    )

    $serverProtocolProperties = $null

    $newObjectParameters = @{
        TypeName     = 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        ArgumentList = @($ServerName)
    }

    $managedComputerObject = New-Object @newObjectParameters

    $serverInstance = $managedComputerObject.ServerInstances[$InstanceName]

    if ($serverInstance)
    {
        $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

        $serverProtocolProperties = $serverInstance.ServerProtocols[$protocolNameProperties.Name]
    }

    return $serverProtocolProperties
}
