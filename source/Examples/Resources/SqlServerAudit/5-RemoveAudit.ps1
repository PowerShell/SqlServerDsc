<#
    .EXAMPLE
        This example shows how to ensure that an audit destination
        is absent on the instance sqltest.company.local\DSC.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerAudit FileAudit_Server
        {
            Ensure               = 'Absent'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Name                 = 'FileAudit'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
