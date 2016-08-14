# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerLogin'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

# Begin Testing
try
{
    #region Pester Test Initialization

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

    $nodeName = 'localhost'
    $instanceName = 'MSSQLSERVER'

    $mockSqlLoginUser = "dba" 
    $mockSqlLoginPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
    $mockSqlLoginCredential = New-Object System.Management.Automation.PSCredential( $mockSqlLoginUser, $mockSqlLoginPassword )

    $defaultParameters = @{
        SQLInstanceName = $instanceName
        SQLServer = $nodeName
    }

    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Logins {
                    return @{
                        'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru ) )
                        'John' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'SqlLogin' -PassThru ) )
                        'COMPANY\SqlUsers' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsGroup' -PassThru ) )
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'COMPANY\UnknownUser'
            }

            $result = Get-TargetResource @testParameters

            It 'Should not return the state as absent' {
                $result.Ensure | Should Be 'Absent'
                $result.LoginType | Should Be ''
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Connect-SQL' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }
    
        Context 'When the system is in the desired state for a Windows user' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'COMPANY\Stacy'
            }
    
            $result = Get-TargetResource @testParameters

            It 'Should not return the state as present' {
                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'WindowsUser'
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Connect-SQL' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is in the desired state for a Windows group' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'COMPANY\SqlUsers'
            }
    
            $result = Get-TargetResource @testParameters

            It 'Should not return the state as present' {
                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'WindowsGroup'
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Connect-SQL' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is in the desired state for a SQL login' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'John'
            }
    
            $result = Get-TargetResource @testParameters

            It 'Should not return the state as present' {
                $result.Ensure | Should Be 'Present'
                $result.LoginType | Should Be 'SqlLogin'
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Connect-SQL' {
                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Logins {
                    return @{
                        'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru ) )
                        'John' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'SqlLogin' -PassThru ) )
                        'COMPANY\SqlUsers' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsGroup' -PassThru ) )
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {
            It 'Should return desired state as absent when desired windows user don''t exists' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'COMPANY\UnknownUser'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $false

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }

            It 'Should return desired state as present when desired login exists regardless of login type' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'COMPANY\SqlUsers'
                    LoginType = 'SqlLogin'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'John'
                    LoginType = 'WindowsUser'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Connect-SQL -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope It 
            }
        }

        Context 'When the system is in the desired state' {
            It 'Should return that desired state as present when desired windows user exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'COMPANY\Stacy'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }

            It 'Should return that desired state as present when desired windows group exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'COMPANY\SqlUsers'
                    LoginType = 'WindowsGroup'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }

            It 'Should return that desired state as present when desired sql login exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Name = 'John'
                    LoginType = 'SqlLogin'
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true

                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It 
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object Object | 
                Add-Member ScriptProperty Logins {
                    return @{
                        'COMPANY\Stacy' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsUser' -PassThru |
                                        Add-Member ScriptMethod Drop {} -PassThru ) )
                        'John' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'SqlLogin' -PassThru |
                                        Add-Member ScriptMethod Drop {} -PassThru ) )
                        'COMPANY\SqlUsers' = @( ( New-Object Object |
                                        Add-Member NoteProperty LoginType 'WindowsGroup' -PassThru |
                                        Add-Member ScriptMethod Drop {} -PassThru ) )
                    }
                } -PassThru -Force 
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'UnknownSqlLogin'
                LoginType = 'SqlLogin'
            }

            It 'Should throw an error when desired login type is a SQL login and LoginCredential parameter is not passed' {
                { Set-TargetResource @testParameters } | Should Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters += @{
                LoginCredential = $mockSqlLoginCredential
            }

            It 'Should not throw an error when desired login type is a SQL login' {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        LoginType = 'SqlLogin'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable

                { Set-TargetResource @testParameters } | Should Not Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'COMPANY\UnknownUser'
                LoginType = 'WindowsUser'
            }

            It 'Should not throw an error when desired login type is a Windows User' {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        LoginType = 'WindowsUser'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable

                { Set-TargetResource @testParameters } | Should Not Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'COMPANY\UnknownGroup'
                LoginType = 'WindowsGroup'
            }

            It 'Should not throw an error when desired login type is a Windows Group' {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        LoginType = 'WindowsGroup'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable

                { Set-TargetResource @testParameters } | Should Not Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure = 'Absent'
                Name = 'John'
            }

            It 'Should not throw an error when desired login should be absent but are present' {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Absent'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable

                { Set-TargetResource @testParameters } | Should Not Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Context 'When the system is in the desired state' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'John'
                LoginType = 'SqlLogin'
            }

            It 'Should throw an error when desired login type is a SQL login and LoginCredential parameter is not passed' {
                { Set-TargetResource @testParameters } | Should Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters += @{
                LoginCredential = $mockSqlLoginCredential
            }

            It 'Should not throw an error when desired login type is a SQL login' {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        LoginType = 'SqlLogin'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable

                { Set-TargetResource @testParameters } | Should Not Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'COMPANY\Stacy'
                LoginType = 'WindowsUser'
            }

            It 'Should not throw an error when desired login type is a Windows User' {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        LoginType = 'WindowsUser'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable

                { Set-TargetResource @testParameters } | Should Not Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                Name = 'COMPANY\SqlUsers'
                LoginType = 'WindowsGroup'
            }

            It 'Should not throw an error when desired login type is a Windows Group' {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Present'
                        LoginType = 'WindowsGroup'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable

                { Set-TargetResource @testParameters } | Should Not Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure = 'Absent'
                Name = 'John'
                LoginType = 'SqlLogin'
            }

            It 'Should not throw an error when desired login should be absent but are already absent' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object Object | 
                        Add-Member ScriptProperty Logins {
                            return @{
                                'John' = @( ( New-Object Object |
                                                Add-Member NoteProperty LoginType 'SqlLogin' -PassThru |
                                                Add-Member ScriptMethod Drop { 
                                                    throw 'Called Drop() method when the login is already absent'
                                                } -PassThru ) )
                            }
                        } -PassThru -Force 
                } -ModuleName $script:DSCResourceName -Verifiable

                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Absent'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable

                { Set-TargetResource @testParameters } | Should Not Throw
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }
        }

        Assert-VerifiableMocks
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment 

    #endregion
}
