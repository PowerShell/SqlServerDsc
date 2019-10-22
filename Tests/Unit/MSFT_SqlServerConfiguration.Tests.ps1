<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlServerConfiguration DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlServerConfiguration'

# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

$defaultState = @{
    ServerName     = 'CLU01'
    InstanceName   = 'ClusteredInstance'
    OptionName     = 'user connections'
    OptionValue    = 0
    RestartService = $false
    RestartTimeout = 120
}

$desiredState = @{
    ServerName     = 'CLU01'
    InstanceName   = 'ClusteredInstance'
    OptionName     = 'user connections'
    OptionValue    = 500
    RestartService = $false
    RestartTimeout = 120
}

$desiredStateRestart = @{
    ServerName     = 'CLU01'
    InstanceName   = 'ClusteredInstance'
    OptionName     = 'user connections'
    OptionValue    = 5000
    RestartService = $true
    RestartTimeout = 120
}

$dynamicOption = @{
    ServerName     = 'CLU02'
    InstanceName   = 'ClusteredInstance'
    OptionName     = 'show advanced options'
    OptionValue    = 0
    RestartService = $false
    RestartTimeout = 120
}

$invalidOption = @{
    ServerName     = 'CLU01'
    InstanceName   = 'MSSQLSERVER'
    OptionName     = 'Does Not Exist'
    OptionValue    = 1
    RestartService = $false
    RestartTimeout = 120
}

