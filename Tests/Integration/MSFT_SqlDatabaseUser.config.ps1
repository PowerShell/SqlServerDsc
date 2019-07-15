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
                CertificateFile = $env:DscPublicCertificatePath

                UserName        = "$env:COMPUTERNAME\SqlAdmin"
                Password        = 'P@ssw0rd1'

                ServerName      = $env:COMPUTERNAME
                InstanceName    = 'DSCSQLTEST'

                # This is created by the SqlDatabase integration tests.
                DatabaseName    = 'Database1'

                User1_Name      = 'User1'
                User1_UserType  = 'Login'
                User1_LoginName = 'DscUser1' # Windows User

                User2_Name      = 'User2'
                User2_UserType  = 'Login'
                User2_LoginName = 'DscUser4' # SQL login

                User3_Name      = 'User3'
                User3_UserType  = 'NoLogin'

                User4_Name      = 'User4'
                User4_UserType  = 'Login'
                User4_LoginName = 'DscSqlUsers1' # Windows Group
            }
        )
    }
}

<#
    .SYNOPSIS
        Creates a database user with a login against a SQL login which is of type
        Windows user.
#>
Configuration MSFT_SqlDatabase_AddDatabaseUser1_Config
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
            UserType     = $Node.User1_Type
            LoginName    = $Node.User1_LoginName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database user with a login against a SQL login which is of type SQL.
#>
Configuration MSFT_SqlDatabase_AddDatabaseUser2_Config
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
            UserType     = $Node.User2_Type
            LoginName    = $Node.User2_LoginName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database user without a login.
#>
Configuration MSFT_SqlDatabase_AddDatabaseUser3_Config
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
            UserType     = $Node.User3_Type

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database user with a login against a SQL login which is of type
        Windows Group.
#>
Configuration MSFT_SqlDatabase_AddDatabaseUser4_Config
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
            UserType     = $Node.User4_Type
            LoginName    = $Node.User4_LoginName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes a database user.
#>
Configuration MSFT_SqlDatabase_RemoveDatabaseUser4_Config
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
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
