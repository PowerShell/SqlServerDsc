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

        # for now support is just for tcp protocol
        # possible future feature to support additional protocols
        [parameter(Mandatory = $true)]
        [ValidateSet("tcp")]
        [System.String]
        $ProtocolName
    )

    Write-Verbose "xSQLServerNetwork.Get-TargetResourece ..."
    Write-Verbose "Parameters: InstanceName = $InstanceName; ProtocolName = $ProtocolName"

    # create isolated appdomain to load version specific libs, this needed if you have multiple versions of SQL server in the same configuration
    $dom_get = [System.AppDomain]::CreateDomain("xSQLServerNetwork_Get_$InstanceName")

    Try
    {
        $version = GetVersion -InstanceName $InstanceName

        if([string]::IsNullOrEmpty($version))
        {
            throw "Unable to resolve SQL version for instance"
        }

        $smo = $dom_get.Load("Microsoft.SqlServer.Smo, Version=$version.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
        $sqlWmiManagement = $dom_get.Load("Microsoft.SqlServer.SqlWmiManagement, Version=$version.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")

        Write-Verbose "Creating [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer] object"
        $wmi = new-object $sqlWmiManagement.GetType("Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer")

        Write-Verbose "Getting [$ProtocolName] network protocol for [$InstanceName] SQL instance"
        $tcp = $wmi.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

        Write-Verbose "Reading state values:"
        $returnValue = @{
            InstanceName = $InstanceName
            ProtocolName = $ProtocolName
            IsEnabled = $tcp.IsEnabled
            TCPDynamicPorts = $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpDynamicPorts"].Value
            TCPPort = $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpPort"].Value
        }

        $returnValue.Keys | % { Write-Verbose "$_ = $($returnValue[$_])" }

    }
    Finally
    {
        [System.AppDomain]::Unload($dom_get)
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
        [ValidateSet("tcp")]
        [System.String]
        $ProtocolName,

        [System.Boolean]
        $IsEnabled,

        [ValidateSet("0")]
        [System.String]
        $TCPDynamicPorts,

        [System.String]
        $TCPPort,

        [System.Boolean]
        $RestartService = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    Write-Verbose "xSQLServerNetwork.Set-TargetResource ..."
    Write-Verbose "Parameters: InstanceName = $InstanceName; ProtocolName = $ProtocolName; IsEnabled=$IsEnabled; TCPDynamicPorts = $TCPDynamicPorts; TCPPort = $TCPPort; RestartService=$RestartService;"

    Write-Verbose "Calling xSQLServerNetwork.Get-TargetResource ..."
    $currentState = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName

    # create isolated appdomain to load version specific libs, this needed if you have multiple versions of SQL server in the same configuration
    $dom_set = [System.AppDomain]::CreateDomain("xSQLServerNetwork_Set_$InstanceName")

    Try
    {
        $version = GetVersion -InstanceName $InstanceName

        if([string]::IsNullOrEmpty($version))
        {
            throw "Unable to resolve SQL version for instance"
        }

        $smo = $dom_set.Load("Microsoft.SqlServer.Smo, Version=$version.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
        $sqlWmiManagement = $dom_set.Load("Microsoft.SqlServer.SqlWmiManagement, Version=$version.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")

        $desiredState = @{
            InstanceName = $InstanceName
            ProtocolName = $ProtocolName
            IsEnabled = $IsEnabled
            TCPDynamicPorts = $TCPDynamicPorts
            TCPPort = $TCPPort
        }

        Write-Verbose "Creating [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer] object"
        $wmi = new-object $sqlWmiManagement.GetType("Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer")

        Write-Verbose "Getting [$ProtocolName] network protocol for [$InstanceName] SQL instance"
        $tcp = $wmi.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

        Write-Verbose "Checking [IsEnabled] property ..."
        if($desiredState["IsEnabled"] -ine $currentState["IsEnabled"])
        {
            Write-Verbose "Updating [IsEnabled] from $($currentState["IsEnabled"]) to $($desiredState["IsEnabled"])"
            $tcp.IsEnabled = $desiredState["IsEnabled"]
        }

        Write-Verbose "Checking [TCPDynamicPorts] property ..."
        if($desiredState["TCPDynamicPorts"] -ine $currentState["TCPDynamicPorts"])
        {
            Write-Verbose "Updating [TCPDynamicPorts] from $($currentState["TCPDynamicPorts"]) to $($desiredState["TCPDynamicPorts"])"
            $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpDynamicPorts"].Value = $desiredState["TCPDynamicPorts"]
        }

        Write-Verbose "Checking [TCPPort property] ..."
        if($desiredState["TCPPort"] -ine $currentState["TCPPort"])
        {
            Write-Verbose "Updating [TCPPort] from $($currentState["TCPPort"]) to $($desiredState["TCPPort"])"
            $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpPort"].Value = $desiredState["TCPPort"]
        }

        Write-Verbose "Saving changes ..."
        $tcp.Alter()

        if($RestartService)
        {
            Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $InstanceName -Timeout $RestartTimeout
        }
    }
    Finally
    {
        [System.AppDomain]::Unload($dom_set)
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
        [ValidateSet("tcp")]
        [System.String]
        $ProtocolName,

        [System.Boolean]
        $IsEnabled,

        [ValidateSet("0")]
        [System.String]
        $TCPDynamicPorts,

        [System.String]
        $TCPPort,

        [System.Boolean]
        $RestartService = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    Write-Verbose "xSQLServerNetwork.Test-TargetResource ..."
    Write-Verbose "Parameters: InstanceName = $InstanceName; ProtocolName = $ProtocolName; IsEnabled=$IsEnabled; TCPDynamicPorts = $TCPDynamicPorts; TCPPort = $TCPPort; RestartService=$RestartService;"

    $desiredState = @{
        InstanceName = $InstanceName
        ProtocolName = $ProtocolName
        IsEnabled = $IsEnabled
        TCPDynamicPorts = $TCPDynamicPorts
        TCPPort = $TCPPort
    }

    Write-Verbose "Calling xSQLServerNetwork.Get-TargetResource ..."
    $currentState = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName

    Write-Verbose "Comparing desiredState with currentSate ..."
    foreach($key in $desiredState.Keys)
    {
        if($currentState.Keys -eq $key)
        {
            if($desiredState[$key] -ine $currentState[$key] )
            {
                Write-Verbose "$key is different: desired = $($desiredState[$key]); current = $($currentState[$key])"
                return $false
            }
        }
        else
        {
            Write-Verbose "$key is missing"
            return $false
        }
    }

    Write-Verbose "States match"
    return $true
}

Function GetVersion
{
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $instanceId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").$InstanceName
    $sqlVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup").Version
    $sqlVersion.Split(".")[0]
}

Export-ModuleMember -Function *-TargetResource
