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

        The resource is run using the SYSTEM account, but the setup is run using impersonation, with the credentials in
        SetupCredential, when Action is 'Addnode'.

        Assumes the credentials assigned to SourceCredential have read permission on the share and on the UNC path.
        The media will be copied locally, using impersonation with the credentials provided in SourceCredential, so
        that the impersonated credentials in SetupCredential can access the media locally.

        Setup cannot be run using PsDscRunAsCredential at this time (see issue #405 and issue #444). That
        also means that at this time PsDscRunAsCredential can not be used to access media on the UNC share.

        There is currently a bug that prevents the resource to logon to the instance if the current node is not the
        active node. This is beacuse the resource tries to logon using the SYSTEM account instead of the credentials
        in SetupCredential, and the resource does not currently support the built-in PsDscRunAsCredential either (see
        issue #444).
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

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        #region Install prerequisites for SQL Server
        WindowsFeature 'NetFramework35'
        {
            Name   = 'NET-Framework-Core'
            Source = '\\fileserver.company.local\images$\Win2k12R2\Sources\Sxs' # Assumes built-in Everyone has read permission to the share and path.
            Ensure = 'Present'
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
        #endregion Install prerequisites for SQL Server

        #region Install SQL Server Failover Cluster
        SqlSetup 'InstallNamedInstanceNode2-INST2016'
        {
            Action                     = 'AddNode'
            ForceReboot                = $false
            UpdateEnabled              = 'False'
            SourcePath                 = '\\fileserver.compant.local\images$\SQL2016RTM'
            SourceCredential           = $SqlInstallCredential

            InstanceName               = 'INST2016'
            Features                   = 'SQLENGINE,AS'

            SQLSvcAccount              = $SqlServiceCredential
            AgtSvcAccount              = $SqlAgentServiceCredential
            ASSvcAccount               = $SqlServiceCredential

            FailoverClusterNetworkName = 'TESTCLU01A'

            PsDscRunAsCredential       = $SqlInstallCredential

            DependsOn                  = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45'
        }
        #region Install SQL Server Failover Cluster
    }
}
