$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = '.\tests\Unit\SqlServerDsc.Common.Tests.ps1'
$pesterConfig.Run.Exit = $true
$pesterConfig.Run.PassThru = $false
$pesterConfig.Filter.Tag = @(
    'GetRegistryPropertyValue'
    'FormatPath'
    'ConnectUncPath'
)
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.OutputPath = './output/coverage.xml'
$pesterConfig.CodeCoverage.OutputEncoding = 'UTF8'
$pesterConfig.CodeCoverage.Path = '.\source\Modules\SqlServerDsc.Common\SqlServerDsc.Common.psm1'
$pesterConfig.CodeCoverage.ExcludeTests = $true
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnit2.5'
$pesterConfig.TestResult.OutputPath = './output/testResults.xml'
$pesterConfig.TestResult.OutputEncoding = 'UTF8'
$pesterConfig.TestResult.TestSuiteName = 'Pester5'
$pesterConfig.Output.Verbosity = 'Detailed'

# $pesterConfig = [PesterConfiguration] @{
#     CodeCoverage = @{
#         Enabled = $true
#         Path = '.\src\functions\Coverage.ps1'
#     }
#     Run = @{
#         Path = '.\tst\functions\Coverage.Tests.ps1'
#     }
# }


# Does not Generates JacCoCo
Invoke-Pester -Configuration $pesterConfig
