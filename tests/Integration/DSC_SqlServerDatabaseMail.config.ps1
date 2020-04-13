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

                MailServerName  = 'mail.company.local'
                AccountName     = 'MyMail'
                ProfileName     = 'MyMailProfile'
                EmailAddress    = 'NoReply@company.local'
                Description     = 'Default mail account and profile.'
                LoggingLevel    = 'Normal'
                TcpPort         = 25

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Configures database mail.

    .NOTES
        This also enables the option 'Database Mail XPs'.
#>
Configuration MSFT_SqlServerDatabaseMail_Add_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerConfiguration 'EnableDatabaseMailXPs'
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.InstanceName
            OptionName     = 'Database Mail XPs'
            OptionValue    = 1
            RestartService = $false
        }

        SqlServerDatabaseMail 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = $Node.AccountName
            ProfileName          = $Node.ProfileName
            EmailAddress         = $Node.EmailAddress
            ReplyToAddress       = $Node.EmailAddress
            DisplayName          = $Node.MailServerName
            MailServerName       = $Node.MailServerName
            Description          = $Node.Description
            LoggingLevel         = $Node.LoggingLevel
            TcpPort              = $Node.TcpPort

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes database mail.

    .NOTES
        This also disables the option 'Database Mail XPs'.
#>
Configuration MSFT_SqlServerDatabaseMail_Remove_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerDatabaseMail 'Integration_Test'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = $Node.AccountName
            ProfileName          = $Node.ProfileName
            EmailAddress         = $Node.EmailAddress
            MailServerName       = $Node.MailServerName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlServerConfiguration 'DisableDatabaseMailXPs'
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.InstanceName
            OptionName     = 'Database Mail XPs'
            OptionValue    = 0
            RestartService = $false
        }
    }
}
