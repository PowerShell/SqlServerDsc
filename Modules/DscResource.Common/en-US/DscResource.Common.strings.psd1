# Localized resources for helper module DscResource.Common.

ConvertFrom-StringData @'
    PropertyTypeInvalidForDesiredValues = Property 'DesiredValues' must be either a [System.Collections.Hashtable], [CimInstance] or [PSBoundParametersDictionary]. The type detected was {0}.
    PropertyTypeInvalidForValuesToCheck = If 'DesiredValues' is a CimInstance, then property 'ValuesToCheck' must contain a value.
    PropertyValidationError = Expected to find an array value for property {0} in the current values, but it was either not present or was null. This has caused the test method to return false.
    PropertiesDoesNotMatch = Found an array for property {0} in the current values, but this array does not match the desired state. Details of the changes are below.
    PropertyThatDoesNotMatch = {0} - {1}
    ValueOfTypeDoesNotMatch = {0} value for property {1} does not match. Current state is '{2}' and desired state is '{3}'.
    UnableToCompareProperty = Unable to compare property {0} as the type {1} is not handled by the Test-DscParameterState cmdlet.
    RobocopyIsCopying = Robocopy is copying media from source '{0}' to destination '{1}'.
    RobocopyUsingUnbufferedIo = Robocopy is using unbuffered I/O.
    RobocopyNotUsingUnbufferedIo = Unbuffered I/O cannot be used due to incompatible version of Robocopy.
    RobocopyArguments = Robocopy is started with the following arguments: {0}
    RobocopyErrorCopying = Robocopy reported errors when copying files. Error code: {0}.
    RobocopyFailuresCopying = Robocopy reported that failures occurred when copying files. Error code: {0}.
    RobocopySuccessful = Robocopy copied files successfully
    RobocopyRemovedExtraFilesAtDestination = Robocopy found files at the destination path that is not present at the source path, these extra files was remove at the destination path.
    RobocopyAllFilesPresent = Robocopy reported that all files already present.
    StartSetupProcess = Started the process with id {0} using the path '{1}', and with a timeout value of {2} seconds.
    ConnectedToDatabaseEngineInstance = Connected to SQL instance '{0}'.
    FailedToConnectToDatabaseEngineInstance = Failed to connect to SQL instance '{0}'.
    ConnectedToAnalysisServicesInstance = Connected to Analysis Services instance '{0}'.
    FailedToConnectToAnalysisServicesInstance = Failed to connected to Analysis Services instance '{0}'.
    SqlMajorVersion = SQL major version is {0}.
    SqlServerVersionIsInvalid = Could not get the SQL version for the instance '{0}'.
    PreferredModuleFound = Preferred module SqlServer found.
    PreferredModuleNotFound = Information: PowerShell module SqlServer not found, trying to use older SQLPS module.
    ImportedPowerShellModule = Importing PowerShell module '{0}' with version '{1}' from path '{2}'.
    PowerShellModuleAlreadyImported = Found PowerShell module {0} already imported in the session.
    ModuleForceRemoval = Forcibly removed the SQL PowerShell module from the session to import it fresh again.
    DebugMessagePushingLocation = SQLPS module changes CWD to SQLSERVER:\ when loading, pushing location to pop it when module is loaded.
    DebugMessagePoppingLocation = Popping location back to what it was before importing SQLPS module.
    PowerShellSqlModuleNotFound = Neither PowerShell module SqlServer or SQLPS was found. Unable to run SQL Server cmdlets.
    FailedToImportPowerShellSqlModule = Failed to import {0} module.
    GetSqlServerClusterResources = Getting cluster resource for SQL Server.
    GetSqlAgentClusterResource = Getting active cluster resource SQL Server Agent.
    BringClusterResourcesOffline = Bringing the SQL Server resources {0} offline.
    BringSqlServerClusterResourcesOnline = Bringing the SQL Server resource back online.
    BringSqlServerAgentClusterResourcesOnline = Bringing the SQL Server Agent resource online.
    GetServiceInformation = Getting information about service '{0}'.
    RestartService = '{0}' service is restarting.
    StoppingService = '{0}' service is stopping.
    StartingService = '{0}' service is starting.
    WaitServiceRestart = Waiting {0} seconds before starting service '{1}'.
    StartingDependentService = Starting service '{0}'.
    WaitingInstanceTimeout = Waiting for instance {0}\\{1} to report status online, with a timeout value of {2} seconds.
    FailedToConnectToInstanceTimeout = Failed to connect to the instance {0}\\{1} within the timeout period of {2} seconds.
    ExecuteQueryWithResultsFailed = Executing query with results failed on database '{0}'.
    ExecuteNonQueryFailed = Executing non-query failed on database '{0}'.
    AlterAvailabilityGroupReplicaFailed = Failed to alter the availability group replica '{0}'.
    GetEffectivePermissionForLogin = Getting the effective permissions for the login '{0}' on '{1}'.
    ClusterPermissionsMissing = The cluster does not have permissions to manage the Availability Group on '{0}\\{1}'. Grant 'Connect SQL', 'Alter Any Availability Group', and 'View Server State' to either 'NT SERVICE\\ClusSvc' or 'NT AUTHORITY\\SYSTEM'.
    ClusterLoginMissing = The login '{0}' is not present. {1}
    ClusterLoginMissingPermissions = The account '{0}' is missing one or more of the following permissions: {1}
    ClusterLoginMissingRecommendedPermissions = The recommended account '{0}' is missing one or more of the following permissions: {1}
    ClusterLoginPermissionsPresent = The cluster login '{0}' has the required permissions.

    # - NOTE!
    # - Below strings are used by helper functions New-TerminatingError and New-WarningMessage.
    # - These strings were merged from old SqlServerDsc.strings.psd1. These will be moved to it's individual
    # - resource when that resources get moved over to the new localization.
    # - NOTE!

    # Common
    NoKeyFound = No Localization key found for ErrorType: '{0}'.
    AbsentNotImplemented = Ensure = Absent is not implemented!
    RemoteConnectionFailed = Remote PowerShell connection to Server '{0}' failed.
    TODO = ToDo. Work not implemented at this time.

    HadrNotEnabled = HADR is not enabled.
    ParameterNotOfType = The parameter '{0}' is not of the type '{1}'.
    ParameterNullOrEmpty = The parameter '{0}' is NULL or empty.

    # SQLServer
    NoDatabase = Database '{0}' does not exist on SQL server '{1}\\{2}'.
    SSRSNotFound = SQL Reporting Services instance '{0}' does not exist!
    RoleNotFound = Role '{0}' does not exist on database '{1}' on SQL server '{2}\\{3}'."
    LoginNotFound = Login '{0}' does not exist on SQL server '{1}\\{2}'."
    FailedLogin = Creating a login of type 'SqlLogin' requires LoginCredential
'@
