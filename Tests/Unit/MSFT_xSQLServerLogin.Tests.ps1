# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]

$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerLogin'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

# Begin Testing
try
{
    #region Pester Test Initialization

    Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force
    Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

    # Create PSCredential object for SQL Logins
    $mockSqlLoginUser = 'dba' 
    $mockSqlLoginPassword = 'P@ssw0rd-12P@ssw0rd-12' | ConvertTo-SecureString -AsPlainText -Force
    $mockSqlLoginCredential = New-Object System.Management.Automation.PSCredential( $mockSqlLoginUser, $mockSqlLoginPassword )

    $mockSqlLoginBadPassword = 'pw' | ConvertTo-SecureString -AsPlainText -Force
    $mockSqlLoginCredentialBadPassword = New-Object System.Management.Automation.PSCredential( $mockSqlLoginUser, $mockSqlLoginBadPassword )

    $mockSqlLoginReusedPassword = 'reused' | ConvertTo-SecureString -AsPlainText -Force
    $mockSqlLoginCredentialReusedPassword = New-Object System.Management.Automation.PSCredential( $mockSqlLoginUser, $mockSqlLoginReusedPassword )

    $mockSqlLoginOtherPassword = 'other' | ConvertTo-SecureString -AsPlainText -Force
    $mockSqlLoginCredentialOtherPassword = New-Object System.Management.Automation.PSCredential( $mockSqlLoginUser, $mockSqlLoginOtherPassword )

    $instanceParameters = @{
        SQLInstanceName = 'MSSQLSERVER'
        SQLServer = 'Server1'
    }

    $getTargetResource_UnknownSqlLogin = $instanceParameters.Clone()
    $getTargetResource_UnknownSqlLogin.Add( 'Name','UnknownSqlLogin' )

    $getTargetResource_UnknownWindows = $instanceParameters.Clone()
    $getTargetResource_UnknownWindows.Add( 'Name','Windows\UserOrGroup' )

    $getTargetResource_KnownSqlLogin = $instanceParameters.Clone()
    $getTargetResource_KnownSqlLogin.Add( 'Name','SqlLogin1' )

    $getTargetResource_KnownWindowsUser = $instanceParameters.Clone()
    $getTargetResource_KnownWindowsUser.Add( 'Name','Windows\User1' )

    $getTargetResource_KnownWindowsGroup = $instanceParameters.Clone()
    $getTargetResource_KnownWindowsGroup.Add( 'Name','Windows\Group1' )

    $testTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
    $testTargetResource_WindowsUserAbsent.Add( 'Name','Windows\UserAbsent' )
    $testTargetResource_WindowsUserAbsent.Add( 'LoginType','WindowsUser' )

    $testTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
    $testTargetResource_WindowsGroupAbsent.Add( 'Name','Windows\GroupAbsent' )
    $testTargetResource_WindowsGroupAbsent.Add( 'LoginType','WindowsGroup' )

    $testTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
    $testTargetResource_SqlLoginAbsent.Add( 'Name','SqlLoginAbsent' )
    $testTargetResource_SqlLoginAbsent.Add( 'LoginType','SqlLogin' )

    $testTargetResource_WindowsUserPresent = $instanceParameters.Clone()
    $testTargetResource_WindowsUserPresent.Add( 'Name','Windows\User1' )
    $testTargetResource_WindowsUserPresent.Add( 'LoginType','WindowsUser' )

    $testTargetResource_WindowsGroupPresent = $instanceParameters.Clone()
    $testTargetResource_WindowsGroupPresent.Add( 'Name','Windows\Group1' )
    $testTargetResource_WindowsGroupPresent.Add( 'LoginType','WindowsGroup' )

    $testTargetResource_SqlLoginPresentWithDefaultValues = $instanceParameters.Clone()
    $testTargetResource_SqlLoginPresentWithDefaultValues.Add( 'Name','SqlLogin1' )
    $testTargetResource_SqlLoginPresentWithDefaultValues.Add( 'LoginType','SqlLogin' )
    
    $setTargetResource_CertificateAbsent = $instanceParameters.Clone()
    $setTargetResource_CertificateAbsent.Add( 'Name','Certificate' )
    $setTargetResource_CertificateAbsent.Add( 'LoginType','Certificate' )
    
    $setTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
    $setTargetResource_WindowsUserAbsent.Add( 'Name','Windows\UserAbsent' )
    $setTargetResource_WindowsUserAbsent.Add( 'LoginType','WindowsUser' )

    $setTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
    $setTargetResource_WindowsGroupAbsent.Add( 'Name','Windows\GroupAbsent' )
    $setTargetResource_WindowsGroupAbsent.Add( 'LoginType','WindowsGroup' )

    $setTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
    $setTargetResource_SqlLoginAbsent.Add( 'Name','SqlLoginAbsent' )
    $setTargetResource_SqlLoginAbsent.Add( 'LoginType','SqlLogin' )

    $setTargetResource_SqlLoginAbsentExisting = $instanceParameters.Clone()
    $setTargetResource_SqlLoginAbsentExisting.Add( 'Name','Existing' )
    $setTargetResource_SqlLoginAbsentExisting.Add( 'LoginType','SqlLogin' )

    $setTargetResource_SqlLoginAbsentUnknown = $instanceParameters.Clone()
    $setTargetResource_SqlLoginAbsentUnknown.Add( 'Name','Unknown' )
    $setTargetResource_SqlLoginAbsentUnknown.Add( 'LoginType','SqlLogin' )
    
    $setTargetResource_WindowsUserPresent = $instanceParameters.Clone()
    $setTargetResource_WindowsUserPresent.Add( 'Name','Windows\User1' )
    $setTargetResource_WindowsUserPresent.Add( 'LoginType','WindowsUser' )

    $setTargetResource_CertificateAbsent = $instanceParameters.Clone()
    $setTargetResource_CertificateAbsent.Add( 'Name','Certificate' )
    $setTargetResource_CertificateAbsent.Add( 'LoginType','Certificate' )
    
    $setTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
    $setTargetResource_WindowsUserAbsent.Add( 'Name','Windows\UserAbsent' )
    $setTargetResource_WindowsUserAbsent.Add( 'LoginType','WindowsUser' )

    $setTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
    $setTargetResource_WindowsGroupAbsent.Add( 'Name','Windows\GroupAbsent' )
    $setTargetResource_WindowsGroupAbsent.Add( 'LoginType','WindowsGroup' )

    $setTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
    $setTargetResource_SqlLoginAbsent.Add( 'Name','SqlLoginAbsent' )
    $setTargetResource_SqlLoginAbsent.Add( 'LoginType','SqlLogin' )

    $setTargetResource_SqlLoginAbsentExisting = $instanceParameters.Clone()
    $setTargetResource_SqlLoginAbsentExisting.Add( 'Name','Existing' )
    $setTargetResource_SqlLoginAbsentExisting.Add( 'LoginType','SqlLogin' )

    $setTargetResource_SqlLoginAbsentUnknown = $instanceParameters.Clone()
    $setTargetResource_SqlLoginAbsentUnknown.Add( 'Name','Unknown' )
    $setTargetResource_SqlLoginAbsentUnknown.Add( 'LoginType','SqlLogin' )
    
    $setTargetResource_WindowsUserPresent = $instanceParameters.Clone()
    $setTargetResource_WindowsUserPresent.Add( 'Name','Windows\User1' )
    $setTargetResource_WindowsUserPresent.Add( 'LoginType','WindowsUser' )

    $setTargetResource_WindowsGroupPresent = $instanceParameters.Clone()
    $setTargetResource_WindowsGroupPresent.Add( 'Name','Windows\Group1' )
    $setTargetResource_WindowsGroupPresent.Add( 'LoginType','WindowsGroup' )

    $setTargetResource_SqlLoginPresent = $instanceParameters.Clone()
    $setTargetResource_SqlLoginPresent.Add( 'Name','SqlLogin1' )
    $setTargetResource_SqlLoginPresent.Add( 'LoginType','SqlLogin' )

    $mockConnectSql = {
        $windowsUser = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Windows\User1' )
        $windowsUser.LoginType = 'WindowsUser'
        $windowsGroup = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Windows\Group1' )
        $windowsGroup.LoginType = 'windowsGroup'
        $sqlLogin = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'SqlLogin1' )
        $sqlLogin.LoginType = 'SqlLogin'
        $sqlLogin.MustChangePassword = $false
        $sqlLogin.PasswordPolicyEnforced = $true
        $sqlLogin.PasswordExpirationEnabled = $true
        
        $mock = New-Object PSObject -Property @{
            LoginMode = 'Mixed'
            Logins = @{
                $windowsUser.Name = $windowsUser
                $windowsGroup.Name = $windowsGroup
                $sqlLogin.Name = $sqlLogin
            }
        }

        return $mock
    }

    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Verifiable -Scope Describe

        Context 'When the login is Absent' {

            It 'Should be Absent when an unknown SQL Login is provided' {
                ( Get-TargetResource @getTargetResource_UnknownSqlLogin ).Ensure | Should Be 'Absent'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be Absent when an unknown Windows User or Group is provided' {
                ( Get-TargetResource @getTargetResource_UnknownWindows ).Ensure | Should Be 'Absent'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }

        Context 'When the login is Present' {
            It 'Should be Present when a known SQL Login is provided' {
                $result = Get-TargetResource @getTargetResource_KnownSqlLogin

                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'SqlLogin'
                $result.LoginMustChangePassword | Should Not BeNullOrEmpty
                $result.LoginPasswordExpirationEnabled | Should Not BeNullOrEmpty
                $result.LoginPasswordPolicyEnforced | Should Not BeNullOrEmpty

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be Present when a known Windows User is provided' {
                $result = Get-TargetResource @getTargetResource_KnownWindowsUser

                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'WindowsUser'
                $result.LoginMustChangePassword | Should BeNullOrEmpty
                $result.LoginPasswordExpirationEnabled | Should BeNullOrEmpty
                $result.LoginPasswordPolicyEnforced | Should BeNullOrEmpty

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be Present when a known Windows User is provided' {
                $result = Get-TargetResource @getTargetResource_KnownWindowsGroup

                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'WindowsGroup'
                $result.LoginMustChangePassword | Should BeNullOrEmpty
                $result.LoginPasswordExpirationEnabled | Should BeNullOrEmpty
                $result.LoginPasswordPolicyEnforced | Should BeNullOrEmpty

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable

        Context 'When the desired state is Absent' {
            It 'Should return $true when the specified Windows user is Absent' {
                $testTargetResource_WindowsUserAbsent_EnsureAbsent = $testTargetResource_WindowsUserAbsent.Clone()
                $testTargetResource_WindowsUserAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsureAbsent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $true when the specified Windows group is Absent' {
                $testTargetResource_WindowsGroupAbsent_EnsureAbsent = $testTargetResource_WindowsGroupAbsent.Clone()
                $testTargetResource_WindowsGroupAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsureAbsent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Absent' {
                $testTargetResource_SqlLoginAbsent_EnsureAbsent = $testTargetResource_SqlLoginAbsent.Clone()
                $testTargetResource_SqlLoginAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsureAbsent ) | Should Be $true 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $false when the specified Windows user is Present' {
                $testTargetResource_WindowsUserPresent_EnsureAbsent = $testTargetResource_WindowsUserPresent.Clone()
                $testTargetResource_WindowsUserPresent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_WindowsUserPresent_EnsureAbsent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $false when the specified Windows group is Present' {
                $testTargetResource_WindowsGroupPresent_EnsureAbsent = $testTargetResource_WindowsGroupPresent.Clone()
                $testTargetResource_WindowsGroupPresent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_WindowsGroupPresent_EnsureAbsent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Present' {
                $testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }
        
        Context 'When the desired state is Present' {
            It 'Should return $false when the specified Windows user is Absent' {
                $testTargetResource_WindowsUserAbsent_EnsurePresent = $testTargetResource_WindowsUserAbsent.Clone()
                $testTargetResource_WindowsUserAbsent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsurePresent ) | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $false when the specified Windows group is Absent' {
                $testTargetResource_WindowsGroupAbsent_EnsurePresent = $testTargetResource_WindowsGroupAbsent.Clone()
                $testTargetResource_WindowsGroupAbsent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsurePresent ) | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Absent' {
                $testTargetResource_SqlLoginAbsent_EnsurePresent = $testTargetResource_SqlLoginAbsent.Clone()
                $testTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsurePresent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $true when the specified Windows user is Present' {
                $testTargetResource_WindowsUserPresent_EnsurePresent = $testTargetResource_WindowsUserPresent.Clone()
                $testTargetResource_WindowsUserPresent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_WindowsUserPresent_EnsurePresent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $true when the specified Windows group is Present' {
                $testTargetResource_WindowsGroupPresent_EnsurePresent = $testTargetResource_WindowsGroupPresent.Clone()
                $testTargetResource_WindowsGroupPresent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_WindowsGroupPresent_EnsurePresent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Present using default parameter values' {
                $testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Present and PasswordExpirationEnabled is $true' {
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent.Add( 'LoginPasswordExpirationEnabled',$true )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent ) | Should Be $true 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Present and PasswordExpirationEnabled is $false' {
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent.Add( 'LoginPasswordExpirationEnabled',$false )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Present and PasswordPolicyEnforced is $true' {
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent.Add( 'LoginPasswordPolicyEnforced',$true )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent ) | Should Be $true 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Present and PasswordPolicyEnforced is $false' {
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent.Add( 'LoginPasswordPolicyEnforced',$false )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Present using default parameter values and the password is properly configured.' {
                $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent.Add( 'LoginCredential',$mockSqlLoginCredential )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent ) | Should Be $true 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 2 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Present using default parameter values and the password is not properly configured.' {
                Mock -CommandName Connect-SQL -MockWith { throw } -ModuleName $script:DSCResourceName -Scope It -Verifiable -ParameterFilter { $SetupCredential }
                
                $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent.Add( 'LoginCredential',$mockSqlLoginCredentialBadpassword )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 2 -Exactly
            }
        }
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName
        Mock -CommandName Update-SQLServerLogin -MockWith {} -ModuleName $script:DSCResourceName
        Mock -CommandName New-SQLServerLogin -MockWith {} -ModuleName $script:DSCResourceName
        Mock -CommandName Remove-SQLServerLogin -MockWith {} -ModuleName $script:DSCResourceName
        Mock -CommandName Set-SQLServerLoginPassword -MockWith {} -ModuleName $script:DSCResourceName

        Context 'When the desired state is Absent' {
            It 'Should drop the specified Windows User when it is Present' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_WindowsUserPresent_EnsureAbsent = $setTargetResource_WindowsUserPresent.Clone()
                $setTargetResource_WindowsUserPresent_EnsureAbsent.Add( 'Ensure','Absent' )

                Set-TargetResource @setTargetResource_WindowsUserPresent_EnsureAbsent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should drop the specified Windows Group when it is Present' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_WindowsGroupPresent_EnsureAbsent = $setTargetResource_WindowsGroupPresent.Clone()
                $setTargetResource_WindowsGroupPresent_EnsureAbsent.Add( 'Ensure','Absent' )

                Set-TargetResource @setTargetResource_WindowsGroupPresent_EnsureAbsent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should drop the specified SQL Login when it is Present' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_SqlLoginPresent_EnsureAbsent = $setTargetResource_SqlLoginPresent.Clone()
                $setTargetResource_SqlLoginPresent_EnsureAbsent.Add( 'Ensure','Absent' )

                Set-TargetResource @setTargetResource_SqlLoginPresent_EnsureAbsent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should do nothing when the specified Windows User is Absent' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_WindwsUserAbsent_EnsureAbsent = $setTargetResource_WindowsUserAbsent.Clone()
                $setTargetResource_WindwsUserAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                Set-TargetResource @setTargetResource_WindwsUserAbsent_EnsureAbsent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should do nothing when the specified Windows Group is Absent' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_WindwsGroupAbsent_EnsureAbsent = $setTargetResource_WindowsGroupAbsent.Clone()
                $setTargetResource_WindwsGroupAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                Set-TargetResource @setTargetResource_WindwsGroupAbsent_EnsureAbsent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should do nothing when the specified SQL Login is Absent' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_SqlLoginAbsent_EnsureAbsent = $setTargetResource_SqlLoginAbsent.Clone()
                $setTargetResource_SqlLoginAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsureAbsent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }
        }

        Context 'When the desired state is Present' {
            It 'Should add the specified Windows User when it is Absent' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_WindowsUserAbsent_EnsurePresent = $setTargetResource_WindowsUserAbsent.Clone()
                $setTargetResource_WindowsUserAbsent_EnsurePresent.Add( 'Ensure','Present' )

                Set-TargetResource @setTargetResource_WindowsUserAbsent_EnsurePresent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should add the specified Windows Group when it is Absent' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_WindowsGroupAbsent_EnsurePresent = $setTargetResource_WindowsGroupAbsent.Clone()
                $setTargetResource_WindowsGroupAbsent_EnsurePresent.Add( 'Ensure','Present' )

                Set-TargetResource @setTargetResource_WindowsGroupAbsent_EnsurePresent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should add the specified SQL Login when it is Absent' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable

                $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
                $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure','Present' )
                $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'LoginCredential',$mockSqlLoginCredential )

                Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should add the specified SQL Login when it is Absent and MustChangePassword is $false' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
                $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure','Present' )
                $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'LoginCredential',$mockSqlLoginCredential )
                $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'LoginMustChangePassword',$false )

                Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error when adding an unsupported login type' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_CertificateAbsent_EnsurePresent = $setTargetResource_CertificateAbsent.Clone()
                $setTargetResource_CertificateAbsent_EnsurePresent.Add( 'Ensure','Present' )

                { Set-TargetResource @setTargetResource_CertificateAbsent_EnsurePresent } | Should Throw 'LoginTypeNotImplemented'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error when adding the specified SQL Login when it is Absent and is missing the LoginCredential parameter' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred = $setTargetResource_SqlLoginAbsent.Clone()
                $setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred.Add( 'Ensure','Present' )

                { Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred } | Should Throw 'LoginCredentialNotFound'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should do nothing if the specified Windows User is Present' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_WindowsUserPresent_EnsurePresent = $setTargetResource_WindowsUserPresent.Clone()
                $setTargetResource_WindowsUserPresent_EnsurePresent.Add( 'Ensure','Present' )

                Set-TargetResource @setTargetResource_WindowsUserPresent_EnsurePresent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should do nothing if the specified Windows Group is Present' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_WindowsGroupPresent_EnsurePresent = $setTargetResource_WindowsGroupPresent.Clone()
                $setTargetResource_WindowsGroupPresent_EnsurePresent.Add( 'Ensure','Present' )

                Set-TargetResource @setTargetResource_WindowsGroupPresent_EnsurePresent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }

            It 'Should update the password of the specified SQL Login if it is Present and all parameters match' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_SqlLoginPresent_EnsurePresent = $setTargetResource_SqlLoginPresent.Clone()
                $setTargetResource_SqlLoginPresent_EnsurePresent.Add( 'Ensure','Present' )
                $setTargetResource_SqlLoginPresent_EnsurePresent.Add( 'LoginCredential',$mockSqlLoginCredential )

                Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 1 -Exactly
            }

            It 'Should set PasswordExpirationEnabled on the specified SQL Login if it does not match the LoginPasswordExpirationEnabled parameter' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled = $setTargetResource_SqlLoginPresent.Clone()
                $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled.Add( 'Ensure','Present' )
                $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled.Add( 'LoginCredential',$mockSqlLoginCredential )
                $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled.Add( 'LoginPasswordExpirationEnabled',$false )

                Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 1 -Exactly
            }

            It 'Should set PasswordPolicyEnforced on the specified SQL Login if it does not match the LoginPasswordPolicyEnforced parameter' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced = $setTargetResource_SqlLoginPresent.Clone()
                $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced.Add( 'Ensure','Present' )
                $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced.Add( 'LoginCredential',$mockSqlLoginCredential )
                $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced.Add( 'LoginPasswordPolicyEnforced',$false )

                Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 1 -Exactly
            }

            It 'Should throw the correct error when creating a SQL Login if the LoginMode is not Mixed' {
                $mockConnectSQL_LoginModeNormal = {
                    return New-Object Object | 
                        Add-Member ScriptProperty Logins {
                            return @{
                                'Windows\User1' = ( New-Object Object | 
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Windows\User1' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsUser' -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
                                )
                                'SqlLogin1' = ( New-Object Object | 
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SqlLogin1' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'SqlLogin' -PassThru | 
                                    Add-Member -MemberType NoteProperty -Name 'MustChangePassword' -Value $false -PassThru | 
                                    Add-Member -MemberType NoteProperty -Name 'PasswordExpirationEnabled' -Value $true -PassThru | 
                                    Add-Member -MemberType NoteProperty -Name 'PasswordPolicyEnforced' -Value $true -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
                                )
                                'Windows\Group1' = ( New-Object Object | 
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Windows\Group1' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsGroup' -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
                                )
                            }
                        } -PassThru |
                        Add-Member -MemberType NoteProperty -Name LoginMode -Value 'Normal' -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL_LoginModeNormal -ModuleName $script:DSCResourceName -Scope It -Verifiable
                
                $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
                $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure','Present' )
                $setTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'LoginCredential',$mockSqlLoginCredential )

                { Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent } | Should Throw 'IncorrectLoginMode'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SQLServerLogin -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Set-SQLServerLoginPassword -Scope It -Times 0 -Exactly
            }
        }
    }

    InModuleScope -ModuleName $script:DSCResourceName {
        Describe "$($script:DSCResourceName)\Update-SQLServerLogin" {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName

            Context 'When the Login is altered' {
                It 'Should silently alter the login' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Domain\User' )
                    $login.LoginType = 'WindowsUser'

                    { Update-SQLServerLogin -Login $login } | Should Not Throw
                }

                It 'Should throw the correct error when altering the login fails' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Domain\User' )
                    $login.LoginType = 'WindowsUser'
                    $login.MockLoginType = 'SqlLogin'

                    { Update-SQLServerLogin -Login $login } | Should Throw 'AlterLoginFailed'
                }
            }
        }

        Describe "$($script:DSCResourceName)\New-SQLServerLogin" {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName
            
            Context 'When the Login is created' {
                It 'Should silently create a Windows login' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Domain\User' )
                    $login.LoginType = 'WindowsUser'
                    $login.MockLoginType = 'WindowsUser'

                    { New-SQLServerLogin -Login $login } | Should Not Throw
                }

                It 'Should silently create a SQL login' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'dba' )
                    $login.LoginType = 'SqlLogin'
                    $login.MockLoginType = 'SqlLogin'
                    
                    $createLoginParams = @{
                        Login = $login
                        SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                        LoginCreateOptions = 'None'
                    }

                    { New-SQLServerLogin @createLoginParams } | Should Not Throw
                }

                It 'Should throw the correct error when login creation fails' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Domain\User' )
                    $login.LoginType = 'WindowsUser'
                    $login.MockLoginType = 'SqlLogin'

                    { New-SQLServerLogin -Login $login } | Should Throw 'LoginCreationFailedWindowsNotSpecified'
                }

                It 'Should throw the correct error when password validation fails when creating a SQL Login' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'dba' )
                    $login.LoginType = 'SqlLogin'
                    
                    $createLoginParams = @{
                        Login = $login
                        SecureString = ConvertTo-SecureString -String 'pw' -AsPlainText -Force
                        LoginCreateOptions = 'None'
                    }

                    { New-SQLServerLogin @createLoginParams } | Should Throw 'PasswordValidationFailed'
                }

                It 'Should throw the correct error when creating a SQL Login fails' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Existing' )
                    $login.LoginType = 'SqlLogin'
                    
                    $createLoginParams = @{
                        Login = $login
                        SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                        LoginCreateOptions = 'None'
                    }

                    { New-SQLServerLogin @createLoginParams } | Should Throw 'LoginCreationFailedFailedOperation'
                }

                It 'Should throw the correct error when creating a SQL Login fails with an unhandled exception' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Unknown' )
                    $login.LoginType = 'SqlLogin'
                    
                    $createLoginParams = @{
                        Login = $login
                        SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                        LoginCreateOptions = 'None'
                    }

                    { New-SQLServerLogin @createLoginParams } | Should Throw 'LoginCreationFailedSqlNotSpecified'
                }
            }
        }

        Describe "$($script:DSCResourceName)\Remove-SQLServerLogin" {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName
            
            Context 'When the Login is dropped' {
                It 'Should silently drop the login' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Domain\User' )
                    $login.LoginType = 'WindowsUser'

                    { Remove-SQLServerLogin -Login $login } | Should Not Throw
                }

                It 'Should throw the correct error when dropping the login fails' {
                    $login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'Domain\User' )
                    $login.LoginType = 'WindowsUser'
                    $login.MockLoginType = 'SqlLogin'

                    { Remove-SQLServerLogin -Login $login } | Should Throw 'DropLoginFailed'
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-SQLServerLoginPassword" {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName

            Context 'When the password is set on an existing login' {
                It 'Should silently set the password' {
                    $setPwParams = @{
                        Login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'dba' )
                        SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                    }
                    
                    { Set-SQLServerLoginPassword @setPwParams } | Should Not Throw
                }

                It 'Should throw the correct error when password validation fails' {
                    $setPwParams = @{
                        Login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'dba' )
                        SecureString = ConvertTo-SecureString -String 'pw' -AsPlainText -Force
                    }
                    
                    { Set-SQLServerLoginPassword @setPwParams } | Should Throw 'PasswordValidationFailed'
                }

                It 'Should throw the correct error when changing the password fails' {
                    $setPwParams = @{
                        Login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'dba' )
                        SecureString = ConvertTo-SecureString -String 'reused' -AsPlainText -Force
                    }
                    
                    { Set-SQLServerLoginPassword @setPwParams } | Should Throw 'PasswordChangeFailed'
                }

                It 'Should throw the correct error when changing the password fails' {
                    $setPwParams = @{
                        Login = New-Object Microsoft.SqlServer.Management.Smo.Login( 'Server', 'dba' )
                        SecureString = ConvertTo-SecureString -String 'other' -AsPlainText -Force
                    }
                    
                    { Set-SQLServerLoginPassword @setPwParams } | Should Throw 'PasswordChangeFailed'
                }
            }
        }
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
