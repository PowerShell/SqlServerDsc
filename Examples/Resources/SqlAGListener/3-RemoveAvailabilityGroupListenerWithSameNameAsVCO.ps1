<#
.EXAMPLE
    This example will remove an Availability Group listener with a different name than cluster role VCO.
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
        SqlAGListener RemoveAvailabilityGroupListenerWithDifferentNameAsVCO
        {
            Ensure               = 'Absent'
            NodeName             = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            AvailabilityGroup    = 'AvailabilityGroup-01'
            Name                 = 'AG-01'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
