# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'

            ServerName                  = $env:COMPUTERNAME
            InstanceName                = 'DSCSQL2016'

            GetSqlScriptPath            = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
            SetSqlScriptPath            = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
            TestSqlScriptPath           = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())

            GetSqlScript                = @'
SELECT Name FROM sys.databases WHERE Name = 'MyScriptDatabase1' FOR JSON AUTO
'@

            TestSqlScript               = @'
if (select count(name) from sys.databases where name = 'MyScriptDatabase1') = 0
BEGIN
    RAISERROR ('Did not find database [MyScriptDatabase1]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [MyScriptDatabase1]'
END
'@

            SetSqlScript                = @'
CREATE DATABASE [MyScriptDatabase1]
'@

            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration MSFT_SqlScript_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        Script CreateFile_GetSqlScript
        {
            SetScript = {
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

            GetScript = {
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

        Script CreateFile_TestSqlScript
        {
            SetScript = {
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

            GetScript = {
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

        Script CreateFile_SetSqlScript
        {
            SetScript = {
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

            GetScript = {
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
    }
}

Configuration MSFT_SqlScript_RunSqlScriptAsUser_Config
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

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
