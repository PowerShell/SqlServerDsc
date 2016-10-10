<#
.EXAMPLE
    This example shows how to ensure that the SQL Alias
    SQLDSC* exists with Named Pipes or TCP. 
#>

    Configuration Example 
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SysAdminAccount
        )
        
        Import-DscResource -ModuleName xSqlServer

        node localhost {
            xSQLAlias Add_SqlAlias_TCP
            {
                Ensure = 'Present'
                Name = 'SQLDSC-TCP'
                ServerName = "SQLServer\DSC"
                Protocol = 'TCP'
                TcpPort = 1777
                PsDscRunAsCredential = $SysAdminAccount
            }

            xSQLAlias Add_SqlAlias_TCPUseDynamicTcpPort
            {
                Ensure = 'Present'
                Name = 'SQLDSC-DYN'
                ServerName = "SQLServer\DSC"
                Protocol = 'TCP'
                UseDynamicTcpPort = $true
                PsDscRunAsCredential = $SysAdminAccount
            }

            xSQLAlias Add_SqlAlias_NP
            {
                Ensure = 'Present'
                Name = 'SQLDSC-NP'
                ServerName = "\\sqlnode\PIPE\sql\query"
                Protocol = 'NP'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
