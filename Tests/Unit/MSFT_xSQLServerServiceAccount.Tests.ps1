
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

function Invoke-TestSetup {}

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
        $mockNamedInstance = 'Testnstance'
        $mockServiceAccountName = 'CONTOSO\sql.service'
        $mockServiceAccountCredential = (New-Object pscredential $mockServiceAccountName, (ConvertTo-SecureString -String 'P@ssword1' -AsPlainText -Force))
        $mockBadServiceAccountCredential = (New-Object PSCredential 'CONTOSO\sql.service2', (ConvertTo-SecureString -String 'P@ssword1' -AsPlainText -Force))

        $mockNewObject_ManagedComputer_DefaultInstance = {
            return @{
                Name = $mockSqlServer
                Services = @(
                    @{
                        Name = $mockDefaultInstanceName
                        ServiceAccount = $mockServiceAccountName
                        Type = 'SqlServer'
                    }
                )
            }
        }

        $mockNewObject_ManagedComputer_NamedInstance = {
            return @{
                Name = $mockSqlServer
                Services = @{
                    Name = ('MSSQL${0}' -f $mockNamedInstance)
                    ServiceAccount = $mockServiceAccountName
                    Type = 'SqlServer'
                }
            }
        }

        $mockNewObject_ParameterFilter = { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' }

        Describe 'MSFT_xSQLServerServiceAccount\Get-TargetResource' -Tag 'Get' {

            Context 'When getting the service information for a default instance' {

                $mockNewObjectParams = @{
                    CommandName = 'New-Object'
                    MockWith = $mockNewObject_ManagedComputer_DefaultInstance
                    ParameterFilter = $mockNewObject_ParameterFilter
                    Verifiable = $true
                }

                Mock @mockNewObjectParams

                It 'Should return the correct service information' {
                    $testServiceType = 'SqlServer'

                    # Splat the function parameters
                    $getTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = $testServiceType
                    }

                    # Get the service information
                    $testServiceInformation = Get-TargetResource @getTargetResourceParams

                    # Validate the hashtable returned
                    $testServiceInformation.SQLServer | Should Be $mockSqlServer
                    $testServiceInformation.SQLInstanceName | Should Be $mockDefaultInstanceName
                    $testServiceInformation.ServiceType | Should Be $testServiceType
                    $testServiceInformation.ServiceAccount | Should Be $mockServiceAccountName
                }

                It 'Should throw an exception when an invalid ServiceType and InstanceName are specified' {
                    { Get-TargetResource -SQLServer $mockSqlServer -SQLInstanceName $mockDefaultInstanceName -ServiceType SqlAgent } |
                        Should Throw "The SqlAgent service on $($mockSqlServer)\$($mockDefaultInstanceName) could not be found."
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks

                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 2
                }
            }

            Context 'When getting the service information for a named instance' {

                $mockNewObjectParams = @{
                    CommandName = 'New-Object'
                    MockWith = $mockNewObject_ManagedComputer_NamedInstance
                    ParameterFilter = $mockNewObject_ParameterFilter
                    Verifiable = $true
                }

                Mock @mockNewObjectParams

                It 'Should return the correct service information' {
                    $testServiceType = 'SqlServer'

                    # Splat the function parameters
                    $getTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockNamedInstance
                        ServiceType = $testServiceType
                    }

                    # Get the service information
                    $testServiceInformation = Get-TargetResource @getTargetResourceParams

                    # Validate the hashtable returned
                    $testServiceInformation.SQLServer | Should Be $mockSqlServer
                    $testServiceInformation.SQLInstanceName | Should Be $mockNamedInstance
                    $testServiceInformation.ServiceType | Should Be $testServiceType
                    $testServiceInformation.ServiceAccount | Should Be $mockServiceAccountName
                }

                It 'Should throw an exception when an invalid ServiceType and InstanceName are specified' {
                    { Get-TargetResource -SQLServer $mockSqlServer -SQLInstanceName $mockNamedInstance -ServiceType SqlAgent } |
                        Should Throw "The SqlAgent service on $($mockSqlServer)\$($mockNamedInstance) could not be found."
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks

                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 2
                }
            }
        }

        Describe 'MSFT_xSQLServerServiceAccount\Test-TargetResource' -Tag 'Test' {

            $mockNewObjectParams = @{
                CommandName = 'New-Object'
                MockWith = $mockNewObject_ManagedComputer_DefaultInstance
                ParameterFilter = $mockNewObject_ParameterFilter
                Verifiable = $true
            }

            Mock @mockNewObjectParams

            Context 'When the system is not in the desired state' {
                It 'Should return false' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = 'SqlServer'
                        ServiceAccount = $mockBadServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParams | Should Be $false
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return true' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = 'SqlServer'
                        ServiceAccount = $mockServiceAccountCredential
                    }

                    Test-TargetResource @testTargetResourceParams | Should Be $true
                }

                It 'Should use all mocked commands' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName New-Object -ParameterFilter $mockNewObject_ParameterFilter -Exactly -Times 1
                }
            }

            Context 'When the system is in the desired state and Force is specified' {
                It 'Should return false' {
                    $testTargetResourceParams = @{
                        SQLServer = $mockSqlServer
                        SQLInstanceName = $mockDefaultInstanceName
                        ServiceType = 'SqlServer'
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
    }
}
finally
{
    Invoke-TestCleanup
}
