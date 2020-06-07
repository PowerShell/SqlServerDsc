Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017')))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlDatabaseObjectPermission'
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

        $configurationName = "$($script:dscResourceName)_Prerequisites_Config"

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
        }

        $configurationName = "$($script:dscResourceName)_Grant_Config"

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

                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.SchemaName | Should -Be $ConfigurationData.AllNodes.SchemaName
                $resourceCurrentState.ObjectName | Should -Be $ConfigurationData.AllNodes.ObjectName
                $resourceCurrentState.ObjectType | Should -Be 'Table'
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name

                $getTargetResourceResult.Permission | Should -HaveCount 2
                $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'
                $getTargetResourceResult.Permission[1] | Should -BeOfType 'CimInstance'

                $grantPermission = $getTargetResourceResult.Permission.Where( { $_.State -eq 'Grant' })
                $grantPermission | Should -Not -BeNullOrEmpty
                $grantPermission.Ensure | Should -Be 'Present'
                $grantPermission.Permission | Should -HaveCount 1
                $grantPermission.Permission | Should -Contain @('Select')

                $grantPermission = $getTargetResourceResult.Permission.Where( { $_.State -eq 'Deny' })
                $grantPermission | Should -Not -BeNullOrEmpty
                $grantPermission.Ensure | Should -Be 'Present'
                $grantPermission.Permission | Should -HaveCount 2
                $grantPermission.Permission | Should -Contain @('Delete')
                $grantPermission.Permission | Should -Contain @('Alter')
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_Revoke_Config"

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

                $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                $resourceCurrentState.SchemaName | Should -Be $ConfigurationData.AllNodes.SchemaName
                $resourceCurrentState.ObjectName | Should -Be $ConfigurationData.AllNodes.ObjectName
                $resourceCurrentState.ObjectType | Should -Be 'Table'
                $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name

                $getTargetResourceResult.Permission | Should -HaveCount 2
                $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'
                $getTargetResourceResult.Permission[1] | Should -BeOfType 'CimInstance'

                $grantPermission = $getTargetResourceResult.Permission.Where( { $_.State -eq 'Grant' })
                $grantPermission | Should -Not -BeNullOrEmpty
                $grantPermission.Ensure | Should -Be 'Absent'
                $grantPermission.Permission | Should -HaveCount 1
                $grantPermission.Permission | Should -Contain @('Select')

                $grantPermission = $getTargetResourceResult.Permission.Where( { $_.State -eq 'Deny' })
                $grantPermission | Should -Not -BeNullOrEmpty
                $grantPermission.Ensure | Should -Be 'Absent'
                $grantPermission.Permission | Should -HaveCount 2
                $grantPermission.Permission | Should -Contain @('Delete')
                $grantPermission.Permission | Should -Contain @('Alter')
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
