# Localized resources for MSFT_SqlServerAgentOperator

ConvertFrom-StringData @'
    GetSqlAgents = Getting SQL Agent Operators.
    SqlAgentPresent = SQL Agent Operator '{0}' is present.
    SqlAgentAbsent = SQL Agent Operator '{0}' is absent.
    UpdatingSqlAgentOperator = Updating SQL Agent Operator '{0}' with specified settings.
    UpdateOperatorSetError = Unable to update the email address for '{2}' to '{3}' on {0}\\{1}.
    AddSqlAgentOperator = Adding SQL Agent Operator '{0}'.
    UpdateEmailAddress = Updating email address to '{0}' for '{1}'.
    CreateOperatorSetError = Unable to create the SQL Agent Operator '{0}' on {1}\\{2}.
    DeleteSqlAgentOperator = Deleting SQL Agent Operator '{0}'.
    DropOperatorSetError = Unable to drop the SQL Agent Operator '{0}' on {1}\\{2}.
    TestSqlAgentOperator = Checking if SQL Agent Operator '{0}' is present of absent.
    SqlAgentOperatorExistsButShouldNot = Ensure is set to Absent. The SQL Agent Operator '{0}' should be dropped.
    SqlAgentOperatorDoesNotExistButShould  = Ensure is set to Present. The SQL Agent Operator '{0}' should be created.
    SqlAgentOperatorExistsButEmailWrong  = SQL Agent Operator '{0}' exists but has the wrong email address.
'@
