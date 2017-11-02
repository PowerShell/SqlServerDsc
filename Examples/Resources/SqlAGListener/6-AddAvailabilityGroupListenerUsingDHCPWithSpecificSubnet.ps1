<#
.EXAMPLE
    This example will add an Availability Group listener using DHCP with a specific subnet.
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
        SqlAGListener AvailabilityGroupListenerWithSameNameAsVCO
        {
            Ensure               = 'Present'
            NodeName             = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            AvailabilityGroup    = 'AG-01'
            Name                 = 'AG-01'
            DHCP                 = $true
            IpAddress            = '192.168.0.1/255.255.252.0'
            Port                 = 5301

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
