Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force

<#
    .SYNOPSIS
    Gets the specified login by name.

    .PARAMETER Name
    The name of the login to retrieve.
    
    .PARAMETER SQLServer
    Hostname of the SQL Server to retrieve the login from.
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to retrieve the login from. 
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Name,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    Import-SQLPSModule
    
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    Write-Verbose 'Getting SQL logins'
    New-VerboseMessage -Message "Getting the login '$Name' from '$SQLServer\$SQLInstanceName'"

    $login = $serverObject.Logins[$Name]

    if ( $login )
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    New-VerboseMessage -Message "The login '$Name' is $ensure from the '$SQLServer\$SQLInstanceName' instance."

    $returnValue = @{
        Ensure = $Ensure
        Name = $Name
        LoginType = $login.LoginType
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    if ( $login.LoginType -eq 'SqlLogin' )
    {
        $returnValue.Add('LoginMustChangePassword',$login.MustChangePassword)
        $returnValue.Add('LoginPasswordExpirationEnabled',$login.PasswordExpirationEnabled)
        $returnValue.Add('LoginPasswordPolicyEnforced',$login.PasswordPolicyEnforced)
    }

    return $returnValue
}

<#
    .SYNOPSIS
    Creates a login.

    .PARAMETER Ensure
    Specifies if the login to exist. Default is 'Present'.
    
    .PARAMETER Name
    The name of the login to retrieve.

    .PARAMETER LoginType
    The type of login to create. Default is 'WindowsUser'
    
    .PARAMETER SQLServer
    Hostname of the SQL Server to create the login on.
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to create the login on.

    .PARAMETER LoginCredential
    The credential containing the password for a SQL Login. Only applies if the login type is SqlLogin.

    .PARAMETER LoginMustChangePassword
    Specifies if the login is required to have its password change on the next login. Only applies to SQL Logins.

    .PARAMETER LoginPasswordExpirationEnabled
    Specifies if the login password is required to expire in accordance to the operating system security policy. Only applies to SQL Logins.

    .PARAMETER LoginPasswordPolicyEnforced
    Specifies if the login password is required to conform to the password policy specified in the system security policy. Only applies to SQL Logins.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory=$true)]
        [System.String]
        $Name,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.LoginType]
        $LoginType = 'WindowsUser',

        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLInstanceName
    )

    DynamicParam
    {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        if ( $LoginType -eq 'SqlLogin' -and $Ensure -eq 'Present' )
        {
            # Create the LoginCredential parameter 
            $loginCredAttribute = New-Object System.Management.Automation.ParameterAttribute
            $loginCredAttribute.Mandatory = $true
            $ac1 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ac1.Add($loginCredAttribute)
            $loginCredParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LoginCredential', [System.Management.Automation.PSCredential], $ac1)
            $paramDictionary.Add('LoginCredential', $loginCredParam)

            # Create the LoginMustChangePassword parameter
            $loginMustChangePasswordAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ac2 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ac2.Add($loginMustChangePasswordAttribute)
            $loginMustChangePasswordParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LoginMustChangePassword', [bool], $ac2)
            $loginMustChangePasswordParam.Value = $true
            $paramDictionary.Add('LoginMustChangePassword', $loginMustChangePasswordParam)

            # Create the LoginPasswordExpirationEnabled parameter
            $loginPasswordExpirationEnabledAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ac3 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ac3.Add($loginPasswordExpirationEnabledAttribute)
            $loginPasswordExpirationEnabledParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LoginPasswordExpirationEnabled', [bool], $ac3)
            $loginPasswordExpirationEnabledParam.Value = $true
            $paramDictionary.Add('LoginPasswordExpirationEnabled', $loginPasswordExpirationEnabledParam)

            # Create the LoginPasswordPolicyEnforced parameter
            $loginPasswordPolicyEnforcedAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ac3 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ac3.Add($loginPasswordPolicyEnforcedAttribute)
            $loginPasswordPolicyEnforcedParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LoginPasswordPolicyEnforced', [bool], $ac3)
            $loginPasswordPolicyEnforcedParam.Value = $true
            $paramDictionary.Add('LoginPasswordPolicyEnforced', $loginPasswordPolicyEnforcedParam)
        }

        return $paramDictionary
    }

    Process
    {
        # Get the dynamic parameters
        $LoginCredential = $paramDictionary.LoginCredential.Value
        $LoginMustChangePassword = $paramDictionary.LoginMustChangePassword.Value
        $LoginPasswordExpirationEnabled = $paramDictionary.LoginPasswordExpirationEnabled.Value
        $LoginPasswordPolicyEnforced = $paramDictionary.LoginPasswordPolicyEnforced.Value
        
        Import-SQLPSModule

        $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

        switch ( $Ensure )
        {
            'Present'
            {
                if ( $serverObject.Logins[$Name] )
                {
                    $login = $serverObject.Logins[$Name]

                    if ( $login.LoginType -eq 'SqlLogin' )
                    {
                        if ( $login.PasswordExpirationEnabled -ne $LoginPasswordExpirationEnabled )
                        {
                            New-VerboseMessage -Message "Setting PasswordExpirationEnabled to '$LoginPasswordExpirationEnabled' for the login '$Name' on the '$SQLServer\$SQLInstanceName' instance."
                            $login.PasswordExpirationEnabled = $LoginPasswordExpirationEnabled
                            $login.Alter()
                        }

                        if ( $login.PasswordPolicyEnforced -ne $LoginPasswordPolicyEnforced )
                        {
                            New-VerboseMessage -Message "Setting PasswordPolicyEnforced to '$LoginPasswordPolicyEnforced' for the login '$Name' on the '$SQLServer\$SQLInstanceName' instance."
                            $login.PasswordPolicyEnforced = $LoginPasswordPolicyEnforced
                            $login.Alter()
                        }
                    }
                }
                else
                {
                    # Some login types need additional work. These will need to be fleshed out more in the future
                    if ( @('Certificate','AsymmetricKey','ExternalUser','ExternalGroup') -contains $LoginType )
                    {
                        throw New-TerminatingError -ErrorType LoginTypeNotImplemented -FormatArgs $LoginType -ErrorCategory NotImplemented
                    }

                    New-VerboseMessage -Message "Adding the login '$Name' to the '$SQLServer\$SQLInstanceName' instance."
                    
                    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $serverObject,$Name
                    $login.LoginType = $LoginType

                    switch ($LoginType)
                    {
                        SqlLogin
                        {
                            $login.PasswordPolicyEnforced = $LoginPasswordPolicyEnforced
                            $login.PasswordExpirationEnabled = $LoginPasswordExpirationEnabled
                            if ( $LoginMustChangePassword )
                            {
                                $LoginCreateOptions = [Microsoft.SqlServer.Management.Smo.LoginCreateOptions]::MustChange
                            }
                            else
                            {
                                $LoginCreateOptions = [Microsoft.SqlServer.Management.Smo.LoginCreateOptions]::None
                            }
                            
                            try
                            {
                                $login.Create($LoginCredential.Password,$LoginCreateOptions)
                            }
                            catch [Microsoft.SqlServer.Management.Smo.FailedOperationException]
                            {
                                if ( $_.Exception.InnerException.InnerException.InnerException -match 'Password validation failed' )
                                {
                                    throw New-TerminatingError -ErrorType PasswordValidationFailed -FormatArgs $Name,$_.Exception.InnerException.InnerException.InnerException -ErrorCategory SecurityError
                                }
                                else
                                {
                                    throw New-TerminatingError -ErrorType LoginCreationFailed -FormatArgs $Name -ErrorCategory NotSpecified
                                }
                            }
                            catch
                            {
                                throw New-TerminatingError -ErrorType LoginCreationFailed -FormatArgs $Name -ErrorCategory NotSpecified
                            }
                        }

                        default
                        {
                            $login.Create()
                        }
                    }
                }
            }

            'Absent'
            {
                if ( $serverObject.Logins[$Name] )
                {
                    New-VerboseMessage -Message "Dropping the login '$Name' from the '$SQLServer\$SQLInstanceName' instance."
                    $serverObject.Logins[$Name].Drop()
                }
            }
        }
    }
}

