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

                ComputerName    = $env:COMPUTERNAME
                InstanceName    = 'DSCSQLTEST'
                RestartTimeout  = 120

                DataFilePath    = 'C:\SQLData\'
                LogFilePath     = 'C:\SQLLog\'

                # Ending backslash is regression test for issue #1307.
                BackupFilePath  = 'C:\Backups\'

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Changes the DATA default location
#>
Configuration DSC_SqlDatabaseDefaultLocation_Data_Config
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
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

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            DependsOn            = '[File]SQLDataPath'
        }
    }
}

<#
    .SYNOPSIS
        Changes the LOG default location
#>
Configuration DSC_SqlDatabaseDefaultLocation_Log_Config
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
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

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            DependsOn            = '[File]SQLLogPath'
        }
    }
}

<#
    .SYNOPSIS
        Changes the BACKUP default location
#>
Configuration DSC_SqlDatabaseDefaultLocation_Backup_Config
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
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

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            DependsOn            = '[File]SQLBackupPath'
        }
    }
}
