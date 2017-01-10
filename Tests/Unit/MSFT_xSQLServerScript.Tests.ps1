<#
    .SYNOPSIS
        Automated unit test for MSFT_xSQLServerScript DSC Resource
#>

# Suppression of this PSSA rule allowed in tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
Param()

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
    -DSCModuleName 'xSQLServer' `
    -DSCResourceName 'MSFT_xSQLServerScript'  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    Add-Type -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SqlPowerShellSqlExecutionException.cs')
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SQLPSStub.psm1') -Force
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}


# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xSQLServerScript' {

        $script:DSCModuleName       = 'xSQLServer'
        $resourceName     = 'MSFT_xSQLServerScript'
        $sqlServerHelperModuleName = 'xSQLServerHelper'

        $testParameters = @{
            ServerInstance = $env:COMPUTERNAME
            SetFilePath = "set.sql"
            GetFilePath = "get.sql"
            TestFilePath = "test.sql"
        }

        Describe "$resourceName\Get-TargetResource" {

            Context 'Get-TargetResource fails to import SQLPS module' {
                $throwMessage = "Failed to import SQLPS module."

                Mock -CommandName Import-Module -MockWith {
                    throw $throwMessage
                } -ModuleName $sqlServerHelperModuleName

                It 'Should throw the correct error from Import-Module' {
                    { Get-TargetResource @testParameters } | Should Throw $throwMessage
                }
            }

            Context 'Get-TargetResource returns script results successfully' {
                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerInstance | Should Be $testParameters.ServerInstance
                    $result.SetFilePath | Should Be $testParameters.SetFilePath
                    $result.GetFilePath | Should Be $testParameters.GetFilePath
                    $result.TestFilePath | Should Be $testParameters.TestFilePath
                    $result.GetType() | Should Be "hashtable"
                }
            }

            Context 'Get-TargetResource throws an error when running the script in the GetFilePath parameter' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {
                    throw $errorMessage
                }

                It 'Should throw the correct error from Invoke-Sqlcmd' {
                    { Get-TargetResource @testParameters } | Should Throw $errorMessage
                }
            }
        }

        Describe "$resourceName\Set-TargetResource" {

            Context 'Set-TargetResource fails to import SQLPS module' {
                $throwMessage = "Failed to import SQLPS module."

                Mock -CommandName Import-Module -MockWith { throw $throwMessage } -ModuleName $sqlServerHelperModuleName

                It 'Should throw the correct error from Import-Module' {
                    { Set-TargetResource @testParameters } | Should Throw $throwMessage
                }
            }

            Context 'Set-TargetResource runs script without issue' {
                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {
                    return ''
                }

                It 'Should return the expected results' {
                    $result = Set-TargetResource @testParameters
                    $result | Should Be ''
                }
            }

            Context 'Set-TargetResource throws an error when running the script in the SetFilePath parameter' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {
                    throw $errorMessage
                }

                It 'Should throw the correct error from Invoke-Sqlcmd' {
                    { Set-TargetResource @testParameters } | Should Throw $errorMessage
                }
            }
        }

        Describe "$resourceName\Test-TargetResource" {
            Context 'Test-TargetResource fails to import SQLPS module' {
                $throwMessage = 'Failed to import SQLPS module.'

                Mock -CommandName Import-Module -MockWith {
                    throw $throwMessage
                } -ModuleName $sqlServerHelperModuleName

                It 'Should throw the correct error from Import-Module' {
                    { Set-TargetResource @testParameters } | Should Throw $throwMessage
                }
            }

            Context 'Test-TargetResource runs script without issue' {
                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {}

                It 'Should return true' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }
            }

            Context 'Test-TargetResource throws the exception SqlPowerShellSqlExecutionException when running the script in the TestFilePath parameter' {
                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {
                    throw New-Object Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException
                }

                It 'Should return false' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }
            }

            Context 'Test-TargetResource throws an unexpected error when running the script in the TestFilePath parameter' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {
                    throw $errorMessage
                }

                It 'Should throw the correct error from Invoke-Sqlcmd' {
                    { Test-TargetResource @testParameters } | Should Throw $errorMessage
                }
            }
        }

        Describe "$resourceName\Invoke-SqlScript" {
            $invokeScriptParameters = @{
                ServerInstance = $env:COMPUTERNAME
                SqlScriptPath = "set.sql"
            }

            Context 'Invoke-SqlScript fails to import SQLPS module' {
                $throwMessage = "Failed to import SQLPS module."

                Mock -CommandName Import-Module -MockWith {
                    throw $throwMessage
                } -ModuleName $sqlServerHelperModuleName

                It 'Should throw the correct error from Import-Module' {
                    { Invoke-SqlScript @invokeScriptParameters } | Should Throw $throwMessage
                }
            }

            Context 'Invoke-SQlScript is called with credentials' {
                $passwordPlain = "password"
                $user = "User"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {} -ParameterFilter {
                    ($Username -eq $user) -and ($Password -eq $passwordPlain)
                }

                $password = ConvertTo-SecureString -String $passwordPlain -AsPlainText -Force
                $cred = New-Object pscredential -ArgumentList $user, $password

                It 'Should call Invoke-Sqlcmd with correct parameters' {
                    $invokeScriptParameters.Add("Credential", $cred)
                    $null = Invoke-SqlScript @invokeScriptParameters

                    Assert-MockCalled -CommandName Invoke-Sqlcmd -ParameterFilter {
                        ($Username -eq $user) -and ($Password -eq $passwordPlain)
                    } -Times 1 -Exactly -Scope It
                }
            }

            Context 'Invoke-SqlScript fails to execute the SQL scripts' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {
                    throw $errorMessage
                }

                It 'Should throw the correct error from Invoke-Sqlcmd' {
                    { Invoke-SqlScript @invokeScriptParameters } | Should Throw $errorMessage
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
