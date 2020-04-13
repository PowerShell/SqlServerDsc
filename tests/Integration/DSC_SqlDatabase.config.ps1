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

                DatabaseName1   = 'Database1'
                DatabaseName2   = 'Database2'
                Collation       = 'SQL_Latin1_General_Pref_CP850_CI_AS'
            }
        )
    }
}

<#
    .SYNOPSIS
        Creates a database with standard collation.
#>
Configuration MSFT_SqlDatabase_AddDatabase1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabase 'Integration_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.DatabaseName1

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database with a specific collation.
#>
Configuration MSFT_SqlDatabase_AddDatabase2_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabase 'Integration_Test'
        {
            Ensure       = 'Present'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.DatabaseName2
            Collation    = $Node.Collation

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a database with a specific collation.
#>
Configuration MSFT_SqlDatabase_RemoveDatabase2_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabase 'Integration_Test'
        {
            Ensure       = 'Absent'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.DatabaseName2

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
