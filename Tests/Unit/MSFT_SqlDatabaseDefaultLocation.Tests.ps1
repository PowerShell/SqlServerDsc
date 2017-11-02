#region Header

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'SqlServerDSC' `
    -DSCResourceName 'MSFT_SqlDatabaseDefaultLocation' `
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

    InModuleScope 'MSFT_SqlDatabaseDefaultLocation' {
        $mockSqlServerName = 'localhost'
        $mockSqlServerInstanceName = 'MSSQLSERVER'
        $mockSQLDataPath = 'C:\Program Files\Data\'
        $mockSqlLogPath = 'C:\Program Files\Log\'
        $mockSqlBackupPath = 'C:\Program Files\Backup\'
        $mockSqlAlterDataPath = 'C:\Program Files\'
        $mockSqlAlterLogPath = 'C:\Program Files\'
        $mockSqlAlterBackupPath = 'C:\Program Files\'
        $mockRestartService = $true
        $mockExpectedAlterDataPath = $env:temp
        $mockExpectedAlterLogPath = $env:temp
        $mockExpectedAlterBackupPath = $env:temp
        $mockInvalidPathForData = 'C:\InvalidPath'
        $mockInvalidPathForLog = 'C:\InvalidPath'
        $mockInvalidPathForBackup = 'C:\InvalidPath'
        $mockInvalidOperationForAlterMethod = $false
        $mockProcessOnlyOnActiveNode = $true

        $script:WasMethodAlterCalled = $false

        #region Function mocks

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            SQLInstanceName = $mockSqlServerInstanceName
            SQLServer       = $mockSqlServerName
        }

        $mockConnectSQL = {
            return New-Object Object -TypeName Microsoft.SqlServer.Management.Smo.Server |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockSqlServerInstanceName -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockSqlServerName -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name DefaultFile -Value $mockSqlDataPath -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name DefaultLog -Value $mockSqlLogPath -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name BackupDirectory -Value $mockSqlBackupPath -PassThru -Force |
                        Add-Member -MemberType ScriptMethod -Name Alter -Value {
                            if ($mockInvalidOperationForAlterMethod)
                            {
                                throw 'Mock Alter Method was called with invalid operation.'
                            }
                            $script:WasMethodAlterCalled = $true
                        } -PassThru -Force
        }

        $testCases = @(
            @{
                Type = 'Data'
                Path = $mockSqlDataPath
                AlterPath = $mockSqlAlterDataPath
                ExepectedAlterPath = $mockExpectedAlterDataPath
                InvalidPath = $mockInvalidPathForData
            },
            @{
                Type = 'Log'
                Path = $mockSqlLogPath
                AlterPath = $mockSqlAlterLogPath
                ExepectedAlterPath = $mockExpectedAlterLogPath
                InvalidPath = $mockInvalidPathForLog
            },
            @{
                Type = 'Backup'
                Path = $mockSqlBackupPath
                AlterPath = $mockSqlAlterBackupPath
                ExepectedAlterPath = $mockExpectedAlterBackupPath
                InvalidPath = $mockInvalidPathForBackup
            }
        )
        #endregion

        Describe 'MSFT_SqlDatabaseDefaultLocation\Get-TargetResource' -Tag 'Get'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Test-ActiveNode -Mockwith {
                    param
                    (
                        [psobject]
                        $ServerObject
                    )

                    return $true
                } -Verifiable
            }

            Context 'When the system is either in the desired state or not in the desired state' {
                It 'Should get the default path for <Type> with the value <Path>' -TestCases $testCases {
                    param
                    (
                        $Type,
                        $Path
                    )

                    $getTargetResourceResult = Get-TargetResource @mockDefaultParameters -Type $Type -Path $Path

                    $getTargetResourceResult.Path | Should -Be $Path
                    $getTargetResourceResult.Type | Should -Be $Type
                    $getTargetResourceResult.SQLServer | Should -Be $mockDefaultParameters.SQLServer
                    $getTargetResourceResult.SQLInstanceName | Should -Be $mockDefaultParameters.SQLInstanceName

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
             }
        }

        Describe 'MSFT_SqlDatabaseDefaultLocation\Test-TargetResource' -Tag 'Test'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Test-ActiveNode -MockWith {
                    $mockProcessOnlyOnActiveNode
                } -Verifiable
            }

            Context 'When the system is in the desired state.' {
                It 'Should return true when the desired state of the <Type> path has the value <Path>' -TestCases $testCases {
                    param
                    (
                        $Type,
                        $Path
                    )

                    $testTargetResourceResult = Test-TargetResource @mockDefaultParameters -Type $Type -Path $Path
                    $testTargetResourceResult | Should -Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state.' {
                It 'Should return false when the desired state of the <Type> path does not equal <Path>' -TestCases $testCases {
                    param
                    (
                        $Type,
                        $Path,
                        $AlterPath
                    )

                    $testTargetResourceResult = Test-TargetResource @mockDefaultParameters -Type $Type -Path $AlterPath
                    $testTargetResourceResult | Should -Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
            Context 'When the ProcessOnlyOnActiveNode parameter is passed' {
                AfterAll {
                    $mockProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNodeOriginal
                }

                BeforeAll {
                    $mockProcessOnlyOnActiveNodeOriginal = $mockProcessOnlyOnActiveNode
                    $mockProcessOnlyOnActiveNode = $false
                }

                It 'Should be "true" when ProcessOnlyOnActiveNode is <mockProcessOnlyOnActiveNode>.' {
                    $testTargetResourceParameters = $mockDefaultParameters
                    $testTargetResourceParameters += @{
                        Path    = $mockSqlDataPath
                        Type    = 'Data'
                        ProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNode
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should be "true" when ProcessOnlyOnActiveNode is <mockProcessOnlyOnActiveNodeOriginal>.' {
                    $testTargetResourceParameters = $mockDefaultParameters
                    $testTargetResourceParameters += @{
                        Path    = $mockSqlDataPath
                        Type    = 'Data'
                        ProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNodeOriginal
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'MSFT_SqlDatabaseDefaultLocation\Set-TargetResource' -Tag 'Set'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Restart-SqlService -Verifiable

                # This is used to evaluate if mocked Alter() method was called.
                $script:WasMethodAlterCalled = $false
            }

            Context 'When the system is not in the desired state.' {
                It 'Should not throw when the path is successfully changed.' -TestCases $testCases {
                    param
                    (
                        $Type,
                        $Path,
                        $AlterPath
                    )

                    $setTargetResourceParameters = @{
                        Type = $Type
                        Path = $AlterPath
                        RestartService = $mockRestartService
                    }


                    {Set-TargetResource @mockDefaultParameters @setTargetResourceParameters} | Should -Not -Throw
                    $script:WasMethodAlterCalled | Should -Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled Restart-SqlService -Exactly -Times 1 -Scope It
                }

                It 'Should throw when the path is invalid.' -TestCases $testCases {
                    param
                    (
                        $Type,
                        $InvalidPath
                    )

                    $setTargetResourceParameters = @{
                        Type = $Type
                        Path = $InvalidPath
                        RestartService = $mockRestartService
                    }

                    $throwInvalidPath = "The path '$InvalidPath' does not exist."
                    {Set-TargetResource @mockDefaultParameters @setTargetResourceParameters} | Should -Throw $throwInvalidPath
                    $script:WasMethodAlterCalled | Should -Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 0 -Scope It
                    Assert-MockCalled Restart-SqlService -Exactly -Times 0 -Scope It
                }
            }

            $mockInvalidOperationForAlterMethod = $true

            It 'Should throw the correct error when Alter() method was called with invalid operation' -TestCases $testCases {
                param
                (
                    $Type,
                    $Path,
                    $AlterPath,
                    $ExepectedAlterPath
                )

                $throwInvalidOperation = "Changing the default path failed."

                $setTargetResourceParameters = @{
                    Type = $Type
                    Path = $ExepectedAlterPath
                    RestartService = $mockRestartService
                }

                {Set-TargetResource @mockDefaultParameters @setTargetResourceParameters} | Should -Throw $throwInvalidOperation

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                Assert-MockCalled Restart-SqlService -Exactly -Times 0 -Scope It
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
