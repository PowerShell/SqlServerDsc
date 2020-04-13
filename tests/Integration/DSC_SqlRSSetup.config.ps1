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
                NodeName            = 'localhost'
                InstanceName        = 'SSRS'
                IAcceptLicenseTerms = 'Yes'
                SourcePath          = Join-Path -Path $env:TEMP -ChildPath 'SQLServerReportingServices.exe'
                Edition             = 'Development'

                UserName            = "$env:COMPUTERNAME\SqlInstall"
                Password            = 'P@ssw0rd1'

                CertificateFile     = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Installs a Microsoft SQL Server Reporting Services instance.

    .NOTES
        When this test was written the build worker already contained a
        Microsoft SQL Server Reporting Services instance.
        If it exist, it will be upgraded.

        Uninstall is not tested, because when upgrading the existing Microsoft
        SQL Server 2017 Reporting Services instance it requires a restart which
        prevents uninstall until the node is rebooted.
#>
Configuration MSFT_SqlRSSetup_InstallReportingServicesAsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRSSetup 'Integration_Test'
        {
            InstanceName         = $Node.InstanceName
            IAcceptLicenseTerms  = $Node.IAcceptLicenseTerms
            SourcePath           = $Node.SourcePath
            Edition              = $Node.Edition

            # The build worker contains already an instance, make sure to upgrade it.
            VersionUpgrade       = $true

            # Suppressing restart because the build worker are not allowed to be restarted.
            SuppressRestart      = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Stopping the Microsoft SQL Server Reporting Services instance to
        save memory on the build worker.
#>
Configuration MSFT_SqlRSSetup_StopReportingServicesInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'

    node $AllNodes.NodeName
    {
        Service 'StopReportingServicesInstance'
        {
            Name  = 'SQLServerReportingServices'
            State = 'Stopped'
        }
    }
}
