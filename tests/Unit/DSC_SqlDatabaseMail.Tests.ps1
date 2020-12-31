<#
    .SYNOPSIS
        Unit test for DSC_SqlDatabaseMail DSC resource.

#>
BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlDatabaseMail'

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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'DSC_SqlDatabaseMail\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
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
                            Add-Member -MemberType NoteProperty -Name 'Port' -Value $mockTcpPort -PassThru -Force
                        )
                    } -PassThru -Force
        }

        $mailProfileObject = {
            return @(
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockProfileName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Description' -Value $mockProfileName -PassThru -Force
            )
        }

        $mockConnectSQL = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name 'Configuration' -Value {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name 'DatabaseMailEnabled' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'RunValue' -Value $mockDynamicDatabaseMailEnabledRunValue -PassThru -Force
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
                                            Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicLoggingLevelValue -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'Profiles' -Value {
                                        # This executes the variable that contains the mock
                                        return @( & $mailProfileObject )
                                    } -PassThru -Force
                                } -PassThru |
                                Add-Member -MemberType ScriptProperty -Name 'JobServer' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'AgentMailType' -Value 'DatabaseMail' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'DatabaseMailProfile' -Value $mockProfileName -PassThru -Force
                                    } -PassThru -Force
        }

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the configuration is absent' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $inModuleScopeParameters = @{
                    MockEmailAddress   = $mockEmailAddress
                    MockMailServerName = $mockMailServerName
                    MockProfileName    = $mockProfileName
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockEmailAddress,
                        $MockMailServerName,
                        $MockProfileName
                    )

                    $script:mockGetTargetResourceParameters = $mockDefaultParameters.Clone()
                    $script:mockGetTargetResourceParameters.AccountName = 'MissingAccount'
                    $script:mockGetTargetResourceParameters.EmailAddress = $MockEmailAddress
                    $script:mockGetTargetResourceParameters.MailServerName = $MockMailServerName
                    $script:mockGetTargetResourceParameters.ProfileName = $MockProfileName
                }
            }

            It 'Should return the state as absent' {
                InModuleScope -ScriptBlock {
                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Ensure | Should -Be 'Absent'
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return $null for the rest of the properties' {
                InModuleScope -ScriptBlock {
                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.AccountName | Should -BeNullOrEmpty
                    $getTargetResourceResult.EmailAddress | Should -BeNullOrEmpty
                    $getTargetResourceResult.MailServerName | Should -BeNullOrEmpty
                    $getTargetResourceResult.LoggingLevel | Should -BeNullOrEmpty
                    $getTargetResourceResult.ProfileName | Should -BeNullOrEmpty
                    $getTargetResourceResult.DisplayName | Should -BeNullOrEmpty
                    $getTargetResourceResult.ReplyToAddress | Should -BeNullOrEmpty
                    $getTargetResourceResult.Description | Should -BeNullOrEmpty
                    $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should call all verifiable mocks' {
                Should -InvokeVerifiable
            }
        }

        Context 'When the configuration is present' {
            BeforeAll {
                $mockDynamicLoggingLevelValue = $mockLoggingLevelNormalValue
                $mockDynamicDescription = $mockDescription
                $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $inModuleScopeParameters = @{
                    MockAccountName    = $mockAccountName
                    MockEmailAddress   = $mockEmailAddress
                    MockMailServerName = $mockMailServerName
                    MockProfileName    = $mockProfileName
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockAccountName,
                        $MockEmailAddress,
                        $MockMailServerName,
                        $MockProfileName
                    )

                    $script:mockGetTargetResourceParameters = $mockDefaultParameters.Clone()
                    $script:mockGetTargetResourceParameters.AccountName = $MockAccountName
                    $script:mockGetTargetResourceParameters.EmailAddress = $MockEmailAddress
                    $script:mockGetTargetResourceParameters.MailServerName = $MockMailServerName
                    $script:mockGetTargetResourceParameters.ProfileName = $MockProfileName
                }
            }

            It 'Should return the state as present' {
                InModuleScope -ScriptBlock {
                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Ensure | Should -Be 'Present'
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the correct values for the rest of the properties' {
                $inModuleScopeParameters = @{
                    MockAccountName    = $mockAccountName
                    MockEmailAddress   = $mockEmailAddress
                    MockMailServerName = $mockMailServerName
                    MockProfileName    = $mockProfileName
                    MockLoggingLevel   = $mockLoggingLevelNormal
                    MockDisplayName    = $mockDisplayName
                    MockReplyToAddress = $mockReplyToAddress
                    MockDescription    = $mockDescription
                    MockTcpPort        = $mockTcpPort
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockAccountName,
                        $MockEmailAddress,
                        $MockMailServerName,
                        $MockProfileName,
                        $MockLoggingLevel,
                        $MockDisplayName,
                        $MockReplyToAddress,
                        $MockDescription,
                        $MockTcpPort
                    )

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.AccountName | Should -Be $MockAccountName
                    $getTargetResourceResult.EmailAddress | Should -Be $MockEmailAddress
                    $getTargetResourceResult.MailServerName | Should -Be $MockMailServerName
                    $getTargetResourceResult.LoggingLevel | Should -Be $MockLoggingLevel
                    $getTargetResourceResult.ProfileName | Should -Be $MockProfileName
                    $getTargetResourceResult.DisplayName | Should -Be $MockDisplayName
                    $getTargetResourceResult.ReplyToAddress | Should -Be $MockReplyToAddress
                    $getTargetResourceResult.Description | Should -Be $MockDescription
                    $getTargetResourceResult.TcpPort | Should -Be $MockTcpPort
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the current logging level is <LoggingLevel>' -ForEach @(
            @{
                LoggingLevel      = 'Normal'
                LoggingLevelValue = '1'
            },
            @{
                LoggingLevel      = 'Extended'
                LoggingLevelValue = '2'
            }
            @{
                LoggingLevel      = 'Verbose'
                LoggingLevelValue = '3'
            }
        ) {
            BeforeAll {
                $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
                $mockDynamicLoggingLevelValue = $LoggingLevelValue

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $inModuleScopeParameters = @{
                    MockAccountName    = $mockAccountName
                    MockEmailAddress   = $mockEmailAddress
                    MockMailServerName = $mockMailServerName
                    MockProfileName    = $mockProfileName
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockAccountName,
                        $MockEmailAddress,
                        $MockMailServerName,
                        $MockProfileName
                    )

                    $script:mockGetTargetResourceParameters = $mockDefaultParameters.Clone()
                    $script:mockGetTargetResourceParameters.AccountName = $MockAccountName
                    $script:mockGetTargetResourceParameters.EmailAddress = $MockEmailAddress
                    $script:mockGetTargetResourceParameters.MailServerName = $MockMailServerName
                    $script:mockGetTargetResourceParameters.ProfileName = $MockProfileName
                }
            }

            It 'Should return the correct value for property LoggingLevel' {
                $inModuleScopeParameters = @{
                    MockLoggingLevel = $LoggingLevel
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockLoggingLevel
                    )

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.LoggingLevel | Should -Be $MockLoggingLevel
                }
            }
        }

        Context 'When the current description is returned as an empty string' {
            BeforeAll {
                $mockDynamicDescription = ''

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            It 'Should return $null for property Description' {
                InModuleScope -ScriptBlock {
                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Description | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When the Database Mail feature is disabled' {
            BeforeAll {
                $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailDisabledConfigValue

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Ensure | Should -Be 'Absent'
                    $getTargetResourceResult.AccountName | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'DSC_SqlDatabaseMail\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $mockAccountName = 'MyMail'
        $mockEmailAddress = 'NoReply@company.local'
        $mockReplyToAddress = $mockEmailAddress
        $mockProfileName = 'MyMailProfile'
        $mockMailServerName = 'mail.company.local'
        $mockDisplayName = $mockMailServerName
        $mockDescription = 'My mail description'
        $mockTcpPort = 25
        $mockLoggingLevel = 'Normal'

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName   = 'MSSQLSERVER'
                ServerName     = 'localhost'
                AccountName    = 'MyMail'
                EmailAddress   = 'NoReply@company.local'
                MailServerName = 'mail.company.local'
                ProfileName    = 'MyMailProfile'
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the configuration is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return the state as $true' {
                InModuleScope -ScriptBlock {
                    $testTargetResourceParameters = $script:mockDefaultParameters.Clone()
                    $testTargetResourceParameters.Ensure = 'Absent'
                    $testTargetResourceParameters.AccountName = 'MissingAccount'

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters

                    $testTargetResourceResult | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the configuration is present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure         = 'Present'
                        ServerName     = $mockServerName
                        InstanceName   = $mockInstanceName
                        AccountName    = $mockAccountName
                        EmailAddress   = $mockEmailAddress
                        MailServerName = $mockMailServerName
                        LoggingLevel   = $mockLoggingLevel
                        ProfileName    = $mockProfileName
                        DisplayName    = $mockDisplayName
                        ReplyToAddress = $mockReplyToAddress
                        Description    = $mockDescription
                        TcpPort        = $mockTcpPort
                    }
                }
            }

            It 'Should return the state as $true' {
                $inModuleScopeParameters = @{
                    MockLoggingLevel   = $mockLoggingLevel
                    MockDisplayName    = $mockDisplayName
                    MockReplyToAddress = $mockReplyToAddress
                    MockDescription    = $mockDescription
                    MockTcpPort        = $mockTcpPort
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockLoggingLevel,
                        $MockDisplayName,
                        $MockReplyToAddress,
                        $MockDescription,
                        $MockTcpPort
                    )

                    $testTargetResourceParameters = $script:mockDefaultParameters.Clone()
                    $testTargetResourceParameters.LoggingLevel = $MockLoggingLevel
                    $testTargetResourceParameters.DisplayName = $MockDisplayName
                    $testTargetResourceParameters.ReplyToAddress = $MockReplyToAddress
                    $testTargetResourceParameters.Description = $MockDescription
                    $testTargetResourceParameters.TcpPort = $MockTcpPort

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters

                    $testTargetResourceResult | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the configuration should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return the state as $false' {
                InModuleScope -ScriptBlock {
                    $testTargetResourceParameters = $script:mockDefaultParameters.Clone()
                    $testTargetResourceParameters.Ensure = 'Absent'

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the configuration should be present' {
            BeforeDiscovery {
                $testCase = @(
                    @{
                        Property      = 'EmailAddress'
                        PropertyValue = 'wrong@email.address'
                    }
                    @{
                        Property      = 'MailServerName'
                        PropertyValue = 'smtp.contoso.com'
                    }
                    @{
                        Property      = 'ProfileName'
                        PropertyValue = 'NewProfile'
                    }
                    @{
                        Property      = 'DisplayName'
                        PropertyValue = 'New display name'
                    }
                    @{
                        Property      = 'ReplyToAddress'
                        PropertyValue = 'new-reply@email.address'
                    }
                    @{
                        Property      = 'Description'
                        PropertyValue = 'New description'
                    }
                    @{
                        Property      = 'LoggingLevel'
                        PropertyValue = 'Extended'
                    }
                    @{
                        Property      = 'TcpPort'
                        PropertyValue = '2525'
                    }
                )
            }

            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure         = 'Present'
                        ServerName     = $mockServerName
                        InstanceName   = $mockInstanceName
                        AccountName    = $mockAccountName
                        EmailAddress   = $mockEmailAddress
                        MailServerName = $mockMailServerName
                        LoggingLevel   = 'Normal'
                        ProfileName    = $mockProfileName
                        DisplayName    = $mockDisplayName
                        ReplyToAddress = $mockReplyToAddress
                        Description    = $mockDescription
                        TcpPort        = $mockTcpPort
                    }
                }
            }

            It 'Should return the state as $false when <Property> is missing' -ForEach @(
                @{
                    Property      = 'AccountName'
                    PropertyValue = 'MissingAccountName'
                }
            ) {
                $inModuleScopeParameters = @{
                    Property      = $Property
                    PropertyValue = $PropertyValue
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $Property,
                        $PropertyValue
                    )

                    $testTargetResourceParameters = $script:mockDefaultParameters.Clone()
                    $testTargetResourceParameters.$Property = $PropertyValue

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }

            It 'Should return the state as $false when <Property> is wrong' -ForEach $testCase {
                $inModuleScopeParameters = @{
                    Property      = $Property
                    PropertyValue = $PropertyValue
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $Property,
                        $PropertyValue
                    )

                    $testTargetResourceParameters = $script:mockDefaultParameters.Clone()
                    $testTargetResourceParameters.$Property = $PropertyValue

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_SqlDatabaseMail\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
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

        $mockAgentMailTypeDatabaseMail = 'DatabaseMail'
        $mockAgentMailTypeSqlAgentMail = 'SQLAgentMail'

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
                            InModuleScope -ScriptBlock {
                                $script:MailServerRenameMethodCallCount += 1
                            }
                    } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                            InModuleScope -ScriptBlock {
                                $script:MailServerAlterMethodCallCount += 1
                            }
                    } -PassThru -Force
                )
            } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Create' -Value {
                    InModuleScope -ScriptBlock {
                        $script:MailAccountCreateMethodCallCount += 1
                    }
            } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                    InModuleScope -ScriptBlock {
                        $script:MailAccountDropMethodCallCount += 1
                    }
            } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                    InModuleScope -ScriptBlock {
                        $script:MailAccountAlterMethodCallCount += 1
                    }
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
                        InModuleScope -ScriptBlock {
                            $script:MailProfileCreateMethodCallCount += 1
                        }
                } -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                        InModuleScope -ScriptBlock {
                            $script:MailProfileAlterMethodCallCount += 1
                        }
                } -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                        InModuleScope -ScriptBlock {
                            $script:MailProfileDropMethodCallCount += 1
                        }
                    } -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'AddPrincipal' -Value {
                        InModuleScope -ScriptBlock {
                            $script:MailProfileAddPrincipalMethodCallCount += 1
                        }
                } -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'AddAccount' -Value {
                        InModuleScope -ScriptBlock {
                            $script:MailProfileAddAccountMethodCallCount += 1
                        }
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
                        Add-Member -MemberType NoteProperty -Name 'RunValue' -Value $mockDynamicDatabaseMailEnabledRunValue -PassThru -Force
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
                                InModuleScope -ScriptBlock {
                                    $script:LoggingLevelAlterMethodCallCount += 1
                                }
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
                    Add-Member -MemberType NoteProperty -Name 'AgentMailType' -Value $mockDynamicAgentMailType -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'DatabaseMailProfile' -Value $mockDynamicDatabaseMailProfile -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                        InModuleScope -ScriptBlock {
                            $script:JobServerAlterMethodCallCount += 1
                        }
                } -PassThru -Force
            } -PassThru -Force
        }

        $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
        $mockDynamicLoggingLevelValue = $mockLoggingLevelNormalValue
        $mockDynamicDescription = $mockDescription
        $mockDynamicAgentMailType = $mockAgentMailTypeDatabaseMail
        $mockDynamicDatabaseMailProfile = $mockProfileName

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                AccountName    = 'MyMail'
                EmailAddress   = 'NoReply@company.local'
                MailServerName = 'mail.company.local'
                ProfileName    = 'MyMailProfile'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            # Reset all method call counts before each It-block.
            $script:MailAccountCreateMethodCallCount = 0
            $script:MailServerRenameMethodCallCount = 0
            $script:MailServerAlterMethodCallCount = 0
            $script:MailAccountAlterMethodCallCount = 0
            $script:MailProfileCreateMethodCallCount = 0
            $script:MailProfileAlterMethodCallCount = 0
            $script:MailProfileAddPrincipalMethodCallCount = 0
            $script:MailProfileAddAccountMethodCallCount = 0
            $script:JobServerAlterMethodCallCount = 0
            $script:LoggingLevelAlterMethodCallCount = 0
            $script:MailProfileDropMethodCallCount = 0
            $script:MailAccountDropMethodCallCount = 0
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the configuration should be absent' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $mockDynamicExpectedAccountName = $mockMissingAccountName
                $mockDynamicDatabaseMailProfile = $null
                $mockDynamicAgentMailType = $mockAgentMailTypeSqlAgentMail
            }

            AfterAll {
                $mockDynamicExpectedAccountName = $mockAccountName
                $mockDynamicDatabaseMailProfile = $mockProfileName
                $mockDynamicAgentMailType = $mockAgentMailTypeDatabaseMail
            }

            It 'Should call the correct methods without throwing' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = $mockDefaultParameters.Clone()
                    $setTargetResourceParameters.Ensure = 'Absent'
                    $setTargetResourceParameters.AccountName = 'MissingAccount'
                    $setTargetResourceParameters.ProfileName = 'MissingProfile'

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $script:MailAccountCreateMethodCallCount | Should -Be 0
                    $script:MailServerRenameMethodCallCount | Should -Be 0
                    $script:MailServerAlterMethodCallCount | Should -Be 0
                    $script:MailAccountAlterMethodCallCount | Should -Be 0
                    $script:MailProfileCreateMethodCallCount | Should -Be 0
                    $script:MailProfileAlterMethodCallCount | Should -Be 0
                    $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                    $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                    $script:JobServerAlterMethodCallCount | Should -Be 0
                    $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                    $script:MailProfileDropMethodCallCount | Should -Be 0
                    $script:MailAccountDropMethodCallCount | Should -Be 0
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the configuration should be present' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            It 'Should call the correct methods without throwing' {
                $inModuleScopeParameters = @{
                    MockLoggingLevel   = $mockLoggingLevelNormal
                    MockDisplayName    = $mockDisplayName
                    MockReplyToAddress = $mockReplyToAddress
                    MockDescription    = $mockDescription
                    MockTcpPort        = $mockTcpPort
                }

                InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                    # This should be able to be removed in a future version of Pester.
                    param
                    (
                        $MockLoggingLevel,
                        $MockDisplayName,
                        $MockReplyToAddress,
                        $MockDescription,
                        $MockTcpPort
                    )

                    $setTargetResourceParameters = $mockDefaultParameters.Clone()
                    $setTargetResourceParameters['DisplayName'] = $MockDisplayName
                    $setTargetResourceParameters['ReplyToAddress'] = $MockReplyToAddress
                    $setTargetResourceParameters['Description'] = $MockDescription
                    $setTargetResourceParameters['LoggingLevel'] = $MockLoggingLevel
                    $setTargetResourceParameters['TcpPort'] = $MockTcpPort

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $script:MailAccountCreateMethodCallCount | Should -Be 0
                    $script:MailServerRenameMethodCallCount | Should -Be 0
                    $script:MailServerAlterMethodCallCount | Should -Be 0
                    $script:MailAccountAlterMethodCallCount | Should -Be 0
                    $script:MailProfileCreateMethodCallCount | Should -Be 0
                    $script:MailProfileAlterMethodCallCount | Should -Be 0
                    $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
                    $script:MailProfileAddAccountMethodCallCount | Should -Be 0
                    $script:JobServerAlterMethodCallCount | Should -Be 0
                    $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                    $script:MailProfileDropMethodCallCount | Should -Be 0
                    $script:MailAccountDropMethodCallCount | Should -Be 0
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the configuration should be absent' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            It 'Should return the state as $false' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = $mockDefaultParameters.Clone()
                    $setTargetResourceParameters.Ensure = 'Absent'

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $script:JobServerAlterMethodCallCount | Should -Be 1
                    $script:MailProfileDropMethodCallCount | Should -Be 1
                    $script:MailAccountDropMethodCallCount | Should -Be 1
                }
            }
        }

        Context 'When the configuration should be present' {
            Context 'When Database Mail XPs is enabled but fails evaluation' {
                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailDisabledConfigValue
                }

                AfterAll {
                    $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        {
                            $mockErrorRecord = Get-InvalidOperationRecord -Message $script:localizedData.DatabaseMailDisabled

                            $setTargetResourceParameters = $mockDefaultParameters.Clone()

                            Set-TargetResource @setTargetResourceParameters
                        } | Should -Throw $mockErrorRecord.Exception.Message
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When account name and profile name is missing' {
                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                    Mock -CommandName New-Object -MockWith $mockNewObject_MailAccount -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.SMO.Mail.MailAccount'
                    } -Verifiable

                    Mock -CommandName New-Object -MockWith $mockNewObject_MailProfile -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.SMO.Mail.MailProfile'
                    } -Verifiable
                }

                It 'Should call the correct methods without throwing' {
                    InModuleScope -ScriptBlock {
                        $setTargetResourceParameters = $mockDefaultParameters.Clone()
                        $setTargetResourceParameters['AccountName'] = 'MissingAccount'
                        $setTargetResourceParameters['ProfileName'] = 'MissingProfile'

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:MailAccountCreateMethodCallCount | Should -Be 1
                        $script:MailServerRenameMethodCallCount | Should -Be 1
                        $script:MailServerAlterMethodCallCount | Should -Be 1
                        $script:MailAccountAlterMethodCallCount | Should -Be 0
                        $script:MailProfileCreateMethodCallCount | Should -Be 1
                        $script:MailProfileAlterMethodCallCount | Should -Be 1
                        $script:MailProfileAddPrincipalMethodCallCount | Should -Be 1
                        $script:MailProfileAddAccountMethodCallCount | Should -Be 1
                        $script:JobServerAlterMethodCallCount | Should -Be 1
                        $script:LoggingLevelAlterMethodCallCount | Should -Be 0
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When properties are not in desired state' {
                BeforeDiscovery {
                    $testCase = @(
                        @{
                            Property      = 'EmailAddress'
                            PropertyValue = 'wrong@email.address'
                        }
                        @{
                            Property      = 'MailServerName'
                            PropertyValue = 'smtp.contoso.com'
                        }
                        @{
                            Property      = 'DisplayName'
                            PropertyValue = 'New display name'
                        }
                        @{
                            Property      = 'ReplyToAddress'
                            PropertyValue = 'new-reply@email.address'
                        }
                        @{
                            Property      = 'Description'
                            PropertyValue = 'New description'
                        }
                        @{
                            Property      = 'LoggingLevel'
                            PropertyValue = 'Extended'
                        }
                        @{
                            Property      = 'LoggingLevel'
                            PropertyValue = 'Verbose'
                        }
                        @{
                            Property      = 'TcpPort'
                            PropertyValue = '2525'
                        }
                    )
                }

                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                }

                It 'Should call the correct methods when <Property> should be changed to the value ''<PropertyValue>''' -ForEach $testCase {
                    $inModuleScopeParameters = @{
                        Property      = $Property
                        PropertyValue = $PropertyValue
                    }

                    InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                        # This should be able to be removed in a future version of Pester.
                        param
                        (
                            $Property,
                            $PropertyValue
                        )

                        $setTargetResourceParameters = $mockDefaultParameters.Clone()

                        $setTargetResourceParameters.$Property = $PropertyValue

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        $script:MailAccountCreateMethodCallCount | Should -Be 0

                        if ($Property -eq 'MailServerName')
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
                        elseif ($Property -eq 'TcpPort')
                        {
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
                        elseif ($Property -eq 'LoggingLevel')
                        {
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
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Assert-VerifiableMock
}
