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
    
    Import-DscResource -ModuleName xSqlServer

    node localhost {
        xSQLServerLogin Add_WindowsUser
        {
            Ensure = 'Present'
            Name = 'CONTOSO\WindowsUser'
            LoginType = 'WindowsUser'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerLogin Add_WindowsGroup
        {
            Ensure = 'Present'
            Name = 'CONTOSO\WindowsGroup'
            LoginType = 'WindowsGroup'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerLogin Add_SqlLogin
        {
            Ensure = 'Present'
            Name = 'SqlLogin'
            LoginType = 'SqlLogin'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            LoginCredential = $LoginCredential
            LoginMustChangePassword = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced = $true
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
