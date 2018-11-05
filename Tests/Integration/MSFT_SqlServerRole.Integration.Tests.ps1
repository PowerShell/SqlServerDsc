# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 3)]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceFriendlyName = 'SqlServerRole'
$script:DSCResourceName = "MSFT_$($script:DSCResourceFriendlyName)"

if (-not $env:APPVEYOR -eq $true)
{
    Write-Warning -Message ('Integration test for {0} will be skipped unless $env:APPVEYOR equals $true' -f $script:DSCResourceName)
    return
}

#region HEADER
# Integration Test Template Version: 1.1.2
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

$mockSqlAdminAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
$mockSqlAdminAccountUserName = "$env:COMPUTERNAME\SqlAdmin"
$mockSqlAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAdminAccountUserName, $mockSqlAdminAccountPassword

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    $mockRole1Name = $ConfigurationData.AllNodes.Role1Name
    $mockRole2Name = $ConfigurationData.AllNodes.Role2Name
    $mockRole3Name = $ConfigurationData.AllNodes.Role3Name
    $mockUser1Name = $ConfigurationData.AllNodes.User1Name
    $mockUser2Name = $ConfigurationData.AllNodes.User2Name
    $mockUser4Name = $ConfigurationData.AllNodes.User4Name

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:DSCResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:DSCResourceName)_AddRole1_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlAdministratorCredential = $mockSqlAdminCredential
                        OutputPath                 = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData          = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState =  $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $mockRole1Name
                $resourceCurrentState.Members | Should -Be $mockUser4Name
                $resourceCurrentState.MembersToInclude | Should -Be $mockUser4Name
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }
        }

        $configurationName = "$($script:DSCResourceName)_AddRole2_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlAdministratorCredential = $mockSqlAdminCredential
                        OutputPath                 = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData          = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $mockRole2Name
                $resourceCurrentState.Members | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }
        }

        $configurationName = "$($script:DSCResourceName)_AddRole3_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlAdministratorCredential = $mockSqlAdminCredential
                        OutputPath                 = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData          = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $mockRole3Name
                $resourceCurrentState.Members | Should -Be @(
                    $mockUser1Name
                    $mockUser2Name
                )
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }
        }

        $configurationName = "$($script:DSCResourceName)_Role1_ChangeMembers_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlAdministratorCredential = $mockSqlAdminCredential
                        OutputPath                 = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData          = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $mockRole1Name
                $resourceCurrentState.Members | Should -Be @(
                    $mockUser1Name
                    $mockUser2Name
                )
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }
        }

        $configurationName = "$($script:DSCResourceName)_Role2_AddMembers_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlAdministratorCredential = $mockSqlAdminCredential
                        OutputPath                 = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData          = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $mockRole2Name
                $resourceCurrentState.Members | Should -Be @(
                    $mockUser1Name
                    $mockUser2Name
                    $mockUser4Name
                )
                $resourceCurrentState.MembersToInclude | Should -Be @(
                    $mockUser1Name
                    $mockUser2Name
                    $mockUser4Name
                )
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }
        }

        $configurationName = "$($script:DSCResourceName)_Role2_RemoveMembers_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlAdministratorCredential = $mockSqlAdminCredential
                        OutputPath                 = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData          = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $mockRole2Name
                $resourceCurrentState.Members | Should -Be $mockUser4Name
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -Be @(
                    $mockUser1Name
                    $mockUser2Name
                )
            }
        }

        $configurationName = "$($script:DSCResourceName)_RemoveRole3_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlAdministratorCredential = $mockSqlAdminCredential
                        OutputPath                 = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData          = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Absent'
                $resourceCurrentState.ServerRoleName | Should -Be $mockRole3Name
                $resourceCurrentState.Members | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
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
