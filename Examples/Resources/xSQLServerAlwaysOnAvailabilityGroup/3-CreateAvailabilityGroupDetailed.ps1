<#
.EXAMPLE
    This example shows how to ensure that the Availability Group 'TestAG' exists.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                      = '*'
            SQLInstanceName               = 'MSSQLSERVER'
            ProcessOnlyOnActiveNode       = $true

            AutomatedBackupPreference     = 'Primary'
            AvailabilityMode              = 'SynchronousCommit'
            BackupPriority                = 50
            ConnectionModeInPrimaryRole   = 'AllowAllConnections'
            ConnectionModeInSecondaryRole = 'AllowNoConnections'
            FailoverMode                  = 'Automatic'
            HealthCheckTimeout            = 15000

            BasicAvailabilityGroup        = $False
            DatabaseHealthTrigger         = $True
            DtcSupportEnabled             = $True
        },

        @{
            NodeName                      = 'SP23-VM-SQL1'
            Role                          = 'PrimaryReplica'
        }
    )
}

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    Node $AllNodes.NodeName {
        # Adding the required service account to allow the cluster to log into SQL
        xSQLServerLogin AddNTServiceClusSvc
        {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            SQLServer            = $Node.NodeName
            SQLInstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Add the required permissions to the cluster service login
        xSQLServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn            = '[xSQLServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            NodeName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Create a DatabaseMirroring endpoint
        xSQLServerEndpoint HADREndpoint
        {
            EndPointName         = 'HADR'
            Ensure               = 'Present'
            Port                 = 5022
            SQLServer            = $Node.NodeName
            SQLInstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            xSQLServerAlwaysOnAvailabilityGroup AddTestAG
            {
                Ensure                        = 'Present'
                Name                          = 'TestAG'
                SQLInstanceName               = $Node.SQLInstanceName
                SQLServer                     = $Node.NodeName
                ProcessOnlyOnActiveNode       = $Node.ProcessOnlyOnActiveNode

                AutomatedBackupPreference     = $Node.AutomatedBackupPreference
                AvailabilityMode              = $Node.AvailabilityMode
                BackupPriority                = $Node.BackupPriority
                ConnectionModeInPrimaryRole   = $Node.ConnectionModeInPrimaryRole
                ConnectionModeInSecondaryRole = $Node.ConnectionModeInSecondaryRole
                FailoverMode                  = $Node.FailoverMode
                HealthCheckTimeout            = $Node.HealthCheckTimeout

                # sql server 2016 or later only
                BasicAvailabilityGroup        = $Node.BasicAvailabilityGroup
                DatabaseHealthTrigger         = $Node.DatabaseHealthTrigger
                DtcSupportEnabled             = $Node.DtcSupportEnabled

                DependsOn                     = '[xSQLServerEndpoint]HADREndpoint', '[xSQLServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential          = $SysAdminAccount
            }
        }
    }
}
