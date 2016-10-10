<#
.EXAMPLE
    This example shows how to ensure that the SQL Alias
    SQLDSC* does not exist with Named Pipes or TCP. 
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
            xSQLAlias Remove_SqlAlias_TCP
            {
                Ensure = 'Absent'
                Name = 'SQLDSC-TCP'
                ServerName = "SQLServer\DSC"
                Protocol = 'TCP'
                TcpPort = 1777
                PsDscRunAsCredential = $SysAdminAccount
            }

            xSQLAlias Remove_SqlAlias_NP
            {
                Ensure = 'Absent'
                Name = 'SQLDSC-NP'
                ServerName = "\\sqlnode\PIPE\sql\query"
                Protocol = 'NP'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
