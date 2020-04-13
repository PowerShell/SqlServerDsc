<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlServerRole DSC resource.

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
$script:dscResourceName = 'MSFT_SqlServerRole'

function Invoke-TestSetup
{
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
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockSqlServerRole = 'AdminSqlforBI'
        $mockSqlServerChildRole = 'TestChildRole'
        $mockSqlServerLoginOne = 'CONTOSO\John'
        $mockSqlServerLoginTwo = 'CONTOSO\Kelly'
        $mockSqlServerLoginThree = 'CONTOSO\Lucy'
        $mockSqlServerLoginFour = 'CONTOSO\Steve'
        $mockEnumMemberNames = @(
            $mockSqlServerLoginOne,
            $mockSqlServerLoginTwo
        )
        $mockSecurityPrincipals = @(
            $mockSqlServerLoginOne
            $mockSqlServerLoginTwo
            $mockSqlServerLoginThree
            $mockSqlServerLoginFour
            $mockSqlServerChildRole
        )
        $mockSqlServerLoginType = 'WindowsUser'
        $mockExpectedServerRoleToDrop = 'ServerRoleToDrop'
        $mockPrincipalsAsArrays = $false

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
        }

        #region Function mocks

        $mockConnectSQL = {
            $mockServerObjectHashtable = @{
                InstanceName = $mockInstanceName
                ComputerNamePhysicalNetBIOS = $mockServerName
                Name = "$mockServerName\$mockInstanceName"
            }

            if ($mockPrincipalsAsArrays)
            {
                $mockServerObjectHashtable += @{
                    Logins = @()
                    Roles = @()
                }
            }
            else
            {
                $mockServerObjectHashtable += @{
                    Logins = @{}
                    Roles = @{}
                }
            }

            $mockServerObject = [PSCustomObject]$mockServerObjectHashtable

            # Add the roles to the mock Server objet
            foreach ($mockRole in $($mockSqlServerRole, $mockSqlServerChildRole))
            {
                # Create the role objet
                $mockRoleObject = [PSCustomObject]@{
                    Name = $mockRole
                }

                # Add mocked methods
                $mockRoleObject | Add-Member -MemberType ScriptMethod -Name EnumMemberNames -Value {
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
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [String]
                        $memberName
                    )

                    if ($mockInvalidOperationForAddMemberMethod)
                    {
                        throw 'Mock AddMember Method was called with invalid operation.'
                    }

                    if ($mockExpectedMemberToAdd -ne $memberName)
                    {
                        throw "Called mocked AddMember() method without adding the right login. Expected '{0}'. But was '{1}'." `
                            -f $mockExpectedMemberToAdd, $memberName
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [String]
                        $memberName
                    )

                    if ($mockInvalidOperationForDropMemberMethod)
                    {
                        throw 'Mock DropMember Method was called with invalid operation.'
                    }

                    if ($mockExpectedMemberToDrop -ne $memberName)
                    {
                        throw "Called mocked DropMember() method without removing the right login. Expected '{0}'. But was '{1}'." `
                            -f $mockExpectedMemberToDrop, $memberName
                    }
                }

                # Add the mock role to the roles collection
                if ($mockServerObject.Roles -is [array])
                {
                    $mockServerObject.Roles += $mockRoleObject
                }
                else
                {
                    $mockServerObject.Roles.Add($mockRole, $mockRoleObject)
                }
            }

            # Add all mock logins
            foreach ($mockLoginName in @($mockSqlServerLoginOne, $mockSqlServerLoginTwo, $mockSqlServerLoginThree, $mockSqlServerLoginFour))
            {
                $mockLoginObject = [PSCustomObject]@{
                    Name = $mockLoginName
                    LoginType = $mockSqlServerLoginType
                }

                if ($mockServerObject.Logins -is [array])
                {
                    $mockServerObject.Logins += $mockLoginObject
                }
                else
                {
                    $mockServerObject.Logins.Add($mockLoginName, $mockLoginObject)
                }
            }

            return @($mockServerObject)
        }

        $mockNewObjectServerRole = {
            $mockObject = [PSCustomObject] @{
                Name = $mockSqlServerRoleAdd
            }

            $mockObject | Add-Member -MemberType ScriptMethod -Name Create -Value {
                if ($mockInvalidOperationForCreateMethod)
                {
                    throw 'Mock Create Method was called with invalid operation.'
                }

                if ( $this.Name -ne $mockExpectedServerRoleToCreate )
                {
                    throw "Called mocked Create() method without adding the right server role. Expected '{0}'. But was '{1}'." `
                        -f $mockExpectedServerRoleToCreate, $this.Name
                }
            }

            return @($mockObject)
        }

        #endregion

        Describe "MSFT_SqlServerRole\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is in the desired state and ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName = 'UnknownRoleName'
                }

                It 'Should return the state as absent when the role does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the members as null' {
                    $result = Get-TargetResource @testParameters
                    $result.Members | Should -Be $null

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName = $mockSqlServerRole
                }

                It 'Should not return the state as absent when the role exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Not -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the members as not null' {
                    $result = Get-TargetResource @testParameters
                    $result.Members | Should -Not -Be $null

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Regression test for issue #790
                It 'Should return the members as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.Members -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing values to parameters and throwing with EnumMemberNames method' {
                It 'Should throw the correct error' {
                    $mockInvalidOperationForEnumMethod = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        ServerRoleName = $mockSqlServerRole
                    }

                    $errorMessage = $script:localizedData.EnumMemberNamesServerRoleGetError `
                        -f $mockServerName, $mockInstanceName, $mockSqlServerRole

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state, parameter Members is assigned a value and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName = $mockSqlServerRole
                    Members        = $mockEnumMemberNames
                }

                It 'Should return the state as present when the members are correct' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the members as not null' {
                    $result = Get-TargetResource @testParameters
                    $result.Members | Should -Be $testParameters.Members

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Regression test for issue #790
                It 'Should return the members as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.Members -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state, parameter MembersToInclude is assigned a value and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName   = $mockSqlServerRole
                    MembersToInclude = $mockSqlServerLoginTwo
                }

                It 'Should return the state as present when the correct members exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the members as not null' {
                    $result = Get-TargetResource @testParameters
                    $result.Members | Should -Not -Be $null

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Regression test for issue #790
                It 'Should return the members as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.Members -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName
                    $result.MembersToInclude | Should -Be $testParameters.MembersToInclude

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state, parameter MembersToExclude is assigned a value and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName   = $mockSqlServerRole
                    MembersToExclude = $mockSqlServerLoginThree
                }

                It 'Should return the state as present when the members does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName
                    $result.MembersToExclude | Should -Be $testParameters.MembersToExclude

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state, parameter MembersToInclude is assigned a value, parameter Members is assigned a value, and ensure is set to Present' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        ServerRoleName   = $mockSqlServerRole
                        Members          = $mockEnumMemberNames
                        MembersToInclude = $mockSqlServerLoginThree
                    }

                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

            }

            Context 'When the system is not in the desired state, parameter MembersToExclude is assigned a value, parameter Members is assigned a value, and ensure is set to Present' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        ServerRoleName   = $mockSqlServerRole
                        Members          = $mockEnumMemberNames
                        MembersToExclude = $mockSqlServerLoginThree
                    }

                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName = 'UnknownRoleName'
                }

                It 'Should return the state as absent when the role does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the members as null' {
                    $result = Get-TargetResource @testParameters
                    $result.Members | Should -Be $null

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state, parameter Members is assigned a value and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName = $mockSqlServerRole
                    Members        = @($mockSqlServerLoginOne, $mockSqlServerLoginThree)
                }

                It 'Should return the state as absent when the members in the role are wrong' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the members as not null' {
                    $result = Get-TargetResource @testParameters
                    $result.Members | Should -Not -Be $null

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Regression test for issue #790
                It 'Should return the members as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.Members -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state, parameter MembersToInclude is assigned a value and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName   = $mockSqlServerRole
                    MembersToInclude = $mockSqlServerLoginThree
                }

                It 'Should return the state as absent when the members in the role are missing' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the members as not null' {
                    $result = Get-TargetResource @testParameters
                    $result.Members | Should -Not -Be $null

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Regression test for issue #790
                It 'Should return the members as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.Members -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName
                    $result.MembersToInclude | Should -Be $testParameters.MembersToInclude

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state, parameter MembersToExclude is assigned a value and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    ServerRoleName   = $mockSqlServerRole
                    MembersToExclude = $mockSqlServerLoginTwo
                }

                It 'Should return the state as absent when the members in the role are present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName
                    $result.MembersToExclude | Should -Be $testParameters.MembersToExclude

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When evaluating role membership, case sensitivity should not be used. (Issue #1153)' {
                It 'Should return Present when the MemberToInclude is a member of the role.' {
                    $testParameters = $mockDefaultParameters.Clone()
                    $testParameters += @{
                        ServerRoleName = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginOne.ToUpper()
                    }

                    $result = Get-TargetResource @testParameters

                    $result.Ensure | Should -Be 'Present'
                    $result.Members | Should -Contain $mockSqlServerLoginOne

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return Absent when the MembersToExclude is a member of the role.' {
                    $testParameters = $mockDefaultParameters.Clone()
                    $testParameters += @{
                        ServerRoleName = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginOne.ToUpper()
                    }

                    $result = Get-TargetResource @testParameters

                    $result.Ensure | Should -Be 'Absent'
                    $result.Members | Should -Contain $mockSqlServerLoginOne

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerRole\Test-TargetResource" -Tag 'Test' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                It 'Should return false when desired server role exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Absent'
                        ServerRoleName = $mockSqlServerRole
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Absent' {
                It 'Should return true when desired server role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Absent'
                        ServerRoleName = 'newServerRole'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present' {
                It 'Should return true when desired server role exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Present'
                        ServerRoleName = $mockSqlServerRole
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure parameter is set to Present' {
                It 'Should return false when desired members are not in desired server role' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members        = @($mockSqlServerLoginThree, $mockSqlServerLoginFour)
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both the parameters Members and MembersToInclude are assigned a value and ensure is set to Present' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        Members          = $mockEnumMemberNames
                        MembersToInclude = $mockSqlServerLoginThree
                    }

                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                    { Test-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should return true when desired server role exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginTwo
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should return false when desired server role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginThree
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both the parameters Members and MembersToExclude are assigned a value and ensure is set to Present' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        Members          = $mockEnumMemberNames
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                    { Test-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should return true when desired server role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginThree
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should return false when desired server role exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerRole\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectServerRole -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
                }
                Mock -CommandName Test-SqlSecurityPrincipal -MockWith {
                    return ($mockSecurityPrincipals -contains $SecurityPrincipal)
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                It 'Should not throw when calling the drop method' {
                    $mockSqlServerRole = 'ServerRoleToDrop'
                    $mockExpectedServerRoleToDrop = 'ServerRoleToDrop'
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Absent'
                        ServerRoleName = $mockSqlServerRole
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                It 'Should throw the correct error when calling the drop method' {
                    $mockInvalidOperationForDropMethod = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Absent'
                        ServerRoleName = $mockSqlServerRole
                    }

                    $errorMessage = $script:localizedData.DropServerRoleSetError `
                        -f $mockServerName, $mockInstanceName, $mockSqlServerRole

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present' {
                It 'Should not throw when calling the create method' {
                    $mockSqlServerRoleAdd = 'ServerRoleToAdd'
                    $mockExpectedServerRoleToCreate = 'ServerRoleToAdd'
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Present'
                        ServerRoleName = $mockSqlServerRoleAdd
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.ServerRole' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
                    } -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present' {
                It 'Should throw the correct error when calling the create method' {
                    $mockSqlServerRoleAdd = 'ServerRoleToAdd'
                    $mockExpectedServerRoleToCreate = 'ServerRoleToAdd'
                    $mockInvalidOperationForCreateMethod = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Present'
                        ServerRoleName = $mockSqlServerRoleAdd
                    }

                    $errorMessage = $script:localizedData.CreateServerRoleSetError `
                        -f $mockServerName, $mockInstanceName, $mockSqlServerRoleAdd

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.ServerRole' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
                    } -Scope Context
                }
            }

            Context 'When both the parameters Members and MembersToInclude are assigned a value and ensure is set to Present' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        Members          = $mockEnumMemberNames
                        MembersToInclude = $mockSqlServerLoginThree
                    }

                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both the parameters Members and MembersToExclude are assigned a value and ensure is set to Present' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        Members          = $mockEnumMemberNames
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should not thrown when calling the AddMember method' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginThree
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should throw the correct error when calling the AddMember method' {
                    $mockInvalidOperationForAddMemberMethod = $true
                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToInclude = $mockSqlServerLoginThree
                    }

                    $errorMessage = $script:localizedData.AddMemberServerRoleSetError `
                        -f $mockServerName, $mockInstanceName, $mockSqlServerRole, $mockSqlServerLoginThree

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should throw the correct error when login does not exist' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToInclude = 'KingJulian'
                    }

                    $errorMessage = $script:localizedData.AddMemberServerRoleSetError -f (
                        $mockServerName,
                        $mockInstanceName,
                        $mockSqlServerRole,
                        'KingJulian'
                    )

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should not throw when calling the DropMember method' {
                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should throw the correct error when calling the DropMember method' {
                    $mockInvalidOperationForDropMemberMethod = $true
                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToExclude = $mockSqlServerLoginTwo
                    }

                    $errorMessage = $script:localizedData.DropMemberServerRoleSetError `
                        -f $mockServerName, $mockInstanceName, $mockSqlServerRole, $mockSqlServerLoginTwo

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
                It 'Should throw the correct error when login does not exist' {
                    $mockEnumMemberNames = @('KingJulian', $mockSqlServerLoginOne, $mockSqlServerLoginTwo)
                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure           = 'Present'
                        ServerRoleName   = $mockSqlServerRole
                        MembersToExclude = 'KingJulian'
                    }

                    $errorMessage = $script:localizedData.DropMemberServerRoleSetError -f (
                        $mockServerName,
                        $mockInstanceName,
                        $mockSqlServerRole,
                        'KingJulian'
                    )

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter Members is assigned a value and ensure is set to Present' {
                It 'Should throw the correct error when login does not exist' {
                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo

                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members        = @('KingJulian', $mockSqlServerLoginOne, $mockSqlServerLoginThree)
                    }

                    $errorMessage = $script:localizedData.AddMemberServerRoleSetError -f (
                        $mockServerName,
                        $mockInstanceName,
                        $mockSqlServerRole,
                        'KingJulian'
                    )

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Members parameter is set and ensure parameter is set to Present' {
                It 'Should not throw when calling both the AddMember and DropMember methods' {
                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Ensure         = 'Present'
                        ServerRoleName = $mockSqlServerRole
                        Members        = @($mockSqlServerLoginOne, $mockSqlServerLoginThree)
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When nesting role membership' {
                Context 'When defining an explicit list of members.' {
                    It 'Should not throw when the member is a Role' {
                        $mockExpectedMemberToAdd = $mockSqlServerChildRole
                        $testParameters = $mockDefaultParameters.Clone()

                        $testParameters += @{
                            Ensure = 'Present'
                            ServerRoleName = $mockSqlServerRole
                            Members = @($mockSqlServerLoginOne, $mockSqlServerLoginTwo, $mockSqlServerChildRole)
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When specifying a list of security principals to include in the Role.' {
                    It 'Should not throw when a member to inculde is a Role.' {
                        $mockExpectedMemberToAdd = $mockSqlServerChildRole
                        $testParameters = $mockDefaultParameters.Clone()

                        $testParameters += @{
                            Ensure = 'Present'
                            ServerRoleName = $mockSqlServerRole
                            MembersToInclude = @($mockSqlServerChildRole)
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When specifying a list of security principals to remove from the Role.' {
                    It 'Should not throw when the member to exclude is a Role.' {
                        $mockExpectedMemberToDrop = $mockSqlServerChildRole
                        $testParameters = $mockDefaultParameters.Clone()

                        $testParameters += @{
                            Ensure = 'Present'
                            ServerRoleName = $mockSqlServerRole
                            MembersToExclude = @($mockSqlServerChildRole)
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When evaluating role membership, case sensitivity should not be used. (Issue #1153)' {
                Context 'When specifying explicit role members.' {
                    It 'Should not attempt to remove an explicit member from the role.' {
                        $mockExpectedMemberToDrop = $mockSqlServerLoginTwo

                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            ServerRoleName = $mockSqlServerRole
                            Ensure = 'Present'
                            Members = $mockSqlServerLoginOne.ToUpper()
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should not attempt to add an explicit member that already exists in the role.' {
                        $mockExpectedMemberToAdd = ''

                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            ServerRoleName = $mockSqlServerRole
                            Ensure = 'Present'
                            Members = @($mockSqlServerLoginOne.ToUpper(), $mockSqlServerLoginTwo)
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When specifying mandatory role membership.' {
                    It 'Should not attempt to add a member that already exists in the role.' {
                        $mockExpectedMemberToAdd = ''

                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            ServerRoleName = $mockSqlServerRole
                            Ensure = 'Present'
                            MembersToInclude = @($mockSqlServerLoginOne.ToUpper())
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should attempt to remove a member that is to be excluded.' {
                        $mockExpectedMemberToDrop = $mockSqlServerLoginOne

                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            ServerRoleName = $mockSqlServerRole
                            Ensure = 'Present'
                            MembersToExclude = @($mockSqlServerLoginOne.ToUpper())
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlServerRole\Test-SqlSecurityPrincipal' -Tag 'Helper' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $mockPrincipalsAsArrays = $true
                $testSqlServerObject = Connect-SQL -ServerName $mockServerName -InstanceName $mockInstanceName
            }

            Context 'When the security principal does not exist.' {
                It 'Should throw the correct exception' {
                    $testSecurityPrincipal = 'Nabrond'

                    $testParameters = @{
                        SqlServerObject = $testSqlServerObject
                        SecurityPrincipal = $testSecurityPrincipal
                    }

                    $testErrorMessage = $script:localizedData.SecurityPrincipalNotFound -f (
                        $testSecurityPrincipal,
                        "$mockServerName\$mockInstanceName"
                    )

                    { Test-SqlSecurityPrincipal @testParameters } | Should -Throw -ExpectedMessage $testErrorMessage
                }

                It 'Should return false when ErrorAction is set to SilentlyContinue' {
                    $testSecurityPrincipal = 'Nabrond'

                    $testParameters = @{
                        SqlServerObject = $testSqlServerObject
                        SecurityPrincipal = $testSecurityPrincipal
                    }

                    <#
                        Pester will still see the error on the stack regardless of the value used for ErrorAction
                        Wrap this call in a try/catch to swallow the exception and capture the return value.
                    #>
                    try
                    {
                        $result = Test-SqlSecurityPrincipal @testParameters -ErrorAction SilentlyContinue
                    }
                    catch
                    {
                        continue;
                    }

                    $result | Should -Be $false
                }
            }

            Context 'When the security principal exists.' {
                It 'Should return true when the principal is a Login.' {

                    $testParameters = @{
                        SqlServerObject = $testSqlServerObject
                        SecurityPrincipal = $mockSqlServerLoginOne
                    }

                    Test-SqlSecurityPrincipal @testParameters | Should -Be $true
                }

                It 'Should return true when the principal is a Login and case does not match.' {
                    $testParameters = @{
                        SqlServerObject = $testSqlServerObject
                        SecurityPrincipal = $mockSqlServerLoginOne.ToUpper()
                    }

                    Test-SqlSecurityPrincipal @testParameters | Should -Be $true
                }

                It 'Should return true when the principal is a Role.' {
                    $testParameters = @{
                        SqlServerObject = $testSqlServerObject
                        SecurityPrincipal = $mockSqlServerRole
                    }

                    Test-SqlSecurityPrincipal @testParameters | Should -Be $true
                }

                It 'Should return true when the principal is a Role and case does not match.' {
                    $testParameters = @{
                        SqlServerObject = $testSqlServerObject
                        SecurityPrincipal = $mockSqlServerRole.ToUpper()
                    }

                    Test-SqlSecurityPrincipal @testParameters | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
