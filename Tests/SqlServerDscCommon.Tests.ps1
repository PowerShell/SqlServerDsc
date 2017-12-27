$script:moduleRoot = Split-Path $PSScriptRoot -Parent

Describe 'SqlServerDsc module common tests' {
    Context -Name 'When the resource should be used to compile a configuration in Azure Automation' {
        $fullPathHardLimit = 129 # 129 characters is the current maximum for a relative path to be able to compile configurations in Azure Automation.
        $allModuleFiles = Get-ChildItem -Path $script:moduleRoot -Recurse

        $testCaseModuleFile = @()
        $allModuleFiles | ForEach-Object -Process {
            $testCaseModuleFile += @(
                @{
                    FullRelativePath = $_.FullName -replace ($script:moduleRoot -replace '\\','\\')
                }
            )
        }

        It 'The length of the full path ''<FullRelativePath>'' should not exceed the max hard limit' -TestCases $testCaseModuleFile {
            param
            (
                [Parameter()]
                [System.String]
                $FullRelativePath
            )

            $FullRelativePath.Length | Should -Not -BeGreaterThan $fullPathHardLimit
        }
    }
}
