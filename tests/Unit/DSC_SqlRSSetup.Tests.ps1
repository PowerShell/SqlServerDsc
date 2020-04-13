<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlRSSetup DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlRSSetup'

function Invoke-TestSetup
{
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
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        <#
            .SYNOPSIS
                Used to test arguments passed to Start-SqlSetupProcess while inside and It-block.

                This function must be called inside a Mock, since it depends being run inside an It-block.

            .PARAMETER Argument
                A string containing all the arguments separated with space and each argument should start with '/'.
                Only the first string in the array is evaluated.

            .PARAMETER ExpectedArgument
                A hash table containing all the expected arguments.
        #>
        function Test-SetupArgument
        {
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $Argument,

                [Parameter(Mandatory = $true)]
                [System.Collections.Hashtable]
                $ExpectedArgument
            )

            $argumentHashTable = @{}

            # Break the argument string into a hash table
            ($Argument -split ' ?/') | ForEach-Object {
                if ($_ -imatch '(\w+)="?([^\/]+)"?')
                {
                    $key = $Matches[1]
                    $value = ($Matches[2] -replace '" "',' ') -replace '"',''

                    $argumentHashTable.Add($key, $value)
                }
                elseif ($_ -imatch '(\w+)')
                {
                    $key = $Matches[1]
                    $value = [System.Management.Automation.SwitchParameter] $true

                    $argumentHashTable.Add($key, $value)
                }
            }

            $actualValues = $argumentHashTable.Clone()

            # Limit the output in the console when everything is fine.
            if ($actualValues.Count -ne $ExpectedArgument.Count)
            {
                Write-Warning -Message 'Verified the setup argument count (expected vs actual)'
                Write-Warning -Message ('Expected: {0}' -f ($ExpectedArgument.Keys -join ','))
                Write-Warning -Message ('Actual: {0}' -f ($actualValues.Keys -join ','))
            }

            # Start by checking whether we have the same number of parameters
            $actualValues.Count | Should -Be $ExpectedArgument.Count `
                -Because ('the expected arguments was: {0}' -f ($ExpectedArgument.Keys -join ','))

            Write-Verbose -Message 'Verified actual setup argument values against expected setup argument values' -Verbose

            foreach ($argumentKey in $ExpectedArgument.Keys)
            {
                $argumentKeyName =  $actualValues.GetEnumerator() |
                    Where-Object -FilterScript {
                        $_.Name -eq $argumentKey
                    } | Select-Object -ExpandProperty 'Name'

                $argumentValue = $actualValues.$argumentKey

                $argumentKeyName | Should -Be $argumentKey
                $argumentValue | Should -Be $ExpectedArgument.$argumentKey
            }
        }

        $mockInstanceName = 'SSRS'
        $mockCurrentVersion = '14.0.6514.11481'

        # Default parameters that are used for the It-blocks.
        $mockDefaultParameters = @{
            InstanceName       = $mockInstanceName
            IAcceptLicenseTerms = 'Yes'
            SourcePath         = '\\server\share\SQLServerReportingServices.exe'
        }

        Describe "MSFT_SqlRSSetup\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                $mockGetTargetResourceParameters = $mockDefaultParameters.Clone()
            }

            Context 'When the system is in the desired state' {
                Context 'When there are no installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-RegistryPropertyValue
                    }

                    It 'Should return $null as the InstanceName' {
                        $result = Get-TargetResource @mockGetTargetResourceParameters
                        $result.InstanceName | Should -BeNullOrEmpty

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @mockGetTargetResourceParameters
                        $result.IAcceptLicenseTerms | Should -Be $mockGetTargetResourceParameters.IAcceptLicenseTerms
                        $result.SourcePath | Should -Be $mockGetTargetResourceParameters.SourcePath

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
                    }

                    It 'Should return $null or $false for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters
                        $getTargetResourceResult.Action | Should -BeNullOrEmpty
                        $getTargetResourceResult.SourceCredential | Should -BeNullOrEmpty
                        $getTargetResourceResult.ProductKey | Should -BeNullOrEmpty
                        $getTargetResourceResult.ForceRestart | Should -BeFalse
                        $getTargetResourceResult.EditionUpgrade | Should -BeFalse
                        $getTargetResourceResult.Edition | Should -BeNullOrEmpty
                        $getTargetResourceResult.LogPath | Should -BeNullOrEmpty
                        $getTargetResourceResult.InstallFolder | Should -BeNullOrEmpty
                        $getTargetResourceResult.ErrorDumpDirectory | Should -BeNullOrEmpty
                        $getTargetResourceResult.CurrentVersion | Should -BeNullOrEmpty
                        $getTargetResourceResult.ServiceName | Should -BeNullOrEmpty

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When there is an installed Reporting Services' {
                    BeforeAll {
                        $mockGetRegistryPropertyValue_InstanceName = {
                            <#
                                Currently only the one instance name of 'SSRS' is supported,
                                and the same name is currently used for instance id.
                            #>
                            return $mockInstanceName
                        }

                        $mockGetRegistryPropertyValue_InstanceName_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' `
                                -and $Name -eq $mockInstanceName
                        }

                        $mockInstallRootDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                        $mockGetRegistryPropertyValue_InstallRootDirectory = {
                            return $mockInstallRootDirectory
                        }

                        $mockGetRegistryPropertyValue_InstallRootDirectory_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' `
                                -and $Name -eq 'InstallRootDirectory'
                        }

                        $mockServiceName = 'SQLServerReportingServices'
                        $mockGetRegistryPropertyValue_ServiceName = {
                            return $mockServiceName
                        }

                        $mockGetRegistryPropertyValue_ServiceName_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' `
                                -and $Name -eq 'ServiceName'
                        }

                        $mockErrorDumpDir = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
                        $mockGetRegistryPropertyValue_ErrorDumpDir = {
                            return $mockErrorDumpDir
                        }

                        $mockGetRegistryPropertyValue_ErrorDumpDir_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' `
                                -and $Name -eq 'ErrorDumpDir'
                        }

                        $mockGetPackage_CurrentVersion = {
                            return @{
                                Version = $mockCurrentVersion
                            }
                        }

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetRegistryPropertyValue_InstanceName `
                            -ParameterFilter $mockGetRegistryPropertyValue_InstanceName_ParameterFilter

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetRegistryPropertyValue_InstallRootDirectory `
                            -ParameterFilter $mockGetRegistryPropertyValue_InstallRootDirectory_ParameterFilter

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetRegistryPropertyValue_ServiceName `
                            -ParameterFilter $mockGetRegistryPropertyValue_ServiceName_ParameterFilter

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetRegistryPropertyValue_ErrorDumpDir `
                            -ParameterFilter $mockGetRegistryPropertyValue_ErrorDumpDir_ParameterFilter

                        # This is a workaround for the issue https://github.com/pester/Pester/issues/604.
                        function Get-Package
                        {
                            [CmdletBinding()]
                            param
                            (
                                [Parameter(Mandatory = $true)]
                                [System.String]
                                $Name,

                                [Parameter(Mandatory = $true)]
                                [System.String]
                                $ProviderName
                            )

                            throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
                        }

                        Mock -CommandName Get-Package -MockWith $mockGetPackage_CurrentVersion
                    }

                    It 'Should return the correct InstanceName' {
                        $result = Get-TargetResource @mockGetTargetResourceParameters
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetRegistryPropertyValue_InstanceName_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @mockGetTargetResourceParameters
                        $result.IAcceptLicenseTerms | Should -Be $mockGetTargetResourceParameters.IAcceptLicenseTerms
                        $result.SourcePath | Should -Be $mockGetTargetResourceParameters.SourcePath
                    }

                    It 'Should return the correct values for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters
                        $getTargetResourceResult.Action | Should -BeNullOrEmpty
                        $getTargetResourceResult.SourceCredential | Should -BeNullOrEmpty
                        $getTargetResourceResult.ProductKey | Should -BeNullOrEmpty
                        $getTargetResourceResult.ForceRestart | Should -BeFalse
                        $getTargetResourceResult.EditionUpgrade | Should -BeFalse
                        $getTargetResourceResult.Edition | Should -BeNullOrEmpty
                        $getTargetResourceResult.LogPath | Should -BeNullOrEmpty
                        $getTargetResourceResult.InstallFolder | Should -Be $mockInstallRootDirectory
                        $getTargetResourceResult.ErrorDumpDirectory | Should -Be $mockErrorDumpDir
                        $getTargetResourceResult.CurrentVersion | Should -Be $mockCurrentVersion
                        $getTargetResourceResult.ServiceName | Should -Be $mockServiceName

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetRegistryPropertyValue_InstallRootDirectory_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetRegistryPropertyValue_ServiceName_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetRegistryPropertyValue_ErrorDumpDir_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Get-Package -Exactly -Times 1 -Scope 'It'
                    }

                    Context 'When there is an installed Reporting Services, but no installed package is found to determine version' {
                        BeforeEach {
                            Mock -CommandName Get-Package
                            Mock -CommandName Write-Warning
                        }

                        It 'Should return the correct values for the rest of the properties' {
                            $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters
                            $getTargetResourceResult.CurrentVersion | Should -BeNullOrEmpty

                            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope 'It'
                        }
                    }
                }
            }
        }

        Describe "MSFT_SqlRSSetup\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
            }

            Context 'When the system is in the desired state' {
                Context 'When there are no installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = $null
                            }
                        }
                    }

                    It 'Should return $true' {
                        $mockTestTargetResourceParameters['Action'] = 'Uninstall'

                        $result = Test-TargetResource @mockTestTargetResourceParameters
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When there is an installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = 'SSRS'
                                CurrentVersion = $mockCurrentVersion
                            }
                        }

                        Mock -CommandName Get-FileProductVersion -MockWith {
                            return [System.Version] $mockCurrentVersion
                        }
                    }

                    It 'Should return $true' {
                        $result = Test-TargetResource @mockTestTargetResourceParameters
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Get-FileProductVersion -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the installed Reporting Services is an older version that the installation media, but parameter VersionUpgrade is not used' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = 'SSRS'
                                CurrentVersion = $mockCurrentVersion
                            }
                        }

                        Mock -CommandName Get-FileProductVersion -MockWith {
                            return [System.Version] '15.1.1.0'
                        }
                    }

                    It 'Should return $false' {
                        # This is called without the parameter 'VersionUpgrade'.
                        $result = Test-TargetResource @mockTestTargetResourceParameters
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Get-FileProductVersion -Exactly -Times 1 -Scope 'It'
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When there should be no installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = 'SSRS'
                            }
                        }
                    }

                    It 'Should return $false' {
                        $mockTestTargetResourceParameters['Action'] = 'Uninstall'

                        $result = Test-TargetResource @mockTestTargetResourceParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When there are no installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = $null
                            }
                        }

                        Mock -CommandName Get-FileProductVersion -MockWith {
                            return [System.Version] $mockCurrentVersion
                        }
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @mockTestTargetResourceParameters -Verbose
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the wrong version of Reporting Services is installed, and parameter VersionUpgrade is used' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = 'SSRS'
                                CurrentVersion = $mockCurrentVersion
                            }
                        }

                        Mock -CommandName Get-FileProductVersion -MockWith {
                            return [System.Version] '15.1.1.0'
                        }
                    }

                    It 'Should return $false' {
                        $mockTestTargetResourceParameters['VersionUpgrade'] = $true

                        $result = Test-TargetResource @mockTestTargetResourceParameters -Verbose
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Get-FileProductVersion -Exactly -Times 1 -Scope 'It'
                    }
                }
            }
        }

        Describe "MSFT_SqlRSSetup\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                $mockProductKey = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
            }

            BeforeEach {
                $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()

                # Reset global variable DSCMachineStatus before each test.
                $global:DSCMachineStatus = 0
            }


            Context 'When providing a missing SourcePath' {
                BeforeEach {
                    $mockSetTargetResourceParameters['Edition'] = 'Development'

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    }
                }

                It 'Should throw the correct error message' {
                    $errorMessage = $script:localizedData.SourcePathNotFound -f $mockSetTargetResourceParameters.SourcePath
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $errorMessage
                }
            }

            Context 'When providing a correct path in SourcePath, but no executable' {
                BeforeEach {
                    $mockSetTargetResourceParameters['Edition'] = 'Development'

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return @{
                            Extension = ''
                        }
                    }
                }

                It 'Should throw the correct error message' {
                    $errorMessage = $script:localizedData.SourcePathNotFound -f $mockSetTargetResourceParameters.SourcePath
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $errorMessage
                }
            }

            Context 'When providing both the parameters ProductKey and Edition' {
                BeforeEach {
                    $mockSetTargetResourceParameters['Edition'] = 'Development'
                    $mockSetTargetResourceParameters['ProductKey'] = $mockProductKey
                }

                It 'Should throw the correct error message' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $script:localizedData.EditionInvalidParameter
                }
            }

            Context 'When providing neither the parameters ProductKey or Edition' {
                It 'Should throw the correct error message' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $script:localizedData.EditionMissingParameter
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return @{
                            Extension = '.exe'
                        }
                    }
                }

                Context 'When Reporting Services are installed with the minimum required parameters' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['ProductKey'] = $mockProductKey

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                            PID = $mockProductKey
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When Reporting Services should be uninstalled' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Action'] = 'Uninstall'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            Uninstall = [System.Management.Automation.SwitchParameter] $true
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When Reporting Services are installed with parameter Edition' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When Reporting Services are installed with parameters ProductKey, SuppressRestart, LogPath, EditionUpgrade, and InstallFolder' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['ProductKey'] = $mockProductKey
                        $mockSetTargetResourceParameters['SuppressRestart'] = $true
                        $mockSetTargetResourceParameters['LogPath'] = 'log.txt'
                        $mockSetTargetResourceParameters['EditionUpgrade'] = $true
                        $mockSetTargetResourceParameters['InstallFolder'] = 'C:\Temp'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                            PID = $mockProductKey
                            NoRestart = [System.Management.Automation.SwitchParameter] $true
                            Log = 'log.txt'
                            EditionUpgrade = [System.Management.Automation.SwitchParameter] $true
                            InstallFolder = 'C:\Temp'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When Reporting Services are installed using parameter SourceCredential' {
                    BeforeAll {
                        $mockLocalPath = 'C:\LocalPath'

                        $mockShareCredentialUserName = 'COMPANY\SqlAdmin'
                        $mockShareCredentialPassword = 'dummyPassW0rd'
                        $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            $mockShareCredentialUserName,
                            ($mockShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
                        )

                        Mock -CommandName Invoke-InstallationMediaCopy -MockWith {
                            return $mockLocalPath
                        }
                    }

                    BeforeEach {
                        $mockSetTargetResourceParameters['ProductKey'] = $mockProductKey

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                            PID = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        $mockSetTargetResourceParameters['SourceCredential'] = $mockShareCredential
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-InstallationMediaCopy -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            # Have to build the correct path (local path + executable).
                            $FilePath -eq (Join-Path -Path $mockLocalPath -ChildPath (Split-Path -Path $mockSetTargetResourceParameters.SourcePath -Leaf))
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the Reporting Services installation is successful with exit code 3010' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 3010
                        }
                    }

                    It 'Should call the correct mocks, and set $global:DSCMachineStatus to 1' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        # Should set the global DSCMachineStatus variable.
                        $global:DSCMachineStatus | Should -Be 1

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }

                    Context 'When the Reporting Services installation is successful with exit code 3010, and called with parameter SuppressRestart' {
                        BeforeEach {
                            $mockSetTargetResourceParameters['Edition'] = 'Development'
                            $mockSetTargetResourceParameters['SuppressRestart'] = $true

                            $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                                Quiet = [System.Management.Automation.SwitchParameter] $true
                                IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                                Edition = 'Dev'
                                NoRestart = [System.Management.Automation.SwitchParameter] $true
                            }
                        }

                        It 'Should call the correct mocks' {
                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                                $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                            } -Exactly -Times 1 -Scope 'It'

                            # Should not set the global DSCMachineStatus variable.
                            $global:DSCMachineStatus | Should -Be 0
                        }
                    }
                }

                Context 'When the Reporting Services installation is successful and ForceRestart is used' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'
                        $mockSetTargetResourceParameters['ForceRestart'] = $true

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Test-PendingRestart
                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks, and set $global:DSCMachineStatus to 1' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        # Should set the global DSCMachineStatus variable.
                        $global:DSCMachineStatus | Should -Be 1

                        Assert-MockCalled -CommandName Test-PendingRestart -Exactly -Times 0 -Scope 'It'
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the Reporting Services installation is successful, and there are a pending restart' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Test-PendingRestart -MockWith {
                            return $true
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks, and set $global:DSCMachineStatus to 1' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        # Should set the global DSCMachineStatus variable.
                        $global:DSCMachineStatus | Should -Be 1

                        Assert-MockCalled -CommandName Test-PendingRestart -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the Reporting Services installation fails' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 1
                        }
                    }

                    It 'Should throw the correct error message' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $script:localizedData.SetupFailed

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'

                        # Should not set the global DSCMachineStatus variable.
                        $global:DSCMachineStatus | Should -Be 0
                    }

                    Context 'When the Reporting Services installation fails, and called with parameter LogPath' {
                        BeforeEach {
                            $mockSetTargetResourceParameters['Edition'] = 'Development'
                            $mockSetTargetResourceParameters['LogPath'] = 'TestDrive:\'

                            $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                                Quiet = [System.Management.Automation.SwitchParameter] $true
                                IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                                Edition = 'Dev'
                                log = $mockSetTargetResourceParameters.LogPath
                            }
                        }

                        It 'Should throw the correct error message' {
                            $errorMessage = $script:localizedData.SetupFailedWithLog -f $mockSetTargetResourceParameters.LogPath

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $errorMessage

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                                $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                            } -Exactly -Times 1 -Scope 'It'

                            # Should not set the global DSCMachineStatus variable.
                            $global:DSCMachineStatus | Should -Be 0
                        }
                    }
                }
            }
        }

        Describe "MSFT_SqlRSSetup\Convert-EditionName" -Tag 'Helper' {
            Context 'When converting edition names' {
                $testCases = @(
                    @{
                        InputName = 'Development'
                        OutputName = 'Dev'
                    }
                    @{
                        InputName = 'Evaluation'
                        OutputName = 'Eval'
                    }
                    @{
                        InputName = 'ExpressAdvanced'
                        OutputName = 'ExprAdv'
                    }
                    @{
                        InputName = 'Dev'
                        OutputName = 'Development'
                    }
                    @{
                        InputName = 'Eval'
                        OutputName = 'Evaluation'
                    }
                    @{
                        InputName = 'ExprAdv'
                        OutputName = 'ExpressAdvanced'
                    }
                )

                It 'Should return the value <OutputName> when converting from value <InputName>' -TestCases $testCases {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $InputName,

                        [Parameter()]
                        [System.String]
                        $OutputName
                    )

                    Convert-EditionName -Name $InputName | Should -Be $OutputName
                }
            }
        }

        Describe "MSFT_SqlRSSetup\Get-FileProductVersion" -Tag 'Helper' {
            Context 'When converting edition names' {
                $mockProductVersion = '14.0.0.0'

                BeforeAll {
                    Mock -CommandName Get-Item -MockWith {
                        return @{
                            VersionInfo = @{
                                ProductVersion = $mockProductVersion
                            }
                        }
                    }
                }

                It 'Should return the correct product version' {
                    Get-FileProductVersion -Path 'TestDrive:\MockExecutable.exe' | Should -Be $mockProductVersion
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

