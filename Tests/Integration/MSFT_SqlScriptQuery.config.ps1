<#
    This is used to make sure the integration test run in the correct order.
    The integration test should run after the integration tests SqlServerLogin
    and SqlServerRole, so any problems in those will be caught first, since
    these integration tests are using those resources.
#>
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 4)]
param()

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'

            ServerName                  = $env:COMPUTERNAME
            InstanceName                = 'DSCSQL2016'

            Database1Name               = 'ScriptDatabase1'
            Database2Name               = 'ScriptDatabase2'

            GetQuery                = @'
SELECT Name FROM sys.databases WHERE Name = '$(DatabaseName)' FOR JSON AUTO
'@

            TestQuery               = @'
if (select count(name) from sys.databases where name = '$(DatabaseName)') = 0
BEGIN
    RAISERROR ('Did not find database [$(DatabaseName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [$(DatabaseName)]'
END
'@

            SetQuery                = @'
CREATE DATABASE [$(DatabaseName)]
'@

            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration MSFT_SqlScriptQuery_CreateDependencies_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $UserCredential
    )

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {

        SqlServerLogin ('Create{0}' -f $UserCredential.UserName)
        {
            Ensure                         = 'Present'
            Name                           = $UserCredential.UserName
            LoginType                      = 'SqlLogin'
            LoginCredential                = $UserCredential
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential           = $SqlAdministratorCredential
        }

        SqlServerRole ('Add{0}ToDbCreator' -f $UserCredential.UserName)
        {
            Ensure               = 'Present'
            ServerRoleName       = 'dbcreator'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Members              = @(
                $UserCredential.UserName
            )

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = @(
                ('[SqlServerLogin]Create{0}' -f $UserCredential.UserName)
            )
        }
    }
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

    node localhost {
        SqlScriptQuery 'Integration_Test'
        {
            ServerInstance       = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName

            GetQuery    = $Node.GetQuery
            TestQuery   = $Node.TestQuery
            SetQuery    = $Node.SetQuery
            Variable    = @(
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

    node localhost {
        SqlScriptQuery 'Integration_Test'
        {
            ServerInstance = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName

            GetQuery    = $Node.GetQuery
            TestQuery   = $Node.TestQuery
            SetQuery    = $Node.SetQuery
            Variable    = @(
                ('DatabaseName={0}' -f $Node.Database2Name)
            )
            QueryTimeout   = 30
            Credential     = $UserCredential
        }
    }
}
