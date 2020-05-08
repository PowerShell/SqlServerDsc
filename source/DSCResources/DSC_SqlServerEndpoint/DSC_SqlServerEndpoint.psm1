$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the endpoint.

    .PARAMETER EndpointName
        The name of the endpoint.

    .PARAMETER EndpointType
        Specifies the type of endpoint. Currently the only type that is supported
        is the Database Mirror type.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .NOTES
        Get-TargetResource throws an error when the endpoint does not match the
        endpoint type. This is because the endpoint cannot be changed once
        the endpoint have been created and manual intervention is needed.
        Also Set-TargetResource and Test-TargetResource depends on that the
        Get-TargetResource does this check so we don't need to have the same
        check in those functions as well.
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseMirroring')]
        [System.String]
        $EndpointType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.GetEndpoint -f $EndpointName, $InstanceName
    )

    $getTargetResourceReturnValues = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Ensure       = 'Absent'
        EndpointName = ''
        Port         = ''
        IpAddress    = ''
        Owner        = ''
        State        = $null
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.ConnectedToInstance -f $ServerName, $InstanceName
        )

        $endpointObject = $sqlServerObject.Endpoints[$EndpointName]
        if ($endpointObject.Name -eq $EndpointName)
        {
            if ($endpointObject.EndpointType -ne $EndpointType)
            {
                $errorMessage = $script:localizedData.EndpointFoundButWrongType -f $EndpointName, $endpointObject.EndpointType, $EndpointType
                New-InvalidOperationException -Message $errorMessage
            }

            $getTargetResourceReturnValues.Ensure = 'Present'
            $getTargetResourceReturnValues.EndpointName = $endpointObject.Name
            $getTargetResourceReturnValues.Port = $endpointObject.Protocol.Tcp.ListenerPort
            $getTargetResourceReturnValues.IpAddress = $endpointObject.Protocol.Tcp.ListenerIPAddress
            $getTargetResourceReturnValues.Owner = $endpointObject.Owner
            $getTargetResourceReturnValues.State = $endpointObject.EndpointState
        }
    }
    else
    {
        $errorMessage = $script:localizedData.NotConnectedToInstance -f $ServerName, $InstanceName
        New-InvalidOperationException -Message $errorMessage
    }

    return $getTargetResourceReturnValues
}

