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

            GetSqlScriptPath            = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
            SetSqlScriptPath            = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
            TestSqlScriptPath           = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())

            GetSqlScript                = @'
SELECT Name FROM sys.databases WHERE Name = '$(DatabaseName)' FOR JSON AUTO
'@

            TestSqlScript               = @'
if (select count(name) from sys.databases where name = '$(DatabaseName)') = 0
BEGIN
    RAISERROR ('Did not find database [$(DatabaseName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [$(DatabaseName)]'
END
'@

            SetSqlScript                = @'
CREATE DATABASE [$(DatabaseName)]
'@

            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration MSFT_SqlScript_CreateDependencies_Config
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
        Script 'CreateFile_GetSqlScript'
        {
            SetScript  = {
                $Using:Node.GetSqlScript | Out-File -FilePath $Using:Node.GetSqlScriptPath -Encoding ascii -NoClobber -Force
            }

            TestScript = {
                if (Test-Path -Path $Using:Node.GetSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.GetSqlScriptPath -Raw
                    return $fileContent -eq $Using:Node.GetSqlScript
                }
                else
                {
                    return $false
                }
            }

            GetScript  = {
                $fileContent = $null

                if (Test-Path -Path $Using:Node.GetSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.GetSqlScriptPath -Raw
                }

                return @{
                    Result = $fileContent
                }
            }
        }

        Script 'CreateFile_TestSqlScript'
        {
            SetScript  = {
                $Using:Node.TestSqlScript | Out-File -FilePath $Using:Node.TestSqlScriptPath -Encoding ascii -NoClobber -Force
            }

            TestScript = {
                if (Test-Path -Path $Using:Node.TestSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.TestSqlScriptPath -Raw
                    return $fileContent -eq $Using:Node.TestSqlScript
                }
                else
                {
                    return $false
                }
            }

            GetScript  = {
                $fileContent = $null

                if (Test-Path -Path $Using:Node.TestSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.TestSqlScriptPath -Raw
                }

                return @{
                    Result = $fileContent
                }
            }
        }

        Script 'CreateFile_SetSqlScript'
        {
            SetScript  = {
                $Using:Node.SetSqlScript | Out-File -FilePath $Using:Node.SetSqlScriptPath -Encoding ascii -NoClobber -Force
            }

            TestScript = {
                if (Test-Path -Path $Using:Node.SetSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.SetSqlScriptPath -Raw
                    return $fileContent -eq $Using:Node.SetSqlScript
                }
                else
                {
                    return $false
                }
            }

            GetScript  = {
                $fileContent = $null

                if (Test-Path -Path $Using:Node.SetSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.SetSqlScriptPath -Raw
                }

                return @{
                    Result = $fileContent
                }
            }
        }

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

Configuration MSFT_SqlScript_RunSqlScriptAsWindowsUser_Config
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
        SqlScript 'Integration_Test'
        {
            ServerInstance       = "$($Node.ServerName)\$($Node.InstanceName)"

            GetFilePath          = $Node.GetSqlScriptPath
            TestFilePath         = $Node.TestSqlScriptPath
            SetFilePath          = $Node.SetSqlScriptPath
            Variable             = @(
                ('DatabaseName={0}' -f $Node.Database1Name)
            )
            QueryTimeout         = 30

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

Configuration MSFT_SqlScript_RunSqlScriptAsSqlUser_Config
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
        SqlScript 'Integration_Test'
        {
            ServerInstance = "$($Node.ServerName)\$($Node.InstanceName)"

            GetFilePath    = $Node.GetSqlScriptPath
            TestFilePath   = $Node.TestSqlScriptPath
            SetFilePath    = $Node.SetSqlScriptPath
            Variable       = @(
                ('DatabaseName={0}' -f $Node.Database2Name)
            )
            QueryTimeout   = 30
            Credential     = $UserCredential
        }
    }
}
