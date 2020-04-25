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
            Ensure                              = 'Present'
            ServerName                          = 'sqltest.company.local'
            InstanceName                        = 'DSC'
            Name                                = 'AdminAudit'
            AuditName                           = 'SecLogAudit'
            Enabled                             = $true
            AuditChangeGroup                    = $true
            BackupRestoreGroup                  = $true
            DatabaseObjectChangeGroup           = $true
            DatabaseObjectOwnershipChangeGroup  = $true
            DatabaseObjectPermissionChangeGroup = $true
            DatabaseOwnershipChangeGroup        = $true
            DatabasePermissionChangeGroup       = $true
            DatabasePrincipalChangeGroup        = $true
            DatabasePrincipalImpersonationGroup = $true
            DatabaseRoleMemberChangeGroup       = $true
            SchemaObjectChangeGroup             = $true
            SchemaObjectOwnershipChangeGroup    = $true
            SchemaObjectPermissionChangeGroup   = $true
            ServerObjectChangeGroup             = $true
            ServerObjectOwnershipChangeGroup    = $true
            ServerObjectPermissionChangeGroup   = $true
            ServerOperationGroup                = $true
            ServerPermissionChangeGroup         = $true
            ServerPrincipalChangeGroup          = $true
            ServerPrincipalImpersonationGroup   = $true
            ServerRoleMemberChangeGroup         = $true
            ServerStateChangeGroup              = $true
            TraceChangeGroup                    = $true
            DependsOn                           = '[SqlServerAudit]SecurityLogAudit_Server'
            PsDscRunAsCredential                = $SqlAdministratorCredential
        }
    }
}
