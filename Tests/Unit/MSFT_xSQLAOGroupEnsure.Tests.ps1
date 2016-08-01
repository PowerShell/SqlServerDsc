# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()
<#
.Synopsis
   Template for creating DSC Resource Unit Tests
.DESCRIPTION
   To Use:
     1. Copy to \Tests\Unit\ folder and rename <ResourceName>.tests.ps1 (e.g. MSFT_xFirewall.tests.ps1)
     2. Customize TODO sections.

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>


# TODO: Customize these parameters...
$script:DSCModuleName      = 'xSQLServer' # Example xNetworking
$script:DSCResourceName    = 'MSFT_xSQLAOGroupEnsure' # Example MSFT_xFirewall
# /TODO

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{
    #region Pester Test Initialization

    # TODO: Optionally create any variables here for use by your tests
    # See https://github.com/PowerShell/xNetworking/blob/dev/Tests/Unit/MSFT_xDhcpClient.Tests.ps1
    # Mocks that should be applied to all cmdlets being tested may
    # also be created here if required.

    #endregion Pester Test Initialization

    # TODO: Common DSC Resource describe block structure
    # The following three Describe blocks are included as a common test pattern.
    # If a different test pattern would be more suitable, then test describe blocks
    # may be completely replaced. The goal of this pattern should be to describe 
    # the potential states a system could be in so that the get/test/set cmdlets
    # can be tested in those states. Any mocks that relate to that specific state
    # can be included in the relevant describe block. For a more detailed description
    # of this approach please review https://github.com/PowerShell/DscResources/issues/143 

    # Add as many of these example 'states' as required to simulate the scenarions that
    # the DSC resource is designed to work with, below a simple "is in desired state" and
    # "is not in desired state" are used, but there may be more complex combinations of 
    # factors, depending on how complex your resource is.

    #region Get-TargetResource
    Describe 'Get-TargetResource'{
        Mock -ModuleName 'MSFT_xSQLAOGroupEnsure' -CommandName Connect-SQL -MockWith {
                    # build a custom object to return which is close to the real SMO object
                    $smoObj = [PSCustomObject]@{
                                SQLServer = 'Node01';
                                SQLInstanceName = 'Prd01';
                                ClusterName = 'Clust01';
                            }
                    # add the AvailabilityGroups entry as this is an ArrayList and allows us the functionality later
                    $smoObj | Add-Member -MemberType NoteProperty -Name 'AvailabilityGroups' -Value @{
                                        'AG01' = @{
                                            AvailabilityGroupListeners = @{ 
                                                name = 'AgList01';
                                                availabilitygrouplisteneripaddresses = [System.Collections.ArrayList]@(@{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'});
                                                portnumber = 5022;};
                                            AvailabilityDatabases = @(@{name='AdventureWorks'});
                                            };
                                        };
                    # we need to be able to call the Add method like we would for an array but it needs to also function like a hashtable so override the Add method
                    #$smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {param($value) $_.AvailabilityGroups[$value.Name] = $value} -Force;
                    $smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {return $true} -Force;
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force;
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force;
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name Drop -Value {return $true} -Force;
                return $smoObj
            }
    
        Context "When the configuration is already set" {
            
            $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
            $username = "dba" 
            $credential = New-Object System.Management.Automation.PSCredential($username,$password)
    
            $SqlAOGroup = Get-TargetResource -Ensure 'Present' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $credential;
    
            It 'Should return hashtable with Ensure = $true'{
                $SqlAOGroup.Ensure | Should Be $true
            }
         }
    
         Context "When the configuration is not yet set or has drift" {
            
            $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
            $username = "dba" 
            $credential = New-Object System.Management.Automation.PSCredential($username,$password)
    
            $SqlAOGroup = Get-TargetResource -Ensure 'Absent' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $credential;
    
            It 'Should return hashtable with Ensure = $false'{
                $SqlAOGroup.Ensure | Should Be $false
            }
         }
    }
    #endregion Get-TargetResource

    #region Test-TargetResource
    Describe 'Test-TargetResource'{
        Mock -ModuleName 'MSFT_xSQLAOGroupEnsure' -CommandName Connect-SQL -MockWith {
                    # build a custom object to return which is close to the real SMO object
                    $smoObj = [PSCustomObject]@{
                                SQLServer = 'Node01';
                                SQLInstanceName = 'Prd01';
                                ClusterName = 'Clust01';
                            }
                    # add the AvailabilityGroups entry as this is an ArrayList and allows us the functionality later
                    $smoObj | Add-Member -MemberType NoteProperty -Name 'AvailabilityGroups' -Value @{
                                        'AG01' = @{
                                            AvailabilityGroupListeners = @{ 
                                                name = 'AgList01';
                                                availabilitygrouplisteneripaddresses = [System.Collections.ArrayList]@(@{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'});
                                                portnumber = 5022;};
                                            AvailabilityDatabases = @(@{name='AdventureWorks'});
                                            };
                                        };
                    # we need to be able to call the Add method like we would for an array but it needs to also function like a hashtable so override the Add method
                    #$smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {param($value) $_.AvailabilityGroups[$value.Name] = $value} -Force;
                    $smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {return $true} -Force;
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force;
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force;
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name Drop -Value {return $true} -Force;
                return $smoObj
            }
    
        Context "When the configuration is valid" {
            
            $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
            $username = "dba" 
            $credential = New-Object System.Management.Automation.PSCredential($username,$password)
    
            $SqlAOGroupTest = Test-TargetResource -Ensure 'Present' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $credential;
    
            It 'Should return $true'{
                $SqlAOGroupTest | Should Be $true
            }
         }
    
         Context "When the configuration has drifted" {
            
            $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
            $username = "dba" 
            $credential = New-Object System.Management.Automation.PSCredential($username,$password)
    
            $SqlAOGroupTest = Test-TargetResource -Ensure 'Absent' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $credential;
    
            It 'Should return $false'{
                $SqlAOGroupTest | Should Be $false
            }
         }
    }
    #endregion Test-TargetResource

Describe 'Set-TargetResource'{
    
    # create this first as we need to override the new-object cmdlet later
    $password = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
    $username = "dba";
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)

    InModuleScope 'MSFT_xSQLAOGroupEnsure' {
        function Get-ClusterNode
        {
            [CmdLetBinding()]
            Param(
                [string]$Cluster
            )

        }

        $source = @"
namespace Microsoft.SqlServer.Management.Smo
{
    public class AvailabilityReplicaFailoverMode
    {
        public static string Automatic = "Automatic";
        public static string Manual = "Manual";
        public static string Unknown = "Unknown";
    }
}
"@
        Add-Type -TypeDefinition $source

        $source = @"
namespace Microsoft.SqlServer.Management.Smo
{
    public class AvailabilityReplicaAvailabilityMode
    {
        public static string AsynchronousCommit = "AsynchronousCommit";
        public static string SynchronousCommit = "SynchronousCommit";
        public static string Unknown = "Unknown";
    }
}
"@
        Add-Type -TypeDefinition $source
    

        Mock -CommandName Connect-SQL -MockWith {
                # build a custom object to return which is close to the real SMO object
                $smoObj = [PSCustomObject]@{
                            SQLServer = 'Node01';
                            SQLInstanceName = 'Prd01';
                            ClusterName = 'Clust01';
                        }
                # add the AvailabilityGroups entry as this is an ArrayList and allows us the functionality later
                $smoObj | Add-Member -MemberType NoteProperty -Name 'AvailabilityGroups' -Value @{
                                    'AG01' = @{
                                        AvailabilityGroupListeners = @{ 
                                            name = 'AgList01';
                                            availabilitygrouplisteneripaddresses = [System.Collections.ArrayList]@(@{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'});
                                            portnumber = 5022;};
                                        AvailabilityDatabases = @(@{name='AdventureWorks'});
                                        };
                                    };
                # we need to be able to call the Add method like we would for an array but it needs to also function like a hashtable so override the Add method
                #$smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {param($value) $_.AvailabilityGroups[$value.Name] = $value} -Force;
                $smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {return $true} -Force;
                $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force;
                $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force;
                $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name Drop -Value {return $true} -Force;
            return $smoObj
        }
        Mock -CommandName Grant-ServerPerms -MockWith {
            New-VerboseMessage -Message "Granted Permissions to $AuthorizedUser"
        }
        Mock -CommandName New-ListenerADObject -MockWith {
            New-VerboseMessage -Message "Created new Listener Object"
        }
        Mock -CommandName New-Object -MockWith {
            Param($TypeName)
            Switch ($TypeName)
            {
                'Microsoft.SqlServer.Management.Smo.AvailabilityGroup' {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject";
                                AutomatedBackupPreference = '';
                                FailureConditionLevel = '';
                                HealthCheckTimeout = '';
                                AvailabilityReplicas = [System.Collections.ArrayList]@();
                                AvailabilityGroupListeners = [System.Collections.ArrayList]@();
                            }
                    $object | Add-Member -MemberType ScriptMethod -Name Create -Value {return $true};
                }
                'Microsoft.SqlServer.Management.Smo.AvailabilityReplica' {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject";
                                EndpointUrl = '';
                                FailoverMode = '';
                                AvailabilityMode = '';
                                BackupPriority = 0;
                                ConnectionModeInPrimaryRole = '';
                                ConnectionModeInSecondaryRole = '';
                             }
                }
                'Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener' {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject";
                                PortNumber = '';
                                AvailabilityGroupListenerIPAddresses = [System.Collections.ArrayList]@();
                            }
                }
                'Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress' {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject";
                                IsDHCP = '';
                                IPAddress = '';
                                SubnetMask = '';
                            }
                }
                Default {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject";
                            }
                }
            }
            return $object;
        }
        Mock Get-Module -MockWith {
            return 'Module Name';
        }

        Mock Get-ClusterNode -MockWith {
            $clusterNode = @(
                            [PSCustomObject]@{
                                    Name = 'Node01';
                                };
                            , [PSCustomObject]@{
                                    Name = 'Node02';
                                };
                            , [PSCustomObject]@{
                                    Name = 'Node03';
                                };
                            , [PSCustomObject]@{
                                    Name = 'Node04';
                                };
                            )
            return $clusterNode;
        }
    }


    Context "Set the configuration" {
        
        # setup the params for the function using splatting method
        $Params = @{
                    Ensure = 'Present';
                    AvailabilityGroupName = 'AG01';
                    AvailabilityGroupNameListener = 'AgList01';
                    AvailabilityGroupNameIP = '192.168.0.1';
                    AvailabilityGroupSubMask = '255.255.255.0';
                    AvailabilityGroupPort = 1433;
                    ReadableSecondary = 'ReadOnly';
                    AutoBackupPreference = 'Primary';
                    SQLServer = 'localhost';
                    SQLInstanceName = 'MSSQLSERVER';
                    SetupCredential = $credential;
                }

        $SqlAOGroup = Set-TargetResource @Params;
        
        #this shouldn't have generated any errors which they are caught by pester without further checks
     }
    
}
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
