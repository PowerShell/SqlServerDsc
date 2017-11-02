<#
    .EXAMPLE
        This example shows how to install a named instance of SQL Server on a single server, from an UNC path.
    .NOTES
        Assumes the credentials assigned to SourceCredential have read permission on the share and on the UNC path.
        The media will be copied locally, using impersonation with the credentials provided in SourceCredential, so
        that the SYSTEM account can access the media locally.

        SQL Server setup is run using the SYSTEM account. Even if SetupCredential is provided
        it is not used to install SQL Server at this time (see issue #139).
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

        #region Install SQL Server
        SqlSetup 'InstallNamedInstance-INST2016'
        {
            InstanceName          = 'INST2016'
            Features              = 'SQLENGINE,AS'
            SQLCollation          = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount         = $SqlServiceCredential
            AgtSvcAccount         = $SqlAgentServiceCredential
            ASSvcAccount          = $SqlServiceCredential
            SQLSysAdminAccounts   = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName
            ASSysAdminAccounts    = 'COMPANY\SQL Administrators', $SqlAdministratorCredential.UserName
            InstallSharedDir      = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir           = 'C:\Program Files\Microsoft SQL Server'
            InstallSQLDataDir     = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
            SQLUserDBDir          = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
            SQLUserDBLogDir       = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
            SQLTempDBDir          = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
            SQLTempDBLogDir       = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
            SQLBackupDir          = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Backup'
            ASConfigDir           = 'C:\MSOLAP13.INST2016\Config'
            ASDataDir             = 'C:\MSOLAP13.INST2016\Data'
            ASLogDir              = 'C:\MSOLAP13.INST2016\Log'
            ASBackupDir           = 'C:\MSOLAP13.INST2016\Backup'
            ASTempDir             = 'C:\MSOLAP13.INST2016\Temp'
            SourcePath            = '\\fileserver.compant.local\images$\SQL2016RTM'
            SourceCredential      = $SqlInstallCredential
            UpdateEnabled         = 'False'
            ForceReboot           = $false
            BrowserSvcStartupType = 'Automatic'

            PsDscRunAsCredential  = $SqlInstallCredential

            DependsOn             = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45'
        }
        #endregion Install SQL Server
    }
}
