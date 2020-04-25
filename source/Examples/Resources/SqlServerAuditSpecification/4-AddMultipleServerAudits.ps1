<#
    .EXAMPLE
        This example shows how to add multiple audit specifications to the same instance.
        Each audit can only contain one audit specification.
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
        SqlServerAudit SecurityLogAudit_Server01
        {
            Ensure                    = 'Present'
            ServerName                = 'sqltest.company.local'
            InstanceName              = 'DSC'
            Name                      = 'SecLogAudit01'
            DestinationType           = 'SecurityLog'
            Enabled                   = $true
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }

        SqlServerAudit SecurityLogAudit_Server02
        {
            Ensure                    = 'Present'
            ServerName                = 'sqltest.company.local'
            InstanceName              = 'DSC'
            Name                      = 'SecLogAudit02'
            DestinationType           = 'SecurityLog'
            Enabled                   = $true
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }

        SqlServerAuditSpecification ServerAuditSpecification_AuditAudit
        {
            Ensure                    = 'Present'
            ServerName                = 'sqltest.company.local'
            InstanceName              = 'DSC'
            Name                      = 'AuditAudit'
            AuditName                 = 'SecLogAudit01'
            Enabled                   = $true
            AuditChangeGroup          = $true
            TraceChangeGroup          = $true
            DependsOn                 = "[SqlServerAudit]SecurityLogAudit_Server01"
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }



        SqlServerAuditSpecification ServerAuditSpecification_AdminAudit
        {
            Ensure                                = 'Present'
            ServerName                            = 'sqltest.company.local'
            InstanceName                          = 'DSC'
            Name                                  = 'AdminAudit'
            AuditName                             = 'SecLogAudit02'
            Enabled                               = $true
            AuditChangeGroup                      = $true
            BackupRestoreGroup                    = $true
            DatabaseObjectChangeGroup             = $true
            DatabaseObjectOwnershipChangeGroup    = $true
            DatabaseObjectPermissionChangeGroup   = $true
            DatabaseOwnershipChangeGroup          = $true
            DatabasePermissionChangeGroup         = $true
            DatabasePrincipalChangeGroup          = $true
            DatabasePrincipalImpersonationGroup   = $true
            DatabaseRoleMemberChangeGroup         = $true
            SchemaObjectChangeGroup               = $true
            SchemaObjectOwnershipChangeGroup      = $true
            SchemaObjectPermissionChangeGroup     = $true
            ServerObjectChangeGroup               = $true
            ServerObjectOwnershipChangeGroup      = $true
            ServerObjectPermissionChangeGroup     = $true
            ServerOperationGroup                  = $true
            ServerPermissionChangeGroup           = $true
            ServerPrincipalChangeGroup            = $true
            ServerPrincipalImpersonationGroup     = $true
            ServerRoleMemberChangeGroup           = $true
            ServerStateChangeGroup                = $true
            TraceChangeGroup                      = $true
            DependsOn                             = "[SqlServerAudit]SecurityLogAudit_Server02"
            PsDscRunAsCredential                  = $SqlAdministratorCredential
        }
    }
}
