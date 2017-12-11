$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlServiceAccount'

#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    # Compile the SMO stubs for use by the unit tests.
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')
}

function Invoke-TestCleanup
{
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
            Processed      = $false
            NewUserAccount = [System.String]::Empty
            NewPassword    = [System.String]::Emtpy
        }

        # Script block for changing the service account in mocks
        $mockSetServiceAccount = {
            param
            (
                [System.String]
                $User,

                [System.String]
                $Password
            )

            # Update the object
            $testServiceAccountUpdated.Processed = $true
            $testServiceAccountUpdated.NewUserAccount = $User
            $testServiceAccountUpdated.NewPassword = $Password
        }

        # Script block to throw an exception when changing a service account.
        $mockSetServiceAccount_Exception = {
            param
            (
                [System.String]
                $User,

                [System.String]
                $Password
            )

            throw (New-Object -TypeName Microsoft.SqlServer.Management.Smo.FailedOperationException 'SetServiceAccount')
        }

        # Splat for creating the SetServiceAccount method
        $mockAddMemberParameters_SetServiceAccount = @{
            Name       = 'SetServiceAccount'
            MemberType = 'ScriptMethod'
            Value      = $mockSetServiceAccount
        }

        $mockAddMemberParameters_SetServiceAccount_Exception = @{
            Name       = 'SetServiceAccount'
            MemberType = 'ScriptMethod'
            Value      = $mockSetServiceAccount_Exception
        }

        # Used to mock ManagedComputer object for a default instance
        $mockNewObject_ManagedComputer_DefaultInstance = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name     = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name           = $mockDefaultInstanceName
                        ServiceAccount = $mockDefaultServiceAccountName
                        Type           = 'SqlServer'
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
                Name     = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name           = $mockDefaultInstanceName
                        ServiceAccount = ($mockLocalServiceAccountName -replace $mockSqlServer, '.')
                        Type           = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object {
                $_ | Add-Member @mockAddMemberParameters_SetServiceAccount
            }

            return $managedComputerObject
        }

        <#
            Creates a new ManagedComputer object for a default instance that thows an exception
            when attempting to set the service account
        #>
        $mockNewObject_ManagedComputer_DefaultInstance_SetServiceAccountException = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name     = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name           = $mockDefaultInstanceName
                        ServiceAccount = $mockDefaultServiceAccountName
                        Type           = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object {
                $_ | Add-Member @mockAddMemberParameters_SetServiceAccount_Exception
            }

            return $managedComputerObject
        }

        # Used to mock a ManagedComputer object for a named instance
        $mockNewObject_ManagedComputer_NamedInstance = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name     = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name           = ('MSSQL${0}' -f $mockNamedInstance)
                        ServiceAccount = $mockDesiredServiceAccountName
                        Type           = 'SqlServer'
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
                Name     = $mockSqlServer
                Services = @(
                    New-Object -TypeName PSObject -Property @{
                        Name           = ('MSSQL${0}' -f $mockNamedInstance)
                        ServiceAccount = $mockDesiredServiceAccountName
                        Type           = 'SqlServer'
                    }
                )
            }

            $managedComputerObject.Services | ForEach-Object {
                $_ | Add-Member @mockAddMemberParameters_SetServiceAccount_Exception
            }

            return $managedComputerObject
        }

        # Parameter filter for mocks of New-Object
        $mockNewObject_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        }

        # Splat to simplify creation of Mock for New-Object with a default instance
        $mockNewObjectParameters_DefaultInstance = @{
            CommandName     = 'New-Object'
            MockWith        = $mockNewObject_ManagedComputer_DefaultInstance
            ParameterFilter = $mockNewObject_ParameterFilter
            Verifiable      = $true
        }

        # Splat to simplify creation of Mock for New-Object with a named instance
        $mockNewObjectParameters_NamedInstance = @{
            CommandName     = 'New-Object'
            MockWith        = $mockNewObject_ManagedComputer_NamedInstance
            ParameterFilter = $mockNewObject_ParameterFilter
            Verifiable      = $true
        }

        # Registry key used to index service type mappings
        $testServicesRegistryKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services'

        # Hashtable mirroring HKLM:\Software\Microsoft\Microsoft SQL Server\Services
        $testServicesRegistryTable = @{
            'Analysis Server' = @{
                LName = 'MSOLAP$'
                Name = 'MSSQLServerOLAPService'
                Type = 5
            }

            'Full Text' = @{
                LName = 'msftesql$'
                Name = 'msftesql'
                Type = 3
            }

            'Full-text Filter Daemon Launcher' = @{
                LName = 'MSSQLFDLauncher$'
                Name = 'MSSQLFDLauncher'
                Type = 9
            }

            'Launchpad Service' = @{
                LName = 'MSSQLLaunchpad$'
                Name = 'MSSQLLaunchpad'
                Type = 12
            }

            'Notification Services' = @{
                LName = 'NS$'
                Name = 'NsService'
                Type = 8
            }

            'Report Server' = @{
                LName = 'ReportServer$'
                Name = 'ReportServer'
                Type = 6
            }

            'ReportServer' = @{
                LName = 'ReportServer$'
                Name = 'ReportServer'
                Type = 6
            }

            'SQL Agent' = @{
                LName = 'SQLAGENT$'
                Name = 'SQLSERVERAGENT'
                Type = 2
            }

            'SQL Browser' = @{
                LName = ''
                Name = 'SQLBrowser'
                Type = 7
            }

            'SQL Server' = @{
                LName = 'MSSQL$'
                Name = 'MSSQLSERVER'
                Type = 1
            }

            'SQL Server Polybase Data Movement Service' = @{
                LName = 'SQLPBDMS$'
                Name = 'SQLPBDMS'
                Type = 11
            }

            'SQL Server Polybase Engine' = @{
                LName = 'SQLPBENGINE$'
                Name = 'SQLPBENGINE'
                Type = 10
            }

            'SSIS Server' = @{
                LName = ''
                Name = 'MsDtsServer'
                Type = 4
            }
        }

        # Used by Get-SqlServiceName for service name resolution
        $mockGetChildItem = {
            return @(
                foreach($serviceType in $testServicesRegistryTable.Keys)
                {
                    New-Object -TypeName PSObject -Property @{
                        MockKeyName = $serviceType
                        MockName = $testServicesRegistryTable.$serviceType.Name
                        MockLName = $testServicesRegistryTable.$serviceType.LName
                        MockType = $testServicesRegistryTable.$serviceType.Type
                    } | Add-Member -MemberType ScriptMethod -Name 'GetValue' -Value {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Property
                        )

                        $propertyToReturn = "Mock$($Property)"
                        return $this.$propertyToReturn
                    } -PassThru
                }
            )
        }

        # Parameter filter for Get-ChildItem mock
        $mockGetChildItem_ParameterFilter = {
            $Path -eq $testServicesRegistryKey
        }

        # Splat to simplify creation of Mock for Get-ChildItem
        $mockGetChildItemParameters = @{
            CommandName = 'Get-ChildItem'
            MockWith = $mockGetChildItem
            ParameterFilter = $mockGetChildItem_ParameterFilter
            Verifiable = $true
        }

        Describe 'MSFT_SqlServerServiceAccount\ConvertTo-ManagedServiceType' -Tag 'Helper' {
            Context 'Translating service types' {
                $testCases = @(
                    @{
                        ServiceType  = 'DatabaseEngine'
                        ExpectedType = 'SqlServer'
                    }

                    @{
                        ServiceType  = 'SQLServerAgent'
                        ExpectedType = 'SqlAgent'
                    }

                    @{
                        ServiceType  = 'Search'
                        ExpectedType = 'Search'
                    }

                    @{
                        ServiceType  = 'IntegrationServices'
                        ExpectedType = 'SqlServerIntegrationService'
                    }

                    @{
                        ServiceType  = 'AnalysisServices'
                        ExpectedType = 'AnalysisServer'
                    }

                    @{
                        ServiceType  = 'ReportingServices'
                        ExpectedType = 'ReportServer'
                    }

                    @{
                        ServiceType  = 'SQLServerBrowser'
                        ExpectedType = 'SqlBrowser'
                    }

                    @{
                        ServiceType  = 'NotificationServices'
                        ExpectedType = 'NotificationServer'
                    }
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

                    $managedServiceType | Should -BeOfType Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType
                    $managedServiceType | Should -Be $ExpectedType
                }
            }
        }

        Describe 'MSFT_SqlServerServiceAccount\Get-SqlServiceName' -Tag 'Helper' {
            Mock @mockGetChildItemParameters

            Context 'When getting the service name for a default instance' {
                # Define cases for the various parameters to test
                $testCases = @(
                    @{
                        ServiceType = 'DatabaseEngine'
                        ExpectedServiceName = 'MSSQLSERVER'
                    },
                    @{
                        ServiceType = 'SQLServerAgent'
                        ExpectedServiceName = 'SQLSERVERAGENT'
                    },
                    @{
                        ServiceType = 'Search'
                        ExpectedServiceName = 'msftesql'
                    },
                    @{
                        ServiceType = 'IntegrationServices'
                        ExpectedServiceName = 'MsDtsServer'
                    },
                    @{
                        ServiceType = 'AnalysisServices'
                        ExpectedServiceName = 'MSSQLServerOLAPService'
                    },
                    @{
                        ServiceType = 'ReportingServices'
                        ExpectedServiceName = 'ReportServer'
                    },
                    @{
                        ServiceType = 'SQLServerBrowser'
                        ExpectedServiceName = 'SQLBrowser'
                    },
                    @{
                        ServiceType = 'NotificationServices'
                        ExpectedServiceName = 'NsService'
                    }
                )

                It 'Should return the correct service name for <ServiceType>' -TestCases $testCases {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $ServiceType,

                        [Parameter()]
                        [System.String]
                        $ExpectedServiceName
                    )

                    # Get the service name
                    Get-SqlServiceName -InstanceName $mockDefaultInstanceName -ServiceType $ServiceType | Should Be $ExpectedServiceName

                    # Ensure the mock is utilized
                    Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter $mockGetChildItem_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When getting the service name for a named instance' {
                BeforeAll {
                    # Define cases for the various parameters to test
                    $instanceAwareTestCases = @(
                        @{
                            ServiceType = 'DatabaseEngine'
                            ExpectedServiceName = ('MSSQL${0}' -f $mockNamedInstance)
                        },
                        @{
                            ServiceType = 'SQLServerAgent'
                            ExpectedServiceName = ('SQLAGENT${0}' -f $mockNamedInstance)
                        },
                        @{
                            ServiceType = 'Search'
                            ExpectedServiceName = ('MSFTESQL${0}' -f $mockNamedInstance)
                        },
                        @{
                            ServiceType = 'AnalysisServices'
                            ExpectedServiceName = ('MSOLAP${0}' -f $mockNamedInstance)
                        },
                        @{
                            ServiceType = 'ReportingServices'
                            ExpectedServiceName = ('ReportServer${0}' -f $mockNamedInstance)
                        },
                        @{
                            ServiceType = 'NotificationServices'
                            ExpectedServiceName = ('NS${0}' -f $mockNamedInstance)
                        }
                    )

                    $notInstanceAwareTestCases = @(
                        @{
                            ServiceType = 'IntegrationServices'
                            # ExpectedServiceName = ('{0}' -f $mockNamedInstance)
                        },
                        @{
                            ServiceType = 'SQLServerBrowser'
                            # ExpectedServiceName = ('{0}' -f $mockNamedInstance)
                        }
                    )
                }

                It 'Should return the correct service name for <ServiceType>' -TestCases $instanceAwareTestCases {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $ServiceType,

                        [Parameter()]
                        [System.String]
                        $ExpectedServiceName
                    )

                    # Get the service name
                    Get-SqlServiceName -InstanceName $mockNamedInstance -ServiceType $ServiceType | Should Be $ExpectedServiceName

                    # Ensure the mock is utilized
                    Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter $mockGetChildItem_ParameterFilter -Scope It -Exactly -Times 1
                }

                It 'Should thow an error for <ServiceType> which is not instance-aware' -TestCases $notInstanceAwareTestCases {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $ServiceType
                    )

                    # Get the localized error message
                    $testErrorMessage = $script:localizedData.NotInstanceAware -f $ServiceType

                    # An exception should be raised
                    { Get-SqlServiceName -InstanceName $mockNamedInstance -ServiceType $ServiceType } | Should Throw $testErrorMessage
                }
            }

            Context 'When getting the service name for a type that is not defined' {
                BeforeAll {
                    $mockGetChildItemParameters_NoServices = $mockGetChildItemParameters.Clone()
                    $mockGetChildItemParameters_NoServices.MockWith = { return @() }

                    # Mock the Get-ChildItem command
                    Mock @mockGetChildItemParameters_NoServices
                }

                It 'Should throw an exception if the service name cannot be derived' {
                    $testErrorMessage = $script:localizedData.UnknownServiceType -f 'DatabaseEngine'

                    { Get-SqlServiceName -InstanceName $mockNamedInstance -ServiceType DatabaseEngine } | Should Throw $testErrorMessage

                    # Ensure the mock was called
                    Assert-MockCalled -CommandName Get-ChildItem -Times 1 -Exactly -Scope It
                }
            }
        }

        Describe 'MSFT_SqlServerServiceAccount\Get-ServiceObject' -Tag 'Helper' {
            Mock -CommandName Import-SQLPSModule -Verifiable

            $defaultGetServiceObjectParameters = @{
                ServerName   = $mockSqlServer
                InstanceName = ''
                ServiceType  = $mockServiceType
            }

            Context 'When getting the service information for a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance

                It 'Should have the correct Type for the service' {
                    $getServiceObjectParameters = $defaultGetServiceObjectParameters.Clone()
                    $getServiceObjectParameters.InstanceName = $mockDefaultInstanceName

                    $serviceObject = Get-ServiceObject @getServiceObjectParameters
                    $serviceObject.Type | Should -Be 'SqlServer'

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -Scope It -Exactly -Times 1
                }
            }

            Context 'When getting the service information for a named instance' {
                Mock @mockNewObjectParameters_NamedInstance

                It 'Should have the correct Type for the service' {
                    $getServiceObjectParameters = $defaultGetServiceObjectParameters.Clone()
                    $getServiceObjectParameters.InstanceName = $mockNamedInstance

                    $serviceObject = Get-ServiceObject @getServiceObjectParameters
                    $serviceObject.Type | Should -Be 'SqlServer'

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -Scope It -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_SqlServerServiceAccount\Get-TargetResource' -Tag 'Get' {
            Mock -CommandName Import-SQLPSModule -Verifiable

            Context 'When getting the service information for a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance

                $defaultGetTargetResourceParameters = @{
                    ServerName     = $mockSqlServer
                    InstanceName   = $mockDefaultInstanceName
                    ServiceType    = $mockServiceType
                    ServiceAccount = $mockDefaultServiceAccountCredential
                }

                It 'Should return the correct service information' {
                    # Get the service information
                    $testServiceInformation = Get-TargetResource @defaultGetTargetResourceParameters

                    # Validate the hashtable returned
                    $testServiceInformation.ServerName | Should -Be $mockSqlServer
                    $testServiceInformation.InstanceName | Should -Be $mockDefaultInstanceName
                    $testServiceInformation.ServiceType | Should -Be 'SqlServer'
                    $testServiceInformation.ServiceAccount | Should -Be $mockDefaultServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }

                It 'Should throw the correct exception when an invalid ServiceType and InstanceName are specified' {
                    $getTargetResourceParameters = $defaultGetTargetResourceParameters.Clone()
                    $getTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    { Get-TargetResource @getTargetResourceParameters } |
                        Should -Throw "The SQLServerAgent service on $($mockSqlServer)\$($mockDefaultInstanceName) could not be found."

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When getting the service information for a named instance' {
                Mock @mockNewObjectParameters_NamedInstance

                # Splat the function parameters
                $defaultGetTargetResourceParameters = @{
                    ServerName     = $mockSqlServer
                    InstanceName   = $mockNamedInstance
                    ServiceType    = $mockServiceType
                    ServiceAccount = $mockServiceAccountCredential
                }

                It 'Should return the correct service information' {
                    # Get the service information
                    $testServiceInformation = Get-TargetResource @defaultGetTargetResourceParameters

                    # Validate the hashtable returned
                    $testServiceInformation.ServerName | Should -Be $mockSqlServer
                    $testServiceInformation.InstanceName | Should -Be $mockNamedInstance
                    $testServiceInformation.ServiceType | Should -Be 'SqlServer'
                    $testServiceInformation.ServiceAccount | Should -Be $mockDesiredServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }

                It 'Should throw the correct exception when an invalid ServiceType and InstanceName are specified' {
                    $getTargetResourceParameters = $defaultGetTargetResourceParameters.Clone()
                    $getTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    { Get-TargetResource @getTargetResourceParameters } |
                        Should -Throw "The SQLServerAgent service on $($mockSqlServer)\$($mockNamedInstance) could not be found."

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
                    ServerName     = $mockSqlServer
                    InstanceName   = $mockDefaultInstanceName
                    ServiceType    = $mockServiceType
                    ServiceAccount = $mockLocalServiceAccountCredential
                }

                It 'Should have the same domain name as the computer name' {
                    $currentState = Get-TargetResource @defaultGetTargetResourceParameters

                    # Validate the service account
                    $currentState.ServiceAccount | Should -Be $mockLocalServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_SqlServerServiceAccount\Test-TargetResource' -Tag 'Test' {
            Mock -CommandName Import-SQLPSModule -Verifiable

            Context 'When the system is not in the desired state for a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockDefaultInstanceName
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state or a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockDefaultInstanceName
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state and Force is specified' {
                Mock @mockNewObjectParameters_DefaultInstance

                It 'Should return False when Force is specified' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockDefaultInstanceName
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                        Force          = $true
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 0
                }
            }

            Context 'When the system is not in the desired state for a named instance' {
                Mock @mockNewObjectParameters_NamedInstance

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockNamedInstance
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state for a named instance' {
                Mock @mockNewObjectParameters_NamedInstance

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockNamedInstance
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state for a named instance and Force is specified' {
                Mock @mockNewObjectParameters_NamedInstance

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockNamedInstance
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                        Force          = $true
                    }

                    # Validate the return  value
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 0
                }
            }
        }

        Describe 'MSFT_SqlServerServiceAccount\Set-TargetResource' -Tag 'Set' {
            Mock -CommandName Import-SQLPSModule -Verifiable

            Context 'When changing the service account for the default instance' {
                BeforeAll {
                    $defaultSetTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockDefaultInstanceName
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Mock @mockNewObjectParameters_DefaultInstance

                    Mock -CommandName Restart-SqlService -Verifiable
                }

                BeforeEach {
                    $testServiceAccountUpdated.Processed = $false
                    $testServiceAccountUpdated.NewUserAccount = [System.String]::Empty
                    $testServiceAccountUpdated.NewPassword = [System.String]::Empty
                }

                It 'Should update the service account information' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                    # Update the service information
                    Set-TargetResource @setTargetResourceParameters

                    # Validate that the correct information was passed through and updated
                    $testServiceAccountUpdated.Processed | Should -Be $true
                    $testServiceAccountUpdated.NewUserAccount | Should -Be $setTargetResourceParameters.ServiceAccount.Username
                    $testServiceAccountUpdated.NewPassword | Should -Be $setTargetResourceParameters.ServiceAccount.GetNetworkCredential().Password

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }

                It 'Should throw the correct exception when an invalid service name and type is provided' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    # Get the localized error message
                    $mockCorrectErrorMessage = $script:localizedData.ServiceNotFound -f $setTargetResourceParameters.ServiceType, $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName

                    # Attempt to update the service account
                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockCorrectErrorMessage

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
                    $mockCorrectErrorMessage = $script:localizedData.SetServiceAccountFailed -f $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName, ''

                    # Attempt to update the service account
                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockCorrectErrorMessage

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }
            }

            Context 'When changing the service account for the default instance' {
                BeforeAll {
                    $defaultSetTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockNamedInstance
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Mock @mockNewObjectParameters_NamedInstance

                    Mock -CommandName Restart-SqlService -Verifiable
                }

                BeforeEach {
                    $testServiceAccountUpdated.Processed = $false
                    $testServiceAccountUpdated.NewUserAccount = [System.String]::Empty
                    $testServiceAccountUpdated.NewPassword = [System.String]::Empty
                }

                It 'Should update the service account information' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                    # Update the service information
                    Set-TargetResource @setTargetResourceParameters

                    # Validate that the correct information was passed through and updated
                    $testServiceAccountUpdated.Processed | Should -Be $true
                    $testServiceAccountUpdated.NewUserAccount | Should -Be $setTargetResourceParameters.ServiceAccount.Username
                    $testServiceAccountUpdated.NewPassword | Should -Be $setTargetResourceParameters.ServiceAccount.GetNetworkCredential().Password

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }

                It 'Should throw the correct exception when an invalid service name and type is provided' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    # Get the expected localized error message
                    $mockCorrectErrorMessage = $script:localizedData.ServiceNotFound -f $setTargetResourceParameters.ServiceType, $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName

                    # Attempt to update the service account
                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockCorrectErrorMessage

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
                    $mockCorrectErrorMessage = $script:localizedData.SetServiceAccountFailed -f $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName, ''

                    # Attempt to update the service information
                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockCorrectErrorMessage

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
