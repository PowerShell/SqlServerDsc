# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            ServerName                  = $env:COMPUTERNAME
            InstanceName                = 'DSCSQL2016'

            PSDscAllowPlainTextPassword = $true

            MailServerName              = 'mail.company.local'
            AccountName                 = 'MyMail'
            ProfileName                 = 'MyMailProfile'
            EmailAddress                = 'NoReply@company.local'
            Description                 = 'Default mail account and profile.'
            LoggingLevel                = 'Normal'
            TcpPort                     = 25
        }
    )
}

Configuration MSFT_SqlServerDatabaseMail_Add_Config
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

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

Configuration MSFT_SqlServerDatabaseMail_Remove_Config
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
        SqlServerDatabaseMail 'Integration_Test'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = $Node.AccountName
            ProfileName          = $Node.ProfileName
            EmailAddress         = $Node.EmailAddress
            MailServerName       = $Node.MailServerName

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}


