ConvertFrom-StringData @'
    GetDatabase = Get the state of the database '{0}' on the instance '{1}'.
    DatabasePresent = The database '{0}' is present.
    DatabaseAbsent = It does not exist a database named '{0}'.
    InvalidCollation = The specified collation '{0}' is not a valid collation for the instance '{1}'.
    InvalidCompatibilityLevel = The specified compatibility level '{0}' is not a valid compatibility level for the instance '{1}'.
    SetDatabase = Changing properties of the database '{0}' on the instance '{1}'.
    UpdatingRecoveryModel = Changing the database recovery model to '{0}'.
    UpdatingCollation = Changing the database collation to '{0}'.
    UpdatingCompatibilityLevel = Changing the database compatibility level to '{0}'.
    FailedToUpdateDatabase = Failed to update database {0} with specified changes.
    CreateDatabase = Creating the database '{0}'.
    DropDatabase = Removing the database '{0}'.
    FailedToCreateDatabase = Failed to create the database '{0}'.
    FailedToDropDatabase = Failed to remove the database '{0}'
    TestingConfiguration = Determines the state of the database '{0}' on the instance '{1}'.
    NotInDesiredStateAbsent = Expected the database '{0}' to absent, but it was present.
    NotInDesiredStatePresent = Expected the database '{0}' to present, but it was absent
    CollationWrong = The database '{0}' exist and has the collation '{1}', but expected it to have the collation '{2}'.
    CompatibilityLevelWrong = The database '{0}' exist and has the compatibility level '{1}', but expected it to have the compatibility level '{2}'.
    RecoveryModelWrong = The database '{0}' exist and has the recovery model '{1}', but expected it to have the recovery model '{2}'.
    OwnerNameWrong = The database '{0}' exist and has the owner '{1}', but expected it to have the owner '{2}'.
    UpdatingOwner = Changing the database owner to '{0}'.
    FailedToUpdateOwner = Failed changing to owner to '{0}' for the database '{1}'.
'@
