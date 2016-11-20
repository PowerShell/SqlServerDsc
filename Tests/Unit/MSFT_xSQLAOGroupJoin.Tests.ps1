# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLAOGroupJoin'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockSQLServerName = 'localhost'
        $mockSQLServerInstanceName = 'TEST'
        
        $mockUnknonwAvailabilityGroupName = 'UnkownGroup'

        $mockAvailabilityGroupName = 'TestGroup'
        $mockAvailabilityGroupListenerName = 'ListnerName'
        $mockAvailabilityGroupListenerPortNumber = 5022
        $mockAvailabilityGroupListenerIPAddress = '192.168.0.1'
        $mockAvailabilityGroupListenerSubnetMask = '255.255.255.0'
        $mockAvailabilityDatabasesName = 'MyDatabase'

        $mockmockSetupCredentialUserName = "COMPANY\sqladmin" 
        $mockmockSetupCredentialPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $mockSetupCredential = New-Object System.Management.Automation.PSCredential( $mockmockSetupCredentialUserName, $mockmockSetupCredentialPassword )

        #region Function mocks

        $mockConnectSQL = {
            return @(
                (
                    New-Object Object | 
                        Add-Member NoteProperty -Name AvailabilityGroups -Value @{
                            "$mockAvailabilityGroupName" = @(
                                New-Object Object | 
                                    Add-Member NoteProperty -Name 'Name' -Value $mockAvailabilityGroupName -PassThru |
                                    Add-Member ScriptProperty AvailabilityGroupListeners {
                                        return @( ( New-Object Object |
                                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityGroupListenerName -PassThru | 
                                            Add-Member -MemberType NoteProperty -Name 'PortNumber' -Value $mockAvailabilityGroupListenerPortNumber -PassThru | 
                                            Add-Member ScriptProperty AvailabilityGroupListenerIPAddresses {
                                                return @( ( New-Object Object |
                                                        Add-Member -MemberType NoteProperty -Name 'IPAddress' -Value $mockAvailabilityGroupListenerIPAddress -PassThru | 
                                                        Add-Member -MemberType NoteProperty -Name 'SubnetMask' -Value $mockAvailabilityGroupListenerSubnetMask -PassThru -Force 
                                                    ) )
                                            } -PassThru -Force
                                        ) )
                                    } -PassThru |
                                    Add-Member ScriptProperty AvailabilityDatabases {
                                        return @( ( New-Object Object |
                                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAvailabilityDatabasesName -PassThru -Force
                                        ) )
                                    } -PassThru -Force
                            )
                        } -PassThru |
                        Add-Member ScriptMethod JoinAvailabilityGroup {
                            param
                            (
                                [Parameter()]
                                [String]
                                $AvailabilityGroupName
                            )

                            if( $AvailabilityGroupName -eq $mockUnknonwAvailabilityGroupName )
                            {
                                throw 'Mock of method JoinAvailabilityGroup() throw error'
                            }
                            
                            return
                        } -PassThru -Force
                )
            )
        }

        #endregion Function mocks
       
        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            SQLServer = $mockSQLServerName
            SQLInstanceName = $mockSQLServerInstanceName
            SetupCredential = $mockSetupCredential
        }

        Describe 'MSFT_xSQLAOGroupJoin\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                # General mocks
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context "When the system is not in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        AvailabilityGroupName = $mockUnknonwAvailabilityGroupName
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                }

                It 'Should return the correct values in the hash table' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Absent'
                    $result.AvailabilityGroupName | Should BeNullOrEmpty
                    $result.AvailabilityGroupNameListener | Should BeNullOrEmpty
                    $result.AvailabilityGroupNameIP | Should BeNullOrEmpty
                    $result.AvailabilityGroupSubMask | Should BeNullOrEmpty
                    $result.AvailabilityGroupPort | Should BeNullOrEmpty
                    $result.AvailabilityGroupNameDatabase | Should BeNullOrEmpty
                }
            }

            Context "When the system is in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        AvailabilityGroupName = $mockAvailabilityGroupName
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                }

                It 'Should return the correct values in the hash table' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
                    $result.AvailabilityGroupName | Should Be $mockAvailabilityGroupName
                    $result.AvailabilityGroupNameListener | Should Be $mockAvailabilityGroupListenerName
                    $result.AvailabilityGroupNameIP | Should Be $mockAvailabilityGroupListenerIPAddress
                    $result.AvailabilityGroupSubMask | Should Be $mockAvailabilityGroupListenerSubnetMask
                    $result.AvailabilityGroupPort | Should Be $mockAvailabilityGroupListenerPortNumber
                    $result.AvailabilityGroupNameDatabase | Should Be $mockAvailabilityDatabasesName
                }
            }

            Assert-VerifiableMocks
        }
        
        Describe 'MSFT_xSQLAOGroupJoin\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                # General mocks
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context "When the system is not in the desired state and Availability Group should be present" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        AvailabilityGroupName = $mockUnknonwAvailabilityGroupName
                    }
                }

                It 'Should return the state as absent ($false)' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context "When the system is not in the desired state and Availability Group should be absent" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Absent'
                        AvailabilityGroupName = $mockAvailabilityGroupName
                    }
                }

                It 'Should return the state as absent ($false)' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context "When the system is in the desired state with Availibilty Group already present" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        AvailabilityGroupName = $mockAvailabilityGroupName
                    }
                }

                It 'Should return the state as present ($true)' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context "When the system is in the desired state with Availibilty Group already absent" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Absent'
                        AvailabilityGroupName = $mockUnknonwAvailabilityGroupName
                    }
                }

                It 'Should return the state as present ($true)' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
           
            Assert-VerifiableMocks
        }

        Describe 'MSFT_xSQLAOGroupJoin\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                # General mocks
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Initialize-SqlServerAssemblies -MockWith {} -Verifiable
                Mock -CommandName Grant-ServerPerms -MockWith {} -Verifiable
            }

            Context "When the system is not in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure = 'Present'
                        AvailabilityGroupName = $mockAvailabilityGroupName
                    }
                }

                It 'Should not throw when joining mocked availability group' {
                    { Set-TargetResource @testParameters } | Should Not Throw
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Initialize-SqlServerAssemblies -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Grant-ServerPerms -Exactly -Times 1 -Scope It
                }

                It 'Should throw with the right error message when failing to join mocked availability group' {
                    $testParameters.AvailabilityGroupName = $mockUnknonwAvailabilityGroupName
                    { Set-TargetResource @testParameters } | Should Throw "Unable to Join $mockUnknonwAvailabilityGroupName on localhost\TEST"
                    
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Initialize-SqlServerAssemblies -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Grant-ServerPerms -Exactly -Times 1 -Scope It
                }
            }
            
            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}
