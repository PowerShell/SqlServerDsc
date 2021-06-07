<#
    .SYNOPSIS
        Unit test for helper functions in module SqlServerDsc.Common.

    .NOTES
        SMO stubs
        ---------
        These are loaded at the start so that it is known that they are left in the
        session after test finishes, and will spill over to other tests. There does
        not exist a way to unload assemblies. It is possible to load these in a
        InModuleScope but the classes are still present in the parent scope when
        Pester has ran.

        SqlServer/SQLPS stubs
        ---------------------
        These are imported using Import-SqlModuleStub in a BeforeAll-block in only
        a test that requires them, and must be removed in an AfterAll-block using
        Remove-SqlModuleStub so the stub cmdlets does not spill over to another
        test.
#>

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:subModuleName = 'SqlServerDsc.Common'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Loading SMO stubs.
    if (-not ('Microsoft.SqlServer.Management.Smo.Server' -as [Type]))
    {
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
    }

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlServerDsc.Common\Get-RegistryPropertyValue' -Tag 'GetRegistryPropertyValue' {
    BeforeAll {
        $mockWrongRegistryPath = 'HKLM:\SOFTWARE\AnyPath'
        $mockPropertyName = 'InstanceName'
        $mockPropertyValue = 'AnyValue'
    }

    Context 'When there are no property in the registry' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                return @{
                    'UnknownProperty' = $mockPropertyValue
                }
            }
        }

        It 'Should return $null' {
            $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It -Module $script:subModuleName
        }
    }

    Context 'When the call to Get-ItemProperty throws an error (i.e. when the path does not exist)' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                throw 'mocked error'
            }
        }

        It 'Should not throw an error, but return $null' {
            $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
        }
    }

    Context 'When there are a property in the registry' {
        BeforeAll {
            $mockCorrectRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

            Mock -CommandName Get-ItemProperty -MockWith {
                return @{
                    $mockPropertyName = $mockPropertyValue
                }
            } -ParameterFilter {
                $Path -eq $mockCorrectRegistryPath `
                -and $Name -eq $mockPropertyName
            }
        }

        It 'Should return the correct value' {
            $result = Get-RegistryPropertyValue -Path $mockCorrectRegistryPath -Name $mockPropertyName
            $result | Should -Be $mockPropertyValue

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlServerDsc.Common\Format-Path' -Tag 'FormatPath' {
    BeforeAll {
        $mockCorrectPath = 'C:\Correct\Path'
        $mockPathWithTrailingBackslash = 'C:\Correct\Path\'
        $mockPathWithOnlyQualifier = 'M:'
        $mockCorrectQualifierPath = 'M:\'
    }

    Context 'When there is a path that is wrongly formatted, but now formatting was requested' {
        It 'Should return the same wrongly formatted path' {
            $result = Format-Path -Path $mockPathWithTrailingBackslash
            $result | Should -BeExactly $mockPathWithTrailingBackslash
        }
    }

    Context 'When there is a path that is formatted correctly, and using TrailingSlash' {
        It 'Should return the same path' {
            $result = Format-Path -Path $mockCorrectPath -TrailingSlash
            $result | Should -BeExactly $mockCorrectPath
        }
    }

    Context 'When there is a path that has a trailing backslash, and using TrailingSlash' {
        It 'Should return the path without trailing backslash' {
            $result = Format-Path -Path $mockPathWithTrailingBackslash -TrailingSlash
            $result | Should -BeExactly $mockCorrectPath
        }
    }

    Context 'When there is a path that has only a qualifier, and using TrailingSlash' {
        It 'Should return the path with trailing backslash after the qualifier' {
            $result = Format-Path -Path $mockPathWithOnlyQualifier -TrailingSlash
            $result | Should -BeExactly $mockCorrectQualifierPath
        }
    }
}

# Tests only the parts of the code that does not already get tested thru the other tests.
Describe 'SqlServerDsc.Common\Copy-ItemWithRobocopy' -Tag 'CopyItemWithRobocopy' {
    BeforeAll {
        $mockRobocopyExecutableName = 'Robocopy.exe'
        $mockRobocopyExecutableVersionWithoutUnbufferedIO = '6.2.9200.00000'
        $mockRobocopyExecutableVersionWithUnbufferedIO = '6.3.9600.16384'
        $mockRobocopyExecutableVersion = ''     # Set dynamically during runtime
        $mockRobocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
        $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
        $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'
        $mockRobocopyArgumentUseUnbufferedIO = '/J'
        $mockRobocopyArgumentSourcePath = 'C:\Source\SQL2016'
        $mockRobocopyArgumentDestinationPath = 'D:\Temp'
        $mockRobocopyArgumentSourcePathWithSpaces = 'C:\Source\SQL2016 STD SP1'
        $mockRobocopyArgumentDestinationPathWithSpaces = 'D:\Temp\DSC SQL2016'

        $mockGetCommand = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockRobocopyExecutableName -PassThru |
                        Add-Member -MemberType ScriptProperty -Name FileVersionInfo -Value {
                            return @( ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'ProductVersion' -Value $mockRobocopyExecutableVersion -PassThru -Force
                                ) )
                        } -PassThru -Force
                )
            )
        }

        $mockStartSqlSetupProcessExpectedArgument = ''  # Set dynamically during runtime
        $mockStartSqlSetupProcessExitCode = 0  # Set dynamically during runtime

        $mockStartSqlSetupProcess_Robocopy = {
            if ( $ArgumentList -cne $mockStartSqlSetupProcessExpectedArgument )
            {
                throw "Expected arguments was not the same as the arguments in the function call.`nExpected: '$mockStartSqlSetupProcessExpectedArgument' `n But was: '$ArgumentList'"
            }

            return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value 0 -PassThru -Force
        }

        $mockStartSqlSetupProcess_Robocopy_WithExitCode = {
            return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value $mockStartSqlSetupProcessExitCode -PassThru -Force
        }
    }

    Context 'When Copy-ItemWithRobocopy is called it should return the correct arguments' {
        BeforeEach {
            Mock -CommandName Get-Command -MockWith $mockGetCommand
            Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy
            $mockRobocopyArgumentSourcePathQuoted = '"{0}"' -f $mockRobocopyArgumentSourcePath
            $mockRobocopyArgumentDestinationPathQuoted = '"{0}"' -f $mockRobocopyArgumentDestinationPath
        }


        It 'Should use Unbuffered IO when copying' {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

            $mockStartSqlSetupProcessExpectedArgument =
                $mockRobocopyArgumentSourcePathQuoted,
                $mockRobocopyArgumentDestinationPathQuoted,
                $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty,
                $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                $mockRobocopyArgumentUseUnbufferedIO,
                $mockRobocopyArgumentSilent -join ' '

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process  -Exactly -Times 1 -Scope It
        }

        It 'Should not use Unbuffered IO when copying' {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithoutUnbufferedIO

            $mockStartSqlSetupProcessExpectedArgument =
                $mockRobocopyArgumentSourcePathQuoted,
                $mockRobocopyArgumentDestinationPathQuoted,
                $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty,
                $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                '',
                $mockRobocopyArgumentSilent -join ' '

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }
    }

    Context 'When Copy-ItemWithRobocopy throws an exception it should return the correct error messages' {
        BeforeAll {
            $mockRobocopyArgumentSourcePath = 'C:\Source\SQL2016'
            $mockRobocopyArgumentDestinationPath = 'D:\Temp\DSCSQL2016'
            $mockRobocopyExecutableName = 'Robocopy.exe'
            $mockRobocopyExecutableVersion = ''     # Set dynamically during runtime
        }

        BeforeEach {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

            Mock -CommandName Get-Command -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockRobocopyExecutableName -PassThru |
                            Add-Member -MemberType ScriptProperty -Name FileVersionInfo -Value {
                                return @( ( New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ProductVersion' -Value $mockRobocopyExecutableVersion -PassThru -Force
                                    ) )
                            } -PassThru -Force
                    )
                )
            }

            Mock -CommandName Start-Process -MockWith {
                return New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value $mockStartSqlSetupProcessExitCode -PassThru -Force
            }
        }

        It 'Should throw the correct error message when error code is 8' {
            $mockStartSqlSetupProcessExitCode = 8

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.RobocopyErrorCopying
            }

            $mockErrorMessage = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $mockStartSqlSetupProcessExitCode
            )

            $mockErrorMessage.Exception.Message | Should -Not -BeNullOrEmpty

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw -ExpectedMessage $mockErrorMessage

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should throw the correct error message when error code is 16' {
            $mockStartSqlSetupProcessExitCode = 16

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }


            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.RobocopyErrorCopying
            }

            $mockErrorMessage = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $mockStartSqlSetupProcessExitCode
            )

            $mockErrorMessage.Exception.Message | Should -Not -BeNullOrEmpty

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw -ExpectedMessage $mockErrorMessage

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should throw the correct error message when error code is greater than 7 (but not 8 or 16)' {
            $mockStartSqlSetupProcessExitCode = 9

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.RobocopyFailuresCopying
            }

            $mockErrorMessage = Get-InvalidResultRecord -Message (
                $mockLocalizedString -f $mockStartSqlSetupProcessExitCode
            )

            $mockErrorMessage | Should -Not -BeNullOrEmpty

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw -ExpectedMessage $mockErrorMessage

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }
    }

    Context 'When Copy-ItemWithRobocopy is called and finishes successfully it should return the correct exit code' {
        BeforeEach {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

            Mock -CommandName Get-Command -MockWith $mockGetCommand
            Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy_WithExitCode
        }

        AfterEach {
            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should finish successfully with exit code 1' {
            $mockStartSqlSetupProcessExitCode = 1

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should finish successfully with exit code 2' {
            $mockStartSqlSetupProcessExitCode = 2

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should finish successfully with exit code 3' {
            $mockStartSqlSetupProcessExitCode = 3

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw
        }
    }

    Context 'When Copy-ItemWithRobocopy is called with spaces in paths and finishes successfully it should return the correct exit code' {
        BeforeEach {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

            Mock -CommandName Get-Command -MockWith $mockGetCommand
            Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy_WithExitCode
        }

        AfterEach {
            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should finish successfully with exit code 1' {
            $mockStartSqlSetupProcessExitCode = 1

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePathWithSpaces
                DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
            }

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

        }

        It 'Should finish successfully with exit code 2' {
            $mockStartSqlSetupProcessExitCode = 2

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePathWithSpaces
                DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
            }

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

        }

        It 'Should finish successfully with exit code 3' {
            $mockStartSqlSetupProcessExitCode = 3

            $copyItemWithRobocopyParameter = @{
                Path = $mockRobocopyArgumentSourcePathWithSpaces
                DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
            }

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw
        }
    }
}

Describe 'SqlServerDsc.Common\Invoke-InstallationMediaCopy' -Tag 'InvokeInstallationMediaCopy' {
    BeforeAll {
        $mockSourcePathGuid = 'cc719562-0f46-4a16-8605-9f8a47c70402'
        $mockDestinationPath = 'C:\Users\user\AppData\Local\Temp'

        $mockShareCredentialUserName = 'COMPANY\SqlAdmin'
        $mockShareCredentialPassword = 'dummyPassW0rd'
        $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
            $mockShareCredentialUserName,
            ($mockShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
        )

        $mockGetTemporaryFolder = {
            return $mockDestinationPath
        }

        $mockNewGuid = {
            return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Guid' -Value $mockSourcePathGuid -PassThru -Force
        }

        Mock -CommandName Connect-UncPath
        Mock -CommandName Disconnect-UncPath
        Mock -CommandName Copy-ItemWithRobocopy
        Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder
        Mock -CommandName New-Guid -MockWith $mockNewGuid
    }

    Context 'When invoking installation media copy, using SourcePath containing leaf' {
        BeforeAll {
            $mockSourcePathUNCWithLeaf = '\\server\share\leaf'
        }

        It 'Should call the correct mocks' {
            {
                $invokeInstallationMediaCopyParameters = @{
                    SourcePath = $mockSourcePathUNCWithLeaf
                    SourceCredential = $mockShareCredential
                }

                Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Guid -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Copy-ItemWithRobocopy -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
        }

        It 'Should return the correct destination path' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath = $mockSourcePathUNCWithLeaf
                SourceCredential = $mockShareCredential
                PassThru = $true
            }

            $invokeInstallationMediaCopyResult = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters

            $invokeInstallationMediaCopyResult | Should -Be ('{0}\leaf' -f $mockDestinationPath)
        }
    }

    Context 'When invoking installation media copy, using SourcePath containing a second leaf' {
        BeforeAll {
            $mockSourcePathUNCWithLeaf = '\\server\share\leaf\secondleaf'
        }

        It 'Should call the correct mocks' {
            {
                $invokeInstallationMediaCopyParameters = @{
                    SourcePath = $mockSourcePathUNCWithLeaf
                    SourceCredential = $mockShareCredential
                }

                Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Guid -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Copy-ItemWithRobocopy -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
        }

        It 'Should return the correct destination path' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath = $mockSourcePathUNCWithLeaf
                SourceCredential = $mockShareCredential
                PassThru = $true
            }

            $invokeInstallationMediaCopyResult = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters

            $invokeInstallationMediaCopyResult | Should -Be ('{0}\secondleaf' -f $mockDestinationPath)
        }
    }

    Context 'When invoking installation media copy, using SourcePath without a leaf' {
        BeforeAll {
            $mockSourcePathUNC = '\\server\share'
        }

        It 'Should call the correct mocks' {
            {
                $invokeInstallationMediaCopyParameters = @{
                    SourcePath = $mockSourcePathUNC
                    SourceCredential = $mockShareCredential
                }

                Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Guid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Copy-ItemWithRobocopy -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
        }

        It 'Should return the correct destination path' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath = $mockSourcePathUNC
                SourceCredential = $mockShareCredential
                PassThru = $true
            }

            $invokeInstallationMediaCopyResult = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
            $invokeInstallationMediaCopyResult | Should -Be ('{0}\{1}' -f $mockDestinationPath, $mockSourcePathGuid)
        }
    }
}

Describe 'SqlServerDsc.Common\Connect-UncPath' -Tag 'ConnectUncPath' {
    BeforeAll {
        $mockSourcePathUNC = '\\server\share'

        $mockShareCredentialUserName = 'COMPANY\SqlAdmin'
        $mockShareCredentialPassword = 'dummyPassW0rd'
        $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
            $mockShareCredentialUserName,
            ($mockShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
        )

        $mockFqdnShareCredentialUserName = 'SqlAdmin@company.local'
        $mockFqdnShareCredentialPassword = 'dummyPassW0rd'
        $mockFqdnShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
            $mockFqdnShareCredentialUserName,
            ($mockFqdnShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
        )

        Mock -CommandName New-SmbMapping -MockWith {
            return @{
                RemotePath = $mockSourcePathUNC
            }
        }
    }

    Context 'When connecting to a UNC path without credentials (using current credentials)' {
        It 'Should call the correct mocks' {
            {
                $connectUncPathParameters = @{
                    RemotePath = $mockSourcePathUNC
                }

                Connect-UncPath @connectUncPathParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName New-SmbMapping -ParameterFilter {
                <#
                    Due to issue https://github.com/pester/Pester/issues/1542
                    we must use `$null -ne $UserName` instead of
                    `$PSBoundParameters.ContainsKey('UserName') -eq $false`.
                #>
                $RemotePath -eq $mockSourcePathUNC `
                -and $null -eq $UserName
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When connecting to a UNC path with specific credentials' {
        It 'Should call the correct mocks' {
            {
                $connectUncPathParameters = @{
                    RemotePath = $mockSourcePathUNC
                    SourceCredential = $mockShareCredential
                }

                Connect-UncPath @connectUncPathParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName New-SmbMapping -ParameterFilter {
                $RemotePath -eq $mockSourcePathUNC `
                -and $UserName -eq $mockShareCredentialUserName
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When connecting using Fully Qualified Domain Name (FQDN)' {
        It 'Should call the correct mocks' {
            {
                $connectUncPathParameters = @{
                    RemotePath = $mockSourcePathUNC
                    SourceCredential = $mockFqdnShareCredential
                }

                Connect-UncPath @connectUncPathParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName New-SmbMapping -ParameterFilter {
                $RemotePath -eq $mockSourcePathUNC `
                -and $UserName -eq $mockFqdnShareCredentialUserName
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When connecting to a UNC path and using parameter PassThru' {
        It 'Should return the correct MSFT_SmbMapping object' {
            $connectUncPathParameters = @{
                RemotePath = $mockSourcePathUNC
                SourceCredential = $mockShareCredential
                PassThru = $true
            }

            $connectUncPathResult = Connect-UncPath @connectUncPathParameters
            $connectUncPathResult.RemotePath | Should -Be $mockSourcePathUNC
        }
    }
}

Describe 'SqlServerDsc.Common\Disconnect-UncPath' -Tag 'DisconnectUncPath' {
    BeforeAll {
        $mockSourcePathUNC = '\\server\share'

        Mock -CommandName Remove-SmbMapping
    }

    Context 'When disconnecting from an UNC path' {
        It 'Should call the correct mocks' {
            {
                $disconnectUncPathParameters = @{
                    RemotePath = $mockSourcePathUNC
                }

                Disconnect-UncPath @disconnectUncPathParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlServerDsc.Common\Test-PendingRestart' -Tag 'TestPendingRestart' {
    Context 'When there is a pending reboot' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 'AnyValue'
            }
        }

        It 'Should return $true' {
            $testPendingRestartResult = Test-PendingRestart
            $testPendingRestartResult | Should -BeTrue

            Should -Invoke -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope It
        }
    }

    Context 'When there are no pending reboot' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue
        }

        It 'Should return $true' {
            $testPendingRestartResult = Test-PendingRestart
            $testPendingRestartResult | Should -BeFalse

            Should -Invoke -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlServerDsc.Common\Start-SqlSetupProcess' -Tag 'StartSqlSetupProcess' {
    Context 'When starting a process successfully' {
        It 'Should return exit code 0' {
            $startSqlSetupProcessParameters = @{
                FilePath = 'powershell.exe'
                ArgumentList = '-NonInteractive -NoProfile -Command &{Start-Sleep -Seconds 2}'
                Timeout = 30
            }

            $processExitCode = Start-SqlSetupProcess @startSqlSetupProcessParameters
            $processExitCode | Should -BeExactly 0
        }
    }

    Context 'When starting a process and the process does not finish before the timeout period' {
        It 'Should throw an error message' {
            $startSqlSetupProcessParameters = @{
                FilePath = 'powershell.exe'
                ArgumentList = '-NonInteractive -NoProfile -Command &{Start-Sleep -Seconds 4}'
                Timeout = 2
            }

            { Start-SqlSetupProcess @startSqlSetupProcessParameters } | Should -Throw -ErrorId 'ProcessNotTerminated,Microsoft.PowerShell.Commands.WaitProcessCommand'
        }
    }
}

Describe 'SqlServerDsc.Common\Restart-SqlService' -Tag 'RestartSqlService' {
    Context 'Restart-SqlService standalone instance' {
        Context 'When the Windows services should be restarted' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'MSSQLSERVER'
                        ServiceName = 'MSSQLSERVER'
                        Status = 'Online'
                        IsClustered = $false
                    }
                }

                Mock -CommandName Get-Service -MockWith {
                    return @{
                        Name = 'MSSQLSERVER'
                        DisplayName = 'Microsoft SQL Server (MSSQLSERVER)'
                        DependentServices = @(
                            @{
                                Name = 'SQLSERVERAGENT'
                                DisplayName = 'SQL Server Agent (MSSQLSERVER)'
                                Status = 'Running'
                                DependentServices = @()
                            }
                        )
                    }
                }

                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
                Mock -CommandName Restart-SqlClusterService -ModuleName $subModuleName
            }

            It 'Should restart SQL Service and running SQL Agent service' {
                { Restart-SqlService -ServerName $env:COMPUTERNAME -InstanceName 'MSSQLSERVER' } | Should -Not -Throw

                Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                    <#
                        Make sure we assert just the first call to Connect-SQL.

                        Due to issue https://github.com/pester/Pester/issues/1542
                        we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $false`.
                    #>
                    $ErrorAction -ne 'SilentlyContinue'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Restart-SqlClusterService -Scope It -Exactly -Times 0 -ModuleName $subModuleName
                Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 1

            }

            Context 'When skipping the cluster check' {
                It 'Should restart SQL Service and running SQL Agent service' {
                    { Restart-SqlService -ServerName $env:COMPUTERNAME -InstanceName 'MSSQLSERVER' -SkipClusterCheck } | Should -Not -Throw

                    Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                        <#
                            Make sure we assert just the first call to Connect-SQL.

                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $false`.
                        #>
                        $ErrorAction -ne 'SilentlyContinue'
                    } -Scope It -Exactly -Times 0

                    Should -Invoke -CommandName Restart-SqlClusterService -Scope It -Exactly -Times 0 -ModuleName $subModuleName
                    Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                    Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                    Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 1
                }
            }

            Context 'When skipping the online check' {
                It 'Should restart SQL Service and running SQL Agent service and not wait for the SQL Server instance to come back online' {
                    { Restart-SqlService -ServerName $env:COMPUTERNAME -InstanceName 'MSSQLSERVER' -SkipWaitForOnline } | Should -Not -Throw

                    Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                        <#
                            Make sure we assert just the first call to Connect-SQL.

                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $false`.
                        #>
                        $ErrorAction -ne 'SilentlyContinue'
                    } -Scope It -Exactly -Times 1

                    Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                        <#
                            Make sure we assert the second call to Connect-SQL

                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $true`.
                        #>
                        $ErrorAction -eq 'SilentlyContinue'
                    } -Scope It -Exactly -Times 0

                    Should -Invoke -CommandName Restart-SqlClusterService -Scope It -Exactly -Times 0 -ModuleName $subModuleName
                    Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                    Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                    Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 1
                }
            }
        }

        Context 'When the SQL Server instance is a Failover Cluster instance' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'MSSQLSERVER'
                        ServiceName = 'MSSQLSERVER'
                        Status = 'Online'
                        IsClustered = $true
                    }
                }

                Mock -CommandName Get-Service
                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
                Mock -CommandName Restart-SqlClusterService -ModuleName $subModuleName
            }

            It 'Should just call Restart-SqlClusterService to restart the SQL Server cluster instance' {
                { Restart-SqlService -ServerName $env:COMPUTERNAME -InstanceName 'MSSQLSERVER' } | Should -Not -Throw

                Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                    <#
                        Make sure we assert just the first call to Connect-SQL.

                        Due to issue https://github.com/pester/Pester/issues/1542
                        we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $false`.
                    #>
                    $ErrorAction -ne 'SilentlyContinue'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Restart-SqlClusterService -Scope It -Exactly -Times 1 -ModuleName $subModuleName
                Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 0
                Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 0
                Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 0
            }

            Context 'When passing the Timeout value' {
                It 'Should just call Restart-SqlClusterService with the correct parameter' {
                    { Restart-SqlService -ServerName $env:COMPUTERNAME -InstanceName 'MSSQLSERVER' -Timeout 120 } | Should -Not -Throw

                    Should -Invoke -CommandName Restart-SqlClusterService -ParameterFilter {
                        <#
                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('Timeout') -eq $true`.
                        #>
                        $null -ne $Timeout
                    } -Scope It -Exactly -Times 1 -ModuleName $subModuleName
                }
            }

            Context 'When passing the OwnerNode value' {
                It 'Should just call Restart-SqlClusterService with the correct parameter' {
                    { Restart-SqlService -ServerName $env:COMPUTERNAME -InstanceName 'MSSQLSERVER' -OwnerNode @('TestNode') } | Should -Not -Throw

                    Should -Invoke -CommandName Restart-SqlClusterService -ParameterFilter {
                        <#
                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('OwnerNode') -eq $true`.
                        #>
                        $null -ne $OwnerNode
                    } -Scope It -Exactly -Times 1 -ModuleName $subModuleName
                }
            }
        }

        Context 'When the Windows services should be restarted but there is not SQL Agent service' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'NOAGENT'
                        InstanceName = 'NOAGENT'
                        ServiceName = 'NOAGENT'
                        Status = 'Online'
                    }
                }

                Mock -CommandName Get-Service -MockWith {
                    return @{
                        Name = 'MSSQL$NOAGENT'
                        DisplayName = 'Microsoft SQL Server (NOAGENT)'
                        DependentServices = @()
                    }
                }

                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
                Mock -CommandName Restart-SqlClusterService -ModuleName $subModuleName
            }

            It 'Should restart SQL Service and not try to restart missing SQL Agent service' {
                { Restart-SqlService -ServerName $env:COMPUTERNAME -InstanceName 'NOAGENT' -SkipClusterCheck } | Should -Not -Throw

                Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 0
            }
        }

        Context 'When the Windows services should be restarted but the SQL Agent service is stopped' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'STOPPEDAGENT'
                        InstanceName = 'STOPPEDAGENT'
                        ServiceName = 'STOPPEDAGENT'
                        Status = 'Online'
                    }
                }

                Mock -CommandName Get-Service -MockWith {
                    return @{
                        Name = 'MSSQL$STOPPEDAGENT'
                        DisplayName = 'Microsoft SQL Server (STOPPEDAGENT)'
                        DependentServices = @(
                            @{
                                Name = 'SQLAGENT$STOPPEDAGENT'
                                DisplayName = 'SQL Server Agent (STOPPEDAGENT)'
                                Status = 'Stopped'
                                DependentServices = @()
                            }
                        )
                    }
                }

                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
                Mock -CommandName Restart-SqlClusterService -ModuleName $subModuleName
            }

            It 'Should restart SQL Service and not try to restart stopped SQL Agent service' {
                { Restart-SqlService -ServerName $env:COMPUTERNAME -InstanceName 'STOPPEDAGENT' -SkipClusterCheck } | Should -Not -Throw

                Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 0
            }
        }

        Context 'When it fails to connect to the instance within the timeout period' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name = 'MSSQLSERVER'
                        InstanceName = ''
                        ServiceName = 'MSSQLSERVER'
                        Status = 'Offline'
                    }
                }

                Mock -CommandName Get-Service -MockWith {
                    return @{
                        Name = 'MSSQLSERVER'
                        DisplayName = 'Microsoft SQL Server (MSSQLSERVER)'
                        DependentServices = @(
                            @{
                                Name = 'SQLSERVERAGENT'
                                DisplayName = 'SQL Server Agent (MSSQLSERVER)'
                                Status = 'Running'
                                DependentServices = @()
                            }
                        )
                    }
                }

                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
            }

            It 'Should wait for timeout before throwing error message' {
                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $localizedData.FailedToConnectToInstanceTimeout
                }

                $mockErrorMessage = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f $env:ComputerName, 'MSSQLSERVER', 4
                )

                $mockErrorMessage.Exception.Message | Should -Not -BeNullOrEmpty

                {
                    Restart-SqlService -ServerName $env:ComputerName -InstanceName 'MSSQLSERVER' -Timeout 4 -SkipClusterCheck
                } | Should -Throw -ExpectedMessage $mockErrorMessage

                Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                    <#
                        Make sure we assert the second call to Connect-SQL

                        Due to issue https://github.com/pester/Pester/issues/1542
                        we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $true`.
                    #>
                    $ErrorAction -eq 'SilentlyContinue'
                } -Scope It -Exactly -Times 2
            }
        }
    }
}