<#
    .SYNOPSIS
        Create, changes or drops an endpoint.

    .PARAMETER EndpointName
        The name of the endpoint.

    .PARAMETER EndpointType
        Specifies the type of endpoint. Currently the only type that is supported
        is the Database Mirror type.

    .PARAMETER Ensure
        If the endpoint should be present or absent. Default values is 'Present'.

    .PARAMETER Port
        The network port the endpoint is listening on. Default value is 5022, but
        default value is only used during endpoint creation, it is not enforce.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER IpAddress
        The network IP address the endpoint is listening on. Default value is '0.0.0.0'
        which means listen on any valid IP address. The default value is only used
        during endpoint creation, it is not enforce.

    .PARAMETER Owner
        The owner of the endpoint. Default is the login used for the creation.

    .PARAMETER State
        Specifies the state of the endpoint. Valid states are Started, Stopped, or
        Disabled. When an endpoint is created and the state is not specified then
        the endpoint will be started after it is created. The state will not be
        enforced unless the parameter is specified.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $EndpointName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseMirroring')]
        [System.String]
        $EndpointType,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.UInt16]
        $Port = 5022,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $IpAddress = '0.0.0.0',

        [Parameter()]
        [System.String]
        $Owner,

        [Parameter()]
        [ValidateSet('Started', 'Stopped', 'Disabled')]
        [System.String]
        $State
    )

    $getTargetResourceParameters = @{
        EndpointName = $EndpointName
        EndpointType = $EndpointType
        ServerName = $ServerName
        InstanceName = $InstanceName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        if ($Ensure -eq 'Present')
        {
            if ($getTargetResourceResult.Ensure -eq 'Absent')
            {

                Write-Verbose -Message (
                    $script:localizedData.CreateEndpoint -f $EndpointName, $InstanceName
                )

                switch ($EndpointType)
                {
                    'DatabaseMirroring'
                    {
                        $endpointObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Endpoint' -ArgumentList @($sqlServerObject, $EndpointName)
                        $endpointObject.EndpointType = [Microsoft.SqlServer.Management.Smo.EndpointType]::DatabaseMirroring
                        $endpointObject.ProtocolType = [Microsoft.SqlServer.Management.Smo.ProtocolType]::Tcp
                        $endpointObject.Protocol.Tcp.ListenerPort = $Port
                        $endpointObject.Protocol.Tcp.ListenerIPAddress = $IpAddress

                        if ($PSBoundParameters.ContainsKey('Owner'))
                        {
                            $endpointObject.Owner = $Owner
                        }

                        $endpointObject.Payload.DatabaseMirroring.ServerMirroringRole = [Microsoft.SqlServer.Management.Smo.ServerMirroringRole]::All
                        $endpointObject.Payload.DatabaseMirroring.EndpointEncryption = [Microsoft.SqlServer.Management.Smo.EndpointEncryption]::Required
                        $endpointObject.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm = [Microsoft.SqlServer.Management.Smo.EndpointEncryptionAlgorithm]::Aes
                        $endpointObject.Create()

                        <#
                            If endpoint state is not specified, then default to
                            starting the endpoint. If state is specified then
                            it will be handled later.
                        #>
                        if (-not ($PSBoundParameters.ContainsKey('State')))
                        {
                            $endpointObject.Start()
                        }
                    }
                }
            }
            else
            {
                Write-Verbose -Message (
                    $script:localizedData.SetEndpoint -f $EndpointName, $InstanceName
                )

                $endpointObject = $sqlServerObject.Endpoints[$EndpointName]

                if (-not $endpointObject)
                {
                    $errorMessage = $script:localizedData.EndpointNotFound -f $EndpointName

                    New-ObjectNotFoundException -Message $errorMessage
                }
            }

            <#
                The endpoint exist or was just created. Verifying supported
                properties so they are in desired state.
            #>

            # Properties regardless of endpoint type.
            if ($PSBoundParameters.ContainsKey('State'))
            {
                if ($endpointObject.EndpointState -ne $State)
                {
                    Write-Verbose -Message (
                        $script:localizedData.ChangingEndpointState -f $State
                    )

                    switch ($State)
                    {
                        'Started'
                        {
                            $endpointObject.Start()
                        }

                        'Stopped'
                        {
                            $endpointObject.Stop()
                        }

                        'Disabled'
                        {
                            $endpointObject.Disable()
                        }
                    }
                }
            }

            # Individual endpoint type properties.
            switch ($EndpointType)
            {
                'DatabaseMirroring'
                {
                    if ($PSBoundParameters.ContainsKey('IpAddress'))
                    {
                        if ($endpointObject.Protocol.Tcp.ListenerIPAddress -ne $IpAddress)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdatingEndpointIPAddress -f $IpAddress
                            )

                            $endpointObject.Protocol.Tcp.ListenerIPAddress = $IpAddress
                            $endpointObject.Alter()
                        }
                    }

                    if ($PSBoundParameters.ContainsKey('Port'))
                    {
                        if ($endpointObject.Protocol.Tcp.ListenerPort -ne $Port)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdatingEndpointPort -f $Port
                            )

                            $endpointObject.Protocol.Tcp.ListenerPort = $Port
                            $endpointObject.Alter()
                        }
                    }

                    if ($PSBoundParameters.ContainsKey('Owner'))
                    {
                        if ($endpointObject.Owner -ne $Owner)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdatingEndpointOwner -f $Owner
                            )

                            $endpointObject.Owner = $Owner
                            $endpointObject.Alter()
                        }
                    }
                }
            }
        }

        if ($Ensure -eq 'Absent' -and $getTargetResourceResult.Ensure -eq 'Present')
        {
            $endpointObject = $sqlServerObject.Endpoints[$EndpointName]

            if ($endpointObject)
            {
                Write-Verbose -Message (
                    $script:localizedData.DropEndpoint -f $EndpointName, $InstanceName
                )

                $endpointObject.Drop()
            }
            else
            {
                $errorMessage = $script:localizedData.EndpointNotFound -f $EndpointName

                New-ObjectNotFoundException -Message $errorMessage
            }
        }
    }
    else
    {
        $errorMessage = $script:localizedData.NotConnectedToInstance -f $ServerName, $InstanceName

        New-InvalidOperationException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Tests if the principal (login) has the desired permissions.

    .PARAMETER EndpointName
        The name of the endpoint.

    .PARAMETER EndpointType
        Specifies the type of endpoint. Currently the only type that is supported
        is the Database Mirror type.

    .PARAMETER Ensure
        If the endpoint should be present or absent. Default values is 'Present'.

    .PARAMETER Port
        The network port the endpoint is listening on. Default value is 5022, but
        default value is only used during endpoint creation, it is not enforce.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER IpAddress
        The network IP address the endpoint is listening on. Default value is '0.0.0.0'
        which means listen on any valid IP address. The default value is only used
        during endpoint creation, it is not enforce.

    .PARAMETER Owner
        The owner of the endpoint. Default is the login used for the creation.

    .PARAMETER State
        Specifies the state of the endpoint. Valid states are Started, Stopped, or
        Disabled. When an endpoint is created and the state is not specified then
        the endpoint will be started after it is created. The state will not be
        enforced unless the parameter is specified.
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('DatabaseMirroring')]
        [System.String]
        $EndpointType,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.UInt16]
        $Port = 5022,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $IpAddress = '0.0.0.0',

        [Parameter()]
        [System.String]
        $Owner,

        [Parameter()]
        [ValidateSet('Started', 'Stopped', 'Disabled')]
        [System.String]
        $State
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration -f $EndpointName, $InstanceName
    )

    $getTargetResourceParameters = @{
        EndpointName = $EndpointName
        EndpointType = $EndpointType
        ServerName = $ServerName
        InstanceName = $InstanceName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    if ($getTargetResourceResult.Ensure -eq $Ensure)
    {
        $result = $true

        if ($PSBoundParameters.ContainsKey('Owner'))
        {
            if ($getTargetResourceResult.Owner -ne $Owner)
            {
                $result = $false
            }
        }


        if ($PSBoundParameters.ContainsKey('State'))
        {
            if ($getTargetResourceResult.State -ne $State)
            {
                $result = $false
            }
        }

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

    if ($result)
    {
        Write-Verbose -Message (
            $script:localizedData.InDesiredState -f $EndpointName
        )
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState -f $EndpointName
        )
    }

    return $result
}

Export-ModuleMember -Function *-TargetResource
