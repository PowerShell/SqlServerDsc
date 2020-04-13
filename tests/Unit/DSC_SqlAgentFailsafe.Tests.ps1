<#
    .SYNOPSIS
        Automated unit test for DSC_SqlAgentFailsafe DSC resource.

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
$script:dscResourceName = 'DSC_SqlAgentFailsafe'

function Invoke-TestSetup
{
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
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockSqlAgentFailsafeName = 'FailsafeOp'
        $mockSqlAgentFailsafeNotification = 'NotifyEmail'
        $mockInvalidOperationForAlterMethod = $false

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
        }

        #region Function mocks
        $mockConnectSQL = {
            return @(
                (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
                    Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
                    Add-Member -MemberType ScriptProperty -Name JobServer -Value {
                        return (New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name Name -Value $mockServerName -PassThru |
                            Add-Member -MemberType ScriptProperty -Name AlertSystem -Value {
                                return ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name FailSafeOperator -Value $mockSqlAgentFailsafeName -PassThru -Force |
                                    Add-Member -MemberType NoteProperty -Name NotificationMethod -Value $mockSqlAgentFailsafeNotification -PassThru -Force |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                        if ($mockInvalidOperationForAlterMethod)
                                        {
                                            throw 'Mock Alter Method was called with invalid operation.'
                                        }
                                    } -PassThru -Force
                                )
                            } -PassThru
                        )
                    } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "DSC_SqlAgentFailsafe\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When Connect-SQL returns nothing' {
                It 'Should throw the correct error' {
                    Mock -CommandName Connect-SQL -MockWith {
                        return $null
                    }

                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name   = 'FailsafeOp'
                    }

                    { Get-TargetResource @testParameters } | Should -Throw ($script:localizedData.ConnectServerFailed -f $testParameters.ServerName, $testParameters.InstanceName)
                }
            }

            Context 'When the system is not in the desired state' {
                $testParameters = $mockDefaultParameters

                $testParameters += @{
                    Name         = 'DifferentOp'
                }

                It 'Should return the state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is in the desired state for a sql agent failsafe operator' {
                $testParameters = $mockDefaultParameters

                $testParameters += @{
                    Name         = 'FailsafeOp'
                }

                It 'Should return the state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.NotificationMethod | Should -Be $mockSqlAgentFailsafeNotification
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }
            Assert-VerifiableMock
        }

        Describe "DSC_SqlAgentFailsafe\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when desired sql agent failsafe operator does not exist' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name                = 'MissingFailsafe'
                        NotificationMethod  = 'NotifyEmail'
                        Ensure              = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should return the state as false when desired sql agent failsafe operator exists but has the incorrect notification method' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name               = 'FailsafeOp'
                        Ensure             = 'Present'
                        NotificationMethod = 'Pager'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should return the state as false when non-desired sql agent failsafe operator exists' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name   = 'FailsafeOp'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Present' {
                It 'Should return the state as true when desired sql agent failsafe operator exist' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name      = 'FailsafeOp'
                        Ensure    = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should return the state as true when desired sql agent failsafe operator exists and has the correct notification method' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name               = 'FailsafeOp'
                        Ensure             = 'Present'
                        NotificationMethod = 'NotifyEmail'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                It 'Should return the state as true when desired sql agent failsafe operator does not exist' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name   = 'NotFailsafe'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }
            Assert-VerifiableMock
        }

        Describe "DSC_SqlAgentFailsafe\Set-TargetResource" -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When Connect-SQL returns nothing' {
                It 'Should throw the correct error' {
                    Mock -CommandName Get-TargetResource -Verifiable
                    Mock -CommandName Connect-SQL -MockWith {
                        return $null
                    }

                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name   = 'FailsafeOp'
                        Ensure = 'Present'
                    }

                    { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.ConnectServerFailed -f $testParameters.ServerName, $testParameters.InstanceName)
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Present'{
                It 'Should not throw when adding the sql agent failsafe operator' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name   = 'Newfailsafe'
                        Ensure = 'Present'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should not throw when changing the severity'  {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name                = 'Newfailsafe'
                        Ensure              = 'Present'
                        NotificationMethod  = 'Pager'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should throw when notification method is not valid' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name                = 'Newfailsafe'
                        Ensure              = 'Present'
                        NotificationMethod  = 'Letter'
                    }

                    { Set-TargetResource @testParameters } | Should -Throw
                }

                $mockInvalidOperationForAlterMethod = $true
                It 'Should throw the correct error when Alter() method was called with invalid operation' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name   = 'NewFailsafe'
                        Ensure = 'Present'
                    }

                    $errorMessage = ($script:localizedData.UpdateFailsafeOperatorError -f $testParameters.Name, $testParameters.ServerName, $testParameters.InstanceName)
                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 3 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should not throw when removing the sql agent failsafe operator' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name   = 'FailsafeOp'
                        Ensure = 'Absent'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                $mockInvalidOperationForAlterMethod = $true
                It 'Should throw the correct error when Alter() method was called with invalid operation' {
                    $testParameters = $mockDefaultParameters

                    $testParameters += @{
                        Name   = 'FailsafeOp'
                        Ensure = 'Absent'
                    }

                    $errorMessage = ($script:localizedData.UpdateFailsafeOperatorError -f $testParameters.Name, $testParameters.ServerName, $testParameters.InstanceName)
                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }
            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}
