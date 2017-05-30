<#
    .EXAMPLE
        This example shows how to add a node to an existing SQL Server failover cluster.
    .NOTES
        This example assumes that a Failover Cluster is already present with the first SQL Server Failover Cluster
        node already installed.
        This example also assumes that that the same shared disks on the first node is also present on this second
        node.

        See the example 4-InstallNamedInstanceInFailoverClusterFirstNode.ps1 for information how to setup the first
        SQL Server Failover Cluster node.

        The resource is run using the built-in PsDscRunAsCredential parameter. These credentials should be allowed
        to install SQL Server, as well allowed to connect and access to the instance on the active cluster node.
        Normally it is not possible to install using the SYSTEM account, since the system account normally don't
        have the permission necessary to connect and access the active cluster node.

        This examples assumes the credentials assigned to SourceCredential have read permission on the share and
        on the UNC path. The media will be copied locally, using impersonation with the credentials provided in
        SourceCredential. The setup will start from the local location.
        If SourceCredential is not specified, the credentials in PsDscRunAsCredential will be used to directly
        access the UNC path.
#>
Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlInstallCredential,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlAdministratorCredential = $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlServiceCredential,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlAgentServiceCredential = $SqlServiceCredential
    )

    Import-DscResource -ModuleName xSQLServer

    node localhost
    {
        #region Install prerequisites for SQL Server
        WindowsFeature 'NetFramework35' {
           Name = 'NET-Framework-Core'
           Source = '\\fileserver.company.local\images$\Win2k12R2\Sources\Sxs' # Assumes built-in Everyone has read permission to the share and path.
           Ensure = 'Present'
        }

        WindowsFeature 'NetFramework45' {
           Name = 'NET-Framework-45-Core'
           Ensure = 'Present'
        }
        #endregion Install prerequisites for SQL Server

        #region Install SQL Server Failover Cluster
        xSQLServerSetup 'InstallNamedInstanceNode2-INST2016'
        {
            Action = 'AddNode'
            ForceReboot = $false
            UpdateEnabled = 'False'
            SourcePath = '\\fileserver.compant.local\images$\SQL2016RTM'
            SourceCredential = $SqlInstallCredential

            InstanceName = 'INST2016'
            Features = 'SQLENGINE,AS'

            SQLSvcAccount = $SqlServiceCredential
            AgtSvcAccount = $SqlAgentServiceCredential
            ASSvcAccount = $SqlServiceCredential

            FailoverClusterNetworkName = 'TESTCLU01A'

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn = '[WindowsFeature]NetFramework35','[WindowsFeature]NetFramework45'
        }
        #region Install SQL Server Failover Cluster
    }
}
