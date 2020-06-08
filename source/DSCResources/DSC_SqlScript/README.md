# Description

The `SqlScript` DSC resource provides the means to run a user generated
T-SQL script on the SQL Server instance. Three scripts are required;
Get T-SQL script, Set T-SQL script and the Test T-SQL script.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server 2012 or later.
* Target machine must have access to the SQLPS PowerShell module or the SqlServer
  PowerShell module.

## Known issues

* There is a known problem running this resource using PowerShell 4.0.
See [issue #273](https://github.com/dsccommunity/SqlServerDsc/issues/273)
for more information._

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlScript).

## Scripts

### Get T-SQL Script (GetFilePath)

The Get T-SQL script is used to query the status when running the cmdlet
Get-DscConfiguration, and the result can be found in the property `GetResult`.

### Test T-SQL Script (TestFilePath)

The Test T-SQL script is used to test if the desired state is met. If Test
T-SQL raises an error or returns any value other than 'null' the test fails, thus
the Set T-SQL script is run.

### Set T-SQL Script (SetFilePath)

The Set T-SQL script performs the actual change when Test T-SQL script fails.
