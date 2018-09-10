Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') -Force

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlServerSecureConnection'

<#
    .SYNOPSIS
        Gets the SQL Server Encryption status.

    .PARAMETER InstanceName
        Name of the SQL Server instance to be configured.

    .PARAMETER Thumbprint
        Thumbprint of the certificate being used for encryption. If parameter Ensure is set to 'Absent', then the parameter Certificate can be set to an empty string.

    .PARAMETER ForceEncryption
        If all connections to the SQL instance should be encrypted. If this parameter is not assigned a value, the default is that all connections must be encrypted.

    .PARAMETER Ensure
        If Encryption should be Enabled (Present) or Disabled (Absent).

    .PARAMETER ServiceAccount
        Name of the account running the SQL Server service.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Thumbprint,

        [Parameter()]
        [boolean]
        $ForceEncryption = $true,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount
    )

    Write-Verbose -Message (
            $script:localizedData.GetEncryptionSettings `
                -f $InstanceName
    )

    $encryptionSettings = Get-EncryptedConnectionSettings -InstanceName $InstanceName

    Write-Verbose -Message (
                    $script:localizedData.EncryptedSettings `
                        -f $encryptionSettings.Certificate, $encryptionSettings.ForceEncryption
                )

    return @{
        InstanceName    = [System.String] $InstanceName
        Thumbprint      = [System.String] $encryptionSettings.Certificate
        ForceEncryption = [boolean] $encryptionSettings.ForceEncryption
        Ensure          = [System.String] $ensure
        ServiceAccount  = [System.String] $ServiceAccount
    }
}

