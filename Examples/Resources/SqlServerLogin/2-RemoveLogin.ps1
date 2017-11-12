<#
.EXAMPLE
This example shows how to remove the Windows user 'CONTOSO\WindowsUser'.

.EXAMPLE
This example shows how to remove Windows group 'CONTOSO\WindowsGroup'.

.EXAMPLE
This example shows how to remove the SQL Login 'SqlLogin'.
#>

Configuration Example
{
    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlServerLogin Remove_WindowsUser
        {
            Ensure       = 'Absent'
            Name         = 'CONTOSO\WindowsUser'
            LoginType    = 'WindowsUser'
            ServerName   = 'TestServer.company.local'
            InstanceName = 'DSC'
        }

        SqlServerLogin Remove_WindowsGroup
        {
            Ensure       = 'Absent'
            Name         = 'CONTOSO\WindowsGroup'
            LoginType    = 'WindowsGroup'
            ServerName   = 'TestServer.company.local'
            InstanceName = 'DSC'
        }

        SqlServerLogin Remove_SqlLogin
        {
            Ensure       = 'Absent'
            Name         = 'SqlLogin'
            LoginType    = 'SqlLogin'
            ServerName   = 'TestServer.company.local'
            InstanceName = 'DSC'
        }
    }
}
