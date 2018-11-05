$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName         = 'localhost'
            ServerName       = $env:COMPUTERNAME
            InstanceName     = 'DSCSQL2016'

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

Configuration MSFT_SqlServerLogin_CreateDependencies_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $UserCredential
    )

    Import-DscResource -ModuleName 'PSDscResources'

    node localhost {
        User 'CreateDscUser1'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser1Name -Leaf
            Password = $UserCredential
        }

        User 'CreateDscUser2'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser2Name -Leaf
            Password = $UserCredential
        }

        User 'CreateDscUser3'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.DscUser3Name -Leaf
            Password = $UserCredential
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
    }
}

Configuration MSFT_SqlServerLogin_AddLoginDscUser1_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser1Name
            LoginType            = $Node.DscUser1Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

Configuration MSFT_SqlServerLogin_AddLoginDscUser2_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser2Name
            LoginType            = $Node.DscUser2Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

Configuration MSFT_SqlServerLogin_AddLoginDscUser3_Disabled_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscUser3Name
            LoginType            = $Node.DscUser3Type
            Disabled             = $true

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

Configuration MSFT_SqlServerLogin_AddLoginDscUser4_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $UserCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServerLogin 'Integration_Test'
        {
            Ensure                         = 'Present'
            Name                           = $Node.DscUser4Name
            LoginType                      = $Node.DscUser4Type
            LoginCredential                = $UserCredential
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential           = $SqlAdministratorCredential
        }
    }
}

Configuration MSFT_SqlServerLogin_AddLoginDscSqlUsers1_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Present'
            Name                 = $Node.DscSqlUsers1Name
            LoginType            = $Node.DscSqlUsers1Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

Configuration MSFT_SqlServerLogin_RemoveLoginDscUser3_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlServerLogin 'Integration_Test'
        {
            Ensure               = 'Absent'
            Name                 = $Node.DscUser3Name
            LoginType            = $Node.DscUser3Type

            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}


