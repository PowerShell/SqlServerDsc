Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017')))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlScriptQuery'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

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

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_RunSqlScriptQueryAsWindowsUser_Config"

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
                $resourceCurrentState.GetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.GetQuery -replace '\r\n', "`n")
                $resourceCurrentState.TestQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.TestQuery -replace '\r\n', "`n")
                $resourceCurrentState.SetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.SetQuery -replace '\r\n', "`n")
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_RunSqlScriptQueryAsSqlUser_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

                $resourceCurrentState.GetResult | Should -Match $ConfigurationData.AllNodes.Database2Name
                $resourceCurrentState.GetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.GetQuery -replace '\r\n', "`n")
                $resourceCurrentState.TestQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.TestQuery -replace '\r\n', "`n")
                $resourceCurrentState.SetQuery -replace '\r\n', "`n" | Should -Be ($ConfigurationData.AllNodes.SetQuery -replace '\r\n', "`n")
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
