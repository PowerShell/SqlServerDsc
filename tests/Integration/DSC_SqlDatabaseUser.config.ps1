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
                NodeName          = 'localhost'
                CertificateFile   = $env:DscPublicCertificatePath

                UserName          = "$env:COMPUTERNAME\SqlAdmin"
                Password          = 'P@ssw0rd1'

                ServerName        = $env:COMPUTERNAME
                InstanceName      = 'DSCSQLTEST'

                # This is created by the SqlDatabase integration tests.
                DatabaseName      = 'Database1'

                User1_Name        = 'User1'
                User1_UserType    = 'Login'
                User1_LoginName   =  "$env:COMPUTERNAME\DscUser1" # Windows User

                User2_Name        = 'User2'
                User2_UserType    = 'Login'
                User2_LoginName   = 'DscUser4' # SQL login

                User3_Name        = 'User3'
                User3_UserType    = 'NoLogin'

                User4_Name        = 'User4'
                User4_UserType    = 'Login'
                User4_LoginName   = "$env:COMPUTERNAME\DscSqlUsers1" # Windows Group

                User5_Name        = 'User5'
                User5_UserType    = 'Certificate'
                CertificateName   = 'Certificate1'

                User6_Name        = 'User6'
                User6_UserType    = 'AsymmetricKey'
                AsymmetricKeyName = 'AsymmetricKey1'
            }
        )
    }
}

<#
    .SYNOPSIS
        Creates a database user with a login against a SQL login which is of type
        Windows user.
#>
Configuration MSFT_SqlDatabaseUser_AddDatabaseUser1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabaseUser 'Integration_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            DatabaseName = $Node.DatabaseName
            Name         = $Node.User1_Name
            UserType     = $Node.User1_UserType
            LoginName    = $Node.User1_LoginName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database user with a login against a SQL login which is of type SQL.
#>
Configuration MSFT_SqlDatabaseUser_AddDatabaseUser2_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabaseUser 'Integration_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            DatabaseName = $Node.DatabaseName
            Name         = $Node.User2_Name
            UserType     = $Node.User2_UserType
            LoginName    = $Node.User2_LoginName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database user without a login.
#>
Configuration MSFT_SqlDatabaseUser_AddDatabaseUser3_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabaseUser 'Integration_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            DatabaseName = $Node.DatabaseName
            Name         = $Node.User3_Name
            UserType     = $Node.User3_UserType

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database user with a login against a SQL login which is of type
        Windows Group.
#>
Configuration MSFT_SqlDatabaseUser_AddDatabaseUser4_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabaseUser 'Integration_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            DatabaseName = $Node.DatabaseName
            Name         = $Node.User4_Name
            UserType     = $Node.User4_UserType
            LoginName    = $Node.User4_LoginName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Re-creates a database user which had a login, to a user without login.
#>
Configuration MSFT_SqlDatabaseUser_RecreateDatabaseUser4_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabaseUser 'Integration_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            DatabaseName = $Node.DatabaseName
            Name         = $Node.User4_Name
            UserType     = 'NoLogin'
            Force        = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes a database user.
#>
Configuration MSFT_SqlDatabaseUser_RemoveDatabaseUser4_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabaseUser 'Integration_Test'
        {
            Ensure       = 'Absent'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            DatabaseName = $Node.DatabaseName
            Name         = $Node.User4_Name

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database user mapped to a certificate.
#>
Configuration MSFT_SqlDatabaseUser_AddDatabaseUser5_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScriptQuery 'CreateDatabaseCertificate'
        {
            ServerInstance = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName

            GetQuery     = @'
SELECT Name FROM [$(DatabaseName)].sys.certificates WHERE Name = '$(CertificateName)' FOR JSON AUTO
'@

            TestQuery    = @'
if (select count(name) from [$(DatabaseName)].sys.certificates where name = '$(CertificateName)') = 0
BEGIN
    RAISERROR ('Did not find the certificate [$(CertificateName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found the certificate [$(CertificateName)]'
END
'@

            SetQuery     = @'
USE [$(DatabaseName)];
CREATE CERTIFICATE [$(CertificateName)]
    ENCRYPTION BY PASSWORD = 'P@ssw0rd1'
    WITH SUBJECT = 'SqlServerDsc Integration Test';
'@

            QueryTimeout = 30
            Variable     = @(
                ('DatabaseName={0}' -f $Node.DatabaseName)
                ('CertificateName={0}' -f $Node.CertificateName)
            )

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlDatabaseUser 'Integration_Test'
        {
            Ensure          = 'Present'
            ServerName      = $Node.ServerName
            InstanceName    = $Node.InstanceName
            DatabaseName    = $Node.DatabaseName
            Name            = $Node.User5_Name
            UserType        = $Node.User5_UserType
            CertificateName = $Node.CertificateName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database user mapped to an asymmetric key.
#>
Configuration MSFT_SqlDatabaseUser_AddDatabaseUser6_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScriptQuery 'CreateDatabaseAsymmetricKey'
        {
            ServerInstance = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName

            GetQuery     = @'
SELECT Name FROM [$(DatabaseName)].sys.asymmetric_keys WHERE Name = '$(AsymmetricKeyName)' FOR JSON AUTO
'@

            TestQuery    = @'
if (select count(name) from [$(DatabaseName)].sys.asymmetric_keys where name = '$(AsymmetricKeyName)') = 0
BEGIN
    RAISERROR ('Did not find the asymmetric key [$(AsymmetricKeyName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found the asymmetric key [$(AsymmetricKeyName)]'
END
'@

            SetQuery     = @'
USE [$(DatabaseName)];
CREATE ASYMMETRIC KEY [$(AsymmetricKeyName)]
    WITH ALGORITHM = RSA_2048
    ENCRYPTION BY PASSWORD = 'P@ssw0rd1';
'@

            QueryTimeout = 30
            Variable     = @(
                ('DatabaseName={0}' -f $Node.DatabaseName)
                ('AsymmetricKeyName={0}' -f $Node.AsymmetricKeyName)
            )

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlDatabaseUser 'Integration_Test'
        {
            Ensure            = 'Present'
            ServerName        = $Node.ServerName
            InstanceName      = $Node.InstanceName
            DatabaseName      = $Node.DatabaseName
            Name              = $Node.User6_Name
            UserType          = $Node.User6_UserType
            AsymmetricKeyName = $Node.AsymmetricKeyName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
