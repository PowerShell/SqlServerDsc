<#
    .SYNOPSIS
        Automated unit test for DSC_SqlTraceFlag DSC resource.

#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlTraceFlag'

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
        Describe "DSC_SqlTraceFlag\Get-TargetResource" -Tag 'Get'  {
            BeforeAll {
                $mockServerName = 'TestServer'
                $mockFakeServerName = 'FakeServer'
                $mockInstanceName1 = 'MSSQLSERVER'
                $mockInstanceName1Agent = 'SQLSERVERAGENT'
                $mockInstanceName2 = 'INST00'
                $mockInstanceName2Agent = 'SQLAgent$INST00'
                $mockInstanceName3 = 'INST01'
                $mockInstanceName3Agent = 'SQLAgent$INST01'

                $mockInvalidOperationForAlterMethod = $false

                $mockServerInstances = [System.Collections.ArrayList]::new()
                $mockServerInstances.Add($mockInstanceName1) | Out-Null
                $mockServerInstances.Add($mockInstanceName2) | Out-Null

                 # The Trailing spaces in these here strings are ment to be there. Do not remove!
                $mockStartupParametersInstance1 = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802
"@
                $mockStartupParametersInstance2 = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@

                # Default parameters that are used for the It-blocks
                $mockDefaultParameters1 = @{
                    InstanceName = $mockInstanceName1
                    ServerName   = $mockServerName
                }

                $mockInst00Parameters = @{
                    InstanceName = $mockInstanceName2
                    ServerName   = $mockServerName
                }

                $mockInst01Parameters = @{
                    InstanceName = $mockInstanceName3
                    ServerName   = $mockServerName
                }

                $mockNonExistServerParameters = @{
                    InstanceName = $mockInstanceName1
                    ServerName   = $mockFakeServerName
                }

                $mockNewObject_ParameterFilter_RealServerName = {
                    $ServerName -eq $mockServerName
                }

                $mockNewObject_ParameterFilter_FakeServerName = {
                    $ServerName -eq $mockFakeServerName
                }

                $script:mockMethodAlterRan = $false
                $script:mockMethodAlterValue = ''

                #region Function mocks
                $mockSmoWmiManagedComputer = {
                    $mockServerObjectHashtable = @{
                        State = "Existing"
                        Name = $mockServerName
                        ServerInstances = $mockServerInstances
                    }

                    class service
                    {
                        [string]$Name
                        [string]$ServiceState
                        [string]$StartupParameters
                    }

                    $Services = [System.Collections.ArrayList]::new()

                    $service1 = [service]::new()
                    $service1.Name = $mockInstanceName1
                    $service1.ServiceState = "Running"
                    $service1.StartupParameters = $mockStartupParametersInstance1

                    $Services.Add($service1) | Out-Null

                    $service2 = [service]::new()
                    $service2.Name = $mockInstanceName1Agent
                    $service2.ServiceState = "Running"
                    $service2.StartupParameters = ""

                    $Services.Add($service2) | Out-Null

                    $service3 = [service]::new()
                    $service3.Name = 'MSSQL${0}' -f $mockInstanceName2
                    $service3.ServiceState = "Running"
                    $service3.StartupParameters = $mockStartupParametersInstance2

                    $Services.Add($service3) | Out-Null

                    $service4 = [service]::new()
                    $service4.Name = 'SQLAgent${0}' -f $mockInstanceName2Agent
                    $service4.ServiceState = "Stopped"
                    $service4.StartupParameters = ""

                    $Services.Add($service4) | Out-Null

                    $ServerServices = [System.Collections.ArrayList]::new()

                    foreach ($mockService in $Services)
                    {
                        $mockService | Add-Member -MemberType ScriptMethod -Name Alter -Value {
                            $script:mockMethodAlterRan = $true
                            $script:mockMethodAlterValue = $this.StartupParameters
                        } -PassThru
                        $ServerServices.Add( $mockService) | Out-Null
                    }

                    $mockServerObjectHashtable += @{
                        Services = $ServerServices
                    }
                    $mockServerObject = [PSCustomObject]$mockServerObjectHashtable

                    return @($mockServerObject)
                }
                Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer -ParameterFilter $mockNewObject_ParameterFilter_RealServerName -Verifiable
                Mock -CommandName Import-SQLPSModule
            }

            Context 'For the default instance' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                }
                It 'Should return a ManagedComputer object.' {
                    $result = Get-TargetResource @testParameters

                    $result.ServerName | Should -Be $mockServerName -Because 'ServerName must be correct'
                    $result.InstanceName | Should -Be $mockInstanceName1 -Because 'InstanceName must be correct'
                    $result.TraceFlags | Should -Be '3226' ,'1802' -Because 'TraceFlags must be correct'
                    $result.TraceFlags.Count | Should -Be 2 -Because 'number of TraceFlags must be correct'
                }
                It 'Should not throw' {
                    {Get-TargetResource @testParameters} | Should -Not -Throw
                }
            }

            Context 'For a named instance' {
                BeforeAll {
                    $testParameters = $mockInst00Parameters
                }
                It 'Should return a ManagedComputer object.' {
                    $result = Get-TargetResource @testParameters

                    $result.ServerName | Should -Be $mockServerName -Because 'ServerName must be correct'
                    $result.InstanceName | Should -Be $mockInstanceName2 -Because 'InstanceName must be correct'
                    $result.TraceFlags | Should -BeNullOrEmpty -Because 'TraceFlags must be correct'
                    $result.TraceFlags.Count | Should -Be 0 -Because 'number of TraceFlags must be correct'
                }

                It 'Should not throw' {
                    {Get-TargetResource @testParameters} | Should -Not -Throw
                }
            }

            Context 'For a nonexist instance' {
                BeforeAll {
                    $testParameters = $mockInst01Parameters
                }
                It 'Should throw for incorect parameters' {
                    {Get-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to WMI information '{0}' in '{1}'." -f $mockInstanceName3, $mockServerName)
                }
            }

            Context 'For a nonexist server' {
                BeforeAll {
                    $testParameters = $mockNonExistServerParameters
                    Mock -CommandName New-Object -MockWith {
                        return $null
                    } -ParameterFilter $mockNewObject_ParameterFilter_FakeServerName -Verifiable
                }
                It 'Should throw for incorect parameters' {
                    {Get-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to ComputerManagement '{0}'." -f $mockFakeServerName)
                }
            }
        }

        Describe "DSC_SqlTraceFlag\Test-TargetResource" -Tag 'Test' {
            BeforeAll {
                $mockServerName = 'TestServer'
                $mockFakeServerName = 'FakeServer'
                $mockInstanceName1 = 'MSSQLSERVER'
                $mockInstanceName1Agent = 'SQLSERVERAGENT'
                $mockInstanceName2 = 'INST00'
                $mockInstanceName2Agent = 'SQLAgent$INST00'
                $mockInstanceName3 = 'INST01'
                $mockInstanceName3Agent = 'SQLAgent$INST01'

                $mockInvalidOperationForAlterMethod = $false

                $mockServerInstances = [System.Collections.ArrayList]::new()
                $mockServerInstances.Add($mockInstanceName1) | Out-Null
                $mockServerInstances.Add($mockInstanceName2) | Out-Null

                # The Trailing spaces in these here strings are ment to be there. Do not remove!
                $mockStartupParametersInstance1 = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802
"@
                $mockStartupParametersInstance2 = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@

                # Default parameters that are used for the It-blocks
                $mockDefaultParameters1 = @{
                    InstanceName = $mockInstanceName1
                    ServerName   = $mockServerName
                }

                $mockInst00Parameters = @{
                    InstanceName = $mockInstanceName2
                    ServerName   = $mockServerName
                }

                $mockInst01Parameters = @{
                    InstanceName = $mockInstanceName3
                    ServerName   = $mockServerName
                }

                $mockNonExistServerParameters = @{
                    InstanceName = $mockInstanceName1
                    ServerName   = $mockFakeServerName
                }

                $mockNewObject_ParameterFilter_RealServerName = {
                    $ServerName -eq $mockServerName
                }

                $mockNewObject_ParameterFilter_FakeServerName = {
                    $ServerName -eq $mockFakeServerName
                }

                $script:mockMethodAlterRan = $false
                $script:mockMethodAlterValue = ''

                #region Function mocks
                $mockSmoWmiManagedComputer = {
                    $mockServerObjectHashtable = @{
                        State = "Existing"
                        Name = $mockServerName
                        ServerInstances = $mockServerInstances
                    }

                    class service
                    {
                        [string]$Name
                        [string]$ServiceState
                        [string]$StartupParameters
                    }

                    $Services = [System.Collections.ArrayList]::new()

                    $service1 = [service]::new()
                    $service1.Name = $mockInstanceName1
                    $service1.ServiceState = "Running"
                    $service1.StartupParameters = $mockStartupParametersInstance1

                    $Services.Add($service1) | Out-Null

                    $service2 = [service]::new()
                    $service2.Name = $mockInstanceName1Agent
                    $service2.ServiceState = "Running"
                    $service2.StartupParameters = ""

                    $Services.Add($service2) | Out-Null

                    $service3 = [service]::new()
                    $service3.Name = 'MSSQL${0}' -f $mockInstanceName2
                    $service3.ServiceState = "Running"
                    $service3.StartupParameters = $mockStartupParametersInstance2

                    $Services.Add($service3) | Out-Null

                    $service4 = [service]::new()
                    $service4.Name = 'SQLAgent${0}' -f $mockInstanceName2Agent
                    $service4.ServiceState = "Stopped"
                    $service4.StartupParameters = ""

                    $Services.Add($service4) | Out-Null

                    $ServerServices = [System.Collections.ArrayList]::new()

                    foreach ($mockService in $Services)
                    {
                        $mockService | Add-Member -MemberType ScriptMethod -Name Alter -Value {
                            $script:mockMethodAlterRan = $true
                            $script:mockMethodAlterValue = $this.StartupParameters
                        } -PassThru
                        $ServerServices.Add( $mockService) | Out-Null
                    }

                    $mockServerObjectHashtable += @{
                        Services = $ServerServices
                    }
                    $mockServerObject = [PSCustomObject]$mockServerObjectHashtable

                    return @($mockServerObject)
                }
                Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer -Verifiable
                Mock -CommandName Import-SQLPSModule
            }

            Context 'When the system is not in the desired state and TraceFlags is empty' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags = @()
                    }
                }

                It 'Should return false when Traceflags on the instance exist' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and TraceFlags is empty' {
                BeforeAll {
                    $testParameters = $mockInst00Parameters
                    $testParameters += @{
                        TraceFlags = @()
                    }
                }

                It 'Should return true when no Traceflags on the instance exist' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags = '3228'
                    }
                }

                It 'Should return false when Traceflags do not match the actual TraceFlags' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToInclude are not in the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlagsToInclude = '3228'
                    }
                }

                It 'Should return false when TraceflagsToInclude are not in the actual TraceFlags' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present and `$TraceFlagsToInclude are in the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlagsToInclude = '3226'
                    }
                }

                It 'Should return false when TraceflagsToInclude are in the actual TraceFlags' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToExclude are in the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlagsToExclude = '3226'
                    }
                }

                It 'Should return false when TraceflagsToExclude are in the actual TraceFlags' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present and `$TraceFlagsToExclude are not in the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlagsToExclude = '3228'
                    }
                }

                It 'Should return true when TraceflagsToExclude are not in the actual TraceFlags' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }


            Context 'When both the parameters TraceFlags and TraceFlagsToInclude are assigned a value.' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags          = '3228'
                        TraceFlagsToInclude = '3228'
                    }
                }

                It 'Should throw the correct error' {
                    { Test-TargetResource @testParameters } | Should -Throw '(DRC0010)'
                }

                It 'Should not be executed' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When both the parameters TraceFlags and TraceFlagsToExclude are assigned a value.' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags          = '3228'
                        TraceFlagsToExclude = '3228'
                    }
                }

                It 'Should throw the correct error' {
                    { Test-TargetResource @testParameters } | Should -Throw '(DRC0010)'
                }

                It 'Should not be executed' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
                }
            }

        }

         Describe "DSC_SqlTraceFlag\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                        $mockServerName = 'TestServer'
                        $mockFakeServerName = 'FakeServer'
                        $mockInstanceName1 = 'MSSQLSERVER'
                        $mockInstanceName1Agent = 'SQLSERVERAGENT'
                        $mockInstanceName2 = 'INST00'
                        $mockInstanceName2Agent = 'SQLAgent$INST00'
                        $mockInstanceName3 = 'INST01'
                        $mockInstanceName3Agent = 'SQLAgent$INST01'

                        $mockInvalidOperationForAlterMethod = $false

                        $mockServerInstances = [System.Collections.ArrayList]::new()
                        $mockServerInstances.Add($mockInstanceName1) | Out-Null
                        $mockServerInstances.Add($mockInstanceName2) | Out-Null

                         # The Trailing spaces in these here strings are ment to be there. Do not remove!
                        $mockStartupParametersInstance1 = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802
