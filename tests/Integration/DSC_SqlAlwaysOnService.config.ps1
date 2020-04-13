#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    <#
        Get all adapters with static IP addresses, all of which should be ignored
        when creating the cluster.
    #>
    $ignoreAdapterIpAddress = Get-NetAdapter |
        Get-NetIPInterface |
        Where-Object -FilterScript {
        $_.AddressFamily -eq 'IPv4' `
            -and $_.Dhcp -eq 'Disabled'
    } | Get-NetIPAddress

    $ignoreIpNetwork = @()
    foreach ($adapterIpAddress in $ignoreAdapterIpAddress)
    {
        <#
            Get-NetIPAddressNetwork is in CommonTestHelper.psm1 which is imported
            withing the integration test before this file is dot-sourced.
        #>
        $ipNetwork = (Get-NetIPAddressNetwork -IPAddress $adapterIpAddress.IPAddress -PrefixLength $adapterIpAddress.PrefixLength).NetworkAddress
        $ignoreIpNetwork += ('{0}/{1}' -f $ipNetwork, $adapterIpAddress.PrefixLength)
    }

    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                 = 'localhost'
                ComputerName             = $env:COMPUTERNAME
                InstanceName             = 'DSCSQLTEST'
                RestartTimeout           = 120

                UserName                 = "$env:COMPUTERNAME\SqlInstall"
                Password                 = 'P@ssw0rd1'

                LoopbackAdapterName      = 'ClusterNetwork'
                LoopbackAdapterIpAddress = '192.168.40.10'
                LoopbackAdapterGateway   = '192.168.40.254'

                ClusterStaticIpAddress   = '192.168.40.11'
                IgnoreNetwork            = $ignoreIpNetwork

                CertificateFile          = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Prerequisites for AlwaysOn.

    .NOTES
        Configures the loopback adapter (that was installed prior in the
        integration tests), and then configures Failover Clustering as a
        detached cluster.
#>
Configuration DSC_SqlAlwaysOnService_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName 'NetworkingDsc' -ModuleVersion '7.4.0.0'

    node $AllNodes.NodeName
    {
        WindowsFeature 'AddFeatureFailoverClustering'
        {
            Ensure = 'Present'
            Name   = 'Failover-clustering'
        }

        WindowsFeature 'AddFeatureFailoverClusteringPowerShellModule'
        {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-PowerShell'
        }

        IPAddress 'LoopbackAdapterIPv4Address'
        {
            IPAddress      = $Node.LoopbackAdapterIpAddress
            InterfaceAlias = $Node.LoopbackAdapterName
            AddressFamily  = 'IPv4'
        }

        <#
            Must have a default gateway for the Cluster to be able to use the
            loopback adapter as clustered network.
            This will be removed directly after the cluster has been created.
        #>
        DefaultGatewayAddress 'LoopbackAdapterIPv4DefaultGateway'
        {
            Address        = $Node.LoopbackAdapterGateway
            InterfaceAlias = $Node.LoopbackAdapterName
            AddressFamily  = 'IPv4'
        }

        <#
            This is not using a dedicated DSC resource because xFailOverCluster
            does not support administrative access point at this time.
            Issue https://github.com/PowerShell/xFailOverCluster/issues/147.
        #>
        Script 'CreateActiveDirectoryDetachedCluster'
        {
            SetScript  = {
                $clusterStaticIpAddress = $Using:Node.ClusterStaticIpAddress
                $ignoreNetwork = $Using:Node.IgnoreNetwork

                Write-Verbose -Message ('Ignoring networks: ''{0}''' -f ($ignoreNetwork -join ', ')) -Verbose

                $newClusterParameters = @{
                    Name                      = 'DSCCLU01'
                    Node                      = $env:COMPUTERNAME
                    StaticAddress             = $clusterStaticIpAddress
                    IgnoreNetwork             = $ignoreNetwork
                    NoStorage                 = $true
                    AdministrativeAccessPoint = 'Dns'

                    # Ignoring warnings that cluster might not be able to start correctly.
                    WarningAction             = 'SilentlyContinue'

                    # Make sure to stop on any error.
                    ErrorAction               = 'Stop'
                }

                Write-Verbose -Message ('Creating Active Directory-Detached cluster ''{0}'' with IP address ''{1}''.' -f $newClusterParameters.Name, $clusterStaticIpAddress)

                New-Cluster @newClusterParameters | Out-Null
            }

            TestScript = {
                $result = $false

                <#
                    Only create Active Directory-Detached cluster if the computer
                    is not part of a domain.
                #>
                if (-not (Get-CimInstance Win32_ComputerSystem).PartOfDomain)
                {
                    $clusterName = 'DSCCLU01'
                    if (Get-Cluster -Name $clusterName -ErrorAction SilentlyContinue)
                    {
                        Write-Verbose -Message ('Cluster ''{0}'' exist.' -f $clusterName)
                        $result = $true
                    }
                    else
                    {
                        Write-Verbose -Message ('Cluster ''{0}'' does not exist.' -f $clusterName)
                    }
                }
                else
                {
                    Write-Verbose -Message 'Computer is domain-joined. Skipping creation of Active Directory-Detached cluster. Expecting a cluster to be present by other means than thru the integration test.'
                    $result = $true
                }

                return $result
            }

            GetScript  = {
                [System.String] $clusterName = $null

                $cluster = Get-Cluster -Name 'DSCCLU01' -ErrorAction SilentlyContinue
                if ($cluster)
                {
                    $clusterName = $cluster.Name
                }

                return @{
                    Result = $clusterName
                }
            }

            DependsOn  = @(
                '[WindowsFeature]AddFeatureFailoverClustering'
                '[WindowsFeature]AddFeatureFailoverClusteringPowerShellModule'
            )

        }
    }
}

<#
    .SYNOPSIS
        Clean up settings on the loopback adapter so it is not interfering
        with the other integration tests.
#>
Configuration DSC_SqlAlwaysOnService_CleanupDependencies_Config
{
    Import-DscResource -ModuleName 'NetworkingDsc' -ModuleVersion '7.4.0.0'

    node $AllNodes.NodeName
    {
        <#
            Removing the default gateway from the loopback adapter.
        #>
        DefaultGatewayAddress 'LoopbackAdapterIPv4DefaultGateway'
        {
            InterfaceAlias = $Node.LoopbackAdapterName
            AddressFamily  = 'IPv4'
        }
    }
}

<#
    .SYNOPSIS
        Enables AlwaysOn.
#>
Configuration DSC_SqlAlwaysOnService_EnableAlwaysOn_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAlwaysOnService 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ComputerName
            InstanceName         = $Node.InstanceName
            RestartTimeout       = $Node.RestartTimeout

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

        }
    }
}

<#
    .SYNOPSIS
        Disables AlwaysOn.
#>
Configuration DSC_SqlAlwaysOnService_DisableAlwaysOn_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAlwaysOnService 'Integration_Test'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.ComputerName
            InstanceName         = $Node.InstanceName
            RestartTimeout       = $Node.RestartTimeout

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
