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
    # Get a spare drive letter
    $mockLastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $mockIsoMediaDriveLetter = [char](([int][char]$mockLastDrive) + 1)

    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName             = 'localhost'

                RunAs_UserName       = "$env:COMPUTERNAME\SqlInstall"
                RunAs_Password       = 'P@ssw0rd1'
                Service_UserName     = "$env:COMPUTERNAME\svc-Reporting"
                Service_Password     = 'yig-C^Equ3'

                InstanceName         = 'DSCRS2016'
                Features             = 'RS'
                InstallSharedDir     = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir  = 'C:\Program Files (x86)\Microsoft SQL Server'
                UpdateEnabled        = 'False'
                SuppressReboot       = $true # Make sure we don't reboot during testing.
                ForceReboot          = $false

                ImagePath            = "$env:TEMP\SQL2016.iso"
                DriveLetter          = $mockIsoMediaDriveLetter

                DatabaseServerName   = $env:COMPUTERNAME
                DatabaseInstanceName = 'DSCSQL2016'

                CertificateFile      = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Add dependencies for configuring Reporting Services. Mounts the ISO,
        create the service account, make sure .NET Framework 4.5 is installed,
        and installs the Reporting Services,
#>
Configuration MSFT_SqlRS_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'StorageDsc'
    Import-DscResource -ModuleName 'SqlServerDsc'

    $reportingServicesServiceCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.Service_UserName, (ConvertTo-SecureString -String $Node.Service_Password -AsPlainText -Force))

    node $AllNodes.NodeName
    {
        MountImage 'MountIsoMedia'
        {
            ImagePath   = $Node.ImagePath
            DriveLetter = $Node.DriveLetter
            Ensure      = 'Present'
        }

        WaitForVolume 'WaitForMountOfIsoMedia'
        {
            DriveLetter      = $Node.DriveLetter
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        User 'CreateReportingServicesServiceAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $reportingServicesServiceCredential.UserName -Leaf
            Password = $reportingServicesServiceCredential
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        SqlSetup 'InstallReportingServicesInstance'
        {
            InstanceName          = $Node.InstanceName
            Features              = $Node.Features
            SourcePath            = "$($Node.DriveLetter):\"
            BrowserSvcStartupType = 'Automatic'
            RSSvcAccount          = $reportingServicesServiceCredential
            InstallSharedDir      = $Node.InstallSharedDir
            InstallSharedWOWDir   = $Node.InstallSharedWOWDir
            UpdateEnabled         = $Node.UpdateEnabled
            SuppressReboot        = $Node.SuppressReboot
            ForceReboot           = $Node.ForceReboot

            DependsOn             = @(
                '[WaitForVolume]WaitForMountOfIsoMedia'
                '[User]CreateReportingServicesServiceAccount'
                '[WindowsFeature]NetFramework45'
            )

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.RunAs_UserName, (ConvertTo-SecureString -String $Node.RunAs_Password -AsPlainText -Force))

        }
    }
}

<#
    .SYNOPSIS
        Configures the Reporting Services.
#>
Configuration MSFT_SqlRS_InstallReportingServices_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRS 'Integration_Test'
        {
            # Instance name for the Reporting Services.
            InstanceName         = $Node.InstanceName

            <#
                Instance for Reporting Services databases.
                Note: This instance is created in a prior integration test.
            #>
            DatabaseServerName   = $Node.DatabaseServerName
            DatabaseInstanceName = $Node.DatabaseInstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.RunAs_UserName, (ConvertTo-SecureString -String $Node.RunAs_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Enables SSL on the Reporting Services.
#>
Configuration MSFT_SqlRS_InstallReportingServices_ConfigureSsl_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRS 'Integration_Test'
        {
            # Instance name for the Reporting Services.
            InstanceName         = $Node.InstanceName
            UseSsl               = $true

            <#
                Instance for Reporting Services databases.
                Note: This instance is created in a prior integration test.
            #>
            DatabaseServerName   = $Node.DatabaseServerName
            DatabaseInstanceName = $Node.DatabaseInstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.RunAs_UserName, (ConvertTo-SecureString -String $Node.RunAs_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Disables SSL on the Reporting Services.
#>
Configuration MSFT_SqlRS_InstallReportingServices_RestoreToNoSsl_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRS 'Integration_Test'
        {
            # Instance name for the Reporting Services.
            InstanceName         = $Node.InstanceName
            UseSsl               = $false

            <#
                Instance for Reporting Services databases.
                Note: This instance is created in a prior integration test.
            #>
            DatabaseServerName   = $Node.DatabaseServerName
            DatabaseInstanceName = $Node.DatabaseInstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.RunAs_UserName, (ConvertTo-SecureString -String $Node.RunAs_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Stops the Reporting Services instance to save resource on the build worker.
#>
Configuration MSFT_SqlRS_StopReportingServicesInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node $AllNodes.NodeName
    {
        Service ('StopReportingServicesInstance{0}' -f $Node.InstanceName)
        {
            Name  = ('ReportServer${0}' -f $Node.InstanceName)
            State = 'Stopped'
        }
    }
}
