<#
.EXAMPLE
    This example shows how to set the maximum memory
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
        xSQLServerMemory Set_SQLServerMaxMemory_ToAuto
        {
            Ensure = 'Present'
            DynamicAlloc = $true
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
