<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlServerPermission DSC resource.

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
$script:dscResourceName = 'MSFT_SqlServerPermission'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

#endregion HEADER

function Invoke-TestSetup
{
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
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
        $mockServerName = 'localhost'
        $mockInstanceName = 'DEFAULT'
        $mockPrincipal = 'COMPANY\SqlServiceAcct'
        $mockOtherPrincipal = 'COMPANY\OtherAccount'
        $mockPermission = @('ConnectSql', 'AlterAnyAvailabilityGroup', 'ViewServerState')

        #endregion Pester Test Initialization

        $defaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
            Principal    = $mockPrincipal
            Permission   = $mockPermission
        }

        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Roles -Value {
                        return @{
                            $mockSqlServerRole = ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlServerRole -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name EnumMemberNames -Value {
                                    if ($mockInvalidOperationForEnumMethod)
                                    {
                                        throw 'Mock EnumMemberNames Method was called with invalid operation.'
                                    }
                                    else
                                    {
                                        $mockEnumMemberNames
                                    }
                                } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                    if ($mockInvalidOperationForDropMethod)
                                    {
                                        throw 'Mock Drop Method was called with invalid operation.'
                                    }

                                    if ( $this.Name -ne $mockExpectedServerRoleToDrop )
                                    {
                                        throw "Called mocked drop() method without dropping the right server role. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedServerRoleToDrop, $this.Name
                                    }
                                } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                    if ($mockInvalidOperationForAddMemberMethod)
                                    {
                                        throw 'Mock AddMember Method was called with invalid operation.'
                                    }

                                    if ( $mockSqlServerLoginToAdd -ne $mockExpectedMemberToAdd )
                                    {
                                        throw "Called mocked AddMember() method without adding the right login. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedMemberToAdd, $mockSqlServerLoginToAdd
                                    }
                                } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                    if ($mockInvalidOperationForDropMemberMethod)
                                    {
                                        throw 'Mock DropMember Method was called with invalid operation.'
                                    }

                                    if ( $mockSqlServerLoginToDrop -ne $mockExpectedMemberToDrop )
                                    {
                                        throw "Called mocked DropMember() method without removing the right login. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedMemberToDrop, $mockSqlServerLoginToDrop
                                    }
                                } -PassThru
                            )
                        }
                    } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Logins -Value {
                        return @{
                            $mockSqlServerLoginOne  = @((
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                            $mockSqlServerLoginTwo  = @((
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                            $mockSqlServerLoginTree = @((
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                            $mockSqlServerLoginFour = @((
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                        }
                    } -PassThru -Force
                )
            )
        }

        Describe 'MSFT_SqlServerPermission\Get-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith {
                    $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$mockServerName\$mockInstanceName"
                    $mockObjectSmoServer.DisplayName = $mockInstanceName
                    $mockObjectSmoServer.InstanceName = $mockInstanceName
                    $mockObjectSmoServer.IsHadrEnabled = $false
                    $mockObjectSmoServer.MockGranteeName = $mockPrincipal

                    return $mockObjectSmoServer
                } -Verifiable
            }

            Context 'When the system is not in the desired state' {
                Context 'When no permission is set for the principal' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    It 'Should return the desired state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should -Be 'Absent'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.ServerName | Should -Be $mockServerName
                        $result.InstanceName | Should -Be $mockInstanceName
                        $result.Principal | Should -Be $mockPrincipal
                    }

                    It 'Should not return any permissions' {
                        $result = Get-TargetResource @testParameters
                        $result.Permission | Should -Be ''
                    }

                    It 'Should call the mock function Connect-SQL' {
                        Get-TargetResource @testParameters | Out-Null
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When one permission is missing for the principal' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    BeforeEach {
                        $testParameters.Permission = @( 'AlterAnyAvailabilityGroup', 'ViewServerState', 'AlterAnyEndpoint')
                    }

                    It 'Should return the desired state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should -Be 'Absent'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.ServerName | Should -Be $mockServerName
                        $result.InstanceName | Should -Be $mockInstanceName
                        $result.Principal | Should -Be $mockPrincipal
                    }

                    It 'Should not return any permissions' {
                        $result = Get-TargetResource @testParameters
                        $result.Permission | Should -Be @('AlterAnyAvailabilityGroup', 'ConnectSql', 'ViewServerState')
                    }

                    It 'Should call the mock function Connect-SQL' {
                        Get-TargetResource @testParameters | Out-Null
                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the Get-TargetResource throws an error' {
                    It 'Should return the correct error message' {
                        Mock -CommandName Connect-Sql -MockWith {
                            throw 'Mocked error.'
                        }

                        { Get-TargetResource @testParameters } | Should -Throw ($script:localizedData.PermissionGetError -f $mockPrincipal)
                    }
                }
            }

            Context 'When the system is in the desired state' {
                [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $mockServerName
                    $result.InstanceName | Should -Be $mockInstanceName
                    $result.Principal | Should -Be $mockPrincipal
                }

                It 'Should return the permissions passed as parameter' {
                    $result = Get-TargetResource @testParameters
                    foreach ($currentPermission in $mockPermission)
                    {
                        if ( $result.Permission -ccontains $currentPermission )
                        {
                            $permissionState = $true
                        }
                        else
                        {
                            $permissionState = $false
                            break
                        }
                    }

                    $permissionState | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Get-TargetResource @testParameters | Out-Null
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlServerPermission\Test-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith {
                    $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$mockServerName\$mockInstanceName"
                    $mockObjectSmoServer.DisplayName = $mockInstanceName
                    $mockObjectSmoServer.InstanceName = $mockInstanceName
                    $mockObjectSmoServer.IsHadrEnabled = $false
                    $mockObjectSmoServer.MockGranteeName = $mockPrincipal

                    return $mockObjectSmoServer
                } -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should return that desired state is absent when wanted desired state is to be Present' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $testParameters.Add('Ensure', 'Present')

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when wanted desired state is to be Absent' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $testParameters.Add('Ensure', 'Absent')


                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return that desired state is present when wanted desired state is to be Present' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $testParameters.Add('Ensure', 'Present')

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is present when wanted desired state is to be Absent' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $testParameters.Add('Ensure', 'Absent')

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlServerPermission\Set-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith {
                    $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$mockServerName\$mockInstanceName"
                    $mockObjectSmoServer.DisplayName = $mockInstanceName
                    $mockObjectSmoServer.InstanceName = $mockInstanceName
                    $mockObjectSmoServer.IsHadrEnabled = $false
                    $mockObjectSmoServer.MockGranteeName = $mockPrincipal

                    return $mockObjectSmoServer
                } -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should not throw error when desired state is to be Present' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $testParameters.Add('Ensure', 'Present')

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                }

                It 'Should not throw error when desired state is to be Absent' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $testParameters.Add('Ensure', 'Absent')

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should not throw error when desired state is to be Present' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $testParameters.Add('Ensure', 'Present')

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should not throw error when desired state is to be Absent' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $testParameters.Add('Ensure', 'Absent')

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                Context 'When the Set-TargetResource throws an error' {
                    It 'Should return the correct error message' {
                        Mock -CommandName Connect-SQL -MockWith {
                            $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                            $mockObjectSmoServer.Name = "$mockServerName\$mockInstanceName"
                            $mockObjectSmoServer.DisplayName = $mockInstanceName
                            $mockObjectSmoServer.InstanceName = $mockInstanceName
                            $mockObjectSmoServer.IsHadrEnabled = $false
                            # This make the SMO Server object mock to throw when Grant() method is called.
                            $mockObjectSmoServer.MockGranteeName = $mockOtherPrincipal

                            return $mockObjectSmoServer
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.ChangingPermissionFailed -f $mockPrincipal)
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe 'SqlServerPermission\Export-TargetResource' {
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
    Invoke-TestCleanup
}
