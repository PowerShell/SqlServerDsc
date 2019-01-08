<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlServerLogin DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

# This is used to make sure the unit test run in a container.
[Microsoft.DscResourceKit.UnitTest(ContainerName = 'Container2', ContainerImage = 'microsoft/windowsservercore')]
# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlServerLogin'

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
    Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force
    Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )
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
        # Create PSCredential object for SQL Logins
        $mockSqlLoginUser = 'dba'
        $mockSqlLoginPassword = 'P@ssw0rd-12P@ssw0rd-12' | ConvertTo-SecureString -AsPlainText -Force
        $mockSqlLoginCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockSqlLoginUser, $mockSqlLoginPassword)

        $mockSqlLoginBadPassword = 'pw' | ConvertTo-SecureString -AsPlainText -Force
        $mockSqlLoginCredentialBadPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockSqlLoginUser, $mockSqlLoginBadPassword)

        $mockSqlLoginReusedPassword = 'reused' | ConvertTo-SecureString -AsPlainText -Force
        $mockSqlLoginCredentialReusedPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockSqlLoginUser, $mockSqlLoginReusedPassword)

        $mockSqlLoginOtherPassword = 'other' | ConvertTo-SecureString -AsPlainText -Force
        $mockSqlLoginCredentialOtherPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($mockSqlLoginUser, $mockSqlLoginOtherPassword)

        $instanceParameters = @{
            InstanceName = 'MSSQLSERVER'
            ServerName   = 'Server1'
        }

        $getTargetResource_UnknownSqlLogin = $instanceParameters.Clone()
        $getTargetResource_UnknownSqlLogin.Add( 'Name', 'UnknownSqlLogin' )

        $getTargetResource_UnknownWindows = $instanceParameters.Clone()
        $getTargetResource_UnknownWindows.Add( 'Name', 'Windows\UserOrGroup' )

        $getTargetResource_KnownSqlLogin = $instanceParameters.Clone()
        $getTargetResource_KnownSqlLogin.Add( 'Name', 'SqlLogin1' )

        $getTargetResource_KnownWindowsUser = $instanceParameters.Clone()
        $getTargetResource_KnownWindowsUser.Add( 'Name', 'Windows\User1' )

        $getTargetResource_KnownWindowsGroup = $instanceParameters.Clone()
        $getTargetResource_KnownWindowsGroup.Add( 'Name', 'Windows\Group1' )

        $testTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
        $testTargetResource_WindowsUserAbsent.Add( 'Name', 'Windows\UserAbsent' )
        $testTargetResource_WindowsUserAbsent.Add( 'LoginType', 'WindowsUser' )

        $testTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
        $testTargetResource_WindowsGroupAbsent.Add( 'Name', 'Windows\GroupAbsent' )
        $testTargetResource_WindowsGroupAbsent.Add( 'LoginType', 'WindowsGroup' )

        $testTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
        $testTargetResource_SqlLoginAbsent.Add( 'Name', 'SqlLoginAbsent' )
        $testTargetResource_SqlLoginAbsent.Add( 'LoginType', 'SqlLogin' )

        $testTargetResource_WindowsUserPresent = $instanceParameters.Clone()
        $testTargetResource_WindowsUserPresent.Add( 'Name', 'Windows\User1' )
        $testTargetResource_WindowsUserPresent.Add( 'LoginType', 'WindowsUser' )

        $testTargetResource_WindowsGroupPresent = $instanceParameters.Clone()
        $testTargetResource_WindowsGroupPresent.Add( 'Name', 'Windows\Group1' )
        $testTargetResource_WindowsGroupPresent.Add( 'LoginType', 'WindowsGroup' )

        $testTargetResource_SqlLoginPresentWithDefaultValues = $instanceParameters.Clone()
        $testTargetResource_SqlLoginPresentWithDefaultValues.Add( 'Name', 'SqlLogin1' )
        $testTargetResource_SqlLoginPresentWithDefaultValues.Add( 'LoginType', 'SqlLogin' )

        $setTargetResource_CertificateAbsent = $instanceParameters.Clone()
        $setTargetResource_CertificateAbsent.Add( 'Name', 'Certificate' )
        $setTargetResource_CertificateAbsent.Add( 'LoginType', 'Certificate' )

        $setTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
        $setTargetResource_WindowsUserAbsent.Add( 'Name', 'Windows\UserAbsent' )
        $setTargetResource_WindowsUserAbsent.Add( 'LoginType', 'WindowsUser' )

        $setTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
        $setTargetResource_WindowsGroupAbsent.Add( 'Name', 'Windows\GroupAbsent' )
        $setTargetResource_WindowsGroupAbsent.Add( 'LoginType', 'WindowsGroup' )

        $setTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
        $setTargetResource_SqlLoginAbsent.Add( 'Name', 'SqlLoginAbsent' )
        $setTargetResource_SqlLoginAbsent.Add( 'LoginType', 'SqlLogin' )

        $setTargetResource_SqlLoginAbsentExisting = $instanceParameters.Clone()
        $setTargetResource_SqlLoginAbsentExisting.Add( 'Name', 'Existing' )
        $setTargetResource_SqlLoginAbsentExisting.Add( 'LoginType', 'SqlLogin' )

        $setTargetResource_SqlLoginAbsentUnknown = $instanceParameters.Clone()
        $setTargetResource_SqlLoginAbsentUnknown.Add( 'Name', 'Unknown' )
        $setTargetResource_SqlLoginAbsentUnknown.Add( 'LoginType', 'SqlLogin' )

        $setTargetResource_WindowsUserPresent = $instanceParameters.Clone()
        $setTargetResource_WindowsUserPresent.Add( 'Name', 'Windows\User1' )
        $setTargetResource_WindowsUserPresent.Add( 'LoginType', 'WindowsUser' )

        $setTargetResource_CertificateAbsent = $instanceParameters.Clone()
        $setTargetResource_CertificateAbsent.Add( 'Name', 'Certificate' )
        $setTargetResource_CertificateAbsent.Add( 'LoginType', 'Certificate' )

        $setTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
        $setTargetResource_WindowsUserAbsent.Add( 'Name', 'Windows\UserAbsent' )
        $setTargetResource_WindowsUserAbsent.Add( 'LoginType', 'WindowsUser' )

        $setTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
        $setTargetResource_WindowsGroupAbsent.Add( 'Name', 'Windows\GroupAbsent' )
        $setTargetResource_WindowsGroupAbsent.Add( 'LoginType', 'WindowsGroup' )

        $setTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
        $setTargetResource_SqlLoginAbsent.Add( 'Name', 'SqlLoginAbsent' )
        $setTargetResource_SqlLoginAbsent.Add( 'LoginType', 'SqlLogin' )

        $setTargetResource_SqlLoginAbsentExisting = $instanceParameters.Clone()
        $setTargetResource_SqlLoginAbsentExisting.Add( 'Name', 'Existing' )
        $setTargetResource_SqlLoginAbsentExisting.Add( 'LoginType', 'SqlLogin' )

        $setTargetResource_SqlLoginAbsentUnknown = $instanceParameters.Clone()
        $setTargetResource_SqlLoginAbsentUnknown.Add( 'Name', 'Unknown' )
        $setTargetResource_SqlLoginAbsentUnknown.Add( 'LoginType', 'SqlLogin' )

        $setTargetResource_WindowsUserPresent = $instanceParameters.Clone()
        $setTargetResource_WindowsUserPresent.Add( 'Name', 'Windows\User1' )
        $setTargetResource_WindowsUserPresent.Add( 'LoginType', 'WindowsUser' )

        $setTargetResource_WindowsGroupPresent = $instanceParameters.Clone()
        $setTargetResource_WindowsGroupPresent.Add( 'Name', 'Windows\Group1' )
        $setTargetResource_WindowsGroupPresent.Add( 'LoginType', 'WindowsGroup' )

        $setTargetResource_SqlLoginPresent = $instanceParameters.Clone()
        $setTargetResource_SqlLoginPresent.Add( 'Name', 'SqlLogin1' )
        $setTargetResource_SqlLoginPresent.Add( 'LoginType', 'SqlLogin' )

        <#
            These are set when the mocked methods Enable() and Disabled() are called.
            Can be used to verify that the method was actually called or not called.
        #>
        $script:mockWasLoginClassMethodEnableCalled = $false
        $script:mockWasLoginClassMethodDisabledCalled = $false

        $mockConnectSql = {
            $windowsUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Windows\User1')
            $windowsUser.LoginType = 'WindowsUser'
            $windowsUser = $windowsUser | Add-Member -Name 'Disable' -MemberType ScriptMethod -Value {
                $script:mockWasLoginClassMethodDisabledCalled = $true
            } -PassThru -Force

            $windowsGroup = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList ('Server', 'Windows\Group1')
            $windowsGroup.LoginType = 'windowsGroup'

            $sqlLogin = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'SqlLogin1')
            $sqlLogin.LoginType = 'SqlLogin'
            $sqlLogin.MustChangePassword = $false
            $sqlLogin.PasswordPolicyEnforced = $true
            $sqlLogin.PasswordExpirationEnabled = $true

            $sqlLoginDisabled = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Windows\UserDisabled')
            $sqlLoginDisabled.LoginType = 'WindowsUser'
            $sqlLoginDisabled.IsDisabled = $true
            $sqlLoginDisabled = $sqlLoginDisabled | Add-Member -Name 'Enable' -MemberType ScriptMethod -Value {
                $script:mockWasLoginClassMethodEnableCalled = $true
            } -PassThru -Force

            $mock = New-Object -TypeName PSObject -Property @{
                LoginMode = 'Mixed'
                Logins = @{
                    $windowsUser.Name = $windowsUser
                    $windowsGroup.Name = $windowsGroup
                    $sqlLogin.Name = $sqlLogin
                    $sqlLoginDisabled.Name = $sqlLoginDisabled
                }
            }

            return $mock
        }

        $mockAccountDisabledException = New-Object System.Exception 'Account disabled'
        $mockAccountDisabledException | Add-Member -Name 'Number' -Value 18470 -MemberType NoteProperty
        #endregion Pester Test Initialization

        Describe 'MSFT_SqlServerLogin\Get-TargetResource' {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            Context 'When the login is Absent' {

                It 'Should be Absent when an unknown SQL Login is provided' {
                    ( Get-TargetResource @getTargetResource_UnknownSqlLogin ).Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be Absent when an unknown Windows User or Group is provided' {
                    ( Get-TargetResource @getTargetResource_UnknownWindows ).Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }

            Context 'When the login is Present' {
                It 'Should be Present when a known SQL Login is provided' {
                    $result = Get-TargetResource @getTargetResource_KnownSqlLogin

                    $result.Ensure | Should -Be 'Present'
                    $result.LoginType | Should -Be 'SqlLogin'
                    $result.LoginMustChangePassword | Should -Not -BeNullOrEmpty
                    $result.LoginPasswordExpirationEnabled | Should -Not -BeNullOrEmpty
                    $result.LoginPasswordPolicyEnforced | Should -Not -BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be Present when a known Windows User is provided' {
                    $result = Get-TargetResource @getTargetResource_KnownWindowsUser

                    $result.Ensure | Should -Be 'Present'
                    $result.LoginType | Should -Be 'WindowsUser'
                    $result.LoginMustChangePassword | Should -BeNullOrEmpty
                    $result.LoginPasswordExpirationEnabled | Should -BeNullOrEmpty
                    $result.LoginPasswordPolicyEnforced | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be Present when a known Windows Group is provided' {
                    $result = Get-TargetResource @getTargetResource_KnownWindowsGroup

                    $result.Ensure | Should -Be 'Present'
                    $result.LoginType | Should -Be 'WindowsGroup'
                    $result.LoginMustChangePassword | Should -BeNullOrEmpty
                    $result.LoginPasswordExpirationEnabled | Should -BeNullOrEmpty
                    $result.LoginPasswordPolicyEnforced | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be return the correct values when a login is disabled' {
                    $mockGetTargetResourceParameters = $instanceParameters.Clone()
                    $mockGetTargetResourceParameters.Add( 'Name', 'Windows\UserDisabled' )
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                    $result.LoginType | Should -Be 'WindowsUser'
                    $result.LoginMustChangePassword | Should -BeNullOrEmpty
                    $result.LoginPasswordExpirationEnabled | Should -BeNullOrEmpty
                    $result.LoginPasswordPolicyEnforced | Should -BeNullOrEmpty
                    $result.Disabled | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'MSFT_SqlServerLogin\Test-TargetResource' {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            Context 'When the desired state is Absent' {
                It 'Should return $true when the specified Windows user is Absent' {
                    $testTargetResource_WindowsUserAbsent_EnsureAbsent = $testTargetResource_WindowsUserAbsent.Clone()
                    $testTargetResource_WindowsUserAbsent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsureAbsent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the specified Windows group is Absent' {
                    $testTargetResource_WindowsGroupAbsent_EnsureAbsent = $testTargetResource_WindowsGroupAbsent.Clone()
                    $testTargetResource_WindowsGroupAbsent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsureAbsent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the specified SQL Login is Absent' {
                    $testTargetResource_SqlLoginAbsent_EnsureAbsent = $testTargetResource_SqlLoginAbsent.Clone()
                    $testTargetResource_SqlLoginAbsent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsureAbsent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the specified Windows user is Present' {
                    $testTargetResource_WindowsUserPresent_EnsureAbsent = $testTargetResource_WindowsUserPresent.Clone()
                    $testTargetResource_WindowsUserPresent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    ( Test-TargetResource @testTargetResource_WindowsUserPresent_EnsureAbsent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the specified Windows group is Present' {
                    $testTargetResource_WindowsGroupPresent_EnsureAbsent = $testTargetResource_WindowsGroupPresent.Clone()
                    $testTargetResource_WindowsGroupPresent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    ( Test-TargetResource @testTargetResource_WindowsGroupPresent_EnsureAbsent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the specified SQL Login is Present' {
                    $testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                    $testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be return $false when a login should be disabled but are enabled' {
                    $mockTestTargetResourceParameters = $instanceParameters.Clone()
                    $mockTestTargetResourceParameters.Add( 'Ensure', 'Present' )
                    $mockTestTargetResourceParameters.Add( 'Name', 'Windows\User1' )
                    $mockTestTargetResourceParameters.Add( 'Disabled', $true )

                    $result = Test-TargetResource @mockTestTargetResourceParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be return $false when a login should be enabled but are disabled' {
                    $mockTestTargetResourceParameters = $instanceParameters.Clone()
                    $mockTestTargetResourceParameters.Add( 'Ensure', 'Present' )
                    $mockTestTargetResourceParameters.Add( 'Name', 'Windows\UserDisabled' )
                    $mockTestTargetResourceParameters.Add( 'Disabled', $false )

                    $result = Test-TargetResource @mockTestTargetResourceParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be return $true when a login should be present but disabled' {
                    $mockTestTargetResourceParameters = $getTargetResource_KnownSqlLogin.Clone()
                    $mockTestTargetResourceParameters.Add('Ensure', 'Present')
                    $mockTestTargetResourceParameters.Add('Disabled', $true)
                    $mockTestTargetResourceParameters.Add('LoginType', 'SqlLogin')

                    # Override mock declaration
                    Mock -CommandName Connect-SQL -MockWith {return $mockAccountDisabledException} 

                    # Override Get-TargetResource
                    Mock -CommandName Get-TargetResource {return @{
                        Ensure       = 'Present'
                        Name         = $mockTestTargetResourceParameters.Name
                        LoginType    = $mockTestTargetResourceParameters.LoginType
                        ServerName   = 'Server1'
                        InstanceName = 'MSSQLERVER'
                        Disabled     = $true
                        LoginMustChangePassword = $false
                        PasswordExpirationEnabled = $true
                        PasswordPolicyEnforced = $true
                      }
                    }

                    # Call the test target
                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    Assert-MockCalled -CommandName Get-TargetResource -Scope It -Times 1 -Exactly
                    Assert-MockCAlled -CommandName Connect-SQL -Scope It -Times 1 -Exactly

                    # Should be true
                    $result | Should -Be $true

                }
            }

            Context 'When the desired state is Present' {
                It 'Should return $false when the specified Windows user is Absent' {
                    $testTargetResource_WindowsUserAbsent_EnsurePresent = $testTargetResource_WindowsUserAbsent.Clone()
                    $testTargetResource_WindowsUserAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should not be checking login properties when Windows user is Absent' {
                    Mock -CommandName New-VerboseMessage -ParameterFilter {$message.contains('rather than WindowsUser')}

                    $testTargetResource_WindowsUserAbsent_EnsurePresent = $testTargetResource_WindowsUserAbsent.Clone()
                    $testTargetResource_WindowsUserAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName New-VerboseMessage -Scope It -Times 0 -Exactly
                }

                It 'Should return $false when the specified Windows group is Absent' {
                    $testTargetResource_WindowsGroupAbsent_EnsurePresent = $testTargetResource_WindowsGroupAbsent.Clone()
                    $testTargetResource_WindowsGroupAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should not be checking login properties when Windows group is Absent' {
                    Mock -CommandName New-VerboseMessage -ParameterFilter {$message.contains('rather than WindowsGroup')}

                    $testTargetResource_WindowsGroupAbsent_EnsurePresent = $testTargetResource_WindowsGroupAbsent.Clone()
                    $testTargetResource_WindowsGroupAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName New-VerboseMessage -Scope It -Times 0 -Exactly
                }

                It 'Should return $false when the specified SQL Login is Absent' {
                    $testTargetResource_SqlLoginAbsent_EnsurePresent = $testTargetResource_SqlLoginAbsent.Clone()
                    $testTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should not be checking login properties when SQL Login is Absent' {
                    Mock -CommandName New-VerboseMessage -ParameterFilter {$message.contains('rather than SqlLogin')}

                    $testTargetResource_SqlLoginAbsent_EnsurePresent = $testTargetResource_SqlLoginAbsent.Clone()
                    $testTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName New-VerboseMessage -Scope It -Times 0 -Exactly
                }

                It 'Should return $true when the specified Windows user is Present' {
                    $testTargetResource_WindowsUserPresent_EnsurePresent = $testTargetResource_WindowsUserPresent.Clone()
                    $testTargetResource_WindowsUserPresent_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_WindowsUserPresent_EnsurePresent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the specified Windows group is Present' {
                    $testTargetResource_WindowsGroupPresent_EnsurePresent = $testTargetResource_WindowsGroupPresent.Clone()
                    $testTargetResource_WindowsGroupPresent_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_WindowsGroupPresent_EnsurePresent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the specified SQL Login is Present using default parameter values' {
                    $testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                    $testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent.Add( 'Ensure', 'Present' )

                    ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the specified SQL Login is Present and PasswordExpirationEnabled is $true' {
                    $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                    $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent.Add( 'Ensure', 'Present' )
                    $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent.Add( 'LoginPasswordExpirationEnabled', $true )

                    ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the specified SQL Login is Present and PasswordExpirationEnabled is $false' {
                    $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                    $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent.Add( 'Ensure', 'Present' )
                    $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent.Add( 'LoginPasswordExpirationEnabled', $false )

                    ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the specified SQL Login is Present and PasswordPolicyEnforced is $true' {
                    $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                    $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent.Add( 'Ensure', 'Present' )
                    $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent.Add( 'LoginPasswordPolicyEnforced', $true )

                    ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $false when the specified SQL Login is Present and PasswordPolicyEnforced is $false' {
                    $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                    $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent.Add( 'Ensure', 'Present' )
                    $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent.Add( 'LoginPasswordPolicyEnforced', $false )

                    ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return $true when the specified SQL Login is Present using default parameter values and the password is properly configured.' {
                    $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                    $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent.Add( 'Ensure', 'Present' )
                    $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent.Add( 'LoginCredential', $mockSqlLoginCredential )

                    ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent ) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                }

                It 'Should return $false when the specified SQL Login is Present using default parameter values and the password is not properly configured.' {
                    Mock -CommandName Connect-SQL -MockWith { throw } -Verifiable -ParameterFilter { $SetupCredential }

                    $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                    $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent.Add( 'Ensure', 'Present' )
                    $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent.Add( 'LoginCredential', $mockSqlLoginCredentialBadPassword )

                    ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent ) | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
                }

                It 'Should be return $true when a login is enabled' {
                    $mockTestTargetResourceParameters = $instanceParameters.Clone()
                    $mockTestTargetResourceParameters.Add( 'Ensure', 'Present' )
                    $mockTestTargetResourceParameters.Add( 'Name', 'Windows\User1' )
                    $mockTestTargetResourceParameters.Add( 'Disabled', $false )

                    $result = Test-TargetResource @mockTestTargetResourceParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be return $true when a login is disabled' {
                    $mockTestTargetResourceParameters = $instanceParameters.Clone()
                    $mockTestTargetResourceParameters.Add( 'Ensure', 'Present' )
                    $mockTestTargetResourceParameters.Add( 'Name', 'Windows\UserDisabled' )
                    $mockTestTargetResourceParameters.Add( 'Disabled', $true )

                    $result = Test-TargetResource @mockTestTargetResourceParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'MSFT_SqlServerLogin\Set-TargetResource' {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName
            Mock -CommandName Update-SQLServerLogin -ModuleName $script:DSCResourceName
            Mock -CommandName New-SQLServerLogin -ModuleName $script:DSCResourceName
            Mock -CommandName Remove-SQLServerLogin -ModuleName $script:DSCResourceName
            Mock -CommandName Set-SQLServerLoginPassword -ModuleName $script:DSCResourceName

            Context 'When the desired state is Absent' {
                BeforeEach {
                    $script:mockWasLoginClassMethodEnableCalled = $false
                    $script:mockWasLoginClassMethodDisabledCalled = $false
                }

                It 'Should drop the specified Windows User when it is Present' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_WindowsUserPresent_EnsureAbsent = $setTargetResource_WindowsUserPresent.Clone()
                    $setTargetResource_WindowsUserPresent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    Set-TargetResource @setTargetResource_WindowsUserPresent_EnsureAbsent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should enable the specified Windows User when it is disabled' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $mockSetTargetResourceParameters = $instanceParameters.Clone()
                    $mockSetTargetResourceParameters.Add( 'Ensure', 'Present' )
                    $mockSetTargetResourceParameters.Add( 'Name', 'Windows\UserDisabled' )
                    $mockSetTargetResourceParameters.Add( 'Disabled', $false )

                    Set-TargetResource @mockSetTargetResourceParameters
                    $script:mockWasLoginClassMethodEnableCalled | Should -Be $true
                    $script:mockWasLoginClassMethodDisabledCalled | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should disable the specified Windows User when it is enabled' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $mockSetTargetResourceParameters = $instanceParameters.Clone()
                    $mockSetTargetResourceParameters.Add( 'Ensure', 'Present' )
                    $mockSetTargetResourceParameters.Add( 'Name', 'Windows\User1' )
                    $mockSetTargetResourceParameters.Add( 'Disabled', $true )

                    Set-TargetResource @mockSetTargetResourceParameters
                    $script:mockWasLoginClassMethodEnableCalled | Should -Be $false
                    $script:mockWasLoginClassMethodDisabledCalled | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should drop the specified Windows Group when it is Present' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_WindowsGroupPresent_EnsureAbsent = $setTargetResource_WindowsGroupPresent.Clone()
                    $setTargetResource_WindowsGroupPresent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    Set-TargetResource @setTargetResource_WindowsGroupPresent_EnsureAbsent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should drop the specified SQL Login when it is Present' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_SqlLoginPresent_EnsureAbsent = $setTargetResource_SqlLoginPresent.Clone()
                    $setTargetResource_SqlLoginPresent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    Set-TargetResource @setTargetResource_SqlLoginPresent_EnsureAbsent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should do nothing when the specified Windows User is Absent' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_WindowsUserAbsent_EnsureAbsent = $setTargetResource_WindowsUserAbsent.Clone()
                    $setTargetResource_WindowsUserAbsent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    Set-TargetResource @setTargetResource_WindowsUserAbsent_EnsureAbsent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should do nothing when the specified Windows Group is Absent' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_WindowsGroupAbsent_EnsureAbsent = $setTargetResource_WindowsGroupAbsent.Clone()
                    $setTargetResource_WindowsGroupAbsent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    Set-TargetResource @setTargetResource_WindowsGroupAbsent_EnsureAbsent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should do nothing when the specified SQL Login is Absent' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_SqlLoginAbsent_EnsureAbsent = $setTargetResource_SqlLoginAbsent.Clone()
                    $setTargetResource_SqlLoginAbsent_EnsureAbsent.Add( 'Ensure', 'Absent' )

                    Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsureAbsent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the desired state is Present' {
                BeforeEach {
                    $script:mockWasLoginClassMethodEnableCalled = $false
                    $script:mockWasLoginClassMethodDisabledCalled = $false
                }

                It 'Should add the specified Windows User when it is Absent' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_WindowsUserAbsent_EnsurePresent = $setTargetResource_WindowsUserAbsent.Clone()
                    $setTargetResource_WindowsUserAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    Set-TargetResource @setTargetResource_WindowsUserAbsent_EnsurePresent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should add the specified Windows User as disabled when it is Absent' {
                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName PSObject -Property @{
                            Logins = @{}
                        }
                    }-Verifiable

                    Mock -CommandName New-Object -MockWith {
                        $windowsUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Windows\User1')
                        $windowsUser = $windowsUser | Add-Member -Name 'Disable' -MemberType ScriptMethod -Value {
                            $script:mockWasLoginClassMethodDisabledCalled = $true
                        } -PassThru -Force

                        return $windowsUser
                    } -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Login' -and $ArgumentList[1] -eq 'Windows\UserAbsent'
                    }-Verifiable

                    $mockSetTargetResourceParameters = $instanceParameters.Clone()
                    $mockSetTargetResourceParameters.Add( 'Ensure', 'Present' )
                    $mockSetTargetResourceParameters.Add( 'Name', 'Windows\UserAbsent' )
                    $mockSetTargetResourceParameters.Add( 'Disabled', $true )

                    Set-TargetResource @mockSetTargetResourceParameters
                    $script:mockWasLoginClassMethodDisabledCalled | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should add the specified Windows Group when it is Absent' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_WindowsGroupAbsent_EnsurePresent = $setTargetResource_WindowsGroupAbsent.Clone()
                    $setTargetResource_WindowsGroupAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    Set-TargetResource @setTargetResource_WindowsGroupAbsent_EnsurePresent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should add the specified SQL Login when it is Absent' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
                    $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure', 'Present' )
                    $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'LoginCredential', $mockSqlLoginCredential )

                    Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should add the specified SQL Login when it is Absent and MustChangePassword is $false' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
                    $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure', 'Present' )
                    $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'LoginCredential', $mockSqlLoginCredential )
                    $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'LoginMustChangePassword', $false )

                    Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error when adding an unsupported login type' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_CertificateAbsent_EnsurePresent = $setTargetResource_CertificateAbsent.Clone()
                    $setTargetResource_CertificateAbsent_EnsurePresent.Add( 'Ensure', 'Present' )

                    { Set-TargetResource @setTargetResource_CertificateAbsent_EnsurePresent } | Should -Throw 'LoginTypeNotImplemented'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error when adding the specified SQL Login when it is Absent and is missing the LoginCredential parameter' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred = $setTargetResource_SqlLoginAbsent.Clone()
                    $setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred.Add( 'Ensure', 'Present' )

                    { Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred } | Should -Throw 'LoginCredentialNotFound'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should do nothing if the specified Windows User is Present' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_WindowsUserPresent_EnsurePresent = $setTargetResource_WindowsUserPresent.Clone()
                    $setTargetResource_WindowsUserPresent_EnsurePresent.Add( 'Ensure', 'Present' )

                    Set-TargetResource @setTargetResource_WindowsUserPresent_EnsurePresent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should do nothing if the specified Windows Group is Present' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_WindowsGroupPresent_EnsurePresent = $setTargetResource_WindowsGroupPresent.Clone()
                    $setTargetResource_WindowsGroupPresent_EnsurePresent.Add( 'Ensure', 'Present' )

                    Set-TargetResource @setTargetResource_WindowsGroupPresent_EnsurePresent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }

                It 'Should update the password of the specified SQL Login if it is Present and all parameters match' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_SqlLoginPresent_EnsurePresent = $setTargetResource_SqlLoginPresent.Clone()
                    $setTargetResource_SqlLoginPresent_EnsurePresent.Add( 'Ensure', 'Present' )
                    $setTargetResource_SqlLoginPresent_EnsurePresent.Add( 'LoginCredential', $mockSqlLoginCredential )

                    Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 1 -Exactly
                }

                It 'Should set PasswordExpirationEnabled on the specified SQL Login if it does not match the LoginPasswordExpirationEnabled parameter' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled = $setTargetResource_SqlLoginPresent.Clone()
                    $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled.Add( 'Ensure', 'Present' )
                    $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled.Add( 'LoginCredential', $mockSqlLoginCredential )
                    $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled.Add( 'LoginPasswordExpirationEnabled', $false )

                    Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 1 -Exactly
                }

                It 'Should set PasswordPolicyEnforced on the specified SQL Login if it does not match the LoginPasswordPolicyEnforced parameter' {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced = $setTargetResource_SqlLoginPresent.Clone()
                    $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced.Add( 'Ensure', 'Present' )
                    $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced.Add( 'LoginCredential', $mockSqlLoginCredential )
                    $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced.Add( 'LoginPasswordPolicyEnforced', $false )

                    Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 1 -Exactly
                }

                It 'Should throw the correct error when creating a SQL Login if the LoginMode is not Mixed' {
                    $mockConnectSQL_LoginModeNormal = {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType ScriptProperty -Name Logins -Value {
                            return @{
                                'Windows\User1' = ( New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Windows\User1' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsUser' -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
                                )
                                'SqlLogin1' = ( New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SqlLogin1' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'SqlLogin' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'MustChangePassword' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'PasswordExpirationEnabled' -Value $true -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'PasswordPolicyEnforced' -Value $true -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
                                )
                                'Windows\Group1' = ( New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Windows\Group1' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsGroup' -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
                                )
                            }
                        } -PassThru |
                            Add-Member -MemberType NoteProperty -Name LoginMode -Value 'Normal' -PassThru -Force
                    }

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL_LoginModeNormal -Verifiable

                    $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
                    $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure', 'Present' )
                    $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'LoginCredential', $mockSqlLoginCredential )

                    { Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent } | Should -Throw 'IncorrectLoginMode'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
                }
            }
        }

        Describe 'MSFT_SqlServerLogin\Update-SQLServerLogin' {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName

            Context 'When the Login is altered' {
                It 'Should silently alter the login' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Domain\User')
                    $login.LoginType = 'WindowsUser'

                    { Update-SQLServerLogin -Login $login } | Should -Not -Throw
                }

                It 'Should throw the correct error when altering the login fails' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Domain\User')
                    $login.LoginType = 'WindowsUser'
                    $login.MockLoginType = 'SqlLogin'

                    { Update-SQLServerLogin -Login $login } | Should -Throw 'AlterLoginFailed'
                }
            }
        }

        Describe 'MSFT_SqlServerLogin\New-SQLServerLogin' {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName

            Context 'When the Login is created' {
                It 'Should silently create a Windows login' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Domain\User')
                    $login.LoginType = 'WindowsUser'
                    $login.MockLoginType = 'WindowsUser'

                    { New-SQLServerLogin -Login $login } | Should -Not -Throw
                }

                It 'Should silently create a SQL login' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'dba')
                    $login.LoginType = 'SqlLogin'
                    $login.MockLoginType = 'SqlLogin'

                    $createLoginParameters = @{
                        Login = $login
                        SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                        LoginCreateOptions = 'None'
                    }

                    { New-SQLServerLogin @createLoginParameters } | Should -Not -Throw
                }

                It 'Should throw the correct error when login creation fails' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Domain\User')
                    $login.LoginType = 'WindowsUser'
                    $login.MockLoginType = 'SqlLogin'

                    { New-SQLServerLogin -Login $login } | Should -Throw 'LoginCreationFailedWindowsNotSpecified'
                }

                It 'Should throw the correct error when password validation fails when creating a SQL Login' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'dba')
                    $login.LoginType = 'SqlLogin'

                    $createLoginParameters = @{
                        Login = $login
                        SecureString = ConvertTo-SecureString -String 'pw' -AsPlainText -Force
                        LoginCreateOptions = 'None'
                    }

                    { New-SQLServerLogin @createLoginParameters } | Should -Throw 'PasswordValidationFailed'
                }

                It 'Should throw the correct error when creating a SQL Login fails' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Existing')
                    $login.LoginType = 'SqlLogin'

                    $createLoginParameters = @{
                        Login = $login
                        SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                        LoginCreateOptions = 'None'
                    }

                    { New-SQLServerLogin @createLoginParameters } | Should -Throw 'LoginCreationFailedFailedOperation'
                }

                It 'Should throw the correct error when creating a SQL Login fails with an unhandled exception' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Unknown')
                    $login.LoginType = 'SqlLogin'

                    $createLoginParameters = @{
                        Login = $login
                        SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                        LoginCreateOptions = 'None'
                    }

                    { New-SQLServerLogin @createLoginParameters } | Should -Throw 'LoginCreationFailedSqlNotSpecified'
                }
            }
        }

        Describe 'MSFT_SqlServerLogin\Remove-SQLServerLogin' {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName

            Context 'When the Login is dropped' {
                It 'Should silently drop the login' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Domain\User')
                    $login.LoginType = 'WindowsUser'

                    { Remove-SQLServerLogin -Login $login } | Should -Not -Throw
                }

                It 'Should throw the correct error when dropping the login fails' {
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'Domain\User')
                    $login.LoginType = 'WindowsUser'
                    $login.MockLoginType = 'SqlLogin'

                    { Remove-SQLServerLogin -Login $login } | Should -Throw 'DropLoginFailed'
                }
            }
        }

        Describe 'MSFT_SqlServerLogin\Set-SQLServerLoginPassword' {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName

            Context 'When the password is set on an existing login' {
                It 'Should silently set the password' {
                    $setPasswordParameters = @{
                        Login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'dba')
                        SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                    }

                    { Set-SQLServerLoginPassword @setPasswordParameters } | Should -Not -Throw
                }

                It 'Should throw the correct error when password validation fails' {
                    $setPasswordParameters = @{
                        Login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'dba')
                        SecureString = ConvertTo-SecureString -String 'pw' -AsPlainText -Force
                    }

                    { Set-SQLServerLoginPassword @setPasswordParameters } | Should -Throw 'PasswordValidationFailed'
                }

                It 'Should throw the correct error when changing the password fails' {
                    $setPasswordParameters = @{
                        Login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'dba')
                        SecureString = ConvertTo-SecureString -String 'reused' -AsPlainText -Force
                    }

                    { Set-SQLServerLoginPassword @setPasswordParameters } | Should -Throw 'PasswordChangeFailed'
                }

                It 'Should throw the correct error when changing the password fails' {
                    $setPasswordParameters = @{
                        Login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @('Server', 'dba')
                        SecureString = ConvertTo-SecureString -String 'other' -AsPlainText -Force
                    }

                    { Set-SQLServerLoginPassword @setPasswordParameters } | Should -Throw 'PasswordChangeFailed'
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
