$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlServerDatabaseMail'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockAccountName = 'MyMail'
        $mockEmailAddress = 'NoReply@company.local'
        $mockReplyToAddress = $mockEmailAddress
        $mockProfileName = 'MyMailProfile'
        $mockMailServerName = 'mail.company.local'
        $mockDisplayName = $mockMailServerName
        $mockDescription = 'My mail description'
        $mockTcpPort = 25

        $mockDatabaseMailDisabledConfigValue = 0
        $mockDatabaseMailEnabledConfigValue = 1

        $mockAgentMailType = 'DatabaseMail'

        $mockLoggingLevelNormal = 'Normal'
        $mockLoggingLevelNormalValue = '1'
        $mockLoggingLevelExtended = 'Extended'
        $mockLoggingLevelExtendedValue = '2'
        $mockLoggingLevelVerbose = 'Verbose'
        $mockLoggingLevelVerboseValue = '3'

        $mockMissingAccountName = 'MissingAccount'

        # Default parameters that are used for the It-blocks.
        $mockDefaultParameters = @{
            InstanceName   = $mockInstanceName
            ServerName     = $mockServerName
            AccountName    = $mockAccountName
            EmailAddress   = $mockEmailAddress
            MailServerName = $mockMailServerName
            ProfileName    = $mockProfileName
        }

        # Contains mocked object that is used between several mocks.
        $mailAccountObject = {
            New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAccountName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $mockDisplayName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'EmailAddress' -Value $mockEmailAddress -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ReplyToAddress' -Value $mockReplyToAddress -PassThru |
                Add-Member -MemberType NoteProperty -Name 'Description' -Value $mockDynamicDescription -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'MailServers' -Value {
                    return @(
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockMailServerName -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Port' -Value $mockTcpPort -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Rename' -Value {
                                $script:MailServerRenameMethodCallCount += 1
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                $script:MailServerAlterMethodCallCount += 1
                            } -PassThru -Force
                    )
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Create' -Value {
                    $script:MailAccountCreateMethodCallCount += 1
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                    $script:MailAccountAlterMethodCallCount += 1
                } -PassThru -Force
        }

        $mockNewObject_MailAccount = {
            # This executes the variable that contains the mock
            return @( & $mailAccountObject )
        }

        $mailProfileObject = {
            return @(
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockProfileName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Description' -Value $mockProfileName -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Create' -Value {
                        $script:MailProfileCreateMethodCallCount += 1
                    } -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                        $script:MailProfileAlterMethodCallCount += 1
                    } -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'AddPrincipal' -Value {
                        $script:MailProfileAddPrincipalMethodCallCount += 1
                    } -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'AddAccount' -Value {
                        $script:MailProfileAddAccountMethodCallCount += 1
                    } -PassThru -Force
                )
        }

        $mockNewObject_MailProfile = {
            # This executes the variable that contains the mock
            return @( & $mailProfileObject )
        }

        $mockConnectSQL = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name 'Configuration' -Value {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name 'DatabaseMailEnabled' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'RunValue' -Value $mockDynamicDatabaseMailEnabledRunValue -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ConfigValue' -Value $mockDatabaseMailDisabledConfigValue -PassThru -Force
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                            $script:ConfigurationAlterMethodCallCount += 1
                        } -PassThru -Force
                } -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'Mail' -Value {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name 'Accounts' -Value {
                            # This executes the variable that contains the mock
                            return @( & $mailAccountObject )
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'ConfigurationValues' -Value {
                            return @{
                                'LoggingLevel' = New-Object -TypeName Object |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicLoggingLevelValue -PassThru |
                                                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                                    $script:LoggingLevelAlterMethodCallCount += 1
                                                } -PassThru -Force
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Profiles' -Value {
                            # This executes the variable that contains the mock
                            return @( & $mailProfileObject )
                        } -PassThru -Force
                } -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'JobServer' -Value {
                    return New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'AgentMailType' -Value $mockAgentMailType -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'DatabaseMailProfile' -Value $mockProfileName -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                $script:JobServerAlterMethodCallCount += 1
                            } -PassThru -Force
                } -PassThru -Force
        }

        Describe "MSFT_SqlServerDatabaseMail\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
                $mockDynamicLoggingLevelValue = $mockLoggingLevelExtendedValue
                $mockDynamicDescription = $mockDescription
            }

            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $getTargetResourceParameters = $mockDefaultParameters.Clone()
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    BeforeEach {
                        $getTargetResourceParameters['AccountName'] = $mockMissingAccountName
                    }

                    It 'Should return the state as absent' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Ensure | Should -Be 'Absent'

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @getTargetResourceParameters
                        $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should return $null for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.AccountName | Should -BeNullOrEmpty
                        $getTargetResourceResult.EmailAddress | Should -BeNullOrEmpty
                        $getTargetResourceResult.MailServerName | Should -BeNullOrEmpty
                        $getTargetResourceResult.LoggingLevel | Should -BeNullOrEmpty
                        $getTargetResourceResult.ProfileName | Should -BeNullOrEmpty
                        $getTargetResourceResult.DisplayName | Should -BeNullOrEmpty
                        $getTargetResourceResult.ReplyToAddress | Should -BeNullOrEmpty
                        $getTargetResourceResult.Description | Should -BeNullOrEmpty
                        $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is present' {
                    It 'Should return the state as present' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Ensure | Should -Be 'Present'

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @getTargetResourceParameters
                        $result.ServerName | Should -Be $getTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the correct values for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.AccountName | Should -Be $mockAccountName
                        $getTargetResourceResult.EmailAddress | Should -Be $mockEmailAddress
                        $getTargetResourceResult.MailServerName | Should -Be $mockMailServerName
                        $getTargetResourceResult.LoggingLevel | Should -Be $mockLoggingLevelExtended
                        $getTargetResourceResult.ProfileName | Should -Be $mockProfileName
                        $getTargetResourceResult.DisplayName | Should -Be $mockDisplayName
                        $getTargetResourceResult.ReplyToAddress | Should -Be $mockReplyToAddress
                        $getTargetResourceResult.Description | Should -Be $mockDescription
                        $getTargetResourceResult.TcpPort | Should -Be $mockTcpPort

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the current logging level is ''Normal''' {
                    BeforeAll {
                        $mockDynamicLoggingLevelValue = $mockLoggingLevelNormalValue
                    }

                    It 'Should return the correct value for property LoggingLevel' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.LoggingLevel | Should -Be $mockLoggingLevelNormal
                    }
                }

                Context 'When the current logging level is ''Extended''' {
                    BeforeAll {
                        $mockDynamicLoggingLevelValue = $mockLoggingLevelExtendedValue
                    }

                    It 'Should return the correct value for property LoggingLevel' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.LoggingLevel | Should -Be $mockLoggingLevelExtended
                    }
                }

                Context 'When the current logging level is ''Verbose''' {
                    BeforeAll {
                        $mockDynamicLoggingLevelValue = $mockLoggingLevelVerboseValue
                    }

                    It 'Should return the correct value for property LoggingLevel' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.LoggingLevel | Should -Be $mockLoggingLevelVerbose
                    }
                }

                Context 'When the current description is returned as an empty string' {
                    BeforeAll {
                        $mockDynamicDescription = ''
                    }

                    It 'Should return $null for property Description' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Description | Should -BeNullOrEmpty
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerDatabaseMail\Test-TargetResource" -Tag 'Test' {
            BeforeAll {
                $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
                $mockDynamicLoggingLevelValue = $mockLoggingLevelExtendedValue
                $mockDynamicDescription = $mockDescription
            }

            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $testTargetResourceParameters = $mockDefaultParameters.Clone()
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                        $testTargetResourceParameters['AccountName'] = $mockMissingAccountName
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is present' {
                    BeforeEach {
                        $testTargetResourceParameters['DisplayName'] = $mockDisplayName
                        $testTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
                        $testTargetResourceParameters['Description'] = $mockDescription
                        $testTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
                        $testTargetResourceParameters['TcpPort'] = $mockTcpPort
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    BeforeEach {
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration should be present' {
                    $defaultTestCase = @{
                        AccountName    = $mockAccountName
                        EmailAddress   = $mockEmailAddress
                        MailServerName = $mockMailServerName
                        ProfileName    = $mockProfileName
                        DisplayName    = $mockDisplayName
                        ReplyToAddress = $mockReplyToAddress
                        Description    = $mockDescription
                        LoggingLevel   = $mockLoggingLevelExtended
                        TcpPort        = $mockTcpPort
                    }

                    $testCaseAccountNameIsMissing = $defaultTestCase.Clone()
                    $testCaseAccountNameIsMissing['TestName'] = 'AccountName is missing'
                    $testCaseAccountNameIsMissing['AccountName'] = 'MissingAccountName'

                    $testCaseEmailAddressIsWrong = $defaultTestCase.Clone()
                    $testCaseEmailAddressIsWrong['TestName'] = 'EmailAddress is wrong'
                    $testCaseEmailAddressIsWrong['EmailAddress'] = 'wrong@email.address'

                    $testCaseMailServerNameIsWrong = $defaultTestCase.Clone()
                    $testCaseMailServerNameIsWrong['TestName'] = 'MailServerName is wrong'
                    $testCaseMailServerNameIsWrong['MailServerName'] = 'smtp.contoso.com'

                    $testCaseProfileNameIsWrong = $defaultTestCase.Clone()
                    $testCaseProfileNameIsWrong['TestName'] = 'ProfileName is wrong'
                    $testCaseProfileNameIsWrong['ProfileName'] = 'NewProfile'

                    $testCaseDisplayNameIsWrong = $defaultTestCase.Clone()
                    $testCaseDisplayNameIsWrong['TestName'] = 'DisplayName is wrong'
                    $testCaseDisplayNameIsWrong['DisplayName'] = 'New display name'

                    $testCaseReplyToAddressIsWrong = $defaultTestCase.Clone()
                    $testCaseReplyToAddressIsWrong['TestName'] = 'ReplyToAddress is wrong'
                    $testCaseReplyToAddressIsWrong['ReplyToAddress'] = 'new-reply@email.address'

                    $testCaseDescriptionIsWrong = $defaultTestCase.Clone()
                    $testCaseDescriptionIsWrong['TestName'] = 'Description is wrong'
                    $testCaseDescriptionIsWrong['Description'] = 'New description'

                    $testCaseLoggingLevelIsWrong = $defaultTestCase.Clone()
                    $testCaseLoggingLevelIsWrong['TestName'] = 'LoggingLevel is wrong'
                    $testCaseLoggingLevelIsWrong['LoggingLevel'] = $mockLoggingLevelNormal

                    $testCaseTcpPortIsWrong = $defaultTestCase.Clone()
                    $testCaseTcpPortIsWrong['TestName'] = 'TcpPort is wrong'
                    $testCaseTcpPortIsWrong['TcpPort'] = 2525

                    $testCases = @(
                        $testCaseAccountNameIsMissing
                        $testCaseEmailAddressIsWrong
                        $testCaseMailServerNameIsWrong
                        $testCaseProfileNameIsWrong
                        $testCaseDisplayNameIsWrong
                        $testCaseReplyToAddressIsWrong
                        $testCaseDescriptionIsWrong
                        $testCaseLoggingLevelIsWrong
                        $testCaseTcpPortIsWrong
                    )

                    It 'Should return the state as $false when <TestName>' -TestCases $testCases {
                        param
                        (
                            $AccountName,
                            $EmailAddress,
                            $MailServerName,
                            $ProfileName,
                            $DisplayName,
                            $ReplyToAddress,
                            $Description,
                            $LoggingLevel,
                            $TcpPort
                        )

                        $testTargetResourceParameters['AccountName'] = $AccountName
                        $testTargetResourceParameters['EmailAddress'] = $EmailAddress
                        $testTargetResourceParameters['MailServerName'] = $MailServerName
                        $testTargetResourceParameters['ProfileName'] = $ProfileName
                        $testTargetResourceParameters['DisplayName'] = $DisplayName
                        $testTargetResourceParameters['ReplyToAddress'] = $ReplyToAddress
                        $testTargetResourceParameters['Description'] = $Description
                        $testTargetResourceParameters['LoggingLevel'] = $LoggingLevel
                        $testTargetResourceParameters['TcpPort'] = $TcpPort

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerDatabaseMail\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
                $mockDynamicLoggingLevelValue = $mockLoggingLevelExtendedValue
                $mockDynamicDescription = $mockDescription
            }

            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObject_MailAccount -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.SMO.Mail.MailAccount'
                } -Verifiable

                Mock -CommandName New-Object -MockWith $mockNewObject_MailProfile -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.SMO.Mail.MailProfile'
                } -Verifiable

                $setTargetResourceParameters = $mockDefaultParameters.Clone()

                $script:ConfigurationAlterMethodCallCount = 0
                $script:MailAccountCreateMethodCallCount  = 0
                $script:MailServerRenameMethodCallCount = 0
                $script:MailServerAlterMethodCallCount = 0
                $script:MailAccountAlterMethodCallCount = 0
                $script:MailProfileCreateMethodCallCount = 0
                $script:MailProfileAlterMethodCallCount = 0
                $script:MailProfileAddPrincipalMethodCallCount = 0
                $script:MailProfileAddAccountMethodCallCount = 0
                $script:JobServerAlterMethodCallCount = 0
                $script:LoggingLevelAlterMethodCallCount = 0

                $mockDynamicExpectedAccountName = $mockMissingAccountName
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    BeforeEach {
                        $setTargetResourceParameters['Ensure'] = 'Absent'
                        $setTargetResourceParameters['AccountName'] = $mockMissingAccountName
                    }

                    It 'Should call the correct methods without throwing' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $script:ConfigurationAlterMethodCallCount | Should -Be 0

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is present' {
                    BeforeEach {
                        $setTargetResourceParameters['DisplayName'] = $mockDisplayName
                        $setTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
                        $setTargetResourceParameters['Description'] = $mockDescription
                        $setTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
                        $setTargetResourceParameters['TcpPort'] = $mockTcpPort
                    }

                    It 'Should call the correct methods without throwing' {
                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                        $script:ConfigurationAlterMethodCallCount | Should -Be 0

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                # Context 'When the configuration should be absent' {
                #     BeforeEach {
                #         $setTargetResourceParameters['Ensure'] = 'Absent'
                #     }

                #     It 'Should return the state as $false' {
                #         { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                #         $script:ConfigurationAlterMethodCallCount | Should -Be 1
                #     }
                # }

                Context 'When the configuration should be present' {
                    Context 'When database mail XPs is enabled but fails evaluation' {
                        $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailDisabledConfigValue

                        <#
                            Note: This test also tests the code that enables
                            Database Mail XPs.
                            Because of how the current code is written it is not
                            possible to verify that the code works without it
                            throwing (can't mock the property
                            $sqlServerObject.Configuration.DatabaseMailEnabled.RunValue
                            to be both 0 before running and then changing the
                            mock to 1 during testing to pass evaluation)
                        #>
                        It 'Should throw the correct error message' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Throw 'Database Mail XPs are not enabled.'

                            $script:ConfigurationAlterMethodCallCount | Should -Be 1

                            Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When account name is missing' {
                        #$mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailDisabledConfigValue

                        It 'Should call the correct methods without throwing' {
                            $setTargetResourceParameters['AccountName'] = $mockMissingAccountName
                            $setTargetResourceParameters['DisplayName'] = $mockDisplayName
                            $setTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
                            $setTargetResourceParameters['Description'] = $mockDescription
                            $setTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
                            $setTargetResourceParameters['TcpPort'] = $mockTcpPort

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                            $script:ConfigurationAlterMethodCallCount | Should -Be 0
                            $script:MailAccountCreateMethodCallCount | Should -Be 1
                            $script:MailServerRenameMethodCallCount | Should -Be 1
                            $script:MailServerAlterMethodCallCount | Should -Be 1
                            $script:MailAccountAlterMethodCallCount | Should -Be 0

                            Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When properties are not in desired state' {
                        $defaultTestCase = @{
                            AccountName    = $mockAccountName
                            EmailAddress   = $mockEmailAddress
                            MailServerName = $mockMailServerName
                            ProfileName    = $mockProfileName
                            DisplayName    = $mockDisplayName
                            ReplyToAddress = $mockReplyToAddress
                            Description    = $mockDescription
                            LoggingLevel   = $mockLoggingLevelExtended
                            TcpPort        = $mockTcpPort
                        }

                        $testCaseEmailAddressIsWrong = $defaultTestCase.Clone()
                        $testCaseEmailAddressIsWrong['TestName'] = 'EmailAddress is wrong'
                        $testCaseEmailAddressIsWrong['EmailAddress'] = 'wrong@email.address'

                        $testCaseMailServerNameIsWrong = $defaultTestCase.Clone()
                        $testCaseMailServerNameIsWrong['TestName'] = 'MailServerName is wrong'
                        $testCaseMailServerNameIsWrong['MailServerName'] = 'smtp.contoso.com'

                        $testCaseProfileNameIsWrong = $defaultTestCase.Clone()
                        $testCaseProfileNameIsWrong['TestName'] = 'ProfileName is wrong'
                        $testCaseProfileNameIsWrong['ProfileName'] = 'NewProfile'

                        $testCaseDisplayNameIsWrong = $defaultTestCase.Clone()
                        $testCaseDisplayNameIsWrong['TestName'] = 'DisplayName is wrong'
                        $testCaseDisplayNameIsWrong['DisplayName'] = 'New display name'

                        $testCaseReplyToAddressIsWrong = $defaultTestCase.Clone()
                        $testCaseReplyToAddressIsWrong['TestName'] = 'ReplyToAddress is wrong'
                        $testCaseReplyToAddressIsWrong['ReplyToAddress'] = 'new-reply@email.address'

                        $testCaseDescriptionIsWrong = $defaultTestCase.Clone()
                        $testCaseDescriptionIsWrong['TestName'] = 'Description is wrong'
                        $testCaseDescriptionIsWrong['Description'] = 'New description'

                        $testCaseLoggingLevelIsWrong_Normal = $defaultTestCase.Clone()
                        $testCaseLoggingLevelIsWrong_Normal['TestName'] = 'LoggingLevel is wrong, should be ''Normal'''
                        $testCaseLoggingLevelIsWrong_Normal['LoggingLevel'] = $mockLoggingLevelNormal

                        $testCaseLoggingLevelIsWrong_Verbose = $defaultTestCase.Clone()
                        $testCaseLoggingLevelIsWrong_Verbose['TestName'] = 'LoggingLevel is wrong, should be ''Verbose'''
                        $testCaseLoggingLevelIsWrong_Verbose['LoggingLevel'] = $mockLoggingLevelVerbose

                        $testCaseTcpPortIsWrong = $defaultTestCase.Clone()
                        $testCaseTcpPortIsWrong['TestName'] = 'TcpPort is wrong'
                        $testCaseTcpPortIsWrong['TcpPort'] = 2525

                        $testCases = @(
                            $testCaseEmailAddressIsWrong
                            $testCaseMailServerNameIsWrong
                            $testCaseProfileNameIsWrong
                            $testCaseDisplayNameIsWrong
                            $testCaseReplyToAddressIsWrong
                            $testCaseDescriptionIsWrong
                            $testCaseLoggingLevelIsWrong_Normal
                            $testCaseLoggingLevelIsWrong_Verbose
                            $testCaseTcpPortIsWrong
                        )

                        It 'Should return the state as $false when <TestName>' -TestCases $testCases {
                            param
                            (
                                $TestName,
                                $AccountName,
                                $EmailAddress,
                                $MailServerName,
                                $ProfileName,
                                $DisplayName,
                                $ReplyToAddress,
                                $Description,
                                $LoggingLevel,
                                $TcpPort
                            )

                            $setTargetResourceParameters['AccountName'] = $AccountName
                            $setTargetResourceParameters['EmailAddress'] = $EmailAddress
                            $setTargetResourceParameters['MailServerName'] = $MailServerName
                            $setTargetResourceParameters['ProfileName'] = $ProfileName
                            $setTargetResourceParameters['DisplayName'] = $DisplayName
                            $setTargetResourceParameters['ReplyToAddress'] = $ReplyToAddress
                            $setTargetResourceParameters['Description'] = $Description
                            $setTargetResourceParameters['LoggingLevel'] = $LoggingLevel
                            $setTargetResourceParameters['TcpPort'] = $TcpPort

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:ConfigurationAlterMethodCallCount | Should -Be 0
                            $script:MailAccountCreateMethodCallCount | Should -Be 0

                            if ($TestName -like '*MailServerName*')
                            {
                                $script:MailServerRenameMethodCallCount | Should -Be 1
                                $script:MailServerAlterMethodCallCount | Should -Be 1
                                $script:MailAccountAlterMethodCallCount | Should -Be 0
                                $script:MailProfileCreateMethodCallCount | Should -Be 0
                                $script:MailProfileAlterMethodCallCount | Should -Be 0
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                                $script:JobServerAlterMethodCallCount | Should -Be 0
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                            }
                            elseif ($TestName -like '*TcpPort*') {
                                $script:MailServerRenameMethodCallCount | Should -Be 0
                                $script:MailServerAlterMethodCallCount | Should -Be 1
                                $script:MailAccountAlterMethodCallCount | Should -Be 0
                                $script:MailProfileCreateMethodCallCount | Should -Be 0
                                $script:MailProfileAlterMethodCallCount | Should -Be 0
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                                $script:JobServerAlterMethodCallCount | Should -Be 0
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                            }
                            elseif ($TestName -like '*ProfileName*') {
                                $script:MailServerRenameMethodCallCount | Should -Be 0
                                $script:MailServerAlterMethodCallCount | Should -Be 0
                                $script:MailAccountAlterMethodCallCount | Should -Be 0
                                $script:MailProfileCreateMethodCallCount | Should -Be 1
                                $script:MailProfileAlterMethodCallCount | Should -Be 1
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 1
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 1
                                $script:JobServerAlterMethodCallCount | Should -Be 1
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                            }
                            elseif ($TestName -like '*LoggingLevel*') {
                                $script:MailServerRenameMethodCallCount | Should -Be 0
                                $script:MailServerAlterMethodCallCount | Should -Be 0
                                $script:MailAccountAlterMethodCallCount | Should -Be 0
                                $script:MailProfileCreateMethodCallCount | Should -Be 0
                                $script:MailProfileAlterMethodCallCount | Should -Be 0
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                                $script:JobServerAlterMethodCallCount | Should -Be 0
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 1
                            }
                            else
                            {
                                $script:MailServerRenameMethodCallCount | Should -Be 0
                                $script:MailServerAlterMethodCallCount | Should -Be 0
                                $script:MailAccountAlterMethodCallCount | Should -Be 1
                                $script:MailProfileCreateMethodCallCount | Should -Be 0
                                $script:MailProfileAlterMethodCallCount | Should -Be 0
                                $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                                $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                                $script:JobServerAlterMethodCallCount | Should -Be 0
                                $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                            }

                            Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                        }
                    }
                }
            }

            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}

