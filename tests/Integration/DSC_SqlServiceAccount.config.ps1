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
                NodeName                   = 'localhost'

                Install_UserName           = "$env:COMPUTERNAME\SqlInstall"
                Install_Password           = 'P@ssw0rd1'

                SqlPrimary_UserName        = "$env:COMPUTERNAME\svc-SqlPrimary"
                SqlSecondary_UserName      = "$env:COMPUTERNAME\svc-SqlSecondary"
                SqlAgentPrimary_UserName   = "$env:COMPUTERNAME\svc-SqlAgentPri"
                SqlAgentSecondary_UserName = "$env:COMPUTERNAME\svc-SqlAgentSec"
                Password                   = 'yig-C^Equ3'

                ServerName                 = $env:COMPUTERNAME
                DefaultInstanceName        = 'MSSQLSERVER'
                NamedInstanceName          = 'DSCSQLTEST'

                ServiceTypeDatabaseEngine  = 'DatabaseEngine'
                ServiceTypeSqlServerAgent  = 'SqlServerAgent'

                CertificateFile            = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Make sure the dependencies for these tests are configured.

    .NOTES
        The dependencies:
          - Must have the default instance MSSQLSERVER started.
#>
Configuration MSFT_SqlServiceAccount_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'

    node $AllNodes.NodeName
    {
        Service ('StartSqlServerDefaultInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = $Node.DefaultInstanceName
            State = 'Running'
        }

        Service ('StartSqlServerAgentForInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Running'
        }
    }
}

<#
    .SYNOPSIS
        Changes the SQL Server service account of the default instance to a
        different account that was initially used during installation.

    .NOTES
        This test was intentionally meant to run as SYSTEM.
#>
Configuration MSFT_SqlServiceAccount_DatabaseEngine_DefaultInstance_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.DefaultInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            RestartService = $true
            ServiceAccount = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlSecondary_UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Changes the SQL Server Agent service account of the default instance to
        a different account that was initially used during installation.

    .NOTES
        This test is intentionally meant to run using the credentials in
        $SqlInstallCredential.
#>
Configuration MSFT_SqlServiceAccount_SqlServerAgent_DefaultInstance_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.DefaultInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            RestartService       = $true
            ServiceAccount       = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlAgentSecondary_UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Install_UserName, (ConvertTo-SecureString -String $Node.Install_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Reverts the SQL Server service account of the default instance to the
        original account that was initially used during installation.

    .NOTES
        This test was intentionally meant to run as SYSTEM.
#>
Configuration MSFT_SqlServiceAccount_DatabaseEngine_DefaultInstance_Restore_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.DefaultInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            RestartService = $true
            ServiceAccount = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlPrimary_UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Reverts the SQL Server Agent service account of the default instance to
        the original account that was initially used during installation.

    .NOTES
        This test is intentionally meant to run using the credentials in
        $SqlInstallCredential.
#>
Configuration MSFT_SqlServiceAccount_SqlServerAgent_DefaultInstance_Restore_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.DefaultInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            RestartService       = $true
            ServiceAccount       = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlAgentPrimary_UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Install_UserName, (ConvertTo-SecureString -String $Node.Install_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Stopping the default instance service to save memory on the build worker.
#>
Configuration MSFT_SqlServiceAccount_StopSqlServerDefaultInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'

    node $AllNodes.NodeName
    {
        Service ('StopSqlServerAgentForInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Stopped'
        }

        Service ('StopSqlServerDefaultInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = $Node.DefaultInstanceName
            State = 'Stopped'
        }
    }
}

<#
    .SYNOPSIS
        Changes the SQL Server service account of the named instance to a
        different account that was initially used during installation.

    .NOTES
        This test was intentionally meant to run as SYSTEM.
#>
Configuration MSFT_SqlServiceAccount_DatabaseEngine_NamedInstance_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.NamedInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            RestartService = $true
            ServiceAccount = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlSecondary_UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Changes the SQL Server Agent service account of the named instance to
        a different account that was initially used during installation.

    .NOTES
        This test is intentionally meant to run using the credentials in
        $SqlInstallCredential.
#>
Configuration MSFT_SqlServiceAccount_SqlServerAgent_NamedInstance_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.NamedInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            RestartService       = $true
            ServiceAccount       = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlAgentSecondary_UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Install_UserName, (ConvertTo-SecureString -String $Node.Install_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Reverts the SQL Server service account of the named instance to the
        original account that was initially used during installation.

    .NOTES
        This test was intentionally meant to run as SYSTEM.
#>
Configuration MSFT_SqlServiceAccount_DatabaseEngine_NamedInstance_Restore_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.NamedInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            RestartService = $true
            ServiceAccount = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlPrimary_UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Reverts the SQL Server Agent service account of the named instance to
        the original account that was initially used during installation.

    .NOTES
        This test is intentionally meant to run using the credentials in
        $SqlInstallCredential.
#>
Configuration MSFT_SqlServiceAccount_SqlServerAgent_NamedInstance_Restore_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.NamedInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            RestartService       = $true
            ServiceAccount       = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlAgentPrimary_UserName, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Install_UserName, (ConvertTo-SecureString -String $Node.Install_Password -AsPlainText -Force))
        }
    }
}
