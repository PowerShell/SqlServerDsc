# Credential Overview

## Group Managed Service Account

To support [Group Managed Service Accounts](https://docs.microsoft.com/en-us/windows-server/security/group-managed-service-accounts/group-managed-service-accounts-overview)
(gMSAs) the DSC resource must support it. This also applies to Managed Service
Accounts (MSAs).

There are more information about using (g)MSAs with SQL Server
in the article [Configure Windows Service Accounts and Permissions](https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-windows-service-accounts-and-permissions) in section [Managed Service Accounts, Group Managed Service Accounts, and Virtual Accounts](https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-windows-service-accounts-and-permissions#New_Accounts)

To use a (g)MSA with a DSC resource you should pass the (g)MSA account name
in the credential object and use any text string as password.

>It is not possible to pass `$null` as password, it is a limitation by
>how the MOF is generated when encrypting passwords.

If there is a resource that you find that will not work with a (g)MSAs then
please submit a [new issue](https://github.com/dsccommunity/SqlServerDsc/issues/new?template=Problem_with_resource.md).
Then the community can work together to support (g)MSAs for that DSC resource
too.

For designing a resource for (g)MSAs see the section [Group Managed Service Account](https://github.com/dsccommunity/SqlServerDsc/blob/main/CONTRIBUTING.md#group-managed-service-account)
in the contribution guidelines.

<sup>_This was discussed in [issue #738](https://github.com/dsccommunity/SqlServerDsc/issues/738)_.</sup>

## Built-In Account

To use a built-in account with a DSC resource you should pass the built-in
account name, e.g. 'NT AUTHORITY\NetworkService' in the credential object
and use any text string as password.

>It is not possible to pass `$null` as password, it is a limitation by
>how the MOF is generated when encrypting passwords.

If there is a resource that you find that will not work with a built-in account
then please submit a [new issue](https://github.com/dsccommunity/SqlServerDsc/issues/new?template=Problem_with_resource.md).
Then the community can work together to support built-in accounts for that
DSC resource too.
