$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlServerPermission'

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
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
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

        Describe 'MSFT_SqlServerPermission\Get-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith {
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$mockServerName\$mockInstanceName"
                    $mockObjectSmoServer.DisplayName = $mockInstanceName
                    $mockObjectSmoServer.InstanceName = $mockInstanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
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
                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
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
                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the Get-TargetResource throws an error' {
                    It 'Should return the correct error message' {
                        Mock -CommandName Connect-Sql -MockWith {
                            throw 'Mocked error.'
                        }

                        { Get-TargetResource @testParameters } | Should -Throw 'Unexpected result when trying to get permissions for ''COMPANY\SqlServiceAcct''. InnerException: Mocked error.'
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
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlServerPermission\Test-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith {
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$mockServerName\$mockInstanceName"
                    $mockObjectSmoServer.DisplayName = $mockInstanceName
                    $mockObjectSmoServer.InstanceName = $mockInstanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
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

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when wanted desired state is to be Absent' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $testParameters.Add('Ensure', 'Absent')


                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return that desired state is present when wanted desired state is to be Present' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $testParameters.Add('Ensure', 'Present')

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is present when wanted desired state is to be Absent' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $testParameters.Add('Ensure', 'Absent')

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlServerPermission\Set-TargetResource' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith {
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "$mockServerName\$mockInstanceName"
                    $mockObjectSmoServer.DisplayName = $mockInstanceName
                    $mockObjectSmoServer.InstanceName = $mockInstanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $mockPrincipal

                    return $mockObjectSmoServer
                } -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should not throw error when desired state is to be Present' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $testParameters.Add('Ensure', 'Present')

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                }

                It 'Should not throw error when desired state is to be Absent' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $testParameters.Add('Ensure', 'Absent')

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 2 -Scope It
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should not throw error when desired state is to be Present' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

                    $testParameters.Add('Ensure', 'Present')

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should not throw error when desired state is to be Absent' {
                    [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

                    $testParameters.Add('Ensure', 'Absent')

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                Context 'When the Set-TargetResource throws an error' {
                    It 'Should return the correct error message' {
                        Mock -CommandName Connect-SQL -MockWith {
                            $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server
                            $mockObjectSmoServer.Name = "$mockServerName\$mockInstanceName"
                            $mockObjectSmoServer.DisplayName = $mockInstanceName
                            $mockObjectSmoServer.InstanceName = $mockInstanceName
                            $mockObjectSmoServer.IsHadrEnabled = $False
                            # This make the SMO Server object mock to throw when Grant() method is called.
                            $mockObjectSmoServer.MockGranteeName = $mockOtherPrincipal

                            return $mockObjectSmoServer
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should -Throw 'Changing permission for principal ''COMPANY\SqlServiceAcct'' failed. InnerException: Exception calling "Grant" with "2" argument(s): "Expected to get granteeName == ''COMPANY\OtherAccount''. But got ''COMPANY\SqlServiceAcct'''
                    }
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
