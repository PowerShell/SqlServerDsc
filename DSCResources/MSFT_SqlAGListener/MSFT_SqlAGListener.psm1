Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
        Returns the current state of the Availability Group listener.

    .PARAMETER InstanceName
        The SQL Server instance name of the primary replica. Default value is 'MSSQLSERVER'.

    .PARAMETER ServerName
        The host name or FQDN of the primary replica.

    .PARAMETER Name
        The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).

    .PARAMETER AvailabilityGroup
        The name of the availability group to which the availability group listener is or will be connected.
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
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup
    )

    try
    {
        $availabilityGroupListener = Get-SQLAlwaysOnAvailabilityGroupListener -Name $Name -AvailabilityGroup $AvailabilityGroup -ServerName $ServerName -InstanceName $InstanceName

        if ($null -ne $availabilityGroupListener)
        {
            New-VerboseMessage -Message "Listener $Name exist."

            $ensure = 'Present'
            $port = [uint16]( $availabilityGroupListener | Select-Object -ExpandProperty PortNumber )

            $presentIpAddress = $availabilityGroupListener.AvailabilityGroupListenerIPAddresses
            $dhcp = [bool]( $presentIpAddress | Select-Object -First 1 -ExpandProperty IsDHCP )

            $ipAddress = @()
            foreach ($currentIpAddress in $presentIpAddress)
            {
                $ipAddress += "$($currentIpAddress.IPAddress)/$($currentIpAddress.SubnetMask)"
            }
        }
        else
        {
            New-VerboseMessage -Message "Listener $Name does not exist"

            $ensure = 'Absent'
            $port = 0
            $dhcp = $false
            $ipAddress = $null
        }
    }
    catch
    {
        throw New-TerminatingError -ErrorType AvailabilityGroupListenerNotFound -FormatArgs @($Name) -ErrorCategory ObjectNotFound -InnerException $_.Exception
    }

    return @{
        InstanceName      = [System.String] $InstanceName
        ServerName        = [System.String] $ServerName
        Name              = [System.String] $Name
        Ensure            = [System.String] $ensure
        AvailabilityGroup = [System.String] $AvailabilityGroup
        IpAddress         = [System.String[]] $ipAddress
        Port              = [System.UInt16] $port
        DHCP              = [System.Boolean] $dhcp
    }
}

