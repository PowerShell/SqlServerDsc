$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                  = 'localhost'
            ServerName                = $env:COMPUTERNAME
            DefaultInstanceName       = 'MSSQLSERVER'
            NamedInstanceName         = 'DSCSQL2016'

            ServiceTypeDatabaseEngine = 'DatabaseEngine'
            ServiceTypeSqlServerAgent = 'SqlServerAgent'

            CertificateFile           = $env:DscPublicCertificatePath
        }
    )
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
    Import-DscResource -ModuleName 'PSDscResources'

    node localhost
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
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceSecondaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.DefaultInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            ServiceAccount = $SqlServiceSecondaryCredential
            RestartService = $true
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
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceSecondaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.DefaultInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            ServiceAccount       = $SqlAgentServiceSecondaryCredential
            RestartService       = $true

            PsDscRunAsCredential = $SqlInstallCredential
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
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.DefaultInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            ServiceAccount = $SqlServicePrimaryCredential
            RestartService = $true
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
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.DefaultInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            ServiceAccount       = $SqlAgentServicePrimaryCredential
            RestartService       = $true

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

<#
    .SYNOPSIS
        Stopping the default instance service to save memory on the build worker.
#>
Configuration MSFT_SqlServiceAccount_StopSqlServerDefaultInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node localhost
    {
        Service ('StartSqlServerAgentForInstance{0}' -f $Node.DefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Stopped'
        }

        Service ('StartSqlServerDefaultInstance{0}' -f $Node.DefaultInstanceName)
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
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceSecondaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.NamedInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            ServiceAccount = $SqlServiceSecondaryCredential
            RestartService = $true
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
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceSecondaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.NamedInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            ServiceAccount       = $SqlAgentServiceSecondaryCredential
            RestartService       = $true

            PsDscRunAsCredential = $SqlInstallCredential
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
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServiceAccount Integration_Test
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.NamedInstanceName
            ServiceType    = $Node.ServiceTypeDatabaseEngine
            ServiceAccount = $SqlServicePrimaryCredential
            RestartService = $true
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
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServiceAccount Integration_Test
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.NamedInstanceName
            ServiceType          = $Node.ServiceTypeSQLServerAgent
            ServiceAccount       = $SqlAgentServicePrimaryCredential
            RestartService       = $true

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}
