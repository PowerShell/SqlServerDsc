<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlScript DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

# Suppression of this PSSA rule allowed in tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlScript'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SqlPowerShellSqlExecutionException.cs')
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
        Describe 'MSFT_SqlScript\Get-TargetResource' {
            BeforeAll {
                $testParameters = @{
                    ServerInstance = $env:COMPUTERNAME
                    SetFilePath    = "set.sql"
                    GetFilePath    = "get.sql"
                    TestFilePath   = "test.sql"
                }

                $testParametersTimeout = @{
                    ServerInstance = $env:COMPUTERNAME
                    SetFilePath    = "set-timeout.sql"
                    GetFilePath    = "get-timeout.sql"
                    TestFilePath   = "test-timeout.sql"
                    QueryTimeout   = 30
                }
            }

            Context 'When Get-TargetResource returns script results successfully' {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Get-TargetResource @testParameters

                    $result.ServerInstance | Should -Be $testParameters.ServerInstance
                    $result.SetFilePath | Should -Be $testParameters.SetFilePath
                    $result.GetFilePath | Should -Be $testParameters.GetFilePath
                    $result.TestFilePath | Should -Be $testParameters.TestFilePath
                    $result | Should -BeOfType [System.Collections.Hashtable]
                }
            }

            Context 'When Get-TargetResource returns script results successfully with query timeout' {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Get-TargetResource @testParametersTimeout
                    $result.ServerInstance | Should -Be $testParametersTimeout.ServerInstance
                    $result.SetFilePath | Should -Be $testParametersTimeout.SetFilePath
                    $result.GetFilePath | Should -Be $testParametersTimeout.GetFilePath
                    $result.TestFilePath | Should -Be $testParametersTimeout.TestFilePath
                    $result | Should -BeOfType [System.Collections.Hashtable]
                }
            }

            Context 'When Get-TargetResource throws an error when running the script in the GetFilePath parameter' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Invoke-SqlScript -MockWith {
                    throw $errorMessage
                }

                It 'Should throw the correct error from Invoke-Sqlcmd' {
                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }
            }
        }

        Describe 'MSFT_SqlScript\Set-TargetResource' {
            Context 'When Set-TargetResource runs script without issue' {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Set-TargetResource @testParameters
                    $result | Should -Be ''
                }
            }

            Context 'When Set-TargetResource runs script without issue using timeout' {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Set-TargetResource @testParametersTimeout
                    $result | Should -Be ''
                }
            }

            Context 'When Set-TargetResource throws an error when running the script in the SetFilePath parameter' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Invoke-SqlScript -MockWith {
                    throw $errorMessage
                }

                It 'Should throw the correct error from Invoke-Sqlcmd' {
                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }
            }
        }

        Describe 'MSFT_SqlScript\Test-TargetResource' {
            Context 'When the system is in the desired state' {
                Context 'When Test-TargetResource runs script without issue' {
                    Mock -CommandName Invoke-SqlScript

                    It 'Should return true' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $true
                    }
                }

                Context 'When Test-TargetResource runs script without issue with timeout' {
                    Mock -CommandName Invoke-SqlScript

                    It 'Should return true' {
                        $result = Test-TargetResource @testParametersTimeout
                        $result | Should -Be $true
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When Invoke-SqlScript returns an SQL error code from the script that was ran' {
                    Mock -CommandName Invoke-SqlScript -MockWith {
                        return 1
                    }

                    It 'Should return false' {
                        $result = Test-TargetResource @testParametersTimeout
                        $result | Should -Be $false
                    }
                }

                Context 'When Test-TargetResource throws the exception SqlPowerShellSqlExecutionException when running the script in the TestFilePath parameter' {
                    Mock -CommandName Invoke-SqlScript -MockWith {
                        throw New-Object -TypeName Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException
                    }

                    It 'Should return false' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $false
                    }
                }

                Context 'When Test-TargetResource throws an unexpected error when running the script in the TestFilePath parameter' {
                    $errorMessage = "Failed to run SQL Script"

                    Mock -CommandName Invoke-SqlScript -MockWith {
                        throw $errorMessage
                    }

                    It 'Should throw the correct error from Invoke-Sqlcmd' {
                        { Test-TargetResource @testParameters } | Should -Throw $errorMessage
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
