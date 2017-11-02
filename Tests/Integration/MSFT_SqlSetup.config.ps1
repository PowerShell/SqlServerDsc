# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 1)]
param()

# Get a spare drive letter
$mockLastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
$mockIsoMediaDriveLetter = [char](([int][char]$mockLastDrive) + 1)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'

            InstanceName                = 'DSCSQL2016'
            Features                    = 'SQLENGINE,CONN,BC,SDK'
            SQLCollation                = 'Finnish_Swedish_CI_AS'
            InstallSharedDir            = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir         = 'C:\Program Files (x86)\Microsoft SQL Server'
            UpdateEnabled               = 'False'
            SuppressReboot              = $true # Make sure we don't reboot during testing.
            ForceReboot                 = $false

            ImagePath                   = "$env:TEMP\SQL2016.iso"
            DriveLetter                 = $mockIsoMediaDriveLetter

            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration MSFT_SqlSetup_InstallSqlEngineAsSystem_Config
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
        $SqlServiceCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceCredential
    )

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'xStorage'
    Import-DscResource -ModuleName 'SqlServerDSC'

    node localhost {
        xMountImage 'MountIsoMedia'
        {
            ImagePath   = $Node.ImagePath
            DriveLetter = $Node.DriveLetter
            Ensure      = 'Present'
        }

        xWaitForVolume WaitForMountOfIsoMedia
        {
            DriveLetter      = $Node.DriveLetter
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        User 'CreateSqlServiceAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlServiceCredential.UserName -Leaf
            Password = $SqlServiceCredential
        }

        User 'CreateSqlAgentServiceAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAgentServiceCredential.UserName -Leaf
            Password = $SqlAgentServiceCredential
        }

        User 'CreateSqlInstallAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlInstallCredential.UserName -Leaf
            Password = $SqlInstallCredential
        }

        Group 'AddSqlInstallAsAdministrator'
        {
            Ensure = 'Present'
            GroupName = 'Administrators'
            MembersToInclude = $SqlInstallCredential.UserName
        }

        User 'CreateSqlAdminAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
            Password = $SqlAdministratorCredential
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        SqlSetup 'Integration_Test'
        {
            InstanceName          = $Node.InstanceName
            Features              = $Node.Features
            SourcePath            = "$($Node.DriveLetter):\"
            BrowserSvcStartupType = 'Automatic'
            SQLCollation          = $Node.SQLCollation
            SQLSvcAccount         = $SqlServiceCredential
            AgtSvcAccount         = $SqlAgentServiceCredential
            ASSvcAccount          = $SqlServiceCredential
            InstallSharedDir      = $Node.InstallSharedDir
            InstallSharedWOWDir   = $Node.InstallSharedWOWDir
            UpdateEnabled         = $Node.UpdateEnabled
            SuppressReboot        = $Node.SuppressReboot
            ForceReboot           = $Node.ForceReboot

            # This must be set if using SYSTEM account to install.
            SQLSysAdminAccounts   = @(
                $SqlAdministratorCredential.UserName
                <#
                    Must have permission to properties IsClustered and
                    IsHadrEnable for SqlAlwaysOnService.
                #>
                $SqlInstallCredential.UserName
            )

            DependsOn             = @(
                '[xMountImage]MountIsoMedia'
                '[User]CreateSqlServiceAccount'
                '[User]CreateSqlAgentServiceAccount'
                '[User]CreateSqlInstallAccount'
                '[Group]AddSqlInstallAsAdministrator'
                '[User]CreateSqlAdminAccount'
                '[WindowsFeature]NetFramework45'
            )
        }
    }
}
