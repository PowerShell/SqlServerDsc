<#
    .EXAMPLE
        This example will wait for the cluster role/group 'AGTest1'.
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

    Import-DscResource -ModuleName SqlServerDSC

    node localhost
    {
        SqlWaitForAvailabilityGroup SQLConfigureAG-WaitAGTest1
        {
            Name                 = 'AGTest1'
            RetryIntervalSec     = 20
            RetryCount           = 30

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
