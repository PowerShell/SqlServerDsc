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
                NodeName            = 'localhost'

                UserName            = "$env:COMPUTERNAME\SqlInstall"
                Password            = 'P@ssw0rd1'

                DefaultInstanceName = 'MSSQLSERVER'
                InstanceName        = 'DSCSQLTEST'

                CertificateFile     = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Starting the default instance because it is a prerequisites.
#>
Configuration DSC_SqlServerReplication_Prerequisites_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'

    node $AllNodes.NodeName
    {
        Service ('StopSqlServerInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = $Node.DefaultInstanceName
            State = 'Running'
        }

        Service ('StopSqlServerAgentForInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Running'
        }

        File 'CreateTempFolder'
        {
            DestinationPath = 'C:\Temp'
            Type = 'Directory'
            Ensure = 'Present'

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds the instance as a distributor.
#>
Configuration DSC_SqlServerReplication_AddDistributor_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerReplication 'Integration_Test'
        {
            Ensure               = 'Present'
            DistributorMode      = 'Local'
            WorkingDirectory     = 'C:\Temp'

            <#
                Must be the same database name as the publisher configuration
                in the next test. The default for this parameter is the database
                name 'distribution'.
            #>
            DistributionDBName   = 'MyDistribution'

            # Next test will connect to this instance as a publisher.
            InstanceName         = $Node.InstanceName

            AdminLinkCredentials = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds the instance as a publisher.
#>
Configuration DSC_SqlServerReplication_AddPublisher_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerReplication 'Integration_Test'
        {
            Ensure               = 'Present'
            DistributorMode      = 'Remote'
            WorkingDirectory     = 'C:\Temp'

            <#
                Must be the same database name as in the distributor configuration
                in the previous test. The default for this parameter is the database
                name 'distribution'.
            #>
            DistributionDBName   = 'MyDistribution'

            # This is set to the default instance.
            InstanceName         = $Node.DefaultInstanceName

            <#
                This is set to the instance that was configured as a distributor
                in the previous test.
            #>
            RemoteDistributor    = ('{0}\{1}' -f $env:COMPUTERNAME, $Node.InstanceName)

            AdminLinkCredentials = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the instance as a publisher.
#>
Configuration DSC_SqlServerReplication_RemovePublisher_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerReplication 'Integration_Test'
        {
            Ensure               = 'Absent'
            InstanceName         = $Node.InstanceName
            <#
                Remove using the value 'Local' to avoid needing to specify
                the parameter DistributionDBName. This is a bug in the resource
                and will be resolved by issue #1527.
            #>
            DistributorMode      = 'Local'
            WorkingDirectory     = 'C:\Temp'

            AdminLinkCredentials = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the instance as a distributor.
#>
Configuration DSC_SqlServerReplication_RemoveDistributor_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerReplication 'Integration_Test'
        {
            Ensure               = 'Absent'
            InstanceName         = $Node.InstanceName
            DistributorMode      = 'Local'
            WorkingDirectory     = 'C:\Temp'

            AdminLinkCredentials = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Stopping the default instance to save memory on the build worker.
#>
Configuration DSC_SqlServerReplication_Cleanup_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'

    node $AllNodes.NodeName
    {
        SqlDatabase 'RemoveDatabaseMyDistributionFromDefaultInstance'
        {
            Ensure       = 'Absent'
            ServerName   = $env:COMPUTERNAME
            InstanceName = $Node.DefaultInstanceName
            Name         = 'MyDistribution'

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlDatabase 'RemoveDatabaseMyDistributionFromNamedInstance'
        {
            Ensure       = 'Absent'
            ServerName   = $env:COMPUTERNAME
            InstanceName = $Node.InstanceName
            Name         = 'MyDistribution'

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        Service ('StopSqlServerAgentForInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Stopped'
        }

        Service ('StopSqlServerInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = $Node.DefaultInstanceName
            State = 'Stopped'
        }

        File 'CreateTempFolder'
        {
            DestinationPath = 'C:\Temp'
            Type = 'Directory'
            Ensure = 'Absent'
            Force = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
