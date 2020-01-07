<#
    .N<#
    .SYNOPSIS
        Automated unit test for DSC_SqlServerReplication DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName   = 'SqlServerDSC'
$script:dscResourceName = 'DSC_SqlServerReplication'

$script:timer = [System.Diagnostics.Stopwatch]::StartNew()

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

try
{
    InModuleScope $script:dscResourceName {
        Describe 'Helper functions' {
            Context 'Get-SqlServerMajorVersion' {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return [PSCustomObject] @{
                        MSSQLSERVER = 'MSSQL12.MSSQLSERVER'
                    }
                } -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
                }

                It 'Should return correct major version for default instance' {
                    Mock -CommandName Get-ItemProperty -MockWith {
                        return [PSCustomObject] @{
                            Version = '12.1.4100.1'
                        }
                    } -ParameterFilter {
                        $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\Setup'
                    }

                    Get-SqlServerMajorVersion -InstanceName 'MSSQLSERVER' | Should -Be '12'
                }

                It 'Should throw error if major version cannot be resolved' {

                    Mock -CommandName Get-ItemProperty -MockWith {
                        return [PSCustomObject] @{
                            Version = ''
                        }
                    } -ParameterFilter {
                        $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\Setup'
                    }

                    { Get-SqlServerMajorVersion -InstanceName 'MSSQLSERVER' } | Should -Throw ($script:localizedData.FailedToDetectSqlVersion -f 'MSSQLSERVER')
                }
            }

            Context 'Get-SqlLocalServerName' {

                It 'Should return COMPUTERNAME given MSSQLSERVER' {
                    Get-SqlLocalServerName -InstanceName MSSQLSERVER | Should -Be $env:COMPUTERNAME
                }

                It 'Should return COMPUTERNAME\InstanceName given InstanceName' {
                    Get-SqlLocalServerName -InstanceName InstanceName | Should -Be "$($env:COMPUTERNAME)\InstanceName"
                }

            }
        }

        $secpasswd = ConvertTo-SecureString 'P@$$w0rd1' -AsPlainText -Force
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('AdminLink', $secpasswd)

        Describe 'The system is not in the desired state given Local distribution mode' {
            BeforeAll {
                $testParameters = @{
                    InstanceName = 'MSSQLSERVER'
                    AdminLinkCredentials = $credentials
                    DistributorMode = 'Local'
                    WorkingDirectory = 'C:\Temp'
                }

                Mock -CommandName Get-SqlServerMajorVersion -MockWith { return '99' }
                Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME' }
                Mock -CommandName New-ServerConnection -MockWith {
                    return [PSCustomObject] @{
                        ServerInstance = $SqlServerName
                    }
                }
                Mock -CommandName New-ReplicationServer -MockWith {
                    return [PSCustomObject] @{
                        IsDistributor = $false
                        IsPublisher = $false
                        DistributionDatabase = ''
                        DistributionServer = 'SERVERNAME'
                        WorkingDirectory = ''
                    }
                }
                Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
                Mock -CommandName Install-LocalDistributor -MockWith { }
                Mock -CommandName Install-RemoteDistributor -MockWith { }
                Mock -CommandName Register-DistributorPublisher -MockWith { }
                Mock -CommandName Uninstall-Distributor -MockWith {}
            }

            Context 'The system is not in the desired state' {
                Context 'Get method' {
                    $result = Get-TargetResource @testParameters
                    It 'Get method calls Get-SqlServerMajorVersion with InstanceName = MSSQLSERVER' {
                        Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                            -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                    }
                    It 'Get method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                        Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                            -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                    }
                    It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                        Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                            -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
                    }
                    It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                        Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                            -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
                    }
                    It 'Get method does not call New-DistributionDatabase' {
                        Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                    }
                    It 'Get method does not call Install-LocalDistributor' {
                        Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                    }
                    It 'Get method does not call Install-RemoteDistributor' {
                        Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                    }
                    It 'Ger method does not call Register-DistributorPublisher' {
                        Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                    }
                    It 'Ger method does not call Uninstall-Distributor' {
                        Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                    }
                    It 'Get method returns Ensure = Absent' {
                        $result.Ensure | Should -Be 'Absent'
                    }
                    It "Get method returns InstanceName = $($testParameters.InstanceName)" {
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                    }
                    It 'Get method returns DistributorMode as $null' {
                        $result.DistributorMode | Should -BeNullOrEmpty
                    }
                    It 'Get method returns DistributionDBName as $null' {
                        $result.DistributionDBName | Should -BeNullOrEmpty
                    }
                    It 'Get method returns RemoteDistributor as $null' {
                        $result.RemoteDistributor | Should -BeNullOrEmpty
                    }
                    It 'Get method returns WorkingDirectory as $null' {
                        $result.WorkingDirectory | Should -BeNullOrEmpty
                    }
                }
            }

            Context 'Test method' {
                It 'Test method returns false' {
                    Test-TargetResource @testParameters | Should -Be $false
                }
            }

            Context 'Set method' {
                Set-TargetResource @testParameters
                It 'Set method calls Get-SqlServerMajorVersion with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Set method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
                }
                It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
                }
                It 'Set method calls New-DistributionDatabase with $DistributionDBName = distribution' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 1 `
                        -ParameterFilter { $DistributionDBName -eq 'distribution' }
                }
                It 'Set method calls Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 1 `
                        -ParameterFilter { $ReplicationServer.DistributionServer -eq 'SERVERNAME' }
                }
                It 'Set method calls Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 1 `
                        -ParameterFilter { $PublisherName -eq 'SERVERNAME' }
                }
                It 'Set method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Set method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
            }
        }

        Describe 'The system is not in the desired state given Remote distribution mode' {

            $testParameters = @{
                InstanceName = 'INSTANCENAME'
                AdminLinkCredentials = $credentials
                DistributorMode = 'Remote'
                RemoteDistributor = 'REMOTESERVER'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Present'
            }

            Mock -CommandName Get-SqlServerMajorVersion -MockWith { return '99' }
            Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME\INSTANCENAME' }
            Mock -CommandName New-ServerConnection -MockWith {
                return [PSCustomObject] @{
                    ServerInstance = $SqlServerName
                }
            }
            Mock -CommandName New-ReplicationServer -MockWith {
                return [PSCustomObject] @{
                    IsDistributor = $false
                    IsPublisher = $false
                    DistributionDatabase = ''
                    DistributionServer = ''
                    WorkingDirectory = ''
                }
            }
            Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
            Mock -CommandName Install-LocalDistributor -MockWith { }
            Mock -CommandName Install-RemoteDistributor -MockWith { }
            Mock -CommandName Register-DistributorPublisher -MockWith { }
            Mock -CommandName Uninstall-Distributor -MockWith {}

            Context 'The system is not in the desired state' {
                Context 'Get method' {
                    $result = Get-TargetResource @testParameters
                    It 'Get method calls Get-SqlServerMajorVersion with $InstanceName = INSTANCENAME' {
                        Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                            -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                    }
                    It 'Get method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
                        Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                            -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                    }
                    It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
                        Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                            -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
                    }
                    It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
                        Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                            -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
                    }
                    It 'Get method does not call New-DistributionDatabase' {
                        Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                    }
                    It 'Get method does not call Install-LocalDistributor' {
                        Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                    }
                    It 'Get method does not call Install-RemoteDistributor' {
                        Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                    }
                    It 'Ger method does not call Register-DistributorPublisher' {
                        Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                    }
                    It 'Ger method does not call Uninstall-Distributor' {
                        Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                    }
                    It 'Get method returns Ensure = Absent' {
                        $result.Ensure | Should -Be 'Absent'
                    }
                    It "Get method returns InstanceName = $($testParameters.InstanceName)" {
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                    }
                    It 'Get method returns DistributorMode as $null' {
                        $result.DistributorMode | Should -BeNullOrEmpty
                    }
                    It 'Get method returns DistributionDBName as $null' {
                        $result.DistributionDBName | Should -BeNullOrEmpty
                    }
                    It 'Get method returns RemoteDistributor as $null' {
                        $result.RemoteDistributor | Should -BeNullOrEmpty
                    }
                    It 'Get method returns WorkingDirectory as $null' {
                        $result.WorkingDirectory | Should -BeNullOrEmpty
                    }
                }
            }

            Context 'Test method' {
                It 'Test method returns false' {
                    Test-TargetResource @testParameters | Should -Be $false
                }
            }

            Context 'Set method' {
                Set-TargetResource @testParameters
                It 'Set method calls Get-SqlServerMajorVersion with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Set method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
                }
                It "Set method calls New-ServerConnection with $SqlServerName = $($testParameters.RemoteDistributor)" {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq $testParameters.RemoteDistributor }
                }
                It 'Set method calls Register-DistributorPublisher with RemoteDistributor connection' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 1 `
                        -ParameterFilter {
                            $PublisherName -eq 'SERVERNAME\INSTANCENAME' `
                            -and $ServerConnection.ServerInstance -eq $testParameters.RemoteDistributor
                        }
                }
                It 'Set method calls Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 1 `
                        -ParameterFilter { $RemoteDistributor -eq $testParameters.RemoteDistributor }
                }
                It 'Set method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Set method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
            }

            Context 'When calling the Set method with the ''Remote'' distributor mode, but does not provide the parameter RemoteDistributor'  {
                BeforeAll {
                    $testParameters.Remove('RemoteDistributor')
                }

                It 'Should throw the correct errror' {
                    { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.NoRemoteDistributor
                }
            }
        }

        Describe 'The system is in sync given Local distribution mode' {

            $testParameters = @{
                InstanceName = 'MSSQLSERVER'
                AdminLinkCredentials = $credentials
                DistributorMode = 'Local'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Present'
            }

            Mock -CommandName Get-SqlServerMajorVersion -MockWith { return '99' }
            Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME' }
            Mock -CommandName New-ServerConnection -MockWith {
                return [PSCustomObject] @{
                    ServerInstance = $SqlServerName
                }
            }
            Mock -CommandName New-ReplicationServer -MockWith {
                return [PSCustomObject] @{
                    IsDistributor = $true
                    IsPublisher = $true
                    DistributionDatabase = 'distribution'
                    DistributionServer = 'SERVERNAME'
                    WorkingDirectory = 'C:\temp'
                }
            }
            Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
            Mock -CommandName Install-LocalDistributor -MockWith { }
            Mock -CommandName Install-RemoteDistributor -MockWith { }
            Mock -CommandName Register-DistributorPublisher -MockWith { }
            Mock -CommandName Uninstall-Distributor -MockWith {}

            Context 'Get method' {
                $result = Get-TargetResource @testParameters
                It 'Get method calls Get-SqlServerMajorVersion with InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Get method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
                }
                It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
                }
                It 'Get method does not call New-DistributionDatabase' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Get method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Get method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Ger method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
                It 'Ger method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
                It 'Get method returns Ensure = Present' {
                    $result.Ensure | Should -Be 'Present'
                }
                It "Get method returns InstanceName = $($testParameters.InstanceName)" {
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }
                It "Get method returns DistributorMode = $($testParameters.DistributorMode)" {
                    $result.DistributorMode | Should -Be $testParameters.DistributorMode
                }
                It 'Get method returns DistributionDBName = distribution' {
                    $result.DistributionDBName | Should -Be 'distribution'
                }
                It 'Get method returns RemoteDistributor = SERVERNAME' {
                    $result.RemoteDistributor | Should -Be 'SERVERNAME'
                }
                It 'Get method returns WorkingDirectory = C:\temp' {
                    $result.WorkingDirectory | Should -Be 'C:\temp'
                }
            }

            Context 'Test method' {
                It 'Test method returns true' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'Set method' {
                Set-TargetResource @testParameters
                It 'Set method calls Get-SqlServerMajorVersion with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Set method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
                }
                It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
                }
                It 'Set method does not call New-DistributionDatabase with $DistributionDBName = distribution' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Set method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Set method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Set method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
                It 'Set method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
            }
        }

        Describe 'The system is in sync given Remote distribution mode' {

            $testParameters = @{
                InstanceName = 'INSTANCENAME'
                AdminLinkCredentials = $credentials
                DistributorMode = 'Remote'
                RemoteDistributor = 'REMOTESERVER'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Present'
            }

            Mock -CommandName Get-SqlServerMajorVersion -MockWith { return '99' }
            Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME\INSTANCENAME' }
            Mock -CommandName New-ServerConnection -MockWith {
                return [PSCustomObject] @{
                    ServerInstance = $SqlServerName
                }
            }
            Mock -CommandName New-ReplicationServer -MockWith {
                return [PSCustomObject] @{
                    IsDistributor = $false
                    IsPublisher = $true
                    DistributionDatabase = 'distribution'
                    DistributionServer = 'REMOTESERVER'
                    WorkingDirectory = 'C:\temp'
                }
            }
            Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
            Mock -CommandName Install-LocalDistributor -MockWith { }
            Mock -CommandName Install-RemoteDistributor -MockWith { }
            Mock -CommandName Register-DistributorPublisher -MockWith { }
            Mock -CommandName Uninstall-Distributor -MockWith {}

            Context 'Get method' {
                $result = Get-TargetResource @testParameters
                It 'Get method calls Get-SqlServerMajorVersion with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Get method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Get method does not call New-DistributionDatabase' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Get method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Get method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Ger method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
                It 'Ger method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
                It 'Get method returns Ensure = Present' {
                    $result.Ensure | Should -Be 'Present'
                }
                It "Get method returns InstanceName = $($testParameters.InstanceName)" {
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }
                It "Get method returns DistributorMode = $($testParameters.DistributorMode)" {
                    $result.DistributorMode | Should -Be $testParameters.DistributorMode
                }
                It 'Get method returns DistributionDBName = distribution' {
                    $result.DistributionDBName | Should -Be 'distribution'
                }
                It "Get method returns RemoteDistributor = $($testParameters.RemoteDistributor)" {
                    $result.RemoteDistributor | Should -Be $testParameters.RemoteDistributor
                }
                It 'Get method returns WorkingDirectory = C:\temp' {
                    $result.WorkingDirectory | Should -Be 'C:\temp'
                }
            }

            Context 'Test method' {
                It 'Test method returns true' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'Set method' {
                Set-TargetResource @testParameters
                It 'Set method calls Get-SqlServerMajorVersion with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Set method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Set method does not call New-DistributionDatabase' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Set method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Set method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Set method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
                It 'Set method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
            }
        }

        Describe 'The system is not in desired state given Local distribution, but should be Absent' {

            $testParameters = @{
                InstanceName = 'MSSQLSERVER'
                AdminLinkCredentials = $credentials
                DistributorMode = 'Local'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Absent'
            }

            Mock -CommandName Get-SqlServerMajorVersion -MockWith { return '99' }
            Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME' }
            Mock -CommandName New-ServerConnection -MockWith {
                return [PSCustomObject] @{
                    ServerInstance = $SqlServerName
                }
            }
            Mock -CommandName New-ReplicationServer -MockWith {
                return [PSCustomObject] @{
                    IsDistributor = $true
                    IsPublisher = $true
                    DistributionDatabase = 'distribution'
                    DistributionServer = 'SERVERNAME'
                    WorkingDirectory = 'C:\temp'
                }
            }
            Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
            Mock -CommandName Install-LocalDistributor -MockWith { }
            Mock -CommandName Install-RemoteDistributor -MockWith { }
            Mock -CommandName Register-DistributorPublisher -MockWith { }
            Mock -CommandName Uninstall-Distributor -MockWith {}

            Context 'Get method' {
                $result = Get-TargetResource @testParameters
                It 'Get method calls Get-SqlServerMajorVersion with InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Get method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
                }
                It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
                }
                It 'Get method does not call New-DistributionDatabase' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Get method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Get method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Ger method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
                It 'Ger method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
                It 'Get method returns Ensure = Present' {
                    $result.Ensure | Should -Be 'Present'
                }
                It "Get method returns InstanceName = $($testParameters.InstanceName)" {
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }
                It "Get method returns DistributorMode = $($testParameters.DistributorMode)" {
                    $result.DistributorMode | Should -Be $testParameters.DistributorMode
                }
                It 'Get method returns DistributionDBName = distribution' {
                    $result.DistributionDBName | Should -Be 'distribution'
                }
                It 'Get method returns RemoteDistributor is empty' {
                    $result.RemoteDistributor | Should -Be 'SERVERNAME'
                }
                It 'Get method returns WorkingDirectory = C:\temp' {
                    $result.WorkingDirectory | Should -Be 'C:\temp'
                }
            }

            Context 'Test method' {
                It 'Test method returns false' {
                    Test-TargetResource @testParameters | Should -Be $false
                }
            }

            Context 'Set method' {
                Set-TargetResource @testParameters

                It 'Set method calls Get-SqlServerMajorVersion with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Set method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
                }
                It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
                }
                It 'Set method calls Uninstall-Distributor with $ReplicationServer.DistributionServer = SERVERNAME' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 1 `
                        -ParameterFilter { $ReplicationServer.DistributionServer -eq 'SERVERNAME' }
                }
                It 'Set method does not call New-DistributionDatabase' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Set method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Set method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Set method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
            }
        }

        Describe 'The system is not in desired state given Remote distribution, but should be Absent' {

            $testParameters = @{
                InstanceName = 'INSTANCENAME'
                AdminLinkCredentials = $credentials
                DistributorMode = 'Remote'
                RemoteDistributor = 'REMOTESERVER'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Absent'
            }

            Mock -CommandName Get-SqlServerMajorVersion -MockWith { return '99' }
            Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME\INSTANCENAME' }
            Mock -CommandName New-ServerConnection -MockWith {
                return [PSCustomObject] @{
                    ServerInstance = $SqlServerName
                }
            }
            Mock -CommandName New-ReplicationServer -MockWith {
                return [PSCustomObject] @{
                    IsDistributor = $false
                    IsPublisher = $true
                    DistributionDatabase = 'distribution'
                    DistributionServer = 'REMOTESERVER'
                    WorkingDirectory = 'C:\temp'
                }
            }
            Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
            Mock -CommandName Install-LocalDistributor -MockWith { }
            Mock -CommandName Install-RemoteDistributor -MockWith { }
            Mock -CommandName Register-DistributorPublisher -MockWith { }
            Mock -CommandName Uninstall-Distributor -MockWith {}

            Context 'Get method' {
                $result = Get-TargetResource @testParameters
                It 'Get method calls Get-SqlServerMajorVersion with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Get method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Get method does not call New-DistributionDatabase' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Get method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Get method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Ger method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
                It 'Ger method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
                It 'Get method returns Ensure = Present' {
                    $result.Ensure | Should -Be 'Present'
                }
                It "Get method returns InstanceName = $($testParameters.InstanceName)" {
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }
                It "Get method returns DistributorMode = $($testParameters.DistributorMode)" {
                    $result.DistributorMode | Should -Be $testParameters.DistributorMode
                }
                It 'Get method returns DistributionDBName = distribution' {
                    $result.DistributionDBName | Should -Be 'distribution'
                }
                It "Get method returns RemoteDistributor = $($testParameters.RemoteDistributor)" {
                    $result.RemoteDistributor | Should -Be $testParameters.RemoteDistributor
                }
                It 'Get method returns WorkingDirectory = C:\temp' {
                    $result.WorkingDirectory | Should -Be 'C:\temp'
                }
            }

            Context 'Test method' {
                It 'Test method returns false' {
                    Test-TargetResource @testParameters | Should -Be $false
                }
            }

            Context 'Set method' {
                Set-TargetResource @testParameters
                It 'Set method calls Get-SqlServerMajorVersion with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Set method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
                }
                It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
                }
                It 'Set method calls Uninstall-Distributor with $ReplicationServer.DistributionServer = REMOTESERVER' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 1 `
                        -ParameterFilter { $ReplicationServer.DistributionServer -eq 'REMOTESERVER' }
                }
                It 'Set method does not call New-DistributionDatabase' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Set method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Set method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Set method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
            }
        }

        Describe 'The system is in sync when Absent' {

            $testParameters = @{
                InstanceName = 'MSSQLSERVER'
                AdminLinkCredentials = $credentials
                DistributorMode = 'Local'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Absent'
            }

            Mock -CommandName Get-SqlServerMajorVersion -MockWith { return '99' }
            Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME' }
            Mock -CommandName New-ServerConnection -MockWith {
                return [PSCustomObject] @{
                    ServerInstance = $SqlServerName
                }
            }
            Mock -CommandName New-ReplicationServer -MockWith {
                return [PSCustomObject] @{
                    IsDistributor = $false
                    IsPublisher = $false
                    DistributionDatabase = ''
                    DistributionServer = ''
                    WorkingDirectory = ''
                }
            }
            Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
            Mock -CommandName Install-LocalDistributor -MockWith { }
            Mock -CommandName Install-RemoteDistributor -MockWith { }
            Mock -CommandName Register-DistributorPublisher -MockWith { }
            Mock -CommandName Uninstall-Distributor -MockWith {}

            Context 'Get method' {
                $result = Get-TargetResource @testParameters
                It 'Get method calls Get-SqlServerMajorVersion with InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Get method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
                }
                It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
                }
                It 'Get method does not call New-DistributionDatabase' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Get method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Get method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Ger method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
                It 'Ger method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
                It 'Get method returns Ensure = Absent' {
                    $result.Ensure | Should -Be 'Absent'
                }
                It "Get method returns InstanceName = $($testParameters.InstanceName)" {
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }
                It 'Get method returns DistributorMode as $null' {
                    $result.DistributorMode | Should -BeNullOrEmpty
                }
                It 'Get method returns DistributionDBName as $null' {
                    $result.DistributionDBName | Should -BeNullOrEmpty
                }
                It 'Get method returns RemoteDistributor as $null' {
                    $result.RemoteDistributor | Should -BeNullOrEmpty
                }
                It 'Get method returns WorkingDirectory as $null' {
                    $result.WorkingDirectory | Should -BeNullOrEmpty
                }
            }

            Context 'Test method' {
                It 'Test method returns true' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'Set method' {
                Set-TargetResource @testParameters
                It 'Set method calls Get-SqlServerMajorVersion with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlServerMajorVersion -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Set method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                    Assert-MockCalled -CommandName Get-SqlLocalServerName -Times 1 `
                        -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
                }
                It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ServerConnection -Times 1 `
                        -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
                }
                It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                    Assert-MockCalled -CommandName New-ReplicationServer -Times 1 `
                        -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
                }
                It 'Set method does not call New-DistributionDatabase with $DistributionDBName = distribution' {
                    Assert-MockCalled -CommandName New-DistributionDatabase -Times 0
                }
                It 'Set method does not call Install-LocalDistributor' {
                    Assert-MockCalled -CommandName Install-LocalDistributor -Times 0
                }
                It 'Set method does not call Install-RemoteDistributor' {
                    Assert-MockCalled -CommandName Install-RemoteDistributor -Times 0
                }
                It 'Set method does not call Register-DistributorPublisher' {
                    Assert-MockCalled -CommandName Register-DistributorPublisher -Times 0
                }
                It 'Set method does not call Uninstall-Distributor' {
                    Assert-MockCalled -CommandName Uninstall-Distributor -Times 0
                }
            }
        }

    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Write-Verbose -Message ('Test {1} run for {0} minutes' -f ([timespan]::FromMilliseconds($script:timer.ElapsedMilliseconds)).ToString("mm\:ss"), $script:DSCResourceName) -Verbose
    $script:timer.Stop()
}
