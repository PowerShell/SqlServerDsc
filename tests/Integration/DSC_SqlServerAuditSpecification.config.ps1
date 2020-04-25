#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'
                CertificateFile = $env:DscPublicCertificatePath

                UserName        = "$env:COMPUTERNAME\SqlAdmin"
                Password        = 'P@ssw0rd1'

                ServerName      = $env:COMPUTERNAME
                InstanceName    = 'DSCSQLTEST'

                AuditName1            = 'FileAudit'
                DestinationType1      = 'File'
                FilePath1             = 'C:\Temp\audit\'
                MaximumFileSize1      = 10
                MaximumFileSizeUnit1  = 'MB'
                MaximumRolloverFiles1 = 11

                AuditSpecificationName = 'AdminAudit'
            }
        )
    }
}

<#
    .SYNOPSIS
        Creates a Server Audit with File destination.
#>
Configuration DSC_SqlServerAuditSpecification_AddAudit1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerAudit 'Integration_TestPrepare'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Name                 = $Node.AuditName1
            DestinationType      = $Node.DestinationType1
            FilePath             = $Node.FilePath1
            MaximumFileSize      = $Node.MaximumFileSize1
            MaximumFileSizeUnit  = $Node.MaximumFileSizeUnit1
            MaximumRolloverFiles = $Node.MaximumRolloverFiles1

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlServerAuditSpecification 'Integration_Test'
        {
            Ensure                    = 'Present'
            ServerName                = $Node.ServerName
            InstanceName              = $Node.InstanceName
            Name                      = $Node.AuditSpecificationName
            AuditName                 = $Node.AuditName1
            Enabled                   = $true
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
            DependsOn                 = "[SqlServerAudit]Integration_TestPrepare"
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }
    }
}

<#
    .SYNOPSIS
        Creates a audit to the securitylog, with a filer.
#>
Configuration DSC_SqlServerAudit_AddSecLogAudit_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerAudit 'Integration_TestPrepare'
        {
            Ensure          = 'Present'
            ServerName      = $Node.ServerName
            InstanceName    = $Node.InstanceName
            Name            = $Node.AuditName2
            DestinationType = $Node.DestinationType2
            Filter          = $Node.Filter2

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

         SqlServerAuditSpecification 'Integration_Test'
        {
            Ensure                    = 'Present'
            ServerName                = $Node.ServerName
            InstanceName              = $Node.InstanceName
            Name                      = $Node.AuditSpecificationName
            AuditName                 = $Node.AuditName1
            Enabled                   = $true
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
            DependsOn                 = "[SqlServerAudit]Integration_TestPrepare"
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }
    }
}

<#
    .SYNOPSIS
        Should remove the filter
#>
Configuration DSC_SqlServerAudit_AddSecLogAuditNoFilter_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerAudit 'Integration_TestPrepare'
        {
            Ensure          = 'Present'
            ServerName      = $Node.ServerName
            InstanceName    = $Node.InstanceName
            Name            = $Node.AuditName2
            DestinationType = $Node.DestinationType2

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

         SqlServerAuditSpecification 'Integration_Test'
        {
            Ensure                    = 'Present'
            ServerName                = $Node.ServerName
            InstanceName              = $Node.InstanceName
            Name                      = $Node.AuditSpecificationName
            AuditName                 = $Node.AuditName1
            Enabled                   = $true
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
            DependsOn                 = "[SqlServerAudit]Integration_TestPrepare"
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }
    }
}

<#
    .SYNOPSIS
        Removes the file audit.
#>
Configuration DSC_SqlServerAudit_RemoveAudit1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlServerAudit 'Integration_TestPrepare'
        {
            Ensure       = 'Absent'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.AuditName1

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlServerAuditSpecification 'Integration_Test'
        {
            Ensure                    = 'Present'
            ServerName                = $Node.ServerName
            InstanceName              = $Node.InstanceName
            Name                      = $Node.AuditSpecificationName
            AuditName                 = $Node.AuditName1
            Enabled                   = $true
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
            DependsOn                 = "[SqlServerAudit]Integration_TestPrepare"
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }
    }
}