Describe 'SqlServerDsc.Common\Restart-SqlClusterService' -Tag 'RestartSqlClusterService' {
    Context 'When not clustered instance is found' {
        BeforeAll {
            Mock -CommandName Get-CimInstance
            Mock -CommandName Get-CimAssociatedInstance
            Mock -CommandName Invoke-CimMethod
        }

        It 'Should not restart any cluster resources' {
            InModuleScope -ScriptBlock {
                { Restart-SqlClusterService -InstanceName 'MSSQLSERVER' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
        }
    }

    Context 'When clustered instance is offline' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                    InstanceName = 'MSSQLSERVER'
                }
                # Mock the resource to be online.
                $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 3 -TypeName 'Int32'

                return $mock
            }

            Mock -CommandName Get-CimAssociatedInstance
            Mock -CommandName Invoke-CimMethod
        }

        It 'Should not restart any cluster resources' {
            InModuleScope -ScriptBlock {
                { Restart-SqlClusterService -InstanceName 'MSSQLSERVER' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 0

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'TakeOffline'
            } -Scope It -Exactly -Times 0

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'BringOnline'
            } -Scope It -Exactly -Times 0
        }
    }

    Context 'When restarting a Sql Server clustered instance' {
        Context 'When it is the default instance'{
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should restart SQL Server cluster resource and the SQL Agent cluster resource' {
                InModuleScope -ScriptBlock {
                    { Restart-SqlClusterService -InstanceName 'MSSQLSERVER' } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1
            }
        }

        Context 'When it is a named instance'{
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (DSCTEST)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'DSCTEST'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should restart SQL Server cluster resource and the SQL Agent cluster resource' {
                InModuleScope -ScriptBlock {
                    { Restart-SqlClusterService -InstanceName 'DSCTEST' } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (DSCTEST)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (DSCTEST)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (DSCTEST)'
                } -Scope It -Exactly -Times 1
            }
        }
    }

    Context 'When restarting a Sql Server clustered instance and the SQL Agent is offline' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                    InstanceName = 'MSSQLSERVER'
                }
                # Mock the resource to be online.
                $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                return $mock
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith {
                $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                # Mock the resource to be offline.
                $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 3 -TypeName 'Int32'

                return $mock
            }

            Mock -CommandName Invoke-CimMethod
        }

        It 'Should restart the SQL Server cluster resource and ignore the SQL Agent cluster resource online ' {
            InModuleScope -ScriptBlock {
                { Restart-SqlClusterService -InstanceName 'MSSQLSERVER' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
            } -Scope It -Exactly -Times 1

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
            } -Scope It -Exactly -Times 1
        }
    }

    Context 'When passing the parameter OwnerNode' {
        Context 'When both the SQL Server and SQL Agent cluster resources is owned by the current node' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be offline.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should restart the SQL Server cluster resource and the SQL Agent cluster resource' {
                InModuleScope -ScriptBlock {
                    { Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -OwnerNode @('NODE1') } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1
            }
        }

        Context 'When both the SQL Server and SQL Agent cluster resources is owned by the current node but the SQL Agent cluster resource is offline' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be offline.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 3 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should only restart the SQL Server cluster resource' {
                InModuleScope -ScriptBlock {
                    { Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -OwnerNode @('NODE1') } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (MSSQLSERVER)'
                } -Scope It -Exactly -Times 0
            }
        }

        Context 'When only the SQL Server cluster resources is owned by the current node' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be offline.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE2' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should only restart the SQL Server cluster resource' {
                InModuleScope -ScriptBlock {
                    { Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -OwnerNode @('NODE1') } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (MSSQLSERVER)'
                } -Scope It -Exactly -Times 0
            }
        }

        Context 'When the SQL Server cluster resources is not owned by the current node' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource','root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE2' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance
                Mock -CommandName Invoke-CimMethod
            }

            It 'Should not restart any cluster resources' {
                InModuleScope -ScriptBlock {
                    { Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -OwnerNode @('NODE1') } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 0

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline'
                } -Scope It -Exactly -Times 0

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline'
                } -Scope It -Exactly -Times 0
            }
        }
    }
}

