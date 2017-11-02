$script:DSCModuleName = 'SQLServerDSC'
$script:DSCResourceFriendlyName = 'SqlRS'
$script:DSCResourceName = "MSFT_$($script:DSCResourceFriendlyName)"

if (-not $env:APPVEYOR -eq $true)
{
    Write-Warning -Message ('Integration test for {0} will be skipped unless $env:APPVEYOR equals $true' -f $script:DSCResourceName)
    return
}

#region HEADER
# Integration Test Template Version: 1.1.2
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

$mockSqlAdminAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
$mockSqlAdminAccountUserName = "$env:COMPUTERNAME\SqlAdmin"
$mockSqlAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAdminAccountUserName, $mockSqlAdminAccountPassword

$mockReportingServicesServiceAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
$mockReportingServicesServiceAccountUserName = "$env:COMPUTERNAME\svc-Reporting"
$mockReportingServicesServiceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockReportingServicesServiceAccountUserName, $mockReportingServicesServiceAccountPassword

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    $mockInstanceName = $ConfigurationData.AllNodes.InstanceName
    $mockRSSQLServer = $ConfigurationData.AllNodes.RSSQLServer
    $mockRSSQLInstanceName = $ConfigurationData.AllNodes.RSSQLInstanceName

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:DSCResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:DSCResourceName)_InstallReportingServices_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential               = $mockSqlInstallCredential
                        SqlAdministratorCredential         = $mockSqlAdminCredential
                        ReportingServicesServiceCredential = $mockReportingServicesServiceCredential
                        OutputPath                         = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData                  = $ConfigurationData
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
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $currentConfiguration = Get-DscConfiguration

                $resourceCurrentState = $currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.InstanceName | Should -Be $mockInstanceName
                $resourceCurrentState.RSSQLServer | Should -Be $mockRSSQLServer
                $resourceCurrentState.RSSQLInstanceName | Should -Be $mockRSSQLInstanceName
                $resourceCurrentState.IsInitialized | Should -Be $true
            }

            It 'Should be able to access the ReportServer site without any error' {
                $reportServerUri = 'http://{0}/ReportServer_{1}' -f $env:COMPUTERNAME, $mockInstanceName

                try
                {
                    $webRequestReportServer = Invoke-WebRequest -Uri $reportServerUri -UseDefaultCredentials
                    # if the request finishes successfully this should return status code 200.
                    $webRequestStatusCode = $webRequestReportServer.StatusCode -as [int]
                }
                catch
                {
                    <#
                        If the request generated an exception i.e. "HTTP Error 503. The service is unavailable."
                        we can pull the status code from the Exception.Response property.
                    #>
                    $webRequestResponse = $_.Exception.Response
                    $webRequestStatusCode = $webRequestResponse.StatusCode -as [int]
                }

                $webRequestStatusCode | Should -BeExactly 200
            }

            It 'Should be able to access the Reports site without any error' {
                $reportsUri = 'http://{0}/Reports_{1}' -f $env:COMPUTERNAME, $mockInstanceName

                try
                {
                    $webRequestReportServer = Invoke-WebRequest -Uri $reportsUri -UseDefaultCredentials
                    # if the request finishes successfully this should return status code 200.
                    $webRequestStatusCode = $webRequestReportServer.StatusCode -as [int]
                }
                catch
                {
                    <#
                        If the request generated an exception i.e. "HTTP Error 503. The service is unavailable."
                        we can pull the status code from the Exception.Response property.
                    #>
                    $webRequestResponse = $_.Exception.Response
                    $webRequestStatusCode = $webRequestResponse.StatusCode -as [int]
                }

                $webRequestStatusCode | Should -BeExactly 200
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
