<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlAG DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlAG'

#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    # Load the default SQL Module stub
    Import-SQLModuleStub
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
        # This is relative to the path of the resource module script, not test test script.
        $script:moduleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Tests' -ChildPath (Join-Path -Path 'TestHelpers' -ChildPath 'CommonTestHelper.psm1'))) -Force

        #region parameter mocks

        # Define the values that could be passed into the Name parameter
        $mockNameParameters = @{
            AbsentAvailabilityGroup = 'AvailabilityGroup2'
            CreateAvailabilityGroupFailed = 'AvailabilityGroup5'
            CreateAvailabilityGroupReplicaFailed = 'AvailabilityGroup4'
            PresentAvailabilityGroup = 'AvailabilityGroup1'
            RemoveAvailabilityGroupFailed = 'AvailabilityGroup3'
        }

        # Define the values that could be passed into the ServerName parameter
        $mockSqlServerParameters = @{
            Server1 = @{
                FQDN = 'Server1.contoso.com'
                #IP = '192.168.1.1'
                #NetBIOS = 'Server1'
            }

            Server2 = @{
                FQDN = 'Server2.contoso.com'
                #IP = '192.168.1.2'
                #NetBIOS = 'Server2'
            }
        }

        # Define the values that could be passed into the InstanceName parameter
        $mockInstanceNameParameters = @(
            'MSSQLSERVER',
            'NamedInstance'
        )

        $mockProcessOnlyOnActiveNode = $true

        #endregion parameter mocks

        #region property mocks

        $mockIsHadrEnabled = $true
        $mockIsDatabaseMirroringEndpointPresent = $true

        $mockServerObjectProperties = @{
            Server1 = @{
                NetName = 'Server1'
            }

            Server2 = @{
                NetName = 'Server2'
            }
        }

        $mockAvailabilityGroupProperties = @{
            AutomatedBackupPreference = 'Secondary' # Not the default parameter value
            BasicAvailabilityGroup = $true # Not the default parameter value
            DatabaseHealthTrigger = $true # Not the default parameter value
            DtcSupportEnabled = $true # Not the default parameter value
            FailureConditionLevel = 'OnCriticalServerErrors' # Not the default parameter value
            HealthCheckTimeout = 20000
            Name = $mockNameParameters.PresentAvailabilityGroup
            PrimaryReplicaServerName = $mockServerObjectProperties.Server1.NetName
        }

        $mockAvailabilityGroupReplicaProperties = @{
            Server1 = @{
                AvailabilityMode = 'SynchronousCommit' # Not the default parameter value
                BackupPriority = 49 # Not the default parameter value
                ConnectionModeInPrimaryRole = 'AllowAllConnections' # Not the default parameter value
                ConnectionModeInSecondaryRole = 'AllowNoConnections' # Not the default parameter value
                EndpointHostName = $mockServerObjectProperties.Server1.NetName
                EndpointProtocol = 'TCP'
                EndpointPort = 5022
                FailoverMode = 'Automatic' # Not the default parameter value
                Name = $mockServerObjectProperties.Server1.NetName
                Role = 'Primary'
            }

            Server2 = @{
                AvailabilityMode = 'SynchronousCommit' # Not the default parameter value
                BackupPriority = 49 # Not the default parameter value
                ConnectionModeInPrimaryRole = 'AllowAllConnections' # Not the default parameter value
                ConnectionModeInSecondaryRole = 'AllowNoConnections' # Not the default parameter value
                EndpointHostName = $mockServerObjectProperties.Server2.NetName
                EndpointProtocol = 'TCP'
                EndpointPort = 5022
                FailoverMode = 'Automatic' # Not the default parameter value
                Name = $mockServerObjectProperties.Server2.NetName
                Role = 'Primary'
            }
        }

        $mockDatabaseMirroringEndpointProperties = @{
            Protocol = 'TCP'
            ListenerPort = 5022
        }

        #endregion property mocks

        #region test cases

        $getTargetResourceAbsentTestCases = @()
        $getTargetResourcePresentTestCases = @()
        $setTargetResourceCreateAvailabilityGroupFailedTestCases = @()
        $setTargetResourceCreateAvailabilityGroupWithParameterTestCases = @()
        $setTargetResourcesEndpointUrlTestCases = @()
        $setTargetResourceEndpointMissingTestCases = @()
        $setTargetResourceHadrDisabledTestCases = @()
        $setTargetResourcePropertyIncorrectTestCases = @()
        $setTargetResourceRemoveAvailabilityGroupTestCases = @()
        $setTargetResourceRemoveAvailabilityGroupErrorTestCases = @()
        $testTargetResourceAbsentTestCases = @()
        $testTargetResourceEndpointIncorrectTestCases = @()
        $testTargetResourcePresentTestCases = @()
        $testTargetResourcePropertyIncorrectTestCases = @()
        $testTargetResourceProcessOnlyOnActiveNodeTestCases = @()

        $majorVersionsToTest = @(12,13)
        $ensureCasesToTest = @('Absent','Present')
        $endpointUrlPropertiesToTest = @('EndpointPort','EndpointProtocol')

        $createAvailabilityGroupFailuresToTest = @{
            $mockNameParameters.CreateAvailabilityGroupFailed = 'CreateAvailabilityGroupFailed'
            $mockNameParameters.CreateAvailabilityGroupReplicaFailed = 'CreateAvailabilityGroupReplicaFailed'
        }

        # Get all of the parameters tied with the resource except the required parameters, Ensure, and DtcSupportEnabled
        $resourceParameters = @{}
        ( Get-Command -Name Test-TargetResource ).Parameters.Values | Where-Object -FilterScript {
            (
                # Ignore these specific parameters. These get tested enough.
                @('Ensure', 'Name', 'ServerName', 'InstanceName', 'DtcSupportEnabled', 'ProcessOnlyOnActiveNode') -notcontains $_.Name
            ) -and (
                # Ignore the CmdletBinding parameters
                $_.Attributes.TypeId.Name -notcontains 'AliasAttribute'
            )
        } | ForEach-Object -Process {
            $currentParameter = $_.Name

            $resourceParameters.Add(
                $currentParameter,
                ( @($mockAvailabilityGroupProperties.$currentParameter,$mockAvailabilityGroupReplicaProperties.Server1.$currentParameter) -join '' )
            )
        }

        # Define the properties that are SQL 2016 and newer
        $sql13AvailabilityGroupProperties = @(
            'BasicAvailabilityGroup'
            'DatabaseHealthTrigger'
            'DtcSupportEnabled'
        )

        foreach ( $majorVersionToTest in $majorVersionsToTest )
        {
            foreach ( $mockSqlServer in $mockSqlServerParameters.GetEnumerator() )
            {
                # Determine with SQL Server mock will be used
                $mockSqlServerToBeUsed = $mockSqlServer.Key

                foreach ( $mockSqlServerParameter in $mockSqlServer.Value.Values )
                {
                    foreach ( $mockInstanceNameParameter in $mockInstanceNameParameters )
                    {
                        # Build the domain instance name
                        if ( $mockInstanceNameParameter -eq 'MSSQLSERVER' )
                        {
                            $domainInstanceNameProperty = $mockSqlServerParameter
                        }
                        else
                        {
                            $domainInstanceNameProperty = '{0}\{1}' -f $mockSqlServerParameter,$mockInstanceNameParameter
                        }

                        if ( $mockSqlServerToBeUsed -eq 'Server1' )
                        {
                            $getTargetResourceAbsentTestCases += @{
                                Name = $mockNameParameters.AbsentAvailabilityGroup
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }

                            $getTargetResourcePresentTestCases += @{
                                Name = $mockNameParameters.PresentAvailabilityGroup
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }

                            foreach ( $createAvailabilityGroupFailureToTest in $createAvailabilityGroupFailuresToTest.GetEnumerator() )
                            {
                                $setTargetResourceCreateAvailabilityGroupFailedTestCases += @{
                                    ErrorResult = $createAvailabilityGroupFailureToTest.Value
                                    Ensure = 'Present'
                                    Name = $createAvailabilityGroupFailureToTest.Key
                                    ServerName = $mockSqlServerParameter
                                    InstanceName = $mockInstanceNameParameter
                                    Version = $majorVersionToTest
                                }
                            }

                            $setTargetResourceEndpointMissingTestCases += @{
                                Ensure = 'Present'
                                Name = $mockNameParameters.AbsentAvailabilityGroup
                                Result = $script:localizedData.DatabaseMirroringEndpointNotFound -f ('{0}\{1}' -f $mockSqlServerParameter, $mockInstanceNameParameter)
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }

                            $setTargetResourceHadrDisabledTestCases += @{
                                Ensure = 'Present'
                                Name = $mockNameParameters.AbsentAvailabilityGroup
                                Result = $script:localizedData.HadrNotEnabled
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }

                            $setTargetResourceRemoveAvailabilityGroupTestCases += @{
                                Ensure = 'Absent'
                                Name = $mockNameParameters.PresentAvailabilityGroup
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }
                        }

                        switch ( $mockSqlServerToBeUsed )
                        {
                            'Server1'
                            {
                                $setTargetResourceRemoveAvailabilityGroupErrorTestCaseErrorResult = 'RemoveAvailabilityGroupFailed'
                                $setTargetResourceRemoveAvailabilityGroupErrorTestCaseName = $mockNameParameters.RemoveAvailabilityGroupFailed
                            }

                            'Server2'
                            {
                                $setTargetResourceRemoveAvailabilityGroupErrorTestCaseErrorResult = 'InstanceNotPrimaryReplica'
                                $setTargetResourceRemoveAvailabilityGroupErrorTestCaseName = $mockNameParameters.PresentAvailabilityGroup
                            }
                        }

                        $setTargetResourceRemoveAvailabilityGroupErrorTestCases += @{
                            ErrorResult = $setTargetResourceRemoveAvailabilityGroupErrorTestCaseErrorResult
                            Ensure = 'Absent'
                            Name = $setTargetResourceRemoveAvailabilityGroupErrorTestCaseName
                            ServerName = $mockSqlServerParameter
                            InstanceName = $mockInstanceNameParameter
                            Version = $majorVersionToTest
                        }

                        foreach ( $processOnlyOnActiveNode in @($true,$false) )
                        {
                            $testTargetResourceProcessOnlyOnActiveNodeTestCases += @{
                                Ensure = 'Present'
                                Name = $mockNameParameters.PresentAvailabilityGroup
                                ProcessOnlyOnActiveNode = $processOnlyOnActiveNode
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }
                        }

                        # Create test cases for Absent/Present
                        foreach ( $ensureCaseToTest in $ensureCasesToTest )
                        {
                            $testTargetResourceAbsentTestCases += @{
                                Ensure = $ensureCaseToTest
                                Name = $mockNameParameters.AbsentAvailabilityGroup
                                Result = ( $ensureCaseToTest -eq 'Absent' )
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }

                            $testTargetResourcePresentTestCases += @{
                                Ensure = $ensureCaseToTest
                                Name = $mockNameParameters.PresentAvailabilityGroup
                                Result = ( $ensureCaseToTest -eq 'Present' )
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }
                        }

                        # Create Present test cases for each parameter
                        foreach ( $resourceParameter in $resourceParameters.GetEnumerator() )
                        {
                            # Move on if we're testing a version less than 13 and it's a property that was only introduced in 13
                            if ( ( $sql13AvailabilityGroupProperties -contains $resourceParameter.Key ) -and ( $majorVersionToTest -lt 13 ) )
                            {
                                # Move to the next parameter
                                continue
                            }

                            # Get the current parameter object
                            $currentParameterObject = ( Get-Command Test-TargetResource ).Parameters.($resourceParameter.Key)

                            switch ( $currentParameterObject.ParameterType.ToString() )
                            {
                                'System.Boolean'
                                {
                                    # Get the opposite value of what is supplied
                                    $testCaseParameterValue = -not $resourceParameter.Value
                                }

                                'System.UInt32'
                                {
                                    # Change the supplied number to something else. Absolute value is to protect against zero minus 1
                                    $testCaseParameterValue = [System.Math]::Abs( ( $resourceParameter.Value - 1 ) )
                                }

                                'System.String'
                                {
                                    # Get the valid values for the current parameter
                                    $currentParameterValidValues = $currentParameterObject.Attributes.ValidValues

                                    # Select a value other than what is defined in the mocks
                                    $testCaseParameterValue = $currentParameterValidValues | Where-Object -FilterScript {
                                        $_ -ne $resourceParameter.Value
                                    } | Select-Object -First 1

                                    # If the value is null or empty, set it to something
                                    if ( [System.String]::IsNullOrEmpty($testCaseParameterValue) )
                                    {
                                        $testCaseParameterValue = 'AnotherHostName'
                                    }
                                }

                                default
                                {
                                    $testCaseParameterValue = $null
                                }
                            }

                            if ( $mockSqlServerToBeUsed -eq 'Server1' )
                            {
                                $setTargetResourceCreateAvailabilityGroupWithParameterTestCases += @{
                                    DomainInstanceName = $domainInstanceNameProperty
                                    Ensure = 'Present'
                                    Name = $mockNameParameters.AbsentAvailabilityGroup
                                    ParameterName = $resourceParameter.Key
                                    ParameterValue = $testCaseParameterValue
                                    ServerName = $mockSqlServerParameter
                                    InstanceName = $mockInstanceNameParameter
                                    Version = $majorVersionToTest
                                }
                            }

                            $setTargetResourcePropertyIncorrectTestCases += @{
                                Ensure = 'Present'
                                Name = $mockNameParameters.PresentAvailabilityGroup
                                ParameterName = $resourceParameter.Key
                                ParameterValue = $testCaseParameterValue
                                Result = $false
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }

                            $testTargetResourcePropertyIncorrectTestCases += @{
                                Ensure = 'Present'
                                Name = $mockNameParameters.PresentAvailabilityGroup
                                ParameterName = $resourceParameter.Key
                                ParameterValue = $testCaseParameterValue
                                Result = $false
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }
                        }

                        # Create Present test cases for the endpoint components
                        foreach ( $endpointProperty in $endpointUrlPropertiesToTest )
                        {
                            switch ( $mockAvailabilityGroupReplicaProperties.Server1.$endpointProperty.GetType().ToString() )
                            {
                                'System.Int32'
                                {
                                    # Change the supplied number to something else. Absolute value is to protect against zero minus 1
                                    $endpointPropertyValue = [System.Math]::Abs( ( $mockAvailabilityGroupReplicaProperties.Server1.$endpointProperty - 1 ) )
                                }

                                'System.String'
                                {
                                    $endpointPropertyValue = 'UDP'
                                }
                            }

                            $setTargetResourcesEndpointUrlTestCases += @{
                                EndpointPropertyName = $endpointProperty
                                EndpointPropertyValue = $endpointPropertyValue
                                Ensure = 'Present'
                                Name = $mockNameParameters.PresentAvailabilityGroup
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }

                            $testTargetResourceEndpointIncorrectTestCases += @{
                                EndpointPropertyName = $endpointProperty
                                EndpointPropertyValue = $endpointPropertyValue
                                Ensure = 'Present'
                                Name = $mockNameParameters.PresentAvailabilityGroup
                                Result = $false
                                ServerName = $mockSqlServerParameter
                                InstanceName = $mockInstanceNameParameter
                                Version = $majorVersionToTest
                            }
                        }
                    }
                }
            }
        }

        #endregion test cases

        #region cmdlet mocks

        $mockConnectSql = {
            param
            (
                [Parameter()]
                [System.String]
                $ServerName,

                [Parameter()]
                [System.String]
                $InstanceName,

                # The following two parameters are used to mock Get-PrimaryReplicaServerObject
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
                $AvailabilityGroup,

                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.Server]
                $ServerObject
            )

            # If this mock function is called from the Get-PrimaryReplicaServerObject command mock
            if ( [System.String]::IsNullOrEmpty($ServerName) -and [System.String]::IsNullOrEmpty($InstanceName) -and $AvailabilityGroup -and $ServerObject )
            {
                $ServerName,$InstanceName = $AvailabilityGroup.PrimaryReplicaServerName.Split('\')
            }

            # Determine which SQL Server mock data we will use
            $mockSqlServer = ( $mockSqlServerParameters.GetEnumerator() | Where-Object -FilterScript { $_.Value.Values -contains $ServerName } ).Name
            if ( [System.String]::IsNullOrEmpty($mockSqlServer) )
            {
                $mockSqlServer = $ServerName
            }
            $mockCurrentServerObjectProperties = $mockServerObjectProperties.$mockSqlServer

            # Build the domain instance name
            if ( ( $InstanceName -eq 'MSSQLSERVER' ) -or [System.String]::IsNullOrEmpty($InstanceName) )
            {
                $mockDomainInstanceName = $mockCurrentServerObjectProperties.NetName
                $mockPrimaryReplicaServerName = $mockAvailabilityGroupProperties.PrimaryReplicaServerName
                $mockAvailabilityGroupReplica1Name = $mockAvailabilityGroupReplicaProperties.Server1.Name
                $mockAvailabilityGroupReplica2Name = $mockAvailabilityGroupReplicaProperties.Server2.Name
            }
            else
            {
                $mockDomainInstanceName = '{0}\{1}' -f $mockCurrentServerObjectProperties.NetName,$InstanceName
                $mockPrimaryReplicaServerName = '{0}\{1}' -f $mockAvailabilityGroupProperties.PrimaryReplicaServerName,$InstanceName
                $mockAvailabilityGroupReplica1Name = '{0}\{1}' -f $mockAvailabilityGroupReplicaProperties.Server1.Name,$InstanceName
                $mockAvailabilityGroupReplica2Name = '{0}\{1}' -f $mockAvailabilityGroupReplicaProperties.Server2.Name,$InstanceName

            }

            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.DomainInstanceName = $mockDomainInstanceName
            $mockServerObject.IsHadrEnabled = $mockIsHadrEnabled
            $mockServerObject.Name = $ServerName
            $mockServerObject.NetName = $mockCurrentServerObjectProperties.NetName
            $mockServerObject.ServiceName = $InstanceName
            $mockServerObject.Version = @{
                Major = $Version
            }

            # Define the availability group object
            $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupObject.AutomatedBackupPreference = $mockAvailabilityGroupProperties.AutomatedBackupPreference
            $mockAvailabilityGroupObject.FailureConditionLevel = $mockAvailabilityGroupProperties.FailureConditionLevel
            $mockAvailabilityGroupObject.HealthCheckTimeout = $mockAvailabilityGroupProperties.HealthCheckTimeout
            $mockAvailabilityGroupObject.Name = $mockAvailabilityGroupProperties.Name
            $mockAvailabilityGroupObject.PrimaryReplicaServerName = $mockPrimaryReplicaServerName
            if ( $Version -ge 13 )
            {
                $mockAvailabilityGroupObject.BasicAvailabilityGroup = $mockAvailabilityGroupProperties.BasicAvailabilityGroup
                $mockAvailabilityGroupObject.DatabaseHealthTrigger = $mockAvailabilityGroupProperties.DatabaseHealthTrigger
                $mockAvailabilityGroupObject.DtcSupportEnabled = $mockAvailabilityGroupProperties.DtcSupportEnabled
            }

            # Define an availability group object to use when mocking a remove failure
            $mockAvailabilityGroupRemoveFailedObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupRemoveFailedObject.Name = $mockNameParameters.RemoveAvailabilityGroupFailed
            $mockAvailabilityGroupRemoveFailedObject.PrimaryReplicaServerName = $mockPrimaryReplicaServerName

            # Define the availability replica 1 object
            $mockAvailabilityReplica1Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityReplica1Object.Name = $mockAvailabilityGroupReplica1Name
            $mockAvailabilityReplica1Object.AvailabilityMode = $mockAvailabilityGroupReplicaProperties.Server1.AvailabilityMode
            $mockAvailabilityReplica1Object.BackupPriority = $mockAvailabilityGroupReplicaProperties.Server1.BackupPriority
            $mockAvailabilityReplica1Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplicaProperties.Server1.ConnectionModeInPrimaryRole
            $mockAvailabilityReplica1Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplicaProperties.Server1.ConnectionModeInSecondaryRole
            $mockAvailabilityReplica1Object.EndpointUrl = "$($mockAvailabilityGroupReplicaProperties.Server1.EndpointProtocol)://$($mockAvailabilityGroupReplicaProperties.Server1.EndpointHostName):$($mockAvailabilityGroupReplicaProperties.Server1.EndpointPort)"
            $mockAvailabilityReplica1Object.FailoverMode = $mockAvailabilityGroupReplicaProperties.Server1.FailoverMode
            $mockAvailabilityReplica1Object.Role = $mockAvailabilityGroupReplicaProperties.Server1.Role

            # Define the availability replica 2 object
            $mockAvailabilityReplica2Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityReplica2Object.Name = $mockAvailabilityGroupReplica2Name
            $mockAvailabilityReplica2Object.AvailabilityMode = $mockAvailabilityGroupReplicaProperties.Server2.AvailabilityMode
            $mockAvailabilityReplica2Object.BackupPriority = $mockAvailabilityGroupReplicaProperties.Server2.BackupPriority
            $mockAvailabilityReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityGroupReplicaProperties.Server2.ConnectionModeInPrimaryRole
            $mockAvailabilityReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityGroupReplicaProperties.Server2.ConnectionModeInSecondaryRole
            $mockAvailabilityReplica2Object.EndpointUrl = "$($mockAvailabilityGroupReplicaProperties.Server2.EndpointProtocol)://$($mockAvailabilityGroupReplicaProperties.Server2.EndpointHostName):$($mockAvailabilityGroupReplicaProperties.Server2.EndpointPort)"
            $mockAvailabilityReplica2Object.FailoverMode = $mockAvailabilityGroupReplicaProperties.Server2.FailoverMode
            $mockAvailabilityReplica2Object.Role = $mockAvailabilityGroupReplicaProperties.Server2.Role

            # Add the availability group to the server object
            $mockAvailabilityGroupObject.AvailabilityReplicas.Add($mockAvailabilityReplica1Object)
            $mockAvailabilityGroupObject.AvailabilityReplicas.Add($mockAvailabilityReplica2Object)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupRemoveFailedObject)

            # Define the database mirroring endpoint object
            if ( $mockIsDatabaseMirroringEndpointPresent )
            {
                $mockDatabaseMirroringEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
                $mockDatabaseMirroringEndpoint.EndpointType = 'DatabaseMirroring'
                $mockDatabaseMirroringEndpoint.Protocol = @{
                    $mockDatabaseMirroringEndpointProperties.Protocol = @{
                        ListenerPort = $mockDatabaseMirroringEndpointProperties.ListenerPort
                    }
                }
                $mockServerObject.Endpoints.Add($mockDatabaseMirroringEndpoint)
            }

            return $mockServerObject
        }

        $mockNewSqlAvailabilityGroup = {
            if ( $ErrorResult -eq 'CreateAvailabilityGroupFailed' )
            {
                throw 'CreateAvailabilityGroupFailed'
            }
        }

        $mockNewSqlAvailabilityGroupReplica = {
            if ( $ErrorResult -eq 'CreateAvailabilityGroupReplicaFailed' )
            {
                throw 'CreateAvailabilityGroupReplicaFailed'
            }

            return New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
        }

        # Mock the Update-AvailabilityGroup function to ensure the specified property was set correctly
        $mockUpdateAvailabilityGroup = {
            param
            (
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
                $AvailabilityGroup
            )

            # If the current value of the property that was set is not equal to the desired value
            if ( $ParameterValue -ne $AvailabilityGroup.$ParameterName )
            {
                foreach ( $currentProperty in $resourceParameters.Keys )
                {
                    # Determine if the property was submitted as part of the configuration
                    # $submittedParameters comes from the Set-TargetResource code
                    if ( $submittedParameters -contains $currentProperty )
                    {
                        Write-Verbose -Message "The property '$($currentProperty)' value is '$($AvailabilityGroup.$currentProperty)' and should be '$( ( Get-Variable -Name $currentProperty ).Value )'." -Verbose
                    }
                }

                throw "Update-AvailabilityGroup should set the property '$($ParameterName)' to '$($ParameterValue)'."
            }
        }

        # Mock the Update-AvailabilityGroupReplica function to ensure the specified property was set correctly
        $mockUpdateAvailabilityGroupReplica = {
            param
            (
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
                $AvailabilityGroupReplica
            )

            # Some parameters don't align directly with a property
            switch ( $ParameterName )
            {
                EndpointHostName
                {
                    $validatedParameter = 'EndpointUrl'
                    $validatedParameterValue = "$($mockDatabaseMirroringEndpointProperties.Protocol)://$($ParameterValue):$($mockDatabaseMirroringEndpointProperties.ListenerPort)"
                }

                default
                {
                    $validatedParameter = $ParameterName
                    $validatedParameterValue = $ParameterValue
                }
            }

            # If the current value of the property that was set is not equal to the desired value
            if ( $validatedParameterValue -ne $AvailabilityGroupReplica.$validatedParameter )
            {
                foreach ( $currentProperty in $resourceParameters.Keys )
                {
                    # Determine if the property was submitted as part of the configuration
                    # $submittedParameters comes from the Set-TargetResource code
                    if ( $submittedParameters -contains $currentProperty )
                    {
                        switch ( $currentProperty )
                        {
                            EndpointHostName
                            {
                                $validatedCurrentProperty = 'EndpointUrl'
                                $validatedCurrentPropertyValue = "$($mockDatabaseMirroringEndpointProperties.Protocol)://$($ParameterValue):$($mockDatabaseMirroringEndpointProperties.ListenerPort)"
                            }

                            default
                            {
                                $validatedCurrentProperty = $currentProperty
                                $validatedCurrentPropertyValue =$AvailabilityGroupReplica.$currentProperty
                            }
                        }

                        Write-Verbose -Message "The property '$($validatedCurrentProperty)' value is '$($AvailabilityGroupReplica.$validatedCurrentProperty)' and should be '$( ( Get-Variable -Name $currentProperty ).Value )'." -Verbose
                    }
                }

                throw "Update-AvailabilityGroupReplica should set the property '$($validatedParameter)' to '$($validatedParameterValue)'."
            }
        }

        #endregion cmdlet mocks

        Describe 'SqlAG\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the Availability Group is Absent' {

                It 'Should not return an Availability Group when Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $getTargetResourceAbsentTestCases {
                    param
                    (
                        $Name,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $getTargetResourceParameters = @{
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present' {
                It 'Should return the correct Availability Group properties when Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $getTargetResourcePresentTestCases {
                    param
                    (
                        $Name,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $getTargetResourceParameters = @{
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    # Determine which SQL Server mock data will be used
                    $mockSqlServer = ( $mockSqlServerParameters.GetEnumerator() | Where-Object -FilterScript { $_.Value.Values -contains $ServerName } ).Name

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.Name | Should -Be $Name
                    $result.ServerName | Should -Be $ServerName
                    $result.InstanceName | Should -Be $InstanceName
                    $result.Ensure | Should -Be 'Present'
                    $result.AutomatedBackupPreference | Should -Be $mockAvailabilityGroupProperties.AutomatedBackupPreference
                    $result.AvailabilityMode | Should -Be $mockAvailabilityGroupReplicaProperties.$mockSqlServer.AvailabilityMode
                    $result.BackupPriority | Should -Be $mockAvailabilityGroupReplicaProperties.$mockSqlServer.BackupPriority
                    $result.ConnectionModeInPrimaryRole | Should -Be $mockAvailabilityGroupReplicaProperties.$mockSqlServer.ConnectionModeInPrimaryRole
                    $result.ConnectionModeInSecondaryRole | Should -Be $mockAvailabilityGroupReplicaProperties.$mockSqlServer.ConnectionModeInSecondaryRole
                    $result.EndpointURL | Should -Be "$($mockAvailabilityGroupReplicaProperties.$mockSqlServer.EndpointProtocol)://$($mockAvailabilityGroupReplicaProperties.$mockSqlServer.EndpointHostName):$($mockAvailabilityGroupReplicaProperties.$mockSqlServer.EndpointPort)"
                    $result.FailureConditionLevel | Should -Be $mockAvailabilityGroupProperties.FailureConditionLevel
                    $result.FailoverMode | Should -Be $mockAvailabilityGroupReplicaProperties.$mockSqlServer.FailoverMode
                    $result.HealthCheckTimeout | Should -Be $mockAvailabilityGroupProperties.HealthCheckTimeout

                    if ( $Version -ge 13 )
                    {
                        $result.BasicAvailabilityGroup | Should -Be $mockAvailabilityGroupProperties.BasicAvailabilityGroup
                        $result.DatabaseHealthTrigger | Should -Be $mockAvailabilityGroupProperties.DatabaseHealthTrigger
                        $result.DtcSupportEnabled | Should -Be $mockAvailabilityGroupProperties.DtcSupportEnabled
                    }
                    else
                    {
                        $result.BasicAvailabilityGroup | Should -BeNullOrEmpty
                        $result.DatabaseHealthTrigger | Should -BeNullOrEmpty
                        $result.DtcSupportEnabled | Should -BeNullOrEmpty
                    }

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'SqlAG\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSql -Verifiable
                Mock -CommandName New-SqlAvailabilityGroup $mockNewSqlAvailabilityGroup -Verifiable
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityGroupReplica -Verifiable
                Mock -CommandName Remove-SqlAvailabilityGroup -Verifiable -ParameterFilter {
                    $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                }
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {
                    throw 'RemoveAvailabilityGroupFailed'
                } -Verifiable -ParameterFilter {
                    $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                }
                Mock -CommandName Test-ClusterPermissions -Verifiable
                Mock -CommandName Update-AvailabilityGroup -MockWith $mockUpdateAvailabilityGroup -Verifiable
                Mock -CommandName Update-AvailabilityGroupReplica -MockWith $mockUpdateAvailabilityGroupReplica -Verifiable
            }

            Context 'When the Availability Group is Absent and the desired state is Present and a parameter is supplied' {
                It 'Should create the availability group "<Name>" with the parameter "<ParameterName>" set to "<ParameterValue>" when Ensure is "<Ensure>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $setTargetResourceCreateAvailabilityGroupWithParameterTestCases {
                    param
                    (
                        $DomainInstanceName,
                        $Ensure,
                        $Name,
                        $ParameterName,
                        $ParameterValue,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $setTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                        $ParameterName = $ParameterValue
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times @{Absent=0;Present=1}.$Ensure -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times @{Absent=0;Present=1}.$Ensure -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                    }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                    }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times @{Absent=0;Present=1}.$Ensure -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the Availability Group is Absent, the desired state is Present, and creating the Availability Group fails' {
                It 'Should throw "<ErrorResult>" when creating the availability group "<Name>" fails, Ensure is "<Ensure>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $setTargetResourceCreateAvailabilityGroupFailedTestCases {
                    param
                    (
                        $ErrorResult,
                        $Ensure,
                        $Name,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    switch ( $ErrorResult )
                    {
                        'CreateAvailabilityGroupFailed'
                        {
                            $assertCreateAvailabilityGroup = 1
                            $errorMessage = $script:localizedData.FailedCreateAvailabilityGroup -f $Name, $InstanceName
                        }

                        'CreateAvailabilityGroupReplicaFailed'
                        {
                            $assertCreateAvailabilityGroup = 0
                            if ($InstanceName -eq 'MSSQLSERVER')
                            {
                                $errorMessage = $script:localizedData.FailedCreateAvailabilityGroupReplica -f 'Server1', $InstanceName
                            }
                            else
                            {
                                $errorMessage = $script:localizedData.FailedCreateAvailabilityGroupReplica -f 'Server1\NamedInstance', $InstanceName
                            }
                        }
                    }

                    $setTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times $assertCreateAvailabilityGroup -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                    }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                    }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the Availability Group is Present and a value is passed to a parameter' {
                It 'Should set "<ParameterName>" to "<ParameterValue>" when Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $setTargetResourcePropertyIncorrectTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $ParameterName,
                        $ParameterValue,
                        $Result,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $setTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                        $ParameterName = $ParameterValue
                    }

                    if ( $mockAvailabilityGroupProperties.Keys -contains $ParameterName )
                    {
                        $assertUpdateAvailabilityGroupMockCalled = 1
                        $assertUpdateAvailabilityGroupReplicaMockCalled = 0
                    }
                    elseif ( $mockAvailabilityGroupReplicaProperties.Server1.Keys -contains $ParameterName )
                    {
                        $assertUpdateAvailabilityGroupMockCalled = 0
                        $assertUpdateAvailabilityGroupReplicaMockCalled = 1
                    }

                    Set-TargetResource @setTargetResourceParameters
                    #{ Set-TargetResource @setTargetResourceParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                    }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                    }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times $assertUpdateAvailabilityGroupMockCalled -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times $assertUpdateAvailabilityGroupReplicaMockCalled -Exactly
                }
            }

            Context 'When the Availability Group is Present and the desired state is Absent' {
                It 'Should remove the Availability Group "<Name>" when Ensure is "<Ensure>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $setTargetResourceRemoveAvailabilityGroupTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $setTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                    }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                    }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the Availability Group is Present and throws an error when removal is attempted' {
                It 'Should throw "<ErrorResult>" when Ensure is "<Ensure>", Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $setTargetResourceRemoveAvailabilityGroupErrorTestCases {
                    param
                    (
                        $ErrorResult,
                        $Ensure,
                        $Name,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    switch ( $ErrorResult )
                    {
                        'RemoveAvailabilityGroupFailed'
                        {
                            $assertRemoveAvailabilityGroupFailed = 1
                            $errorMessage = $script:localizedData.FailedRemoveAvailabilityGroup -f $Name, $InstanceName
                        }

                        'InstanceNotPrimaryReplica'
                        {
                            $assertRemoveAvailabilityGroupFailed = 0
                            if ($InstanceName -eq 'MSSQLSERVER')
                            {
                                $errorMessage = $script:localizedData.NotPrimaryReplica -f 'Server2', $Name, 'Server1'
                            }
                            else
                            {
                                $errorMessage = $script:localizedData.NotPrimaryReplica -f 'Server2\NamedInstance', $Name, 'Server1\NamedInstance'
                            }
                        }
                    }

                    $setTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                    }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times $assertRemoveAvailabilityGroupFailed -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                    }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When HADR is not enabled' {
                AfterAll {
                    $mockIsHadrEnabled = $true
                }

                BeforeAll {
                    $mockIsHadrEnabled = $false
                }

                It 'Should throw "<Result>" when Ensure is "<Ensure>", Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $setTargetResourceHadrDisabledTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Result,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $setTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                    }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                    }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the Database Mirroring Endpoint is missing' {
                AfterAll {
                    $mockIsDatabaseMirroringEndpointPresent = $true
                }

                BeforeAll {
                    $mockIsDatabaseMirroringEndpointPresent = $false
                }

                It 'Should throw "<Result>" when Ensure is "<Ensure>", Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $setTargetResourceEndpointMissingTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Result,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $setTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                    }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                    }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the Endpoint URL is incorrect' {
                AfterEach {
                    # Restore up the original endpoint url settings
                    $mockAvailabilityGroupReplicaProperties.Server1 = $mockAvailabilityGroupReplicaPropertiesServer1Original.Clone()
                    $mockAvailabilityGroupReplicaProperties.Server2 = $mockAvailabilityGroupReplicaPropertiesServer2Original.Clone()
                }

                BeforeEach {
                    # Back up the original endpoint url settings
                    $mockAvailabilityGroupReplicaPropertiesServer1Original = $mockAvailabilityGroupReplicaProperties.Server1.Clone()
                    $mockAvailabilityGroupReplicaPropertiesServer2Original = $mockAvailabilityGroupReplicaProperties.Server2.Clone()
                }

                It 'Should set "<EndpointPropertyName>" to "<EndpointPropertyValue>" when Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $setTargetResourcesEndpointUrlTestCases {
                    param
                    (
                        $EndpointPropertyName,
                        $EndpointPropertyValue,
                        $Ensure,
                        $Name,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $mockAvailabilityGroupReplicaProperties.Server1.$EndpointPropertyName = $EndpointPropertyValue
                    $mockAvailabilityGroupReplicaProperties.Server2.$EndpointPropertyName = $EndpointPropertyValue

                    $setTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-PrimaryReplicaServerObject -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.PresentAvailabilityGroup
                    }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter {
                        $InputObject.Name -eq $mockNameParameters.RemoveAvailabilityGroupFailed
                    }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'SqlAG\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock -CommandName Test-ActiveNode -MockWith {
                    $mockProcessOnlyOnActiveNode
                } -Verifiable
            }

            Context 'When the Availability Group is Absent' {
                It 'Should be "<Result>" when Ensure is "<Ensure>", Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourceAbsentTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Result,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present and the default parameters are passed' {
                It 'Should be "<Result>" when Ensure is "<Ensure>", Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourcePresentTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Result,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present and a value is passed to a parameter' {
                It 'Should be "<Result>" when "<ParameterName>" is "<ParameterValue>", Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourcePropertyIncorrectTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $ParameterName,
                        $ParameterValue,
                        $Result,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                        $ParameterName = $ParameterValue
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present an Endpoint property is incorrect' {
                AfterEach {
                    # Restore up the original endpoint url settings
                    $mockAvailabilityGroupReplicaProperties.Server1 = $mockAvailabilityGroupReplicaPropertiesServer1Original.Clone()
                    $mockAvailabilityGroupReplicaProperties.Server2 = $mockAvailabilityGroupReplicaPropertiesServer2Original.Clone()
                }

                BeforeEach {
                    # Back up the original endpoint url settings
                    $mockAvailabilityGroupReplicaPropertiesServer1Original = $mockAvailabilityGroupReplicaProperties.Server1.Clone()
                    $mockAvailabilityGroupReplicaPropertiesServer2Original = $mockAvailabilityGroupReplicaProperties.Server2.Clone()
                }

                It 'Should be "<Result>" when "<EndpointPropertyName>" is "<EndpointPropertyValue>", Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourceEndpointIncorrectTestCases {
                    param
                    (
                        $EndpointPropertyName,
                        $EndpointPropertyValue,
                        $Ensure,
                        $Name,
                        $Result,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $mockAvailabilityGroupReplicaProperties.Server1.$EndpointPropertyName = $EndpointPropertyValue
                    $mockAvailabilityGroupReplicaProperties.Server2.$EndpointPropertyName = $EndpointPropertyValue

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the ProcessOnlyOnActiveNode parameter is passed' {
                AfterAll {
                    $mockProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNodeOriginal
                }

                BeforeAll {
                    $mockProcessOnlyOnActiveNodeOriginal = $mockProcessOnlyOnActiveNode
                    $mockProcessOnlyOnActiveNode = $false
                }

                It 'Should be "true" when ProcessOnlyOnActiveNode is "<ProcessOnlyOnActiveNode>", Ensure is "<Ensure>", Name is "<Name>", ServerName is "<ServerName>", InstanceName is "<InstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourceProcessOnlyOnActiveNodeTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $ProcessOnlyOnActiveNode,
                        $ServerName,
                        $InstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        ProcessOnlyOnActiveNode = $ProcessOnlyOnActiveNode
                        ServerName = $ServerName
                        InstanceName = $InstanceName
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'SqlAG\Update-AvailabilityGroup' -Tag 'Helper' {
            BeforeAll {
                $mockAvailabilityGroup = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            }

            Context 'When the Availability Group is altered' {
                It 'Should silently alter the Availability Group' {

                    { Update-AvailabilityGroup -AvailabilityGroup $mockAvailabilityGroup } | Should -Not -Throw
                }

                It 'Should throw the correct error, AlterAvailabilityGroupFailed, when altering the Availability Group fails' {

                    $mockAvailabilityGroup.Name = 'AlterFailed'

                    { Update-AvailabilityGroup -AvailabilityGroup $mockAvailabilityGroup } | Should -Throw ($script:localizedData.FailedAlterAvailabilityGroup -f $mockAvailabilityGroup.Name)
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
