BeforeDiscovery {
    # Run only for SQL Server 2017, integration testing at present (not SQL Server 2019)
    if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2017')))
    {
        return
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'SqlRSSetup'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlRSSetup'
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

    # Download Microsoft SQL Server Reporting Services (October 2017) executable
    if (-not (Test-Path -Path $ConfigurationData.AllNodes.SourcePath))
    {
        # By switching to 'SilentlyContinue' should theoretically increase the download speed.
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        $script:mockSourceMediaDisplayName = 'Microsoft SQL Server Reporting Services (October 2017)'
        $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/E/6/4/E6477A2A-9B58-40F7-8AD6-62BB8491EA78/SQLServerReportingServices.exe'

        Write-Verbose -Message ('Start downloading the {1} executable at {0}.' -f (Get-Date -Format 'yyyy-MM-dd hh:mm:ss'), $script:mockSourceMediaDisplayName) -Verbose

        Invoke-WebRequest -Uri $script:mockSourceMediaUrl -OutFile $ConfigurationData.AllNodes.SourcePath

        Write-Verbose -Message ('{1} executable file has SHA1 hash ''{0}''.' -f (Get-FileHash -Path $ConfigurationData.AllNodes.SourcePath -Algorithm 'SHA1').Hash, $script:mockSourceMediaDisplayName) -Verbose

        $ProgressPreference = $previousProgressPreference

        # Double check that the Microsoft SQL Server Reporting Services (October 2017) was downloaded.
        if (-not (Test-Path -Path $ConfigurationData.AllNodes.SourcePath))
        {
            Write-Warning -Message ('{0} executable could not be downloaded, can not run the integration test.' -f $script:mockSourceMediaDisplayName)
            return
        }
        else
        {
            Write-Verbose -Message ('Finished downloading the {1} executable at {0}.' -f (Get-Date -Format 'yyyy-MM-dd hh:mm:ss'), $script:mockSourceMediaDisplayName) -Verbose
        }
    }
    else
    {
        Write-Verbose -Message ('{0} executable is already downloaded' -f $script:mockSourceMediaDisplayName) -Verbose
    }

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
        "$($script:dscResourceName)_InstallReportingServicesAsUser_Config"
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
                    OutputPath                       = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData                = $ConfigurationData
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

            $resourceCurrentState.InstanceName       | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.InstallFolder      | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services'
            $resourceCurrentState.ServiceName        | Should -Be 'SQLServerReportingServices'
            $resourceCurrentState.ErrorDumpDirectory | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
            $resourceCurrentState.CurrentVersion     | Should -BeGreaterThan ([System.Version] '14.0.0.0')
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_StopReportingServicesInstance_Config"
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
    }
}
