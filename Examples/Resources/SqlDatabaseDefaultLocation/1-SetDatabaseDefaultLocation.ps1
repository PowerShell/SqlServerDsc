<#
.EXAMPLE
    This example shows how to manage database default locations for Data, Logs, and Backups for SQL Server.

    In the event this is applied to a Failover Cluster Instance (FCI), the
    ProcessOnlyOnActiveNode property will tell the Test-TargetResource function
    to evaluate if any changes are needed if the node is actively hosting the
    SQL Server Instance.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Data
        {
            SQLServer                       = 'SQLServer'
            SQLInstanceName                 = 'DSC'
            ProcessOnlyOnActiveNode         = $true
            Type                            = 'Data'
            Path                            = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential            = $SysAdminAccount
        }

        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Log
        {
            SQLServer                       = 'SQLServer'
            SQLInstanceName                 = 'DSC'
            ProcessOnlyOnActiveNode         = $true
            Type                            = 'Log'
            Path                            = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential            = $SysAdminAccount
        }

        SqlDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Backup
        {
            SQLServer                       = 'SQLServer'
            SQLInstanceName                 = 'DSC'
            ProcessOnlyOnActiveNode         = $true
            Type                            = 'Backup'
            Path                            = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential            = $SysAdminAccount
        }
    }
}
