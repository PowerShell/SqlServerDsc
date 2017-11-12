Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force
<#
    .SYNOPSIS
        Returns the current state of the endpoint.

    .PARAMETER EndpointName
        The name of the endpoint.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $EndpointName,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $getTargetResourceReturnValues = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Ensure       = 'Absent'
        EndpointName = ''
        Port         = ''
        IpAddress    = ''
    }

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName
    if ($sqlServerObject)
    {
        Write-Verbose -Message ('Connected to {0}\{1}' -f $ServerName, $InstanceName)

        $endpointObject = $sqlServerObject.Endpoints[$EndpointName]
        if ($endpointObject.Name -eq $EndpointName)
        {
            if ($sqlServerObject.Endpoints[$EndPointName].EndpointType -ne 'DatabaseMirroring')
            {
                throw New-TerminatingError -ErrorType EndpointFoundButWrongType `
                    -FormatArgs @($EndpointName) `
                    -ErrorCategory InvalidOperation
            }

            $getTargetResourceReturnValues.Ensure = 'Present'
            $getTargetResourceReturnValues.EndpointName = $endpointObject.Name
            $getTargetResourceReturnValues.Port = $endpointObject.Protocol.Tcp.ListenerPort
            $getTargetResourceReturnValues.IpAddress = $endpointObject.Protocol.Tcp.ListenerIPAddress
        }
        else
        {
            $getTargetResourceReturnValues.Ensure = 'Absent'
            $getTargetResourceReturnValues.EndpointName = ''
            $getTargetResourceReturnValues.Port = ''
            $getTargetResourceReturnValues.IpAddress = ''
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NotConnectedToInstance `
            -FormatArgs @($ServerName, $InstanceName) `
            -ErrorCategory InvalidOperation
    }

    return $getTargetResourceReturnValues
}

<#
    .SYNOPSIS
        Create, changes or drops an endpoint.

    .PARAMETER EndpointName
        The name of the endpoint.

    .PARAMETER Ensure
        If the endpoint should be present or absent. Default values is 'Present'.

    .PARAMETER Port
        The network port the endpoint is listening on. Default value is 5022.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER IpAddress
        The network IP address the endpoint is listening on. Defaults to '0.0.0.0' which means listen on any valid IP address.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $EndpointName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.UInt16]
        $Port = 5022,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $IpAddress = '0.0.0.0'
    )

    $getTargetResourceResult = Get-TargetResource -EndpointName $EndpointName -ServerName $ServerName -InstanceName $InstanceName

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName
    if ($sqlServerObject)
    {
        if ($Ensure -eq 'Present' -and $getTargetResourceResult.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ('Creating endpoint {0}.' -f $EndpointName)

            $endpointObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint -ArgumentList $sqlServerObject, $EndpointName
            $endpointObject.EndpointType = [Microsoft.SqlServer.Management.Smo.EndpointType]::DatabaseMirroring
            $endpointObject.ProtocolType = [Microsoft.SqlServer.Management.Smo.ProtocolType]::Tcp
            $endpointObject.Protocol.Tcp.ListenerPort = $Port
            $endpointObject.Protocol.Tcp.ListenerIPAddress = $IpAddress
            $endpointObject.Payload.DatabaseMirroring.ServerMirroringRole = [Microsoft.SqlServer.Management.Smo.ServerMirroringRole]::All
            $endpointObject.Payload.DatabaseMirroring.EndpointEncryption = [Microsoft.SqlServer.Management.Smo.EndpointEncryption]::Required
            $endpointObject.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm = [Microsoft.SqlServer.Management.Smo.EndpointEncryptionAlgorithm]::Aes
            $endpointObject.Create()
            $endpointObject.Start()
        }
        elseif ($Ensure -eq 'Present' -and $getTargetResourceResult.Ensure -eq 'Present')
        {
            # The endpoint already exist, verifying supported endpoint properties so they are in desired state.
            $endpointObject = $sqlServerObject.Endpoints[$EndpointName]
            if ($endpointObject)
            {
                if ($endpointObject.Protocol.Tcp.ListenerIPAddress -ne $IpAddress)
                {
                    Write-Verbose -Message ('Updating endpoint {0} IP address to {1}.' -f $EndpointName, $IpAddress)
                    $endpointObject.Protocol.Tcp.ListenerIPAddress = $IpAddress
                    $endpointObject.Alter()
                }

                if ($endpointObject.Protocol.Tcp.ListenerPort -ne $Port)
                {
                    Write-Verbose -Message ('Updating endpoint {0} port to {1}.' -f $EndpointName, $Port)
                    $endpointObject.Protocol.Tcp.ListenerPort = $Port
                    $endpointObject.Alter()
                }
            }
            else
            {
                throw New-TerminatingError -ErrorType EndpointNotFound -FormatArgs @($EndpointName) -ErrorCategory ObjectNotFound
            }
        }
        elseif ($Ensure -eq 'Absent' -and $getTargetResourceResult.Ensure -eq 'Present')
        {
            Write-Verbose -Message ('Dropping endpoint {0}.' -f $EndpointName)

            $endpointObject = $sqlServerObject.Endpoints[$EndpointName]
            if ($endpointObject)
            {
                $endpointObject.Drop()
            }
            else
            {
                throw New-TerminatingError -ErrorType EndpointNotFound -FormatArgs @($EndpointName) -ErrorCategory ObjectNotFound
            }
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NotConnectedToInstance `
            -FormatArgs @($ServerName, $InstanceName) `
            -ErrorCategory InvalidOperation
    }
}

<#
    .SYNOPSIS
        Tests if the principal (login) has the desired permissions.

    .PARAMETER EndpointName
        The name of the endpoint.

    .PARAMETER Ensure
        If the endpoint should be present or absent. Default values is 'Present'.

    .PARAMETER Port
        The network port the endpoint is listening on. Default value is 5022.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER IpAddress
        The network IP address the endpoint is listening on. Defaults to '0.0.0.0' which means listen on any valid IP address.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $EndpointName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.UInt16]
        $Port = 5022,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $IpAddress = '0.0.0.0'
    )

    $getTargetResourceResult = Get-TargetResource -EndpointName $EndpointName -ServerName $ServerName -InstanceName $InstanceName
    if ($getTargetResourceResult.Ensure -eq $Ensure)
    {
        $result = $true

        if ($getTargetResourceResult.Ensure -eq 'Present' `
                -and (
                $getTargetResourceResult.Port -ne $Port `
                    -or $getTargetResourceResult.IpAddress -ne $IpAddress
            )
        )
        {
            $result = $false
        }
    }
    else
    {
        $result = $false
    }

    return $result
}

Export-ModuleMember -Function *-TargetResource