Describe 'SqlServerDsc.Common\Connect-SQLAnalysis' -Tag 'ConnectSQLAnalysis' {
    BeforeAll {
        $mockInstanceName = 'TEST'
        $mockDynamicConnectedStatus = $true

        $mockNewObject_MicrosoftAnalysisServicesServer = {
            return New-Object -TypeName Object |
                        Add-Member -MemberType 'NoteProperty' -Name 'Connected' -Value $mockDynamicConnectedStatus -PassThru |
                        Add-Member -MemberType 'ScriptMethod' -Name 'Connect' -Value {
                            param
                            (
                                [Parameter(Mandatory = $true)]
                                [ValidateNotNullOrEmpty()]
                                [System.String]
                                $DataSource
                            )

                            if ($DataSource -ne $mockExpectedDataSource)
                            {
                                throw ("Datasource was expected to be '{0}', but was '{1}'." -f $mockExpectedDataSource,$dataSource)
                            }

                            if ($mockThrowInvalidOperation)
                            {
                                throw 'Unable to connect.'
                            }
                        } -PassThru -Force
        }

        $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter = {
            $TypeName -eq 'Microsoft.AnalysisServices.Server'
        }

        $mockSqlCredentialUserName = 'TestUserName12345'
        $mockSqlCredentialPassword = 'StrongOne7.'
        $mockSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockSqlCredentialPassword -AsPlainText -Force
        $mockSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockSqlCredentialUserName, $mockSqlCredentialSecurePassword)

        $mockNetBiosSqlCredentialUserName = 'DOMAIN\TestUserName12345'
        $mockNetBiosSqlCredentialPassword = 'StrongOne7.'
        $mockNetBiosSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockNetBiosSqlCredentialPassword -AsPlainText -Force
        $mockNetBiosSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockNetBiosSqlCredentialUserName, $mockNetBiosSqlCredentialSecurePassword)

        $mockFqdnSqlCredentialUserName = 'TestUserName12345@domain.local'
        $mockFqdnSqlCredentialPassword = 'StrongOne7.'
        $mockFqdnSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockFqdnSqlCredentialPassword -AsPlainText -Force
        $mockFqdnSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockFqdnSqlCredentialUserName, $mockFqdnSqlCredentialSecurePassword)

        $mockComputerName = Get-ComputerName
    }

    BeforeEach {
        Mock -CommandName New-Object `
            -MockWith $mockNewObject_MicrosoftAnalysisServicesServer `
            -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
    }

    Context 'When using feature flag ''AnalysisServicesConnection''' {
        BeforeAll {
            Mock -CommandName Import-SQLPSModule

            $mockExpectedDataSource = "Data Source=$mockComputerName"
        }

        Context 'When connecting to the default instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                { Connect-SQLAnalysis -FeatureFlag 'AnalysisServicesConnection' } | Should -Not -Throw

                Should -Invoke -CommandName Import-SQLPSModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }

            Context 'When Connected status is $false' {
                BeforeAll {
                    $mockDynamicConnectedStatus = $false
                }

                AfterAll {
                    $mockDynamicConnectedStatus = $true
                }

                It 'Should throw the correct error' {
                    $mockLocalizedString = InModuleScope -ScriptBlock {
                        $script:localizedData.FailedToConnectToAnalysisServicesInstance
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message (
                        $mockLocalizedString -f $mockComputerName
                    )

                    { Connect-SQLAnalysis -FeatureFlag 'AnalysisServicesConnection' } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
                }
            }
        }

        Context 'When connecting to the named instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName"

                { Connect-SQLAnalysis -InstanceName $mockInstanceName -FeatureFlag 'AnalysisServicesConnection' } | Should -Not -Throw
            }
        }

        Context 'When connecting to the named instance using Windows Authentication impersonation' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName;User ID=$mockSqlCredentialUserName;Password=$mockSqlCredentialPassword"

                { Connect-SQLAnalysis -InstanceName $mockInstanceName -SetupCredential $mockSqlCredential -FeatureFlag 'AnalysisServicesConnection' } | Should -Not -Throw
            }
        }
    }

    Context 'When not using feature flag ''AnalysisServicesConnection''' {
        BeforeAll {
            Mock -CommandName Import-Assembly
        }

        Context 'When connecting to the default instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$mockComputerName"

                { Connect-SQLAnalysis } | Should -Not -Throw

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the named instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName"

                { Connect-SQLAnalysis -InstanceName $mockInstanceName } | Should -Not -Throw

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the named instance using Windows Authentication impersonation' {
            Context 'When authentication without NetBIOS domain and Fully Qualified Domain Name (FQDN)' {
                It 'Should not throw when connecting' {
                    $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName;User ID=$mockSqlCredentialUserName;Password=$mockSqlCredentialPassword"

                    { Connect-SQLAnalysis -InstanceName $mockInstanceName -SetupCredential $mockSqlCredential } | Should -Not -Throw

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
                }
            }

            Context 'When authentication using NetBIOS domain' {
                It 'Should not throw when connecting' {
                    $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName;User ID=$mockNetBiosSqlCredentialUserName;Password=$mockNetBiosSqlCredentialPassword"

                    { Connect-SQLAnalysis -InstanceName $mockInstanceName -SetupCredential $mockNetBiosSqlCredential } | Should -Not -Throw

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
                }
            }

            Context 'When authentication using Fully Qualified Domain Name (FQDN)' {
                It 'Should not throw when connecting' {
                    $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName;User ID=$mockFqdnSqlCredentialUserName;Password=$mockFqdnSqlCredentialPassword"

                    { Connect-SQLAnalysis -InstanceName $mockInstanceName -SetupCredential $mockFqdnSqlCredential } | Should -Not -Throw

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
                }
            }
        }

        Context 'When connecting to the default instance using the correct service instance but does not return a correct Analysis Service object' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = ''

                Mock -CommandName New-Object `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.FailedToConnectToAnalysisServicesInstance
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f $mockComputerName
                )

                { Connect-SQLAnalysis } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the default instance using a Analysis Service instance that does not exist' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = "Data Source=$mockComputerName"

                # Force the mock of Connect() method to throw 'Unable to connect.'
                $mockThrowInvalidOperation = $true

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.FailedToConnectToAnalysisServicesInstance
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f $mockComputerName
                )

                { Connect-SQLAnalysis } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter

                # Setting it back to the default so it does not disturb other tests.
                $mockThrowInvalidOperation = $false
            }
        }

        # This test is to test the mock so that it throws correct when data source is not the expected data source
        Context 'When connecting to the named instance using another data source then expected' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = "Force wrong data source"

                $testParameters = @{
                    ServerName = 'DummyHost'
                    InstanceName = $mockInstanceName
                }

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.FailedToConnectToAnalysisServicesInstance
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f "$($testParameters.ServerName)\$($testParameters.InstanceName)"
                )

                { Connect-SQLAnalysis @testParameters } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }
    }
}

Describe 'SqlServerDsc.Common\Invoke-Query' -Tag 'InvokeQuery' {
    BeforeAll {
        $mockExpectedQuery = ''

        $mockSqlCredentialUserName = 'TestUserName12345'
        $mockSqlCredentialPassword = 'StrongOne7.'
        $mockSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockSqlCredentialPassword -AsPlainText -Force
        $mockSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockSqlCredentialUserName, $mockSqlCredentialSecurePassword)

        $masterDatabaseObject = New-Object -TypeName PSObject
        $masterDatabaseObject | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'master'
        $masterDatabaseObject | Add-Member -MemberType ScriptMethod -Name 'ExecuteNonQuery' -Value {
            param
            (
                [Parameter()]
                [System.String]
                $sqlCommand
            )

            if ( $sqlCommand -ne $mockExpectedQuery )
            {
                throw
            }
        }

        $masterDatabaseObject | Add-Member -MemberType ScriptMethod -Name 'ExecuteWithResults' -Value {
            param
            (
                [Parameter()]
                [System.String]
                $sqlCommand
            )

            if ( $sqlCommand -ne $mockExpectedQuery )
            {
                throw
            }

            return New-Object -TypeName System.Data.DataSet
        }

        $databasesObject = New-Object -TypeName PSObject
        $databasesObject | Add-Member -MemberType NoteProperty -Name 'Databases' -Value @{
            'master' = $masterDatabaseObject
        }

        $mockSMOServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
        $mockSMOServer | Add-Member -MemberType NoteProperty -Name 'Databases' -Value @{
            'master' = $masterDatabaseObject
        } -Force

        $mockConnectSql = {
            return @($databasesObject)
        }

        $queryParameters = @{
            ServerName         = 'Server1'
            InstanceName       = 'MSSQLSERVER'
            Database           = 'master'
            Query              = ''
            DatabaseCredential = $mockSqlCredential
        }

        $queryParametersWithSMO = @{
            Query              = ''
            SqlServerObject    = $mockSMOServer
            Database           = 'master'
        }
    }

    BeforeEach {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSql
    }

    Context 'When executing a query with no results' {
        AfterEach {
            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
        }

        It 'Should execute the query silently' {
            $queryParameters.Query = "EXEC sp_configure 'show advanced option', '1'"
            $mockExpectedQuery = $queryParameters.Query.Clone()

            { Invoke-Query @queryParameters } | Should -Not -Throw

            Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                <#
                    Should not be called with a login type.

                    Due to issue https://github.com/pester/Pester/issues/1542
                    we cannot use `$PSBoundParameters.ContainsKey('LoginType') -eq $false`.
                #>
                $null -eq $LoginType
            } -Scope It -Times 1 -Exactly
        }

        It 'Should throw the correct error, ExecuteNonQueryFailed, when executing the query fails' {
            $queryParameters.Query = 'BadQuery'

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.ExecuteNonQueryFailed
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $queryParameters.Database
            )

            { Invoke-Query @queryParameters } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
        }

        Context 'When text should be redacted' {
            BeforeAll {
                Mock -CommandName Write-Verbose -ParameterFilter {
                    $mockLocalizedString = InModuleScope -ScriptBlock {
                        $script:localizedData.ExecuteNonQuery
                    }

                    $Message -eq (
                        $mockLocalizedString -f
                            "select * from MyTable where password = '*******' and password = '*******'"
                    )
                } -MockWith {
                    <#
                        MUST return another message than the parameter filter
                        is looking for, otherwise we get into a endless loop.
                        We returning the to show in the output how the verbose
                        message was redacted.
                    #>
                    Write-Verbose -Message ('MOCK OUTPUT: {0}' -f $Message) -Verbose
                }
            }

            It 'Should execute the query silently and redact text in the verbose output' {
                $queryParameters.Query = "select * from MyTable where password = 'Pa\ssw0rd1' and password = 'secret passphrase'"
                $mockExpectedQuery = $queryParameters.Query.Clone()

                # The `Secret PassPhrase` is using the casing like this to test case-insensitive replace.
                { Invoke-Query @queryParameters -RedactText @('Pa\sSw0rd1','Secret PassPhrase') } | Should -Not -Throw
            }
        }
    }

    Context 'When executing a query with no results using Windows impersonation' {
        It 'Should execute the query silently' {
            $testParameters = $queryParameters.Clone()
            $testParameters.LoginType = 'WindowsUser'
            $testParameters.Query = "EXEC sp_configure 'show advanced option', '1'"
            $mockExpectedQuery = $testParameters.Query.Clone()

            { Invoke-Query @testParameters } | Should -Not -Throw

            Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                $LoginType -eq 'WindowsUser'
            } -Scope It -Times 1 -Exactly
        }
    }

    Context 'when executing a query with no results using SQL impersonation' {
        It 'Should execute the query silently' {
            $testParameters = $queryParameters.Clone()
            $testParameters.LoginType = 'SqlLogin'
            $testParameters.Query = "EXEC sp_configure 'show advanced option', '1'"
            $mockExpectedQuery = $testParameters.Query.Clone()

            { Invoke-Query @testParameters } | Should -Not -Throw

            Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                $LoginType -eq 'SqlLogin'
            } -Scope It -Times 1 -Exactly
        }
    }

    Context 'when executing a query with results' {
        It 'Should execute the query and return a result set' {
            $queryParameters.Query = 'SELECT name FROM sys.databases'
            $mockExpectedQuery = $queryParameters.Query.Clone()

            Invoke-Query @queryParameters -WithResults | Should -Not -BeNullOrEmpty

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
        }

        It 'Should throw the correct error, ExecuteQueryWithResultsFailed, when executing the query fails' {
            $queryParameters.Query = 'BadQuery'

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.ExecuteQueryWithResultsFailed
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $queryParameters.Database
            )

            { Invoke-Query @queryParameters -WithResults } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
        }

        Context 'When text should be redacted' {
            BeforeAll {
                Mock -CommandName Write-Verbose -ParameterFilter {
                    $mockLocalizedString = InModuleScope -ScriptBlock {
                        $script:localizedData.ExecuteQueryWithResults
                    }

                    $Message -eq (
                        $mockLocalizedString -f
                            "select * from MyTable where password = '*******' and password = '*******'"
                    )
                } -MockWith {
                    <#
                        MUST return another message than the parameter filter
                        is looking for, otherwise we get into a endless loop.
                        We returning the to show in the output how the verbose
                        message was redacted.
                    #>
                    Write-Verbose -Message ('MOCK OUTPUT: {0}' -f $Message) -Verbose
                }
            }

            It 'Should execute the query silently and redact text in the verbose output' {
                $queryParameters.Query = "select * from MyTable where password = 'Pa\ssw0rd1' and password = 'secret passphrase'"
                $mockExpectedQuery = $queryParameters.Query.Clone()

                # The `Secret PassPhrase` is using the casing like this to test case-insensitive replace.
                { Invoke-Query @queryParameters -RedactText @('Pa\sSw0rd1','Secret PassPhrase') -WithResults } | Should -Not -Throw
            }
        }
    }

    Context 'When passing in an SMO Server Object' {
        Context 'Execute a query with no results' {
            It 'Should execute the query silently' {
                $queryParametersWithSMO.Query = "EXEC sp_configure 'show advanced option', '1'"
                $mockExpectedQuery = $queryParametersWithSMO.Query.Clone()

                { Invoke-Query @queryParametersWithSMO } | Should -Not -Throw

                Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, ExecuteNonQueryFailed, when executing the query fails' {
                $queryParametersWithSMO.Query = 'BadQuery'

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.ExecuteNonQueryFailed
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f $queryParameters.Database
                )

                { Invoke-Query @queryParametersWithSMO } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
            }
        }

        Context 'When executing a query with results' {
            It 'Should execute the query and return a result set' {
                $queryParametersWithSMO.Query = 'SELECT name FROM sys.databases'
                $mockExpectedQuery = $queryParametersWithSMO.Query.Clone()

                Invoke-Query @queryParametersWithSMO -WithResults | Should -Not -BeNullOrEmpty

                Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, ExecuteQueryWithResultsFailed, when executing the query fails' {
                $queryParametersWithSMO.Query = 'BadQuery'

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.ExecuteQueryWithResultsFailed
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f $queryParameters.Database
                )

                { Invoke-Query @queryParametersWithSMO -WithResults } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
            }
        }

        Context 'When executing a query with piped SMO server object' {
            It 'Should execute the query and return a result set' {
                $mockQuery = 'SELECT name FROM sys.databases'
                $mockExpectedQuery = $mockQuery

                $mockSMOServer | Invoke-Query -Query $mockQuery -Database master -WithResults |
                    Should -Not -BeNullOrEmpty

                Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, ExecuteQueryWithResultsFailed, when executing the query fails' {
                $mockQuery = 'BadQuery'

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.ExecuteQueryWithResultsFailed
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f $queryParameters.Database
                )

                { $mockSMOServer | Invoke-Query -Query $mockQuery -Database master -WithResults } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
            }
        }
    }
}

Describe 'SqlServerDsc.Common\Update-AvailabilityGroupReplica' -Tag 'UpdateAvailabilityGroupReplica' {
    Context 'When the Availability Group Replica is altered' {
        It 'Should silently alter the Availability Group Replica' {
            $availabilityReplica = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica

            { Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityReplica } | Should -Not -Throw

        }

        It 'Should throw the correct error, AlterAvailabilityGroupReplicaFailed, when altering the Availability Group Replica fails' {
            $availabilityReplica = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $availabilityReplica.Name = 'AlterFailed'

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.AlterAvailabilityGroupReplicaFailed
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $availabilityReplica.Name
            )

            $mockErrorRecord.Exception.Message | Should -Not -BeNullOrEmpty

            { Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityReplica } |
                Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
        }
    }
}

Describe 'SqlServerDsc.Common\Test-LoginEffectivePermissions' -Tag 'TestLoginEffectivePermissions' {
    BeforeAll {
        $mockAllServerPermissionsPresent = @(
            'Connect SQL',
            'Alter Any Availability Group',
            'View Server State'
        )

        $mockServerPermissionsMissing = @(
            'Connect SQL',
            'View Server State'
        )

        $mockAllLoginPermissionsPresent = @(
            'View Definition',
            'Impersonate'
        )

        $mockLoginPermissionsMissing = @(
            'View Definition'
        )

        $mockInvokeQueryPermissionsSet = @() # Will be set dynamically in the check

        $mockInvokeQueryPermissionsResult = {
            return New-Object -TypeName PSObject -Property @{
                Tables = @{
                    Rows = @{
                        permission_name = $mockInvokeQueryPermissionsSet
                    }
                }
            }
        }

        $testLoginEffectiveServerPermissionsParams = @{
            ServerName = 'Server1'
            InstanceName = 'MSSQLSERVER'
            Login = 'NT SERVICE\ClusSvc'
            Permissions = @()
        }

        $testLoginEffectiveLoginPermissionsParams = @{
            ServerName = 'Server1'
            InstanceName = 'MSSQLSERVER'
            Login = 'NT SERVICE\ClusSvc'
            Permissions = @()
            SecurableClass = 'LOGIN'
            SecurableName = 'Login1'
        }
    }

    BeforeEach {
        Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryPermissionsResult
    }

    Context 'When all of the permissions are present' {
        It 'Should return $true when the desired server permissions are present' {
            $mockInvokeQueryPermissionsSet = $mockAllServerPermissionsPresent.Clone()
            $testLoginEffectiveServerPermissionsParams.Permissions = $mockAllServerPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveServerPermissionsParams | Should -Be $true

            Should -Invoke -CommandName Invoke-Query -Scope It -Times 1 -Exactly
        }

        It 'Should return $true when the desired login permissions are present' {
            $mockInvokeQueryPermissionsSet = $mockAllLoginPermissionsPresent.Clone()
            $testLoginEffectiveLoginPermissionsParams.Permissions = $mockAllLoginPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveLoginPermissionsParams | Should -Be $true

            Should -Invoke -CommandName Invoke-Query -Scope It -Times 1 -Exactly
        }
    }

    Context 'When a permission is missing' {
        It 'Should return $false when the desired server permissions are not present' {
            $mockInvokeQueryPermissionsSet = $mockServerPermissionsMissing.Clone()
            $testLoginEffectiveServerPermissionsParams.Permissions = $mockAllServerPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveServerPermissionsParams | Should -Be $false

            Should -Invoke -CommandName Invoke-Query -Scope It -Times 1 -Exactly
        }

        It 'Should return $false when the specified login has no server permissions assigned' {
            $mockInvokeQueryPermissionsSet = @()
            $testLoginEffectiveServerPermissionsParams.Permissions = $mockAllServerPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveServerPermissionsParams | Should -Be $false

            Should -Invoke -CommandName Invoke-Query -Scope It -Times 1 -Exactly
        }

        It 'Should return $false when the desired login permissions are not present' {
            $mockInvokeQueryPermissionsSet = $mockLoginPermissionsMissing.Clone()
            $testLoginEffectiveLoginPermissionsParams.Permissions = $mockAllLoginPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveLoginPermissionsParams | Should -Be $false

            Should -Invoke -CommandName Invoke-Query -Scope It -Times 1 -Exactly
        }

        It 'Should return $false when the specified login has no login permissions assigned' {
            $mockInvokeQueryPermissionsSet = @()
            $testLoginEffectiveLoginPermissionsParams.Permissions = $mockAllLoginPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveLoginPermissionsParams | Should -Be $false

            Should -Invoke -CommandName Invoke-Query -Scope It -Times 1 -Exactly
        }
    }
}

Describe 'SqlServerDsc.Common\Import-SQLPSModule' -Tag 'ImportSQLPSModule' {
    BeforeAll {
        <#
            This is the path to the latest version of SQLPS, to test that only the
            newest SQLPS module is returned.
        #>
        $sqlPsLatestModulePath = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'

        <#
            For SQLPS module this should be the root of the module.
            The .psd1 file is parsed from the module full path in the code.
        #>
        $sqlPsExpectedModulePath = Split-Path -Path $sqlPsLatestModulePath -Parent


        $mockImportModule = {
            # Convert the single value array [String[]] to the expected string value [String].
            $moduleNameToImport = $Name[0]

            if ($moduleNameToImport -ne $mockExpectedModuleNameToImport)
            {
                throw ('Wrong module was loaded. Expected {0}, but was {1}.' -f $mockExpectedModuleNameToImport, $moduleNameToImport)
            }

            switch ($moduleNameToImport)
            {
                'SqlServer'
                {
                    $importModuleResult = @{
                        ModuleType = 'Script'
                        Version = '21.0.17279'
                        Name = $moduleNameToImport
                        Path = 'C:\Program Files\WindowsPowerShell\Modules\sqlserver\21.0.17279\SqlServer.psm1'
                    }
                }

                $sqlPsExpectedModulePath
                {
                    # Can not use $Name because that contain the path to the module manifest.
                    $importModuleResult = @(
                        @{
                            ModuleType = 'Script'
                            Version = '0.0'
                            # Intentionally formatted to correctly mimic a real run.
                            Name = 'Sqlps'
                            Path = $sqlPsLatestModulePath
                        }
                        @{
                            ModuleType = 'Manifest'
                            Version = '1.0'
                            # Intentionally formatted to correctly mimic a real run.
                            Name = 'sqlps'
                            Path = $sqlPsLatestModulePath
                        }
                    )
                }
            }

            return $importModuleResult
        }

        $mockGetModuleSqlServer = {
            # Return an array to test so that the latest version is only imported.
            return @(
                New-Object -TypeName PSObject -Property @{
                    Name = 'SqlServer'
                    Version = [Version] '1.0'
                }

                New-Object -TypeName PSObject -Property @{
                    Name = 'SqlServer'
                    Version = [Version] '2.0'
                }
            )
        }

        $mockGetModuleSqlPs = {
            # Return an array to test so that the latest version is only imported.
            return @(
                New-Object -TypeName PSObject -Property @{
                    Name = 'SQLPS'
                    # This is a path to an older version of SQL PS than $sqlPsLatestModulePath.
                    Path = 'C:\Program Files (x86)\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                }

                New-Object -TypeName PSObject -Property @{
                    Name = 'SQLPS'
                    Path = $sqlPsLatestModulePath
                }
            )
        }

        $mockGetModule_SqlServer_ParameterFilter = {
            $FullyQualifiedName.Name -eq 'SqlServer' -and $ListAvailable -eq $true
        }

        $mockGetModule_SQLPS_ParameterFilter = {
            $FullyQualifiedName.Name -eq 'SQLPS' -and $ListAvailable -eq $true
        }

        Mock -CommandName Set-PSModulePath
        Mock -CommandName Push-Location
        Mock -CommandName Pop-Location
    }


    Context 'When module SqlServer is already loaded into the session' {
        BeforeAll {
            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Get-Module -MockWith {
                return @{
                    Name = 'SqlServer'
                }
            }
        }

        It 'Should use the already loaded module and not call Import-Module' {
            { Import-SQLPSModule } | Should -Not -Throw

            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }

    Context 'When module SQLPS is already loaded into the session' {
        BeforeAll {
            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Get-Module -MockWith {
                return @{
                    Name = 'SQLPS'
                }
            }
        }

        It 'Should use the already loaded module and not call Import-Module' {
            { Import-SQLPSModule } | Should -Not -Throw

            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }

    Context 'When module SqlServer exists, but not loaded into the session' {
        BeforeAll {
            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Get-Module -ParameterFilter {
                <#
                    Should not be called with a login type.

                    Due to issue https://github.com/pester/Pester/issues/1542
                    we cannot use `$PSBoundParameters.ContainsKey('Name') -eq $true`.
                #>
                $null -ne $Name
            }

            Mock -CommandName Get-Module -MockWith $mockGetModuleSqlServer -ParameterFilter $mockGetModule_SqlServer_ParameterFilter

            $mockExpectedModuleNameToImport = 'SqlServer'
        }

        It 'Should import the SqlServer module without throwing' {
            { Import-SQLPSModule } | Should -Not -Throw

            Should -Invoke -CommandName Get-Module -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Push-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Pop-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It
        }
    }

    Context 'When only module SQLPS exists, but not loaded into the session, and using -Force' {
        BeforeAll {
            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Remove-Module
            Mock -CommandName Get-Module -ParameterFilter {
                <#
                    Should not be called with a login type.

                    Due to issue https://github.com/pester/Pester/issues/1542
                    we cannot use `$PSBoundParameters.ContainsKey('Name') -eq $true`.
                #>
                $null -ne $Name
            }

            $mockExpectedModuleNameToImport = $sqlPsExpectedModulePath

            Mock -CommandName Get-Module -MockWith $mockGetModuleSqlPs -ParameterFilter $mockGetModule_SQLPS_ParameterFilter
            Mock -CommandName Get-Module -MockWith {
                return $null
            } -ParameterFilter $mockGetModule_SqlServer_ParameterFilter
        }

        It 'Should import the SqlServer module without throwing' {
            { Import-SQLPSModule -Force } | Should -Not -Throw

            Should -Invoke -CommandName Get-Module -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Module -ParameterFilter $mockGetModule_SQLPS_ParameterFilter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Push-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Pop-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It
        }
    }

    Context 'When neither SqlServer or SQLPS exists' {
        BeforeAll {
            Mock -CommandName Import-Module

            $mockExpectedModuleNameToImport = $sqlPsExpectedModulePath

            Mock -CommandName Get-Module
        }

        It 'Should throw the correct error message' {
            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.PowerShellSqlModuleNotFound
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString
            )

            { Import-SQLPSModule } | Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message

            Should -Invoke -CommandName Get-Module -ParameterFilter $mockGetModule_SqlServer_ParameterFilter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Module -ParameterFilter $mockGetModule_SQLPS_ParameterFilter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Push-Location -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Pop-Location -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }

    Context 'When Import-Module fails to load the module' {
        BeforeAll {
            $mockExpectedModuleNameToImport = 'SqlServer'

            Mock -CommandName Get-Module -MockWith $mockGetModuleSqlServer -ParameterFilter $mockGetModule_SqlServer_ParameterFilter
            Mock -CommandName Import-Module -MockWith {
                throw $errorMessage
            }
        }

        It 'Should throw the correct error message' {
            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.FailedToImportPowerShellSqlModule
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $mockExpectedModuleNameToImport
            )

            { Import-SQLPSModule } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

            Should -Invoke -CommandName Get-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Push-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Pop-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It
        }
    }

    # This is to test the tests (so the mock throws correctly)
    Context 'When mock Import-Module is called with wrong module name' {
        BeforeAll {
            $mockExpectedModuleNameToImport = 'UnknownModule'

            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Get-Module -MockWith $mockGetModuleSqlServer -ParameterFilter $mockGetModule_SqlServer_ParameterFilter
        }

        It 'Should throw the correct error message' {
            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.FailedToImportPowerShellSqlModule
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f 'SqlServer'
            )

            { Import-SQLPSModule } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

            Should -Invoke -CommandName Get-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Push-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Pop-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlServerDsc.Common\Get-SqlInstanceMajorVersion' -Tag 'GetSqlInstanceMajorVersion' {
    BeforeAll {
        $mockSqlMajorVersion = 13
        $mockInstanceName = 'TEST'

        $mockGetItemProperty_MicrosoftSQLServer_InstanceNames_SQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name $mockInstanceName -Value $mockInstance_InstanceId -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_MicrosoftSQLServer_FullInstanceId_Setup = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Version' -Value "$($mockSqlMajorVersion).0.4001.0" -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL = {
            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
        }

        $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup = {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockInstance_InstanceId\Setup"
        }
    }

    BeforeEach {
        Mock -CommandName Get-ItemProperty `
            -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL `
            -MockWith $mockGetItemProperty_MicrosoftSQLServer_InstanceNames_SQL

        Mock -CommandName Get-ItemProperty `
            -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup `
            -MockWith $mockGetItemProperty_MicrosoftSQLServer_FullInstanceId_Setup
    }

    $mockInstance_InstanceId = "MSSQL$($mockSqlMajorVersion).$($mockInstanceName)"

    Context 'When calling Get-SqlInstanceMajorVersion' {
        It 'Should return the correct major SQL version number' {
            $result = Get-SqlInstanceMajorVersion -InstanceName $mockInstanceName
            $result | Should -Be $mockSqlMajorVersion

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup
        }
    }

    Context 'When calling Get-SqlInstanceMajorVersion and nothing is returned' {
        It 'Should throw the correct error' {
            Mock -CommandName Get-ItemProperty `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup `
                -MockWith {
                    return New-Object -TypeName Object
                }

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.SqlServerVersionIsInvalid
            }

            $mockErrorMessage = Get-InvalidResultRecord -Message (
                $mockLocalizedString -f $mockInstanceName
            )

            $mockErrorMessage | Should -Not -BeNullOrEmpty

            { Get-SqlInstanceMajorVersion -InstanceName $mockInstanceName } | Should -Throw -ExpectedMessage $mockErrorMessage

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup
        }
    }
}

Describe 'SqlServerDsc.Common\Get-PrimaryReplicaServerObject' -Tag 'GetPrimaryReplicaServerObject' {
    BeforeEach {
        $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
        $mockServerObject.DomainInstanceName = 'Server1'

        $mockAvailabilityGroup = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
        $mockAvailabilityGroup.PrimaryReplicaServerName = 'Server1'

        $mockConnectSql = {
            param
            (
                [Parameter()]
                [System.String]
                $ServerName,

                [Parameter()]
                [System.String]
                $InstanceName
            )

            $mock = @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'DomainInstanceName' -Value $ServerName -PassThru
                )
            )

            # Type the mock as a server object
            $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

            return $mock
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSql
    }

    Context 'When the supplied server object is the primary replica' {
        It 'Should return the same server object that was supplied' {
            $result = Get-PrimaryReplicaServerObject -ServerObject $mockServerObject -AvailabilityGroup $mockAvailabilityGroup

            $result.DomainInstanceName | Should -Be $mockServerObject.DomainInstanceName
            $result.DomainInstanceName | Should -Be $mockAvailabilityGroup.PrimaryReplicaServerName

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
        }

        It 'Should return the same server object that was supplied when the PrimaryReplicaServerNameProperty is empty' {
            $mockAvailabilityGroup.PrimaryReplicaServerName = ''

            $result = Get-PrimaryReplicaServerObject -ServerObject $mockServerObject -AvailabilityGroup $mockAvailabilityGroup

            $result.DomainInstanceName | Should -Be $mockServerObject.DomainInstanceName
            $result.DomainInstanceName | Should -Not -Be $mockAvailabilityGroup.PrimaryReplicaServerName

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
        }
    }

    Context 'When the supplied server object is not the primary replica' {
        It 'Should the server object of the primary replica' {
            $mockAvailabilityGroup.PrimaryReplicaServerName = 'Server2'

            $result = Get-PrimaryReplicaServerObject -ServerObject $mockServerObject -AvailabilityGroup $mockAvailabilityGroup

            $result.DomainInstanceName | Should -Not -Be $mockServerObject.DomainInstanceName
            $result.DomainInstanceName | Should -Be $mockAvailabilityGroup.PrimaryReplicaServerName

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
        }
    }
}

Describe 'SqlServerDsc.Common\Test-AvailabilityReplicaSeedingModeAutomatic' -Tag 'TestAvailabilityReplicaSeedingModeAutomatic' {
    BeforeAll {
        $mockConnectSql = {
            $mock = @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Version' -Value $mockSqlVersion -PassThru
                )
            )

            # Type the mock as a server object
            $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

            return $mock
        }

        $mockDynamic_SeedingMode = 'Manual'
        $mockInvokeQuery = {
            return @{
                Tables = @{
                    Rows = @{
                        seeding_mode_desc = $mockDynamic_SeedingMode
                    }
                }
            }
        }

        $testAvailabilityReplicaSeedingModeAutomaticParams = @{
            ServerName              = 'Server1'
            InstanceName            = 'MSSQLSERVER'
            AvailabilityGroupName   = 'Group1'
            AvailabilityReplicaName = 'Replica2'
        }
    }

    Context 'When the replica seeding mode is manual' {
        BeforeEach {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSql
            Mock -CommandName Invoke-Query -MockWith $mockInvokeQuery
        }

        It 'Should return $false when the instance version is <_>' -ForEach @(11, 12) {
            $mockSqlVersion = $_

            Test-AvailabilityReplicaSeedingModeAutomatic @testAvailabilityReplicaSeedingModeAutomaticParams | Should -Be $false

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Invoke-Query -Scope It -Times 0 -Exactly
        }

        # Test SQL 2016 and later where Seeding Mode is supported.
        It 'Should return $false when the instance version is <_> and the replica seeding mode is manual' -ForEach @(13, 14, 15) {
            $mockSqlVersion = $_

            Test-AvailabilityReplicaSeedingModeAutomatic @testAvailabilityReplicaSeedingModeAutomaticParams | Should -Be $false

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Invoke-Query -Scope It -Times 1 -Exactly
        }
    }

    Context 'When the replica seeding mode is automatic' {
        BeforeEach {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSql
            Mock -CommandName Invoke-Query -MockWith $mockInvokeQuery
        }

        # Test SQL 2016 and later where Seeding Mode is supported.
        It 'Should return $true when the instance version is <_> and the replica seeding mode is automatic' -ForEach @(13, 14, 15) {
            $mockSqlVersion = $_
            $mockDynamic_SeedingMode = 'Automatic'

            Test-AvailabilityReplicaSeedingModeAutomatic @testAvailabilityReplicaSeedingModeAutomaticParams | Should -Be $true

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Invoke-Query -Scope It -Times 1 -Exactly
        }
    }
}

Describe 'SqlServerDsc.Common\Test-ImpersonatePermissions' -Tag 'TestImpersonatePermissions' {
    BeforeAll {
        $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter = {
            $Permissions -eq @('IMPERSONATE ANY LOGIN')
        }

        $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter = {
            $Permissions -eq @('CONTROL SERVER')
        }

        $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter = {
            $Permissions -eq @('IMPERSONATE')
        }

        $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter = {
            $Permissions -eq @('CONTROL')
        }

        $mockConnectionContextObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
        $mockConnectionContextObject.TrueLogin = 'Login1'

        $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
        $mockServerObject.ComputerNamePhysicalNetBIOS = 'Server1'
        $mockServerObject.ServiceName = 'MSSQLSERVER'
        $mockServerObject.ConnectionContext = $mockConnectionContextObject
    }

    BeforeEach {
        Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -MockWith { $false }
        Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -MockWith { $false }
        Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -MockWith { $false }
        Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -MockWith { $false }
    }

    Context 'When impersonate permissions are present for the login' {
        It 'Should return true when the impersonate any login permissions are present for the login' {
            Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -MockWith { $true }
            Test-ImpersonatePermissions -ServerObject $mockServerObject | Should -Be $true

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -Scope It -Times 1 -Exactly
        }

        It 'Should return true when the control server permissions are present for the login' {
            Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -MockWith { $true }
            Test-ImpersonatePermissions -ServerObject $mockServerObject | Should -Be $true

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -Scope It -Times 1 -Exactly
        }

        It 'Should return true when the impersonate login permissions are present for the login' {
            Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -MockWith { $true }
            Test-ImpersonatePermissions -ServerObject $mockServerObject -SecurableName 'Login1' | Should -Be $true

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -Scope It -Times 1 -Exactly
        }

        It 'Should return true when the control login permissions are present for the login' {
            Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -MockWith { $true }
            Test-ImpersonatePermissions -ServerObject $mockServerObject -SecurableName 'Login1' | Should -Be $true

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -Scope It -Times 1 -Exactly
        }
    }

    Context 'When impersonate permissions are missing for the login' {
        It 'Should return false when the server permissions are missing for the login' {
            Test-ImpersonatePermissions -ServerObject $mockServerObject | Should -Be $false

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -Scope It -Times 0 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -Scope It -Times 0 -Exactly
        }

        It 'Should return false when the login permissions are missing for the login' {
            Test-ImpersonatePermissions -ServerObject $mockServerObject -SecurableName 'Login1' | Should -Be $false

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -Scope It -Times 1 -Exactly
        }
    }
}

Describe 'SqlServerDsc.Common\Connect-SQL' -Tag 'ConnectSql' {
    BeforeAll {
        $mockNewObject_MicrosoftDatabaseEngine = {
            <#
                $ArgumentList[0] will contain the ServiceInstance when calling mock New-Object.
                But since the mock New-Object will also be called without arguments, we first
                have to evaluate if $ArgumentList contains values.
            #>
            if( $ArgumentList.Count -gt 0)
            {
                $serverInstance = $ArgumentList[0]
            }

            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name Status -Value {
                    if ($mockExpectedDatabaseEngineInstance -eq 'MSSQLSERVER')
                    {
                        $mockExpectedServiceInstance = $mockExpectedDatabaseEngineServer
                    }
                    else
                    {
                        $mockExpectedServiceInstance = "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                    }

                    if ( $this.ConnectionContext.ServerInstance -eq $mockExpectedServiceInstance )
                    {
                        return 'Online'
                    }
                    else
                    {
                        return $null
                    }
                } -PassThru |
                Add-Member -MemberType NoteProperty -Name ConnectionContext -Value (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name ServerInstance -Value $serverInstance -PassThru |
                        Add-Member -MemberType NoteProperty -Name LoginSecure -Value $true -PassThru |
                        Add-Member -MemberType NoteProperty -Name Login -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name SecurePassword -Value $null -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectAsUser -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectAsUserPassword -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectAsUserName -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name StatementTimeout -Value 600 -PassThru |
                        Add-Member -MemberType NoteProperty -Name ApplicationName -Value 'SqlServerDsc' -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
                            return $true
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Connect -Value {
                            if ($mockExpectedDatabaseEngineInstance -eq 'MSSQLSERVER')
                            {
                                $mockExpectedServiceInstance = $mockExpectedDatabaseEngineServer
                            }
                            else
                            {
                                $mockExpectedServiceInstance = "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                            }

                            if ($this.serverInstance -ne $mockExpectedServiceInstance)
                            {
                                throw ("Mock method Connect() was expecting ServerInstance to be '{0}', but was '{1}'." -f $mockExpectedServiceInstance, $this.serverInstance )
                            }

                            if ($mockThrowInvalidOperation)
                            {
                                throw 'Unable to connect.'
                            }
                        } -PassThru -Force
                ) -PassThru -Force
        }

        $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Server'
        }

        $mockSqlCredentialUserName = 'TestUserName12345'
        $mockSqlCredentialPassword = 'StrongOne7.'
        $mockSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockSqlCredentialPassword -AsPlainText -Force
        $mockSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockSqlCredentialUserName, $mockSqlCredentialSecurePassword)

        $mockWinCredentialUserName = 'DOMAIN\TestUserName12345'
        $mockWinCredentialPassword = 'StrongerOne7.'
        $mockWinCredentialSecurePassword = ConvertTo-SecureString -String $mockWinCredentialPassword -AsPlainText -Force
        $mockWinCredential = New-Object -TypeName PSCredential -ArgumentList ($mockWinCredentialUserName, $mockWinCredentialSecurePassword)

        $mockWinFqdnCredentialUserName = 'TestUserName12345@domain.local'
        $mockWinFqdnCredentialPassword = 'StrongerOne7.'
        $mockWinFqdnCredentialSecurePassword = ConvertTo-SecureString -String $mockWinFqdnCredentialPassword -AsPlainText -Force
        $mockWinFqdnCredential = New-Object -TypeName PSCredential -ArgumentList ($mockWinFqdnCredentialUserName, $mockWinFqdnCredentialSecurePassword)
    }

    BeforeEach {
        Mock -CommandName Import-SQLPSModule
        Mock -CommandName New-Object `
            -MockWith $mockNewObject_MicrosoftDatabaseEngine `
            -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
    }

    Context 'When connecting to the default instance using integrated Windows Authentication' {
        It 'Should return the correct service instance' {
            $mockExpectedDatabaseEngineServer = 'TestServer'
            $mockExpectedDatabaseEngineInstance = 'MSSQLSERVER'

            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly $mockExpectedDatabaseEngineServer

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting to the default instance using SQL Server Authentication' {
        It 'Should return the correct service instance' {
            $mockExpectedDatabaseEngineServer = 'TestServer'
            $mockExpectedDatabaseEngineInstance = 'MSSQLSERVER'
            $mockExpectedDatabaseEngineLoginSecure = $false

            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -SetupCredential $mockSqlCredential -LoginType 'SqlLogin'
            $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -Be $false
            $databaseEngineServerObject.ConnectionContext.Login | Should -Be $mockSqlCredentialUserName
            $databaseEngineServerObject.ConnectionContext.SecurePassword | Should -Be $mockSqlCredentialSecurePassword
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly $mockExpectedDatabaseEngineServer

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting to the named instance using integrated Windows Authentication' {
        It 'Should return the correct service instance' {
            $mockExpectedDatabaseEngineServer = $env:COMPUTERNAME
            $mockExpectedDatabaseEngineInstance = $mockInstanceName

            $databaseEngineServerObject = Connect-SQL -InstanceName $mockExpectedDatabaseEngineInstance
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting to the named instance using SQL Server Authentication' {
        It 'Should return the correct service instance' {
            $mockExpectedDatabaseEngineServer = $env:COMPUTERNAME
            $mockExpectedDatabaseEngineInstance = $mockInstanceName
            $mockExpectedDatabaseEngineLoginSecure = $false

            $databaseEngineServerObject = Connect-SQL -InstanceName $mockExpectedDatabaseEngineInstance -SetupCredential $mockSqlCredential -LoginType 'SqlLogin'
            $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -Be $false
            $databaseEngineServerObject.ConnectionContext.Login | Should -Be $mockSqlCredentialUserName
            $databaseEngineServerObject.ConnectionContext.SecurePassword | Should -Be $mockSqlCredentialSecurePassword
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting to the named instance using integrated Windows Authentication and different server name' {
        It 'Should return the correct service instance' {
            $mockExpectedDatabaseEngineServer = 'SERVER'
            $mockExpectedDatabaseEngineInstance = $mockInstanceName

            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -InstanceName $mockExpectedDatabaseEngineInstance
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting to the named instance using Windows Authentication impersonation' {
        BeforeAll {
            $mockExpectedDatabaseEngineServer = $env:COMPUTERNAME
            $mockExpectedDatabaseEngineInstance = $mockInstanceName
        }

        Context 'When using the default login type' {
            BeforeAll {
                $testParameters = @{
                    ServerName = $mockExpectedDatabaseEngineServer
                    InstanceName = $mockExpectedDatabaseEngineInstance
                    SetupCredential = $mockWinCredential
                }
            }

            It 'Should return the correct service instance' {
                $databaseEngineServerObject = Connect-SQL @testParameters
                $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -Be $true
                $databaseEngineServerObject.ConnectionContext.ConnectAsUserPassword | Should -BeExactly $mockWinCredential.GetNetworkCredential().Password
                $databaseEngineServerObject.ConnectionContext.ConnectAsUserName | Should -BeExactly $mockWinCredential.UserName
                $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -Be $true
                $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -Be $true

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
            }
        }

        Context 'When using the default login type' {
            Context 'When authenticating using NetBIOS domain' {
                BeforeAll {
                    $testParameters = @{
                        ServerName = $mockExpectedDatabaseEngineServer
                        InstanceName = $mockExpectedDatabaseEngineInstance
                        SetupCredential = $mockWinCredential
                        LoginType = 'WindowsUser'
                    }
                }

                It 'Should return the correct service instance' {
                    $databaseEngineServerObject = Connect-SQL @testParameters
                    $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -Be $true
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUserPassword | Should -BeExactly $mockWinCredential.GetNetworkCredential().Password
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUserName | Should -BeExactly $mockWinCredential.UserName
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -Be $true
                    $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -Be $true

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
                }
            }

            Context 'When authenticating using Fully Qualified Domain Name (FQDN)' {
                BeforeAll {
                    $testParameters = @{
                        ServerName = $mockExpectedDatabaseEngineServer
                        InstanceName = $mockExpectedDatabaseEngineInstance
                        SetupCredential = $mockWinFqdnCredential
                        LoginType = 'WindowsUser'
                    }
                }

                It 'Should return the correct service instance' {
                    $databaseEngineServerObject = Connect-SQL @testParameters
                    $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -Be $true
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUserPassword | Should -BeExactly $mockWinFqdnCredential.GetNetworkCredential().Password
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUserName | Should -BeExactly $mockWinFqdnCredential.UserName
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -Be $true
                    $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -Be $true

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
                }
            }
        }
    }

    Context 'When connecting to the default instance using the correct service instance but does not return a correct Database Engine object' {
        It 'Should throw the correct error' {
            $mockExpectedDatabaseEngineServer = $env:COMPUTERNAME
            $mockExpectedDatabaseEngineInstance = $mockInstanceName

            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftDatabaseEngine `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.FailedToConnectToDatabaseEngineInstance
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $mockExpectedDatabaseEngineServer
            )

            { Connect-SQL } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }
}

