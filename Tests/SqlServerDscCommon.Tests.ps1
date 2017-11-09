[CmdletBinding()]
# Suppressing this because we need to generate a mocked credentials that will be passed along to the examples that are needed in the tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$script:moduleRoot = Split-Path $PSScriptRoot -Parent

Describe 'SqlServerDsc module common tests' {
    Context -Name 'When there are example file for resource' {
            <#
                For Appveyor builds copy the module to the system modules directory so it falls
                in to a PSModulePath folder and is picked up correctly.
            #>
            if ($env:APPVEYOR)
            {
                $powershellModulePath = Join-Path -Path (($env:PSModulePath -split ';')[0]) -ChildPath 'SqlServerDsc'
                Copy-item -Path $env:APPVEYOR_BUILD_FOLDER -Destination $powershellModulePath -Recurse -Force
            }

            $mockPassword = ConvertTo-SecureString '&iPm%M5q3K$Hhq=wcEK' -AsPlainText -Force
            $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('username', $mockPassword)
            $mockConfigData = @{
                AllNodes = @(
                    @{
                        NodeName = "localhost"
                        PSDscAllowPlainTextPassword = $true
                    }
                )
            }

            $exampleFile = Get-ChildItem -Path "$script:moduleRoot\Examples\Resources" -Filter "*.ps1" -Recurse

            foreach ($exampleToValidate in $exampleFile)
            {
                $exampleDescriptiveName = Join-Path -Path (Split-Path $exampleToValidate.Directory -Leaf) -ChildPath (Split-Path $exampleToValidate -Leaf)

                It "Should compile MOFs for example '$exampleDescriptiveName' correctly" {
                    {
                        . $exampleToValidate.FullName

                        $exampleCommand = Get-Command Example -ErrorAction SilentlyContinue
                        if ($exampleCommand)
                        {
                            try
                            {
                                $params = @{}
                                $exampleCommand.Parameters.Keys | Where-Object { $_ -like '*Account' -or ($_ -like '*Credential' -and $_ -ne 'PsDscRunAsCredential')  } | ForEach-Object -Process {
                                    $params.Add($_, $mockCredential)
                                }

                                Example @params -ConfigurationData $mockConfigData -OutputPath 'TestDrive:\' -ErrorAction Continue -WarningAction SilentlyContinue | Out-Null
                            }
                            finally
                            {
                                # Remove the function we dot-sourced so next example file doesn't use the previous Example-function.
                                Remove-Item function:Example
                            }
                        }
                        else
                        {
                            throw "The example '$exampleDescriptiveName' does not contain a function 'Example'."
                        }
                    } | Should -Not -Throw
                }
        }

        if ($env:APPVEYOR -eq $true)
        {
            Remove-item -Path $powershellModulePath -Recurse -Force -Confirm:$false

            # Restore the module in 'memory' to ensure other tests after this test have access to it
            Import-Module -Name "$script:moduleRoot\SqlServerDsc.psd1" -Global -Force
        }
    }
}
