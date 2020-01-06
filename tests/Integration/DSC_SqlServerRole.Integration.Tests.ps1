Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017')))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlServerRole'
$script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

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
    -TestType 'Integration'

# Using try/finally to always cleanup.
try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_AddRole1_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
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
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }


                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $ConfigurationData.AllNodes.Role1Name
                $resourceCurrentState.Members | Should -Be $ConfigurationData.AllNodes.User4Name
                $resourceCurrentState.MembersToInclude | Should -Be $ConfigurationData.AllNodes.User4Name
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_AddRole2_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
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
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }


                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $ConfigurationData.AllNodes.Role2Name
                $resourceCurrentState.Members | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_AddRole3_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
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
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }


                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $ConfigurationData.AllNodes.Role3Name
                $resourceCurrentState.Members | Should -Be @(
                    $ConfigurationData.AllNodes.User1Name
                    $ConfigurationData.AllNodes.User2Name
                )
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_Role1_ChangeMembers_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
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
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }


                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $ConfigurationData.AllNodes.Role1Name
                $resourceCurrentState.Members | Should -Be @(
                    $ConfigurationData.AllNodes.User1Name
                    $ConfigurationData.AllNodes.User2Name
                )
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_Role2_AddMembers_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
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
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }


                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $ConfigurationData.AllNodes.Role2Name
                $resourceCurrentState.Members | Should -Be @(
                    $ConfigurationData.AllNodes.User1Name
                    $ConfigurationData.AllNodes.User2Name
                    $ConfigurationData.AllNodes.User4Name
                )
                $resourceCurrentState.MembersToInclude | Should -Be @(
                    $ConfigurationData.AllNodes.User1Name
                    $ConfigurationData.AllNodes.User2Name
                    $ConfigurationData.AllNodes.User4Name
                )
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_Role2_RemoveMembers_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
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
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }


                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.ServerRoleName | Should -Be $ConfigurationData.AllNodes.Role2Name
                $resourceCurrentState.Members | Should -Be $ConfigurationData.AllNodes.User4Name
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -Be @(
                    $ConfigurationData.AllNodes.User1Name
                    $ConfigurationData.AllNodes.User2Name
                )
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_RemoveRole3_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
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
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }


                $resourceCurrentState.Ensure | Should -Be 'Absent'
                $resourceCurrentState.ServerRoleName | Should -Be $ConfigurationData.AllNodes.Role3Name
                $resourceCurrentState.Members | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
                $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_AddNestedRole_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing an exception' {
                $configurationParameters = @{
                    OutputPath = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                { & $configurationName @configurationParameters } | Should -Not -Throw
            }

            It 'Should apply the configuration successfully' {
                $startDscConfigurationParameters = @{
                    Path = $TestDrive
                    ComputerName = 'localhost'
                    Wait = $true
                    Verbose = $true
                    Force = $true
                    ErrorAction = 'Stop'
                }

                { Start-DscConfiguration @startDscConfigurationParameters } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing an exception' {
                { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } |
                    Should -Not -Throw
            }

            It "Should have set the resource and all values should match for $($ConfigurationData.AllNodes.Role4Name)." {
                $testRoleName = $ConfigurationData.AllNodes.Role4Name

                # Extract just the roles we want from the Configuration
                $currentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName -and
                    $_.ServerRoleName -eq $testRoleName
                }

                $currentState.Ensure | Should -Be 'Present'
                $currentState.Members | Should -BeNullOrEmpty
                $currentState.MembersToInclude | Should -BeNullOrEmpty
                $currentState.MembersToExclude | Should -BeNullOrEmpty
            }

            It "Should have set the resource and all values should match for $($ConfigurationData.AllNodes.Role5Name)." {
                $testRoleName = $ConfigurationData.AllNodes.Role5Name
                $testMemberName = $ConfigurationData.AllNodes.Role4Name

                # Extract just the roles we want from the Configuration
                $currentstate = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName -and
                    $_.ServerRoleName -eq $testRoleName
                }

                $currentState.Ensure | Should -Be 'Present'
                $currentState.Members | Should -Be @($testMemberName)
                $currentState.MembersToInclude | Should -Be @($testMemberName)
                $currentState.MembersToExclude | Should -BeNullOrEmpty
            }
        }

        $configurationName = "$($script:dscResourceName)_RemoveNestedRole_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing an exception' {
                $configurationParameters = @{
                    OutputPath = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                { & $configurationName @configurationParameters } | Should -Not -Throw
            }

            It 'Should apply the configuration successfully' {
                $startDscConfigurationParameters = @{
                    Path = $TestDrive
                    ComputerName = 'localhost'
                    Wait = $true
                    Verbose = $true
                    Force = $true
                    ErrorAction = 'Stop'
                }

                { Start-DscConfiguration @startDscConfigurationParameters } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing an exception' {
                { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } |
                    Should -Not -Throw
            }

            It "Should have set the resource and all values should match for $($ConfigurationData.AllNodes.Role5Name)." {
                $testRoleName = $ConfigurationData.AllNodes.Role5Name
                $testMemberName = $ConfigurationData.AllNodes.Role4Name

                $currentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName -and
                    $_.ServerRoleName -eq $testRoleName
                }

                $currentState.Ensure | Should -Be 'Present'
                $currentstate.Members | Should -BeNullOrEmpty
                $currentState.MembersToInclude | Should -BeNullOrEmpty
                $currentState.MembersToExclude | Should -Be $testMemberName
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Write-Verbose -Message ('Test {1} run for {0} minutes' -f ([timespan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString("mm\:ss"), $script:DSCResourceFriendlyName) -Verbose
    $script:timer.Stop()

    #endregion
}
