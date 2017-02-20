<#
.EXAMPLE
    This example shows how to set the minimum memory to 2GB and the maximum memory
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
        xSQLServerMemory Set_SQLServerMinAndMaxMemory_ToAuto
        {
            Ensure = 'Present'
            DynamicAlloc = $true
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            MinMemory = 2048
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
