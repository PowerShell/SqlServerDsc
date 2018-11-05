# Get a spare drive letter
$mockLastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
$mockIsoMediaDriveLetter = [char](([int][char]$mockLastDrive) + 1)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                              = 'localhost'

            # Database Engine properties.
            DatabaseEngineNamedInstanceName       = 'DSCSQL2016'
            DatabaseEngineNamedInstanceFeatures   = 'SQLENGINE,AS,CONN,BC,SDK'
            AnalysisServicesMultiServerMode       = 'MULTIDIMENSIONAL'

            <#
                Analysis Services Tabular properties.
                The features CONN,BC,SDK is installed with the DSCSQL2016 so those
                features will found for DSCTABULAR instance as well.
                The features is added here so the same property can be used to
                evaluate the result in the test.
            #>
            AnalysisServicesTabularInstanceName   = 'DSCTABULAR'
            AnalysisServicesTabularFeatures       = 'AS,CONN,BC,SDK'
            AnalysisServicesTabularServerMode     = 'TABULAR'

            <#
                Database Engine default instance properties.
                The features CONN,BC,SDK is installed with the DSCSQL2016 so those
                features will found for DSCTABULAR instance as well.
                The features is added here so the same property can be used to
                evaluate the result in the test.
            #>
            DatabaseEngineDefaultInstanceName     = 'MSSQLSERVER'
            DatabaseEngineDefaultInstanceFeatures = 'SQLENGINE,CONN,BC,SDK'

            # General SqlSetup properties
            Collation                             = 'Finnish_Swedish_CI_AS'
            InstallSharedDir                      = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir                   = 'C:\Program Files (x86)\Microsoft SQL Server'
            UpdateEnabled                         = 'False'
            SuppressReboot                        = $true # Make sure we don't reboot during testing.
            ForceReboot                           = $false

            # Properties for mounting media
            ImagePath                             = "$env:TEMP\SQL2016.iso"
            DriveLetter                           = $mockIsoMediaDriveLetter

            CertificateFile                       = $env:DscPublicCertificatePath
        }
    )
}

Configuration MSFT_SqlSetup_CreateDependencies_Config
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
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceSecondaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceSecondaryCredential
    )

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'StorageDsc'

    node localhost
    {
        MountImage 'MountIsoMedia'
        {
            ImagePath   = $Node.ImagePath
            DriveLetter = $Node.DriveLetter
            Ensure      = 'Present'
        }

        WaitForVolume WaitForMountOfIsoMedia
        {
            DriveLetter      = $Node.DriveLetter
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        User 'CreateSqlServicePrimaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlServicePrimaryCredential.UserName -Leaf
            Password = $SqlServicePrimaryCredential
        }

        User 'CreateSqlAgentServicePrimaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAgentServicePrimaryCredential.UserName -Leaf
            Password = $SqlAgentServicePrimaryCredential
        }

        User 'CreateSqlServiceSecondaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlServiceSecondaryCredential.UserName -Leaf
            Password = $SqlServicePrimaryCredential
        }

        User 'CreateSqlAgentServiceSecondaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAgentServiceSecondaryCredential.UserName -Leaf
            Password = $SqlAgentServicePrimaryCredential
        }

        User 'CreateSqlInstallAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlInstallCredential.UserName -Leaf
            Password = $SqlInstallCredential
        }

        Group 'AddSqlInstallAsAdministrator'
        {
            Ensure           = 'Present'
            GroupName        = 'Administrators'
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
    }
}

