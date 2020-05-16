# This file should be removed before the pull request is reviewed

# Start from the default configuration values.
$pesterConfig = [PesterConfiguration]::Default

# Output similar to Pester 4.10.1
$pesterConfig.Output.Verbosity = 'Detailed'

# The path to one or more test files.
$pesterConfig.Run.Path = @(
    '.\tests\Unit\SqlServerDsc.Common.Tests.ps1'
)

# Exit after test has run complete.
$pesterConfig.Run.Exit = $true

# If Invoke-Pester should return an object for further processing.
$pesterConfig.Run.PassThru = $false

# Only run these tags.
$pesterConfig.Filter.Tag = @(
    'GetRegistryPropertyValue'
    'FormatPath'
    'ConnectUncPath'
)

# Generate the JaCoCo file 'coverage.xml' in /output.
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.OutputPath = './output/coverage.xml'
$pesterConfig.CodeCoverage.OutputEncoding = 'UTF8'
$pesterConfig.CodeCoverage.Path = '.\source\Modules\SqlServerDsc.Common\SqlServerDsc.Common.psm1'
$pesterConfig.CodeCoverage.ExcludeTests = $true # Exclude our own test code from code coverage.

# Generate the NUNit 2.5 file 'testResults.xml' in /output
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnit2.5'
$pesterConfig.TestResult.OutputPath = './output/testResults.xml'
$pesterConfig.TestResult.OutputEncoding = 'UTF8'
$pesterConfig.TestResult.TestSuiteName = 'Pester5' # Can be set to any name, preferably the module name?

Invoke-Pester -Configuration $pesterConfig

# <#
#     Another way of format the configuration without starting from ::Default
#     (below is not complete, just an example).
# #>
# $pesterConfig = [PesterConfiguration] @{
#     CodeCoverage = @{
#         Enabled = $true
#         Path = '.\src\functions\Coverage.ps1'
#     }
#     Run = @{
#         Path = '.\tst\functions\Coverage.Tests.ps1'
#     }
# }
