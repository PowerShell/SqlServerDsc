<#
    .SYNOPSIS
        Automated unit test for DSC_SqlServerPermission DSC resource.

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
$script:dscResourceName = 'DSC_SqlServerPermission'

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
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Write-Verbose -Message ('Test {1} ran for {0} minutes' -f ([System.TimeSpan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString('mm\:ss'), $script:dscResourceName) -Verbose
    $script:timer.Stop()
}

Invoke-TestSetup

try
{
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

        Describe 'DSC_SqlServerPermission\Get-TargetResource' {
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

        Describe 'DSC_SqlServerPermission\Test-TargetResource' {
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

        Describe 'DSC_SqlServerPermission\Set-TargetResource' {
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
    }
}
finally
{
    Invoke-TestCleanup
}
