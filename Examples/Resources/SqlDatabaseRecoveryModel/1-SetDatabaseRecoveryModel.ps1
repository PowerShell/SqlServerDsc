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

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlDatabase Add_SqlDatabaseAdventureworks
        {
            Ensure               = 'Present'
            Name                 = 'Adventureworks'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlDatabase Add_SqlDatabaseAdventureWorks2012
        {
            Ensure               = 'Present'
            Name                 = 'AdventureWorks2012'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlDatabaseRecoveryModel Set_SqlDatabaseRecoveryModel_Adventureworks
        {
            Name                 = 'Adventureworks'
            RecoveryModel        = 'Full'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        SqlDatabaseRecoveryModel Set_SqlDatabaseRecoveryModel_AdventureWorks2012
        {
            Name                 = 'AdventureWorks2012'
            RecoveryModel        = 'Simple'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
