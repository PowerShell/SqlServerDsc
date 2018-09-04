<#
.EXAMPLE
    This example performs a standard Sql encryption setup. Forcing all connections to be encrypted.
#>
Configuration Example
{
    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlEncryptedConnection DefaultConfiguration
        {
            InstanceName    = 'MSSQLSERVER'
            Thumbprint      = 'fb0b82c94b80da26cf0b86f10ec0c50ae7864a2c'
            ForceEncryption = $true
            Ensure          = 'Present'
            ServiceAccount  = 'SqlSvc'
        }
    }
}
