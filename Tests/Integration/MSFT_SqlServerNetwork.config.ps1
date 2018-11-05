$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName        = 'localhost'
            ServerName      = $env:COMPUTERNAME
            InstanceName    = 'DSCSQL2016'

            ProtocolName    = 'Tcp'
            Enabled         = $true
            Disabled        = $false
            TcpDynamicPort  = $true
            RestartService  = $true

            CertificateFile = $env:DscPublicCertificatePath
        }
    )
}

Configuration MSFT_SqlServerNetwork_SetDisabled_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServerNetwork 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            ProtocolName         = $Node.ProtocolName
            IsEnabled            = $Node.Disabled
            TcpDynamicPort       = $Node.TcpDynamicPort

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

Configuration MSFT_SqlServerNetwork_SetEnabled_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServerNetwork 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            ProtocolName         = $Node.ProtocolName
            IsEnabled            = $Node.Enabled
            TcpDynamicPort       = $Node.TcpDynamicPort

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

