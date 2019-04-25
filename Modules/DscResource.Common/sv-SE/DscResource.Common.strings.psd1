# Swedish localized resources for helper module SqlServerDscHelper.

ConvertFrom-StringData @'
    ConnectedToDatabaseEngineInstance = Ansluten till SQL instans '{0}'.
    FailedToConnectToDatabaseEngineInstance = Misslyckades att ansluta till SQL instans '{0}'.
    ConnectedToAnalysisServicesInstance = Ansluten till Analysis Services instans '{0}'.
    FailedToConnectToAnalysisServicesInstance = Misslyckades att ansluta till Analysis Services instans '{0}'.
    SqlMajorVersion = SQL major version är {0}.
    SqlServerVersionIsInvalid = Kunde inte hämta SQL version för instansen '{0}'.
    PropertyTypeInvalidForDesiredValues = Egenskapen 'DesiredValues' måste vara endera en [System.Collections.Hashtable], [CimInstance] eller [PSBoundParametersDictionary]. Den typ som hittades var {0}.
    PropertyTypeInvalidForValuesToCheck = Om 'DesiredValues' är av typ CimInstance, då måste egenskapen 'ValuesToCheck' sättas till ett värde.
    PropertyValidationError = Förväntades hitta ett värde av typen matris för egenskapen {0} för nuvarande värden, men den var endera inte tillgänglig eller så var den satt till Null. Detta har medfört att test metoden har retunerat falskt.
    PropertiesDoesNotMatch = Hittade en matris för egenskapen {0} för nuvarande värden, men denna matris matchar inte önskat läge. Detaljer för ändringarna finns nedan.
    PropertyThatDoesNotMatch = {0} - {1}
    ValueOfTypeDoesNotMatch = {0} värde för egenskapen {1} matchar inte. Nuvarande läge är '{2}' och önskat läge är '{3}'.
    UnableToCompareProperty = Inte möjligt att jämföra egenskapen {0} som typen {1}. {1} hanteras inte av Test-DscParameterState cmdlet.
    PreferredModuleFound = Föredragen modul SqlServer funnen.
    PreferredModuleNotFound = Information: PowerShell modul SqlServer ej funnen, försöker att använda äldre SQLPS modul.
    ImportedPowerShellModule = Importerade PowerShell modul '{0}' med version '{1}' från mapp '{2}'.
    PowerShellModuleAlreadyImported = Fann att PowerShell modul {0} redan är importerad i sessionen.
    ModuleForceRemoval = Tvingade bort den tidigare SQL PowerShell modulen från sessionen för att importera den fräsch igen.
    DebugMessagePushingLocation = SQLPS modul ändrar nuvarande katalog till SQLSERVER:\ när modulen laddas, sparar nuvarande katalog så den kan återställas efter modulen laddats.
    DebugMessagePoppingLocation = Återställer nuvarande katalog till vad den var innan modulen SQLPS importerades.
    PowerShellSqlModuleNotFound = Varken PowerShell modulen SqlServer eller SQLPS kunde hittas. Kommer inte kunna köra SQL Server cmdlets.
    FailedToImportPowerShellSqlModule = Misslyckades att importera {0} modulen.
    GetSqlServerClusterResources = Hämtar kluster resurser för SQL Server.
    GetSqlAgentClusterResource = Hämtar aktiva kluster resurser för SQL Server Agent.
    BringClusterResourcesOffline = Tar SQL Server resurser {0} offline.
    BringSqlServerClusterResourcesOnline = Tar SQL Server resurser online igen.
    BringSqlServerAgentClusterResourcesOnline = Tar SQL Server Agent resurser online.
    GetSqlServerService = Hämtar SQL Server-tjänst information.
    RestartSqlServerService = SQL Server-tjänst startar om.
    StartingDependentService = Startar tjänst {0}
    ExecuteQueryWithResultsFailed = Exekvering av fråga med resultat misslyckades mot databas '{0}'.
    ExecuteNonQueryFailed = Exekvering av icke-fråga misslyckades på databas '{0}'.
    AlterAvailabilityGroupReplicaFailed = Misslyckades att ändra Availability Group kopia '{0}'.
    GetEffectivePermissionForLogin = Hämtar effektiva behörigheter för inloggningen '{0}' på '{1}'.
    RobocopyIsCopying = Robocopy kopierar media från källan '{0}' till destinationen '{1}'.
    RobocopyUsingUnbufferedIo = Robocopy använder sig av obuffrad I/O.
    RobocopyNotUsingUnbufferedIo = Obuffrad I/O kan inte användas på grund av versionen av Robocopy inte är kompatibel.
    RobocopyArguments = Robocopy startas med följande argument: {0}
    RobocopyErrorCopying = Robocopy rapporterade fel när filer kopierades. Felkod: {0}.
    RobocopyFailuresCopying = Robocopy rapporterade att fel uppstod när filer kopierades. Felkod: {0}.
    RobocopySuccessful = Robocopy lyckades kopiera filer till destinationen.
    RobocopyRemovedExtraFilesAtDestination = Robocopy fann extra filer på destinationen som inte finns i källan, dessa extra filer togs bort på destinationen.
    RobocopyAllFilesPresent = Robocopy rapporterade att alla filer redan finns på destinationen.

    # - NOTE!
    # - Below strings are used by helper functions New-TerminatingError and New-WarningMessage.
    # - These strings were merged from old SqlServerDsc.strings.psd1. These will be moved to it's individual
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

    # SQLServerDatabase
    CreateDatabaseSetError = Failed to create the database named {2} on {0}\\{1}.
    DropDatabaseSetError = Failed to drop the database named {2} on {0}\\{1}.
    FailedToGetOwnerDatabase = Failed to get owner of the database named {0} on {1}\\{2}.
    FailedToSetOwnerDatabase = Failed to set owner named {0} of the database named {1} on {2}\\{3}.
    FailedToSetPermissionDatabase = Failed to set permission for login named {0} of the database named {1} on {2}\\{3}.
    FailedToEnumDatabasePermissions = Failed to get permission for login named {0} of the database named {1} on {2}\\{3}.

    # SQLServerNetwork
    UnableToUseBothDynamicAndStaticPort = Unable to set both TCP dynamic port and TCP static port. Only one can be set.
'@
