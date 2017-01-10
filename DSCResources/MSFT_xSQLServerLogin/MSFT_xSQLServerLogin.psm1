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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )
    
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
    Specifies if the login is required to have its password change on the next login. Only applies to SQL Logins. Default is $true.

    .PARAMETER LoginPasswordExpirationEnabled
    Specifies if the login password is required to expire in accordance to the operating system security policy. Only applies to SQL Logins. Default is $true.

    .PARAMETER LoginPasswordPolicyEnforced
    Specifies if the login password is required to conform to the password policy specified in the system security policy. Only applies to SQL Logins. Default is $true.
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet(
            'WindowsUser',
            'WindowsGroup',
            'SqlLogin',
            'Certificate',
            'AsymmetricKey',
            'ExternalUser',
            'ExternalGroup'
        )]
        [System.String]
        $LoginType = 'WindowsUser',

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $LoginCredential,

        [Parameter()]
        [bool]
        $LoginMustChangePassword = $true,

        [Parameter()]
        [bool]
        $LoginPasswordExpirationEnabled = $true,

        [Parameter()]
        [bool]
        $LoginPasswordPolicyEnforced = $true
    )
    
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
                        Update-SQLServerLogin -Login $login
                    }

                    if ( $login.PasswordPolicyEnforced -ne $LoginPasswordPolicyEnforced )
                    {
                        New-VerboseMessage -Message "Setting PasswordPolicyEnforced to '$LoginPasswordPolicyEnforced' for the login '$Name' on the '$SQLServer\$SQLInstanceName' instance."
                        $login.PasswordPolicyEnforced = $LoginPasswordPolicyEnforced
                        Update-SQLServerLogin -Login $login
                    }

                    # Set the password if it is specified
                    if ( $LoginCredential )
                    {
                         Set-SQLServerLoginPassword -Login $login -SecureString $LoginCredential.Password
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

                if ( ( $LoginType -eq 'SqlLogin' ) -and ( -not $LoginCredential ) )
                {
                    throw New-TerminatingError -ErrorType LoginCredentialNotFound -FormatArgs $Name -ErrorCategory ObjectNotFound
                }
                
                New-VerboseMessage -Message "Adding the login '$Name' to the '$SQLServer\$SQLInstanceName' instance."
                
                $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $serverObject,$Name
                $login.LoginType = $LoginType

                switch ($LoginType)
                {
                    SqlLogin
                    {
                        # Verify the instance is in Mixed authentication mode
                        if ( $serverObject.LoginMode -notmatch 'Mixed|Integrated' )
                        {
                            throw New-TerminatingError -ErrorType IncorrectLoginMode -FormatArgs $SQLServer,$SQLInstanceName,$serverObject.LoginMode -ErrorCategory NotImplemented
                        }
                        
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

                        New-SQLServerLogin -Login $login -LoginCreateOptions $LoginCreateOptions -SecureString $LoginCredential.Password -ErrorAction Stop 
                    }

                    default
                    {
                        New-SQLServerLogin -Login $login
                    }
                }
            }
        }

        'Absent'
        {
            if ( $serverObject.Logins[$Name] )
            {
                New-VerboseMessage -Message "Dropping the login '$Name' from the '$SQLServer\$SQLInstanceName' instance."
                Remove-SQLServerLogin -Login $serverObject.Logins[$Name]
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
    Specifies if the login is required to have its password change on the next login. Only applies to SQL Logins. Default is $true.

    .PARAMETER LoginPasswordExpirationEnabled
    Specifies if the login password is required to expire in accordance to the operating system security policy. Only applies to SQL Logins. Default is $true.

    .PARAMETER LoginPasswordPolicyEnforced
    Specifies if the login password is required to conform to the password policy specified in the system security policy. Only applies to SQL Logins. Default is $true.
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('WindowsUser',
            'WindowsGroup',
            'SqlLogin',
            'Certificate',
            'AsymmetricKey',
            'ExternalUser',
            'ExternalGroup'
        )]
        [System.String]
        $LoginType = 'WindowsUser',

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $LoginCredential,

        [Parameter()]
        [bool]
        $LoginMustChangePassword = $true,

        [Parameter()]
        [bool]
        $LoginPasswordExpirationEnabled = $true,

        [Parameter()]
        [bool]
        $LoginPasswordPolicyEnforced = $true
    )

    # Assume the test will pass
    $testPassed = $true
    
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

            # If testPassed is still true and a login credential was specified, test the password
            if ( $testPassed -and $LoginCredential )
            {
                $userCred = [System.Management.Automation.PSCredential]::new($Name, $LoginCredential.Password)
                
                try
                {
                    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -SetupCredential $userCred    
                }
                catch
                {
                    New-VerboseMessage -Message "Password validation failed for the login '$Name'."
                    $testPassed = $false
                }
            }
        }
    }
    
    return $testPassed
}

