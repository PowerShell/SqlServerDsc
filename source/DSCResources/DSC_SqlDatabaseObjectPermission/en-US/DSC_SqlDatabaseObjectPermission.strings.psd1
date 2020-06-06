ConvertFrom-StringData @'
    GetObjectPermission = Getting the current state of the permissions for the database object '{0}' of type '{1}' in the database '{2}' for the instance '{3}' on the server '{4}'. (SDOP0001)
    TestDesiredState = Determining the current state of the permissions for the database object '{0}' of type '{1}' in the database '{2}' for the instance '{3}' on the server '{4}'. (SDOP0002)
    NotInDesiredState = The permissions for the database object '{0}' is not in desired state. (SDOP0003)
    InDesiredState = The permissions for the database object '{0}' is in desired state. (SDOP0004)
    FailedToGetDatabaseObject = Failed to get the database object '{0}' of type '{1}' in the database '{2}'. (SDOP0005)
    DatabaseObjectIsInDesiredState = The database object '{0}' of type '{1}' is already in desired state. (SDOP0006)
    SetPermission = Setting permissions '{0}' for the user '{1}' with the state '{2}' for the database object '{3}' of type '{4}' in the database '{5}' (SDOP0007)
    RevokePermission = Revoking permissions '{0}' for the user '{1}' and the state '{2}' for the database object '{3}' of type '{4}' in the database '{5}' (SDOP0008)
    SetDesiredState = Setting the desired permissions for the database object '{0}'. (SDOP0009)
    FailedToSetDatabaseObjectPermission = Failed to set the permissions for the user '{0}' on the database object '{1}' in the database '{2}'. (SDOP0009)
    PermissionStateInDesiredState = The permission state '{0}' is already in desired state for database object '{1}'.
'@