Describe 'SqlServerDsc.Common\Split-FullSqlInstanceName' -Tag 'SplitFullSqlInstanceName' {
    Context 'When the "FullSqlInstanceName" parameter is not supplied' {
        It 'Should throw when the "FullSqlInstanceName" parameter is $null' {
            { Split-FullSqlInstanceName -FullSqlInstanceName $null } | Should -Throw
        }

        It 'Should throw when the "FullSqlInstanceName" parameter is an empty string' {
            { Split-FullSqlInstanceName -FullSqlInstanceName '' } | Should -Throw
        }
    }

    Context 'When the "FullSqlInstanceName" parameter is supplied' {
        It 'Should throw when the "FullSqlInstanceName" parameter is "ServerName"' {
            $result = Split-FullSqlInstanceName -FullSqlInstanceName 'ServerName'

            $result.Count | Should -Be 2
            $result.ServerName | Should -Be 'ServerName'
            $result.InstanceName | Should -Be 'MSSQLSERVER'
        }

        It 'Should throw when the "FullSqlInstanceName" parameter is "ServerName\InstanceName"' {
            $result = Split-FullSqlInstanceName -FullSqlInstanceName 'ServerName\InstanceName'

            $result.Count | Should -Be 2
            $result.ServerName | Should -Be 'ServerName'
            $result.InstanceName | Should -Be 'InstanceName'
        }
    }
}

