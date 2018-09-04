Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force

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
        [bool]
        $ForceEncryption = $true,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount
    )

    $encryptionSettings = Get-EncryptedConnectionSettings -InstanceName $InstanceName

    return @{
        InstanceName      = [System.String] $InstanceName
        Thumbprint        = [System.String] $encryptionSettings.Certificate
        ForceEncryption   = [boolean] $encryptionSettings.ForceEncryption
        Ensure            = [System.String] $ensure
        ServiceAccount    = [System.String] $ServiceAccount
    }
}

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
        [bool]
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
        InstanceName      = $InstanceName
        Thumbprint        = $Thumbprint
        ForceEncryption   = $ForceEncryption
        Ensure            = $Ensure
        ServiceAccount    = $ServiceAccount
    }

    $encryptionState = Get-TargetResource @parameters

    if($Ensure -eq 'Present')
    {
        if($ForceEncryption -ne $encryptionState.ForceEncryption -or $Thumbprint -ne $encryptionState.Thumbprint)
        {
            Set-EncryptedConnectionSettings -InstanceName $InstanceName -Certificate $Thumbprint -ForceEncryption $ForceEncryption
        }

        if((Get-CertificatePermission -ThumbPrint $Thumbprint -ServiceAccount $ServiceAccount) -eq $false)
        {
            Set-CertificatePermission -ThumbPrint $Thumbprint -ServiceAccount $ServiceAccount
        }
    }
    else
    {
        if($encryptionState.ForceEncryption -eq $true)
        {
            Set-EncryptedConnectionSettings -InstanceName $InstanceName -Certificate '' -ForceEncryption $false
        }
    }

    Restart-SqlService -SQLServer localhost -SQLInstanceName $InstanceName
}

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
        [bool]
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
        InstanceName      = $InstanceName
        Thumbprint        = $Thumbprint
        ForceEncryption   = $ForceEncryption
        Ensure            = $Ensure
        ServiceAccount    = $ServiceAccount
    }

    New-VerboseMessage -Message "Testing state of Encrypted Connection"

    $encryptionState = Get-TargetResource @parameters

    if($Ensure -eq 'Present')
    {
        if($ForceEncryption -ne $encryptionState.ForceEncryption -or $Thumbprint -ne $encryptionState.Thumbprint)
        {
            return $false
        }

        if((Get-CertificatePermission -ThumbPrint $Thumbprint -ServiceAccount $ServiceAccount) -eq $false)
        {
            return $false
        }
    }
    else
    {
        if($encryptionState.ForceEncryption -eq $true)
        {
            return $false
        }
    }

    return $true
}

function Get-EncryptedConnectionSettings
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InstanceName
    )

    $sqlInstanceId = (Get-Item 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').GetValue($instanceName)

    $superSocketNetLib = Get-Item "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer\SuperSocketNetLib"

    return @{
        ForceEncryption = $superSocketNetLib.GetValue('ForceEncryption')
        Certificate = $superSocketNetLib.GetValue('Certificate')
    }
}

function Set-EncryptedConnectionSettings
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $Certificate,

        [Parameter(Mandatory = $true)]
        [bool]
        $ForceEncryption
    )

    $sqlInstanceId = (Get-Item 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').GetValue($InstanceName)

    $superSocketNetLib = Get-Item "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer\SuperSocketNetLib"

    $superSocketNetLib.SetValue('Certificate', $ThumbPrint)
    $superSocketNetLib.SetValue('ForceEncryption', [int]$ForceEncryption)
}

function Set-CertificatePermission
{
    param
    (
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ThumbPrint,

        [Parameter(Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceAccount
    )

    $cert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object -FilterScript { $PSItem.ThumbPrint -eq $ThumbPrint; };

    # Specify the user, the permissions and the permission type
    $permission = "$($ServiceAccount)","Read","Allow"
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission;

    # Location of the machine related keys
    $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\";
    $keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
    $keyFullPath = $keyPath + $keyName;

    try
    {
        # Get the current acl of the private key
        $acl = (Get-Item $keyFullPath).GetAccessControl()

        # Add the new ace to the acl of the private key
        $acl.AddAccessRule($accessRule);

        # Write back the new acl
        Set-Acl -Path $keyFullPath -AclObject $acl;
    }
    catch
    {
        throw $_;
    }
}

function Get-CertificatePermission
{
    param
    (
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ThumbPrint,

        [Parameter(Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceAccount
    )

    $cert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object -FilterScript { $PSItem.ThumbPrint -eq $ThumbPrint; };

    # Specify the user, the permissions and the permission type
    $permission = "$($ServiceAccount)","Read","Allow"
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission;

    # Location of the machine related keys
    $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\";
    $keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
    $keyFullPath = $keyPath + $keyName;

    try
    {
        # Get the current acl of the private key
        $acl = (Get-Item $keyFullPath).GetAccessControl()

        [array]$permissions = $acl.Access.Where({$_.IdentityReference -eq $accessRule.IdentityReference})
        if($permissions.Count -eq 0)
        {
            return $false
        }

        $rights = $permissions[0].FileSystemRights.value__
        if(($rights -bor 131209) -ne $rights)
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
