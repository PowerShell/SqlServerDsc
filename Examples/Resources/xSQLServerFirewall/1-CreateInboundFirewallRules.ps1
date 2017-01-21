<#
.EXAMPLE
    This example shows how to create the default rules for the supported features.
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
        xSQLServerFirewall Create_FirewallRules_For_SQL2012
        {
            Ensure = 'Present'
            Features = 'SQLENGINE,AS,RS,IS'
            InstanceName = 'SQL2012'
            SourcePath = '\\files.company.local\images\SQL2012'

            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerFirewall Create_FirewallRules_For_SQL2016
        {
            Ensure = 'Present'
            Features = 'SQLENGINE'
            InstanceName = 'SQL2016'
            SourcePath = '\\files.company.local\images\SQL2016'

            SourceCredential = $SysAdminAccount
        }
    }
}
