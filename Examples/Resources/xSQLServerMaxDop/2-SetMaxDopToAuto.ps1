<#
.EXAMPLE
    This example shows how to set max degree of parallelism server 
    configuration option with the automatic configuration.
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
        xSQLServerMaxDop Set_SQLServerMaxDop_ToAuto
        {
            Ensure = 'Present'
            DynamicAlloc = $true
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
