<#
    .SYNOPSIS
        Ensure the correct module stubs are loaded.

    .PARAMETER SQLVersion
        The major version of the SQL instance.

    .PARAMETER ModuleName
        The name of the module to load the stubs for. Default is 'SqlServer'.
#>
function Import-SQLModuleStub
{
    [CmdletBinding(DefaultParameterSetName = 'Module')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [System.UInt32]
        $SQLVersion,

        [Parameter(ParameterSetName = 'Module')]
        [ValidateSet('SQLPS', 'SqlServer')]
        [System.String]
        $ModuleName = 'SqlServer'
    )

    # Translate the module names to their appropriate stub name
    $modulesAndStubs = @{
        SQLPS     = 'SQLPSStub'
        SqlServer = 'SqlServerStub'
    }

    # Determine which module to ensure is loaded based on the parameters passed
    if ( $PsCmdlet.ParameterSetName -eq 'Version' )
    {
        if ( $SQLVersion -le 12 )
        {
            $ModuleName = 'SQLPS'
        }
        elseif ( $SQLVersion -ge 13 )
        {
            $ModuleName = 'SqlServer'
        }
    }

    # Get the stub name
    $stubModuleName = $modulesAndStubs.$ModuleName

    # Ensure none of the other stub modules are loaded
    [System.Array] $otherStubModules = $modulesAndStubs.Values | Where-Object -FilterScript {
        $_ -ne $stubModuleName
    }

    if ( Get-Module -Name $otherStubModules )
    {
        Remove-Module -Name $otherStubModules
    }

    # If the desired module is not loaded, load it now
    if ( -not ( Get-Module -Name $stubModuleName ) )
    {
        # Build the path to the module stub
        $moduleStubPath = Join-Path -Path ( Join-Path -Path ( Join-Path -Path ( Split-Path -Path $PSScriptRoot -Parent ) -ChildPath Unit ) -ChildPath Stubs ) -ChildPath "$($stubModuleName).psm1"

        Import-Module -Name $moduleStubPath -Force -Global -WarningAction 'SilentlyContinue'
    }
}

<#
    .SYNOPSIS
        Installs the PowerShell module 'LoopbackAdapter' from PowerShell Gallery
        and creates a new network loopback adapter.

    .PARAMETER AdapterName
        The name of the loopback adapter to create.
#>
function New-IntegrationLoopbackAdapter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AdapterName
    )

    $loopbackAdapterModuleName = 'LoopbackAdapter'

    # Ensure the loopback adapter module is downloaded
    if (-not (Get-Module -Name $loopbackAdapterModuleName -ListAvailable))
    {
        throw ('Missing module ''{0}''' -f $loopbackAdapterModuleName)
    }

    # Import the loopback adapter module
    Import-Module -Name $loopbackAdapterModuleName -Force

    $loopbackAdapterParameters = @{
        Name = $AdapterName
    }

    try
    {
        # Does the loopback adapter already exist?
        $null = Get-LoopbackAdapter @loopbackAdapterParameters
    }
    catch
    {
        # The loopback Adapter does not exist so create it
        $loopbackAdapterParameters['Force'] = $true
        $loopbackAdapterParameters['ErrorAction'] = 'Stop'

        $null = New-LoopbackAdapter @loopbackAdapterParameters
    } # try
} # function New-IntegrationLoopbackAdapter

<#
    .SYNOPSIS
        Removes a new network loopback adapter.

    .PARAMETER AdapterName
        The name of the loopback adapter to remove.
#>
function Remove-IntegrationLoopbackAdapter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $AdapterName
    )

    $loopbackAdapterParameters = @{
        Name = $AdapterName
    }

    try
    {
        # Does the loopback adapter exist?
        $null = Get-LoopbackAdapter @loopbackAdapterParameters
    }
    catch
    {
        # Loopback Adapter does not exist - do nothing
        return
    }

    if ($env:APPVEYOR)
    {
        # Running in AppVeyor so force silent uninstall of LoopbackAdapter
        $forceUninstall = $true
    }
    else
    {
        $forceUninstall = $false
    }

    $loopbackAdapterParameters['Force'] = $forceUninstall

    # Remove Loopback Adapter
    Remove-LoopbackAdapter @loopbackAdapterParameters
} # function Remove-IntegrationLoopbackAdapter

