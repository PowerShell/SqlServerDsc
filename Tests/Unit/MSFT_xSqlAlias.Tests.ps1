Import-Module "$PSScriptRoot\..\DSCResources\MSFT_xSqlAlias\MSFT_xSqlAlias.psm1" -Prefix 'xSqlAlias' -Force

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
