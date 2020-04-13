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
                NodeName          = 'localhost'

                Admin_UserName    = "$env:COMPUTERNAME\SqlAdmin"
                Admin_Password    = 'P@ssw0rd1'
                SqlLogin_UserName = "DscAdmin1"
                SqlLogin_Password = 'P@ssw0rd1'

                ServerName        = $env:COMPUTERNAME
                InstanceName      = 'DSCSQLTEST'

                Database1Name     = 'ScriptDatabase1'
                Database2Name     = 'ScriptDatabase2'

                GetSqlScriptPath  = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
                SetSqlScriptPath  = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
                TestSqlScriptPath = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())

                GetSqlScript      = @'
SELECT Name FROM sys.databases WHERE Name = '$(DatabaseName)' FOR JSON AUTO
'@

                TestSqlScript     = @'
if (select count(name) from sys.databases where name = '$(DatabaseName)') = 0
BEGIN
    RAISERROR ('Did not find database [$(DatabaseName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [$(DatabaseName)]'
END
'@

                SetSqlScript      = @'
CREATE DATABASE [$(DatabaseName)]
'@

                CertificateFile   = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Dependencies for testing the SqlScript resource.
        - Creates the script files, Get, Test, and Set.
        - Creates the SqlLogin and adds it to db_creator role.
#>
Configuration DSC_SqlScript_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        Script 'CreateFile_GetSqlScript'
        {
            SetScript  = {
                $Using:Node.GetSqlScript | Out-File -FilePath $Using:Node.GetSqlScriptPath -Encoding ascii -NoClobber -Force
            }

            TestScript = {
                <#
                    This takes the string of the $GetScript parameter and creates
                    a new script block (during runtime in the resource) and then
                    runs that script block.
                #>
                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                return $getScriptResult.Result -eq $Using:Node.GetSqlScript
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
                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                return $getScriptResult.Result -eq $Using:Node.TestSqlScript
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
                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                return $getScriptResult.Result -eq $Using:Node.SetSqlScript
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

        SqlServerLogin ('Create{0}' -f $Node.SqlLogin_UserName)
        {
            Ensure                         = 'Present'
            Name                           = $Node.SqlLogin_UserName
            LoginType                      = 'SqlLogin'
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlLogin_UserName, (ConvertTo-SecureString -String $Node.SqlLogin_Password -AsPlainText -Force))

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential           = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        SqlServerRole ('Add{0}ToDbCreator' -f $Node.SqlLogin_UserName)
        {
            Ensure               = 'Present'
            ServerRoleName       = 'dbcreator'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Members              = @(
                $Node.SqlLogin_UserName
            )

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))

            DependsOn            = @(
                ('[SqlServerLogin]Create{0}' -f $Node.SqlLogin_UserName)
            )
        }
    }
}

<#
    .SYNOPSIS
        Runs the SQL script as a Windows User.
#>
Configuration DSC_SqlScript_RunSqlScriptAsWindowsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScript 'Integration_Test'
        {
            ServerInstance       = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName

            GetFilePath          = $Node.GetSqlScriptPath
            TestFilePath         = $Node.TestSqlScriptPath
            SetFilePath          = $Node.SetSqlScriptPath
            Variable             = @(
                ('DatabaseName={0}' -f $Node.Database1Name)
            )
            QueryTimeout         = 30

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Runs the SQL script as a SQL login.
#>
Configuration DSC_SqlScript_RunSqlScriptAsSqlUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScript 'Integration_Test'
        {
            ServerInstance = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName

            GetFilePath    = $Node.GetSqlScriptPath
            TestFilePath   = $Node.TestSqlScriptPath
            SetFilePath    = $Node.SetSqlScriptPath
            Variable       = @(
                ('DatabaseName={0}' -f $Node.Database2Name)
            )
            QueryTimeout   = 30
            Credential     = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlLogin_UserName, (ConvertTo-SecureString -String $Node.SqlLogin_Password -AsPlainText -Force))
        }
    }
}
