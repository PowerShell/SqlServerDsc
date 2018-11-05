# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceFriendlyName = 'SqlAlwaysOnService'
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

$script:integrationErrorMessagePrefix = 'INTEGRATION ERROR MESSAGE:'

$testRootFolderPath = Split-Path -Path $PSScriptRoot -Parent
Import-Module -Name (Join-Path -Path $testRootFolderPath -ChildPath (Join-Path -Path 'TestHelpers' -ChildPath 'CommonTestHelper.psm1')) -Force

$mockSqlInstallAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
$mockSqlInstallAccountUserName = "$env:COMPUTERNAME\SqlInstall"
$mockSqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlInstallAccountUserName, $mockSqlInstallAccountPassword

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

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

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:DSCResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:DSCResourceName)_CreateDependencies_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $script:integrationErrorMessagePrefix, $_) -Verbose
                        throw $_
                    }
                } | Should -Not -Throw
            }
        }

        $configurationName = "$($script:DSCResourceName)_EnableAlwaysOn_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential = $mockSqlInstallCredential
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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $script:integrationErrorMessagePrefix, $_) -Verbose
                        throw $_
                    }
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

                $resourceCurrentState.IsHadrEnabled | Should -Be $true
            }
        }

        $configurationName = "$($script:DSCResourceName)_DisableAlwaysOn_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential = $mockSqlInstallCredential
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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $script:integrationErrorMessagePrefix, $_) -Verbose
                        throw $_
                    }
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

                $resourceCurrentState.IsHadrEnabled | Should -Be $false
            }
        }

        $configurationName = "$($script:DSCResourceName)_CleanupDependencies_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $script:integrationErrorMessagePrefix, $_) -Verbose
                        throw $_
                    }
                } | Should -Not -Throw
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