Describe 'SqlServerDsc.Common\Test-ClusterPermissions' -Tag 'TestClusterPermissions' {
    BeforeAll {
        Mock -CommandName Test-LoginEffectivePermissions -MockWith {
            $mockClusterServicePermissionsPresent
        } -ParameterFilter {
            $LoginName -eq $clusterServiceName
        }

        Mock -CommandName Test-LoginEffectivePermissions -MockWith {
            $mockSystemPermissionsPresent
        } -ParameterFilter {
            $LoginName -eq $systemAccountName
        }

        $clusterServiceName = 'NT SERVICE\ClusSvc'
        $systemAccountName= 'NT AUTHORITY\System'
    }

    BeforeEach {
        $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
        $mockServerObject.NetName = 'TestServer'
        $mockServerObject.ServiceName = 'MSSQLSERVER'

        $mockLogins = @{
            $clusterServiceName = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $mockServerObject,$clusterServiceName
            $systemAccountName = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $mockServerObject,$systemAccountName
        }

        $mockServerObject.Logins = $mockLogins

        $mockClusterServicePermissionsPresent = $false
        $mockSystemPermissionsPresent = $false
    }

    Context 'When the cluster does not have permissions to the instance' {
        It "Should throw the correct error when the logins '$($clusterServiceName)' or '$($systemAccountName)' are absent" {
            $mockServerObject.Logins = @{}

            { Test-ClusterPermissions -ServerObject $mockServerObject } | Should -Throw -ExpectedMessage ( "The cluster does not have permissions to manage the Availability Group on '{0}\{1}'. Grant 'Connect SQL', 'Alter Any Availability Group', and 'View Server State' to either '$($clusterServiceName)' or '$($systemAccountName)'. (SQLCOMMON0049)" -f $mockServerObject.NetName,$mockServerObject.ServiceName )

            Should -Invoke -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter {
                $LoginName -eq $clusterServiceName
            }
            Should -Invoke -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter {
                $LoginName -eq $systemAccountName
            }
        }

        It "Should throw the correct error when the logins '$($clusterServiceName)' and '$($systemAccountName)' do not have permissions to manage availability groups" {
            { Test-ClusterPermissions -ServerObject $mockServerObject } | Should -Throw -ExpectedMessage ( "The cluster does not have permissions to manage the Availability Group on '{0}\{1}'. Grant 'Connect SQL', 'Alter Any Availability Group', and 'View Server State' to either '$($clusterServiceName)' or '$($systemAccountName)'. (SQLCOMMON0049)" -f $mockServerObject.NetName,$mockServerObject.ServiceName )

            Should -Invoke -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter {
                $LoginName -eq $clusterServiceName
            }
            Should -Invoke -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter {
                $LoginName -eq $systemAccountName
            }
        }
    }

    Context 'When the cluster has permissions to the instance' {
        It "Should return NullOrEmpty when '$($clusterServiceName)' is present and has the permissions to manage availability groups" {
            $mockClusterServicePermissionsPresent = $true

            Test-ClusterPermissions -ServerObject $mockServerObject | Should -Be $true

            Should -Invoke -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter {
                $LoginName -eq $clusterServiceName
            }
            Should -Invoke -CommandName Test-LoginEffectivePermissions -Scope It -Times 0 -Exactly -ParameterFilter {
                $LoginName -eq $systemAccountName
            }
        }

        It "Should return NullOrEmpty when '$($systemAccountName)' is present and has the permissions to manage availability groups" {
            $mockSystemPermissionsPresent = $true

            Test-ClusterPermissions -ServerObject $mockServerObject | Should -Be $true

            Should -Invoke -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter {
                $LoginName -eq $clusterServiceName
            }
            Should -Invoke -CommandName Test-LoginEffectivePermissions -Scope It -Times 1 -Exactly -ParameterFilter {
                $LoginName -eq $systemAccountName
            }
        }
    }
}