<#
    .SYNOPSIS
        Creates the Availability Group listener.

    .PARAMETER InstanceName
        The SQL Server instance name of the primary replica. Default value is 'MSSQLSERVER'.

    .PARAMETER ServerName
        The host name or FQDN of the primary replica.

    .PARAMETER Name
        The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).

    .PARAMETER Ensure
        If the availability group listener should be present or absent.

    .PARAMETER AvailabilityGroup
        The name of the availability group to which the availability group listener is or will be connected.

    .PARAMETER IpAddress
        The IP address used for the availability group listener, in the format 192.168.10.45/255.255.252.0. If using DHCP, set to the first IP-address of the DHCP subnet, in the format 192.168.8.1/255.255.252.0. Must be valid in the cluster-allowed IP range.

    .PARAMETER Port
        The port used for the availability group listener.

    .PARAMETER DHCP
        If DHCP should be used for the availability group listener instead of static IP address.
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
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [Parameter()]
        [System.String[]]
        $IpAddress,

        [Parameter()]
        [System.UInt16]
        $Port,

        [Parameter()]
        [System.Boolean]
        $DHCP
    )

    $parameters = @{
        InstanceName      = [System.String] $InstanceName
        ServerName        = [System.String] $ServerName
        Name              = [System.String] $Name
        AvailabilityGroup = [System.String] $AvailabilityGroup
    }

    $availabilityGroupListenerState = Get-TargetResource @parameters
    if ($null -ne $availabilityGroupListenerState)
    {
        if ($Ensure -ne '' -and $availabilityGroupListenerState.Ensure -ne $Ensure)
        {
            if ($Ensure -eq 'Present')
            {
                New-VerboseMessage -Message "Create listener on $AvailabilityGroup"

                $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

                $availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
                if ($availabilityGroupObject)
                {
                    $newListenerParams = @{
                        Name        = $Name
                        InputObject = $availabilityGroupObject
                    }

                    if ($Port)
                    {
                        New-VerboseMessage -Message "Listener port set to $Port"
                        $newListenerParams += @{
                            Port = $Port
                        }
                    }

                    if ($DHCP -and $IpAddress.Count -gt 0)
                    {
                        New-VerboseMessage -Message "Listener set to DHCP with subnet $IpAddress"
                        $newListenerParams += @{
                            DhcpSubnet = [System.String] $IpAddress
                        }
                    }
                    elseif (-not $DHCP -and $IpAddress.Count -gt 0)
                    {
                        New-VerboseMessage -Message "Listener set to static IP-address(es); $($IpAddress -join ', ')"
                        $newListenerParams += @{
                            StaticIp = $IpAddress
                        }
                    }
                    else
                    {
                        New-VerboseMessage -Message 'Listener using DHCP with server default subnet'
                    }

                    New-SqlAvailabilityGroupListener @newListenerParams -ErrorAction Stop | Out-Null
                }
                else
                {
                    throw New-TerminatingError -ErrorType AvailabilityGroupNotFound -FormatArgs @($AvailabilityGroup, $InstanceName) -ErrorCategory ObjectNotFound
                }
            }
            else
            {
                New-VerboseMessage -Message "Remove listener from $AvailabilityGroup"

                $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

                $availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
                if ($availabilityGroupObject)
                {
                    $availabilityGroupListenerObject = $availabilityGroupObject.AvailabilityGroupListeners[$Name]
                    if ($availabilityGroupListenerObject)
                    {
                        $availabilityGroupListenerObject.Drop()
                    }
                    else
                    {
                        throw New-TerminatingError -ErrorType AvailabilityGroupListenerNotFound -ErrorCategory ObjectNotFound
                    }
                }
                else
                {
                    throw New-TerminatingError -ErrorType AvailabilityGroupNotFound -FormatArgs @($AvailabilityGroup, $InstanceName) -ErrorCategory ObjectNotFound
                }
            }
        }
        else
        {
            if ($Ensure -ne '')
            {
                New-VerboseMessage -Message "State is already $Ensure"
            }

            if ($availabilityGroupListenerState.Ensure -eq 'Present')
            {
                if (-not $DHCP -and $availabilityGroupListenerState.IpAddress.Count -lt $IpAddress.Count) # Only able to add a new IP-address, not change existing ones.
                {
                    New-VerboseMessage -Message 'Found at least one new IP-address.'
                    $ipAddressEqual = $false
                }
                else
                {
                    # No new IP-address
                    if ($null -eq $IpAddress -or -not ( Compare-Object -ReferenceObject $IpAddress -DifferenceObject $availabilityGroupListenerState.IpAddress))
                    {
                        $ipAddressEqual = $true
                    }
                    else
                    {
                        throw New-TerminatingError -ErrorType AvailabilityGroupListenerIPChangeError -FormatArgs @($($IpAddress -join ', '), $($availabilityGroupListenerState.IpAddress -join ', ')) -ErrorCategory InvalidOperation
                    }
                }

                if ($($PSBoundParameters.ContainsKey('DHCP')) -and $availabilityGroupListenerState.DHCP -ne $DHCP)
                {
                    throw New-TerminatingError -ErrorType AvailabilityGroupListenerDHCPChangeError -FormatArgs @( $DHCP, $($availabilityGroupListenerState.DHCP) ) -ErrorCategory InvalidOperation
                }

                $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

                $availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
                if ($availabilityGroupObject)
                {
                    $availabilityGroupListenerObject = $availabilityGroupObject.AvailabilityGroupListeners[$Name]
                    if ($availabilityGroupListenerObject)
                    {
                        if ($availabilityGroupListenerState.Port -ne $Port -or -not $ipAddressEqual)
                        {
                            New-VerboseMessage -Message 'Listener differ in configuration.'

                            if ($availabilityGroupListenerState.Port -ne $Port)
                            {
                                New-VerboseMessage -Message 'Changing port configuration'

                                $setListenerParams = @{
                                    InputObject = $availabilityGroupListenerObject
                                    Port        = $Port
                                }

                                Set-SqlAvailabilityGroupListener @setListenerParams -ErrorAction Stop | Out-Null
                            }

                            if (-not $ipAddressEqual)
                            {
                                New-VerboseMessage -Message 'Adding IP-address(es)'

                                $newIpAddress = @()

                                foreach ($currentIpAddress in $IpAddress)
                                {
                                    if (-not ( $availabilityGroupListenerState.IpAddress -contains $currentIpAddress))
                                    {
                                        $newIpAddress += $currentIpAddress
                                    }
                                }

                                $setListenerParams = @{
                                    InputObject = $availabilityGroupListenerObject
                                    StaticIp    = $newIpAddress
                                }

                                Add-SqlAvailabilityGroupListenerStaticIp @setListenerParams -ErrorAction Stop | Out-Null
                            }
                        }
                        else
                        {
                            New-VerboseMessage -Message 'Listener configuration is already correct.'
                        }
                    }
                    else
                    {
                        throw New-TerminatingError -ErrorType AvailabilityGroupListenerNotFound -ErrorCategory ObjectNotFound
                    }
                }
                else
                {
                    throw New-TerminatingError -ErrorType AvailabilityGroupNotFound -FormatArgs @($AvailabilityGroup, $InstanceName) -ErrorCategory ObjectNotFound
                }
            }
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
        Tests if the the Availability Group listener is in desired state.

    .PARAMETER InstanceName
        The SQL Server instance name of the primary replica. Default value is 'MSSQLSERVER'.

    .PARAMETER ServerName
        The host name or FQDN of the primary replica.

    .PARAMETER Name
        The name of the availability group listener, max 15 characters. This name will be used as the Virtual Computer Object (VCO).

    .PARAMETER Ensure
        If the availability group listener should be present or absent.

    .PARAMETER AvailabilityGroup
        The name of the availability group to which the availability group listener is or will be connected.

    .PARAMETER IpAddress
        The IP address used for the availability group listener, in the format 192.168.10.45/255.255.252.0. If using DHCP, set to the first IP-address of the DHCP subnet, in the format 192.168.8.1/255.255.252.0. Must be valid in the cluster-allowed IP range.

    .PARAMETER Port
        The port used for the availability group listener.

    .PARAMETER DHCP
        If DHCP should be used for the availability group listener instead of static IP address.
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
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [Parameter()]
        [System.String[]]
        $IpAddress,

        [Parameter()]
        [System.UInt16]
        $Port,

        [Parameter()]
        [System.Boolean]
        $DHCP
    )

    $parameters = @{
        InstanceName      = [System.String] $InstanceName
        ServerName        = [System.String] $ServerName
        Name              = [System.String] $Name
        AvailabilityGroup = [System.String] $AvailabilityGroup
    }

    New-VerboseMessage -Message "Testing state of listener $Name"

    $availabilityGroupListenerState = Get-TargetResource @parameters
    if ($null -ne $availabilityGroupListenerState)
    {
        if ($null -eq $IpAddress -or ($null -ne $availabilityGroupListenerState.IpAddress -and -not ( Compare-Object -ReferenceObject $IpAddress -DifferenceObject $availabilityGroupListenerState.IpAddress)))
        {
            $ipAddressEqual = $true
        }
        else
        {
            $ipAddressEqual = $false
        }

        [System.Boolean] $result = $false
        if ($availabilityGroupListenerState.Ensure -eq $Ensure)
        {
            if ($Ensure -eq 'Absent')
            {
                $result = $true
            }
        }

        if (-not $($PSBoundParameters.ContainsKey('Ensure')) -or $Ensure -eq 'Present')
        {
            if (($Port -eq "" -or $availabilityGroupListenerState.Port -eq $Port) -and
                $ipAddressEqual -and
                (-not $($PSBoundParameters.ContainsKey('DHCP')) -or $availabilityGroupListenerState.DHCP -eq $DHCP))
            {
                $result = $true
            }
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -ErrorCategory InvalidResult
    }

    return $result
}

function Get-SQLAlwaysOnAvailabilityGroupListener
{
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroup,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName
    )

    Write-Debug "Connecting to availability group $Name as $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    $availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
    if ($availabilityGroupObject)
    {
        $availabilityGroupListener = $availabilityGroupObject.AvailabilityGroupListeners[$Name]
    }
    else
    {
        throw New-TerminatingError -ErrorType AvailabilityGroupNotFound -FormatArgs @($AvailabilityGroup, $InstanceName) -ErrorCategory ObjectNotFound
    }

    return $availabilityGroupListener
}

Export-ModuleMember -Function *-TargetResource
