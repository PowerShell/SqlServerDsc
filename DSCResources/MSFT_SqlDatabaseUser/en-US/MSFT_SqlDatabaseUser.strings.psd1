ConvertFrom-StringData @'
    RetrievingDatabaseUser = Retrieving information about the database user '{0}' from the database '{1}'. (SDU0001)
    DatabaseNotFound = The database '{0}' does not exist. (SDU0002)
    EvaluateDatabaseUser = Determining if the database user '{0}' in the database '{1}' is in the desired state. (SDU0003)
    DatabaseUserExist = The database user '{0}' exist in the database '{1}'. (SDU0004)
    DatabaseUserDoesNotExist = The database user '{0}' does not exist in the database '{1}'. (SDU0005)
    InDesiredState = The database user is in desired state. (SDU0006)
    NotInDesiredState = The database user is not in desired state. (SDU0007)
    UnknownAuthenticationType = The databaser user has an, by the resource, unsupported combination of authentication type '{0}' and login type '{1}'. (SDU0008)
    LoginNameProvidedWithWrongUserType = A login name was provided but the user type is '{0}'. Change to the correct user type or remove the login name. (SDU0009)
    AsymmetricKeyNameProvidedWithWrongUserType = A asymmetric key name was provided but the user type is '{0}'. Change to the correct user type or remove the asymmetric key name. (SDU0010)
    CertificateNameProvidedWithWrongUserType = A certificate name was provided but the user type is '{0}'. Change to the correct user type or remove the certificate name. (SDU0011)
    CreateDatabaseUser = Creating the database user '{0}' in the database '{1}' with the user type '{2}'. (SDU0012)
    FailedCreateDatabaseUser = Failed creating the database user '{0}' in the database '{1}' with the user type '{2}'. (SDU0013)
    DropDatabaseUser = Removing the database user '{0}' from the database '{1}'. (SDU0014)
    FailedDropDatabaseUser = Failed removing the database user '{0}' from the database '{1}'. (SDU0015)
    SqlLoginNotFound = The SQL login '{0}' does not exist in the SQL Server instance. Failed to create the database user. (SDU0016)
    CertificateNotFound = The certificate '{0}' does not exist in the database '{1}'. Failed to create the database user. (SDU0017)
    AsymmetryKeyNotFound = The asymmetry key '{0}' does not exist in the database '{1}'. Failed to create the database user. (SDU0017)
    SetDatabaseUser = Setting the database user '{0}' in the database '{1}' to the desired state. (SDU0018)
    FailedUpdateDatabaseUser = Failed updating the database user '{0}' in the database '{1}' with the user type '{2}'. (SDU0020)
    ChangingLoginName = Changing the databaser user '{0}' to use the SQL login name '{1}'. (SDU0021)
    ChangingUserType = The database user '{0}' currently have the user type '{1}', but expected it to be '{2}'. Re-creating the database user '{0}' in the database '{3}'. (SDU0022)
    ChangingAsymmetricKey = The database user '{0}' currently have the asymmetric key '{1}', but expected it to be '{2}'. Re-creating the database user '{0}' in the database '{3}'. (SDU0022)
    ChangingCertificate = The database user '{0}' currently have the certificate '{1}', but expected it to be '{2}'. Re-creating the database user '{0}' in the database '{3}'. (SDU0022)
    LoginUserTypeWithoutLoginName = No login name was provided with the user type '{0}'. Add a login name to the configuration. (SDU0023)
    AsymmetricKeyUserTypeWithoutAsymmetricKeyName = No asymmetric key name was provided with the user type '{0}'. Add a asymmetric key name to the configuration. (SDU0024)
    CertificateUserTypeWithoutCertificateName = No certificate name was provided with the user type '{0}'. Add a certificate name to the configuration. (SDU0025)
'@
