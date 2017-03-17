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
AlterAvailabilityGroupFailed = Failed to alter the availability group '{0}'.
HadrNotEnabled = HADR is not enabled.

# SQLServer
NoDatabase = Database '{0}' does not exist on SQL server '{1}\\{2}'.
SSRSNotFound = SQL Reporting Services instance '{0}' does not exist!
RoleNotFound = Role '{0}' does not exist on database '{1}' on SQL server '{2}\\{3}'."
LoginNotFound = Login '{0}' does not exist on SQL server '{1}\\{2}'."
FailedLogin = Creating a login of type 'SqlLogin' requires LoginCredential
FeatureNotSupported = '{0}' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information.

# Database Role
AddLoginDatabaseSetError = Failed adding the login {2} as a user of the database {3}, on the instance {0}\\{1}.
DropMemberDatabaseSetError = Failed removing the login {2} from the role {3} on the database {4}, on the instance {0}\\{1}.
AddMemberDatabaseSetError = Failed adding the login {2} to the role {3} on the database {4}, on the instance {0}\\{1}.

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
AlterAvailabilityGroupReplicaFailed = Failed to alter the avilability group replica '{0}'.
ClusterPermissionsMissing = The cluster does not have permissions to manage the Availability Group on '{0}\\{1}'. Grant 'Connect SQL', 'Alter Any Availability Group', and 'View Server State' to either 'NT SERVICE\\ClusSvc' or 'NT AUTHORITY\\SYSTEM'.
CreateAvailabilityGroupReplicaFailed = Creating the Availability Group Replica failed.
CreateAvailabilityGroupFailed = Creating the availability group '{0}' failed with the error '{1}'.
DatabaseMirroringEndpointNotFound = No database mirroring endpoint was found on '{0}\{1}'.
InstanceNotPrimaryReplica = The instance '{0}' is not the primary replica for the availability group '{1}'.
RemoveAvailabilityGroupFailed = Failed to remove the availabilty group '{0}' from the '{1}' instance.

# AlwaysOnAvailabilityGroupReplica
AvailabilityGroupNotFound = Unable to locate the availability group '{0}' on the instance '{1}'.
JoinAvailabilityGroupFailed = Failed to join the availability group replica '{0}'.
RemoveAvailabilityGroupReplicaFailed = Failed to remove the availability group replica '{0}' with the error '{1}'.
ReplicaNotFound = Unable to find the availability group replica '{0}' on the instance '{1}'.

# SQLServerHelper
ExecuteQueryWithResultsFailed = Executing query with results failed on database '{0}'.
ExecuteNonQueryFailed = Executing non-query failed on database '{0}'.
AnalysisServicesFailedToConnect = Failed to connect to Analysis Services '{0}'.
AnalysisServicesNoServerObject = Did not get the expected Analysis Services server object.

# Max degree of parallelism
MaxDopSetError = Unexpected result when trying to configure the max degree of parallelism server configuration option.
MaxDopParamMustBeNull = MaxDop parameter must be set to $null or not assigned if DynamicAlloc parameter is set to $true.

# Server Memory
MaxMemoryParamMustBeNull = The parameter MaxMemory must be null when DynamicAlloc is set to true.
MaxMemoryParamMustNotBeNull = The parameter MaxMemory must not be null when DynamicAlloc is set to false.
AlterServerMemoryFailed = Failed to alter the server configuration memory for {0}\\{1}.
ErrorGetDynamicMaxMemory = Failed to calculate dynamically the maximum memory.

# SQLServerDatabase
CreateDatabaseSetError = Failed to create the database named {2} on {0}\\{1}.
DropDatabaseSetError = Failed to drop the database named {2} on {0}\\{1}.
FailedToGetOwnerDatabase = Failed to get owner of the database named {0} on {1}\\{2}.
FailedToSetOwnerDatabase = Failed to set owner named {0} of the database named {1} on {2}\\{3}.

# SQLServerRole
EnumMemberNamesServerRoleGetError = Failed to enumerate members of the server role named {2} on {0}\\{1}.
MembersToIncludeAndExcludeParamMustBeNull = The parameter MembersToInclude and/or MembersToExclude must not be set, or be set to $null, when parameter Members are used.
CreateServerRoleSetError = Failed to create the server role named {2} on {0}\\{1}.
DropServerRoleSetError = Failed to drop the server role named {2} on {0}\\{1}.
AddMemberServerRoleSetError = Failed to add member {3} to the server role named {2} on {0}\\{1}.
DropMemberServerRoleSetError = Failed to drop member {3} to the server role named {2} on {0}\\{1}.
'@
