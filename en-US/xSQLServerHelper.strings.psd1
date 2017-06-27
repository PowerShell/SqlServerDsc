# Localized resources for helper module xSQLServerHelper.

ConvertFrom-StringData @'
    ConnectedToDatabaseEngineInstance = Connected to SQL instance '{0}'.
    FailedToConnectToDatabaseEngineInstance = Failed to connect to SQL instance '{0}'.
    ConnectedToAnalysisServicesInstance = Connected to Analysis Services instance '{0}'.
    FailedToConnectToAnalysisServicesInstance = Failed to connected to Analysis Services instance '{0}'.
    SqlMajorVersion = SQL major version is {0}.
    CreatingApplicationDomain = Creating application domain '{0}'.
    ReusingApplicationDomain = Reusing application domain '{0}'.
    LoadingAssembly = Loading assembly '{0}'.
    UnloadingApplicationDomain = Unloading application domain '{0}'.
    SqlServerVersionIsInvalid = Could not get the SQL version for the instance '{0}'.
    PropertyTypeInvalidForDesiredValues = Property 'DesiredValues' must be either a [Hashtable], [CimInstance] or [PSBoundParametersDictionary]. The type detected was {0}.
    PropertyTypeInvalidForValuesToCheck = If 'DesiredValues' is a CimInstance, then property 'ValuesToCheck' must contain a value.
    PropertyValidationError = Expected to find an array value for property {0} in the current values, but it was either not present or was null. This has caused the test method to return false.
    PropertiesDoesNotMatch = Found an array for property {0} in the current values, but this array does not match the desired state. Details of the changes are below.
    PropertyThatDoesNotMatch = {0} - {1}
    ValueOfTypeDoesNotMatch = {0} value for property {1} does not match. Current state is '{2}' and desired state is '{3}'.
    UnableToCompareProperty = Unable to compare property {0} as the type {1} is not handled by the Test-SQLDscParameterState cmdlet.
    PreferredModuleFound = Preferred module SqlServer found.
    PreferredModuleNotFound = Information: PowerShell module SqlServer not found, trying to use older SQLPS module.
    ImportingPowerShellModule = Importing PowerShell module {0}.
    DebugMessagePushingLocation = SQLPS module changes CWD to SQLSERVER:\ when loading, pushing location to pop it when module is loaded.
    DebugMessageImportedPowerShellModule = Module {0} imported.
    DebugMessagePoppingLocation = Popping location back to what it was before importing SQLPS module.
    PowerShellSqlModuleNotFound = Neither PowerShell module SqlServer or SQLPS was found. Unable to run SQL Server cmdlets.
    FailedToImportPowerShellSqlModule = Failed to import {0} module.
    GetSqlServerClusterResources = Getting cluster resource for SQL Server.
    GetSqlAgentClusterResource = Getting active cluster resource SQL Server Agent.
    BringClusterResourcesOffline = Bringing the SQL Server resources {0} offline.
    BringSqlServerClusterResourcesOnline = Bringing the SQL Server resource back online.
    BringSqlServerAgentClusterResourcesOnline = Bringing the SQL Server Agent resource online.
    GetSqlServerService = Getting SQL Server service information.
    RestartSqlServerService = SQL Server service restarting.
    StartingDependentService = Starting service {0}
    ExecuteQueryWithResultsFailed = Executing query with results failed on database '{0}'.
    ExecuteNonQueryFailed = Executing non-query failed on database '{0}'.
    AlterAvailabilityGroupReplicaFailed = Failed to alter the availability group replica '{0}'.
    GetEffectivePermissionForLogin = Getting the effective permissions for the login '{0}' on '{1}'.

    # - NOTE!
    # - Below strings are used by helper functions New-TerminatingError and New-WarningMessage.
    # - These strings were merged from old xSQLServer.strings.psd1. These will be moved to it's individual
    # - resource when that resources get moved over to the new localization.
    # - NOTE!

    # Common
    NoKeyFound = No Localization key found for ErrorType: '{0}'.
    AbsentNotImplemented = Ensure = Absent is not implemented!
    TestFailedAfterSet = Test-TargetResource returned false after calling set.
    RemoteConnectionFailed = Remote PowerShell connection to Server '{0}' failed.
    TODO = ToDo. Work not implemented at this time.
    UnexpectedErrorFromGet = Got unexpected result from Get-TargetResource. No change is made.
    NotConnectedToInstance = Was unable to connect to the instance '{0}\\{1}'
    AlterAvailabilityGroupFailed = Failed to alter the availability group '{0}'.
    HadrNotEnabled = HADR is not enabled.
    AvailabilityGroupNotFound = Unable to locate the availability group '{0}' on the instance '{1}'.
    ParameterNotOfType = The parameter '{0}' is not of the type '{1}'.
    ParameterNullOrEmpty = The parameter '{0}' is NULL or empty.

    # SQLServer
    NoDatabase = Database '{0}' does not exist on SQL server '{1}\\{2}'.
    SSRSNotFound = SQL Reporting Services instance '{0}' does not exist!
    RoleNotFound = Role '{0}' does not exist on database '{1}' on SQL server '{2}\\{3}'."
    LoginNotFound = Login '{0}' does not exist on SQL server '{1}\\{2}'."
    FailedLogin = Creating a login of type 'SqlLogin' requires LoginCredential

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
    EndpointFoundButWrongType = Endpoint '{0}' does exist, but it is not of type 'DatabaseMirroring'.

    # Permission
    PermissionGetError = Unexpected result when trying to get permissions for '{0}'.
    ChangingPermissionFailed = Changing permission for principal '{0}' failed.

    # Configuration
    ConfigurationOptionNotFound = Specified option '{0}' could not be found.
    ConfigurationRestartRequired = Configuration option '{0}' has been updated, but a manual restart of SQL Server is required for it to take effect.

    # AlwaysOnService
    AlterAlwaysOnServiceFailed = Failed to ensure Always On is {0} on the instance '{1}'.
    UnexpectedAlwaysOnStatus = The status of property Server.IsHadrEnabled was neither $true or $false. Status is '{0}'.

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

    # AlwaysOnAvailabilityGroup
    ClusterPermissionsMissing = The cluster does not have permissions to manage the Availability Group on '{0}\\{1}'. Grant 'Connect SQL', 'Alter Any Availability Group', and 'View Server State' to either 'NT SERVICE\\ClusSvc' or 'NT AUTHORITY\\SYSTEM'.
    CreateAvailabilityGroupReplicaFailed = Creating the Availability Group Replica '{0}' failed on the instance '{1}'.
    CreateAvailabilityGroupFailed = Creating the availability group '{0}'.
    DatabaseMirroringEndpointNotFound = No database mirroring endpoint was found on '{0}\{1}'.
    InstanceNotPrimaryReplica = The instance '{0}' is not the primary replica for the availability group '{1}'.
    RemoveAvailabilityGroupFailed = Failed to remove the availability group '{0}' from the '{1}' instance.

    # AlwaysOnAvailabilityGroupReplica
    JoinAvailabilityGroupFailed = Failed to join the availability group replica '{0}'.
    RemoveAvailabilityGroupReplicaFailed = Failed to remove the availability group replica '{0}'.
    ReplicaNotFound = Unable to find the availability group replica '{0}' on the instance '{1}'.

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
    FailedToSetPermissionDatabase = Failed to set permission for login named {0} of the database named {1} on {2}\\{3}.
    FailedToEnumDatabasePermissions = Failed to get permission for login named {0} of the database named {1} on {2}\\{3}.

    # SQLServerRole
    EnumMemberNamesServerRoleGetError = Failed to enumerate members of the server role named {2} on {0}\\{1}.
    MembersToIncludeAndExcludeParamMustBeNull = The parameter MembersToInclude and/or MembersToExclude must not be set, or be set to $null, when parameter Members are used.
    CreateServerRoleSetError = Failed to create the server role named {2} on {0}\\{1}.
    DropServerRoleSetError = Failed to drop the server role named {2} on {0}\\{1}.
    AddMemberServerRoleSetError = Failed to add member {3} to the server role named {2} on {0}\\{1}.
    DropMemberServerRoleSetError = Failed to drop member {3} to the server role named {2} on {0}\\{1}.

    # SQLServerNetwork
    UnableToUseBothDynamicAndStaticPort = Unable to set both TCP dynamic port and TCP static port. Only one can be set.

'@