"@
                        $mockStartupParametersInstance2 = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@

                        # Default parameters that are used for the It-blocks
                        $mockDefaultParameters1 = @{
                            InstanceName = $mockInstanceName1
                            ServerName   = $mockServerName
                        }

                        $mockInst00Parameters = @{
                            InstanceName = $mockInstanceName2
                            ServerName   = $mockServerName
                        }

                        $mockInst01Parameters = @{
                            InstanceName = $mockInstanceName3
                            ServerName   = $mockServerName
                        }

                        $mockNonExistServerParameters = @{
                            InstanceName = $mockInstanceName1
                            ServerName   = $mockFakeServerName
                        }

                        $mockNewObject_ParameterFilter_RealServerName = {
                            $ServerName -eq $mockServerName
                        }

                        $mockNewObject_ParameterFilter_FakeServerName = {
                            $ServerName -eq $mockFakeServerName
                        }

                        $script:mockMethodAlterRan = $false
                        $script:mockMethodAlterValue = ''

                        #region Function mocks
                        $mockSmoWmiManagedComputer = {
                            $mockServerObjectHashtable = @{
                                State = "Existing"
                                Name = $mockServerName
                                ServerInstances = $mockServerInstances
                            }

                            class service
                            {
                                [string]$Name
                                [string]$ServiceState
                                [string]$StartupParameters
                            }

                            $Services = [System.Collections.ArrayList]::new()

                            $service1 = [service]::new()
                            $service1.Name = $mockInstanceName1
                            $service1.ServiceState = "Running"
                            $service1.StartupParameters = $mockStartupParametersInstance1

                            $Services.Add($service1) | Out-Null

                            $service2 = [service]::new()
                            $service2.Name = $mockInstanceName1Agent
                            $service2.ServiceState = "Running"
                            $service2.StartupParameters = ""

                            $Services.Add($service2) | Out-Null

                            $service3 = [service]::new()
                            $service3.Name = 'MSSQL${0}' -f $mockInstanceName2
                            $service3.ServiceState = "Running"
                            $service3.StartupParameters = $mockStartupParametersInstance2

                            $Services.Add($service3) | Out-Null

                            $service4 = [service]::new()
                            $service4.Name = 'SQLAgent${0}' -f $mockInstanceName2Agent
                            $service4.ServiceState = "Stopped"
                            $service4.StartupParameters = ""

                            $Services.Add($service4) | Out-Null

                            $ServerServices = [System.Collections.ArrayList]::new()

                            foreach ($mockService in $Services)
                            {
                                $mockService | Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                    $script:mockMethodAlterRan = $true
                                    $script:mockMethodAlterValue = $this.StartupParameters
                                } -PassThru
                                $ServerServices.Add( $mockService) | Out-Null
                            }

                            $mockServerObjectHashtable += @{
                                Services = $ServerServices
                            }
                            $mockServerObject = [PSCustomObject]$mockServerObjectHashtable

                            return @($mockServerObject)
                        }
                Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer -Verifiable
                Mock -CommandName Restart-SqlService -ModuleName $script:dscResourceName -Verifiable
                Mock -CommandName Import-SQLPSModule
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags = @()
                    }
                }

                It 'Should not throw when calling the alter method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodAlterRan | Should -BeTrue -Because 'Alter should run'
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@ -Because 'Alter must change the value correct'

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
                }

            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags = '3228'
                    }
                }

                It 'Should not throw when calling the alter method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodAlterRan | Should -BeTrue -Because 'Alter should run'
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
"@ -Because 'Alter must change the value correct'

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToInclude is not in TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlagsToInclude = '3228'
                    }
                }

                It 'Should not throw when calling the alter method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802;-T3228
