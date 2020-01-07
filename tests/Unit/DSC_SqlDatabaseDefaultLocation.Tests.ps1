<#
    .SYNOPSIS
        Automated unit test for DSC_SqlDatabaseDefaultLocation DSC resource.

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
$script:dscResourceName = 'DSC_SqlDatabaseDefaultLocation'

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

    # Load the default SQL Module stub
    Import-SQLModuleStub
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
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockSQLDataPath = 'C:\Program Files\Data\'
        $mockSqlLogPath = 'C:\Program Files\Log\'

        # Ending backslash is regression test for issue #1307.
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
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
        }

        $mockConnectSQL = {
            return New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server |
                Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru -Force |
                Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru -Force |
                Add-Member -MemberType NoteProperty -Name DefaultFile -Value $mockSqlDataPath -PassThru -Force |
                Add-Member -MemberType NoteProperty -Name DefaultLog -Value $mockSqlLogPath -PassThru -Force |
                # Ending backslash is removed because of regression test for issue #1307.
                Add-Member -MemberType NoteProperty -Name BackupDirectory -Value $mockSqlBackupPath.TrimEnd('\') -PassThru -Force |
                Add-Member -MemberType ScriptMethod -Name Alter -Value {
                if ($mockInvalidOperationForAlterMethod)
                {
                    throw 'Mock Alter Method was called with invalid operation.'
                }
                $script:WasMethodAlterCalled = $true
            } -PassThru -Force
        }
        #endregion

        Describe 'DSC_SqlDatabaseDefaultLocation\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $testCases = @(
                    @{
                        Type               = 'Data'
                        Path               = $mockSqlDataPath
                    },
                    @{
                        Type               = 'Log'
                        Path               = $mockSqlLogPath
                    },
                    @{
                        Type               = 'Backup'
                        # Ending backslash is removed because of regression test for issue #1307.
                        Path               = $mockSqlBackupPath.TrimEnd('\')
                    }
                )
            }

            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Test-ActiveNode -MockWith {
                    param
                    (
                        [PSObject]
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
                    $getTargetResourceResult.ServerName | Should -Be $mockDefaultParameters.ServerName
                    $getTargetResourceResult.InstanceName | Should -Be $mockDefaultParameters.InstanceName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'DSC_SqlDatabaseDefaultLocation\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $testCases = @(
                    @{
                        Type               = 'Data'
                        Path               = $mockSqlDataPath
                        AlterPath          = $mockSqlAlterDataPath
                    },
                    @{
                        Type               = 'Log'
                        Path               = $mockSqlLogPath
                        AlterPath          = $mockSqlAlterLogPath
                    },
                    @{
                        Type               = 'Backup'
                        Path               = $mockSqlBackupPath
                        AlterPath          = $mockSqlAlterBackupPath
                    }
                )
            }
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

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
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

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
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
                        Path                    = $mockSqlDataPath
                        Type                    = 'Data'
                        ProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNode
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }

                It 'Should be "true" when ProcessOnlyOnActiveNode is <mockProcessOnlyOnActiveNodeOriginal>.' {
                    $testTargetResourceParameters = $mockDefaultParameters
                    $testTargetResourceParameters += @{
                        Path                    = $mockSqlDataPath
                        Type                    = 'Data'
                        ProcessOnlyOnActiveNode = $mockProcessOnlyOnActiveNodeOriginal
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'DSC_SqlDatabaseDefaultLocation\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $testCases = @(
                    @{
                        Type               = 'Data'
                        Path               = $mockSqlDataPath
                        AlterPath          = $mockSqlAlterDataPath
                        ExpectedAlterPath  = $mockExpectedAlterDataPath
                        InvalidPath        = $mockInvalidPathForData
                    },
                    @{
                        Type               = 'Log'
                        Path               = $mockSqlLogPath
                        AlterPath          = $mockSqlAlterLogPath
                        ExpectedAlterPath  = $mockExpectedAlterLogPath
                        InvalidPath        = $mockInvalidPathForLog
                    },
                    @{
                        Type               = 'Backup'
                        Path               = $mockSqlBackupPath
                        AlterPath          = $mockSqlAlterBackupPath
                        ExpectedAlterPath  = $mockExpectedAlterBackupPath
                        InvalidPath        = $mockInvalidPathForBackup
                    }
                )
            }

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
                        Type           = $Type
                        Path           = $AlterPath
                        RestartService = $mockRestartService
                    }


                    {Set-TargetResource @mockDefaultParameters @setTargetResourceParameters} | Should -Not -Throw
                    $script:WasMethodAlterCalled | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                }

                It 'Should throw when the path is invalid.' -TestCases $testCases {
                    param
                    (
                        $Type,
                        $InvalidPath
                    )

                    $setTargetResourceParameters = @{
                        Type           = $Type
                        Path           = $InvalidPath
                        RestartService = $mockRestartService
                    }

                    $throwInvalidPath = "The path '$InvalidPath' does not exist."
                    {Set-TargetResource @mockDefaultParameters @setTargetResourceParameters} | Should -Throw $throwInvalidPath
                    $script:WasMethodAlterCalled | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                }
            }

            $mockInvalidOperationForAlterMethod = $true

            It 'Should throw the correct error when Alter() method was called with invalid operation' -TestCases $testCases {
                param
                (
                    $Type,
                    $Path,
                    $AlterPath,
                    $ExpectedAlterPath
                )

                $throwInvalidOperation = "Changing the default path failed."

                $setTargetResourceParameters = @{
                    Type           = $Type
                    Path           = $ExpectedAlterPath
                    RestartService = $mockRestartService
                }

                {Set-TargetResource @mockDefaultParameters @setTargetResourceParameters} | Should -Throw $throwInvalidOperation

                Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
