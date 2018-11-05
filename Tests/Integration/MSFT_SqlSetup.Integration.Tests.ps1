# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 1)]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceFriendlyName = 'SqlSetup'
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
    Workaround for issue #774. In the appveyor.yml file the folder
    C:\Program Files (x86)\Microsoft SQL Server\**\Tools\PowerShell\Modules
    was renamed to
    C:\Program Files (x86)\Microsoft SQL Server\**\Tools\PowerShell\Modules.old
    here we rename back the folder to the correct name. Only the version need
    for our tests are renamed.
#>
$sqlModulePath = Get-ChildItem -Path 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\*.old'
$sqlModulePath | ForEach-Object -Process {
    $newFolderName = (Split-Path -Path $_ -Leaf) -replace '\.old'
    Write-Verbose ('Renaming ''{0}'' to ''..\{1}''' -f $_, $newFolderName) -Verbose
    Rename-Item $_ -NewName $newFolderName -Force
}

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    # These sets variables used for verification from the dot-sourced $ConfigurationData variable.
    $mockDatabaseEngineNamedInstanceName = $ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName
    $mockDatabaseEngineNamedInstanceFeatures = $ConfigurationData.AllNodes.DatabaseEngineNamedInstanceFeatures
    $mockDatabaseEngineDefaultInstanceName = $ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName
    $mockDatabaseEngineDefaultInstanceFeatures = $ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceFeatures
    $mockAnalysisServicesTabularInstanceName = $ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName
    $mockAnalysisServicesTabularFeatures = $ConfigurationData.AllNodes.AnalysisServicesTabularFeatures
    $mockAnalysisServicesTabularServerMode = $ConfigurationData.AllNodes.AnalysisServicesTabularServerMode
    $mockAnalysisServicesMultiServerMode = $ConfigurationData.AllNodes.AnalysisServicesMultiServerMode
    $mockCollation = $ConfigurationData.AllNodes.Collation
    $mockInstallSharedDir = $ConfigurationData.AllNodes.InstallSharedDir
    $mockInstallSharedWOWDir = $ConfigurationData.AllNodes.InstallSharedWOWDir
    $mockUpdateEnable = $ConfigurationData.AllNodes.UpdateEnabled
    $mockSuppressReboot = $ConfigurationData.AllNodes.SuppressReboot
    $mockForceReboot = $ConfigurationData.AllNodes.ForceReboot
    $mockIsoMediaFilePath = $ConfigurationData.AllNodes.ImagePath
    $mockIsoMediaDriveLetter = $ConfigurationData.AllNodes.DriveLetter

    $mockSourceMediaUrl = 'https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SQLServer2016SP1-FullSlipstream-x64-ENU.iso'

    # Download SQL Server media
    if (-not (Test-Path -Path $mockIsoMediaFilePath))
    {
        Write-Verbose -Message "Start downloading the SQL Server media iso at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')" -Verbose

        Invoke-WebRequest -Uri $mockSourceMediaUrl -OutFile $mockIsoMediaFilePath

        # Double check that the SQL media was downloaded.
        if (-not (Test-Path -Path $mockIsoMediaFilePath))
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

    $mockSqlInstallAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
    $mockSqlInstallAccountUserName = "$env:COMPUTERNAME\SqlInstall"
    $mockSqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlInstallAccountUserName, $mockSqlInstallAccountPassword

    $mockSqlAdminAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
    $mockSqlAdminAccountUserName = "$env:COMPUTERNAME\SqlAdmin"
    $mockSqlAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAdminAccountUserName, $mockSqlAdminAccountPassword

    $mockSqlServicePrimaryAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
    $mockSqlServicePrimaryAccountUserName = "$env:COMPUTERNAME\svc-SqlPrimary"
    $mockSqlServicePrimaryCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlServicePrimaryAccountUserName, $mockSqlServicePrimaryAccountPassword

    $mockSqlAgentServicePrimaryAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
    $mockSqlAgentServicePrimaryAccountUserName = "$env:COMPUTERNAME\svc-SqlAgentPri"
    $mockSqlAgentServicePrimaryCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAgentServicePrimaryAccountUserName, $mockSqlAgentServicePrimaryAccountPassword

    $mockSqlServiceSecondaryAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
    $mockSqlServiceSecondaryAccountUserName = "$env:COMPUTERNAME\svc-SqlSecondary"
    $mockSqlServiceSecondaryCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlServiceSecondaryAccountUserName, $mockSqlServiceSecondaryAccountPassword

    $mockSqlAgentServiceSecondaryAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
    $mockSqlAgentServiceSecondaryAccountUserName = "$env:COMPUTERNAME\svc-SqlAgentSec"
    $mockSqlAgentServiceSecondaryCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAgentServiceSecondaryAccountUserName, $mockSqlAgentServiceSecondaryAccountPassword

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
                        SqlAdministratorCredential         = $mockSqlAdminCredential
                        SqlServicePrimaryCredential        = $mockSqlServicePrimaryCredential
                        SqlAgentServicePrimaryCredential   = $mockSqlAgentServicePrimaryCredential
                        SqlServiceSecondaryCredential      = $mockSqlServiceSecondaryCredential
                        SqlAgentServiceSecondaryCredential = $mockSqlAgentServiceSecondaryCredential
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

        $configurationName = "$($script:DSCResourceName)_InstallDatabaseEngineNamedInstanceAsSystem_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential             = $mockSqlInstallCredential
                        SqlAdministratorCredential       = $mockSqlAdminCredential
                        SqlServicePrimaryCredential      = $mockSqlServicePrimaryCredential
                        SqlAgentServicePrimaryCredential = $mockSqlAgentServicePrimaryCredential
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
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Action                     | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccountUsername      | Should -Be ('.\{0}' -f (Split-Path -Path $mockSqlAgentServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.AgtSvcStartupType          | Should -Be 'Automatic'
                $resourceCurrentState.ASServerMode               | Should -Be $mockAnalysisServicesMultiServerMode
                $resourceCurrentState.ASBackupDir                | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockDatabaseEngineNamedInstanceName\OLAP\Backup")
                $resourceCurrentState.ASCollation                | Should -Be $mockCollation
                $resourceCurrentState.ASConfigDir                | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockDatabaseEngineNamedInstanceName\OLAP\Config")
                $resourceCurrentState.ASDataDir                  | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockDatabaseEngineNamedInstanceName\OLAP\Data")
                $resourceCurrentState.ASLogDir                   | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockDatabaseEngineNamedInstanceName\OLAP\Log")
                $resourceCurrentState.ASTempDir                  | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockDatabaseEngineNamedInstanceName\OLAP\Temp")
                $resourceCurrentState.ASSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ASSvcAccountUsername       | Should -Be ('.\{0}' -f (Split-Path -Path $mockSqlServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.AsSvcStartupType           | Should -Be 'Automatic'
                $resourceCurrentState.ASSysAdminAccounts         | Should -Be @(
                    $mockSqlAdminAccountUserName,
                    "NT SERVICE\SSASTELEMETRY`$$mockDatabaseEngineNamedInstanceName"
                )
                $resourceCurrentState.BrowserSvcStartupType      | Should -BeNullOrEmpty
                $resourceCurrentState.ErrorReporting             | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterGroupName   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterIPAddress   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterNetworkName | Should -BeNullOrEmpty
                $resourceCurrentState.Features                   | Should -Be $mockDatabaseEngineNamedInstanceFeatures
                $resourceCurrentState.ForceReboot                | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.InstallSharedDir           | Should -Be $mockInstallSharedDir
                $resourceCurrentState.InstallSharedWOWDir        | Should -Be $mockInstallSharedWOWDir
                $resourceCurrentState.InstallSQLDataDir          | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockDatabaseEngineNamedInstanceName\MSSQL")
                $resourceCurrentState.InstanceDir                | Should -Be $mockInstallSharedDir
                $resourceCurrentState.InstanceID                 | Should -Be $mockDatabaseEngineNamedInstanceName
                $resourceCurrentState.InstanceName               | Should -Be $mockDatabaseEngineNamedInstanceName
                $resourceCurrentState.ISSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ISSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.ProductKey                 | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.SAPwd                      | Should -BeNullOrEmpty
                $resourceCurrentState.SecurityMode               | Should -Be 'SQL'
                $resourceCurrentState.SetupProcessTimeout        | Should -BeNullOrEmpty
                $resourceCurrentState.SourceCredential           | Should -BeNullOrEmpty
                $resourceCurrentState.SourcePath                 | Should -Be "$($mockIsoMediaDriveLetter):\"
                $resourceCurrentState.SQLBackupDir               | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockDatabaseEngineNamedInstanceName\MSSQL\Backup")
                $resourceCurrentState.SQLCollation               | Should -Be $mockCollation
                $resourceCurrentState.SQLSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.SQLSvcAccountUsername      | Should -Be ('.\{0}' -f (Split-Path -Path $mockSqlServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.SqlSvcStartupType          | Should -Be 'Automatic'
                $resourceCurrentState.SQLSysAdminAccounts        | Should -Be @(
                    $mockSqlAdminAccountUserName,
                    $mockSqlInstallAccountUserName,
                    "NT SERVICE\MSSQL`$$mockDatabaseEngineNamedInstanceName",
                    "NT SERVICE\SQLAgent`$$mockDatabaseEngineNamedInstanceName",
                    'NT SERVICE\SQLWriter',
                    'NT SERVICE\Winmgmt',
                    'sa'
                )
                $resourceCurrentState.SQLTempDBDir               | Should -BeNullOrEmpty
                $resourceCurrentState.SQLTempDBLogDir            | Should -BeNullOrEmpty
                $resourceCurrentState.SQLUserDBDir               | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockDatabaseEngineNamedInstanceName\MSSQL\DATA\")
                $resourceCurrentState.SQLUserDBLogDir            | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockDatabaseEngineNamedInstanceName\MSSQL\DATA\")
                $resourceCurrentState.SQMReporting               | Should -BeNullOrEmpty
                $resourceCurrentState.SuppressReboot             | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateEnabled              | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateSource               | Should -BeNullOrEmpty

            }
        }

        $configurationName = "$($script:DSCResourceName)_StopMultiAnalysisServicesInstance_Config"

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

        $configurationName = "$($script:DSCResourceName)_InstallDatabaseEngineDefaultInstanceAsUser_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential             = $mockSqlInstallCredential
                        SqlAdministratorCredential       = $mockSqlAdminCredential
                        SqlServicePrimaryCredential      = $mockSqlServicePrimaryCredential
                        SqlAgentServicePrimaryCredential = $mockSqlAgentServicePrimaryCredential
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
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Action                     | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccountUsername      | Should -Be ('.\{0}' -f (Split-Path -Path $mockSqlAgentServicePrimaryAccountUserName -Leaf))
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
                $resourceCurrentState.Features                   | Should -Be $mockDatabaseEngineDefaultInstanceFeatures
                $resourceCurrentState.ForceReboot                | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.InstallSharedDir           | Should -Be $mockInstallSharedDir
                $resourceCurrentState.InstallSharedWOWDir        | Should -Be $mockInstallSharedWOWDir
                $resourceCurrentState.InstallSQLDataDir          | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockDatabaseEngineDefaultInstanceName\MSSQL")
                $resourceCurrentState.InstanceDir                | Should -Be $mockInstallSharedDir
                $resourceCurrentState.InstanceID                 | Should -Be $mockDatabaseEngineDefaultInstanceName
                $resourceCurrentState.InstanceName               | Should -Be $mockDatabaseEngineDefaultInstanceName
                $resourceCurrentState.ISSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ISSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.ProductKey                 | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.SAPwd                      | Should -BeNullOrEmpty
                $resourceCurrentState.SecurityMode               | Should -Be 'Windows'
                $resourceCurrentState.SetupProcessTimeout        | Should -BeNullOrEmpty
                $resourceCurrentState.SourceCredential           | Should -BeNullOrEmpty
                $resourceCurrentState.SourcePath                 | Should -Be "$($mockIsoMediaDriveLetter):\"
                $resourceCurrentState.SQLBackupDir               | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockDatabaseEngineDefaultInstanceName\MSSQL\Backup")
                $resourceCurrentState.SQLCollation               | Should -Be $mockCollation
                $resourceCurrentState.SQLSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.SQLSvcAccountUsername      | Should -Be ('.\{0}' -f (Split-Path -Path $mockSqlServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.SQLSysAdminAccounts        | Should -Be @(
                    $mockSqlAdminAccountUserName,
                    $mockSqlInstallAccountUserName,
                    "NT SERVICE\$mockDatabaseEngineDefaultInstanceName",
                    "NT SERVICE\SQLSERVERAGENT",
                    'NT SERVICE\SQLWriter',
                    'NT SERVICE\Winmgmt',
                    'sa'
                )
                $resourceCurrentState.SQLTempDBDir               | Should -BeNullOrEmpty
                $resourceCurrentState.SQLTempDBLogDir            | Should -BeNullOrEmpty
                $resourceCurrentState.SQLUserDBDir               | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockDatabaseEngineDefaultInstanceName\MSSQL\DATA\")
                $resourceCurrentState.SQLUserDBLogDir            | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockDatabaseEngineDefaultInstanceName\MSSQL\DATA\")
                $resourceCurrentState.SQMReporting               | Should -BeNullOrEmpty
                $resourceCurrentState.SuppressReboot             | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateEnabled              | Should -BeNullOrEmpty
                $resourceCurrentState.UpdateSource               | Should -BeNullOrEmpty

            }
        }

        $configurationName = "$($script:DSCResourceName)_StopSqlServerDefaultInstance_Config"

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

        $configurationName = "$($script:DSCResourceName)_InstallTabularAnalysisServicesAsSystem_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential        = $mockSqlInstallCredential
                        SqlAdministratorCredential  = $mockSqlAdminCredential
                        SqlServicePrimaryCredential = $mockSqlServicePrimaryCredential
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
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.Action                     | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccount              | Should -BeNullOrEmpty
                $resourceCurrentState.AgtSvcAccountUsername      | Should -BeNullOrEmpty
                $resourceCurrentState.ASServerMode               | Should -Be $mockAnalysisServicesTabularServerMode
                $resourceCurrentState.ASBackupDir                | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockAnalysisServicesTabularInstanceName\OLAP\Backup")
                $resourceCurrentState.ASCollation                | Should -Be $mockCollation
                $resourceCurrentState.ASConfigDir                | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockAnalysisServicesTabularInstanceName\OLAP\Config")
                $resourceCurrentState.ASDataDir                  | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockAnalysisServicesTabularInstanceName\OLAP\Data")
                $resourceCurrentState.ASLogDir                   | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockAnalysisServicesTabularInstanceName\OLAP\Log")
                $resourceCurrentState.ASTempDir                  | Should -Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSAS13.$mockAnalysisServicesTabularInstanceName\OLAP\Temp")
                $resourceCurrentState.ASSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ASSvcAccountUsername       | Should -Be ('.\{0}' -f (Split-Path -Path $mockSqlServicePrimaryAccountUserName -Leaf))
                $resourceCurrentState.ASSysAdminAccounts         | Should -Be @(
                    $mockSqlAdminAccountUserName,
                    "NT SERVICE\SSASTELEMETRY`$$mockAnalysisServicesTabularInstanceName"
                )
                $resourceCurrentState.BrowserSvcStartupType      | Should -BeNullOrEmpty
                $resourceCurrentState.ErrorReporting             | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterGroupName   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterIPAddress   | Should -BeNullOrEmpty
                $resourceCurrentState.FailoverClusterNetworkName | Should -BeNullOrEmpty
                $resourceCurrentState.Features                   | Should -Be $mockAnalysisServicesTabularFeatures
                $resourceCurrentState.ForceReboot                | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.FTSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.InstallSharedDir           | Should -Be $mockInstallSharedDir
                $resourceCurrentState.InstallSharedWOWDir        | Should -Be $mockInstallSharedWOWDir
                $resourceCurrentState.InstallSQLDataDir          | Should -BeNullOrEmpty
                $resourceCurrentState.InstanceDir                | Should -BeNullOrEmpty
                $resourceCurrentState.InstanceID                 | Should -BeNullOrEmpty
                $resourceCurrentState.InstanceName               | Should -Be $mockAnalysisServicesTabularInstanceName
                $resourceCurrentState.ISSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.ISSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.ProductKey                 | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccount               | Should -BeNullOrEmpty
                $resourceCurrentState.RSSvcAccountUsername       | Should -BeNullOrEmpty
                $resourceCurrentState.SAPwd                      | Should -BeNullOrEmpty
                $resourceCurrentState.SecurityMode               | Should -BeNullOrEmpty
                $resourceCurrentState.SetupProcessTimeout        | Should -BeNullOrEmpty
                $resourceCurrentState.SourceCredential           | Should -BeNullOrEmpty
                $resourceCurrentState.SourcePath                 | Should -Be "$($mockIsoMediaDriveLetter):\"
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
        }

        $configurationName = "$($script:DSCResourceName)_StopTabularAnalysisServices_Config"

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
