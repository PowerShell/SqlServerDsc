<#
    .SYNOPSIS
        Automated unit test for DSC_SqlScriptQuery DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

# Suppression of this PSSA rule allowed in tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlScriptQuery'

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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SqlPowerShellSqlExecutionException.cs')

    # Load the default SQL Module stub
    Import-SQLModuleStub
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
         Describe 'DSC_SqlScriptQuery\Get-TargetResource' {
             BeforeAll {
                $testParameters = @{
                    ServerInstance = $env:COMPUTERNAME
                    GetQuery       = "GetQuery;"
                    TestQuery      = "TestQuery;"
                    SetQuery       = "SetQuery;"
                }

                $testParametersTimeout = @{
                    ServerInstance = $env:COMPUTERNAME
                    GetQuery       = "GetQuery;"
                    TestQuery      = "TestQuery;"
                    SetQuery       = "SetQuery;"
                    QueryTimeout   = 30
                }
             }

            Context 'Get-TargetResource returns script results successfully' {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Get-TargetResource @testParameters

                    $result.ServerInstance | Should -Be $testParameters.ServerInstance
                    $result.GetQuery | Should -Be $testParameters.GetQuery
                    $result.SetQuery | Should -Be $testParameters.SetQuery
                    $result.TestQuery | Should -Be $testParameters.TestQuery
                    $result | Should BeOfType Hashtable
                }
            }

            Context 'Get-TargetResource returns script results successfully with query timeout' {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Get-TargetResource @testParametersTimeout
                    $result.ServerInstance | Should -Be $testParametersTimeout.ServerInstance
                    $result.GetQuery | Should -Be $testParameters.GetQuery
                    $result.SetQuery | Should -Be $testParameters.SetQuery
                    $result.TestQuery | Should -Be $testParameters.TestQuery
                    $result | Should BeOfType Hashtable
                }
            }

            Context 'Get-TargetResource throws an error when running the script in the GetQuery parameter' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Invoke-SqlScript -MockWith {
                    throw $errorMessage
                }

                It 'Should throw the correct error from Invoke-Sqlcmd' {
                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }
            }
        }

        Describe 'DSC_SqlScriptQuery\Set-TargetResource' {
            Context 'Set-TargetResource runs script without issue' {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Set-TargetResource @testParameters
                    $result | Should -Be ''
                }
            }

            Context 'Set-TargetResource runs script without issue using timeout' {
                Mock -CommandName Invoke-SqlScript -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Set-TargetResource @testParametersTimeout
                    $result | Should -Be ''
                }
            }

            Context 'Set-TargetResource throws an error when running the script in the SetFilePath parameter' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Invoke-SqlScript -MockWith {
                    throw $errorMessage
                }

                It 'Should throw the correct error from Invoke-Sqlcmd' {
                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }
            }
        }

        Describe 'DSC_SqlScriptQuery\Test-TargetResource' {
            Context 'When the system is in the desired state' {
                Context 'Test-TargetResource runs script without issue' {
                    Mock -CommandName Invoke-SqlScript

                    It 'Should return true' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $true
                    }
                }

                Context 'Test-TargetResource runs script without issue with timeout' {
                    Mock -CommandName Invoke-SqlScript

                    It 'Should return true' {
                        $result = Test-TargetResource @testParametersTimeout
                        $result | Should -Be $true
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When Invoke-SqlScript returns an SQL error code from the query that was ran' {
                    Mock -CommandName Invoke-SqlScript -MockWith {
                        return 1
                    }
                    It 'Should return false' {
                        $result = Test-TargetResource @testParametersTimeout
                        $result | Should -Be $false
                    }
                }

                Context 'Test-TargetResource throws the exception SqlPowerShellSqlExecutionException when running the script in the TestFilePath parameter' {
                    Mock -CommandName Invoke-SqlScript -MockWith {
                        throw New-Object -TypeName Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException
                    }

                    It 'Should return false' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $false
                    }
                }

                Context 'Test-TargetResource throws an unexpected error when running the script in the TestFilePath parameter' {
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