<#
    .SYNOPSIS
        Enables SQL Server Encryption Connection.

    .PARAMETER InstanceName
        Name of the SQL Server instance to be configured.

    .PARAMETER Thumbprint
        Thumbprint of the certificate being used for encryption. If parameter Ensure is set to 'Absent', then the parameter Certificate can be set to an empty string.

    .PARAMETER ForceEncryption
        If all connections to the SQL instance should be encrypted. If this parameter is not assigned a value, the default is that all connections must be encrypted.

    .PARAMETER Ensure
        If Encryption should be Enabled (Present) or Disabled (Absent).

    .PARAMETER ServiceAccount
        Name of the account running the SQL Server service.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Thumbprint,

        [Parameter()]
        [boolean]
        $ForceEncryption = $true,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount
    )

    $parameters = @{
        InstanceName    = $InstanceName
        Thumbprint      = $Thumbprint
        ForceEncryption = $ForceEncryption
        Ensure          = $Ensure
        ServiceAccount  = $ServiceAccount
    }

    $encryptionState = Get-TargetResource @parameters

    if ($Ensure -eq 'Present')
    {
        if ($ForceEncryption -ne $encryptionState.ForceEncryption -or $Thumbprint -ne $encryptionState.Thumbprint)
        {
            Write-Verbose -Message (
                        $script:localizedData.SetEncryptionSetting `
                            -f $InstanceName, $Thumbprint, $ForceEncryption
            )
            Set-EncryptedConnectionSettings -InstanceName $InstanceName -Thumbprint $Thumbprint -ForceEncryption $ForceEncryption
        }

        if ((Test-CertificatePermission -Thumbprint $Thumbprint -ServiceAccount $ServiceAccount) -eq $false)
        {
            Write-Verbose -Message (
                        $script:localizedData.SetCertificatePermission `
                            -f $Thumbprint, $ServiceAccount
            )
            Set-CertificatePermission -Thumbprint $Thumbprint -ServiceAccount $ServiceAccount
        }
    }
    else
    {
        if ($encryptionState.ForceEncryption -eq $true)
        {
            Write-Verbose -Message (
                        $script:localizedData.SetEncryptionSetting `
                            -f $InstanceName, '', $false
            )
            Set-EncryptedConnectionSettings -InstanceName $InstanceName -Thumbprint '' -ForceEncryption $false
        }
    }

    Write-Verbose -Message (
                $script:localizedData.RestartingService `
                    -f $InstanceName
    )
    Restart-SqlService -SQLServer localhost -SQLInstanceName $InstanceName
}

<#
    .SYNOPSIS
        Tests the SQL Server Encryption configuration.

    .PARAMETER InstanceName
        Name of the SQL Server instance to be configured.

    .PARAMETER Thumbprint
        Thumbprint of the certificate being used for encryption. If parameter Ensure is set to 'Absent', then the parameter Certificate can be set to an empty string.

    .PARAMETER ForceEncryption
        If all connections to the SQL instance should be encrypted. If this parameter is not assigned a value, the default is, set to true, that all connections must be encrypted.

    .PARAMETER Ensure
        If Encryption should be Enabled (Present) or Disabled (Absent).

    .PARAMETER ServiceAccount
        Name of the account running the SQL Server service.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Thumbprint,

        [Parameter()]
        [boolean]
        $ForceEncryption = $true,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount
    )

    $parameters = @{
        InstanceName    = $InstanceName
        Thumbprint      = $Thumbprint
        ForceEncryption = $ForceEncryption
        Ensure          = $Ensure
        ServiceAccount  = $ServiceAccount
    }

    Write-Verbose -Message (
                $script:localizedData.TestingConfiguration `
                    -f $InstanceName
    )

    $encryptionState = Get-TargetResource @parameters

    if ($Ensure -eq 'Present')
    {
        if ($ForceEncryption -ne $encryptionState.ForceEncryption -or $Thumbprint -ne $encryptionState.Thumbprint)
        {
            return $false
        }

        if ((Test-CertificatePermission -Thumbprint $Thumbprint -ServiceAccount $ServiceAccount) -eq $false)
        {
            return $false
        }
    }
    else
    {
        if ($encryptionState.ForceEncryption -eq $true)
        {
            return $false
        }
    }

    return $true
}

<#
    .SYNOPSIS
        Gets the SQL Server Encryption settings. Returns Certificate thumbprint and ForceEncryption setting.

    .PARAMETER InstanceName
        Name of the SQL Server Instance to be configured.
#>
function Get-EncryptedConnectionSettings
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InstanceName
    )

    $sqlInstance = Get-Item 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
    if($sqlInstance)
    {
        try
        {
            $sqlInstanceId = (Get-ItemProperty -Path $sqlInstance.PSPath -Name $InstanceName).$InstanceName
        }
        catch
        {
            throw "Instance not found."
        }
        $superSocketNetLib = Get-Item "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer\SuperSocketNetLib"

        if($superSocketNetLib)
        {
            return @{
                ForceEncryption = (Get-ItemProperty -Path $superSocketNetLib.PSPath -Name "ForceEncryption").ForceEncryption
                Certificate     = (Get-ItemProperty -Path $superSocketNetLib.PSPath -Name "Certificate").Certificate
            }
        }
    }
    return $null
}

<#
    .SYNOPSIS
        Sets the SQL Server Encryption settings.

    .PARAMETER InstanceName
        Name of the SQL Server Instance to be configured.

    .PARAMETER Thumbprint
        Thumbprint of the certificate being used for encryption.

    .PARAMETER ForceEncryption
        If all connections to the SQL instance should be encrypted.
#>
function Set-EncryptedConnectionSettings
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $Thumbprint,

        [Parameter(Mandatory = $true)]
        [boolean]
        $ForceEncryption
    )

    $sqlInstance = Get-Item 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
    if($sqlInstance)
    {
        try
        {
            $sqlInstanceId = (Get-ItemProperty -Path $sqlInstance.PSPath -Name $InstanceName).$InstanceName
        }
        catch
        {
            throw "Instance not found."
        }

        $superSocketNetLib = Get-Item "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer\SuperSocketNetLib"

        if($superSocketNetLib)
        {
            Set-ItemProperty -Path $superSocketNetLib.PSPath -Name 'Certificate' -Value $Thumbprint
            Set-ItemProperty -Path $superSocketNetLib.PSPath -Name 'ForceEncryption' -Value $([int]$ForceEncryption)
        }
    }
}

<#
    .SYNOPSIS
        Gives the service account read permissions to the private key on the certificate.

    .PARAMETER Thumbprint
        Thumbprint of the certificate being used for encryption.

    .PARAMETER ServiceAccount
        The service account running SQL Server service.
#>
function Set-CertificatePermission
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Thumbprint,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceAccount
    )

    $cert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object -FilterScript { $PSItem.Thumbprint -eq $Thumbprint }

    # Specify the user, the permissions and the permission type
    $permission = "$($ServiceAccount)", "Read", "Allow"
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission

    # Location of the machine related keys
    $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"
    $keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $keyFullPath = $keyPath + $keyName

    try
    {
        # Get the current acl of the private key
        $acl = (Get-Item $keyFullPath).GetAccessControl()

        # Add the new ace to the acl of the private key
        $acl.AddAccessRule($accessRule)

        # Write back the new acl
        Set-Acl -Path $keyFullPath -AclObject $acl
    }
    catch
    {
        throw $_
    }
}

<#
    .SYNOPSIS
        Test if the service account has read permissions to the private key on the certificate.

    .PARAMETER Thumbprint
        Thumbprint of the certificate being used for encryption.

    .PARAMETER ServiceAccount
        The service account running SQL Server service.
#>
function Test-CertificatePermission
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Thumbprint,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceAccount
    )

    $cert = Get-ChildItem -Path cert:\LocalMachine\My
    $cert = $cert | Where-Object -FilterScript { $PSItem.Thumbprint -eq $Thumbprint }

    # Specify the user, the permissions and the permission type
    $permission = "$($ServiceAccount)", "Read", "Allow"
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission

    # Location of the machine related keys
    $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"
    $keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $keyFullPath = $keyPath + $keyName

    try
    {
        # Get the current acl of the private key
        $acl = (Get-Item $keyFullPath).GetAccessControl()

        [array]$permissions = $acl.Access.Where( {$_.IdentityReference -eq $accessRule.IdentityReference})
        if ($permissions.Count -eq 0)
        {
            return $false
        }

        $rights = $permissions[0].FileSystemRights.value__

        #check if the rights contains Read permission, 131209 is the bitwise number for read. This allows the permissions to be higher then read.
        if (($rights -bor 131209) -ne $rights)
        {
            return $false
        }

        return $true
    }
    catch
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
