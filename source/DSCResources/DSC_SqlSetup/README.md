# Description

The `SqlSetup` DSC resource installs SQL Server on the target node.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* For configurations that utilize the 'InstallFailoverCluster' action, the following
  parameters are required (beyond those required for the standalone installation).
  See the article [Install SQL Server from the Command Prompt](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
  under the section [Failover Cluster Parameters](https://msdn.microsoft.com/en-us/library/ms144259.aspx#Anchor_8)
  for more information.
  * InstanceName (can be MSSQLSERVER if you want to install a default clustered
    instance).
  * FailoverClusterNetworkName
  * FailoverClusterIPAddress
  * Additional parameters need when installing Database Engine.
    * InstallSQLDataDir
    * AgtSvcAccount
    * SQLSvcAccount
    * SQLSysAdminAccounts
  * Additional parameters need when installing Analysis Services.
    * ASSysAdminAccounts
    * AsSvcAccount
* The parameters below can only be used when installing SQL Server 2016 or
  later:
  * SqlTempdbFileCount
  * SqlTempdbFileSize
  * SqlTempdbFileGrowth
  * SqlTempdbLogFileSize
  * SqlTempdbLogFileGrowth

> **Note:** It is not possible to add or remove features to a SQL Server failover
cluster. This is a limitation of SQL Server. See article
[You cannot add or remove features to a SQL Server 2008, SQL Server 2008 R2, or
SQL Server 2012 failover cluster](https://support.microsoft.com/en-us/help/2547273/you-cannot-add-or-remove-features-to-a-sql-server-2008,-sql-server-2008-r2,-or-sql-server-2012-failover-cluster).

## Feature flags

Feature flags are used to toggle functionality on or off. One or more
feature flags can be added to the parameter `FeatureFlag`, i.e.
`FeatureFlag = @('DetectionSharedFeatures')`.

>**NOTE:** The functionality, exposed
with a feature flag, can be changed from one release to another, including
having breaking changes.

<!-- markdownlint-disable MD013 -->
Flag | Description
--- | ---
\- | -
<!-- markdownlint-enable MD013 -->

## Skip rules

The parameter `SkipRule` accept one or more skip rules with will be passed
to `setup.exe`. Using the parameter `SkipRule` is _not recommended_ in a
production environment unless there is a valid reason for it.

For more information about skip rules see the article [SQL 2012 Setup Rules – The 'Missing Reference'](https://deep.data.blog/2014/04/02/sql-2012-setup-rules-the-missing-reference/).

## Credentials for running the resource

### PsDscRunAsCredential

If PsDscRunAsCredential is set, the installation will be performed with those
credentials, and the user name will be used as the first system administrator.

### SYSTEM

If PsDscRunAsCredential is not assigned credentials then installation will be
performed by the SYSTEM account. When installing as the SYSTEM account, then
parameter SQLSysAdminAccounts and ASSysAdminAccounts must be specified when
installing feature Database Engine and Analysis Services respectively.

## Credentials for service accounts

### Service Accounts

Service account username containing dollar sign ('$') is allowed, but if the
dollar sign is at the end of the username it will be considered a Managed Service
Account.

### Managed Service Accounts

If a service account username has a dollar sign at the end of the name it will
be considered a Managed Service Account. Any password passed in
the credential object will be ignored, meaning the account is not expected to
need a '*SVCPASSWORD' argument in the setup arguments.

## Note about 'tempdb' properties

The properties `SqlTempdbFileSize` and `SqlTempdbFileGrowth` that are
returned from `Get-TargetResource` will return the sum of the average size
and growth. If tempdb has data files with both percentage and megabytes the
value returned is a sum of the average megabytes and the average percentage.
For example is there is one data file using growth 100MB and another file
having growth set to 10% then the returned value would be 110.
This will be notable if there are multiple files in the filegroup `PRIMARY`
with different sizes and growths.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlSetup).
