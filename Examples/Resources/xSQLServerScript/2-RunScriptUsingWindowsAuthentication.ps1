<#
.EXAMPLE
    These two example shows how to run SQL script using Windows Authentication.
    First example shows how the resource is run as account SYSTEM. And the second example shows how the resource is run with a user account.
#>

Configuration Example 
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $WindowsCredential
    )

    Import-DscResource -ModuleName xSQLServer

    Node localhost
    {
        xSQLServerScript 'RunSQLScript-AsSYSTEM'
        {
            ServerInstance = 'localhost\SQL2016'

            SetFilePath = 'C:\DSCTemp\SQLScripts\Set-RunSQLScript-AsSYSTEM.sql'
            TestFilePath = 'C:\DSCTemp\SQLScripts\Test-RunSQLScript-AsSYSTEM.sql'
            GetFilePath = 'C:\DSCTemp\SQLScripts\Get-RunSQLScript-AsSYSTEM.sql'
            Variable = @("FilePath=C:\temp\log\AuditFiles")
        }

        xSQLServerScript 'RunSQLScript-AsUSER'
        {
            ServerInstance = 'localhost\SQL2016'

            SetFilePath = 'C:\DSCTemp\SQLScripts\Set-RunSQLScript-AsUSER.sql'
            TestFilePath = 'C:\DSCTemp\SQLScripts\Test-RunSQLScript-AsUSER.sql'
            GetFilePath = 'C:\DSCTemp\SQLScripts\Get-RunSQLScript-AsUSER.sql'
            Variable = @("FilePath=C:\temp\log\AuditFiles")

            PsDscRunAsCredential = $WindowsCredential
        }
    }
}

$configurationData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
        }
    )
}

Example -SqlCredential (Get-Credential) -ConfigurationData $configurationData -OutputPath 'C:\DSCTemp\Configuration'

Start-DscConfiguration -Path 'C:\DSCTemp\Configuration' -Wait -Verbose -Force
