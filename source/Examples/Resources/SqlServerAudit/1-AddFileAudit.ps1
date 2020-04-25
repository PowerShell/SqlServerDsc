<#
    .EXAMPLE
        This example shows how to ensure that an audit destination
        is absent on the instance sqltest.company.local\DSC.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerAudit FileAudit_Server
        {
            Ensure               = 'Present'
            ServerName           = 'SQL2019-01'
            InstanceName         = 'INST01'
            Name                 = 'FileAudit'
            DestinationType      = 'File'
            FilePath             = 'C:\Temp\audit'
            MaximumFileSize      = 10
            MaximumFileSizeUnit  = 'MB'
            MaximumRolloverFiles = 11
            Enabled              = $true
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
