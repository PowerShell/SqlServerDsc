<#
.EXAMPLE
This example shows how to ensure that the Windows user 'CONTOSO\WindowsUser' exists.

.EXAMPLE
This example shows how to ensure that the Windows group 'CONTOSO\WindowsGroup' exists.

.EXAMPLE
This example shows how to ensure that the SQL Login 'SqlLogin' exists.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $LoginCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlServerLogin Add_WindowsUser
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\WindowsUser'
            LoginType            = 'WindowsUser'
            ServerName           = 'TestServer.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlServerLogin Add_DisabledWindowsUser
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\WindowsUser2'
            LoginType            = 'WindowsUser'
            ServerName           = 'TestServer.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
            Disabled             = $true
        }

        SqlServerLogin Add_WindowsGroup
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\WindowsGroup'
            LoginType            = 'WindowsGroup'
            ServerName           = 'TestServer.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlServerLogin Add_SqlLogin
        {
            Ensure                         = 'Present'
            Name                           = 'SqlLogin'
            LoginType                      = 'SqlLogin'
            ServerName                     = 'TestServer.company.local'
            InstanceName                   = 'DSC'
            LoginCredential                = $LoginCredential
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true
            PsDscRunAsCredential           = $SysAdminAccount
        }
    }
}