$mockConnectSQL = {
    return @(
        (
            New-Object -TypeName Object |
            Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
            Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
            Add-Member -MemberType NoteProperty -Name NetName -Value $mockServerName -PassThru |
            Add-Member -MemberType ScriptProperty -Name Databases -Value {
                return @{
                    $mockSqlDatabase = @((
                            New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                            Add-Member -MemberType ScriptProperty -Name Users -Value {
                                return @{
                                    $mockSqlServerLogin1 = @((
                                            New-Object -TypeName Object |
                                            Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                param
                                                (
                                                    [Parameter()]
                                                    [System.String]
                                                    $Name
                                                )
                                                if ($Name -eq $mockExpectedSqlDatabaseRole)
                                                {
                                                    return $true
                                                }
                                                else
                                                {
                                                    return $false
                                                }
                                            } -PassThru
                                        ))
                                    $mockSqlServerLogin2 = @((
                                            New-Object -TypeName Object |
                                            Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                return $true
                                            } -PassThru
                                        ))
                                    $mockSqlServerLogin3 = @((
                                            New-Object -TypeName Object |
                                            Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                return $true
                                            } -PassThru
                                        ))

                                }
                            } -PassThru |
                            Add-Member -MemberType ScriptProperty -Name Roles -Value {
                                return @{
                                    $mockSqlDatabaseRole1 = @((
                                            New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseRole1 -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                                param
                                                (
                                                    [Parameter()]
                                                    [System.String]
                                                    $Name
                                                )
                                                if ($mockInvalidOperationForAddMemberMethod)
                                                {
                                                    throw 'Mock AddMember Method was called with invalid operation.'
                                                }
                                                if ($Name -ne $mockExpectedMemberToAdd)
                                                {
                                                    throw "Called mocked AddMember() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                        -f $mockExpectedMemberToAdd, $Name
                                                }
                                            } -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                                if ($mockInvalidOperationForDropMethod)
                                                {
                                                    throw 'Mock Drop Method was called with invalid operation.'
                                                }

                                                if ($Name -ne $mockExpectedSqlDatabaseRole)
                                                {
                                                    throw "Called mocked Drop() method without dropping the right database role. Expected '{0}'. But was '{1}'." `
                                                        -f $mockExpectedSqlDatabaseRole, $Name
                                                }
                                            } -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                                param
                                                (
                                                    [Parameter()]
                                                    [System.String]
                                                    $Name
                                                )
                                                if ($mockInvalidOperationForDropMemberMethod)
                                                {
                                                    throw 'Mock DropMember Method was called with invalid operation.'
                                                }
                                                if ($Name -ne $mockExpectedMemberToDrop)
                                                {
                                                    throw "Called mocked Drop() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                        -f $mockExpectedMemberToDrop, $Name
                                                }
                                            } -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name EnumMembers -Value {
                                                if ($mockInvalidOperationForEnumMethod)
                                                {
                                                    throw 'Mock EnumMembers Method was called with invalid operation.'
                                                }
                                                else
                                                {
                                                    $mockEnumMembers
                                                }
                                            } -PassThru
                                        ))
                                    $mockSqlDatabaseRole2 = @((
                                            New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseRole2 -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                                param
                                                (
                                                    [Parameter()]
                                                    [System.String]
                                                    $Name
                                                )
                                                if ($mockInvalidOperationForAddMemberMethod)
                                                {
                                                    throw 'Mock AddMember Method was called with invalid operation.'
                                                }
                                                if ($Name -ne $mockExpectedMemberToAdd)
                                                {
                                                    throw "Called mocked AddMember() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                        -f $mockExpectedMemberToAdd, $Name
                                                }
                                            } -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                                param
                                                (
                                                    [Parameter()]
                                                    [System.String]
                                                    $Name
                                                )
                                                if ($mockInvalidOperationForDropMemberMethod)
                                                {
                                                    throw 'Mock DropMember Method was called with invalid operation.'
                                                }
                                                if ($Name -ne $mockExpectedMemberToDrop)
                                                {
                                                    throw "Called mocked Drop() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                        -f $mockExpectedMemberToDrop, $Name
                                                }
                                            } -PassThru
                                        ))
                                }
                            }-PassThru -Force
                        ))
                }
            } -PassThru -Force |
            Add-Member -MemberType ScriptProperty -Name Logins -Value {
                return @{
                    $mockSqlServerLogin1 = @((
                            New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLogin1Type -PassThru
                        ))
                    $mockSqlServerLogin2 = @((
                            New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLogin2Type -PassThru
                        ))
                    $mockSqlServerLogin3 = @((
                            New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLogin3Type -PassThru
                        ))
                }
            } -PassThru -Force

        )
    )
}

try
{
    Describe "$($script:dscResourceName)\Get-TargetResource" {
        Context 'The system is not in the desired state' {
            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object -TypeName PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 0
                            }
                        )
                    }
                }

                # Add the Alter method.
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:dscResourceName -Verifiable

            # Get the current state.
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed' {
                $result.ServerName | Should -Be $desiredState.ServerName
                $result.InstanceName | Should -Be $desiredState.InstanceName
                $result.OptionName | Should -Be $desiredState.OptionName
                $result.OptionValue | Should -Not -Be $desiredState.OptionValue
                $result.RestartService | Should -Be $desiredState.RestartService
                $result.RestartTimeout | Should -Be $desiredState.RestartTimeout
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }

        Context 'The system is in the desired state' {
            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object -TypeName PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 500
                            }
                        )
                    }
                }

                # Add the Alter method.
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:dscResourceName -Verifiable

            # Get the current state.
            $result = Get-TargetResource @desiredState

            It 'Should return the same values as passed' {
                $result.ServerName | Should -Be $desiredState.ServerName
                $result.InstanceName | Should -Be $desiredState.InstanceName
                $result.OptionName | Should -Be $desiredState.OptionName
                $result.OptionValue | Should -Be $desiredState.OptionValue
                $result.RestartService | Should -Be $desiredState.RestartService
                $result.RestartTimeout | Should -Be $desiredState.RestartTimeout
            }

            It 'Should call Connect-SQL mock when getting the current state' {
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope Context -Times 1
            }
        }

        Context 'Invalid option name is supplied' {
            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object -TypeName PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 0
                            }
                        )
                    }
                }

                # Add the Alter method.
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:dscResourceName -Verifiable

            It 'Should throw the correct error message' {
                $errorMessage = ($script:localizedData.ConfigurationOptionNotFound -f $invalidOption.OptionName)
                { Get-TargetResource @invalidOption } | Should -Throw $errorMessage
            }
        }
    }

    Describe "$($script:dscResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object -TypeName PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'user connections'
                            ConfigValue = 500
                        }
                    )
                }
            }

            # Add the Alter method.
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:dscResourceName -Verifiable

        It 'Should cause Test-TargetResource to return false when not in the desired state' {
            Test-TargetResource @defaultState | Should -Be $false
        }

        It 'Should cause Test-TargetResource method to return true' {
            Test-TargetResource @desiredState | Should -Be $true
        }
    }

    Describe "$($script:dscResourceName)\Set-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object -TypeName PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'user connections'
                            ConfigValue = 0
                            IsDynamic   = $false
                        }
                    )
                }
            }

            # Add the Alter method.
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:dscResourceName -Verifiable -ParameterFilter { $ServerName -eq 'CLU01' }

        Mock -CommandName Connect-SQL -MockWith {
            $mock = New-Object -TypeName PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'show advanced options'
                            ConfigValue = 1
                            IsDynamic   = $true
                        }
                    )
                }
            }

            # Add the Alter method.
            $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            return $mock
        } -ModuleName $script:dscResourceName -Verifiable -ParameterFilter { $ServerName -eq 'CLU02' }

        Mock -CommandName Restart-SqlService -ModuleName $script:dscResourceName -Verifiable
        Mock -CommandName Write-Warning -ModuleName $script:dscResourceName -Verifiable

        Context 'Change the system to the desired state' {
            It 'Should not restart SQL for a dynamic option' {
                Set-TargetResource @dynamicOption
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 0 -Exactly
            }

            It 'Should restart SQL for a non-dynamic option' {
                Set-TargetResource @desiredStateRestart
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 1 -Exactly
            }

            It 'Should warn about restart when required, but not requested' {
                Set-TargetResource @desiredState

                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Write-Warning -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Restart-SqlService -Scope It -Times 0 -Exactly
            }

            It 'Should call Connect-SQL to get option values' {
                Assert-MockCalled -ModuleName $script:dscResourceName -CommandName Connect-SQL -Scope Context -Times 3
            }
        }

        Context 'Invalid option name is supplied' {
            Mock -CommandName Connect-SQL -MockWith {
                $mock = New-Object -TypeName PSObject -Property @{
                    Configuration = @{
                        Properties = @(
                            @{
                                DisplayName = 'user connections'
                                ConfigValue = 0
                            }
                        )
                    }
                }

                # Add the Alter method.
                $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                return $mock
            } -ModuleName $script:dscResourceName -Verifiable

            It 'Should throw the correct error message' {
                $errorMessage = ($script:localizedData.ConfigurationOptionNotFound -f $invalidOption.OptionName)
                { Set-TargetResource @invalidOption } | Should -Throw $errorMessage
            }
        }

        Describe 'SqlServerConfiguration\Export-TargetResource' {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

            # Mocking for protocol TCP
            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
                return $null
            } -Verifiable

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'Extract the existing configuration' {
                $result = Export-TargetResource


                It 'Should return content from the extraction' {
                    $result | Should -Not -Be $null
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
