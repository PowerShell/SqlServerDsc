<#
.EXAMPLE
    This example shows how to set the maximum memory
    configuration option with the automatic configuration.

    In the event this is applied to a Failover Cluster Instance (FCI), the
    ProcessOnlyOnActiveNode property will tell the Test-TargetResource function
    to evaluate if any changes are needed if the node is actively hosting the
    SQL Server instance.
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
        SqlServerMemory Set_SQLServerMaxMemory_ToAuto
        {
            Ensure                  = 'Present'
            DynamicAlloc            = $true
            ServerName              = 'sqltest.company.local'
            InstanceName            = 'DSC'
            PsDscRunAsCredential    = $SysAdminAccount
            ProcessOnlyOnActiveNode = $true
        }
    }
}
