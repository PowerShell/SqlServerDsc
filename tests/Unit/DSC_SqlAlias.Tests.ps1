<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlAlias DSC resource.

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
$script:dscResourceName = 'MSFT_SqlAlias'

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
        $registryPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
        $registryPathWow6432Node = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'

        $name = 'MyAlias'
        $serverNameTcp = 'sqlnode.company.local'
        $tcpPort = 1433
        $UseDynamicTcpPort = $false
        $serverNameNamedPipes = 'sqlnode'
        $pipeName = "\\$serverNameNamedPipes\PIPE\sql\query"

        $unknownName = 'UnknownAlias'
        $unknownServerName = 'unknownserver'

        $nameDifferentTcpPort = 'DifferentTcpPort'
        $nameDifferentServerNameTcp = 'DifferentServerNameTcp'
        $nameDifferentPipeName = 'DifferentPipeName'
        $differentTcpPort = 1500
        $differentServerNameTcp = "$unknownServerName.company.local"
        $differentPipeName = "\\$unknownServerName\PIPE\sql\query"

        $nameWow6432NodeDifferFrom64BitOS = 'Wow6432NodeDifferFrom64BitOS'

        $defaultParameters = @{
            Name = $name
            ServerName = $serverNameTcp
            Protocol = 'TCP'
            TcpPort = '1433'
            Ensure = 'Present'
        }

        Describe 'SqlAlias\Get-TargetResource' {
            # Mocking for protocol TCP
            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
                return $null
            } -Verifiable

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is in the desired present state for 64-bit OS using TCP' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameTcp
                }

                $result = Get-TargetResource @testParameters


                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return TCP as the protocol used' {
                    $result.Protocol | Should -Be 'TCP'
                }

                It "Should return $tcpPort as the port number used" {
                    $result.TcpPort | Should -Be $tcpPort
                }

                It 'Should not return any pipe name' {
                    $result.PipeName | Should -Be ''
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired absent state for 64-bit OS' {
                $testParameters = @{
                    Name = $unknownName
                    ServerName = $unknownServerName
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as absent' {
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should not return any protocol' {
                    $result.Protocol | Should -Be ''
                }

                It 'Should not return a port number' {
                    $result.TcpPort | Should -Be 0
                }

                It 'Should not return any pipe name' {
                    $result.PipeName | Should -Be ''
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state because TcpPort is different when desired protocol is TCP' {
                $testParameters = @{
                    Name = $nameDifferentTcpPort
                    ServerName = $serverNameTcp
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return TCP as the protocol used' {
                    $result.Protocol | Should -Be 'TCP'
                }

                It "Should return $differentTcpPort as the port number used" {
                    $result.TcpPort | Should -Be $differentTcpPort
                }

                It 'Should not return any pipe name' {
                    $result.PipeName | Should -Be ''
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state because ServerName is different when desired protocol is TCP' {
                $testParameters = @{
                    Name = $nameDifferentServerNameTcp
                    ServerName = $serverNameTcp
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                }

                It 'Should return different server name than the one passed as parameter' {
                    $result.ServerName | Should -Be $differentServerNameTcp
                }

                It 'Should return TCP as the protocol used' {
                    $result.Protocol | Should -Be 'TCP'
                }

                It "Should return $tcpPort as the port number used" {
                    $result.TcpPort | Should -Be $tcpPort
                }

                It 'Should not return any pipe name' {
                    $result.PipeName | Should -Be ''
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired present state for 64-bit OS using UseDynamicTcpPort' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameTcp
                }

                # Testing protocol TCP "With Dynamically determine port"
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                    return @{
                        'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                    }
                } -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                    return @{
                        'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                    }
                } -Verifiable

                # Mocking 64-bit OS
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return TCP as the protocol used' {
                    $result.Protocol | Should -Be 'TCP'
                }

                It 'Should return the UseDynamicTcpPort parameter as false' {
                    $result.UseDynamicTcpPort | Should -Be $false
                }

                It "Should not return any pipe name" {
                    $result.PipeName | Should -Be ''
                }

                It 'Should not return any TCP Port' {
                    $result.TcpPort | Should -Be 1433
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            # Mocking 32-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '32-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is in the desired present state for 32-bit OS using TCP' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameTcp
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.Protocol | Should -Be $defaultParameters.Protocol
                    $result.TcpPort | Should -Be $defaultParameters.TcpPort
                }

                It 'Should not return any pipe name' {
                    $result.PipeName | Should -Be ''
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the Get-ItemProperty for the Wow6432Node-path' {
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the system is in the desired present state for 32-bit OS using UseDynamicTcpPort' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameTcp
                }

                # Testing protocol TCP "With Dynamically determine port"
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                    return @{
                        'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                    }
                } -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                    return @{
                        'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                    }
                } -Verifiable

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return TCP as the protocol used' {
                    $result.Protocol | Should -Be 'TCP'
                }

                It 'Should return the UseDynamicTcpPort parameter as false' {
                    $result.UseDynamicTcpPort | Should -Be $false
                }

                It "Should not return any pipe name" {
                    $result.PipeName | Should -Be ''
                }

                It 'Should not return any TCP Port' {
                    $result.TcpPort | Should -Be 1433
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the Get-ItemProperty for the Wow6432Node-path' {
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When the system is in the desired absent state for 32-bit OS' {
                $testParameters = @{
                    Name = $unknownName
                    ServerName = $unknownServerName
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as absent' {
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should not return any protocol' {
                    $result.Protocol | Should -Be ''
                }

                It 'Should not return a port number' {
                    $result.TcpPort | Should -Be 0
                }

                It 'Should not return any pipe name' {
                    $result.PipeName | Should -Be ''
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the Get-ItemProperty for the Wow6432Node-path' {
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 0 -Scope Context
                }
            }

            # Testing protocol NP (Named Pipes)
            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentPipeName } -MockWith {
                return @{
                    'DifferentPipeName' = 'DBNMPNTW,\\unknownserver\PIPE\sql\query'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentPipeName } -MockWith {
                return @{
                    'DifferentPipeName' = 'DBNMPNTW,\\unknownserver\PIPE\sql\query'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameWow6432NodeDifferFrom64BitOS } -MockWith {
                return @{
                    'Wow6432NodeDifferFrom64BitOS' = 'DBNMPNTW,\\firstserver\PIPE\sql\query'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameWow6432NodeDifferFrom64BitOS } -MockWith {
                return @{
                    'Wow6432NodeDifferFrom64BitOS' = 'DBNMPNTW,\\secondserver\PIPE\sql\query'
                }
            } -Verifiable

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is in the desired present state for 64-bit OS using Named Pipes' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameNamedPipes
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return NP as the protocol used' {
                    $result.Protocol | Should -Be 'NP'
                }

                It 'Should not return a port number' {
                    $result.TcpPort | Should -Be 0
                }

                It 'Should return the correct pipe name based on the passed ServerName parameter' {
                    $result.PipeName | Should -Be "\\$serverNameNamedPipes\PIPE\sql\query"
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state because ServerName is different when desired protocol is Named Pipes' {
                $testParameters = @{
                    Name = $nameDifferentPipeName
                    ServerName = $serverNameNamedPipes
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return NP as the protocol used' {
                    $result.Protocol | Should -Be 'NP'
                }

                It 'Should not return a port number' {
                    $result.TcpPort | Should -Be 0
                }

                It 'Should return the correct pipe name based on the passed ServerName parameter' {
                    $result.PipeName | Should -Be $differentPipeName
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the state differ between 32-bit OS and 64-bit OS registry keys' {
                $testParameters = @{
                    Name = $nameWow6432NodeDifferFrom64BitOS
                    ServerName = $serverNameNamedPipes
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as absent' {
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should not return any protocol' {
                    $result.Protocol | Should -Be ''
                }

                It 'Should not return a port number' {
                    $result.TcpPort | Should -Be 0
                }

                It 'Should not return any pipe name' {
                    $result.PipeName | Should -Be ''
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            # Mocking 32-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '32-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is in the desired present state for 32-bit OS using Named Pipes' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameNamedPipes
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return NP as the protocol used' {
                    $result.Protocol | Should -Be 'NP'
                }

                It 'Should not return a port number' {
                    $result.TcpPort | Should -Be 0
                }

                It 'Should return the correct pipe name based on the passed ServerName parameter' {
                    $result.PipeName | Should -Be $pipeName
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the Get-ItemProperty for the Wow6432Node-path' {
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 0 -Scope Context
                }
            }

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is in the desired present state for 64-bit OS using UseDynamicTcpPort' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameTcp
                }

                # Testing protocol TCP "With Dynamically determine port"
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                    return @{
                        'MyAlias' = 'DBMSSOCN,sqlnode.company.local'
                    }
                } -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                    return @{
                        'MyAlias' = 'DBMSSOCN,sqlnode.company.local'
                    }
                } -Verifiable

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return TCP as the protocol used' {
                    $result.Protocol | Should -Be 'TCP'
                }

                It 'Should return the UseDynamicTcpPort parameter as true' {
                    $result.UseDynamicTcpPort | Should -Be $true
                }

                It "Should not return any pipe name" {
                    $result.PipeName | Should -Be ''
                }

                It 'Should not return any TCP Port' {
                    $result.TcpPort | Should -Be 0
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            # Mocking 32-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '32-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is in the desired present state for 32-bit OS using UseDynamicTcpPort' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameTcp
                }

                # Testing protocol TCP "With Dynamically determine port"
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                    return @{
                        'MyAlias' = 'DBMSSOCN,sqlnode.company.local'
                    }
                } -Verifiable

                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                    return @{
                        'MyAlias' = 'DBMSSOCN,sqlnode.company.local'
                    }
                } -Verifiable

                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Name | Should -Be $testParameters.Name
                    $result.ServerName | Should -Be $testParameters.ServerName
                }

                It 'Should return TCP as the protocol used' {
                    $result.Protocol | Should -Be 'TCP'
                }

                It 'Should return the UseDynamicTcpPort parameter as true' {
                    $result.UseDynamicTcpPort | Should -Be $true
                }

                It "Should not return any pipe name" {
                    $result.PipeName | Should -Be ''
                }

                It 'Should not return any TCP Port' {
                    $result.TcpPort | Should -Be 0
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the Get-ItemProperty for the Wow6432Node-path' {
                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 0 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe 'SqlAlias\Set-TargetResource' {
            Mock -CommandName New-Item -Verifiable
            Mock -CommandName Set-ItemProperty -Verifiable
            Mock -CommandName Remove-ItemProperty -Verifiable
            Mock -CommandName Test-Path -MockWith {
                return $false
            } -Verifiable

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is not in the desired state for 64-bit OS using TCP' {
                It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty twice each when desired state should be present for protocol TCP' {
                    $testParameters = @{
                        Name = $name
                        Protocol = 'TCP'
                        ServerName = $serverNameTcp
                        TcpPort = $tcpPort
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName New-Item -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 2 -Scope It
                }

                It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty twice each when desired state should be present for protocol Named Pipes' {
                    $testParameters = @{
                        Name = $name
                        Protocol = 'NP'
                        ServerName = $serverNameNamedPipes
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName New-Item -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 2 -Scope It
                }

                It 'Should call mocked functions Test-Path and Remove-ItemProperty twice each when desired state should be absent for 64-bit OS' {
                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    } -Verifiable

                    $testParameters = @{
                        Ensure = 'Absent'
                        Name = $name
                        ServerName = $serverNameTcp
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName Remove-ItemProperty -Exactly 2 -Scope It
                }
            }

            Context 'When the system is not in the desired state for 64-bit OS using UseDynamicTcpPort' {
                It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty twice each when desired state should be present for protocol TCP' {
                    $testParameters = @{
                        Name = $name
                        Protocol = 'TCP'
                        ServerName = $serverNameTcp
                        UseDynamicTcpPort = $true
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName New-Item -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 2 -Scope It
                }

                It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty twice each when desired state should be present for protocol Named Pipes' {
                    $testParameters = @{
                        Name = $name
                        Protocol = 'NP'
                        ServerName = $serverNameNamedPipes
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName New-Item -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 2 -Scope It
                }

                It 'Should call mocked functions Test-Path and Remove-ItemProperty twice each when desired state should be absent for 64-bit OS' {
                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    } -Verifiable

                    $testParameters = @{
                        Ensure = 'Absent'
                        Name = $name
                        ServerName = $serverNameTcp
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 2 -Scope It
                    Assert-MockCalled -CommandName Remove-ItemProperty -Exactly 2 -Scope It
                }
            }

            # Mocking 32-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '32-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is not in the desired state for 32-bit OS using TCP' {
                It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty once each when desired state should be present for protocol TCP' {
                    $testParameters = @{
                        Name = $name
                        Protocol = 'TCP'
                        ServerName = $serverNameTcp
                        TcpPort = $tcpPort
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName New-Item -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1 -Scope It
                }

                It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty once each when desired state should be present for protocol Named Pipes' {
                    $testParameters = @{
                        Name = $name
                        Protocol = 'NP'
                        ServerName = $serverNameNamedPipes
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName New-Item -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1 -Scope It
                }

                It 'Should call mocked functions Test-Path and Remove-ItemProperty once each when desired state should be absent for 32-bit OS' {
                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    } -Verifiable

                    $testParameters = @{
                        Ensure = 'Absent'
                        Name = $name
                        ServerName = $serverNameNamedPipes
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName Remove-ItemProperty -Exactly 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state for 32-bit OS using UseDynamicTcpPort' {
                It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty once each when desired state should be present for protocol TCP' {
                    $testParameters = @{
                        Name = $name
                        Protocol = 'TCP'
                        ServerName = $serverNameTcp
                        UseDynamicTcpPort = $true
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName New-Item -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1 -Scope It
                }

                It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty once each when desired state should be present for protocol Named Pipes' {
                    $testParameters = @{
                        Name = $name
                        Protocol = 'NP'
                        ServerName = $serverNameNamedPipes
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName New-Item -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName Set-ItemProperty -Exactly 1 -Scope It
                }

                It 'Should call mocked functions Test-Path and Remove-ItemProperty once each when desired state should be absent for 32-bit OS' {
                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    } -Verifiable

                    $testParameters = @{
                        Ensure = 'Absent'
                        Name = $name
                        ServerName = $serverNameNamedPipes
                    }

                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Test-Path -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName Remove-ItemProperty -Exactly 1 -Scope It
                }
            }
        }

        Describe 'SqlAlias\Test-TargetResource' {
            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
                return $null
            } -Verifiable

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'When the system is in the desired state (Absent)' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    }

                    $testParameters = @{
                        Ensure = 'Absent'
                        Name = $name
                        ServerName = $serverNameTcp
                    }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParameters | Should -Be $true

                    Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state (when using TCP)' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameTcp
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParameters | Should -Be $true
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state (when using UseDynamicTcpPort)' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameTcp
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParameters | Should -Be $true
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state (when using TCP)' {
                $testParameters = @{
                    Name = $unknownName
                    ServerName = $serverNameTcp
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state (when using UseDynamicTcpPort)' {
                $testParameters = @{
                    Name = $unknownName
                    ServerName = $serverNameTcp
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
                return $null
            } -Verifiable

            Context 'When the system is in the desired state (when using Named Pipes)' {
                $testParameters = @{
                    Name = $name
                    ServerName = $serverNameNamedPipes
                }

                It "Should return true from the test method" {
                    $testParameters.Add('Protocol','NP')
                    Test-TargetResource @testParameters | Should -Be $true
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state (when using Named Pipes)' {
                $testParameters = @{
                    Name = $unknownName
                    ServerName = $unknownServerName
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should call the mocked functions exactly 1 time each' {
                    Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
                        -Exactly -Times 1 -Scope Context

                    Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
                        -Exactly -Times 1 -Scope Context
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