Describe 'SqlServerDsc.Common\Restart-ReportingServicesService' -Tag 'RestartReportingServicesService' {
    BeforeAll {
        $mockGetService = {
            return @{
                Name = $mockDynamicServiceName
                DisplayName = $mockDynamicServiceDisplayName
                DependentServices = @(
                    @{
                        Name = $mockDynamicDependedServiceName
                        Status = 'Running'
                        DependentServices = @()
                    }
                )
            }
        }

    }

    Context 'When restarting a Report Services default instance' {
        BeforeAll {
            $mockServiceName = 'ReportServer'
            $mockDependedServiceName = 'DependentService'

            $mockDynamicServiceName = $mockServiceName
            $mockDynamicDependedServiceName = $mockDependedServiceName
            $mockDynamicServiceDisplayName = 'Reporting Services (MSSQLSERVER)'

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
            Mock -CommandName Get-Service -MockWith $mockGetService
        }

        It 'Should restart the service and dependent service' {
            { Restart-ReportingServicesService -InstanceName 'MSSQLSERVER' } | Should -Not -Throw

            Should -Invoke -CommandName Get-Service -ParameterFilter {
                $Name -eq $mockServiceName
            } -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Stop-Service -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 2
        }
    }

    Context 'When restarting a SQL Server 2017 (or newer) Report Services' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'
            $mockDependedServiceName = 'DependentService'

            $mockDynamicServiceName = $mockServiceName
            $mockDynamicDependedServiceName = $mockDependedServiceName
            $mockDynamicServiceDisplayName = 'Reporting Services'

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
            Mock -CommandName Get-Service -MockWith $mockGetService
        }

        It 'Should restart the service and dependent service' {
            { Restart-ReportingServicesService -InstanceName 'SSRS' } | Should -Not -Throw

            Should -Invoke -CommandName Get-Service -ParameterFilter {
                $Name -eq $mockServiceName
            } -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Stop-Service -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 2
        }
    }

    Context 'When restarting a Report Services named instance' {
        BeforeAll {
            $mockServiceName = 'ReportServer$TEST'
            $mockDependedServiceName = 'DependentService'

            $mockDynamicServiceName = $mockServiceName
            $mockDynamicDependedServiceName = $mockDependedServiceName
            $mockDynamicServiceDisplayName = 'Reporting Services (TEST)'

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
            Mock -CommandName Get-Service -MockWith $mockGetService
        }

        It 'Should restart the service and dependent service' {
            { Restart-ReportingServicesService -InstanceName 'TEST' } | Should -Not -Throw

            Should -Invoke -CommandName Get-Service -ParameterFilter {
                $Name -eq $mockServiceName
            } -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Stop-Service -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 2
        }
    }

    Context 'When restarting a Report Services named instance using a wait timer' {
        BeforeAll {
            $mockServiceName = 'ReportServer$TEST'
            $mockDependedServiceName = 'DependentService'

            $mockDynamicServiceName = $mockServiceName
            $mockDynamicDependedServiceName = $mockDependedServiceName
            $mockDynamicServiceDisplayName = 'Reporting Services (TEST)'

            Mock -CommandName Start-Sleep
            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
            Mock -CommandName Get-Service -MockWith $mockGetService
        }

        It 'Should restart the service and dependent service' {
            { Restart-ReportingServicesService -InstanceName 'TEST' -WaitTime 1 } | Should -Not -Throw

            Should -Invoke -CommandName Get-Service -ParameterFilter {
                $Name -eq $mockServiceName
            } -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Stop-Service -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 2
            Should -Invoke -CommandName Start-Sleep -Scope It -Exactly -Times 1
        }
    }
}

