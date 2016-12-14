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

    # Create PSCredential object for SQL Logins
    $mockSqlLoginUser = "dba" 
    $mockSqlLoginPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
    $mockSqlLoginCredential = New-Object System.Management.Automation.PSCredential( $mockSqlLoginUser, $mockSqlLoginPassword )

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

    #$testTargetResource_SqlLoginPresent.Add( 'LoginMustChangePassword',$true )
    #$testTargetResource_SqlLoginPresent.Add( 'LoginPasswordExpirationEnabled',$true )
    #$testTargetResource_SqlLoginPresent.Add( 'LoginPasswordPolicyEnforced',$true )

    $mockConnectSQL = {
		return New-Object Object | 
			Add-Member ScriptProperty Logins {
				return @{
					'Windows\User1' = @( ( New-Object Object | 
						Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Windows\User1' -PassThru |
						Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsUser' -PassThru -Force
                    ) )
					'SqlLogin1' = @( ( New-Object Object | 
						Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SqlLogin1' -PassThru |
						Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'SqlLogin' -PassThru | 
						Add-Member -MemberType NoteProperty -Name 'MustChangePassword' -Value $false -PassThru | 
						Add-Member -MemberType NoteProperty -Name 'PasswordExpirationEnabled' -Value $true -PassThru | 
						Add-Member -MemberType NoteProperty -Name 'PasswordPolicyEnforced' -Value $true -PassThru -Force
                    ) )
					'Windows\Group1' = @( ( New-Object Object | 
						Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Windows\Group1' -PassThru |
						Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsGroup' -PassThru -Force
                    ) )
				}
			} -PassThru -Force
	}

    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Verifiable -Scope Describe
        Mock -CommandName Import-SQLPSModule -MockWith {} -ModuleName $script:DSCResourceName

        Context 'When the login is Absent' {

            It 'Should be Absent when an unknown SQL Login is provided' {
                ( Get-TargetResource @getTargetResource_UnknownSqlLogin ).Ensure | Should Be 'Absent'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should be Absent when an unknown Windows User or Group is provided' {
                ( Get-TargetResource @getTargetResource_UnknownWindows ).Ensure | Should Be 'Absent'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            
        }

        Context 'When the login is Present' {
            It 'Should be Present when a known SQL Login is provided' {
                $result = Get-TargetResource @getTargetResource_KnownSqlLogin

                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'SqlLogin'
                $result.LoginMustChangePassword | Should Not Be $null
                $result.LoginPasswordExpirationEnabled | Should Not Be $null
                $result.LoginPasswordPolicyEnforced | Should Not Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should be Present when a known Windows User is provided' {
                $result = Get-TargetResource @getTargetResource_KnownWindowsUser

                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'WindowsUser'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should be Present when a known Windows User is provided' {
                $result = Get-TargetResource @getTargetResource_KnownWindowsGroup

                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'WindowsGroup'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Verifiable
        Mock -CommandName Import-SQLPSModule -MockWith {} -ModuleName $script:DSCResourceName

        Context 'When the desired state is Absent' {
            It 'Should return $true when the specified Windows user is Absent' {
                $testTargetResource_WindowsUserAbsent_EnsureAbsent = $testTargetResource_WindowsUserAbsent.Clone()
                $testTargetResource_WindowsUserAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsureAbsent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $true when the specified Windows group is Absent' {
                $testTargetResource_WindowsGroupAbsent_EnsureAbsent = $testTargetResource_WindowsGroupAbsent.Clone()
                $testTargetResource_WindowsGroupAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsureAbsent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Absent' {
                $testTargetResource_SqlLoginAbsent_EnsureAbsent = $testTargetResource_SqlLoginAbsent.Clone()
                $testTargetResource_SqlLoginAbsent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsureAbsent ) | Should Be $true 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $false when the specified Windows user is Present' {
                $testTargetResource_WindowsUserPresent_EnsureAbsent = $testTargetResource_WindowsUserPresent.Clone()
                $testTargetResource_WindowsUserPresent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_WindowsUserPresent_EnsureAbsent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $false when the specified Windows group is Present' {
                $testTargetResource_WindowsGroupPresent_EnsureAbsent = $testTargetResource_WindowsGroupPresent.Clone()
                $testTargetResource_WindowsGroupPresent_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_WindowsGroupPresent_EnsureAbsent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Present' {
                $testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent.Add( 'Ensure','Absent' )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }
        }
        
        Context 'When the desired state is Present' {
            It 'Should return $false when the specified Windows user is Absent' {
                $testTargetResource_WindowsUserAbsent_EnsurePresent = $testTargetResource_WindowsUserAbsent.Clone()
                $testTargetResource_WindowsUserAbsent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsurePresent ) | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $false when the specified Windows group is Absent' {
                $testTargetResource_WindowsGroupAbsent_EnsurePresent = $testTargetResource_WindowsGroupAbsent.Clone()
                $testTargetResource_WindowsGroupAbsent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsurePresent ) | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Absent' {
                $testTargetResource_SqlLoginAbsent_EnsurePresent = $testTargetResource_SqlLoginAbsent.Clone()
                $testTargetResource_SqlLoginAbsent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsurePresent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $true when the specified Windows user is Present' {
                $testTargetResource_WindowsUserPresent_EnsurePresent = $testTargetResource_WindowsUserPresent.Clone()
                $testTargetResource_WindowsUserPresent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_WindowsUserPresent_EnsurePresent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $true when the specified Windows group is Present' {
                $testTargetResource_WindowsGroupPresent_EnsurePresent = $testTargetResource_WindowsGroupPresent.Clone()
                $testTargetResource_WindowsGroupPresent_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_WindowsGroupPresent_EnsurePresent ) | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Present using default parameter values' {
                $testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent.Add( 'Ensure','Present' )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent ) | Should Be $true 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Present and PasswordExpirationEnabled is $true' {
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent.Add( 'LoginPasswordExpirationEnabled',$true )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent ) | Should Be $true 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Present and PasswordExpirationEnabled is $false' {
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent.Add( 'LoginPasswordExpirationEnabled',$false )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $true when the specified SQL Login is Present and PasswordPolicyEnforced is $true' {
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent.Add( 'LoginPasswordPolicyEnforced',$true )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent ) | Should Be $true 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }

            It 'Should return $false when the specified SQL Login is Present and PasswordPolicyEnforced is $false' {
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent.Add( 'Ensure','Present' )
                $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent.Add( 'LoginPasswordPolicyEnforced',$false )

                ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent ) | Should Be $false 

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Time 1 -Exactly
            }
        }
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -ModuleName $script:DSCResourceName -Verifiable
        Mock -CommandName Import-SQLPSModule -MockWith {} -ModuleName $script:DSCResourceName


    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment 

    #endregion
}
