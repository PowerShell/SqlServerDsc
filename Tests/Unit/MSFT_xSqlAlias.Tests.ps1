# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:DSCModuleName      = 'xSQLServer' # Example xNetworking
$script:DSCResourceName    = 'MSFT_xSqlAlias' # Example MSFT_xFirewall

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

try
{
    #region Get-TargetResource
    Describe 'Get-TargetResource'{
    Mock -ModuleName MSFT_xSqlAlias -CommandName Get-ItemProperty -MockWith {
        Write-Output 'DBMSSOCN,localhost,1433'
    }
    
    $SqlAlias = Get-TargetResource -Name 'localhost'

    It 'Should return hashtable with Key Protocol'{
        $SqlAlias.ContainsKey('Protocol') | Should Be $true
    }
     
    It 'Should return hashtable with Value that matches "TCP"'{
        $SqlAlias.Protocol = 'TCP'    
    }
    }
    #end region Get-TargetResource

    #region Set-TargetResource
    Describe 'Set-TargetResource'{

    Mock -ModuleName MSFT_xSqlAlias -CommandName Test-Path -MockWith {
        Write-Output $true
    }

    Mock -ModuleName MSFT_xSqlAlias -CommandName Get-ItemProperty -MockWith {
        Write-Output 'DBMSSOCN,localhost,52002'
    } 
    
    Mock -ModuleName MSFT_xSqlAlias -CommandName Set-ItemProperty -MockWith {
        Write-Output $true
    }    

    Mock -ModuleName MSFT_xSqlAlias -CommandName Get-Wmiobject -MockWith {
        Write-Output @{
            Class = 'win32_OperatingSystem'
            OSArchitecture = '64-bit'
        }
    }

    It 'Should not call Set-ItemProperty with value already set' {
        Set-TargetResource -Name 'myServerAlias'  -Protocol 'TCP' -ServerName 'localhost' -TCPPort 52002 -Ensure 'Present'
        Assert-MockCalled -ModuleName MSFT_xSqlAlias -CommandName Set-ItemProperty -Exactly 0
    }

    It 'Call Set-ItemProperty exactly 2 times (1 for 32bit and 1 for 64 bit reg keys)' {
        Set-TargetResource -Name 'myServerAlias'  -Protocol 'TCP' -ServerName 'localhost' -TCPPort 1433 -Ensure 'Present'
        Assert-MockCalled -ModuleName MSFT_xSqlAlias -CommandName Set-ItemProperty -Exactly 2
    }

}
    #end region Set-TargetResource

    #region Test-TargetResource
    Describe 'Test-TargetResource'{
    Mock -ModuleName MSFT_xSqlAlias -CommandName Test-Path -MockWith {
        Write-Output $true
    }

    Mock -ModuleName MSFT_xSqlAlias -CommandName Get-ItemProperty -MockWith {
        Write-Output @{
            myServerAlias = 'DBMSSOCN,localhost,1433'
        }
    }   

    Mock -ModuleName MSFT_xSqlAlias -CommandName Get-Wmiobject -MockWith {
        Write-Output @{
            Class = 'win32_OperatingSystem'
            OSArchitecture = '64-bit'
        }
    }

    It 'Should return true when Test is passed as Alias thats already set'{
        Test-TargetResource -Name 'myServerAlias'  -Protocol 'TCP' -ServerName localhost -TCPPort 1433 -Ensure 'Present' | Should Be $true
    }

    It 'Should return false when Test is passed as Alias that is not set'{
        Test-TargetResource -Name 'myServerAlias'  -Protocol 'TCP' -ServerName localhost -TCPPort 52002 -Ensure 'Present' | Should Be $false
    }
    }
    #end region Test-TargetResource

    InModuleScope $script:DSCResourceName {
    }

}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
