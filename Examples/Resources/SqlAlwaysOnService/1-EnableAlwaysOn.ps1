<#
.EXAMPLE
    This example shows how to enable SQL Server Always On high availability and
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

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlAlwaysOnService 'EnableAlwaysOn'
        {
            Ensure               = 'Present'
            SQLServer            = 'SP23-VM-SQL1'
            SQLInstanceName      = 'MSSQLSERVER'
            RestartTimeout       = 120

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
