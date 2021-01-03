BeforeDiscovery {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019')))
    {
        return
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'SqlRole'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlRole'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    try
    {
        Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
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

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe "$($script:dscResourceName)_Integration" {
    BeforeAll {
        $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddRole1_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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
            $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
            $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddRole2_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddRole3_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Role1_ChangeMembers_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Role2_AddMembers_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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

            $resourceCurrentState.MembersToInclude | Should -BeNullOrEmpty
            $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Role2_RemoveMembers_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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
            $resourceCurrentState.MembersToExclude | Should -BeNullOrEmpty
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveRole3_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddNestedRole_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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
            $currentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and
                $_.ServerRoleName -eq $testRoleName
            }

            $currentState.Ensure | Should -Be 'Present'
            $currentState.Members | Should -Be @($testMemberName)
            $currentState.MembersToInclude | Should -BeNullOrEmpty
            $currentState.MembersToExclude | Should -BeNullOrEmpty
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveNestedRole_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw

            {
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

        It 'Should be able to call Get-DscConfiguration without throwing an exception' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It "Should have set the resource and all values should match for $($ConfigurationData.AllNodes.Role5Name)." {
            $testRoleName = $ConfigurationData.AllNodes.Role5Name
            $testMemberName = $ConfigurationData.AllNodes.Role4Name

            $currentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName -and
                $_.ServerRoleName -eq $testRoleName
            }

            $currentState.Ensure | Should -Be 'Present'
            $currentState.Members | Should -BeNullOrEmpty
            $currentState.MembersToInclude | Should -BeNullOrEmpty
            $currentState.MembersToExclude | Should -BeNullOrEmpty
        }
    }
}
