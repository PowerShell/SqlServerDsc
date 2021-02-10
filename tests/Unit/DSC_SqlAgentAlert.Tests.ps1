<#
    .SYNOPSIS
        Unit test for DSC_SqlAgentAlert DSC resource.
#>

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlAgentAlert'

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
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'DSC_SqlAgentAlert\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockServerName = 'localhost'
            $script:mockInstanceName = 'MSSQLSERVER'

            # Default parameters that are used for the It-blocks
            $script:mockDefaultParameters = @{
                InstanceName = $mockInstanceName
                ServerName   = $mockServerName
            }
        }

        # Mocked object for Connect-SQL.
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName 'Object' |
                        Add-Member -MemberType 'ScriptProperty' -Name 'JobServer' -Value {
                            return (
                                New-Object -TypeName 'Object' |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'Alerts' -Value {
                                        return @(
                                            (
                                                New-Object -TypeName 'Object' |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlertSev' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value '17' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'MessageId' -Value 0 -PassThru -Force
                                            ),
                                            (
                                                New-Object -TypeName 'Object' |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlertMsg' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value 0 -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'MessageId' -Value '825' -PassThru -Force
                                            )
                                        )
                                    } -PassThru
                            )
                        } -PassThru -Force
                )
            )
        }
    }

    Context 'When Connect-SQL returns nothing' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                return $null
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters.Clone()
                $mockTestParameters.Name = 'TestAlertSev'

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.ConnectServerFailed -f $mockTestParameters.ServerName, $mockTestParameters.InstanceName
                )

                { Get-TargetResource @mockTestParameters } |
                    Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            InModuleScope -ScriptBlock {
                $script:mockTestParameters = $mockDefaultParameters.Clone()
                $script:mockTestParameters.Name = 'MissingAlert'
            }
        }

        It 'Should return the state as absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockTestParameters

                $result.Ensure | Should -Be 'Absent'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockTestParameters

                $result.ServerName | Should -Be $mockTestParameters.ServerName
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
            }
        }

        It 'Should call the mock function Connect-SQL' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }

    Context 'When the system is in the desired state for a sql agent alert' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

            InModuleScope -ScriptBlock {
                $script:mockTestParameters = $mockDefaultParameters.Clone()
                $script:mockTestParameters.Name = 'TestAlertSev'
            }
        }

        It 'Should return the state as present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockTestParameters

                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockTestParameters

                $result.ServerName | Should -Be $mockTestParameters.ServerName
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
                $result.Name | Should -Be $mockTestParameters.Name
                $result.Severity | Should -Be '17'
                $result.MessageId | Should -Be 0
            }
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }
}

Describe 'DSC_SqlAgentAlert\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockServerName = 'localhost'
            $script:mockInstanceName = 'MSSQLSERVER'

            # Default parameters that are used for the It-blocks
            $script:mockDefaultParameters = @{
                InstanceName = $mockInstanceName
                ServerName   = $mockServerName
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the alert does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = $null
                        Ensure       = 'Absent'
                        ServerName   = $ServerName
                        InstanceName = $InstanceName
                        Severity     = $null
                        MessageId    = $null
                    }
                }
            }

            It 'Should return the state as false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters
                    $mockTestParameters += @{
                        Name         = 'MissingAlert'
                        Severity     = '25'
                        Ensure       = 'Present'
                    }

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the alert should not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'TestAlertSev'
                        Ensure       = 'Present'
                        ServerName   = $ServerName
                        InstanceName = $InstanceName
                        Severity     = '17'
                        MessageId    = '825'
                    }
                }
            }

            It 'Should return the state as false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters
                    $mockTestParameters += @{
                        Name   = 'TestAlertSev'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When enforcing a severity alert' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'TestAlertSev'
                        Ensure       = 'Present'
                        ServerName   = $ServerName
                        InstanceName = $InstanceName
                        Severity     = '17'
                        MessageId    = '825'
                    }
                }
            }

            It 'Should return the state as false when desired sql agent alert exists but has the incorrect severity' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters
                    $mockTestParameters += @{
                        Name            = 'TestAlertSev'
                        Ensure          = 'Present'
                        Severity        = '25'
                    }

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeFalse
                }
            }

            It 'Should return the state as false when desired sql agent alert exists but has the incorrect message id' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters
                    $mockTestParameters += @{
                        Name            = 'TestAlertSev'
                        Ensure          = 'Present'
                        MessageId       = '500'
                    }

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeFalse
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When an alert does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'MissingAlert'
                        Ensure       = 'Absent'
                        ServerName   = $ServerName
                        InstanceName = $InstanceName
                        Severity     = $null
                        MessageId    = $null
                    }
                }
            }

            It 'Should return the state as true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters
                    $mockTestParameters += @{
                        Name   = 'MissingAlert'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When enforcing a severity alert' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'TestAlertSev'
                        Ensure       = 'Present'
                        ServerName   = $ServerName
                        InstanceName = $InstanceName
                        Severity     = '17'
                        MessageId    = '825'
                    }
                }
            }

            It 'Should return the state as true when desired sql agent alert exist' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters
                    $mockTestParameters += @{
                        Name      = 'TestAlertSev'
                        Ensure    = 'Present'
                    }

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }

            It 'Should return the state as true when desired sql agent alert exists and has the correct severity' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters
                    $mockTestParameters += @{
                        Name            = 'TestAlertSev'
                        Ensure          = 'Present'
                        Severity        = '17'
                    }

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When enforcing a message alert' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name         = 'TestAlertMsg'
                        Ensure       = 'Present'
                        ServerName   = $ServerName
                        InstanceName = $InstanceName
                        Severity     = '17'
                        MessageId    = '825'
                    }
                }
            }

            It 'Should return the state as true when desired sql agent alert exists and has the correct message id' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters = $mockDefaultParameters
                    $mockTestParameters += @{
                        Name            = 'TestAlertMsg'
                        Ensure          = 'Present'
                        MessageId       = '825'
                    }

                    $result = Test-TargetResource @mockTestParameters

                    $result | Should -BeTrue
                }
            }
        }
    }
}

