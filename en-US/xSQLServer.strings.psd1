ConvertFrom-StringData @'
###PSLOC 
# Common
NoKeyFound = No Localization key found for ErrorType: '{0}'.
AbsentNotImplemented = Ensure = Absent is not implemented!
TestFailedAfterSet = Test-TargetResource returned false after calling set.
RemoteConnectionFailed = Remote PowerShell connection to Server '{0}' failed.
TODO = ToDo. Work not implemented at this time. 
UnexpectedErrorFromGet = Got unexpected result from Get-TargetResource. No change is made.
FailedToImportSQLPSModule = Failed to import SQLPS module. 
NotConnectedToInstance = Was unable to connect to the instance '{0}\\{1}'

# SQLServer
NoDatabase = Database '{0}' does not exist on SQL server '{1}\\{2}'.
SSRSNotFound = SQL Reporting Services instance '{0}' does not exist!
RoleNotFound = Role '{0}' does not exist on database '{1}' on SQL server '{2}\\{3}'."
LoginNotFound = Login '{0}' does not exist on SQL server '{1}\\{2}'."
FailedLogin = Creating a login of type 'SqlLogin' requires LoginCredential
FeatureNotSupported = '{0}' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information.

# AvailabilityGroupListener
AvailabilityGroupListenerNotFound = Trying to make a change to a listener that does not exist.
AvailabilityGroupListenerErrorVerifyExist = Unexpected result when trying to verify existence of listener '{0}'.
AvailabilityGroupListenerIPChangeError = IP-address configuration mismatch. Expecting '{0}' found '{1}'. Resource does not support changing IP-address. Listener needs to be removed and then created again.
AvailabilityGroupListenerDHCPChangeError = IP-address configuration mismatch. Expecting '{0}' found '{1}'. Resource does not support changing between static IP and DHCP. Listener needs to be removed and then created again.

# Endpoint
EndpointNotFound = Endpoint '{0}' does not exist
EndpointErrorVerifyExist = Unexpected result when trying to verify existence of endpoint '{0}'.

# Permission
PermissionGetError = Unexpected result when trying to get permissions for '{0}'.
PrincipalNotFound = Principal '{0}' does not exist.
PermissionMissingEnsure = Ensure is not set. No change can be made.

# Configuration
ConfigurationOptionNotFound = Specified option '{0}' could not be found.
ConfigurationRestartRequired = Configuration option '{0}' has been updated, but a manual restart of SQL Server is required for it to take effect.

# AlwaysOnService
AlterAlwaysOnServiceFailed = Failed to ensure Always On is {0} on the instance '{1}'.

# Login
PasswordValidationFailed = Creation of the login '{0}' failed due to the following error: {1}
LoginCreationFailedFailedOperation = Creation of the login '{0}' failed due to a failed operation.
LoginCreationFailedSqlNotSpecified = Creation of the SQL login '{0}' failed due to an unspecified error.
LoginCreationFailedWindowsNotSpecified = Creation of the Windows login '{0}' failed due to an unspecified error.
LoginTypeNotImplemented = The login type '{0}' is not implemented in this resource.
IncorrectLoginMode = The instance '{0}\{1}' is currently in '{2}' authentication mode. To create a SQL Login, it must be set to 'Mixed' authentication mode.
LoginCredentialNotFound = The credential for the SQL Login '{0}' was not found.
PasswordChangeFailed = Setting the password failed for the SQL Login '{0}'.
AlterLoginFailed = Altering the login '{0}' failed.
CreateLoginFailed = Creating the login '{0}' failed.
DropLoginFailed = Dropping the login '{0}' failed.

# Clustered Setup
FailoverClusterDiskMappingError = Unable to map the specified paths to valid cluster storage. Drives mapped: {0}
FailoverClusterIPAddressNotValid = Unable to map the specified IP Address(es) to valid cluster networks.
FailoverClusterResourceNotFound = Could not locate a SQL Server cluster resource for instance {0}.

# AlwaysOnAvailabilityGroup
AgPropertiesNotSet = The properties on the AG do not match the desired state.
AlterAvailabilityGroupFailed = Failed to alter the availability group '{0}'
AlterAvailabilityGroupReplicaFailed = Failed to alter the avilability group replica '{0}'
ClusterPermissionsMissing = The cluster does not have permissions to manage the Availability Group on '{0}\\{1}'. Grant 'Connect SQL', 'Alter Any Availability Group', and 'View Server State' to either 'NT SERVICE\\ClusSvc' or 'NT AUTHORITY\\SYSTEM'.
CreateAgReplicaFailed = Creating the AG Replica failed
CreateAvailabilityGroupFailed = Creating the availability group '{0}' failed with the error '{1}'.
DatabaseMirroringEndpointNotFound = No DatabaseMirroring endpoint was found on '{0}\{1}'.
HadrNotEnabled = HADR is not enabled
InstanceNotPrimaryReplica = The instance '{0}' is not the primary replica for the availability group '{1}'.
RemoveAvailabilityGroupFailed = Failed to remove the availabilty group '{0}' from the '{1}' instance

# SQLServerHelper
ExecuteQueryWithResultsFailed=Executing query with results failed on database '{0}'
ExecuteNonQueryFailed=Executing non-query failed on database '{0}'
'@
