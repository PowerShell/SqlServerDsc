<#
    .NOTES
        THIS EXAMPLE IS OBSOLETE. Due to major changes to the resource modules
        (this and other modules) over the last few months this example has not
        been updated to reflect those changes.
        Please refer to the examples in each individual resource example folder
        for updated examples.
        https://github.com/PowerShell/SqlServerDsc/tree/dev/Examples/Resources

        There is an issue open to replace this example, please see issue
        https://github.com/PowerShell/SqlServerDsc/issues/462
#>

$StartTime = [System.Diagnostics.Stopwatch]::StartNew()
Function check-even($num){[bool]!($num%2)}

$computers = 'OHSQL9013','OHSQL9014'
$OutputPath = 'F:\DSCConfig'


$cim = New-CimSession -ComputerName $computers

[DSCLocalConfigurationManager()]
Configuration LCM_Push
{
    Param(
        [string[]]$ComputerName
    )
    Node $ComputerName
    {
    Settings
        {
            AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RefreshMode = 'Push'
            RebootNodeIfNeeded = $True
        }
    }
}

foreach ($computer in $computers)
{
    $GUID = (New-Guid).Guid
    LCM_Push -ComputerName $Computer -OutputPath $OutputPath
    Set-DSCLocalConfigurationManager -Path $OutputPath  -CimSession $computer -Verbose
}