Describe 'DSC_SqlAgentAlert\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockServerName = 'localhost'
            $script:mockInstanceName = 'MSSQLSERVER'

            # Default parameters that are used for the It-blocks
            $script:mockDefaultParameters = @{
                InstanceName = $mockInstanceName
                ServerName   = $mockServerName
            }
        }

        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod = $false
        $mockInvalidOperationForAlterMethod = $false
        $mockExpectedSqlAgentAlertToCreate = 'MissingAlertSev'
        $mockExpectedSqlAgentAlertToDrop = 'Sev18'

        # Mocked object for Connect-SQL.
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName 'Object' |
                        Add-Member -MemberType 'ScriptProperty' -Name 'JobServer' -Value {
                            return (
                                New-Object -TypeName 'Object' |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'Alerts' -Value {
                                        return @(
                                            (
                                                New-Object -TypeName 'Object' |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlertSev' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value '17' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'MessageId' -Value 0 -PassThru |
                                                    Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                                                        if ($mockInvalidOperationForDropMethod)
                                                        {
                                                            throw 'Mock Drop Method was called with invalid operation.'
                                                        }

                                                        if ( $this.Name -ne $mockExpectedSqlAgentAlertToDrop )
                                                        {
                                                            throw "Called mocked Drop() method without dropping the right sql agent alert. Expected '{0}'. But was '{1}'." `
                                                                -f $mockExpectedSqlAgentAlertToDrop, $this.Name
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                                                        if ($mockInvalidOperationForAlterMethod)
                                                        {
                                                            throw 'Mock Alter Method was called with invalid operation.'
                                                        }
                                                    } -PassThru -Force
                                            ),
                                            (
                                                New-Object -TypeName 'Object' |
                                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestAlertMsg' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name 'Severity' -Value 0 -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name 'MessageId' -Value '825' -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                                                        if ($mockInvalidOperationForDropMethod)
                                                        {
                                                            throw 'Mocking that the method Drop is throwing an invalid operation.'
                                                        }

                                                        if ($this.Name -ne $mockExpectedSqlAgentAlertToDrop)
                                                        {
                                                            throw "Called mocked Drop() method without dropping the right sql agent alert. Expected '{0}'. But was '{1}'." `
                                                                -f $mockExpectedSqlAgentAlertToDrop, $this.Name
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                                                        if ($mockInvalidOperationForAlterMethod)
                                                        {
                                                            throw 'Mock Alter Method was called with invalid operation.'
                                                        }

                                                        if ($this.MessageId -eq 7)
                                                        {
                                                            throw "Called mocked Create() method for a message id that doesn't exist."
                                                        }

                                                        if ($this.Severity -eq 999)
                                                        {
                                                            throw "Called mocked Create() method for a severity that doesn't exist."
                                                        }
                                                    } -PassThru -Force
                                            )
                                        )
                                    } -PassThru
                            )
                        } -PassThru -Force
                )
            )
        }

        <#
            Mocked object for New-Object with parameter filter
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'.
        #>
        $mockNewSqlAgentAlert = {
            return @(
                (
                    New-Object -TypeName 'Object' |
                        # Using the value from the second property passed in the parameter ArgumentList of the cmdlet New-Object.
                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $ArgumentList[1] -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value $null -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'MessageId' -Value $null -PassThru |
                        Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                            if ($mockInvalidOperationForCreateMethod)
                            {
                                throw 'Mocking that the method Create is throwing an invalid operation.'
                            }

                            if ($this.Name -ne $mockExpectedSqlAgentAlertToCreate)
                            {
                                throw "Called mocked Create() method without adding the right sql agent alert. Expected '{0}'. But was '{1}'." `
                                    -f $mockExpectedSqlAgentAlertToCreate, $this.Name
                            }
                        } -PassThru -Force
                )
            )
        }
    }

    Context 'When Connect-SQL returns nothing' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                return $null
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name   = 'Message7'
                    Ensure = 'Present'
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.ConnectServerFailed -f $mockTestParameters.ServerName, $mockTestParameters.InstanceName
                )

                { Set-TargetResource @mockTestParameters } |
                    Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
            }
        }
    }

    Context 'When the system is not in the desired state and Ensure is set to Present'{
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            Mock -CommandName New-Object -MockWith $mockNewSqlAgentAlert -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
            } -Verifiable
        }

        It 'Should not throw when creating the sql agent alert' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name   = 'MissingAlertSev'
                    Ensure = 'Present'
                    Severity  = '16'
                }

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should not throw when changing the severity' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name      = 'TestAlertSev'
                    Ensure    = 'Present'
                    Severity  = '17'
                }

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }
        }

        It 'Should not throw when changing the message id' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name       = 'TestAlertMsg'
                    Ensure     = 'Present'
                    MessageId  = '825'
                }

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }
        }

        It 'Should throw when changing severity and message id' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name       = 'TestAlertMsg'
                    Ensure     = 'Present'
                    Severity   = '17'
                    MessageId  = '825'
                }

                { Set-TargetResource @mockTestParameters } | Should -Throw
            }
        }

        It 'Should throw when message id is not valid when altering existing alert' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name       = 'TestAlertMsg'
                    Ensure     = 'Present'
                    MessageId  = '7'
                }

                { Set-TargetResource @mockTestParameters } | Should -Throw
            }
        }

        It 'Should throw when severity is not valid when altering existing alert' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name       = 'TestAlertMsg'
                    Ensure     = 'Present'
                    Severity   = '999'
                }

                { Set-TargetResource @mockTestParameters } | Should -Throw
            }
        }

        It 'Should throw when message id is not valid when creating  alert' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name       = 'NewAlertMsg'
                    Ensure     = 'Present'
                    MessageId  = '7'
                }

                { Set-TargetResource @mockTestParameters } | Should -Throw
            }
        }

        It 'Should throw when severity is not valid when creating alert' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name       = 'NewAlertMsg'
                    Ensure     = 'Present'
                    Severity   = '999'
                }

                { Set-TargetResource @mockTestParameters } | Should -Throw
            }
        }

        It 'Should throw the correct error when Create() method was called with invalid operation' {
            $mockInvalidOperationForCreateMethod = $true

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name   = 'NewAlert'
                    Ensure = 'Present'
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.CreateAlertSetError -f $mockTestParameters.Name, $mockTestParameters.ServerName, $mockTestParameters.InstanceName
                )

                <#
                    Using wildcard for comparison due to that the mock throws and adds
                    the mocked exception message on top of the original message.
                #>
                { Set-TargetResource @mockTestParameters } |
                    Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
            }

            $mockInvalidOperationForCreateMethod = $false
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }

    Context 'When the system is not in the desired state and Ensure is set to Absent' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
        }

        It 'Should not throw when dropping the sql agent alert' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name   = 'Sev16'
                    Ensure = 'Absent'
                }

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should throw the correct error when Drop() method was called with invalid operation' {
            $mockInvalidOperationForDropMethod = $true

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = $mockDefaultParameters
                $mockTestParameters += @{
                    Name      = 'TestAlertSev'
                    Ensure    = 'Absent'
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DropAlertSetError -f $mockTestParameters.Name, $mockTestParameters.ServerName, $mockTestParameters.InstanceName
                )

                <#
                    Using wildcard for comparison due to that the mock throws and adds
                    the mocked exception message on top of the original message.
                #>
                { Set-TargetResource @mockTestParameters } |
                    Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
            }

            $mockInvalidOperationForDropMethod = $false
        }

        It 'Should call all verifiable mocks' {
            Should -InvokeVerifiable
        }
    }
}
