<#
.EXAMPLE
    This example shows how to disable SQL Server Always On high availability and
    disaster recovery (HADR).
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
        SqlAlwaysOnService 'DisableAlwaysOn'
        {
            Ensure               = 'Absent'
            SQLServer            = 'SP23-VM-SQL1'
            SQLInstanceName      = 'MSSQLSERVER'
            RestartTimeout       = 120

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
