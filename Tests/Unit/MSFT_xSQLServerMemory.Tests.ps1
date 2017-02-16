$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerMemory'

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
    Add-Type -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    $serverName     = 'SQL01'
    $instanceName   = 'MSSQLSERVER'

    $defaultParameters = @{
        SQLInstanceName = $instanceName
        SQLServer       = $serverName
    }
    
    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [PSCustomObject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MinServerMemory = @{
                        DisplayName = 'min server memory (MB)'
                        Description = 'Minimum size of server memory (MB)'
                        RunValue    = 2048
                        ConfigValue = 2048
                    }
                    MaxServerMemory = @{
                        DisplayName = 'max server memory (MB)'
                        Description = 'Maximum size of server memory (MB)'
                        RunValue    = 10300
                        ConfigValue = 10300
                    }
                }
            }

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is either in the desired state or not in the desired state' {
            $testParameters = $defaultParameters

            $result = Get-TargetResource @testParameters

            It 'Should return the current value for MinMemory' {
                $result.MinMemory | Should Be 2048
            }
            
            It 'Should return the current value for MaxMemory' {
                $result.MaxMemory | Should Be 10300
            }

            It 'Should return the same values as passed as parameters' {
                $result.SQLServer | Should Be $testParameters.SQLServer
                $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Assert-VerifiableMocks
    }
    
    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [PSCustomObject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MinServerMemory = @{
                        DisplayName = 'min server memory (MB)'
                        Description = 'Minimum size of server memory (MB)'
                        RunValue    = 0
                        ConfigValue = 0
                    }
                    MaxServerMemory = @{
                        DisplayName = 'max server memory (MB)'
                        Description = 'Maximum size of server memory (MB)'
                        RunValue    = 10300
                        ConfigValue = 10300
                    }
                }
            }

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Mock -CommandName Get-CimInstance -MockWith {
            $mockGetCimInstanceMem = @()

            $mockGetCimInstanceMem += New-Object -TypeName psobject -Property @{
                Name = 'Physical Memory'
                Tag = 'Physical Memory 0'
                Capacity = 8589934592
            }
            
            $mockGetCimInstanceMem += New-Object -TypeName psobject -Property @{
                Name = 'Physical Memory'
                Tag = 'Physical Memory 1'
                Capacity = 8589934592
            }  
            
            $mockGetCimInstanceMem 
        } -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' } -ModuleName $script:DSCResourceName -Verifiable  

        Mock -CommandName Get-CimInstance -MockWith {
            $mockGetCimInstanceProc = [PSCustomObject]@{
                NumberOfCores = 2
            }
            
            $mockGetCimInstanceProc 
        } -ParameterFilter { $ClassName -eq 'Win32_Processor' } -ModuleName $script:DSCResourceName -Verifiable        

        Mock -CommandName Get-CimInstance -MockWith {
            $mockGetCimInstanceOS = [PSCustomObject]@{
                OSArchitecture = '64-bit'
            }
            
            $mockGetCimInstanceOS 
        } -ParameterFilter { $ClassName -eq 'Win32_operatingsystem' } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure          = 'Present'
                MinMemory       = 1024
                MaxMemory       = 8192
                DynamicAlloc    = $false
            }      

            It 'Should return the state as false when desired MinMemory and MaxMemory are not present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is not in the desired state and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure          = 'Present'
                MaxMemory       = 8192
                DynamicAlloc    = $false
            }      

            It 'Should return the state as false when desired MaxMemory is not present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is in the desired state and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure          = 'Present'
                MinMemory       = 0
                MaxMemory       = 10300
                DynamicAlloc    = $false
            }      

            It 'Should return the state as true when desired MinMemory and MaxMemory are present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the MaxMemory parameter is not null and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxMemory       = 8192
                DynamicAlloc    = $true
                Ensure          = 'Present'
            }

            It 'Should throw the correct error' {
                { Test-TargetResource @testParameters } | Should Throw 'The parameter MaxMemory must be null when DynamicAlloc is set to true.'
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
                        
            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the MaxMemory parameter is null and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc    = $false
                Ensure          = 'Present'
            }

            It 'Should throw the correct error' {
                {Test-TargetResource @testParameters } | Should Throw 'The parameter MaxMemory must not be null when DynamicAlloc is set to false.'
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
                        
            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }
        
        Context 'When the system is not in the desired state and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure          = 'Present'
                DynamicAlloc    = $true
            }      

            It 'Should return the state as false when desired MinMemory and MaxMemory are not present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_PhysicalMemory'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_Processor'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_operatingsystem'
                } -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [PSCustomObject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MinServerMemory = @{
                        DisplayName = 'min server memory (MB)'
                        Description = 'Minimum size of server memory (MB)'
                        RunValue    = 0
                        ConfigValue = 0
                    }
                    MaxServerMemory = @{
                        DisplayName = 'max server memory (MB)'
                        Description = 'Maximum size of server memory (MB)'
                        RunValue    = 12083
                        ConfigValue = 12083
                    }
                }
            }

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is in the desired state and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure          = 'Present'
                DynamicAlloc    = $true
            }      

            It 'Should return the state as true when desired MinMemory and MaxMemory are present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_PhysicalMemory'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_Processor'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_operatingsystem'
                } -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [PSCustomObject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MinServerMemory = @{
                        DisplayName = 'min server memory (MB)'
                        Description = 'Minimum size of server memory (MB)'
                        RunValue    = 1024
                        ConfigValue = 1024
                    }
                    MaxServerMemory = @{
                        DisplayName = 'max server memory (MB)'
                        Description = 'Maximum size of server memory (MB)'
                        RunValue    = 8192
                        ConfigValue = 8192
                    }
                }
            }

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state and Ensure is set to Absent' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure          = 'Absent'
            }      

            It 'Should return the state as false when desired MinMemory and MaxMemory are not set to the default values' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [PSCustomObject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MinServerMemory = @{
                        DisplayName = 'min server memory (MB)'
                        Description = 'Minimum size of server memory (MB)'
                        RunValue    = 0
                        ConfigValue = 0
                    }
                    MaxServerMemory = @{
                        DisplayName = 'max server memory (MB)'
                        Description = 'Maximum size of server memory (MB)'
                        RunValue    = 2147483647
                        ConfigValue = 2147483647
                    }
                }
            }
            
            # Add the Alter method
            $mockSqlServerObject | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is in the desired state and Ensure is set to Absent' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure          = 'Absent'
            }      

            It 'Should return the state as true when desired MinMemory and MaxMemory are present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Assert-VerifiableMocks
    }
    
    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [PSCustomObject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MinServerMemory = @{
                        DisplayName = 'min server memory (MB)'
                        Description = 'Minimum size of server memory (MB)'
                        RunValue    = 0
                        ConfigValue = 0
                    }
                    MaxServerMemory = @{
                        DisplayName = 'max server memory (MB)'
                        Description = 'Maximum size of server memory (MB)'
                        RunValue    = 10300
                        ConfigValue = 10300
                    }
                }
            }
            
            # Add the Alter method
            $mockSqlServerObject | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Mock -CommandName Get-CimInstance -MockWith {
            $mockGetCimInstanceMem = @()

            $mockGetCimInstanceMem += New-Object -TypeName psobject -Property @{
                Name = 'Physical Memory'
                Tag = 'Physical Memory 0'
                Capacity = 17179869184
            }
            
            $mockGetCimInstanceMem += New-Object -TypeName psobject -Property @{
                Name = 'Physical Memory'
                Tag = 'Physical Memory 1'
                Capacity = 17179869184
            }  
            
            $mockGetCimInstanceMem 
        } -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' } -ModuleName $script:DSCResourceName -Verifiable  

        Mock -CommandName Get-CimInstance -MockWith {
            $mockGetCimInstanceProc = [PSCustomObject]@{
                NumberOfCores = 6
            }
            
            $mockGetCimInstanceProc 
        } -ParameterFilter { $ClassName -eq 'Win32_Processor' } -ModuleName $script:DSCResourceName -Verifiable        

        Mock -CommandName Get-CimInstance -MockWith {
            $mockGetCimInstanceOS = [PSCustomObject]@{
                OSArchitecture = 'IA64-bit'
            }
            
            $mockGetCimInstanceOS 
        } -ParameterFilter { $ClassName -eq 'Win32_operatingsystem' } -ModuleName $script:DSCResourceName -Verifiable   

        Context 'When the MaxMemory parameter is not null and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxMemory       = 8192
                DynamicAlloc    = $true
                Ensure          = 'Present'
            }

            It 'Should throw the correct error' {
                { Set-TargetResource @testParameters } | Should Throw 'The parameter MaxMemory must be null when DynamicAlloc is set to true.'
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
                        
            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the MaxMemory parameter is null and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc    = $false
                Ensure          = 'Present'
            }

            It 'Should throw the correct error' {
                { Set-TargetResource @testParameters } | Should Throw 'The parameter MaxMemory must not be null when DynamicAlloc is set to false.'
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
                        
            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is not in the desired state and Ensure is set to Absent' {
            $testParameters = $defaultParameters
            $testParameters += @{
                Ensure = 'Absent'
            }

            It 'Should set the MinMemory and MaxMemory to the default values' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
            
            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system is not in the desired state and Ensure is set to Present, and DynamicAlloc is set to false' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxMemory       = 8192
                MinMemory       = 1024
                DynamicAlloc    = $false
                Ensure          = 'Present'
            }

            It 'Should set the MinMemory and MaxMemory to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to false' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Context 'When the system (OS IA64-bit) is not in the desired state and Ensure is set to Present, and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc    = $true
                Ensure          = 'Present'
            }      

            It 'Should set the MaxMemory to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to true' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_PhysicalMemory'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_Processor'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_operatingsystem'
                } -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Mock -CommandName Get-CimInstance -MockWith {
            $mockGetCimInstanceOS = [PSCustomObject]@{
                OSArchitecture = '32-bit'
            }
            
            $mockGetCimInstanceOS 
        } -ParameterFilter { $ClassName -eq 'Win32_operatingsystem' } -ModuleName $script:DSCResourceName -Verifiable   
        
        Context 'When the system (OS 32-bit) is not in the desired state and Ensure is set to Present, and DynamicAlloc is set to true' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc    = $true
                Ensure          = 'Present'
            }      

            It 'Should set the MaxMemory to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to true' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_PhysicalMemory'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_Processor'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_operatingsystem'
                } -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Mock -CommandName Connect-SQL -MockWith {
            $mockSqlServerObject = [PSCustomObject]@{
                InstanceName                = $instanceName
                ComputerNamePhysicalNetBIOS = $serverName
                Configuration = @{
                    MinServerMemory = @{
                        DisplayName = 'min server memory (MB)'
                        Description = 'Minimum size of server memory (MB)'
                        RunValue    = 0
                        ConfigValue = 0
                    }
                    MaxServerMemory = @{
                        DisplayName = 'max server memory (MB)'
                        Description = 'Maximum size of server memory (MB)'
                        RunValue    = 10300
                        ConfigValue = 10300
                    }
                }
            }
            
            # Add the Alter method
            $mockSqlServerObject | Add-Member -MemberType ScriptMethod -Name Alter -Value {
                throw 'Mock Alter Method was called with invalid operation.'
            }

            $mockSqlServerObject
        } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the desired MinMemory and MaxMemory fails to be set' {
            $testParameters = $defaultParameters
            $testParameters += @{
                MaxMemory       = 8192
                MinMemory       = 1024
                DynamicAlloc    = $false
                Ensure          = 'Present'
            }

            It 'Should throw the correct error' {                
                { Set-TargetResource @testParameters } | Should Throw ("Failed to alter the server configuration memory for $serverName" + "\" +`                                                                       "$instanceName. InnerException: Exception calling ""Alter"" with ""0"" argument(s): " + `                                                                       """Mock Alter Method was called with invalid operation.""")
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should not call the mock function Get-CimInstance' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope Context
            }
        }

        Mock -CommandName Get-CimInstance -MockWith {
            throw
        } -ParameterFilter { $ClassName -eq 'Win32_operatingsystem' } -ModuleName $script:DSCResourceName -Verifiable  
        
        Context 'When the Get-SqlDscDynamicMaxMemory fails to calculate the MaxMemory' {
            $testParameters = $defaultParameters
            $testParameters += @{
                DynamicAlloc    = $true
                Ensure          = 'Present'
            }

            It 'Should throw the correct error' {                
                { Set-TargetResource @testParameters } | Should Throw 'Failed to calculate dynamically the maximum memory.'
            }

            It 'Should call the mock function Connect-SQL' {
                Assert-MockCalled Connect-SQL -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_PhysicalMemory' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_PhysicalMemory'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_Processor'
                } -ModuleName $script:DSCResourceName -Scope Context
            }

            It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_operatingsystem' {
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                    $ClassName -eq 'Win32_operatingsystem'
                } -ModuleName $script:DSCResourceName -Scope Context
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