Describe 'SqlServerDsc.Common\Test-ActiveNode' -Tag 'TestActiveNode' {
    BeforeAll {
        $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
    }

    Context 'When function is executed on a standalone instance' {
        BeforeAll {
            $mockServerObject.IsMemberOfWsfcCluster = $false
        }

        It 'Should return $true' {
            Test-ActiveNode -ServerObject $mockServerObject | Should -BeTrue
        }
    }

    Context 'When function is executed on a failover cluster instance (FCI)' {
        BeforeAll {
            $mockServerObject.IsMemberOfWsfcCluster = $true
        }

        It 'Should return <Result> when the node name is <ComputerNamePhysicalNetBIOS>' -ForEach @(
            @{
                ComputerNamePhysicalNetBIOS = $env:COMPUTERNAME
                Result = $true
            },
            @{
                ComputerNamePhysicalNetBIOS = 'AnotherNode'
                Result = $false
            }
        ) {
            $mockServerObject.ComputerNamePhysicalNetBIOS = $ComputerNamePhysicalNetBIOS

            Test-ActiveNode -ServerObject $mockServerObject | Should -Be $Result
        }
    }
}

Describe 'SqlServerDsc.Common\Invoke-SqlScript' -Tag 'InvokeSqlScript' {
    BeforeAll {
        $invokeScriptFileParameters = @{
            ServerInstance = $env:COMPUTERNAME
            InputFile = "set.sql"
        }

        $invokeScriptQueryParameters = @{
            ServerInstance = $env:COMPUTERNAME
            Query = "Test Query"
        }
    }

    Context 'Invoke-SqlScript fails to import SQLPS module' {
        BeforeAll {
            $throwMessage = "Failed to import SQLPS module."

            Mock -CommandName Import-SQLPSModule -MockWith {
                throw $throwMessage
            }
        }

        It 'Should throw the correct error from Import-Module' {
            { Invoke-SqlScript @invokeScriptFileParameters } | Should -Throw -ExpectedMessage $throwMessage
        }
    }

    Context 'Invoke-SqlScript is called with credentials' {
        BeforeAll {
            # Import PowerShell module SqlServer stub cmdlets.
            Import-SQLModuleStub

            $mockPasswordPlain = 'password'
            $mockUsername = 'User'

            $password = ConvertTo-SecureString -String $mockPasswordPlain -AsPlainText -Force
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockUsername, $password

            Mock -CommandName Import-SQLPSModule
            Mock -CommandName Invoke-Sqlcmd -ParameterFilter {
                $Username -eq $mockUsername -and $Password -eq $mockPasswordPlain
            }
        }

        AfterAll {
            # Remove PowerShell module SqlServer stub cmdlets.
            Remove-SqlModuleStub
        }

        It 'Should call Invoke-Sqlcmd with correct File ParameterSet parameters' {
            $invokeScriptFileParameters.Add('Credential', $credential)
            $null = Invoke-SqlScript @invokeScriptFileParameters

            Should -Invoke -CommandName Invoke-Sqlcmd -ParameterFilter {
                $Username -eq $mockUsername -and $Password -eq $mockPasswordPlain
            } -Times 1 -Exactly -Scope It
        }

        It 'Should call Invoke-Sqlcmd with correct Query ParameterSet parameters' {
            $invokeScriptQueryParameters.Add('Credential', $credential)
            $null = Invoke-SqlScript @invokeScriptQueryParameters

            Should -Invoke -CommandName Invoke-Sqlcmd -ParameterFilter {
                $Username -eq $mockUsername -and $Password -eq $mockPasswordPlain
            } -Times 1 -Exactly -Scope It
        }
    }

    Context 'Invoke-SqlScript fails to execute the SQL scripts' {
        BeforeAll {
            # Import PowerShell module SqlServer stub cmdlets.
            Import-SqlModuleStub
        }

        AfterAll {
            # Remove PowerShell module SqlServer stub cmdlets.
            Remove-SqlModuleStub
        }

        BeforeEach {
            $errorMessage = 'Failed to run SQL Script'

            Mock -CommandName Import-SQLPSModule
            Mock -CommandName Invoke-Sqlcmd -MockWith {
                throw $errorMessage
            }
        }

        It 'Should throw the correct error from File ParameterSet Invoke-Sqlcmd' {
            { Invoke-SqlScript @invokeScriptFileParameters } | Should -Throw -ExpectedMessage $errorMessage
        }

        It 'Should throw the correct error from Query ParameterSet Invoke-Sqlcmd' {
            { Invoke-SqlScript @invokeScriptQueryParameters } | Should -Throw -ExpectedMessage $errorMessage
        }
    }
}

