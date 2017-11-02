<#
    .EXAMPLE
        This example shows how to install the first node in a SQL Server failover cluster.
    .NOTES
        This example assumes that a Failover Cluster is already present with a Cluster Name Object (CNO), IP-address.
        This example also assumes that that all necessary shared disks is present, and formatted with the correct
        drive letter, to accomdate the paths used during SQL Server setup. Minimum is one shared disk.
        This example also assumes that the Cluster Name Object (CNO) has the permission to manage Computer Objects in
        the Organizational Unit (OU) where the CNO Computer Object resides in Active Directory. This is neccessary
        so that SQL Server setup can create a Virtual Computer Object (VCO) for the cluster group
        (Windows Server 2012 R2 and earlier) or cluster role (Windows Server 2016 and later). Also so that the
        Virtual Computer Object (VCO) can be removed when the Failover CLuster instance is uninstalled.

        See the DSC resources xFailoverCluster, xStorage and iSCSIDsc for information how to setup a failover cluster
        with DSC.

        The resource is run using the SYSTEM account, but the setup is run using impersonation, with the credentials in
        SetupCredential, when Action is 'InstallFailoverCluster'.

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

    Import-DscResource -ModuleName SqlServerDSC

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
        SqlSetup 'InstallNamedInstanceNode1-INST2016'
        {
            Action                     = 'InstallFailoverCluster'
            ForceReboot                = $false
            UpdateEnabled              = 'False'
            SourcePath                 = '\\fileserver.compant.local\images$\SQL2016RTM'
            SourceCredential           = $SqlInstallCredential

            InstanceName               = 'INST2016'
            Features                   = 'SQLENGINE,AS'

            InstallSharedDir           = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir        = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir                = 'C:\Program Files\Microsoft SQL Server'

            SQLCollation               = 'Finnish_Swedish_CI_AS'
            SQLSvcAccount              = $SqlServiceCredential
            AgtSvcAccount              = $SqlAgentServiceCredential
            SQLSysAdminAccounts        = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName
            ASSvcAccount               = $SqlServiceCredential
            ASSysAdminAccounts         = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName

            # Drive D: must be a shared disk.
            InstallSQLDataDir          = 'D:\MSSQL\Data'
            SQLUserDBDir               = 'D:\MSSQL\Data'
            SQLUserDBLogDir            = 'D:\MSSQL\Log'
            SQLTempDBDir               = 'D:\MSSQL\Temp'
            SQLTempDBLogDir            = 'D:\MSSQL\Temp'
            SQLBackupDir               = 'D:\MSSQL\Backup'
            ASConfigDir                = 'D:\AS\Config'
            ASDataDir                  = 'D:\AS\Data'
            ASLogDir                   = 'D:\AS\Log'
            ASBackupDir                = 'D:\AS\Backup'
            ASTempDir                  = 'D:\AS\Temp'

            FailoverClusterNetworkName = 'TESTCLU01A'
            FailoverClusterIPAddress   = '192.168.0.46'
            FailoverClusterGroupName   = 'TESTCLU01A'

            PsDscRunAsCredential       = $SqlInstallCredential

            DependsOn                  = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45'
        }
        #region Install SQL Server Failover Cluster
    }
}
