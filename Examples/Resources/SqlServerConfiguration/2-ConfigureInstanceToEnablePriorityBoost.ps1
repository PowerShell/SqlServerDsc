<#
.EXAMPLE
    This example shows how to configure two SQL Server instances on the same server to have the setting 'priority boost' enabled.
.NOTES
    To get all available options run sp_configure on the SQL Server instance, or refer to https://msdn.microsoft.com/en-us/library/ms189631.aspx
#>

Configuration Example
{
    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerConfiguration 'SQLConfigPriorityBoost'
        {

            ServerName     = 'localhost'
            InstanceName   = 'MSSQLSERVER'
            OptionName     = 'priority boost'
            OptionValue    = 1
            RestartService = $false
        }
    }
}
