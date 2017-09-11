
$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerServiceAccount'

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
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

# Compile the SMO stubs for use by the unit tests.`
Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

function Invoke-TestSetup {}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {

#region - Mocks and Global Objects -
        $mockSqlServer = 'TestServer'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockNamedInstance = 'Testnstance'
        $mockServiceType = 'DatabaseEngine'
        $mockDesiredServiceAccountName = 'CONTOSO\sql.service'
        $mockServiceAccountCredential = (New-Object pscredential $mockDesiredServiceAccountName, (ConvertTo-SecureString -String 'P@ssword1' -AsPlainText -Force))
        $mockDefaultServiceAccountName = 'NT SERVICE\MSSQLSERVER'
        $mockDefaultServiceAccountCredential = (New-Object PSCredential $mockDefaultServiceAccountName, (ConvertTo-SecureString -String 'P@ssword1' -AsPlainText -Force))

        # Stores the result of SetServiceAccount calls
        $testServiceAccountUpdated = @{
            Processed = $false
            NewUserAccount = [String]::Empty
            NewPassword = [String]::Emtpy
        }

        $mockSetServiceAccount = {
            param
            (
                [string]
                $User,

                [string]
                $Pass
            )

            # Update the object
            $testServiceAccountUpdated.Processed = $true
            $testServiceAccountUpdated.NewUserAccount = $User
            $testServiceAccountUpdated.NewPassword = $Pass
        }

        $mockAddMemberParams_SetServiceAccount = @{
            Name = 'SetServiceAccount'
            MemberType = 'ScriptMethod'
            Value = $mockSetServiceAccount
        }

        # Used to mock ManagedComputer object for a default instance
        $mockNewObject_ManagedComputer_DefaultInstance = {
            $managedComputerObject = New-Object PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object PSObject -Property @{
                        Name = $mockDefaultInstanceName
                        ServiceAccount = $mockDefaultServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object { $_ | Add-Member @mockAddMemberParams_SetServiceAccount }

            return $managedComputerObject
        }

        $mockNewObject_ManagedComputer_DefaultInstance_SetServiceAccountException = {
            $managedComputerObject = New-Object PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object PSObject -Property @{
                        Name = $mockDefaultInstanceName
                        ServiceAccount = $mockDefaultServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services |
                ForEach-Object {
                    $_ |
                        Add-Member -Name SetServiceAccount -MemberType ScriptMethod -Value {
                            param
                            (
                                [String]
                                $User,

                                [String]
                                $Pass
                            )

                            throw (New-Object Microsoft.SqlServer.Management.Smo.FailedOperationException 'SetServiceAccount')
                        }
                }

            return $managedComputerObject
        }

        # Used to mock a ManagedComputer object for a named instance
        $mockNewObject_ManagedComputer_NamedInstance = {
            $managedComputerObject = New-Object PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object PSObject -Property @{
                        Name = ('MSSQL${0}' -f $mockNamedInstance)
                        ServiceAccount = $mockDesiredServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object { $_ | Add-Member @mockAddMemberParams_SetServiceAccount }

            return $managedComputerObject
        }

        # Used to mock a ManagedComputer object that fails to change the service account
        $mockNewObject_ManagedComputer_NamedInstance_SetServiceAccountException = {
            $managedComputerObject = New-Object PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object PSObject -Property @{
                        Name = ('MSSQL${0}' -f $mockNamedInstance)
                        ServiceAccount = $mockDesiredServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services |
                ForEach-Object {
                    $_ |
                        Add-Member -Name SetServiceAccount -MemberType ScriptMethod -Value {
                            param
                            (
                                [String]
                                $User,

                                [String]
                                $Pass
                            )

                            throw (New-Object Microsoft.SqlServer.Management.Smo.FailedOperationException 'SetServiceAccount')
                        }
                }

            return $managedComputerObject
        }

        $mockNewObject_ParameterFilter = { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' }

        $mockNewObjectParams_DefaultInstance = @{
            CommandName = 'New-Object'
            MockWith = $mockNewObject_ManagedComputer_DefaultInstance
            ParameterFilter = $mockNewObject_ParameterFilter
            Verifiable = $true
        }

        $mockNewObjectParams_NamedInstance = @{
            CommandName = 'New-Object'
            MockWith = $mockNewObject_ManagedComputer_NamedInstance
            ParameterFilter = $mockNewObject_ParameterFilter
            Verifiable = $true
        }
#endregion

        Mock -CommandName Import-SQLPSModule -MockWith {}

        Describe 'MSFT_xSQLServerServiceAccount\Get-ServiceObject' -Tag 'Helper' {

            Mock -CommandName Import-SQLPSModule -MockWith {}

            $defaultGetServiceObjectParams = @{
                SQLServer = $mockSqlServer
                SQLInstanceName = ''
                ServiceType = $mockServiceType
            }

            Context 'When getting the service information for a default instance' {

                Mock @mockNewObjectParams_DefaultInstance

                It 'Should have the correct Type for the service' {
                    $getServiceObjectParams = $defaultGetServiceObjectParams.Clone()
                    $getServiceObjectParams.SQLInstanceName = $mockDefaultInstanceName

                    $serviceObject = Get-ServiceObject @getServiceObjectParams
                    $serviceObject.Type | Should Be 'SqlServer'
                }
            }

            Context 'When getting the service information for a named instance' {
                Mock @mockNewObjectParams_NamedInstance

                It 'Should have the correct Type for the service' {
                    $getServiceObjectParams = $defaultGetServiceObjectParams.Clone()
                    $getServiceObjectParams.SQLInstanceName = $mockNamedInstance

                    $serviceObject = Get-ServiceObject @getServiceObjectParams
                    $serviceObject.Type | Should Be 'SqlServer'
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\ConvertTo-ManagedServiceType' -Tag 'Helper' {

            Mock -CommandName Import-SQLPSModule -MockWith {}

            Context 'Translating service types' {
                $testCases = @(
                    @{ ServiceType = 'DatabaseEngine'; ExpectedType = 'SqlServer' }
                    @{ ServiceType = 'SQLServerAgent'; ExpectedType = 'SqlAgent' }
                    @{ ServiceType = 'Search'; ExpectedType = 'Search' }
                    @{ ServiceType = 'IntegrationServices'; ExpectedType = 'SqlServerIntegrationService' }
                    @{ ServiceType = 'AnalysisServices'; ExpectedType = 'AnalysisServer' }
                    @{ ServiceType = 'ReportingServices'; ExpectedType = 'ReportServer' }
                    @{ ServiceType = 'SQLServerBrowser'; ExpectedType = 'SqlBrowser' }
                    @{ ServiceType = 'NotificationServices'; ExpectedType = 'NotificationServer' }
                )

                It 'Should properly map <ServiceType> to ManagedServiceType-><ExpectedType>' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $ServiceType,

                        [System.String]
                        $ExpectedType
                    )

                    # Get the ManagedServiceType
                    $managedServiceType = ConvertTo-ManagedServiceType -ServiceType $ServiceType

                    $managedServiceType | Should BeOfType Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType
                    $managedServiceType | Should Be $ExpectedType
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\Get-ServiceObject' -Tag 'Helper' {

            $defaultGetServiceObjectParams = @{
                SQLServer = $mockSqlServer
                SQLInstanceName = ''
                ServiceType = $mockServiceType
            }

            Context 'When getting the service information for a default instance' {

                Mock @mockNewObjectParams_DefaultInstance

                It 'Should have the correct Type for the service' {
                    $getServiceObjectParams = $defaultGetServiceObjectParams.Clone()
                    $getServiceObjectParams.SQLInstanceName = $mockDefaultInstanceName

                    $serviceObject = Get-ServiceObject @getServiceObjectParams
                    $serviceObject.Type | Should Be 'SqlServer'
                }
            }

            Context 'When getting the service information for a named instance' {
                Mock @mockNewObjectParams_NamedInstance

                It 'Should have the correct Type for the service' {
                    $getServiceObjectParams = $defaultGetServiceObjectParams.Clone()
                    $getServiceObjectParams.SQLInstanceName = $mockNamedInstance

                    $serviceObject = Get-ServiceObject @getServiceObjectParams
                    $serviceObject.Type | Should Be 'SqlServer'
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\ConvertTo-ManagedServiceType' -Tag 'Helper' {
            Context 'Translating service types' {
                $testCases = @(
                    @{ ServiceType = 'DatabaseEngine'; ExpectedType = 'SqlServer' }
                    @{ ServiceType = 'SQLServerAgent'; ExpectedType = 'SqlAgent' }
                    @{ ServiceType = 'Search'; ExpectedType = 'Search' }
                    @{ ServiceType = 'IntegrationServices'; ExpectedType = 'SqlServerIntegrationService' }
                    @{ ServiceType = 'AnalysisServices'; ExpectedType = 'AnalysisServer' }
                    @{ ServiceType = 'ReportingServices'; ExpectedType = 'ReportServer' }
                    @{ ServiceType = 'SQLServerBrowser'; ExpectedType = 'SqlBrowser' }
                    @{ ServiceType = 'NotificationServices'; ExpectedType = 'NotificationServer' }
                )

                It 'Should properly map <ServiceType> to ManagedServiceType-><ExpectedType>' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $ServiceType,

                        [System.String]
                        $ExpectedType
                    )

                    # Get the ManagedServiceType
                    $managedServiceType = ConvertTo-ManagedServiceType -ServiceType $ServiceType

                    $managedServiceType | Should BeOfType Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType
                    $managedServiceType | Should Be $ExpectedType
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\Get-TargetResource' -Tag 'Get' {

            Mock -CommandName Import-SQLPSModule -MockWith {}

            Context 'When getting the service information for a default instance' {

                Mock @mockNewObjectParams_DefaultInstance

                $defaultGetTargetResourceParams = @{
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockDefaultInstanceName
                    ServiceType = $mockServiceType
                    ServiceAccount = $mockDefaultServiceAccountCredential
                }

                It 'Should return the correct service information' {

                    # Get the service information
                    $testServiceInformation = Get-TargetResource @defaultGetTargetResourceParams

                    # Validate the hashtable returned
                    $testServiceInformation.SQLServer | Should Be $mockSqlServer
                    $testServiceInformation.SQLInstanceName | Should Be $mockDefaultInstanceName
                    $testServiceInformation.ServiceType | Should Be 'SqlServer'
                    $testServiceInformation.ServiceAccount | Should Be $mockDefaultServiceAccountName
                }

                It 'Should throw an exception when an invalid ServiceType and InstanceName are specified' {
                    $getTargetResourceParams = $defaultGetTargetResourceParams.Clone()
                    $getTargetResourceParams.ServiceType = 'SQLServerAgent'

                    { Get-TargetResource @getTargetResourceParams } |
                        Should Throw "The SQLServerAgent service on $($mockSqlServer)\$($mockDefaultInstanceName) could not be found."
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks

                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 2
                }
            }

            Context 'When getting the service information for a named instance' {

                Mock @mockNewObjectParams_NamedInstance

                # Splat the function parameters
                $defaultGetTargetResourceParams = @{
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockNamedInstance
                    ServiceType = $mockServiceType
                    ServiceAccount = $mockServiceAccountCredential
                }

                It 'Should return the correct service information' {
                    # Get the service information
                    $testServiceInformation = Get-TargetResource @defaultGetTargetResourceParams

                    # Validate the hashtable returned
                    $testServiceInformation.SQLServer | Should Be $mockSqlServer
                    $testServiceInformation.SQLInstanceName | Should Be $mockNamedInstance
                    $testServiceInformation.ServiceType | Should Be 'SqlServer'
                    $testServiceInformation.ServiceAccount | Should Be $mockDesiredServiceAccountName
                }

                It 'Should throw an exception when an invalid ServiceType and InstanceName are specified' {
                    $getTargetResourceParams = $defaultGetTargetResourceParams.Clone()
                    $getTargetResourceParams.ServiceType = 'SQLServerAgent'

                    { Get-TargetResource @getTargetResourceParams } |
                        Should Throw "The SQLServerAgent service on $($mockSqlServer)\$($mockNamedInstance) could not be found."
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks

                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 2
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\Test-TargetResource' -Tag 'Test' {

            Mock -CommandName Import-SQLPSModule -MockWith {}

            Context 'When the system is not in the desired state for a default instance' {

                Mock @mockNewObjectParams_DefaultInstance

                It 'Should return false' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParams | Should Be $false
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state or a default instance' {

                Mock @mockNewObjectParams_DefaultInstance

                It 'Should return true' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParams | Should Be $true
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state and Force is specified' {

                Mock @mockNewObjectParams_DefaultInstance

                It 'Should return false' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                        Force = $true
                    }

                    Test-TargetResource @testTargetResourceParams | Should Be $false
                }

                It 'Should not use any mocked commands' {
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 0
                }
            }

            Context 'When the system is not in the desired state for a named instance' {

                Mock @mockNewObjectParams_NamedInstance

                It 'Should return false' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockNamedInstance
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParams | Should Be $false
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state for a named instance' {

                Mock @mockNewObjectParams_NamedInstance

                It 'Should return true' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockNamedInstance
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParams | Should Be $true
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state for a named instance and Force is specified' {

                Mock @mockNewObjectParams_NamedInstance

                It 'Should return false' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockNamedInstance
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                        Force = $true
                    }

                    Test-TargetResource @testTargetResourceParams | Should Be $false
                }

                It 'Should not use any mocked commands' {
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 0
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\Set-TargetResource' -Tag 'Set' {

            Mock -CommandName Import-SQLPSModule -MockWith {}

            Context 'When changing the service account for the default instance' {

                $defaultSetTargetResourceParams = @{
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockDefaultInstanceName
                    ServiceType = $mockServiceType
                    ServiceAccount = $mockDefaultServiceAccountCredential
                }

                Mock @mockNewObjectParams_DefaultInstance

                Mock -CommandName Restart-SqlService -MockWith {} -Verifiable

                BeforeEach {
                    $testServiceAccountUpdated.Processed = $false
                    $testServiceAccountUpdated.NewUserAccount = [String]::Empty
                    $testServiceAccountUpdated.NewPassword = [String]::Empty
                }

                It 'Should update the service account information' {
                    $setTargetResourceParams = $defaultSetTargetResourceParams.Clone()

                    # Update the service information
                    Set-TargetResource @setTargetResourceParams

                    # Validate that the correct information was passed through and updated
                    $testServiceAccountUpdated.Processed | Should Be $true
                    $testServiceAccountUpdated.NewUserAccount | Should Be $setTargetResourceParams.ServiceAccount.Username
                    $testServiceAccountUpdated.NewPassword | Should Be $setTargetResourceParams.ServiceAccount.GetNetworkCredential().Password
                }

                It 'Should throw an exception when an invalid service name and type is provided' {
                    $setTargetResourceParams = $defaultSetTargetResourceParams.Clone()
                    $setTargetResourceParams.ServiceType = 'SQLServerAgent'

                    { Set-TargetResource @setTargetResourceParams } | Should Throw
                }

                It 'Should restart the service if requested' {
                    $setTargetResourceParams = $defaultSetTargetResourceParams.Clone()
                    $setTargetResourceParams += @{ RestartService = $true }

                    Set-TargetResource @setTargetResourceParams

                    Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }

                It 'Should throw an exception if SetServiceAccount call fails' {
                    $newObjectParms = $mockNewObjectParams_DefaultInstance.Clone()
                    $newObjectParms.MockWith = $mockNewObject_ManagedComputer_DefaultInstance_SetServiceAccountException

                    Mock @newObjectParms

                    $setTargetResourceParams = $defaultSetTargetResourceParams.Clone()

                    # Attempt to update the service information
                    { Set-TargetResource @setTargetResourceParams } | Should Throw "Unable to set the service account for $($setTargetResourceParams.SQLServer) on $($setTargetResourceParams.SQLInstanceName)"

                    # Ensure mocks are used
                    Assert-VerifiableMocks
                }
            }

            Context 'When changing the service account for the default instance' {

                $defaultSetTargetResourceParams = @{
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockNamedInstance
                    ServiceType = $mockServiceType
                    ServiceAccount = $mockDefaultServiceAccountCredential
                }

                Mock @mockNewObjectParams_NamedInstance

                Mock -CommandName Restart-SqlService -MockWith {} -Verifiable

                BeforeEach {
                    $testServiceAccountUpdated.Processed = $false
                    $testServiceAccountUpdated.NewUserAccount = [String]::Empty
                    $testServiceAccountUpdated.NewPassword = [String]::Empty
                }

                It 'Should update the service account information' {
                    $setTargetResourceParams = $defaultSetTargetResourceParams.Clone()

                    # Update the service information
                    Set-TargetResource @setTargetResourceParams

                    # Validate that the correct information was passed through and updated
                    $testServiceAccountUpdated.Processed | Should Be $true
                    $testServiceAccountUpdated.NewUserAccount | Should Be $setTargetResourceParams.ServiceAccount.Username
                    $testServiceAccountUpdated.NewPassword | Should Be $setTargetResourceParams.ServiceAccount.GetNetworkCredential().Password
                }

                It 'Should throw an exception when an invalid service name and type is provided' {
                    $setTargetResourceParams = $defaultSetTargetResourceParams.Clone()
                    $setTargetResourceParams.ServiceType = 'SQLServerAgent'

                    { Set-TargetResource @setTargetResourceParams } | Should Throw
                }

                It 'Should restart the service if requested' {
                    $setTargetResourceParams = $defaultSetTargetResourceParams.Clone()
                    $setTargetResourceParams += @{ RestartService = $true }

                    Set-TargetResource @setTargetResourceParams

                    Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }

                It 'Should throw an exception if SetServiceAccount call fails' {
                    $newObjectParms = $mockNewObjectParams_NamedInstance.Clone()
                    $newObjectParms.MockWith = $mockNewObject_ManagedComputer_NamedInstance_SetServiceAccountException

                    Mock @newObjectParms

                    $setTargetResourceParams = $defaultSetTargetResourceParams.Clone()

                    # Attempt to update the service information
                    { Set-TargetResource @setTargetResourceParams } | Should Throw "Unable to set the service account for $($setTargetResourceParams.SQLServer) on $($setTargetResourceParams.SQLInstanceName)"

                    # Ensure mocks are used
                    Assert-VerifiableMocks
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
