# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

<#
.Synopsis
   Template for creating DSC Resource Unit Tests
.DESCRIPTION
   To Use:
     1. Copy to \Tests\Unit\ folder and rename <ResourceName>.tests.ps1 (e.g. MSFT_xFirewall.tests.ps1)
     2. Customize TODO sections.

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>


# TODO: Customize these parameters...
$script:DSCModuleName      = 'xSQLServer' # Example xNetworking
$script:DSCResourceName    = 'MSFT_xSqlAlias' # Example MSFT_xFirewall
# /TODO

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

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{
    #region Pester Test Initialization

    # TODO: Optionally create any variables here for use by your tests
    # See https://github.com/PowerShell/xNetworking/blob/dev/Tests/Unit/MSFT_xDhcpClient.Tests.ps1
    # Mocks that should be applied to all cmdlets being tested may
    # also be created here if required.

    #endregion Pester Test Initialization

    # TODO: Common DSC Resource describe block structure
    # The following three Describe blocks are included as a common test pattern.
    # If a different test pattern would be more suitable, then test describe blocks
    # may be completely replaced. The goal of this pattern should be to describe 
    # the potential states a system could be in so that the get/test/set cmdlets
    # can be tested in those states. Any mocks that relate to that specific state
    # can be included in the relevant describe block. For a more detailed description
    # of this approach please review https://github.com/PowerShell/DscResources/issues/143 

    # Add as many of these example 'states' as required to simulate the scenarions that
    # the DSC resource is designed to work with, below a simple "is in desired state" and
    # "is not in desired state" are used, but there may be more complex combinations of 
    # factors, depending on how complex your resource is.

    #region Get-TargetResource
    Describe 'Get-TargetResource'{
    Mock -ModuleName MSFT_xSqlAlias -CommandName Get-ItemProperty -MockWith {
        Write-Output 'DBMSSOCN,localhost,1433'
    }
    
    $SqlAlias = Get-xSqlAliasTargetResource -Name 'localhost'

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
        Set-xSqlAliasTargetResource -Name 'myServerAlias'  -Protocol 'TCP' -ServerName 'localhost' -TCPPort 52002 -Ensure 'Present'
        Assert-MockCalled -ModuleName MSFT_xSqlAlias -CommandName Set-ItemProperty -Exactly 0
    }

    It 'Call Set-ItemProperty exactly 2 times (1 for 32bit and 1 for 64 bit reg keys)' {
        Set-xSqlAliasTargetResource -Name 'myServerAlias'  -Protocol 'TCP' -ServerName 'localhost' -TCPPort 1433 -Ensure 'Present'
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
        Test-xSqlAliasTargetResource -Name 'myServerAlias'  -Protocol 'TCP' -ServerName localhost -TCPPort 1433 -Ensure 'Present' | Should Be $true
    }

    It 'Should return false when Test is passed as Alias that is not set'{
        Test-xSqlAliasTargetResource -Name 'myServerAlias'  -Protocol 'TCP' -ServerName localhost -TCPPort 52002 -Ensure 'Present' | Should Be $false
    }
    }
    #end region Test-TargetResource

    
    # TODO: Pester Tests for any non-exported Helper Cmdlets
    # If the resource does not contain any non-exported helper cmdlets then
    # this block may be safetly deleted.
    InModuleScope $script:DSCResourceName {
        # The InModuleScope command allows you to perform white-box unit testing
        # on the internal (non-exported) code of a Script Module.

    }
    #endregion Non-Exported Function Unit Tests
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