<#
    .SYNOPSIS
    Alters a login.

    .PARAMETER Login
    The Login object to alter.

    .NOTES
    This function allows us to more easily write mocks.
#>
function Update-SQLServerLogin
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Login]
        $Login
    )

    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        
        $Login.Alter()
    }
    catch
    {
        throw New-TerminatingError -ErrorType AlterLoginFailed -FormatArgs $Login.Name -ErrorCategory NotSpecified
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

<#
    .SYNOPSIS
    Creates a login.

    .PARAMETER Login
    The Login object to create.

    .PARAMETER LoginCreateOptions
    The LoginCreateOptions object to use when creating a SQL login.

    .PARAMETER SecureString
    The SecureString object that contains the password for a SQL login.

    .EXAMPLE
    CreateLogin -Login $login -LoginCreateOptions $LoginCreateOptions -SecureString $LoginCredential.Password -ErrorAction Stop

    .EXAMPLE
    CreateLogin -Login $login

    .NOTES
    This function allows us to more easily write mocks.
#>
function New-SQLServerLogin
{
    [CmdletBinding(DefaultParameterSetName = 'WindowsLogin')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'WindowsLogin')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SqlLogin')]
        [Microsoft.SqlServer.Management.Smo.Login]
        $Login,

        [Parameter(Mandatory = $true, ParameterSetName = 'SqlLogin')]
        [Microsoft.SqlServer.Management.Smo.LoginCreateOptions]
        $LoginCreateOptions,

        [Parameter(Mandatory = $true, ParameterSetName = 'SqlLogin')]
        [System.Security.SecureString]
        $SecureString
    )

    switch ( $PSCmdlet.ParameterSetName )
    {
        'SqlLogin' 
        { 
            try
            {
                $originalErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                
                $login.Create($SecureString,$LoginCreateOptions) 
            }
            catch [Microsoft.SqlServer.Management.Smo.FailedOperationException]
            {
                if ( $_.Exception.InnerException.InnerException.InnerException -match 'Password validation failed' )
                {
                    throw New-TerminatingError -ErrorType PasswordValidationFailed -FormatArgs $Name,$_.Exception.InnerException.InnerException.InnerException -ErrorCategory SecurityError
                }
                else
                {
                    throw New-TerminatingError -ErrorType LoginCreationFailedFailedOperation -FormatArgs $Name -ErrorCategory NotSpecified
                }
            }
            catch
            {
                throw New-TerminatingError -ErrorType LoginCreationFailedSqlNotSpecified -FormatArgs $Name -ErrorCategory NotSpecified
            }
            finally
            {
                $ErrorActionPreference = $originalErrorActionPreference
            }
        }

        'WindowsLogin'
        {
            try
            {
                $originalErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                
                $login.Create()
            }
            catch
            {
                throw New-TerminatingError -ErrorType LoginCreationFailedWindowsNotSpecified -FormatArgs $Name -ErrorCategory NotSpecified
            }
            finally
            {
                $ErrorActionPreference = $originalErrorActionPreference
            }
        }
    }
}

<#
    .SYNOPSIS
    Drops a login.

    .PARAMETER Login
    The Login object to drop.

    .NOTES
    This function allows us to more easily write mocks.
#>
function Remove-SQLServerLogin
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Login]
        $Login
    )

    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        
        $Login.Drop()
    }
    catch
    {
        throw New-TerminatingError -ErrorType DropLoginFailed -FormatArgs $Login.Name -ErrorCategory NotSpecified
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

<#
    .SYNOPSIS
    Changes the password of a SQL Login.

    .PARAMETER Login
    The Login object to change the password on.

    .PARAMETER SecureString
    The SecureString object that contains the password for a SQL login.

    .NOTES
    This function allows us to more easily write mocks.
#>
function Set-SQLServerLoginPassword
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Login]
        $Login,

        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]
        $SecureString
    )

    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        
        $Login.ChangePassword($SecureString)
    }
    catch [Microsoft.SqlServer.Management.Smo.FailedOperationException]
    {
        if ( $_.Exception.InnerException.InnerException.InnerException -match 'Password validation failed' )
        {
            throw New-TerminatingError -ErrorType PasswordValidationFailed -FormatArgs $Name,$_.Exception.InnerException.InnerException.InnerException -ErrorCategory SecurityError
        }
        else
        {
            throw New-TerminatingError -ErrorType PasswordChangeFailed -FormatArgs $Name -ErrorCategory NotSpecified
        }
    }
    catch
    {
        throw New-TerminatingError -ErrorType PasswordChangeFailed -FormatArgs $Name -ErrorCategory NotSpecified
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

Export-ModuleMember -Function *-TargetResource
