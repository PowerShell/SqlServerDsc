configuration MSFT_xSQLServerAlwaysOnService_EnableAlwaysOn_Config
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
