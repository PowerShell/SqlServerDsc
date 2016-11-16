$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
  
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName
    )

    $returnValue = @{
        Name = [System.String] $Name
        Protocol = [System.String] ''
        ServerName = [System.String] $ServerName
        TcpPort = [System.UInt16] 0
        UseDynamicTcpPort = [System.Boolean] $false
        PipeName = [System.String] ''
        Ensure = [System.String] 'Absent'
    }

    $protocolTcp = 'DBMSSOCN'
    $protocolNamedPipes = 'DBNMPNTW'

    Write-Verbose -Message "Getting the SQL Server Client Alias $Name"
    $itemValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' `
                                  -Name $Name `
                                  -ErrorAction SilentlyContinue
    
    if (((Get-WmiObject -Class win32_OperatingSystem).OSArchitecture) -eq '64-bit')
    {
        Write-Verbose -Message "64-bit Operating System. Also get the client alias $Name from Wow6432Node"
        
        $isWow6432Node = $true
        $itemValueWow6432Node = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' `
                                                 -Name $Name `
                                                 -ErrorAction SilentlyContinue
    }
    
    if ((-not $isWow6432Node -and $null -ne $itemValue ) -or `
       (($null -ne $itemValue -and $null -ne $itemValueWow6432Node) -and `
       ($isWow6432Node -and $itemValueWow6432Node."$Name" -eq $itemValue."$Name")))
    {
        $itemConfig = $itemValue."$Name" | ConvertFrom-Csv -Header 'Protocol','ServerName','TcpPort'
        if ($itemConfig)
        {
            if ($itemConfig.Protocol -eq $protocolTcp)
            {
                $returnValue.Ensure = 'Present'
                $returnValue.Protocol = 'TCP'
                $returnValue.ServerName = $itemConfig.ServerName
                if ($itemConfig.TcpPort)
                {
                    $returnValue.TcpPort = $itemConfig.TcpPort
                    $returnValue.UseDynamicTcpPort = $false
                }
                else
                {
                    $returnValue.UseDynamicTcpPort = $true
                    $returnValue.TcpPort = 0
                }
            }
            elseif ($itemConfig.Protocol -eq $protocolNamedPipes)
            {
                $returnValue.Ensure = 'Present'
                $returnValue.Protocol = 'NP'
                $returnValue.PipeName = $itemConfig.ServerName
            }
        }
        else 
        {
            $returnValue.Ensure = 'Absent'
        }
    }
    else
    {
        $returnValue.Ensure = 'Absent'
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet("TCP","NP")]
        [System.String]
        $Protocol = 'TCP',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 1433,

        [Parameter()]
        [System.Boolean]
        $UseDynamicTcpPort = $false,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    if ($Protocol -eq 'NP')
    {
        $itemValue = "DBNMPNTW,\\$ServerName\PIPE\sql\query"
    }

    if ($Protocol -eq 'TCP')
    {
        $itemValue = "DBMSSOCN,$ServerName"
        if (!$UseDynamicTcpPort)
        {
            $itemValue += ",$TcpPort"
        }
    }

    $registryPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
    $registryPathWow6432Node = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' 

    if ($Ensure -eq 'Present')
    {
        if ($PSCmdlet.ShouldProcess($Name, 'Setting the client alias'))
        {
            if (!(Test-Path -Path $registryPath))
            {
                New-Item -Path $registryPath | Out-Null
            }

            Set-ItemProperty -Path $registryPath -Name $Name -Value $itemValue | Out-Null
        }

        # If this is a 64-bit OS then also update Wow6432Node
        if (((Get-WmiObject -Class win32_OperatingSystem).OSArchitecture) -eq '64-bit')
        {
            if ($PSCmdlet.ShouldProcess($Name, 'Setting the client alias (32-bit)'))
            {
                if (!(Test-Path -Path $registryPathWow6432Node))
                {
                    New-Item -Path $registryPathWow6432Node | Out-Null
                }

                Set-ItemProperty -Path $registryPathWow6432Node -Name $Name -Value $itemValue | Out-Null
            }
        }
    }

    if ($Ensure -eq 'Absent')
    {
        if ($PSCmdlet.ShouldProcess($Name, 'Remove the client alias'))
        {
            if (Test-Path -Path $registryPath)
            {
                Remove-ItemProperty -Path $registryPath -Name $Name
            }
        }
            
        # If this is a 64-bit OS then also remove from Wow6432Node
        if (((Get-WmiObject -Class win32_OperatingSystem).OSArchitecture) -eq '64-bit' `
              -and (Test-Path -Path $registryPathWow6432Node))
        {
            if ($PSCmdlet.ShouldProcess($Name, 'Remove the client alias (32-bit)'))
            {
                Remove-ItemProperty -Path $registryPathWow6432Node -Name $Name
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet("TCP","NP")]
        [System.String]
        $Protocol = 'TCP',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 1433,

        [Parameter()]
        [System.Boolean]
        $UseDynamicTcpPort = $false,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message "Testing the SQL Server Client Alias $Name"
     
    $result = $false

    $parameters = @{
        Name = $PSBoundParameters.Name
        ServerName = $PSBoundParameters.ServerName
    }

    $currentValues = Get-TargetResource @parameters

    if ($Ensure -eq $currentValues.Ensure)
    {
        if( $Ensure -eq 'Absent' )
        {
            $result = $true
        }
        else
        {
            Write-Verbose "Ensure is in the desired state. Verifying values."

            if ($Protocol -eq $currentValues.Protocol)
            {
                if ($Protocol -eq 'NP' -and 
                    $currentValues.PipeName -eq "\\$ServerName\PIPE\sql\query")
                {
                    $result = $true
                }
                elseif ($Protocol -eq 'TCP' -and
                    $UseDynamicTcpPort -and
                    $currentValues.ServerName -eq $ServerName)
                {
                    $result = $true
                }
                elseif ($Protocol -eq 'TCP' -and
                    -not $UseDynamicTcpPort -and
                    $currentValues.ServerName -eq $ServerName -and
                    $currentValues.TcpPort -eq $TcpPort)
                {
                    $result = $true
                }
            }
        }
    }
    
    if ($result) 
    {
        Write-Verbose -Message 'In the desired state'
    }
    else
    {
        Write-Verbose -Message 'Not in the desired state'
    }

    return $result
}

Export-ModuleMember -Function *-TargetResource
