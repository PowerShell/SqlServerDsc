$script:currentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Import-Module -Name (Join-Path -Path (Split-Path -Path (Split-Path -Path $script:currentPath -Parent) -Parent) -ChildPath 'SqlServerDscHelper.psm1')

<#
    .SYNOPSIS
        Returns the current state of the SQL Server features.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine. For a default instance, only specify the computer name. For a named instances,
        use the format ComputerName\InstanceName.

    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.

    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet Invoke-Sqlcmd treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER GetQuery
        The full query that will perform the Get Action
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

    .PARAMETER TestQuery
        The full query that will perform the Test Action
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet Invoke-Sqlcmd treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER SetQuery
        The full query that will perform the Set Action

    .PARAMETER Credential
        The credentials to authenticate with, using SQL Authentication. To authenticate using Windows Authentication, assign the credentials
        to the built-in parameter `PsDscRunAsCredential`. If both parameters `Credential` and `PsDscRunAsCredential` are not assigned,
        then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER Variable
        Specifies, as a string array, a Invoke-Sqlcmd scripting variable for use in the Invoke-Sqlcmd script, and sets a value for the variable.
        Use a Windows PowerShell array to specify multiple variables and their values. For more information how to use this,
        please go to the help documentation for [Invoke-Sqlcmd](https://technet.microsoft.com/en-us/library/mt683370.aspx).

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL script execution will time out.
        In some SQL Server versions there is a bug in Invoke-Sqlcmd where the normal default value 0 (no timeout) is not respected and the default value is incorrectly set to 30 seconds.

    .OUTPUTS
        Hash table containing key 'GetResult' which holds the value of the result from the SQL script that was ran from the parameter 'GetFilePath'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter()]
        [System.String]
        $SetFilePath,

        [Parameter()]
        [System.String]
        $GetFilePath,

        [Parameter()]
        [System.String]
        $TestFilePath,

        [Parameter()]
        [System.String]
        $GetQuery,

        [Parameter()]
        [System.String]
        $TestQuery,

        [Parameter()]
        [System.String]
        $SetQuery,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable
    )

    if ($PSBoundParameters.GetFilePath -and $PSBoundParameters.GetScript)
    {
        throw "Cannot complete query using GetFilePath and GetScript. Please use either a file path containing a GetQuery
        or a GetQuery as a string."
    }

    if ($PSBoundParameters.GetFilePath)
    {
        $invokeParameters = @{
            ServerInstance = $ServerInstance
            InputFile      = $GetFilePath
            Credential     = $Credential
            Variable       = $Variable
            QueryTimeout   = $QueryTimeout
            ErrorAction    = "Stop"
        }

        $result = Invoke-SqlScript @invokeParameters

        $getResult = Out-String -InputObject $result
    }
    elseif ($PSBoundParameters.GetQuery)
    {
        $invokeParameters = @{
            ServerInstance = $ServerInstance
            Query          = $GetQuery
            Credential     = $Credential
            Variable       = $Variable
            QueryTimeout   = $QueryTimeout
            ErrorAction    = "Stop"
        }

        $result = Invoke-SqlScript @invokeParameters

        $getResult = Out-String -InputObject $result
    }
    else {
        throw "You must have a query input. Please provide a GetFilePath or GetQuery"
    }

    $returnValue = @{
        ServerInstance = [System.String] $ServerInstance
        SetFilePath    = [System.String] $SetFilePath
        GetFilePath    = [System.String] $GetFilePath
        TestFilePath   = [System.String] $TestFilePath
        GetQuery       = [System.String] $GetQuery
        TestQuery      = [System.String] $TestQuery
        SetQuery       = [System.String] $SetQuery
        Credential     = [System.Object] $Credential
        QueryTimeout   = [System.UInt32] $QueryTimeout
        Variable       = [System.String[]] $Variable
        GetResult      = [System.String[]] $getResult
    }

    $returnValue
}

<#
    .SYNOPSIS
        Returns the current state of the SQL Server features.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine. For a default instance, only specify the computer name. For a named instances,
        use the format ComputerName\InstanceName.

    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.

    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet Invoke-Sqlcmd treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER GetQuery
        The full query that will perform the Get Action
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

    .PARAMETER TestQuery
        The full query that will perform the Test Action
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet Invoke-Sqlcmd treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER SetQuery
        The full query that will perform the Set Action

    .PARAMETER Credential
        The credentials to authenticate with, using SQL Authentication. To authenticate using Windows Authentication, assign the credentials
        to the built-in parameter `PsDscRunAsCredential`. If both parameters `Credential` and `PsDscRunAsCredential` are not assigned,
        then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL script execution will time out.
        In some SQL Server versions there is a bug in Invoke-Sqlcmd where the normal default value 0 (no timeout) is not respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Variable
        Specifies, as a string array, a Invoke-Sqlcmd scripting variable for use in the Invoke-Sqlcmd script, and sets a value for the variable.
        Use a Windows PowerShell array to specify multiple variables and their values. For more information how to use this,
        please go to the help documentation for [Invoke-Sqlcmd](https://technet.microsoft.com/en-us/library/mt683370.aspx).
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(ParameterSetName = 'File')]
        [System.String]
        $SetFilePath,

        [Parameter(ParameterSetName = 'File')]
        [System.String]
        $GetFilePath,

        [Parameter(ParameterSetName = 'File')]
        [System.String]
        $TestFilePath,

        [Parameter(ParameterSetName = 'Query')]
        [System.String]
        $GetQuery,

        [Parameter(ParameterSetName = 'Query')]
        [System.String]
        $TestQuery,

        [Parameter(ParameterSetName = 'Query')]
        [System.String]
        $SetQuery,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable
    )

    if ($PSBoundParameters.SetFilePath -and $PSBoundParameters.SetScript)
    {
        throw "Cannot complete query using SetFilePath and SetScript. Please use either a file path containing a SetQuery
        or a SetQuery as a string."
    }

    if ($PSBoundParameters.SetFilePath)
    {
        $invokeParameters = @{
            ServerInstance = $ServerInstance
            InputFile      = $SetFilePath
            Credential     = $Credential
            Variable       = $Variable
            QueryTimeout   = $QueryTimeout
            ErrorAction    = "Stop"
        }

        Invoke-SqlScript @invokeParameters
    }
    elseif ($PSBoundParameters.SetQuery)
    {
        $invokeParameters = @{
            ServerInstance = $ServerInstance
            Query          = $SetQuery
            Credential     = $Credential
            Variable       = $Variable
            QueryTimeout   = $QueryTimeout
            ErrorAction    = "Stop"
        }

        Invoke-SqlScript @invokeParameters
    }
    else {
        throw "You must have a query input. Please provide a SetFilePath or SetQuery"
    }
}