<#
    .SYNOPSIS
        Returns the IP network address from an IPv4 address and prefix length.

    .PARAMETER IpAddress
        The IP address to look up.

    .PARAMETER PrefixLength
        The prefix length of the network.
#>
function Get-NetIPAddressNetwork
{
    param
    (
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $PrefixLength
    )

    $cidrNotation = $PrefixLength

    # Create array to hold our output mask.
    $subnetMaskOctet = @()

    # For loop to run through each octet.
    for ($octetNumber = 0; $octetNumber -lt 4; $octetNumber++)
    {
        # If there are 8 or more bits left.
        if ($cidrNotation -gt 7)
        {
            # Add 255 to mask array, and subtract 8 bits.
            $subnetMaskOctet += [byte] 255
            $cidrNotation -= 8
        }
        else
        {
            <#
                Bits are less than 8, calculate octet bits and
                zero out the $cidrNotation variable.
            #>
            $subnetMaskOctet += [byte] 255 -shl (8 - $cidrNotation)
            $cidrNotation = 0
        }
    }

    # Convert the calculated octets to the subnet representation.
    $subnetMask = [IPAddress] ($subnetMaskOctet -join '.')

    $networkAddress = ([IPAddress]($IPAddress.Address -band $subnetMask.Address)).IPAddressToString

    $networkObject = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $networkObject -MemberType NoteProperty -Name 'IPAddress' -Value $IPAddress
    Add-Member -InputObject $networkObject -MemberType NoteProperty -Name 'PrefixLength' -Value $PrefixLength
    Add-Member -InputObject $networkObject -MemberType NoteProperty -Name 'SubnetMask' -Value $subnetMask
    Add-Member -InputObject $networkObject -MemberType NoteProperty -Name 'NetworkAddress' -Value $networkAddress

    return $networkObject
}

<#
    .SYNOPSIS
        This command will create a new self-signed certificate to be used to
        secure Sql Server connection.

    .OUTPUTS
        Returns the created certificate. Writes the path to the public
        certificate in the machine environment variable $env:sqlPrivateCertificatePath,
        and the certificate thumbprint in the machine environment variable
        $env:SqlCertificateThumbprint.
#>
function New-SQLSelfSignedCertificate
{
    [CmdletBinding()]
    param ()

    $sqlPublicCertificatePath = Join-Path -Path $env:temp -ChildPath 'SqlPublicKey.cer'
    $sqlPrivateCertificatePath = Join-Path -Path $env:temp -ChildPath 'SqlPrivateKey.cer'
    $sqlPrivateKeyPassword = ConvertTo-SecureString -String "1234" -Force -AsPlainText

    $certificateSubject = $env:COMPUTERNAME

    <#
        There are build workers still on Windows Server 2012 R2 so let's
        use the alternate method of New-SelfSignedCertificate.
    #>
    Import-Module -Name 'PSPKI'

    $newSelfSignedCertificateExParameters = @{
        Subject            = "CN=$certificateSubject"
        EKU                = 'Server Authentication'
        KeyUsage           = 'KeyEncipherment, DataEncipherment'
        SAN                = "dns:$certificateSubject"
        FriendlyName       = 'Sql Encryption certificate'
        Path               = $sqlPrivateCertificatePath
        Password           = $sqlPrivateKeyPassword
        Exportable         = $true
        KeyLength          = 2048
        ProviderName       = 'Microsoft Enhanced Cryptographic Provider v1.0'
        AlgorithmName      = 'RSA'
        SignatureAlgorithm = 'SHA256'
    }

    $certificate = New-SelfSignedCertificateEx @newSelfSignedCertificateExParameters

    Write-Verbose -Message ('Created self-signed certificate ''{0}'' with thumbprint ''{1}''.' -f $certificate.Subject, $certificate.Thumbprint)

    # Update a machine and session environment variable with the path to the private certificate.
    [Environment]::SetEnvironmentVariable('SqlPrivateCertificatePath', $sqlPrivateCertificatePath, 'Machine')
    Write-Verbose -Message ('Machine environment variable SqlPrivateCertificatePath set to ''{0}''' -f [System.Environment]::GetEnvironmentVariable('SqlPrivateCertificatePath', 'Machine'))

    $env:SqlPrivateCertificatePath = $sqlPrivateCertificatePath
    Write-Verbose -Message ('Session environment variable $env:SqlPrivateCertificatePath set to ''{0}''' -f $env:SqlPrivateCertificatePath)

    # Update a machine and session environment variable with the thumbprint of the certificate.
    [Environment]::SetEnvironmentVariable('SqlCertificateThumbprint', $certificate.Thumbprint, 'Machine')
    Write-Verbose -Message ('Machine environment variable $env:SqlCertificateThumbprint set to ''{0}''' -f [System.Environment]::GetEnvironmentVariable('SqlCertificateThumbprint', 'Machine'))

    $env:SqlCertificateThumbprint = $certificate.Thumbprint
    Write-Verbose -Message ('Session environment variable $env:SqlCertificateThumbprint set to ''{0}''' -f $env:SqlCertificateThumbprint)

    return $certificate
}

