# Description

The `SqlRSSetup` DSC resource installs the standalone
[Microsoft SQL Server Reporting Services](https://docs.microsoft.com/en-us/sql/reporting-services/create-deploy-and-manage-mobile-and-paginated-reports).

If both `SourceCredential` and `PsDscRunAsCredential` is used then the
credentials in `SourceCredential` will only be used to copy the
installation media locally, and then the credentials in `PsDscRunAsCredential`
will be used during installation. If `PsDscRunAsCredential` is not
used, then the installation will run as SYSTEM.

>To install Microsoft SQL Server Reporting Services 2016 (or older),
>please use the resource SqlSetup.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* If `PsDscRunAsCredential` common parameter is used to run the resource,
  the specified credential must have permissions to connect to the location
  where the Microsoft SQL Server Reporting Services media is placed.
* The parameter IAcceptLicenseTerms must be set to 'Yes'.
* The parameter InstanceName can only be set to 'SSRS' since there is
  no way to change the instance name.
* When using action 'Uninstall', the same version of the executable as the version
  of the installed product must be used. If not, sometimes the uninstall
  is successful (because the executable returns exit code 0) but the
  Microsoft SQL Server Reporting Services instance was not actually removed.

>NOTE: When using the action 'Uninstall' and the target node to begin with
>requires a restart, on the first run the Microsoft SQL Server Reporting
>Services instance will not be uninstalled, but instead exits with code
>3010 and the node will be, by default, restarted. On the second run after
>restart, the Microsoft SQL Server Reporting Services instance will be
>uninstalled. If the parameter SuppressRestart is used, then the node must
>be restarted manually before the Microsoft SQL Server Reporting Services
>instance will be successfully uninstalled.
>
>The Microsoft SQL Server Reporting Services log will indicate that a
>restart is required by outputting; "*No action was taken as a system
>reboot is required (0x8007015E)*". The log is default located in the
>SSRS folder in `%TEMP%`, e.g. `C:\Users\<user>\AppData\Local\Temp\SSRS`.

## Known issues

* [SqlRSSetup: Will always make an edition upgrade](https://github.com/dsccommunity/SqlServerDsc/issues/1311)

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlRSSetup).
