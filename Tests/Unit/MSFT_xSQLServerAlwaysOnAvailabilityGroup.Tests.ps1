#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Tests' -ChildPath (Join-Path -Path 'TestHelpers' -ChildPath 'CommonTestHelper.psm1'))) -Force -Global

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xSQLServer' `
    -DSCResourceName 'MSFT_xSQLServerAlwaysOnAvailabilityGroup' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    # Load the SMO stubs
    Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

    # Load the default SQL Module stub
    Import-SQLModuleStub
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xSQLServerAlwaysOnAvailabilityGroup' {

        #region parameter mocks

        # Define the values that could be passed into the Name parameter
        $mockNameParameters = @{
            AbsentAvailabilityGroup = 'AvailabilityGroup2'
            PresentAvailabilityGroup = 'AvailabilityGroup1'
        }

        # Define the values that could be passed into the SQLServer parameter
        $mockSqlServerParameters = @{
            Server1 = @{
                FQDN = 'Server1.contoso.com'
                IP = '192.168.1.1'
                NetBIOS = 'Server1'
            }
            Server2 = @{
                FQDN = 'Server2.contoso.com'
                IP = '192.168.1.2'
                NetBIOS = 'Server2'
            }
        }

        # Define the values that could be passed into the SQLInstanceName parameter
        $mockSqlInstanceNameParameters = @(
            'MSSQLSERVER',
            'NamedInstance'
        )

        #endregion parameter mocks

        #region property mocks

        $mockIsHadrEnabled = $true
        $mockIsDatabaseMirroringEndpointPresent = $true

        $mockServerObjectProperies = @{
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
            PrimaryReplicaServerName = $mockServerObjectProperies.Server1.NetName
        }

        $mockAvailabilityGroupReplicaProperties = @{
            Server1 = @{
                AvailabilityMode = 'SynchronousCommit' # Not the default parameter value
                BackupPriority = 49 # Not the default parameter value
                ConnectionModeInPrimaryRole = 'AllowAllConnections' # Not the default parameter value
                ConnectionModeInSecondaryRole = 'AllowNoConnections' # Not the default parameter value
                EndpointHostName = $mockServerObjectProperies.Server1.NetName
                EndpointProtocol = 'TCP'
                EndpointPort = 5022
                FailoverMode = 'Automatic' # Not the default parameter value
                Name = $mockServerObjectProperies.Server1.NetName
                Role = 'Primary'
            }
            Server2 = @{
                AvailabilityMode = 'SynchronousCommit' # Not the default parameter value
                BackupPriority = 49 # Not the default parameter value
                ConnectionModeInPrimaryRole = 'AllowAllConnections' # Not the default parameter value
                ConnectionModeInSecondaryRole = 'AllowNoConnections' # Not the default parameter value
                EndpointHostName = $mockServerObjectProperies.Server2.NetName
                EndpointProtocol = 'TCP'
                EndpointPort = 5022
                FailoverMode = 'Automatic' # Not the default parameter value
                Name = $mockServerObjectProperies.Server2.NetName
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
        $setTargetResourceAbsentTestCases = @()
        $setTargetResourcePresentTestCases = @()
        $testTargetResourcePropertyIncorrectTestCases = @()
        $testTargetResourceEndpointIncorrectTestCases = @()
        $testTargetResourceAbsentTestCases = @()
        $testTargetResourcePresentTestCases = @()

        $majorVersionsToTest = @(12,13)
        $ensureCasesToTest = @('Absent','Present')
        $endpointUrlPropertiesToTest = @('EndpointPort','EndpointProtocol')

        # Get all of the parameters tied with the resource except the required parameters, Ensure, and DtcSupportEnabled
        $resourceParameters = @{}
        ( Get-Command -Name Test-TargetResource ).Parameters.Values | Where-Object -FilterScript {
            (
                # Ignore these specific parameters. These get tested enough.
                @('Ensure', 'Name', 'SQLServer', 'SQLInstanceName', 'DtcSupportEnabled') -notcontains $_.Name
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
            foreach ( $mockSqlServerParameter in $mockSqlServerParameters.Values.Values )
            {
                foreach ( $mockSqlInstanceNameParameter in $mockSqlInstanceNameParameters )
                {
                    $getTargetResourceAbsentTestCases += @{
                        Name = $mockNameParameters.AbsentAvailabilityGroup
                        SQLServer = $mockSqlServerParameter
                        SQLInstanceName = $mockSqlInstanceNameParameter
                        Version = $majorVersionToTest
                    }

                    $getTargetResourcePresentTestCases += @{
                        Name = $mockNameParameters.PresentAvailabilityGroup
                        SQLServer = $mockSqlServerParameter
                        SQLInstanceName = $mockSqlInstanceNameParameter
                        Version = $majorVersionToTest
                    }

                    # Create test cases for Absent/Present
                    foreach ( $ensureCaseToTest in $ensureCasesToTest )
                    {
                        $testTargetResourceAbsentTestCases += @{
                            Ensure = $ensureCaseToTest
                            Name = $mockNameParameters.AbsentAvailabilityGroup
                            Result = ( $ensureCaseToTest -eq 'Absent' )
                            SQLServer = $mockSqlServerParameter
                            SQLInstanceName = $mockSqlInstanceNameParameter
                            Version = $majorVersionToTest
                        }

                        $testTargetResourcePresentTestCases += @{
                            Ensure = $ensureCaseToTest
                            Name = $mockNameParameters.PresentAvailabilityGroup
                            Result = ( $ensureCaseToTest -eq 'Present' )
                            SQLServer = $mockSqlServerParameter
                            SQLInstanceName = $mockSqlInstanceNameParameter
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
                                if ( [string]::IsNullOrEmpty($testCaseParameterValue) )
                                {
                                    $testCaseParameterValue = 'IncorrectValue'
                                }
                            }

                            default
                            {
                                $testCaseParameterValue = $null
                            }
                        }

                        $testTargetResourcePropertyIncorrectTestCases += @{
                            Ensure = 'Present'
                            Name = $mockNameParameters.PresentAvailabilityGroup
                            ParameterName = $resourceParameter.Key
                            ParameterValue = $testCaseParameterValue
                            Result = $false
                            SQLServer = $mockSqlServerParameter
                            SQLInstanceName = $mockSqlInstanceNameParameter
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
                                $endpointPropertyValue = 'Incorrect'
                            }
                        }

                        $testTargetResourceEndpointIncorrectTestCases += @{
                            EndpointPropertyName = $endpointProperty
                            EndpointPropertyValue = $endpointPropertyValue
                            Ensure = 'Present'
                            Name = $mockNameParameters.PresentAvailabilityGroup
                            Result = $false
                            SQLServer = $mockSqlServerParameter
                            SQLInstanceName = $mockSqlInstanceNameParameter
                            Version = $majorVersionToTest
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
                [string]
                $SQLServer,

                [Parameter()]
                [string]
                $SQLInstanceName
            )

            # Determine which SQL Server mock data we will use
            $mockSqlServer = ( $mockSqlServerParameters.GetEnumerator() | Where-Object -FilterScript { $_.Value.Values -contains 'Server1' } ).Name
            $mockCurrentServerObjectProperties = $mockServerObjectProperies.$mockSqlServer

            # Build the domain instance name
            if ( $SQLInstanceName -eq 'MSSQLSERVER' )
            {
                $mockDomainInstanceName = $mockCurrentServerObjectProperties.NetName
                $mockPrimaryReplicaServerName = $mockAvailabilityGroupProperties.PrimaryReplicaServerName
                $mockAvailabilityGroupReplica1Name = $mockAvailabilityGroupReplicaProperties.Server1.Name
            }
            else
            {
                $mockDomainInstanceName = '{0}\{1}' -f $mockCurrentServerObjectProperties.NetName,$SQLInstanceName
                $mockPrimaryReplicaServerName = '{0}\{1}' -f $mockAvailabilityGroupProperties.PrimaryReplicaServerName,$SQLInstanceName
                $mockAvailabilityGroupReplica1Name = '{0}\{1}' -f $mockAvailabilityGroupReplicaProperties.Server1.Name,$SQLInstanceName
            }

            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.DomainInstanceName = $mockDomainInstanceName
            $mockServerObject.IsHadrEnabled = $mockIsHadrEnabled
            $mockServerObject.NetName = $mockCurrentServerObjectProperties.NetName
            $mockServerObject.ServiceName = $SQLInstanceName
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

            # Add the availability group to the server object
            $mockAvailabilityGroupObject.AvailabilityReplicas.Add($mockAvailabilityReplica1Object)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject)

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

        #endregion cmdlet mocks

        Describe 'xSQLServerAlwaysOnAvailabilityGroup\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the Availability Group is Absent' {

                It 'Should not return an Availability Group when Name is "<Name>", SQLServer is "<SQLServer>", SQLInstanceName is "<SQLInstanceName>", and the SQL version is "<Version>"' -TestCases $getTargetResourceAbsentTestCases {
                    param
                    (
                        $Name,
                        $SQLServer,
                        $SQLInstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $getTargetResourceParameters = @{
                        Name = $Name
                        SQLServer = $SQLServer
                        SQLInstanceName = $SQLInstanceName
                    }

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.Ensure | Should Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present' {
                It 'Should return the correct Availability Group properties when Name is "<Name>", SQLServer is "<SQLServer>", SQLInstanceName is "<SQLInstanceName>", and the SQL version is "<Version>"' -TestCases $getTargetResourcePresentTestCases {
                    param
                    (
                        $Name,
                        $SQLServer,
                        $SQLInstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $getTargetResourceParameters = @{
                        Name = $Name
                        SQLServer = $SQLServer
                        SQLInstanceName = $SQLInstanceName
                    }

                    $result = Get-TargetResource @getTargetResourceParameters

                    $result.Name | Should Be $Name
                    $result.SQLServer | Should Be $SQLServer
                    $result.SQLInstanceName | Should Be $SQLInstanceName
                    $result.Ensure | Should Be 'Present'
                    $result.AutomatedBackupPreference | Should Be $mockAvailabilityGroupProperties.AutomatedBackupPreference
                    $result.AvailabilityMode | Should Be $mockAvailabilityGroupReplicaProperties.Server1.AvailabilityMode
                    $result.BackupPriority | Should Be $mockAvailabilityGroupReplicaProperties.Server1.BackupPriority
                    $result.ConnectionModeInPrimaryRole | Should Be $mockAvailabilityGroupReplicaProperties.Server1.ConnectionModeInPrimaryRole
                    $result.ConnectionModeInSecondaryRole | Should Be $mockAvailabilityGroupReplicaProperties.Server1.ConnectionModeInSecondaryRole
                    $result.EndpointURL | Should Be "$($mockAvailabilityGroupReplicaProperties.Server1.EndpointProtocol)://$($mockAvailabilityGroupReplicaProperties.Server1.EndpointHostName):$($mockAvailabilityGroupReplicaProperties.Server1.EndpointPort)"
                    $result.FailureConditionLevel | Should Be $mockAvailabilityGroupProperties.FailureConditionLevel
                    $result.FailoverMode | Should Be $mockAvailabilityGroupReplicaProperties.Server1.FailoverMode
                    $result.HealthCheckTimeout | Should Be $mockAvailabilityGroupProperties.HealthCheckTimeout

                    if ( $Version -ge 13 )
                    {
                        $result.BasicAvailabilityGroup | Should Be $mockAvailabilityGroupProperties.BasicAvailabilityGroup
                        $result.DatabaseHealthTrigger | Should Be $mockAvailabilityGroupProperties.DatabaseHealthTrigger
                        $result.DtcSupportEnabled | Should Be $mockAvailabilityGroupProperties.DtcSupportEnabled
                    }
                    else
                    {
                        $result.BasicAvailabilityGroup | Should BeNullOrEmpty
                        $result.DatabaseHealthTrigger | Should BeNullOrEmpty
                        $result.DtcSupportEnabled | Should BeNullOrEmpty
                    }

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroup\Set-TargetResource' -Tag 'Set' {
            Context '<Context-description>' {
                It 'Should ...test-description' {
                    # test-code
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroup\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the Availability Group is Absent' {
                It 'Should be "<Result>" when Ensure is "<Ensure>", Name is "<Name>", SQLServer is "<SQLServer>", SQLInstanceName is "<SQLInstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourceAbsentTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Result,
                        $SQLServer,
                        $SQLInstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        SQLServer = $SQLServer
                        SQLInstanceName = $SQLInstanceName
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present and the default parameters are passed' {
                It 'Should be "<Result>" when Ensure is "<Ensure>", Name is "<Name>", SQLServer is "<SQLServer>", SQLInstanceName is "<SQLInstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourcePresentTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Result,
                        $SQLServer,
                        $SQLInstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        SQLServer = $SQLServer
                        SQLInstanceName = $SQLInstanceName
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present and a value is passed to a parameter' {
                It 'Should be "<Result>" when "<ParameterName>" is "<ParameterValue>", Name is "<Name>", SQLServer is "<SQLServer>", SQLInstanceName is "<SQLInstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourcePropertyIncorrectTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $ParameterName,
                        $ParameterValue,
                        $Result,
                        $SQLServer,
                        $SQLInstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        SQLServer = $SQLServer
                        SQLInstanceName = $SQLInstanceName
                        $ParameterName = $ParameterValue
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the Availability Group is Present an Enpoint property is incorrect' {
                AfterEach {
                    # Restore up the original endpoint url settings
                    $mockAvailabilityGroupReplicaProperties.Server1 = $mockAvailabilityGroupReplicaPropertiesServer1Original.Clone()
                }

                BeforeEach {
                    # Back up the original endpoint url settings
                    $mockAvailabilityGroupReplicaPropertiesServer1Original = $mockAvailabilityGroupReplicaProperties.Server1.Clone()
                }

                It 'Should be "<Result>" when "<EndpointPropertyName>" is "<EndpointPropertyValue>", Name is "<Name>", SQLServer is "<SQLServer>", SQLInstanceName is "<SQLInstanceName>", and the SQL version is "<Version>"' -TestCases $testTargetResourceEndpointIncorrectTestCases {
                    param
                    (
                        $EndpointPropertyName,
                        $EndpointPropertyValue,
                        $Ensure,
                        $Name,
                        $Result,
                        $SQLServer,
                        $SQLInstanceName,
                        $Version
                    )

                    # Ensure the correct stubs are loaded for the SQL version
                    Import-SQLModuleStub -SQLVersion $Version

                    $mockAvailabilityGroupReplicaProperties.Server1.$EndpointPropertyName = $EndpointPropertyValue

                    $testTargetResourceParameters = @{
                        Ensure = $Ensure
                        Name = $Name
                        SQLServer = $SQLServer
                        SQLInstanceName = $SQLInstanceName
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroup\Update-AvailabilityGroup' -Tag 'Helper' {
            Context '<Context-description>' {
                It 'Should ...test-description' {
                    # test-code
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
