$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName        = 'localhost'
            ServerName      = $env:COMPUTERNAME
            InstanceName    = 'DSCSQL2016'

            Thumbprint      = $env:SqlCertificateThumbprint

            CertificateFile = $env:DscPublicCertificatePath
        }
    )
}

Configuration MSFT_SqlServerSecureConnection_AddSecureConnection_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SqlServicePrimaryUserName
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlServerSecureConnection 'Integration_Test'
        {
            InstanceName = $Node.InstanceName
            Ensure = 'Present'
            Thumbprint = $Node.Thumbprint
            ServiceAccount = $SqlServicePrimaryUserName
            ForceEncryption = $true
        }
    }
}

Configuration MSFT_SqlServerSecureConnection_RemoveSecureConnection_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SqlServicePrimaryUserName
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlServerSecureConnection 'Integration_Test'
        {
            InstanceName = $Node.InstanceName
            Ensure = 'Absent'
            Thumbprint = ''
            ServiceAccount = $SqlServicePrimaryUserName
        }
    }
}
