<#
    This is used to make sure the integration test run in the correct order.
    The integration test should run after the integration tests SqlServerLogin
    and SqlServerRole, so any problems in those will be caught first, since
    these integration tests are using those resources.
#>
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 5)]
param()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlScriptQuery'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

#region HEADER
# Integration Test Template Version: 1.3.2
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Integration
#endregion

# Using try/finally to always cleanup.
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
                $resourceCurrentState.GetQuery | Should -Be $ConfigurationData.AllNodes.GetQuery
                # Need to remove excessive CR from the compare string due to the code being cloned using CRLF.
                $resourceCurrentState.TestQuery | Should -Be ($ConfigurationData.AllNodes.TestQuery -replace [Environment]::NewLine, "`n")
                $resourceCurrentState.SetQuery | Should -Be $ConfigurationData.AllNodes.SetQuery
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
                $resourceCurrentState.GetQuery | Should -Be $ConfigurationData.AllNodes.GetQuery
                $resourceCurrentState.TestQuery | Should -Be $ConfigurationData.AllNodes.TestQuery
                $resourceCurrentState.SetQuery | Should -Be $ConfigurationData.AllNodes.SetQuery
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
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
