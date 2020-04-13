#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'

                Admin_UserName    = "$env:COMPUTERNAME\SqlAdmin"
                Admin_Password    = 'P@ssw0rd1'
                SqlLogin_UserName = "DscAdmin1"
                SqlLogin_Password = 'P@ssw0rd1'

                ServerName      = $env:COMPUTERNAME
                InstanceName    = 'DSCSQLTEST'
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
}

<#
    .SYNOPSIS
        Runs the SQL query as a Windows User.
#>
Configuration DSC_SqlScriptQuery_RunSqlScriptQueryAsWindowsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScriptQuery 'Integration_Test'
        {
            ServerInstance       = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName
            GetQuery             = $Node.GetQuery
            TestQuery            = $Node.TestQuery
            SetQuery             = $Node.SetQuery
            QueryTimeout         = 30
            Variable             = @(
                ('DatabaseName={0}' -f $Node.Database1Name)
            )

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_Username, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Runs the SQL query as a SQL login.
#>
Configuration DSC_SqlScriptQuery_RunSqlScriptQueryAsSqlUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScriptQuery 'Integration_Test'
        {
            ServerInstance = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName
            GetQuery       = $Node.GetQuery
            TestQuery      = $Node.TestQuery
            SetQuery       = $Node.SetQuery
            QueryTimeout   = 30
            Variable       = @(
                ('DatabaseName={0}' -f $Node.Database2Name)
            )
            Credential     = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlLogin_Username, (ConvertTo-SecureString -String $Node.SqlLogin_Password -AsPlainText -Force))
        }
    }
}
