$script:DSCModuleName = 'xSQLServer'
$script:DSCResourceName = 'MSFT_xSQLServerSetup'

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

$mockInstanceName = 'DSCSQL2016'
$mockFeatures = 'SQLENGINE,CONN,BC,SDK'
$mockSqlCollation = 'Finnish_Swedish_CI_AS'
$mockInstallSharedDir = 'C:\Program Files\Microsoft SQL Server'
$mockInstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
$mockUpdateEnable = 'False'
$mockSuppressReboot = $true
$mockForceReboot = $false

$mockSourceMediaUrl = 'http://care.dlservice.microsoft.com/dl/download/F/E/9/FE9397FA-BFAB-4ADD-8B97-91234BC774B2/SQLServer2016-x64-ENU.iso'
$mockIsoMediaFilePath = "$env:TEMP\SQL2016.iso"

# Get a spare drive letter
$mockLastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
$mockIsoMediaDriveLetter = [char](([int][char]$mockLastDrive) + 1)

$mockSqlInstallAccountPassword = ConvertTo-SecureString 'P@ssw0rd1' -AsPlainText -Force
$mockSqlInstallAccountUserName = "$env:COMPUTERNAME\SqlInstall"
$mockSqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlInstallAccountUserName, $mockSqlInstallAccountPassword

$mockSqlAdminAccountPassword = ConvertTo-SecureString 'P@ssw0rd1' -AsPlainText -Force
$mockSqlAdminAccountUserName = "$env:COMPUTERNAME\SqlAdmin"
$mockSqlAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAdminAccountUserName, $mockSqlAdminAccountPassword

$mockSqlServiceAccountPassword = ConvertTo-SecureString 'yig-C^Equ3' -AsPlainText -Force
$mockSqlServiceAccountUserName = "$env:COMPUTERNAME\svc-Sql"
$mockSqlServiceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlServiceAccountUserName, $mockSqlServiceAccountPassword

$mockSqlAgentServiceAccountPassword = ConvertTo-SecureString 'yig-C^Equ3' -AsPlainText -Force
$mockSqlAgentServiceAccountUserName = "$env:COMPUTERNAME\svc-SqlAgent"
$mockSqlAgentServiceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAgentServiceAccountUserName, $mockSqlAgentServiceAccountPassword

# Install dependent DSC modules
Install-Module -Name PSDscResources -Scope CurrentUser -Force
Install-Module -Name xStorage -Scope CurrentUser -Force

# Download SQL Server media
if (-not (Test-Path -Path $mockIsoMediaFilePath))
{
    Write-Verbose "Start downloading the SQL Server media iso at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')" -Verbose

    Invoke-WebRequest $mockSourceMediaUrl -OutFile $mockIsoMediaFilePath

    # Double check that the SQL media was downloaded.
    if (-not (Test-Path -Path $mockIsoMediaFilePath))
    {
        Write-Warning -Message ('SQL media could not be downloaded, can not run the integration test.')
        return
    }
    else
    {
        Write-Verbose "Finished downloading the SQL Server media iso at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')" -Verbose
    }
}
else
{
    Write-Verbose 'SQL Server media is already downloaded' -Verbose
}

