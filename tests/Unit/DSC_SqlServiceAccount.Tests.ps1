<#
    .SYNOPSIS
        Automated unit test for DSC_SqlServiceAccount DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlServiceAccount'

function Invoke-TestSetup
{
    $script:timer = [System.Diagnostics.Stopwatch]::StartNew()

    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Write-Verbose -Message ('Test {1} run for {0} minutes' -f ([System.TimeSpan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString('mm\:ss'), $script:dscResourceName) -Verbose
    $script:timer.Stop()
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {

        $mockSqlServer = 'TestServer'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockNamedInstance = 'TestInstance'
        $mockServiceType = 'DatabaseEngine'
        $mockDesiredServiceAccountName = 'CONTOSO\sql.service'
        $mockServiceAccountCredential = (New-Object -TypeName System.Management.Automation.PSCredential $mockDesiredServiceAccountName, (New-Object -TypeName System.Security.SecureString))
        $mockDefaultServiceAccountName = 'NT SERVICE\MSSQLSERVER'
        $mockDefaultServiceAccountCredential = (New-Object -TypeName System.Management.Automation.PSCredential $mockDefaultServiceAccountName, (New-Object -TypeName System.Security.SecureString))
        $mockLocalServiceAccountName = '$($mockSqlServer)\SqlService'
        $mockLocalServiceAccountCredential = (New-Object -TypeName System.Management.Automation.PSCredential $mockLocalServiceAccountName, (New-Object -TypeName System.Security.SecureString))
        $mockManagedServiceAccountName = 'CONTOSO\sqlservice$'
        $mockManagedServiceAccountCredential = (New-Object -TypeName System.Management.Automation.PSCredential $mockManagedServiceAccountName, (New-Object -TypeName System.Security.SecureString))
        $mockIntegrationServicesObject = @{Name = 'MsDtsServer130'}

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

        $mockGetServiceObject_DefaultInstance = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                        Name           = $mockDefaultInstanceName
                        ServiceAccount = $mockDefaultServiceAccountName
                        Type           = 'SqlServer'
                    }

            $managedComputerObject | Add-Member @mockAddMemberParameters_SetServiceAccount

            return $managedComputerObject
        }

        $mockGetServiceObject_DefaultInstance_SetServiceAccount_ThrowException = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                        Name           = $mockDefaultInstanceName
                        ServiceAccount = $mockDefaultServiceAccountName
                        Type           = 'SqlServer'
                    }

            $managedComputerObject | Add-Member @mockAddMemberParameters_SetServiceAccount_Exception

            return $managedComputerObject
        }

        $mockGetServiceObject_DefaultInstance_LocalServiceAccount = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                        Name           = $mockDefaultInstanceName
                        ServiceAccount = ($mockLocalServiceAccountName -replace $mockSqlServer, '.')
                        Type           = 'SqlServer'
                    }

            $managedComputerObject | Add-Member @mockAddMemberParameters_SetServiceAccount

            return $managedComputerObject
        }

        $mockGetServiceObject_DefaultInstance_ManagedServiceAccount = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                Name           = $mockDefaultInstanceName
                ServiceAccount = $mockManagedServiceAccountName
                Type           = 'SqlServer'
            }

            $managedComputerObject | Add-Member @mockAddMemberParameters_SetServiceAccount

            return $managedComputerObject
        }

        $mockGetServiceObject_NamedInstance = {
            $managedComputerObject = New-Object -TypeName PSObject -Property @{
                        Name           = ('MSSQL${0}' -f $mockNamedInstance)
                        ServiceAccount = $mockDesiredServiceAccountName
                        Type           = 'SqlServer'
                    }

            $managedComputerObject | Add-Member @mockAddMemberParameters_SetServiceAccount

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

        Describe 'DSC_SqlServerServiceAccount\ConvertTo-ManagedServiceType' -Tag 'Helper' {
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

        Describe 'DSC_SqlServerServiceAccount\ConvertTo-ResourceServiceType' -Tag 'Helper' {
            Context 'Translating service types' {
                $testCases = @(
                    @{
                        ServiceType  = 'SqlServer'
                        ExpectedType = 'DatabaseEngine'
                    }

                    @{
                        ServiceType  = 'SqlAgent'
                        ExpectedType = 'SQLServerAgent'
                    }

                    @{
                        ServiceType  = 'Search'
                        ExpectedType = 'Search'
                    }

                    @{
                        ServiceType  = 'SqlServerIntegrationService'
                        ExpectedType = 'IntegrationServices'
                    }

                    @{
                        ServiceType  = 'AnalysisServer'
                        ExpectedType = 'AnalysisServices'
                    }

                    @{
                        ServiceType  = 'ReportServer'
                        ExpectedType = 'ReportingServices'
                    }

                    @{
                        ServiceType  = 'SqlBrowser'
                        ExpectedType = 'SQLServerBrowser'
                    }

                    @{
                        ServiceType  = 'NotificationServer'
                        ExpectedType = 'NotificationServices'
                    }

                    @{
                        ServiceType  = 'UnknownTypeShouldReturnTheSame'
                        ExpectedType = 'UnknownTypeShouldReturnTheSame'
                    }
                )

                It 'Should properly map <ServiceType> to resource type <ExpectedType>' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $ServiceType,

                        [System.String]
                        $ExpectedType
                    )

                    # Get the ManagedServiceType
                    $managedServiceType = ConvertTo-ResourceServiceType -ServiceType $ServiceType

                    $managedServiceType | Should -BeOfType [System.String]
                    $managedServiceType | Should -Be $ExpectedType
                }
            }
        }

        Describe 'DSC_SqlServerServiceAccount\Get-SqlServiceName' -Tag 'Helper' {
            BeforeAll {
                Mock @mockGetChildItemParameters
            }

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
                    Get-SqlServiceName -InstanceName $mockDefaultInstanceName -ServiceType $ServiceType  | Should -Be $ExpectedServiceName

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
                        },
                        @{
                            ServiceType = 'SQLServerBrowser'
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
                    Get-SqlServiceName -InstanceName $mockNamedInstance -ServiceType $ServiceType | Should -Be $ExpectedServiceName

                    # Ensure the mock is utilized
                    Assert-MockCalled -CommandName Get-ChildItem -ParameterFilter $mockGetChildItem_ParameterFilter -Scope It -Exactly -Times 1
                }

                It 'Should throw an error for <ServiceType> which is not instance-aware' -TestCases $notInstanceAwareTestCases {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $ServiceType
                    )

                    # Get the localized error message
                    $testErrorMessage = $script:localizedData.NotInstanceAware -f $ServiceType

                    # An exception should be raised
                    { Get-SqlServiceName -InstanceName $mockNamedInstance -ServiceType $ServiceType } | Should -Throw $testErrorMessage
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

                    { Get-SqlServiceName -InstanceName $mockNamedInstance -ServiceType DatabaseEngine } | Should -Throw $testErrorMessage

                    # Ensure the mock was called
                    Assert-MockCalled -CommandName Get-ChildItem -Times 1 -Exactly -Scope It
                }
            }
        }

        Describe 'DSC_SqlServerServiceAccount\Get-ServiceObject' -Tag 'Helper' {
            BeforeAll {
                Mock -CommandName Import-SQLPSModule -Verifiable
            }

            $defaultGetServiceObjectParameters = @{
                ServerName   = $mockSqlServer
                InstanceName = ''
                ServiceType  = $mockServiceType
            }

            Context 'When getting the service information for a default instance' {
                Mock @mockNewObjectParameters_DefaultInstance
                Mock -CommandName Get-SqlServiceName -MockWith {
                    return 'MSSQLServer'
                }

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
                Mock -CommandName Get-SqlServiceName -MockWith {
                    return ('MSSQL${0}' -f $mockNamedInstance)
                }

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

            Context 'When getting service IntegrationServices' {
                Mock @mockNewObjectParameters_DefaultInstance
                Mock -CommandName Get-SqlServiceName -MockWith {
                    return 'MsDtsServer'
                }
                Mock -CommandName New-Object -MockWith {
                    return @{
                        Services = $mockIntegrationServicesObject
                    }
                }
                It 'Should throw an exception when VersionNumber is not specified'{
                    $getServiceObjectParameters = $defaultGetServiceObjectParameters.Clone()
                    $getServiceObjectParameters.ServiceType = 'IntegrationServices'
                    $getServiceObjectParameters.InstanceName = 'MSSQLSERVER'

                    $testErrorMessage = $script:localizedData.MissingParameter -f 'IntegrationServices'

                    {Get-ServiceObject @getServiceObjectParameters} | Should -Throw $testErrorMessage
                }

                It 'Should return service when VersionNumber is specified'{
                    $getServiceObjectParameters = $defaultGetServiceObjectParameters.Clone()
                    $getServiceObjectParameters.ServiceType = 'IntegrationServices'
                    $getServiceObjectParameters.InstanceName = 'MSSQLSERVER'
                    $getServiceObjectParameters.VersionNumber = '130'

                    Get-ServiceObject @getServiceObjectParameters | Should -Be $mockIntegrationServicesObject
                }
            }
        }

        Describe 'DSC_SqlServerServiceAccount\Get-TargetResource' -Tag 'Get' {
            Context 'When getting the service information for a default instance' {
                BeforeAll {
                    Mock -CommandName Get-ServiceObject -MockWith $mockGetServiceObject_DefaultInstance -ParameterFilter {
                        $ServiceType -eq 'DatabaseEngine'
                    }

                    Mock -CommandName Get-ServiceObject -MockWith {
                        return $null
                    } -ParameterFilter {
                        $ServiceType -eq 'SQLServerAgent'
                    }
                }

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
                    $testServiceInformation.ServiceType | Should -Be 'DatabaseEngine'
                    $testServiceInformation.ServiceAccountName | Should -Be $mockDefaultServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                }

                It 'Should throw the correct exception when an invalid ServiceType and InstanceName are specified' {
                    $getTargetResourceParameters = $defaultGetTargetResourceParameters.Clone()
                    $getTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    { Get-TargetResource @getTargetResourceParameters } |
                        Should -Throw "The SQLServerAgent service on $($mockSqlServer)\$($mockDefaultInstanceName) could not be found."

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                }
            }

            Context 'When getting the service information for a named instance' {
                BeforeAll {
                    Mock -CommandName Get-ServiceObject -MockWith $mockGetServiceObject_NamedInstance -ParameterFilter {
                        $ServiceType -eq 'DatabaseEngine'
                    }

                    Mock -CommandName Get-ServiceObject -MockWith {
                        return $null
                    } -ParameterFilter {
                        $ServiceType -eq 'SQLServerAgent'
                    }
                }

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
                    $testServiceInformation.ServiceType | Should -Be 'DatabaseEngine'
                    $testServiceInformation.ServiceAccountName | Should -Be $mockDesiredServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                }

                It 'Should throw the correct exception when an invalid ServiceType and InstanceName are specified' {
                    $getTargetResourceParameters = $defaultGetTargetResourceParameters.Clone()
                    $getTargetResourceParameters.ServiceType = 'SQLServerAgent'

                    { Get-TargetResource @getTargetResourceParameters } |
                        Should -Throw "The SQLServerAgent service on $($mockSqlServer)\$($mockNamedInstance) could not be found."

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                }
            }

            Context 'When the service account is local to the machine' {
                BeforeAll {
                    Mock -CommandName Get-ServiceObject -MockWith $mockGetServiceObject_DefaultInstance_LocalServiceAccount
                }

                $defaultGetTargetResourceParameters = @{
                    ServerName     = $mockSqlServer
                    InstanceName   = $mockDefaultInstanceName
                    ServiceType    = $mockServiceType
                    ServiceAccount = $mockLocalServiceAccountCredential
                }

                It 'Should have the same domain name as the computer name' {
                    $currentState = Get-TargetResource @defaultGetTargetResourceParameters

                    # Validate the service account
                    $currentState.ServiceAccountName | Should -Be $mockLocalServiceAccountName

                    # Ensure mocks were properly used
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                }
            }

            Context 'When the service account is a Managed Service Account' {
                BeforeAll {
                    Mock -CommandName Get-ServiceObject -MockWith $mockGetServiceObject_DefaultInstance_ManagedServiceAccount
                }

                $defaultGetTargetResourceParameters = @{
                    ServerName     = $mockSqlServer
                    InstanceName   = $mockDefaultInstanceName
                    ServiceType    = $mockServiceType
                    ServiceAccount = $mockManagedServiceAccountCredential
                }

                It 'Should have the Managed Service Account' {
                    $currentState = Get-TargetResource @defaultGetTargetResourceParameters

                    # Validate the managed service account
                    $currentState.ServiceAccountName | Should -Be $mockManagedServiceAccountName

                    # Ensure the mocks were properly used
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_SqlServerServiceAccount\Test-TargetResource' -Tag 'Test' {
            Context 'When the system is not in the desired state for a default instance' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName         = $ServerName
                        InstanceName       = $mockDefaultInstanceName
                        ServiceType        = 'SqlServer'
                        ServiceAccountName = 'NotExpectedAccount'
                    }
                }

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockDefaultInstanceName
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Get-TargetResource -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state or a default instance' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName         = $ServerName
                        InstanceName       = $mockDefaultInstanceName
                        ServiceType        = 'SqlServer'
                        ServiceAccountName = $mockDefaultServiceAccountName
                    }
                }

                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockDefaultInstanceName
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Get-TargetResource -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state and Force is specified' {
                It 'Should always return $false when Force is specified' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockDefaultInstanceName
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                        Force          = $true
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }
            }

            Context 'When the system is not in the desired state for a named instance' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName         = $ServerName
                        InstanceName       = $mockNamedInstance
                        ServiceType        = 'SqlServer'
                        ServiceAccountName = 'NotExpectedAccount'
                    }
                }

                It 'Should return false' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockNamedInstance
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Get-TargetResource -Scope It -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state for a named instance' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName         = $ServerName
                        InstanceName       = $mockNamedInstance
                        ServiceType        = 'SqlServer'
                        ServiceAccountName = $mockDesiredServiceAccountName
                    }
                }
                It 'Should return true' {
                    $testTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockNamedInstance
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    # Ensure mocks are properly used
                    Assert-MockCalled -CommandName Get-TargetResource -Scope It -Exactly -Times 1
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

        Describe 'DSC_SqlServerServiceAccount\Set-TargetResource' -Tag 'Set' {
            Context 'When changing the service account for the default instance' {
                BeforeAll {
                    $defaultSetTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockDefaultInstanceName
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Mock -CommandName Get-ServiceObject -MockWith $mockGetServiceObject_DefaultInstance -ParameterFilter {
                        $ServiceType -eq 'DatabaseEngine'
                    }

                    Mock -CommandName Get-ServiceObject -MockWith {
                        return $null
                    } -ParameterFilter {
                        $ServiceType -eq 'SQLServerAgent'
                    }

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
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
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
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }

                It 'Should restart the service if requested' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters += @{
                        RestartService = $true
                    }

                    Set-TargetResource @setTargetResourceParameters

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 1
                }
            }

            Context 'When changing the service account for the named instance' {
                BeforeAll {
                    $defaultSetTargetResourceParameters = @{
                        ServerName     = $mockSqlServer
                        InstanceName   = $mockNamedInstance
                        ServiceType    = $mockServiceType
                        ServiceAccount = $mockDefaultServiceAccountCredential
                    }

                    Mock -CommandName Get-ServiceObject -MockWith $mockGetServiceObject_DefaultInstance -ParameterFilter {
                        $ServiceType -eq 'DatabaseEngine'
                    }

                    Mock -CommandName Get-ServiceObject -MockWith {
                        return $null
                    } -ParameterFilter {
                        $ServiceType -eq 'SQLServerAgent'
                    }

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
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
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
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 0
                }

                It 'Should restart the service if requested' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                    $setTargetResourceParameters += @{
                        RestartService = $true
                    }

                    Set-TargetResource @setTargetResourceParameters

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                    Assert-MockCalled -CommandName Restart-SqlService -Scope It -Exactly -Times 1
                }
            }

            Context 'When SetServiceAccount() method call fails' {
                BeforeEach {
                    Mock -CommandName Get-ServiceObject -MockWith $mockGetServiceObject_DefaultInstance_SetServiceAccount_ThrowException
                }

                It 'Should throw the correct exception' {
                    $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                    # Get the localized error message
                    $mockCorrectErrorMessage = $script:localizedData.SetServiceAccountFailed -f $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName, ''

                    # Attempt to update the service account
                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockCorrectErrorMessage

                    # Ensure mocks are used properly
                    Assert-MockCalled -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