"@

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToExclude is in TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlagsToExclude = '1802'
                    }
                }

                It 'Should not throw when calling the alter method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226
"@

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags = '3228'
                        RestartService = $true
                    }
                }

                It 'Should not throw when calling the restart method' {
                    { Set-TargetResource @testParameters  } | Should -Not -Throw
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
"@

                    Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both the parameters TraceFlags and TraceFlagsToInclude are assigned a value.' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags          = '3228'
                        TraceFlagsToInclude = '3228'
                    }
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters} | Should -Throw '(DRC0010)'
                }

                It 'Should not be executed' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When both the parameters TraceFlags and TraceFlagsToExclude are assigned a value.' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        TraceFlags          = '3228'
                        TraceFlagsToExclude = '3228'
                    }
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should -Throw '(DRC0010)'
                }

                It 'Should not be executed' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
                }
            }

            Context 'For a nonexist instance' {
                BeforeAll {
                    $testParameters = $mockInst01Parameters
                }
                It 'Should throw for incorect parameters' {
                    {Set-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to WMI information '{0}' in '{1}'." -f $mockInstanceName3, $mockServerName)
                }
            }

            Context 'For a nonexist server' {
                BeforeAll {
                    $testParameters = $mockNonExistServerParameters
                    Mock -CommandName New-Object -MockWith {
                        return $null
                    } -ParameterFilter $mockNewObject_ParameterFilter_FakeServerName -Verifiable
                }
                It 'Should throw for incorect parameters' {
                    {Set-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to ComputerManagement '{0}'." -f $mockFakeServerName)
                }
            }
        }

    }
}
finally
{
    Invoke-TestCleanup
}
