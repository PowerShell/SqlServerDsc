<#
.EXAMPLE
    This example will add an Availability Group listener with the same name as the cluster role VCO.
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
        SqlAGListener AvailabilityGroupListenerWithSameNameAsVCO
        {
            Ensure               = 'Present'
            ServerName           = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            AvailabilityGroup    = 'AG-01'
            Name                 = 'AG-01'
            IpAddress            = '192.168.0.73/255.255.255.0'
            Port                 = 5301

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
