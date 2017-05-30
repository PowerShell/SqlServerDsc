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
        Virtual Computer Object (VCO) can be removed when the Failover Cluster instance is uninstalled.

        The DSC resource modules xFailoverCluster, xStorage and iSCSIDsc can be use to setup a failover cluste using
        iSCSI. See each indiviual DSC resource modules for information om how to use them.

        The resource in this example is run using the built-in PsDscRunAsCredential parameter. These credentials
        should be allowed to install SQL Server, as well allowed to connect and access to the instance.

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
        xSQLServerSetup 'InstallNamedInstanceNode1-INST2016'
        {
            Action = 'InstallFailoverCluster'
            ForceReboot = $false
            UpdateEnabled = 'False'
            SourcePath = '\\fileserver.compant.local\images$\SQL2016RTM'
            SourceCredential = $SqlInstallCredential

            InstanceName = 'INST2016'
            Features = 'SQLENGINE,AS'

            InstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir = 'C:\Program Files\Microsoft SQL Server'

            SQLCollation = 'Finnish_Swedish_CI_AS'
            SQLSvcAccount = $SqlServiceCredential
            AgtSvcAccount = $SqlAgentServiceCredential
            SQLSysAdminAccounts = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName
            ASSvcAccount = $SqlServiceCredential
            ASSysAdminAccounts = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName

            # Drive D: must be a shared disk.
            InstallSQLDataDir = 'D:\MSSQL\Data'
            SQLUserDBDir = 'D:\MSSQL\Data'
            SQLUserDBLogDir = 'D:\MSSQL\Log'
            SQLTempDBDir = 'D:\MSSQL\Temp'
            SQLTempDBLogDir = 'D:\MSSQL\Temp'
            SQLBackupDir = 'D:\MSSQL\Backup'
            ASConfigDir = 'D:\AS\Config'
            ASDataDir = 'D:\AS\Data'
            ASLogDir = 'D:\AS\Log'
            ASBackupDir = 'D:\AS\Backup'
            ASTempDir = 'D:\AS\Temp'

            FailoverClusterNetworkName = 'TESTCLU01A'
            FailoverClusterIPAddress = '192.168.0.46'
            FailoverClusterGroupName = 'TESTCLU01A'

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn = '[WindowsFeature]NetFramework35','[WindowsFeature]NetFramework45'
        }
        #region Install SQL Server Failover Cluster
    }
}
