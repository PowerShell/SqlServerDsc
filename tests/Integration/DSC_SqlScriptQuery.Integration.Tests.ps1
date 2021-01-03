BeforeDiscovery {
    if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019')))
    {
        return
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'SqlScriptQuery'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlScriptQuery'
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
        "$($script:dscResourceName)_RunSqlScriptQueryAsWindowsUser_Config"
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

            <#
                This returns an array of string containing the result of the
                get scripts JSON output. The output looks like the below.

                ```
                JSON_F52E2B61-18A1-11d1-B105-00805F49916B
                -----------------------------------------
                [{"Name":"ScriptDatabase1"}]
                ```

                This could have been easier by just having this test
                $resourceCurrentState.GetResult | Should -Match 'ScriptDatabase1'
                but for making sure the returned data is actually usable, this
                parses the returned data to an object.
            #>
            $regularExpression = [regex] '\[.*\]'
            if ($regularExpression.IsMatch($resourceCurrentState.GetResult))
            {
                $regularExpressionMatch = $regularExpression.Match($resourceCurrentState.GetResult).Value
            }
            else
            {
                Write-Verbose -Message ('Unexpected output from Get-TargetResource: {0}' -f $resourceCurrentState.GetResult) -Verbose
                $regularExpressionMatch = '[{"Name":""}]'
            }

            try
            {
                $resultObject = $regularExpressionMatch | ConvertFrom-Json
            }
            catch
            {
                Write-Verbose -Message ('Output from Get-TargetResource: {0}' -f $resourceCurrentState.GetResult) -Verbose
                Write-Verbose -Message ('Result from regular expression match: {0}' -f $regularExpressionMatch) -Verbose
                throw $_
            }

            $resultObject.Name | Should -Be $ConfigurationData.AllNodes.Database1Name

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.GetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.GetQuery -replace '\r\n', "`n")
            $resourceCurrentState.TestQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.TestQuery -replace '\r\n', "`n")
            $resourceCurrentState.SetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.SetQuery -replace '\r\n', "`n")
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RunSqlScriptQueryAsSqlUser_Config"
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

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.GetResult | Should -Match $ConfigurationData.AllNodes.Database2Name
            $resourceCurrentState.GetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.GetQuery -replace '\r\n', "`n")
            $resourceCurrentState.TestQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.TestQuery -replace '\r\n', "`n")
            $resourceCurrentState.SetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.SetQuery -replace '\r\n', "`n")
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RunSqlScriptQueryWithVariablesDisabled_Config"
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

            <#
                This returns an array of string containing the result of the
                get scripts JSON output. The output looks like the below.

                ```
                JSON_F52E2B61-18A1-11d1-B105-00805F49916B
                -----------------------------------------
                [{"Name":"ScriptDatabase1"}]
                ```

                This could have been easier by just having this test
                $resourceCurrentState.GetResult | Should -Match 'ScriptDatabase1'
                but for making sure the returned data is actually usable, this
                parses the returned data to an object.
            #>
            $regularExpression = [regex] '\[.*\]'
            if ($regularExpression.IsMatch($resourceCurrentState.GetResult))
            {
                $regularExpressionMatch = $regularExpression.Match($resourceCurrentState.GetResult).Value
            }
            else
            {
                Write-Verbose -Message ('Unexpected output from Get-TargetResource: {0}' -f $resourceCurrentState.GetResult) -Verbose
                $regularExpressionMatch = '[{"Name":""}]'
            }

            try
            {
                $resultObject = $regularExpressionMatch | ConvertFrom-Json
            }
            catch
            {
                Write-Verbose -Message ('Output from Get-TargetResource: {0}' -f $resourceCurrentState.GetResult) -Verbose
                Write-Verbose -Message ('Result from regular expression match: {0}' -f $regularExpressionMatch) -Verbose
                throw $_
            }

            $resultObject.Name | Should -Be $ConfigurationData.AllNodes.Database3Name

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.GetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.GetQuery -replace '\r\n', "`n")
            $resourceCurrentState.TestQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.TestQuery -replace '\r\n', "`n")
            $resourceCurrentState.SetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.SetQuery -replace '\r\n', "`n")
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveDatabase3_Config"
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
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
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
    }
}

