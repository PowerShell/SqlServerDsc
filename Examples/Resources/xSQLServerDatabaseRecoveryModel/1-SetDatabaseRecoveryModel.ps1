<#
.EXAMPLE
    This example shows how to set the Recovery Model
    to "Full" for SQL database "AdventureWorks". 
#>

Configuration Example 
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    node localhost 
    {
        xSQLServerDatabase Add_SqlDatabaseAdventureworks
        {
            Ensure = 'Present'
            Name = 'Adventureworks'   
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerDatabaseRecoveryModel Set_SqlDatabaseRecoveryModel_Adventureworks
        {
            Name = 'Adventureworks'
            RecoveryModel = 'Full'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