<#
    .SYNOPSIS
    Tests to verify the login exists and the properties are correctly set.

    .PARAMETER Ensure
    Specifies if the login is supposed to exist. Default is 'Present'.
    
    .PARAMETER Name
    The name of the login.

    .PARAMETER LoginType
    The type of login. Default is 'WindowsUser'
    
    .PARAMETER SQLServer
    Hostname of the SQL Server.
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance.

    .PARAMETER LoginCredential
    The credential containing the password for a SQL Login. Only applies if the login type is SqlLogin.

    .PARAMETER LoginMustChangePassword
    Specifies if the login is required to have its password change on the next login. Only applies to SQL Logins.

    .PARAMETER LoginPasswordExpirationEnabled
    Specifies if the login password is required to expire in accordance to the operating system security policy. Only applies to SQL Logins.

    .PARAMETER LoginPasswordPolicyEnforced
    Specifies if the login password is required to conform to the password policy specified in the system security policy. Only applies to SQL Logins.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory=$true)]
        [System.String]
        $Name,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.LoginType]
        $LoginType = 'WindowsUser',

        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLInstanceName
    )

    DynamicParam
    {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        if ( $LoginType -eq 'SqlLogin' )
        {
            # Create the LoginMustChangePassword parameter
            $loginMustChangePasswordAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ac2 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ac2.Add($loginMustChangePasswordAttribute)
            $loginMustChangePasswordParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LoginMustChangePassword', [bool], $ac2)
            $loginMustChangePasswordParam.Value = $true
            $paramDictionary.Add('LoginMustChangePassword', $loginMustChangePasswordParam)

            # Create the LoginPasswordExpirationEnabled parameter
            $loginPasswordExpirationEnabledAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ac3 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ac3.Add($loginPasswordExpirationEnabledAttribute)
            $loginPasswordExpirationEnabledParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LoginPasswordExpirationEnabled', [bool], $ac3)
            $loginPasswordExpirationEnabledParam.Value = $true
            $paramDictionary.Add('LoginPasswordExpirationEnabled', $loginPasswordExpirationEnabledParam)

            # Create the LoginPasswordPolicyEnforced parameter
            $loginPasswordPolicyEnforcedAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ac4 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ac4.Add($loginPasswordPolicyEnforcedAttribute)
            $loginPasswordPolicyEnforcedParam = New-Object System.Management.Automation.RuntimeDefinedParameter('LoginPasswordPolicyEnforced', [bool], $ac4)
            $loginPasswordPolicyEnforcedParam.Value = $true
            $paramDictionary.Add('LoginPasswordPolicyEnforced', $loginPasswordPolicyEnforcedParam)
        }

        return $paramDictionary
    }

    Process
    {
        # Assume the test will pass
        $testPassed = $true

        # Get the dynamic parameters
        $LoginMustChangePassword = $paramDictionary.LoginMustChangePassword.Value
        $LoginPasswordExpirationEnabled = $paramDictionary.LoginPasswordExpirationEnabled.Value
        $LoginPasswordPolicyEnforced = $paramDictionary.LoginPasswordPolicyEnforced.Value
        
        $getParams = @{
            Name = $Name
            SQLServer = $SQLServer
            SQLInstanceName = $SQLInstanceName
        }
        $loginInfo = Get-TargetResource @getParams

        if ( $Ensure -ne $loginInfo.Ensure )
        {
            New-VerboseMessage -Message "The login '$Name' on the instance '$SQLServer\$SQLInstanceName' is $($loginInfo.Ensure) rather than $Ensure"
            $testPassed = $false
        }

        if ( $Ensure -eq 'Present' )
        {
            if ( $LoginType -ne $loginInfo.LoginType )
            {
                New-VerboseMessage -Message "The login '$Name' on the instance '$SQLServer\$SQLInstanceName' is a $($loginInfo.LoginType) rather than $LoginType"
                $testPassed = $false
            }

            if ( $LoginType -eq 'SqlLogin' )
            {
                if ( $LoginPasswordExpirationEnabled -ne $loginInfo.LoginPasswordExpirationEnabled )
                {
                    New-VerboseMessage -Message "The login '$Name' on the instance '$SQLServer\$SQLInstanceName' has PasswordExpirationEnabled set to $($loginInfo.LoginPasswordExpirationEnabled) rather than $LoginPasswordExpirationEnabled"
                    $testPassed = $false
                }

                if ( $LoginPasswordPolicyEnforced -ne $loginInfo.LoginPasswordPolicyEnforced )
                {
                    New-VerboseMessage -Message "The login '$Name' on the instance '$SQLServer\$SQLInstanceName' has PasswordPolicyEnforced set to $($loginInfo.LoginPasswordPolicyEnforced) rather than $LoginPasswordPolicyEnforced"
                    $testPassed = $false
                }
            }
        }
        
        return $testPassed
    }
}

Export-ModuleMember -Function *-TargetResource
