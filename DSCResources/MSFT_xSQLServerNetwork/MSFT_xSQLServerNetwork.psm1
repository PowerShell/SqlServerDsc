Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        # For now there is only support for the tcp protocol.
        [parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName
    )

    Try
    {
        $dom_get = Register-SqlWmiManagement -SQLInstanceName $InstanceName

        $wmi = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        Write-Verbose "Getting [$ProtocolName] network protocol for [$InstanceName] SQL instance"
        $tcp = $wmi.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

        Write-Verbose "Reading state values:"
        $returnValue = @{
            InstanceName = $InstanceName
            ProtocolName = $ProtocolName
            IsEnabled = $tcp.IsEnabled
            TcpDynamicPorts = $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpDynamicPorts"].Value
            TcpPort = $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpPort"].Value
        }

        $returnValue.Keys | % { Write-Verbose "$_ = $($returnValue[$_])" }

    }
    Finally
    {
        Unregister-SqlAssemblies -ApplicationDomain $dom_get
    }

    return $returnValue
}

Function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [System.Boolean]
        $IsEnabled,

        [ValidateSet("0","")]
        [System.String]
        $TcpDynamicPorts,

        [System.String]
        $TcpPort,

        [System.Boolean]
        $RestartService = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $currentState = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName

    $dom_get = Register-SqlWmiManagement -SQLInstanceName $InstanceName

    Try
    {
        $desiredState = @{
            InstanceName = $InstanceName
            ProtocolName = $ProtocolName
            IsEnabled = $IsEnabled
            TcpDynamicPorts = $TcpDynamicPorts
            TcpPort = $TcpPort
        }

        $isRestartNeeded = $false

        $wmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        Write-Verbose "Getting [$ProtocolName] network protocol for [$InstanceName] SQL instance"
        $tcp = $wmi.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

        Write-Verbose "Checking [IsEnabled] property."
        if($desiredState["IsEnabled"] -ine $currentState["IsEnabled"])
        {
            Write-Verbose "Updating [IsEnabled] from $($currentState["IsEnabled"]) to $($desiredState["IsEnabled"])"
            $tcp.IsEnabled = $desiredState["IsEnabled"]
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        Write-Verbose "Checking [TcpDynamicPorts] property."
        if($desiredState["TcpDynamicPorts"] -ine $currentState["TcpDynamicPorts"])
        {
            Write-Verbose "Updating [TcpDynamicPorts] from $($currentState["TcpDynamicPorts"]) to $($desiredState["TcpDynamicPorts"])"
            $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpDynamicPorts"].Value = $desiredState["TcpDynamicPorts"]
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        Write-Verbose "Checking [TcpPort property]."
        if($desiredState["TcpPort"] -ine $currentState["TcpPort"])
        {
            Write-Verbose "Updating [TcpPort] from $($currentState["TcpPort"]) to $($desiredState["TcpPort"])"
            $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpPort"].Value = $desiredState["TcpPort"]
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        if($RestartService -and $isRestartNeeded)
        {
            Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $InstanceName -Timeout $RestartTimeout
        }
    }
    Finally
    {
        Unregister-SqlAssemblies -ApplicationDomain $dom_get
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [System.Boolean]
        $IsEnabled,

        [ValidateSet("0","")]
        [System.String]
        $TcpDynamicPorts,

        [System.String]
        $TcpPort,

        [System.Boolean]
        $RestartService = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $desiredState = @{
        InstanceName = $InstanceName
        ProtocolName = $ProtocolName
        IsEnabled = $IsEnabled
        TcpDynamicPorts = $TcpDynamicPorts
        TcpPort = $TcpPort
    }

    $currentState = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName

    Write-Verbose "Comparing desiredState with currentSate ..."
    foreach($key in $desiredState.Keys)
    {
        if($desiredState[$key] -ine $currentState[$key] )
        {
            Write-Verbose "$key is different: desired = $($desiredState[$key]); current = $($currentState[$key])"
            return $false
        }
    }

    Write-Verbose "States match"
    return $true
}

Export-ModuleMember -Function *-TargetResource
