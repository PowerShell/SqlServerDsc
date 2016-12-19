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
    Import-DscResource -ModuleName xSqlServer

    node localhost {
        xSQLServerLogin Remove_WindowsUser
        {
            Ensure = 'Absent'
            Name = 'CONTOSO\WindowsUser'
            LoginType = 'WindowsUser'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
        }

        xSQLServerLogin Remove_WindowsGroup
        {
            Ensure = 'Absent'
            Name = 'CONTOSO\WindowsGroup'
            LoginType = 'WindowsGroup'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
        }

        xSQLServerLogin Remove_SqlLogin
        {
            Ensure = 'Absent'
            Name = 'SqlLogin'
            LoginType = 'SqlLogin'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
        }
    }
}