<#
    .SYNOPSIS
        Returns $true if the the environment variable APPVEYOR is set to $true,
        and the environment variable CONFIGURATION is set to the value passed
        in the parameter Type.

    .PARAMETER Name
        Name of the test script that is called. Default value is the name of the
        calling script.

    .PARAMETER Type
        Type of tests in the test file. Can be set to Unit or Integration.

    .PARAMETER Category
        Optional. One or more categories to check if they are set in
        $env:CONFIGURATION. If this are not set, the parameter Type
        is used as category.
#>
function Test-BuildCategory
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name = $MyInvocation.PSCommandPath.Split('\')[-1],

        [Parameter(Mandatory = $true)]
        [ValidateSet('Unit', 'Integration')]
        [System.String]
        $Type,

        [Parameter()]
        [System.String[]]
        $Category
    )

    # Support using only the Type parameter as category names.
    if (-not $Category)
    {
        $Category = @($Type)
    }

    $result = $true

    if ($Type -eq 'Integration' -and -not $env:CI -eq $true)
    {
        Write-Warning -Message ('{1} test for {0} will be skipped unless $env:CI is set to $true' -f $Name, $Type)
        $result = $false
    }

    <#
        If running in CI then check if it should run in the
        current category set in $env:CONFIGURATION.
    #>
    if ($env:CI -eq $true -and -not (Test-ContinuousIntegrationTaskCategory -Category $Category))
    {
        Write-Verbose -Message ('{1} tests in {0} will be skipped unless $env:CONFIGURATION is set to ''{1}''.' -f $Name, ($Category -join ''', or ''')) -Verbose
        $result = $false
    }

    return $result
}

<#
    .SYNOPSIS
        Returns $true if the the environment variable APPVEYOR is set to $true,
        and the environment variable CONFIGURATION is set to the value passed
        in the parameter Type.

    .PARAMETER Category
        One or more categories to check if they are set in $env:CONFIGURATION.
#>
function Test-ContinuousIntegrationTaskCategory
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Category
    )

    $result = $false

    if ($env:CI -eq $true -and $env:CONFIGURATION -in $Category)
    {
        $result = $true
    }

    return $result
}

<#
    .SYNOPSIS
        Waits for LCM to become idle.

    .PARAMETER Clear
        If specified, the LCM will also be cleared of DSC configurations.

    .NOTES
        Used in integration test where integration tests run to quickly before
        LCM have time to cool down.
#>
function Wait-ForIdleLcm
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Clear
    )

    while ((Get-DscLocalConfigurationManager).LCMState -ne 'Idle')
    {
        Write-Verbose -Message 'Waiting for the LCM to become idle'

        Start-Sleep -Seconds 2
    }

    if ($Clear)
    {
        Clear-DscLcmConfiguration
    }
}

<#
    .SYNOPSIS
        Returns an invalid operation exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating
        error
