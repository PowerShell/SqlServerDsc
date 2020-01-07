Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017')))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlSetup'
$script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

$script:timer = [System.Diagnostics.Stopwatch]::StartNew()

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

<#
    .SYNOPSIS
        This function will output the Setup Bootstrap Summary.txt log file.

    .DESCRIPTION
        This function will output the Summary.txt log file, this is to be
        able to debug any problems that potentially occurred during setup.
        This will pick up the newest Summary.txt log file, so any
        other log files will be ignored (AppVeyor build worker has
        SQL Server instances installed by default).
        This code is meant to work regardless what SQL Server
        major version is used for the integration test.
#>
function Show-SqlBootstrapLog
{
    [CmdletBinding()]
    param
    (
    )

    $summaryLogPath = Get-ChildItem -Path 'C:\Program Files\Microsoft SQL Server\**\Setup Bootstrap\Log\Summary.txt' |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    $summaryLog = Get-Content $summaryLogPath

    Write-Verbose -Message $('-' * 80) -Verbose
    Write-Verbose -Message 'Summary.txt' -Verbose
    Write-Verbose -Message $('-' * 80) -Verbose
    $summaryLog | ForEach-Object {
        Write-Verbose $_ -Verbose
    }
    Write-Verbose -Message $('-' * 80) -Verbose
}

<#
    This is used in both the configuration file and in this script file
    to run the correct tests depending of what version of SQL Server is
    being tested in the current job.
#>
if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2017')
{
    $script:sqlVersion = '140'
    $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU.iso'
}
else
{
    $script:sqlVersion = '130'
    $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SQLServer2016SP1-FullSlipstream-x64-ENU.iso'
}

