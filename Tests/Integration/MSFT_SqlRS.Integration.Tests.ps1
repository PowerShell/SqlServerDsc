# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceFriendlyName = 'SqlRS'
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

$script:integrationErrorMessagePrefix = 'INTEGRATION ERROR MESSAGE:'
#endregion

$mockSqlInstallAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
$mockSqlInstallAccountUserName = "$env:COMPUTERNAME\SqlInstall"
$mockSqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlInstallAccountUserName, $mockSqlInstallAccountPassword

$mockReportingServicesServiceAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
$mockReportingServicesServiceAccountUserName = "$env:COMPUTERNAME\svc-Reporting"
$mockReportingServicesServiceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockReportingServicesServiceAccountUserName, $mockReportingServicesServiceAccountPassword

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    $mockInstanceName = $ConfigurationData.AllNodes.InstanceName
    $mockDatabaseServerName = $ConfigurationData.AllNodes.DatabaseServerName
    $mockDatabaseInstanceName = $ConfigurationData.AllNodes.DatabaseInstanceName

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:DSCResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:DSCResourceName)_CreateDependencies_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential               = $mockSqlInstallCredential
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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $integrationErrorMessagePrefix, $_) -Verbose
                        throw $_
                    }
                } | Should -Not -Throw
            }
        }

        $configurationName = "$($script:DSCResourceName)_InstallReportingServices_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential               = $mockSqlInstallCredential
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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $integrationErrorMessagePrefix, $_) -Verbose
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

                $resourceCurrentState.InstanceName | Should -Be $mockInstanceName
                $resourceCurrentState.DatabaseServerName | Should -Be $mockDatabaseServerName
                $resourceCurrentState.DatabaseInstanceName | Should -Be $mockDatabaseInstanceName
                $resourceCurrentState.IsInitialized | Should -Be $true
                $resourceCurrentState.UseSsl | Should -Be $false
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

        $configurationName = "$($script:DSCResourceName)_InstallReportingServices_ConfigureSsl_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential               = $mockSqlInstallCredential
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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $integrationErrorMessagePrefix, $_) -Verbose
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

                $resourceCurrentState.UseSsl | Should -Be $true
            }

            <#
                We expect this to throw any error. Usually 'Unable to connect to the remote server' but it
                can also throw and 'The underlying connection was closed: An unexpected error occurred on a send'.
                When we support SSL fully with this resource, this should not throw at all. So leaving this
                as this without testing for the correct error message on purpose.
            #>
            It 'Should not be able to access the ReportServer site and throw an error message' {
                $reportServerUri = 'http://{0}/ReportServer_{1}' -f $env:COMPUTERNAME, $mockInstanceName

                { Invoke-WebRequest -Uri $reportServerUri -UseDefaultCredentials } | Should -Throw
            }
        }

        $configurationName = "$($script:DSCResourceName)_InstallReportingServices_RestoreToNoSsl_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential               = $mockSqlInstallCredential
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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $integrationErrorMessagePrefix, $_) -Verbose
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

                $resourceCurrentState.UseSsl | Should -Be $false
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
        }

        $configurationName = "$($script:DSCResourceName)_StopReportingServicesInstance_Config"

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

                    try
                    {
                        Start-DscConfiguration @startDscConfigurationParameters
                    }
                    catch
                    {
                        Write-Verbose -Message ('{0} {1}' -f $integrationErrorMessagePrefix, $_) -Verbose
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
