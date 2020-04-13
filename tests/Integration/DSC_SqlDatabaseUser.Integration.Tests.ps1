Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017')))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlDatabaseUser'
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

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_AddDatabaseUser1_Config"

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
                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name
                $resourceCurrentState.UserType | Should -Be $ConfigurationData.AllNodes.User1_UserType
                $resourceCurrentState.LoginName | Should -Be $ConfigurationData.AllNodes.User1_LoginName
                $resourceCurrentState.AsymmetricKeyName | Should -BeNullOrEmpty
                $resourceCurrentState.CertificateName | Should -BeNullOrEmpty
                $resourceCurrentState.AuthenticationType | Should -Be 'Windows'
                $resourceCurrentState.LoginType | Should -Be 'WindowsUser'
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_AddDatabaseUser2_Config"

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
                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User2_Name
                $resourceCurrentState.UserType | Should -Be $ConfigurationData.AllNodes.User2_UserType
                $resourceCurrentState.LoginName | Should -Be $ConfigurationData.AllNodes.User2_LoginName
                $resourceCurrentState.AsymmetricKeyName | Should -BeNullOrEmpty
                $resourceCurrentState.CertificateName | Should -BeNullOrEmpty
                $resourceCurrentState.AuthenticationType | Should -Be 'Instance'
                $resourceCurrentState.LoginType | Should -Be 'SqlLogin'
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_AddDatabaseUser3_Config"

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
                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User3_Name
                $resourceCurrentState.UserType | Should -Be $ConfigurationData.AllNodes.User3_UserType
                $resourceCurrentState.LoginName | Should -BeNullOrEmpty
                $resourceCurrentState.AsymmetricKeyName | Should -BeNullOrEmpty
                $resourceCurrentState.CertificateName | Should -BeNullOrEmpty
                $resourceCurrentState.AuthenticationType | Should -Be 'None'
                $resourceCurrentState.LoginType | Should -Be 'SqlLogin'
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_AddDatabaseUser4_Config"

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
                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User4_Name
                $resourceCurrentState.UserType | Should -Be $ConfigurationData.AllNodes.User4_UserType
                $resourceCurrentState.LoginName | Should -Be $ConfigurationData.AllNodes.User4_LoginName
                $resourceCurrentState.AsymmetricKeyName | Should -BeNullOrEmpty
                $resourceCurrentState.CertificateName | Should -BeNullOrEmpty
                $resourceCurrentState.AuthenticationType | Should -Be 'Windows'
                $resourceCurrentState.LoginType | Should -Be 'WindowsGroup'
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_RecreateDatabaseUser4_Config"

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
                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User4_Name
                $resourceCurrentState.UserType | Should -Be 'NoLogin'
                $resourceCurrentState.LoginName | Should -BeNullOrEmpty
                $resourceCurrentState.AsymmetricKeyName | Should -BeNullOrEmpty
                $resourceCurrentState.CertificateName | Should -BeNullOrEmpty
                $resourceCurrentState.AuthenticationType | Should -Be 'None'
                $resourceCurrentState.LoginType | Should -Be 'SqlLogin'
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_RemoveDatabaseUser4_Config"

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
                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User4_Name
                $resourceCurrentState.UserType | Should -BeNullOrEmpty
                $resourceCurrentState.LoginName | Should -BeNullOrEmpty
                $resourceCurrentState.AsymmetricKeyName | Should -BeNullOrEmpty
                $resourceCurrentState.CertificateName | Should -BeNullOrEmpty
                $resourceCurrentState.AuthenticationType | Should -BeNullOrEmpty
                $resourceCurrentState.UserType | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_AddDatabaseUser5_Config"

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
                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User5_Name
                $resourceCurrentState.UserType | Should -Be $ConfigurationData.AllNodes.User5_UserType
                $resourceCurrentState.LoginName | Should -BeNullOrEmpty
                $resourceCurrentState.AsymmetricKeyName | Should -BeNullOrEmpty
                $resourceCurrentState.CertificateName | Should -Be $ConfigurationData.AllNodes.CertificateName
                $resourceCurrentState.AuthenticationType | Should -Be 'None'
                $resourceCurrentState.LoginType | Should -Be 'Certificate'
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_AddDatabaseUser6_Config"

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
                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User6_Name
                $resourceCurrentState.UserType | Should -Be $ConfigurationData.AllNodes.User6_UserType
                $resourceCurrentState.LoginName | Should -BeNullOrEmpty
                $resourceCurrentState.AsymmetricKeyName | Should -Be $ConfigurationData.AllNodes.AsymmetricKeyName
                $resourceCurrentState.CertificateName | Should -BeNullOrEmpty
                $resourceCurrentState.AuthenticationType | Should -Be 'None'
                $resourceCurrentState.LoginType | Should -Be 'AsymmetricKey'
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
