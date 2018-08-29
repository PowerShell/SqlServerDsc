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
            InstanceName                  = 'MSSQLSERVER'
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
            NodeName = 'SP23-VM-SQL1'
            Role     = 'PrimaryReplica'
        }
    )
}

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    Node $AllNodes.NodeName
    {
        # Adding the required service account to allow the cluster to log into SQL
        SqlServerLogin AddNTServiceClusSvc
        {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.InstanceName
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        # Add the required permissions to the cluster service login
        SqlServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn            = '[SqlServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.InstanceName
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        # Create a DatabaseMirroring endpoint
        SqlServerEndpoint HADREndpoint
        {
            EndPointName         = 'HADR'
            Ensure               = 'Present'
            Port                 = 5022
            ServerName           = $Node.NodeName
            InstanceName         = $Node.InstanceName
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlAlwaysOnService EnableHADR
        {
            Ensure               = 'Present'
            InstanceName         = $Node.InstanceName
            ServerName           = $Node.NodeName
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            SqlAG AddTestAG
            {
                Ensure                        = 'Present'
                Name                          = 'TestAG'
                InstanceName                  = $Node.InstanceName
                ServerName                    = $Node.NodeName
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

                DependsOn                     = '[SqlAlwaysOnService]EnableHADR', '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential          = $SqlAdministratorCredential
            }
        }
    }
}
