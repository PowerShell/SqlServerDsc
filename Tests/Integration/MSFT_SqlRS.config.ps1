# Get a spare drive letter
$mockLastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
$mockIsoMediaDriveLetter = [char](([int][char]$mockLastDrive) + 1)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName             = 'localhost'

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

Configuration MSFT_SqlRS_CreateDependencies_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $ReportingServicesServiceCredential
    )

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'StorageDsc'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
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
            UserName = Split-Path -Path $ReportingServicesServiceCredential.UserName -Leaf
            Password = $ReportingServicesServiceCredential
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
            RSSvcAccount          = $ReportingServicesServiceCredential
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

            PsDscRunAsCredential  = $SqlInstallCredential
        }
    }
}

Configuration MSFT_SqlRS_InstallReportingServices_Config
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

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

Configuration MSFT_SqlRS_InstallReportingServices_ConfigureSsl_Config
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

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

Configuration MSFT_SqlRS_InstallReportingServices_RestoreToNoSsl_Config
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

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

Configuration MSFT_SqlRS_StopReportingServicesInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node localhost
    {
        Service ('StopReportingServicesInstance{0}' -f $Node.InstanceName)
        {
            Name  = ('ReportServer${0}' -f $Node.InstanceName)
            State = 'Stopped'
        }
    }
}
