<#
.EXAMPLE
    This example shows how to set the minimum and maximum memory
    configuration option with the default configuration.
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
        SqlServerMemory Set_SQLServerMaxMemory_ToDefault
        {
            Ensure               = 'Absent'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
