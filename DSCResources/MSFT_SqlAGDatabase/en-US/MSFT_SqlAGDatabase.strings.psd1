# Localized resources for SqlAGDatabase

ConvertFrom-StringData @'
    AddingDatabasesToAvailabilityGroup = Adding the following databases to the '{0}' availability group: {1}.
    AlterAvailabilityGroupDatabaseMembershipFailure = {0}.
    AvailabilityGroupDoesNotExist = The availability group '{0}' does not exist.
    DatabaseShouldBeMember = The following databases should be a member of the availability group '{0}': {1}.
    DatabaseShouldNotBeMember = The following databases should not be a member of the availability group '{0}': {1}.
    DatabasesNotFound = The following databases were not found in the instance: {0}.
    ImpersonatePermissionsMissing = The login '{0}' is missing impersonate permissions in the instances '{1}'.
    NotActiveNode = The node '{0}' is not actively hosting the instance '{1}'. Exiting the test.
    ParameterNotOfType = The parameter '{0}' is not of the type '{1}'.
    ParameterNullOrEmpty = The parameter '{0}' is NULL or empty.
    RemovingDatabasesToAvailabilityGroup = Removing the following databases from the '{0}' availability group: {1}.
'@
