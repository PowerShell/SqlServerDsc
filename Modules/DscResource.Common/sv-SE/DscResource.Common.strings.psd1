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

    # Configuration
    ConfigurationOptionNotFound = Specified option '{0}' could not be found.
    ConfigurationRestartRequired = Configuration option '{0}' has been updated, but a manual restart of SQL Server is required for it to take effect.
'@
