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
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'

                UserName        = "$env:COMPUTERNAME\SqlInstall"
                Password        = 'P@ssw0rd1'

                ServerName      = $env:COMPUTERNAME
                InstanceName    = 'DSCSQLTEST'

                ProtocolName    = 'Tcp'
                Enabled         = $true
                Disabled        = $false
                TcpDynamicPort  = $true
                RestartService  = $true

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Disable network protocol.
#>
Configuration MSFT_SqlServerNetwork_SetDisabled_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerNetwork 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            ProtocolName         = $Node.ProtocolName
            IsEnabled            = $Node.Disabled
            TcpDynamicPort       = $Node.TcpDynamicPort

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Enable network protocol.
#>
Configuration MSFT_SqlServerNetwork_SetEnabled_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerNetwork 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            ProtocolName         = $Node.ProtocolName
            IsEnabled            = $Node.Enabled
            TcpDynamicPort       = $Node.TcpDynamicPort

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

