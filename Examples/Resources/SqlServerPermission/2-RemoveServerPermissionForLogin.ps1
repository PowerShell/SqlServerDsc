<#
    .EXAMPLE
        This example will remove the server permissions AlterAnyAvailabilityGroup and ViewServerState
        from the login 'NT AUTHORITY\SYSTEM'.
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
        # Add permission
        SqlServerPermission SQLConfigureServerPermission
        {
            Ensure               = 'Absent'
            ServerName           = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            Principal            = 'NT AUTHORITY\SYSTEM'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
