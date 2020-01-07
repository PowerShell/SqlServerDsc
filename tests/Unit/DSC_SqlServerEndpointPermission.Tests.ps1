<#
    .SYNOPSIS
        Automated unit test for DSC_SqlServerEndpointPermission DSC resource.

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
$script:dscResourceName = 'DSC_SqlServerEndpointPermission'

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

    Write-Verbose -Message ('Test {1} run for {0} minutes' -f ([System.TimeSpan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString('mm\:ss'), $script:dscResourceName) -Verbose
    $script:timer.Stop()
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $mockNodeName = 'localhost'
        $mockInstanceName = 'SQL2016'
        $mockPrincipal = 'COMPANY\SqlServiceAcct'
        $mockOtherPrincipal = 'COMPANY\OtherAcct'
        $mockEndpointName = 'DefaultEndpointMirror'

        $mockDynamicEndpointName = $mockEndpointName

        $script:mockMethodGrantRan = $false
        $script:mockMethodRevokeRan = $false

        $mockConnectSql = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name 'Endpoints' -Value {
                return @(
                    @{
                        # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                        $mockDynamicEndpointName = New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockEndpointName -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'EnumObjectPermissions' -Value {
                            param($permissionSet)
                            return @(
                                (New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty Grantee $mockDynamicPrincipal -PassThru |
                                        Add-Member -MemberType NoteProperty PermissionState 'Grant' -PassThru
                                )
                            )
                        } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Grant' -Value {
                            param(
                                $permissionSet,
                                $mockPrincipal
                            )

                            $script:mockMethodGrantRan = $true
                        } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                            param(
                                $permissionSet,
                                $mockPrincipal
                            )

                            $script:mockMethodRevokeRan = $true
                        } -PassThru -Force
                    }
                )
            } -PassThru -Force
        }

        $defaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockNodeName
            Name         = $mockEndpointName
            Principal    = $mockPrincipal
        }

        Describe 'DSC_SqlServerEndpointPermission\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            $mockDynamicPrincipal = $mockOtherPrincipal

            Context 'When the system is not in the desired state' {
                It 'Should return the desired state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.Principal | Should -Be $testParameters.Principal
                }

                It 'Should not return any permissions' {
                    $result = Get-TargetResource @testParameters
                    $result.Permission | Should -Be ''
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                $mockDynamicEndpointName = 'UnknownEndPoint'

                Context 'When endpoint is missing' {
                    It 'Should throw the correct error message' {
                        { Get-TargetResource @testParameters } | Should -Throw ($script:localizedData.UnexpectedErrorFromGet -f $testParameters.Name)

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointName = $mockEndpointName
            }

            $mockDynamicPrincipal = $mockPrincipal

            Context 'When the system is in the desired state' {
                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.Principal | Should -Be $testParameters.Principal
                }

                It 'Should return the permissions passed as parameter' {
                    $result = Get-TargetResource @testParameters
                    $result.Permission | Should -Be 'CONNECT'
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DSC_SqlServerEndpointPermission\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicPrincipal = $mockOtherPrincipal

                It 'Should return that desired state is absent when wanted desired state is to be Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Permission'] = 'CONNECT'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                $mockDynamicPrincipal = $mockPrincipal

                It 'Should return that desired state is absent when wanted desired state is to be Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['Permission'] = 'CONNECT'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state' {
                $mockDynamicPrincipal = $mockPrincipal

                It 'Should return that desired state is present when wanted desired state is to be Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Permission'] = 'CONNECT'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                $mockDynamicPrincipal = $mockOtherPrincipal

                It 'Should return that desired state is present when wanted desired state is to be Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['Permission'] = 'CONNECT'

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DSC_SqlServerEndpointPermission\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $mockDynamicPrincipal = $mockOtherPrincipal
                $script:mockMethodGrantRan = $false
                $script:mockMethodRevokeRan = $false

                It 'Should call the the method Grant when desired state is to be Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Permission'] = 'CONNECT'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodGrantRan | Should -Be $true
                    $script:mockMethodRevokeRan | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                }

                $mockDynamicPrincipal = $mockPrincipal
                $script:mockMethodGrantRan = $false
                $script:mockMethodRevokeRan = $false

                It 'Should call the the method Revoke when desired state is to be Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['Permission'] = 'CONNECT'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodGrantRan | Should -Be $false
                    $script:mockMethodRevokeRan | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope It
                }

                $mockDynamicEndpointName = 'UnknownEndPoint'

                Context 'When endpoint is missing' {
                    It 'Should throw the correct error message' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Absent'
                            }
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.EndpointNotFound -f $testParameters.Name)

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                $mockDynamicEndpointName = $mockEndpointName
            }

            Context 'When the system is in the desired state' {
                $mockDynamicPrincipal = $mockPrincipal
                $script:mockMethodGrantRan = $false
                $script:mockMethodRevokeRan = $false

                It 'Should not call Grant() or Revoke() method when desired state is already Present' {
                    $testParameters['Ensure'] = 'Present'
                    $testParameters['Permission'] = 'CONNECT'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodGrantRan | Should -Be $false
                    $script:mockMethodRevokeRan | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                $mockDynamicPrincipal = $mockOtherPrincipal
                $script:mockMethodGrantRan = $false
                $script:mockMethodRevokeRan = $false

                It 'Should not call Grant() or Revoke() method when desired state is already Absent' {
                    $testParameters['Ensure'] = 'Absent'
                    $testParameters['Permission'] = 'CONNECT'

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodGrantRan | Should -Be $false
                    $script:mockMethodRevokeRan | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
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
