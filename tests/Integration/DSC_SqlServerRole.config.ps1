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

                UserName        = "$env:COMPUTERNAME\SqlAdmin"
                Password        = 'P@ssw0rd1'

                ServerName      = $env:COMPUTERNAME
                InstanceName    = 'DSCSQLTEST'

                Role1Name       = 'DscServerRole1'
                Role2Name       = 'DscServerRole2'
                Role3Name       = 'DscServerRole3'
                Role4Name       = 'DscServerRole4'
                Role5Name       = 'DscServerRole5'

                User1Name       = '{0}\{1}' -f $env:COMPUTERNAME, 'DscUser1'
                User2Name       = '{0}\{1}' -f $env:COMPUTERNAME, 'DscUser2'
                User4Name       = 'DscUser4'

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Adds a server role with a single member.
#>
Configuration DSC_SqlServerRole_AddRole1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.Role1Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            MembersToInclude     = @(
                $Node.User4Name
            )

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a server role without any members.
#>
Configuration DSC_SqlServerRole_AddRole2_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerRoleName       = $Node.Role2Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a server role with multiple members.
#>
Configuration DSC_SqlServerRole_AddRole3_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
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

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
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
Configuration DSC_SqlServerRole_Role1_ChangeMembers_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
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

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adding multiple members to an existing group, saving any previous members.
#>
Configuration DSC_SqlServerRole_Role2_AddMembers_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
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

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes two members from an existing group.
#>
Configuration DSC_SqlServerRole_Role2_RemoveMembers_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
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

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes an existing group.
#>
Configuration DSC_SqlServerRole_RemoveRole3_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerRole 'Integration_Test'
        {
            Ensure               = 'Absent'
            ServerRoleName       = $Node.Role3Name
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Adds a custom server role to an existing role
#>
Configuration DSC_SqlServerRole_AddNestedRole_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    Node $AllNodes.NodeName
    {
        SqlServerRole $Node.Role4Name
        {
            Ensure = 'Present'
            ServerRoleName = $Node.Role4Name
            ServerName = $Node.ServerName
            InstanceName = $Node.InstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.Username,
                    (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force)
                )
        }

        SqlServerRole $Node.Role5Name
        {
            Ensure = 'Present'
            ServerRoleName = $Node.Role5Name
            ServerName = $Node.ServerName
            InstanceName = $Node.InstanceName

            MembersToInclude = $Node.Role4Name

            DependsOn = "[SqlServerRole]$($Node.Role4Name)"

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.Username,
                    (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force)
                )
        }
    }
}

<#
    .SYNOPSIS
        Removes a custom server role to an existing role
#>
Configuration DSC_SqlServerRole_RemoveNestedRole_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    Node $AllNodes.NodeName
    {
        SqlServerRole $Node.Role5Name
        {
            Ensure = 'Present'
            ServerRoleName = $Node.Role5Name
            ServerName = $Node.ServerName
            InstanceName = $Node.InstanceName

            MembersToExclude = $Node.Role4Name

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.Username,
                    (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force)
                )
        }
    }
}
