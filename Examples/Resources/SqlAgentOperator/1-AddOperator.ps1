<#
    .EXAMPLE
        This example shows how to ensure that the SQL Agent Operator
        DbaTeam exists with the correct email address.
#>

Configuration Example
{

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlAgentOperator Add_DbaTeam {
            Ensure               = 'Present'
            Name                 = 'DbaTeam'
            ServerName           = 'TestServer'
            InstanceName         = 'MSSQLServer'
            EmailAddress         = 'dbateam@company.com'
        }
    }
}
