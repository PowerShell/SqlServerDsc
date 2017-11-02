<#
    .EXAMPLE
        This example will wait for both the cluster roles/groups 'AGTest1' and 'AGTest2'.
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

        SqlWaitForAvailabilityGroup SQLConfigureAG-WaitAGTest2
        {
            Name                 = 'AGTest2'
            RetryIntervalSec     = 20
            RetryCount           = 30

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
