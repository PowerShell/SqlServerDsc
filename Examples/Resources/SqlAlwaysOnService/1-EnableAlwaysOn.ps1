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
            ServerName           = 'SP23-VM-SQL1'
            InstanceName         = 'MSSQLSERVER'
            RestartTimeout       = 120

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