Write-Verbose -Message ('Running integration tests for SQL Server version {0}' -f $script:sqlVersion) -Verbose

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    # Download SQL Server media
    if (-not (Test-Path -Path $ConfigurationData.AllNodes.ImagePath))
    {
        # By switching to 'SilentlyContinue' should theoretically increase the download speed.
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        Write-Verbose -Message "Start downloading the SQL Server media at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')" -Verbose

        Invoke-WebRequest -Uri $script:mockSourceMediaUrl -OutFile $ConfigurationData.AllNodes.ImagePath

        Write-Verbose -Message ('SQL Server media file has SHA1 hash ''{0}''' -f (Get-FileHash -Path $ConfigurationData.AllNodes.ImagePath -Algorithm 'SHA1').Hash) -Verbose

        $ProgressPreference = $previousProgressPreference

        # Double check that the SQL media was downloaded.
        if (-not (Test-Path -Path $ConfigurationData.AllNodes.ImagePath))
        {
            Write-Warning -Message ('SQL media could not be downloaded, can not run the integration test.')
            return
        }
        else
        {
            Write-Verbose -Message "Finished downloading the SQL Server media iso at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')" -Verbose
        }
    }
    else
    {
        Write-Verbose -Message 'SQL Server media is already downloaded' -Verbose
    }

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_CreateDependencies_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
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
        }

        $configurationName = "$($script:dscResourceName)_InstallDatabaseEngineNamedInstanceAsSystem_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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
            } -ErrorVariable itBlockError

            # Check if previous It-block failed. If so output the SQL Server setup log file.
            if ( $itBlockError.Count -ne 0 )
            {
                Show-SqlBootstrapLog
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

                $resourceCurrentState.Action                     | Should -Be 'Install'
                $resourceCurrentState.AgtSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccountUsername      | Should -Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlAgentServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.AgtSvcStartupType          | Should -Be 'Automatic'
                $resourceCurrentState.ASServerMode               | Should -Be $ConfigurationData.AllNodes.AnalysisServicesMultiServerMode
                $resourceCurrentState.ASBackupDir                | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\OLAP\Backup")
                $resourceCurrentState.ASCollation                | Should -Be $ConfigurationData.AllNodes.Collation
                $resourceCurrentState.ASConfigDir                | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\OLAP\Config")
                $resourceCurrentState.ASDataDir                  | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\OLAP\Data")
                $resourceCurrentState.ASLogDir                   | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\OLAP\Log")
                $resourceCurrentState.ASTempDir                  | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\OLAP\Temp")
                $resourceCurrentState.ASSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ASSvcAccountUsername       | Should -Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.AsSvcStartupType           | Should -Be 'Automatic'
                $resourceCurrentState.ASSysAdminAccounts         | Should -Be @(
                    $ConfigurationData.AllNodes.SqlAdministratorAccountUserName,
                    "NT SERVICE\SSASTELEMETRY`$$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)"
                )
                $resourceCurrentState.BrowserSvcStartupType      | Should -BeNullOrEmpty
                $resourceCurrentState.ErrorReporting             | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterGroupName   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterIPAddress   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterNetworkName | Should -BeNullOrEmpty
                $resourceCurrentState.Features                   | Should -Be $ConfigurationData.AllNodes.DatabaseEngineNamedInstanceFeatures
                $resourceCurrentState.ForceReboot                | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.InstallSharedDir           | Should -Be $ConfigurationData.AllNodes.InstallSharedDir
                $resourceCurrentState.InstallSharedWOWDir        | Should -Be $ConfigurationData.AllNodes.InstallSharedWOWDir
                $resourceCurrentState.InstallSQLDataDir          | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSQLDataDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\MSSQL")
                $resourceCurrentState.InstanceDir                | Should -Be $ConfigurationData.AllNodes.InstanceDir
                $resourceCurrentState.InstanceID                 | Should -Be $ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName
                $resourceCurrentState.InstanceName               | Should -Be $ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName
                $resourceCurrentState.ISSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ISSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.ProductKey                 | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.SAPwd                      | Should -BeNullOrEmpty
                $resourceCurrentState.SecurityMode               | Should -Be 'SQL'
                $resourceCurrentState.SetupProcessTimeout        | Should -BeNullOrEmpty
                $resourceCurrentState.SourceCredential           | Should -BeNullOrEmpty
                $resourceCurrentState.SourcePath                 | Should -Be "$($ConfigurationData.AllNodes.DriveLetter):\"
                $resourceCurrentState.SQLCollation               | Should -Be $ConfigurationData.AllNodes.Collation
                $resourceCurrentState.SQLSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.SQLSvcAccountUsername      | Should -Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.SqlSvcStartupType          | Should -Be 'Automatic'
                $resourceCurrentState.SQLTempDBDir               | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSQLDataDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\MSSQL\Data")
                $resourceCurrentState.SqlTempDbFileCount         | Should -Be $ConfigurationData.AllNodes.SqlTempDbFileCount
                $resourceCurrentState.SqlTempDbFileSize          | Should -Be $ConfigurationData.AllNodes.SqlTempDbFileSize
                $resourceCurrentState.SqlTempDbFileGrowth        | Should -Be $ConfigurationData.AllNodes.SqlTempDbFileGrowth
                $resourceCurrentState.SQLTempDbLogDir            | Should -BeNullOrEmpty
                $resourceCurrentState.SqlTempDbLogFileSize       | Should -Be $ConfigurationData.AllNodes.SqlTempDbLogFileSize
                $resourceCurrentState.SqlTempDbLogFileGrowth     | Should -Be $ConfigurationData.AllNodes.SqlTempDbLogFileGrowth
                $resourceCurrentState.SQLUserDBDir               | Should -Be $ConfigurationData.AllNodes.SQLUserDBDir
                $resourceCurrentState.SQLUserDBLogDir            | Should -Be $ConfigurationData.AllNodes.SQLUserDBLogDir
                $resourceCurrentState.SQLBackupDir               | Should -Be $ConfigurationData.AllNodes.SQLBackupDir
                $resourceCurrentState.SQMReporting               | Should -BeNullOrEmpty
                $resourceCurrentState.SuppressReboot             | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateEnabled              | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateSource               | Should -BeNullOrEmpty

                # Verify all the accounts are returned in the property SQLSysAdminAccounts.
                $ConfigurationData.AllNodes.SqlAdministratorAccountUserName | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                $ConfigurationData.AllNodes.SqlInstallAccountUserName | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                "NT SERVICE\MSSQL`$$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)" | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                "NT SERVICE\SQLAgent`$$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)" | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                'NT SERVICE\SQLWriter' | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                'NT SERVICE\Winmgmt' | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                'sa' | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_StopServicesInstance_Config"

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
        }

        $configurationName = "$($script:dscResourceName)_InstallDatabaseEngineDefaultInstanceAsUser_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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
            } -ErrorVariable itBlockError

            # Check if previous It-block failed. If so output the SQL Server setup log file.
            if ( $itBlockError.Count -ne 0 )
            {
                Show-SqlBootstrapLog
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

                $resourceCurrentState.Action                     | Should -Be 'Install'
                $resourceCurrentState.AgtSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccountUsername      | Should -Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlAgentServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.ASServerMode               | Should -BeNullOrEmpty
                $resourceCurrentState.ASBackupDir                | Should -BeNullOrEmpty
                $resourceCurrentState.ASCollation                | Should -BeNullOrEmpty
                $resourceCurrentState.ASConfigDir                | Should -BeNullOrEmpty
                $resourceCurrentState.ASDataDir                  | Should -BeNullOrEmpty
                $resourceCurrentState.ASLogDir                   | Should -BeNullOrEmpty
                $resourceCurrentState.ASTempDir                  | Should -BeNullOrEmpty
                $resourceCurrentState.ASSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ASSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.ASSysAdminAccounts         | Should -BeNullOrEmpty
                $resourceCurrentState.BrowserSvcStartupType      | Should -BeNullOrEmpty
                $resourceCurrentState.ErrorReporting             | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterGroupName   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterIPAddress   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterNetworkName | Should -BeNullOrEmpty
                $resourceCurrentState.Features                   | Should -Be $ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceFeatures
                $resourceCurrentState.ForceReboot                | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.InstallSharedDir           | Should -Be $ConfigurationData.AllNodes.InstallSharedDir
                $resourceCurrentState.InstallSharedWOWDir        | Should -Be $ConfigurationData.AllNodes.InstallSharedWOWDir
                $resourceCurrentState.InstallSQLDataDir          | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL")
                $resourceCurrentState.InstanceDir                | Should -Be $ConfigurationData.AllNodes.InstallSharedDir
                $resourceCurrentState.InstanceID                 | Should -Be $ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName
                $resourceCurrentState.InstanceName               | Should -Be $ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName
                $resourceCurrentState.ISSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ISSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.ProductKey                 | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.SAPwd                      | Should -BeNullOrEmpty
                $resourceCurrentState.SecurityMode               | Should -Be 'Windows'
                $resourceCurrentState.SetupProcessTimeout        | Should -BeNullOrEmpty
                $resourceCurrentState.SourceCredential           | Should -BeNullOrEmpty
                $resourceCurrentState.SourcePath                 | Should -Be "$($ConfigurationData.AllNodes.DriveLetter):\"
                $resourceCurrentState.SQLBackupDir               | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL\Backup")
                $resourceCurrentState.SQLCollation               | Should -Be $ConfigurationData.AllNodes.Collation
                $resourceCurrentState.SQLSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.SQLSvcAccountUsername      | Should -Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.SQLTempDBDir               | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL\Data")
                $resourceCurrentState.SQLTempDBLogDir            | Should -BeNullOrEmpty
                $resourceCurrentState.SQMReporting               | Should -BeNullOrEmpty
                $resourceCurrentState.SuppressReboot             | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateEnabled              | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateSource               | Should -BeNullOrEmpty

                # Regression test for issue #1287
                $resourceCurrentState.SQLUserDBDir               | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL\DATA\")
                $resourceCurrentState.SQLUserDBLogDir            | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL\DATA\")

                # Verify all the accounts are returned in the property SQLSysAdminAccounts.
                $ConfigurationData.AllNodes.SqlAdministratorAccountUserName | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                $ConfigurationData.AllNodes.SqlInstallAccountUserName | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                "NT SERVICE\$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)" | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                "NT SERVICE\SQLSERVERAGENT" | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                'NT SERVICE\SQLWriter' | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                'NT SERVICE\Winmgmt' | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
                'sa' | Should -BeIn $resourceCurrentState.SQLSysAdminAccounts
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_StopSqlServerDefaultInstance_Config"

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
        }

        $configurationName = "$($script:dscResourceName)_InstallTabularAnalysisServicesAsSystem_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath                  = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData           = $ConfigurationData
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
            } -ErrorVariable itBlockError

            # Check if previous It-block failed. If so output the SQL Server setup log file.
            if ( $itBlockError.Count -ne 0 )
            {
                Show-SqlBootstrapLog
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

                $resourceCurrentState.Action                     | Should -Be 'Install'
                $resourceCurrentState.AgtSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccountUsername      | Should -BeNullOrEmpty
                $resourceCurrentState.ASServerMode               | Should -Be $ConfigurationData.AllNodes.AnalysisServicesTabularServerMode
                $resourceCurrentState.ASBackupDir                | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Backup")
                $resourceCurrentState.ASCollation                | Should -Be $ConfigurationData.AllNodes.Collation
                $resourceCurrentState.ASConfigDir                | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Config")
                $resourceCurrentState.ASDataDir                  | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Data")
                $resourceCurrentState.ASLogDir                   | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Log")
                $resourceCurrentState.ASTempDir                  | Should -Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Temp")
                $resourceCurrentState.ASSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ASSvcAccountUsername       | Should -Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.ASSysAdminAccounts         | Should -Be @(
                    $ConfigurationData.AllNodes.SqlAdministratorAccountUserName,
                    "NT SERVICE\SSASTELEMETRY`$$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)"
                )
                $resourceCurrentState.BrowserSvcStartupType      | Should -BeNullOrEmpty
                $resourceCurrentState.ErrorReporting             | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterGroupName   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterIPAddress   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterNetworkName | Should -BeNullOrEmpty
                $resourceCurrentState.Features                   | Should -Be $ConfigurationData.AllNodes.AnalysisServicesTabularFeatures
                $resourceCurrentState.ForceReboot                | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.InstallSharedDir           | Should -Be $ConfigurationData.AllNodes.InstallSharedDir
                $resourceCurrentState.InstallSharedWOWDir        | Should -Be $ConfigurationData.AllNodes.InstallSharedWOWDir
                $resourceCurrentState.InstallSQLDataDir          | Should -BeNullOrEmpty
                $resourceCurrentState.InstanceDir                | Should -BeNullOrEmpty
                $resourceCurrentState.InstanceID                 | Should -BeNullOrEmpty
                $resourceCurrentState.InstanceName               | Should -Be $ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName
                $resourceCurrentState.ISSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ISSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.ProductKey                 | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.SAPwd                      | Should -BeNullOrEmpty
                $resourceCurrentState.SecurityMode               | Should -BeNullOrEmpty
                $resourceCurrentState.SetupProcessTimeout        | Should -BeNullOrEmpty
                $resourceCurrentState.SourceCredential           | Should -BeNullOrEmpty
                $resourceCurrentState.SourcePath                 | Should -Be "$($ConfigurationData.AllNodes.DriveLetter):\"
                $resourceCurrentState.SQLBackupDir               | Should -BeNullOrEmpty
                $resourceCurrentState.SQLCollation               | Should -BeNullOrEmpty
                $resourceCurrentState.SQLSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.SQLSvcAccountUsername      | Should -BeNullOrEmpty
                $resourceCurrentState.SQLSysAdminAccounts        | Should -BeNullOrEmpty
                $resourceCurrentState.SQLTempDBDir               | Should -BeNullOrEmpty
                $resourceCurrentState.SQLTempDBLogDir            | Should -BeNullOrEmpty
                $resourceCurrentState.SQLUserDBDir               | Should -BeNullOrEmpty
                $resourceCurrentState.SQLUserDBLogDir            | Should -BeNullOrEmpty
                $resourceCurrentState.SQMReporting               | Should -BeNullOrEmpty
                $resourceCurrentState.SuppressReboot             | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateEnabled              | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateSource               | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_StopTabularAnalysisServices_Config"

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
        }

        $configurationName = "$($script:dscResourceName)_StartServicesInstance_Config"

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
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Write-Verbose -Message ('Test {1} run for {0} minutes' -f ([System.TimeSpan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString('mm\:ss'), $script:DSCResourceFriendlyName) -Verbose
    $script:timer.Stop()
}
