BeforeDiscovery {
    if (-not (Test-BuildCategory -Type 'Integration' -Category @('Skipped')))
    {
        return
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'SqlAlwaysOnService'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlAlwaysOnService'
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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # These sets variables used for verification from the dot-sourced $ConfigurationData variable.
    $mockLoopbackAdapterName = $ConfigurationData.AllNodes.LoopbackAdapterName

    <#
        Create the loopback adapter to be used with the cluster.
        The loopback adapter is kept on the build worker after test finishes
        so that the cluster is available.
        The IP address of the loopback adapter is set in the dependencies
        configuration.
    #>
    New-IntegrationLoopbackAdapter -AdapterName $mockLoopbackAdapterName

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
        "$($script:dscResourceName)_CreateDependencies_Config"
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
                    OutputPath = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path = $TestDrive
                    ComputerName = 'localhost'
                    Wait = $true
                    Verbose = $true
                    Force = $true
                    ErrorAction = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_EnableAlwaysOn_Config"
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
                    OutputPath = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path = $TestDrive
                    ComputerName = 'localhost'
                    Wait = $true
                    Verbose = $true
                    Force = $true
                    ErrorAction = 'Stop'
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

            $resourceCurrentState.IsHadrEnabled | Should -Be $true
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_DisableAlwaysOn_Config"
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
                    OutputPath = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path = $TestDrive
                    ComputerName = 'localhost'
                    Wait = $true
                    Verbose = $true
                    Force = $true
                    ErrorAction = 'Stop'
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

            $resourceCurrentState.IsHadrEnabled | Should -Be $false
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_CleanupDependencies_Config"
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
                    OutputPath = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path = $TestDrive
                    ComputerName = 'localhost'
                    Wait = $true
                    Verbose = $true
                    Force = $true
                    ErrorAction = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }
    }
}