Configuration MSFT_SqlSetup_InstallDatabaseEngineNamedInstanceAsSystem_Config
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
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlSetup 'Integration_Test'
        {
            InstanceName          = $Node.DatabaseEngineNamedInstanceName
            Features              = $Node.DatabaseEngineNamedInstanceFeatures
            SourcePath            = "$($Node.DriveLetter):\"
            SqlSvcStartupType     = 'Automatic'
            AgtSvcStartupType     = 'Automatic'
            BrowserSvcStartupType = 'Automatic'
            SecurityMode          = 'SQL'
            SAPwd                 = $SqlAdministratorCredential
            SQLCollation          = $Node.Collation
            SQLSvcAccount         = $SqlServicePrimaryCredential
            AgtSvcAccount         = $SqlAgentServicePrimaryCredential
            ASServerMode          = $Node.AnalysisServicesMultiServerMode
            AsSvcStartupType      = 'Automatic'
            ASCollation           = $Node.Collation
            ASSvcAccount          = $SqlServicePrimaryCredential
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

            # This must be set if using SYSTEM account to install.
            ASSysAdminAccounts    = @(
                $SqlAdministratorCredential.UserName
            )
        }
    }
}

Configuration MSFT_SqlSetup_StopMultiAnalysisServicesInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node localhost
    {
        # Service ('StopSqlServerInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        # {
        #     Name   = ('MSSQL${0}' -f $Node.DatabaseEngineNamedInstanceName)
        #     State  = 'Stopped'
        # }

        Service ('StopMultiAnalysisServicesInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name  = ('MSOLAP${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Stopped'
        }
    }
}

Configuration MSFT_SqlSetup_InstallDatabaseEngineDefaultInstanceAsUser_Config
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
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlSetup 'Integration_Test'
        {
            InstanceName         = $Node.DatabaseEngineDefaultInstanceName
            Features             = $Node.DatabaseEngineDefaultInstanceFeatures
            SourcePath           = "$($Node.DriveLetter):\"
            SQLCollation         = $Node.Collation
            SQLSvcAccount        = $SqlServicePrimaryCredential
            AgtSvcAccount        = $SqlAgentServicePrimaryCredential
            InstallSharedDir     = $Node.InstallSharedDir
            InstallSharedWOWDir  = $Node.InstallSharedWOWDir
            UpdateEnabled        = $Node.UpdateEnabled
            SuppressReboot       = $Node.SuppressReboot
            ForceReboot          = $Node.ForceReboot
            SQLSysAdminAccounts  = @(
                $SqlAdministratorCredential.UserName
            )

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

Configuration MSFT_SqlSetup_StopSqlServerDefaultInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node localhost
    {
        Service ('StopSqlServerAgentForInstance{0}' -f $Node.DatabaseEngineDefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Stopped'
        }


        Service ('StopSqlServerInstance{0}' -f $Node.DatabaseEngineDefaultInstanceName)
        {
            Name  = $Node.DatabaseEngineDefaultInstanceName
            State = 'Stopped'
        }
    }
}

Configuration MSFT_SqlSetup_InstallTabularAnalysisServicesAsSystem_Config
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
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential

    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlSetup 'Integration_Test'
        {
            InstanceName        = $Node.AnalysisServicesTabularInstanceName
            Features            = $Node.AnalysisServicesTabularFeatures
            SourcePath          = "$($Node.DriveLetter):\"
            ASServerMode        = $Node.AnalysisServicesTabularServerMode
            ASCollation         = $Node.Collation
            ASSvcAccount        = $SqlServicePrimaryCredential
            InstallSharedDir    = $Node.InstallSharedDir
            InstallSharedWOWDir = $Node.InstallSharedWOWDir
            UpdateEnabled       = $Node.UpdateEnabled
            SuppressReboot      = $Node.SuppressReboot
            ForceReboot         = $Node.ForceReboot

            # This must be set if using SYSTEM account to install.
            ASSysAdminAccounts  = @(
                $SqlAdministratorCredential.UserName
            )
        }
    }
}

Configuration MSFT_SqlSetup_StopTabularAnalysisServices_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node localhost
    {
        Service ('StopTabularAnalysisServicesInstance{0}' -f $Node.AnalysisServicesTabularInstanceName)
        {
            Name  = ('MSOLAP${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Stopped'
        }
    }
}
