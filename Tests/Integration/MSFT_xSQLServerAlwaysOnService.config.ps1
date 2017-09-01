# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            ComputerName                = $env:COMPUTERNAME
            InstanceName                = 'DSCSQL2016'
            RestartTimeout              = 120

            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration MSFT_xSQLServerAlwaysOnService_EnableAlwaysOn_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'xSQLServer'

    node localhost {
        xSQLServerAlwaysOnService 'Integration_Test'
        {
            Ensure               = 'Present'
            SQLServer            = $Node.ComputerName
            SQLInstanceName      = $Node.InstanceName
            RestartTimeout       = $Node.RestartTimeout

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}
