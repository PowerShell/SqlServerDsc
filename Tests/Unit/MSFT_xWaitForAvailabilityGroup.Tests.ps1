$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xWaitForAvailabilityGroup'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockClusterGroupName = 'AGTest'
        $mockRetryInterval = 1
        $mockRetryCount = 2

        $mockOtherClusterGroupName = 'UnknownAG'

        # Function stub of Get-ClusterGroup (when we do not have Failover Cluster powershell module available)
        function Get-ClusterGroup {
            throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
        }

        $mockGetClusterGroup = {
            if ($Name -ne $mockExpectedClusterGroupName)
            {
                throw ('Mock Get-ClusterGroup called with unexpected name. Expected ''{0}'', but was ''{1}''' -f $mockExpectedClusterGroupName, $Name)
            }

            return New-Object -TypeName PSObject -Property @{
                Name = $Name
            }
        }

        $mockGetClusterGroup_ParameterFilter_KnownGroup = {
            $Name -eq $mockClusterGroupName
        }

        $mockGetClusterGroup_ParameterFilter_UnknownGroup = {
            $Name -eq $mockOtherClusterGroupName
        }

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            Name = $mockClusterGroupName
            RetryIntervalSec = $mockRetryInterval
            RetryCount = $mockRetryCount
        }

        Describe 'MSFT_xWaitForAvailabilityGroup\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Get-ClusterGroup -MockWith $mockGetClusterGroup -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup -Verifiable
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return $null
                } -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup -Verifiable
            }

            Context 'When the system is in the desired state' {
                $mockExpectedClusterGroupName = $mockClusterGroupName

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.RetryIntervalSec | Should -Be $mockRetryInterval
                    $result.RetryCount | Should -Be $mockRetryCount
                }

                It 'Should return that the group exist' {
                    $result = Get-TargetResource @testParameters
                    $result.GroupExist | Should -Be $true
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    $testParameters.Name = $mockOtherClusterGroupName
                }

                $mockExpectedClusterGroupName = $mockOtherClusterGroupName

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.RetryIntervalSec | Should -Be $mockRetryInterval
                    $result.RetryCount | Should -Be $mockRetryCount
                }

                It 'Should return that the group does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.GroupExist | Should -Be $false
                }
            }

            Assert-VerifiableMocks
        }


        Describe 'MSFT_xWaitForAvailabilityGroup\Test-TargetResource' -Tag 'Test'{
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Get-ClusterGroup -MockWith $mockGetClusterGroup -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup -Verifiable
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return $null
                } -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup -Verifiable
            }

            $mockExpectedClusterGroupName = $mockClusterGroupName

            Context 'When the system is in the desired state' {
                It 'Should return that desired state is present ($true)' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
                }
            }

            $mockExpectedClusterGroupName = $mockOtherClusterGroupName

            Context 'When the system is not in the desired state' {
                It 'Should return that desired state is absent ($false)' {
                    $testParameters.Name = $mockOtherClusterGroupName

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMocks
        }

        Describe 'MSFT_xWaitForAvailabilityGroup\Set-TargetResource' -Tag 'Set'{
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Start-Sleep
                Mock -CommandName Get-ClusterGroup -MockWith $mockGetClusterGroup -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup -Verifiable
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return $null
                } -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup -Verifiable
            }

            $mockExpectedClusterGroupName =$mockClusterGroupName

            Context 'When the system is in the desired state' {
                It 'Should find the cluster group and return withput throwing' {
                     { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
                }
            }

            $mockExpectedClusterGroupName = $mockOtherClusterGroupName

            Context 'When the system is not in the desired state' {
                It 'Should throw the correct error message' {
                    $testParameters.Name = $mockOtherClusterGroupName

                    { Set-TargetResource @testParameters } | Should -Throw 'Cluster group UnknownAG not found after 2 attempts with 1 sec interval'

                    Assert-MockCalled -CommandName Get-ClusterGroup -Exactly -Times 2 -Scope It
                }
            }

            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}

