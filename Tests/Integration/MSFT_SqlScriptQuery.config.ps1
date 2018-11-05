$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName        = 'localhost'
            ServerName      = $env:COMPUTERNAME
            InstanceName    = 'DSCSQL2016'
            Database1Name   = 'ScriptDatabase3'
            Database2Name   = 'ScriptDatabase4'

            GetQuery        = @'
SELECT Name FROM sys.databases WHERE Name = '$(DatabaseName)' FOR JSON AUTO
'@

            TestQuery       = @'
if (select count(name) from sys.databases where name = '$(DatabaseName)') = 0
BEGIN
    RAISERROR ('Did not find database [$(DatabaseName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [$(DatabaseName)]'
END
'@

            SetQuery        = @'
CREATE DATABASE [$(DatabaseName)]
'@

            CertificateFile = $env:DscPublicCertificatePath
        }
    )
}

Configuration MSFT_SqlScriptQuery_RunSqlScriptQueryAsWindowsUser_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlScriptQuery 'Integration_Test'
        {
            ServerInstance       = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName
            GetQuery             = $Node.GetQuery
            TestQuery            = $Node.TestQuery
            SetQuery             = $Node.SetQuery
            Variable             = @(
                ('DatabaseName={0}' -f $Node.Database1Name)
            )

            QueryTimeout         = 30
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

Configuration MSFT_SqlScriptQuery_RunSqlScriptQueryAsSqlUser_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $UserCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlScriptQuery 'Integration_Test'
        {
            ServerInstance = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName
            GetQuery       = $Node.GetQuery
            TestQuery      = $Node.TestQuery
            SetQuery       = $Node.SetQuery
            Variable       = @(
                ('DatabaseName={0}' -f $Node.Database2Name)
            )
            QueryTimeout   = 30
            Credential     = $UserCredential
        }
    }
}