try
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                    = 'localhost'
                ImagePath                   = $mockIsoMediaFilePath
                DriveLetter                 = $mockIsoMediaDriveLetter
                InstanceName                = $mockInstanceName
                Features                    = $mockFeatures
                SQLCollation                = $mockSqlCollation
                InstallSharedDir            = $mockInstallSharedDir
                InstallSharedWOWDir         = $mockInstallSharedWOWDir
                UpdateEnabled               = $mockUpdateEnable
                SuppressReboot              = $mockSuppressReboot
                ForceReboot                 = $mockForceReboot

                PSDscAllowPlainTextPassword = $true
            }
        )
    }

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    Describe "$($script:DSCResourceName)_Integration" {
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_InstallSqlEngineAsSystem_Config" `
                    -SqlInstallCredential $mockSqlInstallCredential `
                    -SqlAdministratorCredential $mockSqlAdminCredential `
                    -SqlServiceCredential $mockSqlServiceCredential `
                    -SqlAgentServiceCredential $mockSqlAgentServiceCredential `
                    -OutputPath $TestDrive `
                    -ConfigurationData $ConfigurationData

                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should Not Throw
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the SQL Server setup log file.
        if ( $itBlockError.Count -ne 0 )
        {
            <#
                Below code will output the Summary.txt log file, this is to be
                able to debug any problems that potentially occurred during setup.
                This will pick up the newest Summary.txt log file, so any
                other log files will be ignored (AppVeyor build worker has
                SQL Server instances installed by default).
                This code is meant to work regardless what SQL Server
                major version is used for the integration test.
            #>
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

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $currentConfiguration = Get-DscConfiguration

            $resourceCurrentState = $currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:DSCResourceName)_InstallSqlEngineAsSystem_Config"
            } | Where-Object -FilterScript {
                $_.ResourceId -eq '[xSQLServerSetup]Integration_Test'
            }

            $resourceCurrentState.Action                     | Should BeNullOrEmpty
            $resourceCurrentState.AgtSvcAccount              | Should BeNullOrEmpty
            $resourceCurrentState.AgtSvcAccountUsername      | Should Be ('.\{0}' -f (Split-Path -Path $mockSqlAgentServiceAccountUserName -Leaf))
            $resourceCurrentState.ASBackupDir                | Should BeNullOrEmpty
            $resourceCurrentState.ASCollation                | Should BeNullOrEmpty
            $resourceCurrentState.ASConfigDir                | Should BeNullOrEmpty
            $resourceCurrentState.ASDataDir                  | Should BeNullOrEmpty
            $resourceCurrentState.ASLogDir                   | Should BeNullOrEmpty
            $resourceCurrentState.ASSvcAccount               | Should BeNullOrEmpty
            $resourceCurrentState.ASSvcAccountUsername       | Should BeNullOrEmpty
            $resourceCurrentState.ASSysAdminAccounts         | Should BeNullOrEmpty
            $resourceCurrentState.ASTempDir                  | Should BeNullOrEmpty
            $resourceCurrentState.BrowserSvcStartupType      | Should BeNullOrEmpty
            $resourceCurrentState.ErrorReporting             | Should BeNullOrEmpty
            $resourceCurrentState.FailoverClusterGroupName   | Should BeNullOrEmpty
            $resourceCurrentState.FailoverClusterIPAddress   | Should BeNullOrEmpty
            $resourceCurrentState.FailoverClusterNetworkName | Should BeNullOrEmpty
            $resourceCurrentState.Features                   | Should Be $mockFeatures
            $resourceCurrentState.ForceReboot                | Should BeNullOrEmpty
            $resourceCurrentState.FTSvcAccount               | Should BeNullOrEmpty
            $resourceCurrentState.FTSvcAccountUsername       | Should BeNullOrEmpty
            $resourceCurrentState.InstallSharedDir           | Should Be $mockInstallSharedDir
            $resourceCurrentState.InstallSharedWOWDir        | Should Be $mockInstallSharedWOWDir
            $resourceCurrentState.InstallSQLDataDir          | Should Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockInstanceName\MSSQL")
            $resourceCurrentState.InstanceDir                | Should Be $mockInstallSharedDir
            $resourceCurrentState.InstanceID                 | Should Be $mockInstanceName
            $resourceCurrentState.InstanceName               | Should Be $mockInstanceName
            $resourceCurrentState.ISSvcAccount               | Should BeNullOrEmpty
            $resourceCurrentState.ISSvcAccountUsername       | Should BeNullOrEmpty
            $resourceCurrentState.ProductKey                 | Should BeNullOrEmpty
            $resourceCurrentState.RSSvcAccount               | Should BeNullOrEmpty
            $resourceCurrentState.RSSvcAccountUsername       | Should BeNullOrEmpty
            $resourceCurrentState.SAPwd                      | Should BeNullOrEmpty
            $resourceCurrentState.SecurityMode               | Should Be 'Windows'
            $resourceCurrentState.SetupProcessTimeout        | Should BeNullOrEmpty
            $resourceCurrentState.SourceCredential           | Should BeNullOrEmpty
            $resourceCurrentState.SourcePath                 | Should Be "$($mockIsoMediaDriveLetter):\"
            $resourceCurrentState.SQLBackupDir               | Should Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockInstanceName\MSSQL\Backup")
            $resourceCurrentState.SQLCollation               | Should Be $mockSqlCollation
            $resourceCurrentState.SQLSvcAccount              | Should BeNullOrEmpty
            $resourceCurrentState.SQLSvcAccountUsername      | Should Be ('.\{0}' -f (Split-Path -Path $mockSqlServiceAccountUserName -Leaf))
            $resourceCurrentState.SQLSysAdminAccounts        | Should Be @(
                $mockSqlAdminAccountUserName,
                "NT SERVICE\MSSQL`$$mockInstanceName",
                "NT SERVICE\SQLAgent`$$mockInstanceName",
                'NT SERVICE\SQLWriter',
                'NT SERVICE\Winmgmt',
                'sa'
            )
            $resourceCurrentState.SQLTempDBDir               | Should BeNullOrEmpty
            $resourceCurrentState.SQLTempDBLogDir            | Should BeNullOrEmpty
            $resourceCurrentState.SQLUserDBDir               | Should Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockInstanceName\MSSQL\DATA\")
            $resourceCurrentState.SQLUserDBLogDir            | Should Be (Join-Path -Path $mockInstallSharedDir -ChildPath "MSSQL13.$mockInstanceName\MSSQL\DATA\")
            $resourceCurrentState.SQMReporting               | Should BeNullOrEmpty
            $resourceCurrentState.SuppressReboot             | Should BeNullOrEmpty
            $resourceCurrentState.UpdateEnabled              | Should BeNullOrEmpty
            $resourceCurrentState.UpdateSource               | Should BeNullOrEmpty

        }
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
