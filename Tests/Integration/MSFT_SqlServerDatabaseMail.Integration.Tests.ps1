# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceFriendlyName = 'SqlServerDatabaseMail'
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

$mockSqlInstallAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
$mockSqlInstallAccountUserName = "$env:COMPUTERNAME\SqlInstall"
$mockSqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlInstallAccountUserName, $mockSqlInstallAccountPassword

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    $mockMailServerName = $ConfigurationData.AllNodes.MailServerName
    $mockAccountName = $ConfigurationData.AllNodes.AccountName
    $mockProfileName = $ConfigurationData.AllNodes.ProfileName
    $mockEmailAddress = $ConfigurationData.AllNodes.EmailAddress
    $mockDescription = $ConfigurationData.AllNodes.Description
    $mockLoggingLevel = $ConfigurationData.AllNodes.LoggingLevel
    $mockTcpPort = $ConfigurationData.AllNodes.TcpPort

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:DSCResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:DSCResourceName)_Add_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential = $mockSqlInstallCredential
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
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.AccountName | Should -Be $mockAccountName
                $resourceCurrentState.ProfileName | Should -Be $mockProfileName
                $resourceCurrentState.EmailAddress | Should -Be $mockEmailAddress
                $resourceCurrentState.ReplyToAddress | Should -Be $mockEmailAddress
                $resourceCurrentState.DisplayName | Should -Be $mockMailServerName
                $resourceCurrentState.MailServerName | Should -Be $mockMailServerName
                $resourceCurrentState.Description | Should -Be $mockDescription
                $resourceCurrentState.LoggingLevel | Should -Be $mockLoggingLevel
                $resourceCurrentState.TcpPort | Should -Be $mockTcpPort
            }
        }

        $configurationName = "$($script:DSCResourceName)_Remove_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential = $mockSqlInstallCredential
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
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
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
        }
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
