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
            Thumbprint      = $CertificateThumbprint
            ForceEncryption = $true
            Ensure          = 'Present'
            ServiceAccount  = 'SqlSvc'
        }
    }
}
