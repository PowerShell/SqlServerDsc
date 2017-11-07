<#
.EXAMPLE
    This example shows how to ensure that the Availability Group 'TestAG' exists.

    In the event this is applied to a Failover Cluster Instance (FCI), the
    ProcessOnlyOnActiveNode property will tell the Test-TargetResource function
    to evaluate if any changes are needed if the node is actively hosting the
    SQL Server Instance.
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

    Import-DscResource -ModuleName SqlServerDsc

    Node $AllNodes.NodeName {
        # Adding the required service account to allow the cluster to log into SQL
        SqlServerLogin AddNTServiceClusSvc
        {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            SQLServer            = $Node.NodeName
            SQLInstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Add the required permissions to the cluster service login
        SqlServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn            = '[SqlServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            NodeName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Create a DatabaseMirroring endpoint
        SqlServerEndpoint HADREndpoint
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
            SqlAG AddTestAG
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

                DependsOn                     = '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential          = $SysAdminAccount
            }
        }
    }
}
