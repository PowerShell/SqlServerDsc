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

            DataFilePath                = 'C:\SQLData\'
            LogFilePath                 = 'C:\SQLLog\'
            BackupFilePath              = 'C:\Backups\'
        }
    )
}

Configuration MSFT_SqlDatabaseDefaultLocation_Data_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        File 'SQLDataPath'
        {
            Checksum        = 'SHA-256'
            DestinationPath = $Node.DataFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        SqlDatabaseDefaultLocation 'Integration_Test'
        {
            Type                 = 'Data'
            Path                 = $Node.DataFilePath
            RestartService       = $true
            ServerName           = $Node.ComputerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn            = '[File]SQLDataPath'
        }
    }
}

Configuration MSFT_SqlDatabaseDefaultLocation_Log_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        File 'SQLLogPath'
        {
            Checksum        = 'SHA-256'
            DestinationPath = $Node.LogFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        SqlDatabaseDefaultLocation 'Integration_Test'
        {
            Type                 = 'Log'
            Path                 = $Node.LogFilePath
            RestartService       = $true
            ServerName           = $Node.ComputerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn            = '[File]SQLLogPath'
        }
    }
}

Configuration MSFT_SqlDatabaseDefaultLocation_Backup_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        File 'SQLBackupPath'
        {
            Checksum        = 'SHA-256'
            DestinationPath = $Node.BackupFilePath
            Ensure          = 'Present'
            Force           = $true
            Type            = 'Directory'
        }

        SqlDatabaseDefaultLocation 'Integration_Test'
        {
            Type                 = 'Backup'
            Path                 = $Node.BackupFilePath
            RestartService       = $false
            ServerName           = $Node.ComputerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn            = '[File]SQLBackupPath'
        }
    }
}