Describe 'SqlServerDsc.Common\Get-ServiceAccount' -Tag 'GetServiceAccount' {
    BeforeAll {
        $mockLocalSystemAccountUserName = 'NT AUTHORITY\SYSTEM'
        $mockLocalSystemAccountCredential = New-Object System.Management.Automation.PSCredential $mockLocalSystemAccountUserName, (ConvertTo-SecureString "Password1" -AsPlainText -Force)

        $mockManagedServiceAccountUserName = 'CONTOSO\msa$'
        $mockManagedServiceAccountCredential = New-Object System.Management.Automation.PSCredential $mockManagedServiceAccountUserName, (ConvertTo-SecureString "Password1" -AsPlainText -Force)

        $mockDomainAccountUserName = 'CONTOSO\User1'
        $mockDomainAccountCredential = New-Object System.Management.Automation.PSCredential $mockDomainAccountUserName, (ConvertTo-SecureString "Password1" -AsPlainText -Force)

        $mockLocalServiceAccountUserName = 'NT SERVICE\MyService'
        $mockLocalServiceAccountCredential = New-Object System.Management.Automation.PSCredential $mockLocalServiceAccountUserName, (ConvertTo-SecureString "Password1" -AsPlainText -Force)
    }

    Context 'When getting service account' {
        It 'Should return NT AUTHORITY\SYSTEM' {
            $returnValue = Get-ServiceAccount -ServiceAccount $mockLocalSystemAccountCredential

            $returnValue.UserName | Should -Be $mockLocalSystemAccountUserName
            $returnValue.Password | Should -BeNullOrEmpty
        }

        It 'Should return Domain Account and Password' {
            $returnValue = Get-ServiceAccount -ServiceAccount $mockDomainAccountCredential

            $returnValue.UserName | Should -Be $mockDomainAccountUserName
            $returnValue.Password | Should -Be $mockDomainAccountCredential.GetNetworkCredential().Password
        }

        It 'Should return managed service account' {
            $returnValue = Get-ServiceAccount -ServiceAccount $mockManagedServiceAccountCredential

            $returnValue.UserName | Should -Be $mockManagedServiceAccountUserName
        }

        It 'Should return local service account' {
            $returnValue= Get-ServiceAccount -ServiceAccount $mockLocalServiceAccountCredential

            $returnValue.UserName | Should -Be $mockLocalServiceAccountUserName
            $returnValue.Password | Should -BeNullOrEmpty
        }
    }
}

Describe 'SqlServerDsc.Common\Find-ExceptionByNumber' -Tag 'FindExceptionByNumber' {
    BeforeAll {
        $mockInnerException = New-Object System.Exception "This is a mock inner exception object"
        $mockInnerException | Add-Member -Name 'Number' -Value 2 -MemberType NoteProperty

        $mockException = New-Object System.Exception "This is a mock exception object", $mockInnerException
        $mockException | Add-Member -Name 'Number' -Value 1 -MemberType NoteProperty
    }

    Context 'When searching Exception objects'{
        It 'Should return true for main exception' {
            Find-ExceptionByNumber -ExceptionToSearch $mockException -ErrorNumber 1 | Should -Be $true
        }

        It 'Should return true for inner exception' {
            Find-ExceptionByNumber -ExceptionToSearch $mockException -ErrorNumber 2 | Should -Be $true
        }

        It 'Should return false when message not found' {
            Find-ExceptionByNumber -ExceptionToSearch $mockException -ErrorNumber 3 | Should -Be $false
        }
    }
}

Describe 'SqlServerDsc.Common\Get-ProtocolNameProperties' -Tag 'GetProtocolNameProperties' {
    It "Should return the correct values when the protocol is '<DisplayName>'" -ForEach @(
        @{
            ParameterValue = 'TcpIp'
            DisplayName    = 'TCP/IP'
            Name           = 'Tcp'
        }
        @{
            ParameterValue = 'NamedPipes'
            DisplayName    = 'Named Pipes'
            Name           = 'Np'
        }
        @{
            ParameterValue = 'SharedMemory'
            DisplayName    = 'Shared Memory'
            Name           = 'Sm'
        }
    ) {
        $result = Get-ProtocolNameProperties -ProtocolName $ParameterValue

        $result.DisplayName | Should -Be $DisplayName
        $result.Name | Should -Be  $Name
    }
}

Describe 'SqlServerDsc.Common\Get-ServerProtocolObject' -Tag 'GetServerProtocolObject' {
    BeforeAll {
        $mockInstanceName = 'TestInstance'

        Mock -CommandName New-Object -MockWith {
            return @{
                ServerInstances = @{
                    $mockInstanceName = @{
                        ServerProtocols = @{
                            Tcp = @{
                                IsEnabled           = $true
                                HasMultiIPAddresses = $true
                                ProtocolProperties  = @{
                                    ListenOnAllIPs = $true
                                    KeepAlive      = 30000
                                }
                            }
                        }
                    }
                }
            }
        } -ParameterFilter {
            # Make sure to only mock the creation of the type we want to mock.
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        }
    }

    It 'Should return a ManagedComputer object with the correct values' {
        $mockGetServerProtocolObjectParameters = @{
            ServerName   = 'AnyServer'
            Instance     = $mockInstanceName
            ProtocolName = 'TcpIp'
        }

        $result = Get-ServerProtocolObject @mockGetServerProtocolObjectParameters

        $result.IsEnabled | Should -BeTrue
        $result.HasMultiIPAddresses | Should -BeTrue
        $result.ProtocolProperties.ListenOnAllIPs | Should -BeTrue
        $result.ProtocolProperties.KeepAlive | Should -Be 30000
    }

    Context "When ManagedComputer object has an empty array, 'ServerInstances' value" {
        BeforeAll {
            $mockServerName = 'TestServerName'
            $mockInstanceName = 'TestInstance'

            Mock -CommandName New-Object -MockWith {
                return @{
                    ServerInstances = @()
                }
            } -ParameterFilter {
                # Make sure to only mock the creation of the type we want to mock.
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
            }
        }

        It 'Should throw the correct error message' {
            $mockGetServerProtocolObjectParameters = @{
                ServerName   = $mockServerName
                Instance     = $mockInstanceName
                ProtocolName = 'TcpIp'
            }

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.FailedToObtainServerInstance
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $mockInstanceName, $mockServerName
            )

            $mockErrorRecord.Exception.Message | Should -Not -BeNullOrEmpty

            { Get-ServerProtocolObject @mockGetServerProtocolObjectParameters } | Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
        }
    }
}

Describe 'SqlServerDsc.Common\ConvertTo-ServerInstanceName' -Tag 'ConvertToServerInstanceName' {
    It 'Should return correct service instance for a default instance' {
        $result = ConvertTo-ServerInstanceName -InstanceName 'MSSQLSERVER' -ServerName $env:COMPUTERNAME

        $result | Should -BeExactly $env:COMPUTERNAME
    }

    It 'Should return correct service instance for a name instance' {
        $result = ConvertTo-ServerInstanceName -InstanceName 'MyInstance' -ServerName $env:COMPUTERNAME

        $result | Should -BeExactly ('{0}\{1}' -f $env:COMPUTERNAME, 'MyInstance')
    }
}

Describe 'SqlServerDsc.Common\Get-FilePathMajorVersion' -Tag 'GetFilePathMajorVersion' {
    BeforeAll {
        $mockGetItem_SqlMajorVersion = {
            return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name VersionInfo -Value {
                            return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ProductVersion' -Value '10.0.0000.00000' -PassThru -Force
                        } -PassThru -Force
        }

        Mock -CommandName Get-Item -MockWith $mockGetItem_SqlMajorVersion
    }

    It 'Should return correct version' {
        $result = Get-FilePathMajorVersion -Path 'C:\AnyPath\Setup.exe'

        $result | Should -Be '10'
    }
}

Describe 'Test-FeatureFlag' -Tag 'TestFeatureFlag' {
    Context 'When no feature flags was provided' {
        It 'Should return $false' {
            Test-FeatureFlag -FeatureFlag $null -TestFlag 'MyFlag' | Should -Be $false
        }
    }

    Context 'When feature flags was provided' {
        It 'Should return $true' {
            Test-FeatureFlag -FeatureFlag @('FirstFlag','SecondFlag') -TestFlag 'SecondFlag' | Should -Be $true
        }
    }

    Context 'When feature flags was provided, but missing' {
        It 'Should return $false' {
            Test-FeatureFlag -FeatureFlag @('MyFlag2') -TestFlag 'MyFlag' | Should -Be $false
        }
    }
}
