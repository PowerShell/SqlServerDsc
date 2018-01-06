Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017')))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlServerDatabaseMail'
$script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

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

$script:timer = [System.Diagnostics.Stopwatch]::StartNew()

# Using try/finally to always cleanup.
try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_Add_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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
                $resourceCurrentState.AccountName | Should -Be $ConfigurationData.AllNodes.AccountName
                $resourceCurrentState.ProfileName | Should -Be $ConfigurationData.AllNodes.ProfileName
                $resourceCurrentState.EmailAddress | Should -Be $ConfigurationData.AllNodes.EmailAddress
                $resourceCurrentState.ReplyToAddress | Should -Be $ConfigurationData.AllNodes.EmailAddress
                $resourceCurrentState.DisplayName | Should -Be $ConfigurationData.AllNodes.MailServerName
                $resourceCurrentState.MailServerName | Should -Be $ConfigurationData.AllNodes.MailServerName
                $resourceCurrentState.Description | Should -Be $ConfigurationData.AllNodes.Description
                $resourceCurrentState.LoggingLevel | Should -Be $ConfigurationData.AllNodes.LoggingLevel
                $resourceCurrentState.TcpPort | Should -Be $ConfigurationData.AllNodes.TcpPort
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_Remove_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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
                $resourceCurrentState.AccountName | Should -BeNullOrEmpty
                $resourceCurrentState.ProfileName | Should -BeNullOrEmpty
                $resourceCurrentState.EmailAddress | Should -BeNullOrEmpty
                $resourceCurrentState.ReplyToAddress | Should -BeNullOrEmpty
                $resourceCurrentState.DisplayName | Should -BeNullOrEmpty
                $resourceCurrentState.MailServerName | Should -BeNullOrEmpty
                $resourceCurrentState.Description | Should -BeNullOrEmpty
                $resourceCurrentState.LoggingLevel | Should -BeNullOrEmpty
                $resourceCurrentState.TcpPort | Should -BeNullOrEmpty
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

    Write-Verbose -Message ('Test {1} run for {0} minutes' -f ([timespan]::FromMilliseconds($timer.ElapsedMilliseconds)).ToString("mm\:ss"), $script:DSCResourceFriendlyName) -Verbose
    $timer.Stop()

    #endregion
}