Configuration AlwaysOnCluster
{
    Import-DscResource –Module PSDesiredStateConfiguration
    Import-DscResource -Module SqlServerDSC
    Import-DscResource -Module xFailoverCluster

   Node $AllNodes.Where{$_.Role -eq "PrimaryClusterNode" }.NodeName
   {
        # Set LCM to reboot if needed
        LocalConfigurationManager
        {
            AllowModuleOverwrite = $true
            RefreshMode = 'Push'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            DebugMode = "All"
        }

        WindowsFeature "NET"
        {
            Ensure = "Present"
            Name = "NET-Framework-Core"
            Source = $Node.NETPath
        }

        WindowsFeature "ADTools"
        {
            Ensure = "Present"
            Name = "RSAT-AD-PowerShell"
            Source = $Node.NETPath
        }

      if($Node.Features)
      {
         xSqlServerSetup ($Node.NodeName)
         {
             SourcePath = $Node.SourcePath
             SetupCredential = $Node.InstallerServiceAccount
             InstanceName = $Node.InstanceName
             Features = $Node.Features
             SQLSysAdminAccounts = $Node.AdminAccount
             SQLSvcAccount = $Node.InstallerServiceAccount
             InstallSharedDir = "G:\Program Files\Microsoft SQL Server"
             InstallSharedWOWDir = "G:\Program Files (x86)\Microsoft SQL Server"
             InstanceDir = "G:\Program Files\Microsoft SQL Server"
             InstallSQLDataDir = "G:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLUserDBDir = "G:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLUserDBLogDir = "L:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLTempDBDir = "T:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLTempDBLogDir = "L:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLBackupDir = "G:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"

             DependsOn = '[WindowsFeature]NET'
         }

         SqlWindowsFirewall ($Node.NodeName)
          {
             SourcePath = $Node.SourcePath
             InstanceName = $Node.InstanceName
             Features = $Node.Features

             DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
         }

         SqlServerMemory ($Node.Nodename)
         {
             Ensure = "Present"
             DynamicAlloc = $True

             DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
         }

         SqlServerMaxDop($Node.Nodename)
         {
             Ensure = "Present"
             DynamicAlloc = $true

             DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
         }
       }

       WindowsFeature FailoverFeature
       {
           Ensure = "Present"
           Name      = "Failover-clustering"

           DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
       }

       WindowsFeature RSATClusteringMgmt
       {
           Ensure = "Present"
           Name = "RSAT-Clustering-Mgmt"

           DependsOn = "[WindowsFeature]FailoverFeature"
       }

       WindowsFeature RSATClusteringPowerShell
       {
           Ensure = "Present"
           Name   = "RSAT-Clustering-PowerShell"

           DependsOn = "[WindowsFeature]FailoverFeature"
       }

       WindowsFeature RSATClusteringCmdInterface
       {
           Ensure = "Present"
           Name   = "RSAT-Clustering-CmdInterface"

           DependsOn = "[WindowsFeature]RSATClusteringPowerShell"
       }

       xCluster ensureCreated
       {
           Name = $Node.ClusterName
           StaticIPAddress = $Node.ClusterIPAddress
           DomainAdministratorCredential = $Node.InstallerServiceAccount

           DependsOn = “[WindowsFeature]RSATClusteringCmdInterface”
       }
       SqlAlwaysOnService($Node.Nodename)
       {
            Ensure = "Present"

            DependsOn = ("[xCluster]ensureCreated"),("[xSqlServerSetup]" + $Node.NodeName)
       }

       SqlServerEndpoint($Node.Nodename)
       {
           Ensure = "Present"
           Port = 5022
           AuthorizedUser = "CORP\AutoSvc"
           EndPointName = "Hadr_endpoint"
           DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
       }

       xSQLAOGroupEnsure($Node.Nodename)
       {
          Ensure = "Present"
          AvailabilityGroupName = "MyAG"
          AvailabilityGroupNameListener = "MyAGList"
          AvailabilityGroupNameIP = "10.0.75.201"
          AvailabilityGroupSubMask ="255.255.255.0"
          SetupCredential = $Node.InstallerServiceAccount
          PsDscRunAsCredential = $Node.InstallerServiceAccount
          DependsOn = ("[SqlServerEndpoint]" + $Node.NodeName),("[SqlAlwaysOnService]" + $Node.NodeName),("[WindowsFeature]ADTools")
       }
    }
    Node $AllNodes.Where{$_.Role -eq "ReplicaServerNode" }.NodeName
    {
            # Set LCM to reboot if needed
        LocalConfigurationManager
        {
            AllowModuleOverwrite = $true
            RefreshMode = 'Push'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            DebugMode = "All"
        }

        WindowsFeature "NET"
        {
            Ensure = "Present"
            Name = "NET-Framework-Core"
            Source = $Node.NETPath
        }

      if($Node.Features)
      {
         xSqlServerSetup ($Node.NodeName)
         {
             SourcePath = $Node.SourcePath
             SetupCredential = $Node.InstallerServiceAccount
             InstanceName = $Node.InstanceName
             Features = $Node.Features
             SQLSysAdminAccounts = $Node.AdminAccount
             SQLSvcAccount = $Node.InstallerServiceAccount
             InstallSharedDir = "G:\Program Files\Microsoft SQL Server"
             InstallSharedWOWDir = "G:\Program Files (x86)\Microsoft SQL Server"
             InstanceDir = "G:\Program Files\Microsoft SQL Server"
             InstallSQLDataDir = "G:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLUserDBDir = "G:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLUserDBLogDir = "L:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLTempDBDir = "T:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLTempDBLogDir = "L:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
             SQLBackupDir = "G:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"

             DependsOn = '[WindowsFeature]NET'
         }

         SqlWindowsFirewall ($Node.NodeName)
         {
             SourcePath = $Node.SourcePath
             InstanceName = $Node.InstanceName
             Features = $Node.Features

             DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
         }

         SqlServerMemory ($Node.Nodename)
         {
             Ensure = "Present"
             DynamicAlloc = $True

             DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
         }
         SqlServerMaxDop($Node.Nodename)
         {
             Ensure = "Present"
             DynamicAlloc = $true

             DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
         }

       }

       WindowsFeature FailoverFeature
       {
           Ensure = "Present"
           Name      = "Failover-clustering"

           DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
       }

       WindowsFeature RSATClusteringPowerShell
       {
           Ensure = "Present"
           Name   = "RSAT-Clustering-PowerShell"

           DependsOn = "[WindowsFeature]FailoverFeature"
       }

       WindowsFeature RSATClusteringMgmt
       {
           Ensure = "Present"
           Name = "RSAT-Clustering-Mgmt"

           DependsOn = "[WindowsFeature]FailoverFeature"
       }

       WindowsFeature RSATClusteringCmdInterface
       {
           Ensure = "Present"
           Name   = "RSAT-Clustering-CmdInterface"

           DependsOn = "[WindowsFeature]RSATClusteringPowerShell"
       }

       xWaitForCluster waitForCluster
       {
           Name = $Node.ClusterName
           RetryIntervalSec = 10
           RetryCount = 6

           DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
       }

       xCluster joinCluster
       {
           Name = $Node.ClusterName
           StaticIPAddress = $Node.ClusterIPAddress
           DomainAdministratorCredential = $Node.InstallerServiceAccount

           DependsOn = "[xWaitForCluster]waitForCluster"
       }
       SqlAlwaysOnService($Node.Nodename)
       {
            Ensure = "Present"

            DependsOn = ("[xCluster]joinCluster"),("[xSqlServerSetup]" + $Node.NodeName)
       }
       SqlServerEndpoint($Node.Nodename)
       {
           Ensure = "Present"
           Port = 5022
           AuthorizedUser = "CORP\AutoSvc"
           EndPointName = "Hadr_endpoint"
           DependsOn = ("[xSqlServerSetup]" + $Node.NodeName)
       }

       SqlWaitForAG waitforAG
       {
           Name = "MyAG"
           RetryIntervalSec = 20
           RetryCount = 6

           DependsOn = (“[SqlServerEndpoint]" +$Node.Nodename),(“[SqlServerAlwaysOnService]" +$Node.Nodename)
       }

       xSQLAOGroupJoin ($Node.Nodename)
       {
          Ensure = "Present"
          AvailabilityGroupName = "MyAG"
          SetupCredential = $Node.InstallerServiceAccount
          PsDscRunAsCredential = $Node.InstallerServiceAccount

          DependsOn = ("[SqlWaitForAG]waitforAG")
       }

    }
}
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser =$true
            NETPath = "\\ohdc9000\SQLAutoBuilds\SQL2014\WindowsServer2012R2\sources\sxs"
            SourcePath = "\\ohdc9000\SQLAutoBuilds\SQL2014\"
            InstallerServiceAccount = Get-Credential -UserName CORP\AutoSvc -Message "Credentials to Install SQL Server"
            AdminAccount = "Corp\user1"
            ClusterName = "DevCluster"
            ClusterIPAddress = "10.0.75.199/24"
        }
    )
}
$firstComputer = $computers | Select-Object -First 1
ForEach ($computer in $computers) {

    if($firstComputer -eq $computer)
    {
            $ConfigurationData.AllNodes += @{
            NodeName        = $computer
            InstanceName    = "MSSQLSERVER"
            Features        = "SQLENGINE,IS,SSMS,ADV_SSMS"
            Role = "PrimaryClusterNode"
            }
    }
    else
    {
            $ConfigurationData.AllNodes += @{
            NodeName        = $computer
            InstanceName    = "MSSQLSERVER"
            Features        = "SQLENGINE,IS,SSMS,ADV_SSMS"
            Role = "ReplicaServerNode"
            }
    }
   $Destination = "\\"+$computer+"\\c$\Program Files\WindowsPowerShell\Modules"
   if (Test-Path "$Destination\xFailoverCluster"){Remove-Item -Path "$Destination\xFailoverCluster" -Recurse -Force}
   if (Test-Path "$Destination\xSqlServer"){Remove-Item -Path "$Destination\xSqlServer"-Recurse -Force}
   Copy-Item 'C:\Program Files\WindowsPowerShell\Modules\xFailoverCluster' -Destination $Destination -Recurse -Force
   Copy-Item 'C:\Program Files\WindowsPowerShell\Modules\xSqlServer' -Destination $Destination -Recurse -Force
}

AlwaysOnCluster -ConfigurationData $ConfigurationData -OutputPath $OutputPath

#Push################################

Workflow StartConfigs
{
    param([string[]]$computers,
        [System.string] $Path)

    foreach –parallel ($Computer in $Computers)
    {

        Start-DscConfiguration -ComputerName $Computer -Path $Path -Verbose -Wait -Force
    }
}

StartConfigs -Computers $computers -Path $OutputPath

$StartTime.Elapsed

############Validate##############
<#
Workflow TestConfigs
{
    param([string[]]$computers)
    foreach -parallel ($Computer in $Computers)
    {
        Write-verbose "$Computer :"
        test-dscconfiguration -ComputerName $Computer
    }
}

TestConfigs -computers $computers
#>
