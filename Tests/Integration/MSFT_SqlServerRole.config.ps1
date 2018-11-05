$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName        = 'localhost'
            ServerName      = $env:COMPUTERNAME
            InstanceName    = 'DSCSQL2016'

            Role1Name       = 'DscServerRole1'
            Role2Name       = 'DscServerRole2'
            Role3Name       = 'DscServerRole3'

            User1Name       = '{0}\{1}' -f $env:COMPUTERNAME, 'DscUser1'
            User2Name       = '{0}\{1}' -f $env:COMPUTERNAME, 'DscUser2'
            User4Name       = 'DscUser4'

            CertificateFile = $env:DscPublicCertificatePath
        }
    )
}

<#
    .SYNOPSIS
        Adds a server role with a single member.
#>
Configuration MSFT_SqlServerRole_AddRole1_Config
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
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.Role1Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            MembersToInclude     = @(
                $Node.User4Name
            )

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

<#
    .SYNOPSIS
        Adds a server role without any members.
#>
Configuration MSFT_SqlServerRole_AddRole2_Config
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
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.Role2Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

<#
    .SYNOPSIS
        Adds a server role with multiple members.
#>
Configuration MSFT_SqlServerRole_AddRole3_Config
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
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.Role3Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Members              = @(
                $Node.User1Name
                $Node.User2Name
            )

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

<#
    .SYNOPSIS
        Forces members in an existing server role to be exactly these members,
        no more, no less.
        Role1 started out with one member, but will end up containing only two
        new members.
#>
Configuration MSFT_SqlServerRole_Role1_ChangeMembers_Config
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
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.Role1Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Members              = @(
                $Node.User1Name
                $Node.User2Name
            )

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

<#
    .SYNOPSIS
        Adding multiple members to an existing group, saving any previous members.
#>
Configuration MSFT_SqlServerRole_Role2_AddMembers_Config
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
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.Role2Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            MembersToInclude     = @(
                $Node.User1Name
                $Node.User2Name
                $Node.User4Name
            )

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

<#
    .SYNOPSIS
        Removes two members from an existing group.
#>
Configuration MSFT_SqlServerRole_Role2_RemoveMembers_Config
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
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.Role2Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            MembersToExclude     = @(
                $Node.User1Name
                $Node.User2Name
            )

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}


Configuration MSFT_SqlServerRole_RemoveRole3_Config
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
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Absent'
            ServerRoleName       = $Node.Role3Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
