# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:DSCModuleName      = 'xSQLServer' 
$script:DSCResourceName    = 'MSFT_xSQLAOGroupEnsure'

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

# Begin Testing
try
{
    $mockpassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
    $mockusername = "dba" 
    $mockcredential = New-Object System.Management.Automation.PSCredential($mockusername,$mockpassword)
    
    #region Get-TargetResource
    Describe 'Get-TargetResource'{
        Mock -ModuleName 'MSFT_xSQLAOGroupEnsure' -CommandName Connect-SQL -MockWith {
                    # build a custom object to return which is close to the real SMO object
                    $smoObj = [PSCustomObject]@{
                                SQLServer = 'Node01'
                                SQLInstanceName = 'Prd01'
                                ClusterName = 'Clust01'
                            }
                    # add the AvailabilityGroups entry as this is an ArrayList and allows us the functionality later
                    $smoObj | Add-Member -MemberType NoteProperty -Name 'AvailabilityGroups' -Value @{
                                        'AG01' = @{
                                            AvailabilityGroupListeners = @{ 
                                                name = 'AgList01'
                                                availabilitygrouplisteneripaddresses = [System.Collections.ArrayList]@(@{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'})
                                                portnumber = 5022}
                                            AvailabilityDatabases = @(@{name='AdventureWorks'})
                                            }
                                        }

                    $smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {return $true} -Force
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name Drop -Value {return $true} -Force
                return $smoObj
            }
        
        Context "When the configuration is already set" {
            
            $SqlAOGroup = Get-TargetResource -Ensure 'Present' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $mockcredential
    
            It 'Should return hashtable with Ensure = $true'{
                $SqlAOGroup.Ensure | Should Be $true
            }
         }
    
         Context "When the configuration is not yet set or has drift" {
    
            $SqlAOGroup = Get-TargetResource -Ensure 'Absent' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $mockcredential
    
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
                                SQLServer = 'Node01'
                                SQLInstanceName = 'Prd01'
                                ClusterName = 'Clust01'
                            }
                    # add the AvailabilityGroups entry as this is an ArrayList and allows us the functionality later
                    $smoObj | Add-Member -MemberType NoteProperty -Name 'AvailabilityGroups' -Value @{
                                        'AG01' = @{
                                            AvailabilityGroupListeners = @{ 
                                                name = 'AgList01'
                                                availabilitygrouplisteneripaddresses = [System.Collections.ArrayList]@(@{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'})
                                                portnumber = 5022}
                                            AvailabilityDatabases = @(@{name='AdventureWorks'})
                                            }
                                        }

                    $smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {return $true} -Force
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force
                    $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name Drop -Value {return $true} -Force
                return $smoObj
            }
    
        Context "When the configuration is valid" {
    
            $SqlAOGroupTest = Test-TargetResource -Ensure 'Present' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $mockcredential
    
            It 'Should return $true'{
                $SqlAOGroupTest | Should Be $true
            }
         }
    
         Context "When the configuration has drifted" {
              
            $SqlAOGroupTest = Test-TargetResource -Ensure 'Absent' -AvailabilityGroupName 'AG01' -SQLServer 'localhost' -SQLInstanceName 'MSSQLSERVER' -SetupCredential $mockcredential
    
            It 'Should return $false'{
                $SqlAOGroupTest | Should Be $false
            }
         }
    }
    #endregion Test-TargetResource

Describe 'Set-TargetResource'{
    
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
        public static string Automatic = "Automatic"
        public static string Manual = "Manual"
        public static string Unknown = "Unknown"
    }
}
"@
        Add-Type -TypeDefinition $source

        $source = @"
namespace Microsoft.SqlServer.Management.Smo
{
    public class AvailabilityReplicaAvailabilityMode
    {
        public static string AsynchronousCommit = "AsynchronousCommit"
        public static string SynchronousCommit = "SynchronousCommit"
        public static string Unknown = "Unknown"
    }
}
"@
        Add-Type -TypeDefinition $source
    

        Mock -CommandName Connect-SQL -MockWith {
                # build a custom object to return which is close to the real SMO object
                $smoObj = [PSCustomObject]@{
                            SQLServer = 'Node01'
                            SQLInstanceName = 'Prd01'
                            ClusterName = 'Clust01'
                        }
                # add the AvailabilityGroups entry as this is an ArrayList and allows us the functionality later
                $smoObj | Add-Member -MemberType NoteProperty -Name 'AvailabilityGroups' -Value @{
                                    'AG01' = @{
                                        AvailabilityGroupListeners = @{ 
                                            name = 'AgList01'
                                            availabilitygrouplisteneripaddresses = [System.Collections.ArrayList]@(@{IpAddress = '192.168.0.1'; SubnetMask = '255.255.255.0'})
                                            portnumber = 5022}
                                        AvailabilityDatabases = @(@{name='AdventureWorks'})
                                        }
                                    }

                $smoObj.AvailabilityGroups | Add-Member -MemberType ScriptMethod -Name 'Add' -Value {return $true} -Force
                $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType NoteProperty -Name Name -Value 'AG01' -Force
                $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name ToString -Value {return 'AG01'} -Force
                $smoObj.AvailabilityGroups['AG01'] | Add-Member -MemberType ScriptMethod -Name Drop -Value {return $true} -Force
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
                                Name = "MockedObject"
                                AutomatedBackupPreference = ''
                                FailureConditionLevel = ''
                                HealthCheckTimeout = ''
                                AvailabilityReplicas = [System.Collections.ArrayList]@()
                                AvailabilityGroupListeners = [System.Collections.ArrayList]@()
                            }
                    $object | Add-Member -MemberType ScriptMethod -Name Create -Value {return $true}
                }
                'Microsoft.SqlServer.Management.Smo.AvailabilityReplica' {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject"
                                EndpointUrl = ''
                                FailoverMode = ''
                                AvailabilityMode = ''
                                BackupPriority = 0
                                ConnectionModeInPrimaryRole = ''
                                ConnectionModeInSecondaryRole = ''
                             }
                }
                'Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener' {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject"
                                PortNumber = ''
                                AvailabilityGroupListenerIPAddresses = [System.Collections.ArrayList]@()
                            }
                }
                'Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress' {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject"
                                IsDHCP = ''
                                IPAddress = ''
                                SubnetMask = ''
                            }
                }
                Default {
                    $object = [PSCustomObject]@{
                                Name = "MockedObject"
                            }
                }
            }
            return $object
        }
        Mock Get-Module -MockWith {
            return 'Module Name'
        }

        Mock Get-ClusterNode -MockWith {
            $clusterNode = @(
                            [PSCustomObject]@{
                                    Name = 'Node01'
                                }
                            , [PSCustomObject]@{
                                    Name = 'Node02'
                                }
                            , [PSCustomObject]@{
                                    Name = 'Node03'
                                }
                            , [PSCustomObject]@{
                                    Name = 'Node04'
                                }
                            )
            return $clusterNode
        }
    }


    Context "Set the configuration" {
        
        # setup the params for the function using splatting method
        $Params = @{
                    Ensure = 'Present'
                    AvailabilityGroupName = 'AG01'
                    AvailabilityGroupNameListener = 'AgList01'
                    AvailabilityGroupNameIP = '192.168.0.1'
                    AvailabilityGroupSubMask = '255.255.255.0'
                    AvailabilityGroupPort = 1433
                    ReadableSecondary = 'ReadOnly'
                    AutoBackupPreference = 'Primary'
                    SQLServer = 'localhost'
                    SQLInstanceName = 'MSSQLSERVER'
                    SetupCredential = $mockcredential
                }

        $SqlAOGroup = Set-TargetResource @Params
        
        #this shouldn't have generated any errors which they are caught by pester without further checks
     }
    
}
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
