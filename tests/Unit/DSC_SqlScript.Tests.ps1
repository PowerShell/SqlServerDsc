<#
    .SYNOPSIS
        Automated unit test for DSC_SqlScript DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

# Suppression of this PSSA rule allowed in tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlScript'

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
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SqlPowerShellSqlExecutionException.cs')
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
        Describe 'DSC_SqlScript\Get-TargetResource' {
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

        Describe 'DSC_SqlScript\Set-TargetResource' {
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

        Describe 'DSC_SqlScript\Test-TargetResource' {
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
