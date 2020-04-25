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
        SqlServerAudit SecurityLogAudit_Server
        {
            Ensure               = 'Present'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Name                 = 'SecLogAudit'
            DestinationType      = 'SecurityLog'
            Enabled              = $true
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlServerAuditSpecification 'ServerAuditSpecification_AdminAudit'
        {
            Ensure                                = 'Present'
            ServerName                            = 'sqltest.company.local'
            InstanceName                          = 'DSC'
            Name                                  = 'AdminAudit'
            AuditName                             = 'SecLogAudit'
            Enabled                               = $true
            DatabaseLogoutGroup                   = $true
            FailedDatabaseAuthenticationGroup     = $true
            FailedLoginGroup                      = $true
            LoginChangePasswordGroup              = $true
            LogoutGroup                           = $true
            SuccessfulDatabaseAuthenticationGroup = $true
            SuccessfulLoginGroup                  = $true
            DependsOn                             = '[SqlServerAudit]SecurityLogAudit_Server'
            PsDscRunAsCredential                  = $SqlAdministratorCredential
        }
    }
}
