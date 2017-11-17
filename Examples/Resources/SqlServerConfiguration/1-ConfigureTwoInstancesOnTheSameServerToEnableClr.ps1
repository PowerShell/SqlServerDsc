<#
.EXAMPLE
    This example shows how to configure two SQL Server instances on the same server to have CLR enabled.
.NOTES
    To get all available options run sp_configure on the SQL Server instance, or refer to https://msdn.microsoft.com/en-us/library/ms189631.aspx
#>

$configurationData = @{
    AllNodes = @(
        @{
            NodeName     = 'localhost'
            SQLInstances = @('CONTENT', 'DIST')
            OptionName   = 'clr enabled'
        }
    )
}

Configuration Example
{
    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        foreach ($SQLInstance in $node.SQLInstances)
        {
            SqlServerConfiguration ('SQLConfigCLR_{0}' -f $SQLInstance)
            {
                Servername   = $node.NodeName
                InstanceName = $SQLInstance
                OptionName   = $node.OptionName
                OptionValue  = 1
            }
        }
    }
}
