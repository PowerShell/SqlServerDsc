@{
# Version number of this module.
ModuleVersion = '7.1.0.0'

# ID used to uniquely identify this module
GUID = '74e9ddb5-4cbc-4fa2-a222-2bcfb533fd66'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2014 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module with DSC Resources for deployment and configuration of Microsoft SQL Server.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

DSCResourcesToExport = @('xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership')

# Script module or binary module file associated with this manifest.
RootModule = '.\DSCResources\MSFT_xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership\MSFT_xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership.psm1'

RequiredAssemblies = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xSQLServer/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xSQLServer'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '- Changes to xSQLServerMemory
  - Changed the way SQLServer parameter is passed from Test-TargetResource to Get-TargetResource so that the default value isn"t lost (issue 576).
  - Added condition to unit tests for when no SQLServer parameter is set.
- Changes to xSQLServerMaxDop
  - Changed the way SQLServer parameter is passed from Test-TargetResource to Get-TargetResource so that the default value isn"t lost (issue 576).
  - Added condition to unit tests for when no SQLServer parameter is set.
- Changes to xWaitForAvailabilityGroup
  - Updated README.md with a description for the resources and revised the parameter descriptions.
  - The default value for RetryIntervalSec is now 20 seconds and the default value for RetryCount is now 30 times (issue 505).
  - Cleaned up code and fixed PSSA rules warnings (issue 268).
  - Added unit tests (issue 297).
  - Added descriptive text to README.md that the account that runs the resource must have permission to run the cmdlet Get-ClusterGroup (issue 307).
  - Added read-only parameter GroupExist which will return $true if the cluster role/group exist, otherwise it returns $false (issue 510).
  - Added examples.
- Changes to xSQLServerPermission
  - Cleaned up code, removed SupportsShouldProcess and fixed PSSA rules warnings (issue 241 and issue 262).
  - It is now possible to add permissions to two or more logins on the same instance (issue 526).
  - The parameter NodeName is no longer mandatory and has now the default value of $env:COMPUTERNAME.
  - The parameter Ensure now has a default value of "Present".
  - Updated README.md with a description for the resources and revised the parameter descriptions.
  - Removed dependency of SQLPS provider (issue 482).
  - Added ConnectSql permission. Now that permission can also be granted or revoked.
  - Updated note in resource description to also mention ConnectSql permission.
- Changes to xSQLServerHelper module
  - Removed helper function Get-SQLPSInstance and Get-SQLPSInstanceName because there is no resource using it any longer.
  - Added four new helper functions.
    - Register-SqlSmo, Register-SqlWmiManagement and Unregister-SqlAssemblies to handle the creation on the application domain and loading and unloading of the SMO and SqlWmiManagement assemblies.
    - Get-SqlInstanceMajorVersion to get the major SQL version for a specific instance.
  - Fixed typos in comment-based help
- Changes to xSQLServer
  - Fixed typos in markdown files; CHANGELOG, CONTRIBUTING, README and ISSUE_TEMPLATE.
  - Fixed typos in schema.mof files (and README.md).
  - Updated some parameter description in schema.mof files on those that was found was not equal to README.md.
- Changes to xSQLServerAlwaysOnService
  - Get-TargetResource should no longer fail silently with error "Index operation failed; the array index evaluated to null." (issue 519). Now if the Server.IsHadrEnabled property return neither $true or $false the Get-TargetResource function will throw an error.
- Changes to xSQLServerSetUp
  - Updated xSQLServerSetup Module Get-Resource method to fix (issue 516 and 490).
  - Added change to detect DQ, DQC, BOL, SDK features. Now the function Test-TargetResource returns true after calling set for DQ, DQC, BOL, SDK features (issue 516 and 490).
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Updated to return the exception raised when an error is thrown.
- Changes to xSQLServerAlwaysOnAvailabilityGroupReplica
  - Updated to return the exception raised when an error is thrown.
  - Updated parameter description for parameter Name, so that it says it must be in the format SQLServer\InstanceName for named instance (issue 548).
- Changes to xSQLServerLogin
  - Added an optional boolean parameter Disabled. It can be used to enable/disable existing logins or create disabled logins (new logins are created as enabled by default).
- Changes to xSQLServerDatabaseRole
  - Updated variable passed to Microsoft.SqlServer.Management.Smo.User constructor to fix issue 530
- Changes to xSQLServerNetwork
  - Added optional parameter SQLServer with default value of $env:COMPUTERNAME (issue 528).
  - Added optional parameter RestartTimeout with default value of 120 seconds.
  - Now the resource supports restarting a sql server in a cluster (issue 527 and issue 455).
  - Now the resource allows to set the parameter TcpDynamicPorts to a blank value (partly fixes issue 534). Setting a blank value for parameter TcpDynamicPorts together with a value for parameter TcpPort means that static port will be used.
  - Now the resource will not call Alter() in the Set-TargetResource when there is no change necessary (issue 537).
  - Updated example 1-EnableTcpIpOnCustomStaticPort.
  - Added unit tests (issue 294).
  - Refactored some of the code, cleaned up the rest and fixed PSSA rules warnings (issue 261).
  - If parameter TcpDynamicPort is set to "0" at the same time as TcpPort is set the resource will now throw an error (issue 535).
  - Added examples (issue 536).
  - When TcpDynamicPorts is set to "0" the Test-TargetResource function will no longer fail each time (issue 564).
- Changes to xSQLServerRSConfig
  - Replaced sqlcmd.exe usages with Invoke-Sqlcmd calls (issue 567).
- Changes to xSQLServerDatabasePermission
  - Fixed code style, updated README.md and removed *-SqlDatabasePermission functions from xSQLServerHelper.psm1.
  - Added the option "GrantWithGrant" with gives the user grant rights, together with the ability to grant others the same right.
  - Now the resource can revoke permission correctly (issue 454). When revoking "GrantWithGrant", both the grantee and all the other users the grantee has granted the same permission to, will also get their permission revoked.
  - Updated tests to cover Revoke().
- Changes to xSQLServerHelper
  - The missing helper function ("Test-SPDSCObjectHasProperty"), that was referenced in the helper function Test-SQLDscParameterState, is now incorporated into Test-SQLDscParameterState (issue 589).

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}







