<#
    .SYNOPSIS
        Automated unit test for DSC_DSC_SqlDatabaseObjectPermission DSC resource.
#>

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlDatabaseObjectPermission'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

# Begin Testing

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        Set-StrictMode -Version 1.0

        Describe 'DSC_SqlDatabaseObjectPermission\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName New-Object -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
                } -MockWith {
                    # Return anything so we get an object to pass in the pipeline.
                    return ''
                }

                Mock -CommandName Get-Member -MockWith {
                    <#
                        Returns the names of the properties of the type
                        Microsoft.SqlServer.Management.Smo.ObjectPermissionSet.
                    #>
                    return @(
                        @{
                            Name = 'Alter'
                        }
                        @{
                            Name = 'Connect'
                        }
                        @{
                            Name = 'Control'
                        }
                        @{
                            Name = 'CreateSequence'
                        }
                        @{
                            Name = 'Delete'
                        }
                        @{
                            Name = 'Execute'
                        }
                        @{
                            Name = 'Impersonate'
                        }
                        @{
                            Name = 'Insert'
                        }
                        @{
                            Name = 'Receive'
                        }
                        @{
                            Name = 'References'
                        }
                        @{
                            Name = 'Select'
                        }
                        @{
                            Name = 'Send'
                        }
                        @{
                            Name = 'TakeOwnership'
                        }
                        @{
                            Name = 'Update'
                        }
                        @{
                            Name = 'ViewChangeTracking'
                        }
                        @{
                            Name = 'ViewDefinition'
                        }
                    )
                }

                Mock -CommandName Get-DatabaseObject -MockWith {
                    # Should mock a database object, e.g. Schema, Table, View.
                    return New-Object -TypeName PSCustomObject |
                        Add-Member -MemberType ScriptMethod -Name 'EnumObjectPermissions' -Value {
                            # Returns properties of the type Microsoft.SqlServer.Management.Smo.ObjectPermissionInfo.
                            return New-Object -TypeName PSCustomObject |
                                Add-Member -MemberType NoteProperty -Name 'Grantee' -Value 'TestAppRole' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GranteeType' -Value 'ApplicationRole' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'Grantor' -Value 'dbo' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'GrantorType' -Value 'User' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ColumnName' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ObjectClass' -Value 'ObjectColumn' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ObjectName' -Value 'Table1' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ObjectSchema' -Value 'dbo' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ObjectID' -Value '245575913' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'PermissionState' -Value 'Grant' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'PermissionType' -Value @(
                                    # Returns properties of the type Microsoft.SqlServer.Management.Smo.ObjectPermissionSet.
                                    New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Select' -Value $true -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Update' -Value $true -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                                    ) -PassThru -Force
                                } -PassThru -Force
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Grant'
                            Permission = @('Select', 'Update')
                            Ensure     = '' # Must be empty string to hit a line in the code.
                        } `
                        -ClientOnly

                    $getTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }

                It 'Should return the same values as the passed parameter values' {
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                    $getTargetResourceResult.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                    $getTargetResourceResult.DatabaseName | Should -Be $getTargetResourceParameters.DatabaseName
                    $getTargetResourceResult.SchemaName | Should -Be $getTargetResourceParameters.SchemaName
                    $getTargetResourceResult.ObjectName | Should -Be $getTargetResourceParameters.ObjectName
                    $getTargetResourceResult.ObjectType | Should -Be $getTargetResourceParameters.ObjectType
                    $getTargetResourceResult.Name | Should -Be $getTargetResourceParameters.Name
                }

                It 'Should return the correct metadata for the permission state' {
                    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                    $getTargetResourceResult.Permission | Should -HaveCount 1
                    $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $getTargetResourceResult.Permission.Where( { $_.State -eq 'Grant' })
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When an existing permission state is missing a permission' {
                    BeforeAll {
                        # Create an empty collection of CimInstance that we can return.
                        $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                        <#
                            Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                            to increase code coverage.
                        #>
                        $cimInstancePermissionCollection += New-CimInstance `
                            -ClassName 'DSC_DatabaseObjectPermission' `
                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                            -Property @{
                                State      = 'Grant'
                                Permission = @('Delete')
                                Ensure     = 'Present'
                            } `
                            -ClientOnly

                        $getTargetResourceParameters = @{
                            InstanceName = 'DSCTEST'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $cimInstancePermissionCollection
                        }
                    }

                    It 'Should return the same values as the passed parameter values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                        $getTargetResourceResult.DatabaseName | Should -Be $getTargetResourceParameters.DatabaseName
                        $getTargetResourceResult.SchemaName | Should -Be $getTargetResourceParameters.SchemaName
                        $getTargetResourceResult.ObjectName | Should -Be $getTargetResourceParameters.ObjectName
                        $getTargetResourceResult.ObjectType | Should -Be $getTargetResourceParameters.ObjectType
                        $getTargetResourceResult.Name | Should -Be $getTargetResourceParameters.Name
                    }

                    It 'Should return the correct metadata for the permission state' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.Permission | Should -HaveCount 1
                        $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'

                        $grantPermission = $getTargetResourceResult.Permission.Where( { $_.State -eq 'Grant' })
                        $grantPermission | Should -Not -BeNullOrEmpty
                        $grantPermission.Ensure | Should -Be 'Absent'
                        $grantPermission.Permission | Should -HaveCount 1
                        $grantPermission.Permission | Should -Contain @('Delete')
                    }
                }

                Context 'When a permission state is missing that should be present' {
                    BeforeAll {
                        # Create an empty collection of CimInstance that we can return.
                        $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                        <#
                            Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                            to increase code coverage.
                        #>
                        $cimInstancePermissionCollection += New-CimInstance `
                            -ClassName 'DSC_DatabaseObjectPermission' `
                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                            -Property @{
                                State      = 'Deny'
                                Permission = @('Delete')
                                Ensure     = 'Present'
                            } `
                            -ClientOnly

                        $getTargetResourceParameters = @{
                            InstanceName = 'DSCTEST'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $cimInstancePermissionCollection
                        }
                    }

                    It 'Should return the same values as the passed parameter values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                        $getTargetResourceResult.DatabaseName | Should -Be $getTargetResourceParameters.DatabaseName
                        $getTargetResourceResult.SchemaName | Should -Be $getTargetResourceParameters.SchemaName
                        $getTargetResourceResult.ObjectName | Should -Be $getTargetResourceParameters.ObjectName
                        $getTargetResourceResult.ObjectType | Should -Be $getTargetResourceParameters.ObjectType
                        $getTargetResourceResult.Name | Should -Be $getTargetResourceParameters.Name
                    }

                    It 'Should return the correct metadata for the permission state' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.Permission | Should -HaveCount 1
                        $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'

                        $grantPermission = $getTargetResourceResult.Permission.Where( { $_.State -eq 'Deny' })
                        $grantPermission | Should -Not -BeNullOrEmpty
                        $grantPermission.Ensure | Should -Be 'Absent'
                        $grantPermission.Permission | Should -HaveCount 1
                        $grantPermission.Permission | Should -Contain @('Delete')
                    }
                }

                Context 'When a permission state is present but should be absent' {
                    BeforeAll {
                        # Create an empty collection of CimInstance that we can return.
                        $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                        <#
                            Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                            to increase code coverage.
                        #>
                        $cimInstancePermissionCollection += New-CimInstance `
                            -ClassName 'DSC_DatabaseObjectPermission' `
                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                            -Property @{
                                State      = 'Grant'
                                Permission = @('Select')
                                Ensure     = 'Absent'
                            } `
                            -ClientOnly

                        $getTargetResourceParameters = @{
                            InstanceName = 'DSCTEST'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $cimInstancePermissionCollection
                        }
                    }

                    It 'Should return the same values as the passed parameter values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.InstanceName | Should -Be $getTargetResourceParameters.InstanceName
                        $getTargetResourceResult.DatabaseName | Should -Be $getTargetResourceParameters.DatabaseName
                        $getTargetResourceResult.SchemaName | Should -Be $getTargetResourceParameters.SchemaName
                        $getTargetResourceResult.ObjectName | Should -Be $getTargetResourceParameters.ObjectName
                        $getTargetResourceResult.ObjectType | Should -Be $getTargetResourceParameters.ObjectType
                        $getTargetResourceResult.Name | Should -Be $getTargetResourceParameters.Name
                    }

                    It 'Should return the correct metadata for the permission state' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.Permission | Should -HaveCount 1
                        $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'

                        $grantPermission = $getTargetResourceResult.Permission.Where( { $_.State -eq 'Grant' })
                        $grantPermission | Should -Not -BeNullOrEmpty
                        $grantPermission.Ensure | Should -Be 'Present'
                        $grantPermission.Permission | Should -HaveCount 1
                        $grantPermission.Permission | Should -Contain @('Select')
                        $grantPermission.Permission | Should -Not -Contain @('Delete')
                    }
                }
            }
        }

        Describe 'SqlDatabaseObjectPermission\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                # Using all lower-case on 'update' intentionally.
                $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                    -Permission @('Select', 'update') `
                    -PermissionState 'Grant' `
                    -Ensure 'Present'

                $testTargetResourceParameters = @{
                    InstanceName = 'sql2014'
                    DatabaseName = 'AdventureWorks'
                    SchemaName   = 'dbo'
                    ObjectName   = 'Table1'
                    ObjectType   = 'Table'
                    Name         = 'TestAppRole'
                    Permission   = $cimInstancePermissionCollection
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $true
                            }
                        )
                    }
                }

                It 'Should return $true' {
                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeTrue

                    Assert-MockCalled -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $false
                            }
                        )
                    }
                }

                It 'Should return $false' {
                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse

                    Assert-MockCalled -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'SqlDatabaseObjectPermission\Compare-TargetResourceState' -Tag 'Compare' {
            BeforeAll {
                $mockInstanceName = 'DSCTEST'
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Using all lower-case on 'update' intentionally.
                        Intentionally not providing the CIM instance property
                        'Ensure' on this CIM instance.
                    #>
                    $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission @('Select', 'update') `
                        -PermissionState 'Grant'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Deny'
                            Permission = @('Delete')
                            Ensure     = '' # Must be empty string to hit a line in the code.
                        } `
                        -ClientOnly

                    $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission @('Drop') `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Absent'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $cimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Intentionally left the parameter ServerName out.
                    $compareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }

                It 'Should return the correct metadata for the permission property' {
                    $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeTrue

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -HaveCount 3
                    $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Actual[1] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Actual[2] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Grant' })
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')

                    $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Deny' })
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Delete')

                    $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'GrantWithGrant' })
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Absent'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Drop')

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 3
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[2] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Grant' })
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')

                    $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Deny' })
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Delete')

                    $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'GrantWithGrant' })
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Absent'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Drop')

                    Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the permission state is already present in the current state but not in the desired state' {
                    BeforeAll {
                        # Holds the current permissions.
                        $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                        # Using all lower-case on 'update' intentionally.
                        $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                            -Permission @('Select', 'update') `
                            -PermissionState 'Grant' `
                            -Ensure 'Present'

                        $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                            -Permission @('Delete') `
                            -PermissionState 'Deny' `
                            -Ensure 'Present'

                        $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                            -Permission @('Drop') `
                            -PermissionState 'GrantWithGrant' `
                            -Ensure 'Present'

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $currentCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }
                        }
                    }

                    <#
                        We test the actual permission that are reused in the nested
                        Context-blocks so that we don't have to test that for each test.
                    #>
                    It 'Should return the correct actual permissions for the ''Permission'' property' {
                        $compareTargetResourceParameters = @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }

                        $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                        $compareTargetResourceStateResult | Should -HaveCount 1

                        $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                        $comparedReturnValue | Should -Not -BeNullOrEmpty

                        $comparedReturnValue.Actual | Should -HaveCount 3
                        $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'
                        $comparedReturnValue.Actual[1] | Should -BeOfType 'CimInstance'
                        $comparedReturnValue.Actual[2] | Should -BeOfType 'CimInstance'

                        # Actual permissions
                        $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Grant' })
                        $grantPermission | Should -Not -BeNullOrEmpty
                        $grantPermission.Ensure | Should -Be 'Present'
                        $grantPermission.Permission | Should -HaveCount 2
                        $grantPermission.Permission | Should -Contain @('Select')
                        $grantPermission.Permission | Should -Contain @('Update')

                        $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Deny' })
                        $grantPermission | Should -Not -BeNullOrEmpty
                        $grantPermission.Ensure | Should -Be 'Present'
                        $grantPermission.Permission | Should -HaveCount 1
                        $grantPermission.Permission | Should -Contain @('Delete')

                        $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'GrantWithGrant' })
                        $grantPermission | Should -Not -BeNullOrEmpty
                        $grantPermission.Ensure | Should -Be 'Present'
                        $grantPermission.Permission | Should -HaveCount 1
                        $grantPermission.Permission | Should -Contain @('Drop')

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }

                    Context 'When the permission state ''Grant'' is ''Present'' but desired state is ''Absent''' {
                        BeforeAll {
                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select', 'update') `
                                -PermissionState 'Grant' `
                                -Ensure 'Absent'

                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Delete') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'

                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Drop') `
                                -PermissionState 'GrantWithGrant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            $comparedReturnValue.Expected | Should -HaveCount 3
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                            $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'
                            $comparedReturnValue.Expected[2] | Should -BeOfType 'CimInstance'

                            # Expected permissions
                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Absent'
                            $grantPermission.Permission | Should -HaveCount 2
                            $grantPermission.Permission | Should -Contain @('Select')
                            $grantPermission.Permission | Should -Contain @('Update')

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Delete')

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'GrantWithGrant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Drop')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permission state ''GrantWithGrant'' is ''Present'' but desired state is ''Absent''' {
                        BeforeAll {
                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select', 'update') `
                                -PermissionState 'Grant' `
                                -Ensure 'Present'

                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Delete') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'

                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Drop') `
                                -PermissionState 'GrantWithGrant' `
                                -Ensure 'Absent'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            $comparedReturnValue.Expected | Should -HaveCount 3
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                            $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'
                            $comparedReturnValue.Expected[2] | Should -BeOfType 'CimInstance'

                            # Expected permissions
                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 2
                            $grantPermission.Permission | Should -Contain @('Select')
                            $grantPermission.Permission | Should -Contain @('Update')

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Delete')

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'GrantWithGrant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Absent'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Drop')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permission state ''Deny'' is ''Present'' but desired state is ''Absent''' {
                        BeforeAll {
                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select', 'update') `
                                -PermissionState 'Grant' `
                                -Ensure 'Present'

                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Delete') `
                                -PermissionState 'Deny' `
                                -Ensure 'Absent'

                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Drop') `
                                -PermissionState 'GrantWithGrant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            $comparedReturnValue.Expected | Should -HaveCount 3
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                            $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'
                            $comparedReturnValue.Expected[2] | Should -BeOfType 'CimInstance'

                            # Expected permissions
                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 2
                            $grantPermission.Permission | Should -Contain @('Select')
                            $grantPermission.Permission | Should -Contain @('Update')

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Absent'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Delete')

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'GrantWithGrant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Drop')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permissions for the permission state ''Grant'' is not in desired state' {
                        BeforeAll {
                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('CreateTable') `
                                -PermissionState 'Grant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            # Expected permissions
                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('CreateTable')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permissions for the permission state ''GrantWithGrant'' is not in desired state' {
                        BeforeAll {
                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('CreateTable') `
                                -PermissionState 'GrantWithGrant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            # Expected permissions
                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'GrantWithGrant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('CreateTable')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permissions for the permission state ''Deny'' is not in desired state' {
                        BeforeAll {
                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('CreateTable') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            # Expected permissions
                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('CreateTable')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the specified permission state is missing in the current state' {
                    Context 'When the permission state ''Grant'' is ''Absent'' but desired state is ''Present''' {
                        BeforeAll {
                            # Empty collection to mock no existing permissions in the current state.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select', 'update') `
                                -PermissionState 'Grant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -BeNullOrEmpty

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 2
                            $grantPermission.Permission | Should -Contain @('Select')
                            $grantPermission.Permission | Should -Contain @('Update')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permission state ''GrantWithGrant'' is ''Absent'' but desired state is ''Present''' {
                        BeforeAll {
                            # Empty collection to mock no existing permissions in the current state.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select', 'update') `
                                -PermissionState 'GrantWithGrant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -BeNullOrEmpty

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'GrantWithGrant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 2
                            $grantPermission.Permission | Should -Contain @('Select')
                            $grantPermission.Permission | Should -Contain @('Update')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permission state ''Deny'' is ''Absent'' but desired state is ''Present''' {
                        BeforeAll {
                            # Empty collection to mock no existing permissions in the current state.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select', 'update') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -BeNullOrEmpty

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 2
                            $grantPermission.Permission | Should -Contain @('Select')
                            $grantPermission.Permission | Should -Contain @('Update')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When there already are other existing permissions for specified permission state' {
                    Context 'When the permission state ''Grant'' should include the permission ''Update''' {
                        BeforeAll {
                            # Holds the current permissions.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select') `
                                -PermissionState 'Grant' `
                                -Ensure 'Present'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Update') `
                                -PermissionState 'Grant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -HaveCount 1
                            $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Select')

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Update')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permission state ''GrantWithGrant'' should include the permission ''Update''' {
                        BeforeAll {
                            # Holds the current permissions.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select') `
                                -PermissionState 'GrantWithGrant' `
                                -Ensure 'Present'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Update') `
                                -PermissionState 'GrantWithGrant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -HaveCount 1
                            $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'GrantWithGrant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Select')

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'GrantWithGrant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Update')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permission state ''Deny'' should include the permission ''Update''' {
                        BeforeAll {
                            # Holds the current permissions.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Update') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -HaveCount 1
                            $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Select')

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Update')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When there exist other permission states than the one that is desired' {
                    Context 'When the permission state ''Grant'' should exist' {
                        BeforeAll {
                            # Holds the current permissions.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Update') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select') `
                                -PermissionState 'Grant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -HaveCount 1
                            $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Update')

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Select')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permission state ''GrantWithGrant'' should exist' {
                        BeforeAll {
                            # Holds the current permissions.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Update') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select') `
                                -PermissionState 'GrantWithGrant' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -HaveCount 1
                            $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Update')

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'GrantWithGrant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Select')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the permission state ''Deny'' should exist' {
                        BeforeAll {
                            # Holds the current permissions.
                            $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Select') `
                                -PermissionState 'Grant' `
                                -Ensure 'Present'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName = 'sql2014'
                                    DatabaseName = 'AdventureWorks'
                                    SchemaName   = 'dbo'
                                    ObjectName   = 'Table1'
                                    ObjectType   = 'Table'
                                    Name         = 'TestAppRole'
                                    Permission   = $currentCimInstancePermissionCollection
                                    ServerName   = 'testclu01a'
                                }
                            }

                            # Holds the desired permissions.
                            $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            # Using all lower-case on 'update' intentionally.
                            $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                                -Permission @('Update') `
                                -PermissionState 'Deny' `
                                -Ensure 'Present'
                        }

                        It 'Should return the correct metadata for the ''Permission'' property' {
                            $compareTargetResourceParameters = @{
                                InstanceName = 'sql2014'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $desiredCimInstancePermissionCollection
                                ServerName   = 'testclu01a'
                            }

                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Permission' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            # Actual permissions
                            $comparedReturnValue.Actual | Should -HaveCount 1
                            $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Actual.Where( { $_.State -eq 'Grant' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Select')

                            # Expected permissions
                            $comparedReturnValue.Expected | Should -HaveCount 1
                            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                            $grantPermission = $comparedReturnValue.Expected.Where( { $_.State -eq 'Deny' })
                            $grantPermission | Should -Not -BeNullOrEmpty
                            $grantPermission.Ensure | Should -Be 'Present'
                            $grantPermission.Permission | Should -HaveCount 1
                            $grantPermission.Permission | Should -Contain @('Update')

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }
            }
        }

        Describe 'DSC_SqlDatabaseObjectPermission\Set-TargetResource' -Tag 'Set' {
            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Get-DatabaseObject
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $true
                                Actual         = @(
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'Grant' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                )
                            }
                        )
                    }

                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Grant'
                            Permission = @('Select', 'Update')
                            Ensure     = '' # Must be empty string to hit a line in the code.
                        } `
                        -ClientOnly

                    $setTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }

                It 'Should not try to set any values and should not throw an exception' {
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Get-DatabaseObject -Exactly -Times 0 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the database object is not found' {
                    BeforeAll {
                        Mock -CommandName Compare-TargetResourceState -MockWith {
                            return @(
                                @{
                                    ParameterName  = 'Permission'
                                    InDesiredState = $false
                                }
                            )
                        }

                        Mock -CommandName Get-DatabaseObject

                        # Create an empty collection of CimInstance that we can return.
                        $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                        <#
                            Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                            to increase code coverage.
                        #>
                        $cimInstancePermissionCollection += New-CimInstance `
                            -ClassName 'DSC_DatabaseObjectPermission' `
                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                            -Property @{
                                State      = 'Grant'
                                Permission = @('Select', 'Update')
                                Ensure     = '' # Must be empty string to hit a line in the code.
                            } `
                            -ClientOnly

                        $setTargetResourceParameters = @{
                            InstanceName = 'DSCTEST'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $cimInstancePermissionCollection
                        }
                    }

                    It 'Should throw the correct exception' {
                        $mockErrorMessage = $script:localizedData.FailedToGetDatabaseObject -f @(
                            ('{0}.{1}' -f $setTargetResourceParameters.SchemaName, $setTargetResourceParameters.ObjectName),
                            $setTargetResourceParameters.ObjectType,
                            $setTargetResourceParameters.DatabaseName
                        )

                        { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockErrorMessage
                    }
                }

                Context 'When setting permission for a permission state' {
                    BeforeAll {
                        Mock -CommandName New-Object -ParameterFilter {
                            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
                        } -MockWith {
                            return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Select' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Update' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                        }

                        Mock -CommandName Get-DatabaseObject -MockWith {
                            # Should mock a database object, e.g. Schema, Table, View.
                            return New-Object -TypeName PSCustomObject |
                                Add-Member -MemberType ScriptMethod -Name 'Grant' -Value {
                                    $script:mockMethodGrantRanTimes += 1
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                                    $script:mockMethodDenyRanTimes += 1
                                } -PassThru -Force
                        }
                    }

                    BeforeEach {
                        $script:mockMethodGrantRanTimes = 0
                        $script:mockMethodDenyRanTimes = 0
                    }

                    Context 'When setting permission for the permission state ''Grant''' {
                        BeforeAll {
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName  = 'Permission'
                                        InDesiredState = $false
                                        Actual         = @(
                                            (New-Object -TypeName PSCustomObject |
                                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'Grant' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Absent' -PassThru -Force)
                                        )
                                    }
                                )
                            }

                            # Create an empty collection of CimInstance that we can return.
                            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            <#
                                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                                to increase code coverage.
                            #>
                            $cimInstancePermissionCollection += New-CimInstance `
                                -ClassName 'DSC_DatabaseObjectPermission' `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -Property @{
                                    State      = 'Grant'
                                    Permission = @('Delete')
                                    Ensure     = 'Present'
                                } `
                                -ClientOnly

                            $setTargetResourceParameters = @{
                                InstanceName = 'DSCTEST'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $cimInstancePermissionCollection
                                Verbose      = $true
                            }
                        }

                        It 'Should set the permissions without throwing an exception' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                            $script:mockMethodGrantRanTimes | Should -Be 1
                            $script:mockMethodDenyRanTimes  | Should -Be 0
                        }
                    }

                    Context 'When setting permission for the permission state ''GrantWithGrant''' {
                        BeforeAll {
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName  = 'Permission'
                                        InDesiredState = $false
                                        Actual         = @(
                                            (New-Object -TypeName PSCustomObject |
                                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'GrantWithGrant' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Absent' -PassThru -Force)
                                        )
                                    }
                                )
                            }

                            # Create an empty collection of CimInstance that we can return.
                            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            <#
                                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                                to increase code coverage.
                            #>
                            $cimInstancePermissionCollection += New-CimInstance `
                                -ClassName 'DSC_DatabaseObjectPermission' `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -Property @{
                                    State      = 'GrantWithGrant'
                                    Permission = @('Delete')
                                    Ensure     = 'Present'
                                } `
                                -ClientOnly

                            $setTargetResourceParameters = @{
                                InstanceName = 'DSCTEST'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $cimInstancePermissionCollection
                            }
                        }

                        It 'Should set the permissions without throwing an exception' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                            $script:mockMethodGrantRanTimes | Should -Be 1
                            $script:mockMethodDenyRanTimes  | Should -Be 0
                        }
                    }

                    Context 'When setting permission for the permission state ''Deny''' {
                        BeforeAll {
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName  = 'Permission'
                                        InDesiredState = $false
                                        Actual         = @(
                                            (New-Object -TypeName PSCustomObject |
                                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'Deny' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Absent' -PassThru -Force)
                                        )
                                    }
                                )
                            }

                            # Create an empty collection of CimInstance that we can return.
                            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            <#
                                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                                to increase code coverage.
                            #>
                            $cimInstancePermissionCollection += New-CimInstance `
                                -ClassName 'DSC_DatabaseObjectPermission' `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -Property @{
                                    State      = 'Deny'
                                    Permission = @('Delete')
                                    Ensure     = 'Present'
                                } `
                                -ClientOnly

                            $setTargetResourceParameters = @{
                                InstanceName = 'DSCTEST'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $cimInstancePermissionCollection
                            }
                        }

                        It 'Should set the permissions without throwing an exception' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                            $script:mockMethodGrantRanTimes | Should -Be 0
                            $script:mockMethodDenyRanTimes  | Should -Be 1
                        }
                    }

                    Context 'When one of the permission states is already in desired state' {
                        BeforeAll {
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName  = 'Permission'
                                        InDesiredState = $false
                                        Actual         = @(
                                            (New-Object -TypeName PSCustomObject |
                                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'Deny' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Absent' -PassThru -Force)
                                            (New-Object -TypeName PSCustomObject |
                                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'Grant' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                        )
                                    }
                                )
                            }

                            # Create an empty collection of CimInstance that we can return.
                            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            <#
                                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                                to increase code coverage.
                            #>
                            $cimInstancePermissionCollection += New-CimInstance `
                                -ClassName 'DSC_DatabaseObjectPermission' `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -Property @{
                                    State      = 'Grant'
                                    Permission = @('Delete')
                                    Ensure     = 'Present'
                                } `
                                -ClientOnly

                            $cimInstancePermissionCollection += New-CimInstance `
                                -ClassName 'DSC_DatabaseObjectPermission' `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -Property @{
                                    State      = 'Deny'
                                    Permission = @('Delete')
                                    Ensure     = 'Present'
                                } `
                                -ClientOnly

                            $setTargetResourceParameters = @{
                                InstanceName = 'DSCTEST'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $cimInstancePermissionCollection
                            }
                        }

                        It 'Should set the permissions without throwing an exception' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                            $script:mockMethodGrantRanTimes | Should -Be 0
                            $script:mockMethodDenyRanTimes  | Should -Be 1
                        }
                    }
                }

                Context 'When revoking permission for a permission state' {
                    BeforeAll {
                        Mock -CommandName New-Object -ParameterFilter {
                            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
                        } -MockWith {
                            return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Select' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Update' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                        }

                        Mock -CommandName Get-DatabaseObject -MockWith {
                            # Should mock a database object, e.g. Schema, Table, View.
                            return New-Object -TypeName PSCustomObject |
                                Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                                    $script:mockMethodRevokeRanTimes += 1
                                } -PassThru -Force
                        }
                    }

                    BeforeEach {
                        $script:mockMethodRevokeRanTimes = 0
                    }

                    Context 'When revoking permission for the permission state ''Grant''' {
                        BeforeAll {
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName  = 'Permission'
                                        InDesiredState = $false
                                        Actual         = @(
                                            (New-Object -TypeName PSCustomObject |
                                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'Grant' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                        )
                                    }
                                )
                            }

                            # Create an empty collection of CimInstance that we can return.
                            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            <#
                                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                                to increase code coverage.
                            #>
                            $cimInstancePermissionCollection += New-CimInstance `
                                -ClassName 'DSC_DatabaseObjectPermission' `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -Property @{
                                    State      = 'Grant'
                                    Permission = @('Delete')
                                    Ensure     = 'Absent'
                                } `
                                -ClientOnly

                            $setTargetResourceParameters = @{
                                InstanceName = 'DSCTEST'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $cimInstancePermissionCollection
                                Verbose      = $true
                            }
                        }

                        It 'Should revoke the permissions without throwing an exception' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                            $script:mockMethodRevokeRanTimes | Should -Be 1
                        }
                    }

                    Context 'When revoking permission for the permission state ''GrantWithGrant''' {
                        BeforeAll {
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName  = 'Permission'
                                        InDesiredState = $false
                                        Actual         = @(
                                            (New-Object -TypeName PSCustomObject |
                                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'GrantWithGrant' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                        )
                                    }
                                )
                            }

                            # Create an empty collection of CimInstance that we can return.
                            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            <#
                                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                                to increase code coverage.
                            #>
                            $cimInstancePermissionCollection += New-CimInstance `
                                -ClassName 'DSC_DatabaseObjectPermission' `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -Property @{
                                    State      = 'GrantWithGrant'
                                    Permission = @('Delete')
                                    Ensure     = 'Absent'
                                } `
                                -ClientOnly

                            $setTargetResourceParameters = @{
                                InstanceName = 'DSCTEST'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $cimInstancePermissionCollection
                            }
                        }

                        It 'Should revoke the permissions without throwing an exception' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                            $script:mockMethodRevokeRanTimes | Should -Be 1
                        }
                    }

                    Context 'When revoking permission for the permission state ''Deny''' {
                        BeforeAll {
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName  = 'Permission'
                                        InDesiredState = $false
                                        Actual         = @(
                                            (New-Object -TypeName PSCustomObject |
                                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'Deny' -PassThru |
                                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                        )
                                    }
                                )
                            }

                            # Create an empty collection of CimInstance that we can return.
                            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                            <#
                                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                                to increase code coverage.
                            #>
                            $cimInstancePermissionCollection += New-CimInstance `
                                -ClassName 'DSC_DatabaseObjectPermission' `
                                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                                -Property @{
                                    State      = 'Deny'
                                    Permission = @('Delete')
                                    Ensure     = 'Absent'
                                } `
                                -ClientOnly

                            $setTargetResourceParameters = @{
                                InstanceName = 'DSCTEST'
                                DatabaseName = 'AdventureWorks'
                                SchemaName   = 'dbo'
                                ObjectName   = 'Table1'
                                ObjectType   = 'Table'
                                Name         = 'TestAppRole'
                                Permission   = $cimInstancePermissionCollection
                            }
                        }

                        It 'Should revoke the permissions without throwing an exception' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                            $script:mockMethodRevokeRanTimes | Should -Be 1
                        }
                    }
                }

                Context 'When failing to change permissions' {
                    BeforeAll {
                        Mock -CommandName Compare-TargetResourceState -MockWith {
                            return @(
                                @{
                                    ParameterName  = 'Permission'
                                    InDesiredState = $false
                                }
                            )
                        }

                        Mock -CommandName New-Object -ParameterFilter {
                            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
                        } -MockWith {
                            return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Select' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Update' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                        }

                        Mock -CommandName Get-DatabaseObject -MockWith {
                            # Should mock a database object, e.g. Schema, Table, View.
                            return New-Object -TypeName PSCustomObject |
                                Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                                    throw 'Mocked error'
                                } -PassThru -Force
                        }

                        # Create an empty collection of CimInstance that we can return.
                        $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                        <#
                            Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                            to increase code coverage.
                        #>
                        $cimInstancePermissionCollection += New-CimInstance `
                            -ClassName 'DSC_DatabaseObjectPermission' `
                            -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                            -Property @{
                                State      = 'Grant'
                                Permission = @('Delete')
                                Ensure     = 'Absent'
                            } `
                            -ClientOnly

                        $setTargetResourceParameters = @{
                            InstanceName = 'DSCTEST'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $cimInstancePermissionCollection
                        }
                    }

                    It 'Should throw the correct exception' {
                        $mockErrorMessage = $script:localizedData.FailedToSetDatabaseObjectPermission -f @(
                            $setTargetResourceParameters.Name,
                            ('{0}.{1}' -f $setTargetResourceParameters.SchemaName, $setTargetResourceParameters.ObjectName),
                            $setTargetResourceParameters.DatabaseName
                        )

                        { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockErrorMessage
                    }
                }
            }
        }

        Describe 'SqlDatabaseObjectPermission\Get-DatabaseObject' -Tag 'Helper' {
            BeforeAll {
                Mock -Command Connect-SQL -MockWith {
                    return New-Object -TypeName PSObject |
                        Add-Member -MemberType NoteProperty -Name 'Databases' -Value @{
                            'AdventureWorks' = New-Object -TypeName PSObject |
                                Add-Member -MemberType NoteProperty -Name 'Schemas' -Value (
                                    New-Object -TypeName PSObject |
                                        Add-Member -MemberType ScriptMethod -Name 'Item' -Value {
                                            return 'Schema'
                                        } -PassThru -Force
                                ) -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'Tables' -Value (
                                    New-Object -TypeName PSObject |
                                        Add-Member -MemberType ScriptMethod -Name 'Item' -Value {
                                            return 'Table'
                                        } -PassThru -Force
                                ) -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'StoredProcedures' -Value (
                                    New-Object -TypeName PSObject |
                                        Add-Member -MemberType ScriptMethod -Name 'Item' -Value {
                                            return 'StoredProcedure'
                                        } -PassThru -Force
                                ) -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'Views' -Value (
                                    New-Object -TypeName PSObject |
                                        Add-Member -MemberType ScriptMethod -Name 'Item' -Value {
                                            return 'View'
                                        } -PassThru -Force
                                ) -PassThru -Force
                        } -PassThru -Force
                }

                $testCases = @(
                    @{
                        ObjectType = 'Schema'
                    }
                    @{
                        ObjectType = 'Table'
                    }
                    @{
                        ObjectType = 'StoredProcedure'
                    }
                    @{
                        ObjectType = 'View'
                    }
                )
            }

            It 'Should call the correct mocked method to get object type ''<ObjectType>''' -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $ObjectType
                )

                $getDatabaseObjectParameters = @{
                    ServerName = $env:COMPUTERNAME
                    InstanceName = 'DSCTEST'
                    DatabaseName = 'AdventureWorks'
                    SchemaName   = 'dbo'
                    ObjectName   = 'Table1'
                    ObjectType   = $ObjectType
                }

                # The methods that was mocked returns the expect object type.
                Get-DatabaseObject @getDatabaseObjectParameters | Should -Be $ObjectType
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
