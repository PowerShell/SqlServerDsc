# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            ComputerName                = $env:COMPUTERNAME
            InstanceName                = 'DSCSQL2016'
            RestartTimeout              = 120

            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration MSFT_xSQLServerAlwaysOnService_EnableAlwaysOn_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'xSQLServer'

    node localhost {
        WindowsFeature 'AddFeatureFailoverClustering'
        {
            Ensure = "Present"
            Name   = "Failover-clustering"
        }

        WindowsFeature 'AddFeatureFailoverClusteringPowerShellModule'
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-PowerShell"
        }

        <#
            This is not using a dedicated DSC resource because xFailOverCluster
            does not support administrative access point at this time.
            Issue https://github.com/PowerShell/xFailOverCluster/issues/147.
        #>
        Script 'CreateActiveDirectoryDetachedCluster'
        {
            SetScript  = {
                <#
                    This is used to get the correct IP address in AppVeyor.
                    The logic is to get the IP address of the first NIC not
                    named something like 'Internal' and then addition 1 to the
                    last number. For example if the NIC has and IP address
                    of 10.0.0.10, then cluster IP address will be 10.0.0.11.
                #>
                $ipAddress = Get-NetIPConfiguration | Where-Object -FilterScript {
                    $_.InterfaceAlias -notlike '*Internal*'
                } | Select-Object -ExpandProperty IPv4Address | Select-Object IPAddress
                $ipAddressParts = ($ipAddress[0].IPAddress -split '\.')
                [System.UInt32] $ipAddressParts[3] += 1
                $clusterStaticIpAddress = ($ipAddressParts -join '.')

                $newClusterParameters = @{
                    Name                      = 'DSCCLU01'
                    Node                      = $env:COMPUTERNAME
                    StaticAddress             = $clusterStaticIpAddress
                    NoStorage                 = $true
                    AdministrativeAccessPoint = 'Dns'

                    # Ignoring warnings that cluster might not be able to start correctly.
                    WarningAction             = 'SilentlyContinue'
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
        }

        xSQLServerAlwaysOnService 'Integration_Test'
        {
            Ensure               = 'Present'
            SQLServer            = $Node.ComputerName
            SQLInstanceName      = $Node.InstanceName
            RestartTimeout       = $Node.RestartTimeout

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn            = @(
                '[WindowsFeature]AddFeatureFailoverClustering'
                '[WindowsFeature]AddFeatureFailoverClusteringPowerShellModule'
                '[Script]CreateActiveDirectoryDetachedCluster'
            )
        }
    }
}
