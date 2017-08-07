
$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerServiceAccount'

#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {

        Describe 'ConvertTo-ManagedServiceType' -Tag 'Helper' {
            Context 'When invalid arguments are specified' {
                It 'Should throw an exception' {
                    { ConvertTo-ManagedServiceType -Id 0 } | Should Throw 'Managed Service Type 0 is not valid'
                }
            }

            Context 'When valid arguments are specified' {
                $mockValidServiceTypes = @{
                    1  = 'SqlServer'
                    2  = 'SqlAgent'
                    3  = 'Search'
                    4  = 'SqlServerIntegrationService'
                    5  = 'AnalysisServer'
                    6  = 'ReportServer'
                    7  = 'SqlBrowser'
                    8  = 'NotificationServer'
                    9  = 'Search'
                }

                foreach ($serviceType in $mockValidServiceTypes.GetEnumerator())
                {
                    $mockServiceTypeId = $serviceType.Name
                    $mockServiceTypeName = $serviceType.Value

                    It "Should return the correct service type for $($mockServiceTypeName)" {
                        ConvertTo-ManagedServiceType -Id $mockServiceTypeId | Should Be $mockServiceTypeName
                    }
                }

                It 'Should return the correct service type for SQL Agent' {
                    ConvertTo-ManagedServiceType -Id 2 | Should Be 'SqlAgent'
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
