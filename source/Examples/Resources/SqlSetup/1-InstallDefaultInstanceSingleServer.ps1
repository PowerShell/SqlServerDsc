<#
    .DESCRIPTION
        This example shows how to install a default instance of SQL Server, and
        Analysis Services in Tabular mode, on a single server.

    .NOTES
        SQL Server setup is run using the SYSTEM account. Even if SetupCredential is provided
        it is not used to install SQL Server at this time (see issue #139).
#>
Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential = $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceCredential = $SqlServiceCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

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

        #region Install SQL Server
        SqlSetup 'InstallDefaultInstance'
        {
            InstanceName           = 'MSSQLSERVER'
            Features               = 'SQLENGINE,AS'
            SQLCollation           = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount          = $SqlServiceCredential
            AgtSvcAccount          = $SqlAgentServiceCredential
            ASSvcAccount           = $SqlServiceCredential
            SQLSysAdminAccounts    = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName
            ASSysAdminAccounts     = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName
            InstallSharedDir       = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir    = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir            = 'C:\Program Files\Microsoft SQL Server'
            InstallSQLDataDir      = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLUserDBDir           = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLUserDBLogDir        = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLTempDBDir           = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLTempDBLogDir        = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLBackupDir           = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup'
            ASServerMode           = 'TABULAR'
            ASConfigDir            = 'C:\MSOLAP\Config'
            ASDataDir              = 'C:\MSOLAP\Data'
            ASLogDir               = 'C:\MSOLAP\Log'
            ASBackupDir            = 'C:\MSOLAP\Backup'
            ASTempDir              = 'C:\MSOLAP\Temp'
            SourcePath             = 'C:\InstallMedia\SQL2016RTM'
            NpEnabled              = $true
            TcpEnabled             = $true
            UpdateEnabled          = 'False'
            ForceReboot            = $false

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn            = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45'
        }
        #endregion Install SQL Server
    }
}
