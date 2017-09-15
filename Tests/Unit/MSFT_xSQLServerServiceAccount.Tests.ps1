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

function Invoke-TestSetup
{
    # Compile the SMO stubs for use by the unit tests.`
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {

        $mockSqlServer = 'TestServer'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockNamedInstance = 'TestInstance'
        $mockServiceType = 'DatabaseEngine'
        $mockDesiredServiceAccountName = 'CONTOSO\sql.service'
        $mockServiceAccountCredential = (New-Object -TypeName System.Management.Automation.PSCredential $mockDesiredServiceAccountName, (New-Object -TypeName System.Security.SecureString))
        $mockDefaultServiceAccountName = 'NT SERVICE\MSSQLSERVER'
        $mockDefaultServiceAccountCredential = (New-Object -TypeName System.Management.Automation.PSCredential $mockDefaultServiceAccountName, (New-Object -TypeName System.Security.SecureString))
        $mockLocalServiceAccountName = "$($mockSqlServer)\SqlService"
        $mockLocalServiceAccountCredential = (New-Object -TypeName System.Management.Automation.PSCredential $mockLocalServiceAccountName, (New-Object -TypeName System.Security.SecureString))

        # Stores the result of SetServiceAccount calls
        $testServiceAccountUpdated = @{
            Processed = $false
            NewUserAccount = [String]::Empty
            NewPassword = [String]::Emtpy
        }

        # Script block for changing the service account in mocks
        $mockSetServiceAccount = {
            param
            (
                [System.String]
                $User,

                [System.String]
                $Pass
            )

            # Update the object
            $testServiceAccountUpdated.Processed = $true
            $testServiceAccountUpdated.NewUserAccount = $User
            $testServiceAccountUpdated.NewPassword = $Pass
        }

        # Splat for creating the SetServiceAccount method
        $mockAddMemberParameters_SetServiceAccount = @{
            Name = 'SetServiceAccount'
            MemberType = 'ScriptMethod'
            Value = $mockSetServiceAccount
        }

        # Used to mock ManagedComputer object for a default instance
        $mockNewObject_ManagedComputer_DefaultInstance = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name = $mockDefaultInstanceName
                        ServiceAccount = $mockDefaultServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object {
                $_ | Add-Member @mockAddMemberParameters_SetServiceAccount
            }

            return $managedComputerObject
        }

        # Creates a new ManagedComputer object for a default instance with a local service account
        $mockNewObject_ManagedComputer_DefaultInstance_LocalServiceAccount = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name = $mockDefaultInstanceName
                        ServiceAccount = ($mockLocalServiceAccountName -replace $mockSqlServer,'.')
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object {
                $_ | Add-Member @mockAddMemberParameters_SetServiceAccount
            }

            return $managedComputerObject
        }

        # Creates a new ManagedComputer object for a default instance that thows an exception
        # when attempting to set the service account
        $mockNewObject_ManagedComputer_DefaultInstance_SetServiceAccountException = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name = $mockDefaultInstanceName
                        ServiceAccount = $mockDefaultServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object {
                $_ | Add-Member -Name SetServiceAccount -MemberType ScriptMethod -Value {
                    param
                    (
                        [System.String]
                        $User,

                        [System.String]
                        $Pass
                    )

                    throw (New-Object -TypeName Microsoft.SqlServer.Management.Smo.FailedOperationException 'SetServiceAccount')
                }
            }

            return $managedComputerObject
        }

        # Used to mock a ManagedComputer object for a named instance
        $mockNewObject_ManagedComputer_NamedInstance = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name = ('MSSQL${0}' -f $mockNamedInstance)
                        ServiceAccount = $mockDesiredServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object {
                $_ | Add-Member @mockAddMemberParameters_SetServiceAccount
            }

            return $managedComputerObject
        }

        # Used to mock a ManagedComputer object that fails to change the service account
        $mockNewObject_ManagedComputer_NamedInstance_SetServiceAccountException = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name = ('MSSQL${0}' -f $mockNamedInstance)
                        ServiceAccount = $mockDesiredServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object {
                $_ | Add-Member -Name SetServiceAccount -MemberType ScriptMethod -Value {
                    param
                    (
                        [System.String]
                        $User,

                        [System.String]
                        $Pass
                    )

                    throw (New-Object -TypeName Microsoft.SqlServer.Management.Smo.FailedOperationException 'SetServiceAccount')
                }
            }

            return $managedComputerObject
        }

        # Parameter filter for mocks of New-Object
        $mockNewObject_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        }

        # Splat to simplify creation of Mock for New-Object with a default instance
        $mockNewObjectParameters_DefaultInstance = @{
            CommandName = 'New-Object'
            MockWith = $mockNewObject_ManagedComputer_DefaultInstance
            ParameterFilter = $mockNewObject_ParameterFilter
            Verifiable = $true
        }

        # Splat to simplify creation of Mock for New-Object with a named instance
        $mockNewObjectParameters_NamedInstance = @{
            CommandName = 'New-Object'
            MockWith = $mockNewObject_ManagedComputer_NamedInstance
            ParameterFilter = $mockNewObject_ParameterFilter
            Verifiable = $true
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

        Describe 'MSFT_xSQLServerServiceAccount\Get-ServiceObject' -Tag 'Helper' {
            Mock -CommandName Import-SQLPSModule -Verifiable

            $defaultGetServiceObjectParameters = @{
                SQLServer = $mockSqlServer
                SQLInstanceName = ''
                ServiceType = $mockServiceType
            }

            Context 'When getting the service information for a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance

                It 'Should have the correct Type for the service' {
                    $getServiceObjectParameters = $defaultGetServiceObjectParameters.Clone()
                    $getServiceObjectParameters.SQLInstanceName = $mockDefaultInstanceName

                    $serviceObject = Get-ServiceObject @getServiceObjectParameters
                    $serviceObject.Type | Should Be 'SqlServer'

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -Scope It -Exactly -Times 1
                }
            }

            Context 'When getting the service information for a named instance' {
                Mock @mockNewObjectParameters_NamedInstance

                It 'Should have the correct Type for the service' {
                    $getServiceObjectParameters = $defaultGetServiceObjectParameters.Clone()
                    $getServiceObjectParameters.SQLInstanceName = $mockNamedInstance

                    $serviceObject = Get-ServiceObject @getServiceObjectParameters
                    $serviceObject.Type | Should Be 'SqlServer'

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -Scope It -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\Get-TargetResource' -Tag 'Get' {
            Mock -CommandName Import-SQLPSModule -Verifiable

            Context 'When getting the service information for a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance

                $defaultGetTargetResourceParameters = @{
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockDefaultInstanceName
                    ServiceType = $mockServiceType
                    ServiceAccount = $mockDefaultServiceAccountCredential
                }

                It 'Should return the correct service information' {
                    # Get the service information
                    $testServiceInformation = Get-TargetResource @defaultGetTargetResourceParameters

                    # Validate the hashtable returned
                    $testServiceInformation.SQLServer | Should Be $mockSqlServer
                    $testServiceInformation.SQLInstanceName | Should Be $mockDefaultInstanceName
                    $testServiceInformation.ServiceType | Should Be 'SqlServer'
                    $testServiceInformation.ServiceAccount | Should Be $mockDefaultServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }

                It 'Should throw the correct exception when an invalid ServiceType and InstanceName are specified' {
                    $getTargetResourceParameters = $defaultGetTargetResourceParameters.Clone()
                    $getTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    { Get-TargetResource @getTargetResourceParameters } |
                        Should Throw "The SQLServerAgent service on $($mockSqlServer)\$($mockDefaultInstanceName) could not be found."

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When getting the service information for a named instance' {
                Mock @mockNewObjectParameters_NamedInstance

                # Splat the function parameters
                $defaultGetTargetResourceParameters = @{
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockNamedInstance
                    ServiceType = $mockServiceType
                    ServiceAccount = $mockServiceAccountCredential
                }

                It 'Should return the correct service information' {
                    # Get the service information
                    $testServiceInformation = Get-TargetResource @defaultGetTargetResourceParameters

                    # Validate the hashtable returned
                    $testServiceInformation.SQLServer | Should Be $mockSqlServer
                    $testServiceInformation.SQLInstanceName | Should Be $mockNamedInstance
                    $testServiceInformation.ServiceType | Should Be 'SqlServer'
                    $testServiceInformation.ServiceAccount | Should Be $mockDesiredServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }

                It 'Should throw the correct exception when an invalid ServiceType and InstanceName are specified' {
                    $getTargetResourceParameters = $defaultGetTargetResourceParameters.Clone()
                    $getTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    { Get-TargetResource @getTargetResourceParameters } |
                        Should Throw "The SQLServerAgent service on $($mockSqlServer)\$($mockNamedInstance) could not be found."

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the service account is local to the machine' {
                $mockNewObjectParameters = $mockNewObjectParameters_DefaultInstance.Clone()
                $mockNewObjectParameters.MockWith = $mockNewObject_ManagedComputer_DefaultInstance_LocalServiceAccount

                Mock @mockNewObjectParameters

                $defaultGetTargetResourceParameters = @{
                    SQLServer = $mockSqlServer
                    SQLInstanceName = $mockDefaultInstanceName
                    ServiceType = $mockServiceType
                    ServiceAccount = $mockLocalServiceAccountCredential
                }

                It 'Should have the same domain name as the computer name' {
                    $currentState = Get-TargetResource @defaultGetTargetResourceParameters

                    # Validate the service account
                    $currentState.ServiceAccount | Should Be $mockLocalServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\Test-TargetResource' -Tag 'Test' {
            Mock -CommandName Import-SQLPSModule -Verifiable

            Context 'When the system is not in the desired state for a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state or a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $true

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state and Force is specified' {
                Mock @mockNewObjectParameters_DefaultInstance

                It 'Should return False when Force is specified' {
                    $testTargetResourceParameters = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                        Force = $true
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 0
                }
            }

            Context 'When the system is not in the desired state for a named instance' {
                Mock @mockNewObjectParameters_NamedInstance

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockNamedInstance
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state for a named instance' {
                Mock @mockNewObjectParameters_NamedInstance

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockNamedInstance
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should Be $true

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state for a named instance and Force is specified' {
                Mock @mockNewObjectParameters_NamedInstance

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockNamedInstance
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                        Force = $true
                    }

                    # Validate the return  value
                    Test-TargetResource @testTargetResourceParameters | Should Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 0
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\Set-TargetResource' -Tag 'Set' {
            Mock -CommandName Import-SQLPSModule -Verifiable

            Context 'When changing the service account for the default instance' {
                BeforeAll {
                    $defaultSetTargetResourceParameters = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Mock @mockNewObjectParameters_DefaultInstance

                    Mock -CommandName Restart-SqlService -Verifiable
                }

                BeforeEach {
                    $testServiceAccountUpdated.Processed = $false
                    $testServiceAccountUpdated.NewUserAccount = [String]::Empty
                    $testServiceAccountUpdated.NewPassword = [String]::Empty
                }

                It 'Should update the service account information' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                    # Update the service information
                    Set-TargetResource @setTargetResourceParameters

                    # Validate that the correct information was passed through and updated
                    $testServiceAccountUpdated.Processed | Should Be $true
                    $testServiceAccountUpdated.NewUserAccount | Should Be $setTargetResourceParameters.ServiceAccount.Username
                    $testServiceAccountUpdated.NewPassword | Should Be $setTargetResourceParameters.ServiceAccount.GetNetworkCredential().Password

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }

                It 'Should throw the correct exception when an invalid service name and type is provided' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    # Get the localized error message
                    $mockCorrectErrorMessage = $script:localizedData.SericeNotFound -f $setTargetResourceParameters.ServiceType, $setTargetResourceParameters.SQLServer, $setTargetResourceParameters.SQLInstanceName

                    # Attempt to update the service account
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw $mockCorrectErrorMessage

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }

                It 'Should restart the service if requested' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters += @{
                        RestartService = $true
                    }

                    Set-TargetResource @setTargetResourceParameters

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 1
                }

                It 'Should throw the correct exception if SetServiceAccount call fails' {
                    $newObjectParms = $mockNewObjectParameters_DefaultInstance.Clone()
                    $newObjectParms.MockWith = $mockNewObject_ManagedComputer_DefaultInstance_SetServiceAccountException

                    Mock @newObjectParms

                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                    # Get the localized error message
                    $mockCorrectErrorMessage = $script:localizedData.SetServiceAccountFailed -f $setTargetResourceParameters.SQLServer, $setTargetResourceParameters.SQLInstanceName, ''

                    # Attempt to update the service account
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw $mockCorrectErrorMessage

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }
            }

            Context 'When changing the service account for the default instance' {
                BeforeAll {
                    $defaultSetTargetResourceParameters = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockNamedInstance
                        ServiceType = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Mock @mockNewObjectParameters_NamedInstance

                    Mock -CommandName Restart-SqlService -Verifiable
                }

                BeforeEach {
                    $testServiceAccountUpdated.Processed = $false
                    $testServiceAccountUpdated.NewUserAccount = [String]::Empty
                    $testServiceAccountUpdated.NewPassword = [String]::Empty
                }

                It 'Should update the service account information' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                    # Update the service information
                    Set-TargetResource @setTargetResourceParameters

                    # Validate that the correct information was passed through and updated
                    $testServiceAccountUpdated.Processed | Should Be $true
                    $testServiceAccountUpdated.NewUserAccount | Should Be $setTargetResourceParameters.ServiceAccount.Username
                    $testServiceAccountUpdated.NewPassword | Should Be $setTargetResourceParameters.ServiceAccount.GetNetworkCredential().Password

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }

                It 'Should throw the correct exception when an invalid service name and type is provided' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    # Get the expected localized error message
                    $mockCorrectErrorMessage = $script:localizedData.SericeNotFound -f $setTargetResourceParameters.ServiceType, $setTargetResourceParameters.SQLServer, $setTargetResourceParameters.SQLInstanceName

                    # Attempt to update the service account
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw $mockCorrectErrorMessage

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }

                It 'Should restart the service if requested' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters += @{
                        RestartService = $true
                    }

                    Set-TargetResource @setTargetResourceParameters

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 1
                }

                It 'Should throw the correct exception if SetServiceAccount call fails' {
                    $newObjectParms = $mockNewObjectParameters_NamedInstance.Clone()
                    $newObjectParms.MockWith = $mockNewObject_ManagedComputer_NamedInstance_SetServiceAccountException

                    Mock @newObjectParms

                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                    # Get the expected localized error message
                    $mockCorrectErrorMessage = $script:localizedData.SetServiceAccountFailed -f $setTargetResourceParameters.SQLServer, $setTargetResourceParameters.SQLInstanceName, ''

                    # Attempt to update the service information
                    { Set-TargetResource @setTargetResourceParameters } | Should Throw $mockCorrectErrorMessage

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