<#
    .SYNOPSIS
        Returns the current state of the SQL Server features.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine. For a default instance, only specify the computer name. For a named instances,
        use the format ComputerName\InstanceName.

    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.

    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet Invoke-Sqlcmd treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER GetQuery
        The full query that will perform the Get Action
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

    .PARAMETER TestQuery
        The full query that will perform the Test Action
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet Invoke-Sqlcmd treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER SetQuery
        The full query that will perform the Set Action

    .PARAMETER Credential
        The credentials to authenticate with, using SQL Authentication. To authenticate using Windows Authentication, assign the credentials
        to the built-in parameter `PsDscRunAsCredential`. If both parameters `Credential` and `PsDscRunAsCredential` are not assigned,
        then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL script execution will time out.
        In some SQL Server versions there is a bug in Invoke-Sqlcmd where the normal default value 0 (no timeout) is not respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Variable
        Specifies, as a string array, a Invoke-Sqlcmd scripting variable for use in the Invoke-Sqlcmd script, and sets a value for the variable.
        Use a Windows PowerShell array to specify multiple variables and their values. For more information how to use this,
        please go to the help documentation for [Invoke-Sqlcmd](https://technet.microsoft.com/en-us/library/mt683370.aspx).

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(ParameterSetName = 'File')]
        [System.String]
        $SetFilePath,

        [Parameter(ParameterSetName = 'File')]
        [System.String]
        $GetFilePath,

        [Parameter(ParameterSetName = 'File')]
        [System.String]
        $TestFilePath,

        [Parameter(ParameterSetName = 'Query')]
        [System.String]
        $GetQuery,

        [Parameter(ParameterSetName = 'Query')]
        [System.String]
        $TestQuery,

        [Parameter(ParameterSetName = 'Query')]
        [System.String]
        $SetQuery,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable
    )

    if ($PSBoundParameters.TestFilePath -and $PSBoundParameters.TestsScript)
    {
        throw "Cannot complete query using TestFilePath and TestScript. Please use either a file path containing a TestQuery
        or a TestQuery as a string."
    }

    try
    {
        if ($PSBoundParameters.TestFilePath)
        {
            $invokeParameters = @{
                ServerInstance = $ServerInstance
                InputFile      = $TestFilePath
                Credential     = $Credential
                Variable       = $Variable
                QueryTimeout   = $QueryTimeout
                ErrorAction    = "Stop"
            }

            $result = Invoke-SqlScript @invokeParameters
        }
        elseif ($PSBoundParameters.TestQuery)
        {
            $invokeParameters = @{
                ServerInstance = $ServerInstance
                Query          = $TestQuery
                Credential     = $Credential
                Variable       = $Variable
                QueryTimeout   = $QueryTimeout
                ErrorAction    = "Stop"
            }

            $result = Invoke-SqlScript @invokeParameters
        }
        else {
            throw "You must have a query input. Please provide a TestFilePath or TestQuery"
        }

        if ($null -eq $result)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    catch [Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException]
    {
        Write-Verbose $_
        return $false
    }
}

<#
    .SYNOPSIS
        Execute an SQL script located in a file on disk.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine.
        For default instances, only specify the computer name. For named instances, use the format ComputerName\InstanceName.

    .PARAMETER Query
        The full query that will be executed.

    .PARAMETER SqlScriptPath
        Path to SQL script file that will be executed.

    .PARAMETER Credential
        The credentials to use to authenticate using SQL Authentication. To authenticate using Windows Authentication, assign the credentials
        to the built-in parameter 'PsDscRunAsCredential'. If both parameters 'Credential' and 'PsDscRunAsCredential' are not assigned, then
        the SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL script execution will time out.
        In some SQL Server versions there is a bug in Invoke-Sqlcmd where the normal default value 0 (no timeout) is not respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Variable
        Creates a Invoke-Sqlcmd scripting variable for use in the Invoke-Sqlcmd script, and sets a value for the variable.
#>
function Invoke-SqlScript
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(ParameterSetName = 'Query')]
        [System.String]
        $Query,

        [Parameter(ParameterSetName = 'File')]
        [System.String]
        $InputFile,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable
    )

    Import-SQLPSModule

    if ($null -ne $Credential)
    {
        $null = $PSBoundParameters.Add('Username', $Credential.UserName)

        $null = $PSBoundParameters.Add('Password', $Credential.GetNetworkCredential().Password)
    }

    if ($null -eq $Query)
    {
        $null = $PSBoundParameters.Remove('Query')
    }
    else
    {
        $null = $PSBoundParameters.Remove('InputFile')
    }

    $null = $PSBoundParameters.Remove('Credential')

    Invoke-SqlCmd @PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
