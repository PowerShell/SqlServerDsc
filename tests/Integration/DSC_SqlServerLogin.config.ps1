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
                NodeName         = 'localhost'

                Admin_UserName   = "$env:COMPUTERNAME\SqlAdmin"
                Admin_Password   = 'P@ssw0rd1'

                ServerName       = $env:COMPUTERNAME
                InstanceName     = 'DSCSQLTEST'

                DefaultDbName    = 'DefaultDb'

                DscUser1Name     = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscUser1')
                DscUser1Type     = 'WindowsUser'

                DscUser2Name     = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscUser2')
                DscUser2Type     = 'WindowsUser'

                DscUser3Name     = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscUser3')
                DscUser3Type     = 'WindowsUser'

                DscUser4Name     = 'DscUser4'
                DscUser4Type     = 'SqlLogin'

                DscSqlUsers1Name = ('{0}\{1}' -f $env:COMPUTERNAME, 'DscSqlUsers1')
                DscSqlUsers1Type = 'WindowsGroup'

                CertificateFile  = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Creates the logins that are dependencies.
#>
Configuration DSC_SqlServerLogin_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        User 'CreateDscUser1'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser1Name -Leaf
            # Only the password will be used of this credential object.
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        User 'CreateDscUser2'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser2Name -Leaf
            # Only the password will be used of this credential object.
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        User 'CreateDscUser3'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser3Name -Leaf
            # Only the password will be used of this credential object.
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        Group 'CreateDscSqlUsers1'
        {
            Ensure    = 'Present'
            GroupName = 'DscSqlUsers1'
            Members   = @(
                Split-Path -Path $Node.DscUser1Name -Leaf
                Split-Path -Path $Node.DscUser2Name -Leaf
            )

            DependsOn = @(
                '[User]CreateDscUser1'
                '[User]CreateDscUser2'
            )
        }

        SqlDatabase 'DefaultDb_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.DefaultDbName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a Windows User login.
#>
Configuration DSC_SqlServerLogin_AddLoginDscUser1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser1Name
            LoginType            = $Node.DscUser1Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a second Windows User login.
#>
Configuration DSC_SqlServerLogin_AddLoginDscUser2_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser2Name
            LoginType            = $Node.DscUser2Type
            DefaultDatabase      = $Node.DefaultDbName

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a third Windows User login, and creates it as disabled.
#>
Configuration DSC_SqlServerLogin_AddLoginDscUser3_Disabled_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser3Name
            LoginType            = $Node.DscUser3Type
            Disabled             = $true

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a SQL login.
#>
Configuration DSC_SqlServerLogin_AddLoginDscUser4_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser4Name
            LoginType                      = $Node.DscUser4Type
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true
            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a Windows Group login.
#>
Configuration DSC_SqlServerLogin_AddLoginDscSqlUsers1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscSqlUsers1Name
            LoginType            = $Node.DscSqlUsers1Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the third Windows User login that was created.
#>
Configuration DSC_SqlServerLogin_RemoveLoginDscUser3_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Absent'
            Name                 = $Node.DscUser3Name
            LoginType            = $Node.DscUser3Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Clean up test resources so they are not interfering with
        the other integration tests.
#>
Configuration DSC_SqlServerLogin_CleanupDependencies_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabase 'Remove_DefaultDb_Test'
        {
            Ensure       = 'Absent'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.DefaultDbName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}
