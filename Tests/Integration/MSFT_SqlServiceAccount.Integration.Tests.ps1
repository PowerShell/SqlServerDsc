# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceFriendlyName = 'SqlServiceAccount'
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

$moc
try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    <#
        This should have used $ConfigurationData.AllNodes.ServiceTypeDatabaseEngine
        and $ConfigurationData.AllNodes.ServiceTypeSqlServerAgent, but due to a
        bug (see issue #981) we have to set this to 'SqlServer' and 'SqlAgent'
        respectively.
    #>
    $mockServiceTypeDatabaseEngine = 'SqlServer'
    $mockServiceTypeSqlServerAgent = 'SqlAgent'

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:DSCResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:DSCResourceName)_CreateDependencies_Config"

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

        $configurationName = "$($script:DSCResourceName)_DatabaseEngine_DefaultInstance_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlServiceSecondaryCredential = $mockSqlServiceSecondaryCredential
                        OutputPath                    = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData             = $ConfigurationData
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

                $resourceCurrentState.ServiceType | Should -Be $mockServiceTypeDatabaseEngine
                $resourceCurrentState.ServiceAccountName | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME, (Split-Path -Path $mockSqlServiceSecondaryAccountUserName -Leaf))
            }
        }

        $configurationName = "$($script:DSCResourceName)_SqlServerAgent_DefaultInstance_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential               = $mockSqlInstallCredential
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

                $resourceCurrentState.ServiceType | Should -Be $mockServiceTypeSqlServerAgent
                $resourceCurrentState.ServiceAccountName | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME, (Split-Path -Path $mockSqlAgentServiceSecondaryAccountUserName -Leaf))
            }
        }

        $configurationName = "$($script:DSCResourceName)_DatabaseEngine_DefaultInstance_Restore_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlServicePrimaryCredential = $mockSqlServicePrimaryCredential
                        OutputPath                    = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData             = $ConfigurationData
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

                $resourceCurrentState.ServiceType | Should -Be $mockServiceTypeDatabaseEngine
                $resourceCurrentState.ServiceAccountName | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME, (Split-Path -Path $mockSqlServicePrimaryAccountUserName -Leaf))
            }
        }

        $configurationName = "$($script:DSCResourceName)_SqlServerAgent_DefaultInstance_Restore_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential             = $mockSqlInstallCredential
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

                $resourceCurrentState.ServiceType | Should -Be $mockServiceTypeSqlServerAgent
                $resourceCurrentState.ServiceAccountName | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME, (Split-Path -Path $mockSqlAgentServicePrimaryAccountUserName -Leaf))
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

        $configurationName = "$($script:DSCResourceName)_DatabaseEngine_NamedInstance_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlServiceSecondaryCredential = $mockSqlServiceSecondaryCredential
                        OutputPath                    = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData             = $ConfigurationData
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
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $currentConfiguration = Get-DscConfiguration

                $resourceCurrentState = $currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.ServiceType | Should -Be $mockServiceTypeDatabaseEngine
                $resourceCurrentState.ServiceAccountName | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME, (Split-Path -Path $mockSqlServiceSecondaryAccountUserName -Leaf))
            }
        }

        $configurationName = "$($script:DSCResourceName)_SqlServerAgent_NamedInstance_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential               = $mockSqlInstallCredential
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

                $resourceCurrentState.ServiceType | Should -Be $mockServiceTypeSqlServerAgent
                $resourceCurrentState.ServiceAccountName | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME, (Split-Path -Path $mockSqlAgentServiceSecondaryAccountUserName -Leaf))
            }
        }

        $configurationName = "$($script:DSCResourceName)_DatabaseEngine_NamedInstance_Restore_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlServicePrimaryCredential = $mockSqlServicePrimaryCredential
                        OutputPath                    = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData             = $ConfigurationData
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

                $resourceCurrentState.ServiceType | Should -Be $mockServiceTypeDatabaseEngine
                $resourceCurrentState.ServiceAccountName | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME, (Split-Path -Path $mockSqlServicePrimaryAccountUserName -Leaf))
            }
        }

        $configurationName = "$($script:DSCResourceName)_SqlServerAgent_NamedInstance_Restore_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential             = $mockSqlInstallCredential
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

                $resourceCurrentState.ServiceType | Should -Be $mockServiceTypeSqlServerAgent
                $resourceCurrentState.ServiceAccountName | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME, (Split-Path -Path $mockSqlAgentServicePrimaryAccountUserName -Leaf))
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
