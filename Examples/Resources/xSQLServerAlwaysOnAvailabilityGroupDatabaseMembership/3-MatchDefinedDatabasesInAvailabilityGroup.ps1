[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName= '*'
            PSDscAllowPlainTextPassword = $true
        },

        @{
            NodeName = 'SQL1'
        }
    )
}

Configuration AvailabilityGroupDatabaseMembership
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )
       
    Import-DscResource -ModuleName xSQLServer

    Node $AllNodes.NodeName
    {
        xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership 'AvailabilityGroup1Databases'
        {
            AvailabilityGroupName = 'AG1'
            BackupPath = '\\SQL1\AgInitialize'
            DatabaseName = 'DB*','AdventureWorks'
            SQLInstanceName = 'MSSQLSERVER'
            SQLServer = 'SQL1'
            Ensure = 'Exactly'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