#>
function Get-InvalidOperationRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    $newObjectParameters = @{
        TypeName = 'System.InvalidOperationException'
    }

    if ($PSBoundParameters.ContainsKey('Message') -and $PSBoundParameters.ContainsKey('ErrorRecord'))
    {
        $newObjectParameters['ArgumentList'] = @(
            $Message,
            $ErrorRecord.Exception
        )
    }
    elseif ($PSBoundParameters.ContainsKey('Message'))
    {
        $newObjectParameters['ArgumentList'] = @(
            $Message
        )
    }

    $invalidOperationException = New-Object @newObjectParameters

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $invalidOperationException.ToString(),
            'MachineStateIncorrect',
            'InvalidOperation',
            $null
        )
    }

    return New-Object @newObjectParameters
}

<#
    .SYNOPSIS
        Returns an invalid result exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating
        error
#>
function Get-InvalidResultRecord
{
    [CmdletBinding()]
    [Alias('Get-ObjectNotFoundRecord')]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    $newObjectParameters = @{
        TypeName = 'System.Exception'
    }

    if ($PSBoundParameters.ContainsKey('Message') -and $PSBoundParameters.ContainsKey('ErrorRecord'))
    {
        $newObjectParameters['ArgumentList'] = @(
            $Message,
            $ErrorRecord.Exception
        )
    }
    elseif ($PSBoundParameters.ContainsKey('Message'))
    {
        $newObjectParameters['ArgumentList'] = @(
            $Message
        )
    }

    $invalidOperationException = New-Object @newObjectParameters

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $invalidOperationException.ToString(),
            'MachineStateIncorrect',
            'InvalidOperation',
            $null
        )
    }

    return New-Object @newObjectParameters
}

<#
    .SYNOPSIS
        Used to test arguments passed to Start-SqlSetupProcess while inside and It-block.

        This function must be called inside a Mock, since it depends being run inside an It-block.

    .PARAMETER Argument
        A string containing all the arguments separated with space and each argument should start with '/'.
        Only the first string in the array is evaluated.

    .PARAMETER ExpectedArgument
        A hash table containing all the expected arguments.
#>
function Test-SetupArgument
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Argument,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $ExpectedArgument
    )

    $argumentHashTable = @{}

    # Break the argument string into a hash table
    ($Argument -split ' ?/') | ForEach-Object -Process {
        <#
            This regex must support different types of values, and no values:
            /ENU /ACTION="Install" /FEATURES=SQLENGINE /SQLSYSADMINACCOUNTS="COMPANY\sqladmin" "COMPANY\SQLAdmins" /FailoverClusterDisks="Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs"
        #>
        if ($_ -imatch '(\w+)(=([^\/]+)"?)?')
        {
            $key = $Matches[1]
            if ($key -in @('FailoverClusterDisks', 'FailoverClusterIPAddresses'))
            {
                $value = ($Matches[3] -replace '" "', '; ') -replace '"', ''
            }
            elseif ($key -in @('SkipRules'))
            {
                # Do no transformation.
                $value = $Matches[3]
            }
            else
            {
                $value = ($Matches[3] -replace '" "', ' ') -replace '"', ''
            }

            $argumentHashTable.Add($key, $value)
        }
    }

    $actualValues = $argumentHashTable.Clone()

    # Limit the output in the console when everything is fine.
    if ($actualValues.Count -ne $ExpectedArgument.Count)
    {
        Write-Warning -Message 'Verified the setup argument count (expected vs actual)'
        Write-Warning -Message ('Expected: {0}' -f ($ExpectedArgument.Keys -join ','))
        Write-Warning -Message ('Actual: {0}' -f ($actualValues.Keys -join ','))
    }

    # Start by checking whether we have the same number of parameters
    $actualValues.Count | Should -Be $ExpectedArgument.Count `
        -Because ('the expected arguments was: {0}' -f ($ExpectedArgument.Keys -join ','))

    Write-Verbose -Message 'Verified actual setup argument values against expected setup argument values' -Verbose

    foreach ($argumentKey in $ExpectedArgument.Keys)
    {
        $argumentKeyName = $actualValues.GetEnumerator() |
            Where-Object -FilterScript {
                $_.Name -eq $argumentKey
            } | Select-Object -ExpandProperty 'Name'

        $argumentKeyName | Should -Be $argumentKey -Because 'the argument should have been included when setup.exe was called'

        $argumentValue = $actualValues.$argumentKey
        $argumentValue | Should -Be $ExpectedArgument.$argumentKey -Because 'the argument should have been set to the correct value when calling setup.exe'
    }
}
