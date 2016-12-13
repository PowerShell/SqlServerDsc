# Set Global Module Verbose
$VerbosePreference = 'Continue' 

# Load Localization Data 
Import-LocalizedData LocalizedData -filename xSQLServer.strings.psd1 -ErrorAction SilentlyContinue 
Import-LocalizedData USLocalizedData -filename xSQLServer.strings.psd1 -UICulture en-US -ErrorAction SilentlyContinue

<#
    .SYNOPSIS
        Connect to a SQL Server Database Engine and return the server object.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName 
        String containing the SQL Server Database Engine instance to connect to. 

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting. 
        If this is not provided then the current user will be used to connect to the SQL Server Database Engine instance.
#>
function Connect-SQL
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNull()] 
        [System.String]
        $SQLServer = $env:COMPUTERNAME,
        
        [ValidateNotNull()] 
        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )
    
    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
    
    if ($SQLInstanceName -eq "MSSQLSERVER")
    {
        $connectSql = $SQLServer
    }
    else
    {
        $connectSql = "$SQLServer\$SQLInstanceName"
    }
    
    if ($SetupCredential)
    {
        $sql = New-Object Microsoft.SqlServer.Management.Smo.Server
        $sql.ConnectionContext.ConnectAsUser = $true
        $sql.ConnectionContext.ConnectAsUserPassword = $SetupCredential.GetNetworkCredential().Password
        $sql.ConnectionContext.ConnectAsUserName = $SetupCredential.GetNetworkCredential().UserName 
        $sql.ConnectionContext.ServerInstance = $connectSQL
        $sql.ConnectionContext.connect()
    }
    else
    {
        $sql = New-Object Microsoft.SqlServer.Management.Smo.Server $connectSql
    }

    if (!$sql)
    {
        Throw -Message "Failed connecting to SQL $connectSql"
    }

    New-VerboseMessage -Message "Connected to SQL $connectSql"

    return $sql
}

<#
    .SYNOPSIS
        Connect to a SQL Server Analysis Service and return the server object.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName 
        String containing the SQL Server Analysis Service instance to connect to. 

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting. 
        If this is not provided then the current user will be used to connect to the SQL Server Analysis Service instance.
#>
function Connect-SQLAnalysis
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNull()] 
        [System.String]
        $SQLServer = $env:COMPUTERNAME,
        
        [ValidateNotNull()] 
        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )
    
    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.AnalysisServices')
    
    if ($SQLInstanceName -eq "MSSQLSERVER")
    {
        $connectSql = $SQLServer
    }
    else
    {
        $connectSql = "$SQLServer\$SQLInstanceName"
    }
    
    $sql = New-Object Microsoft.AnalysisServices.Server

    if ($SetupCredential)
    {
        $userName = $SetupCredential.GetNetworkCredential().UserName 
        $password = $SetupCredential.GetNetworkCredential().Password

        $sql.Connect("Data Source=$connectSql;User ID=$userName;Password=$password")
    }
    else
    {
        $sql.Connect("Data Source=$connectSql")
    }

    if (!$sql)
    {
        Throw -Message "Failed connecting to Analysis Services $connectSql"
    }

    New-VerboseMessage -Message "Connected to Analysis Services $connectSql"

    return $sql
}

<#
    .SYNOPSIS
        Returns a localized error message.

    .PARAMETER ErrorType
        String containing the key of the localized error message.

    .PARAMETER FormatArgs
        Collection of strings to replace format objects in the error message.

    .PARAMETER ErrorCategory
        The category to use for the error message. Default value is 'OperationStopped'.
        Valid values are a value from the enumeration System.Management.Automation.ErrorCategory. 

    .PARAMETER TargetObject
        The object that was being operated on when the error occurred. 

    .PARAMETER InnerException
        Exception object that was thorwn when the error occured, which will be added to the final error message.  
#>
function New-TerminatingError 
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ErrorType,

        [Parameter(Mandatory = $false)]
        [String[]]
        $FormatArgs,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::OperationStopped,
        
        [Parameter(Mandatory = $false)]
        [Object]
        $TargetObject = $null,

        [Parameter(Mandatory = $false)]
        [System.Exception]
        $InnerException = $null
    )
    
    $errorMessage = $LocalizedData.$ErrorType
    
    if(!$errorMessage)
    {
        $errorMessage = ($LocalizedData.NoKeyFound -f $ErrorType)

        if(!$errorMessage)
        {
            $errorMessage = ("No Localization key found for key: {0}" -f $ErrorType)
        }
    }

    $errorMessage = ($errorMessage -f $FormatArgs)
    
    if( $InnerException )
    {
        $errorMessage += " InnerException: $($InnerException.Message)"
    }
    
    $callStack = Get-PSCallStack 

    # Get Name of calling script
    if($callStack[1] -and $callStack[1].ScriptName)
    {
        $scriptPath = $callStack[1].ScriptName

        $callingScriptName = $scriptPath.Split('\')[-1].Split('.')[0]
    
        $errorId = "$callingScriptName.$ErrorType"
    }
    else
    {
        $errorId = $ErrorType
    }

    Write-Verbose -Message "$($USLocalizedData.$ErrorType -f $FormatArgs) | ErrorType: $errorId"

    $exception = New-Object System.Exception $errorMessage, $InnerException    
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $ErrorCategory, $TargetObject

    return $errorRecord
}

<#
    .SYNOPSIS
        Displays a localized warning message.

    .PARAMETER WarningType
        String containing the key of the localized warning message.
    
    .PARAMETER FormatArgs
        Collection of strings to replace format objects in warning message.
#>
function New-WarningMessage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $WarningType,

        [String[]]
        $FormatArgs
    )

    ## Attempt to get the string from the localized data
    $warningMessage = $LocalizedData.$WarningType

    ## Ensure there is a message present in the localization file
    if (!$warningMessage)
    {
        $errorParams = @{
            ErrorType = 'NoKeyFound'
            FormatArgs = $WarningType
            ErrorCategory = 'InvalidArgument'
            TargetObject = 'New-WarningMessage'
        }

        ## Raise an error indicating the localization data is not present
        throw New-TerminatingError @errorParams 
    }

    ## Apply formatting
    $warningMessage = $warningMessage -f $FormatArgs

    ## Write the message as a warning
    Write-Warning -Message $warningMessage
}

<#
    .SYNOPSIS
    Displays a standardized verbose message.

    .PARAMETER Message
    String containing the key of the localized warning message.
#>
function New-VerboseMessage
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory=$true)]
        $Message
    )
    Write-Verbose -Message ((Get-Date -format yyyy-MM-dd_HH-mm-ss) + ": $Message");
}

<#
    .SYNOPSIS
        This method is used to compare current and desired values for any DSC resource.

    .PARAMETER CurrentValues
        This is hashtable of the current values that are applied to the resource.

    .PARAMETER DesiredValues 
        This is a PSBoundParametersDictionary of the desired values for the resource.

    .PARAMETER ValuesToCheck
        This is a list of which properties in the desired values list should be checked.
        If this is empty then all values in DesiredValues are checked.
#>
function Test-SQLDscParameterState 
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]  
        [HashTable]
        $CurrentValues,
        
        [Parameter(Mandatory = $true)]  
        [Object]
        $DesiredValues,

        [Array]
        $ValuesToCheck
    )

    $returnValue = $true

    if (($DesiredValues.GetType().Name -ne "HashTable") `
        -and ($DesiredValues.GetType().Name -ne "CimInstance") `
        -and ($DesiredValues.GetType().Name -ne "PSBoundParametersDictionary")) 
    {
        throw "Property 'DesiredValues' in Test-SQLDscParameterState must be either a " + `
              "Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)"
    }

    if (($DesiredValues.GetType().Name -eq "CimInstance") -and ($null -eq $ValuesToCheck)) 
    {
        throw "If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value"
    }

    if (($null -eq $ValuesToCheck) -or ($ValuesToCheck.Count -lt 1)) 
    {
        $keyList = $DesiredValues.Keys
    } 
    else 
    {
        $keyList = $ValuesToCheck
    }

    $keyList | ForEach-Object -Process {
        if (($_ -ne "Verbose")) 
        {
            if (($CurrentValues.ContainsKey($_) -eq $false) `
            -or ($CurrentValues.$_ -ne $DesiredValues.$_) `
            -or (($DesiredValues.ContainsKey($_) -eq $true) -and ($DesiredValues.$_.GetType().IsArray))) 
            {
                if ($DesiredValues.GetType().Name -eq "HashTable" -or `
                    $DesiredValues.GetType().Name -eq "PSBoundParametersDictionary") 
                {
                    
                    $checkDesiredValue = $DesiredValues.ContainsKey($_)
                } 
                else 
                {
                    $checkDesiredValue = Test-SPDSCObjectHasProperty $DesiredValues $_
                }

                if ($checkDesiredValue) 
                {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    if ($desiredType.IsArray -eq $true) 
                    {
                        if (($CurrentValues.ContainsKey($fieldName) -eq $false) `
                        -or ($null -eq $CurrentValues.$fieldName)) 
                        {
                            New-VerboseMessage -Message ("Expected to find an array value for " + `
                                                         "property $fieldName in the current " + `
                                                         "values, but it was either not present or " + `
                                                         "was null. This has caused the test method " + `
                                                         "to return false.")
                            
                            $returnValue = $false
                        } 
                        else 
                        {
                            $arrayCompare = Compare-Object -ReferenceObject $CurrentValues.$fieldName `
                                                           -DifferenceObject $DesiredValues.$fieldName
                            if ($null -ne $arrayCompare) 
                            {
                                New-VerboseMessage -Message ("Found an array for property $fieldName " + `
                                                             "in the current values, but this array " + `
                                                             "does not match the desired state. " + `
                                                             "Details of the changes are below.")
                                $arrayCompare | ForEach-Object -Process {
                                    New-VerboseMessage -Message "$($_.InputObject) - $($_.SideIndicator)"
                                }
                                
                                $returnValue = $false
                            }
                        }
                    } 
                    else 
                    {
                        switch ($desiredType.Name) 
                        {
                            "String" {
                                if (-not [String]::IsNullOrEmpty($CurrentValues.$fieldName) -or `
                                    -not [String]::IsNullOrEmpty($DesiredValues.$fieldName))
                                {
                                    New-VerboseMessage -Message ("String value for property $fieldName does not match. " + `
                                                                 "Current state is '$($CurrentValues.$fieldName)' " + `
                                                                 "and Desired state is '$($DesiredValues.$fieldName)'")
                                    
                                    $returnValue = $false
                                }
                            }
                            "Int32" {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                { 
                                    New-VerboseMessage -Message ("Int32 value for property " + "$fieldName does not match. " + `
                                                                 "Current state is " + "'$($CurrentValues.$fieldName)' " + `
                                                                 "and desired state is " + "'$($DesiredValues.$fieldName)'")
                                    
                                    $returnValue = $false
                                }
                            }
                            "Int16" {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                { 
                                    New-VerboseMessage -Message ("Int32 value for property " + "$fieldName does not match. " + `
                                                                 "Current state is " + "'$($CurrentValues.$fieldName)' " + `
                                                                 "and desired state is " + "'$($DesiredValues.$fieldName)'")
                                    
                                    $returnValue = $false
                                }
                            }
                            default {
                                New-VerboseMessage -Message ("Unable to compare property $fieldName " + `
                                                             "as the type ($($desiredType.Name)) is " + `
                                                             "not handled by the Test-SQLDscParameterState cmdlet")                                
                                
                                $returnValue = $false
                            }
                        }
                    }
                }            
            }
        } 
    }
    
    return $returnValue
}

<#
    .SYNOPSIS
        Connect to a SQL Server Database Engine and give the server permissions 'AlterAnyAvailabilityGroup' and 'ViewServerState' to the provided user.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName 
        String containing the SQL Server Database Engine instance to connect to. 

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting. 
        If this is not provided then the current user will be used to connect to the SQL Server Database Engine instance.

    .PARAMETER AuthorizedUser
        String containing the user to give the server permissions 'AlterAnyAvailabilityGroup' and 'ViewServerState'.
#>
function Grant-ServerPerms
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNull()]         
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [ValidateNotNull()] 
        [System.String]
        $SQLInstanceName= "MSSQLSERVER",

        [ValidateNotNullOrEmpty()]  
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [ValidateNotNullOrEmpty()] 
        [Parameter(Mandatory = $true)]
        [System.String]
        $AuthorizedUser
    )
    
    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -SetupCredential $SetupCredential
    }
    Try{
        $sps = New-Object Microsoft.SqlServer.Management.Smo.ServerPermissionSet([Microsoft.SqlServer.Management.Smo.ServerPermission]::AlterAnyAvailabilityGroup)
        $sps.Add([Microsoft.SqlServer.Management.Smo.ServerPermission]::ViewServerState)
        $SQL.Grant($sps,$AuthorizedUser)
        New-VerboseMessage -Message "Granted Permissions to $AuthorizedUser"
        }
    Catch{
        Write-Error "Failed to grant Permissions to $AuthorizedUser."
        }
}

<#
    .SYNOPSIS
        Connect to a Active Directory and give the Cluster Name Object all rights on the cluster Virtual Computer Object (VCO).

    .PARAMETER AvailabilityGroupNameListener
        String containing the name of the Availabilty Group's Virtual Computer Object (VCO).

    .PARAMETER CNO 
        String containing the name of the Cluster Name Object (CNO) for the failover cluster. 
#>
function Grant-CNOPerms
{
[CmdletBinding()]
    Param
    (
        [ValidateNotNullOrEmpty()] 
        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupNameListener,
        
        [ValidateNotNullOrEmpty()] 
        [Parameter(Mandatory = $true)]
        [System.String]
        $CNO
    )

    #Verify Active Directory Tools are installed, if they are load if not Throw Error
    If (!(Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"})){
        Throw "Active Directory Module is not installed and is Required."
        Exit
    }
    else{Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false}
    Try{
        $AG = Get-ADComputer $AvailabilityGroupNameListener
        
        $comp = $AG.DistinguishedName  # input AD computer distinguishedname
        $acl = Get-Acl "AD:\$comp" 
        $u = Get-ADComputer $CNO                        # get the AD user object given full control to computer
        $SID = [System.Security.Principal.SecurityIdentifier] $u.SID
        
        $identity = [System.Security.Principal.IdentityReference] $SID
        $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
        $type = [System.Security.AccessControl.AccessControlType] "Allow"
        $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
        $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType
        
        $acl.AddAccessRule($ace) 
        Set-Acl -AclObject $acl "AD:\$comp"
        New-VerboseMessage -Message "Granted privileges on $comp to $CNO"
        }
    Catch{
        Throw "Failed to grant Permissions on $comp."
        Exit
        } 
}

<#
    .SYNOPSIS
        Create a new computer object for a Availabilty Group's Virtual Computer Object (VCO).

    .PARAMETER AvailabilityGroupNameListener
        String containing the name of the Availabilty Group's Virtual Computer Object (VCO).

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName 
        String containing the SQL Server Database Engine instance to connect to. 

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting. 
        If this is not provided then the current user will be used to connect to the SQL Server Database Engine instance.
#>
function New-ListenerADObject
{
[CmdletBinding()]
    Param
    (
        [ValidateNotNullOrEmpty()] 
        [Parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupNameListener,
        
        [ValidateNotNull()] 
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [ValidateNotNull()] 
        [System.String]
        $SQLInstanceName = "MSSQLSERVER",
    
        [ValidateNotNullOrEmpty()] 
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -SetupCredential $SetupCredential
    }

    $CNO= $SQL.ClusterName
        
    #Verify Active Directory Tools are installed, if they are load if not Throw Error
    If (!(Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"})){
        Throw "Active Directory Module is not installed and is Required."
        Exit
    }
    else{Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false}
    try{
        $CNO_OU = Get-ADComputer $CNO
        #Accounts for the comma and CN= at the start of Distinguished Name
        #We want to remove these plus the ClusterName to get the actual OU Path.
        $AdditionalChars = 4
        $Trim = $CNO.Length+$AdditionalChars
        $CNOlgth = $CNO_OU.DistinguishedName.Length - $trim
        $OUPath = $CNO_OU.ToString().Substring($Trim,$CNOlgth)
        }
    catch{
        Throw ": Failed to find Computer in AD"
        exit
    }
    
    
    $m = Get-ADComputer -Filter {Name -eq $AvailabilityGroupNameListener} -Server $env:USERDOMAIN | Select-Object -Property * | Measure-Object
    
    If ($m.Count -eq 0)
    {
        Try{
            #Create Computer Object for the AgListenerName
            New-ADComputer -Name $AvailabilityGroupNameListener -SamAccountName $AvailabilityGroupNameListener -Path $OUPath -Enabled $false -Credential $SetupCredential
            New-VerboseMessage -Message "Created Computer Object $AvailabilityGroupNameListener"
            }
        Catch{
               Throw "Failed to Create $AvailabilityGroupNameListener in $OUPath"
            Exit
            }
            
            $SucccessChk =0
    
        #Check for AD Object Validate at least three successful attempts 
        $i=1
        While ($i -le 5) {
            Try{
                $ListChk = Get-ADComputer -filter {Name -like $AvailabilityGroupNameListener}
                If ($ListChk){$SuccessChk++}
                Start-Sleep -Seconds 10  
                If($SuccesChk -eq 3){break}
               }
            Catch{
                 Throw "Failed Validate $AvailabilityGroupNameListener was created in $OUPath"
                 Exit
            }
            $i++
        }            
    }
    Try{
        Grant-CNOPerms -AvailabilityGroupNameListener $AvailabilityGroupNameListener -CNO $CNO
        }
    Catch{
          Throw "Failed Validate grant permissions on $AvailabilityGroupNameListener in location $OUPAth to $CNO"
          Exit
        }

}

<#
    .SYNOPSIS
        Imports the module SQLPS in a standardized way.
#>
function Import-SQLPSModule {
    [CmdletBinding()]
    param()

    
    <# If SQLPS is not removed between resources (if it was started by another DSC resource) getting
    objects with the SQL PS provider will fail in some instances because of some sort of inconsistency. Uncertain why this happens. #>
    if( (Get-Module SQLPS).Count -ne 0 ) {
        Write-Debug "Unloading SQLPS module."
        Remove-Module -Name SQLPS -Force -Verbose:$False
    }
    
    Write-Debug "SQLPS module changes CWD to SQLSERVER:\ when loading, pushing location to pop it when module is loaded."
    Push-Location

    try {
        New-VerboseMessage -Message "Importing SQLPS module."
        Import-Module -Name SQLPS -DisableNameChecking -Verbose:$False -ErrorAction Stop # SQLPS has unapproved verbs, disable checking to ignore Warnings.
        Write-Debug "SQLPS module imported." 
    }
    catch {
        throw New-TerminatingError -ErrorType FailedToImportSQLPSModule -ErrorCategory InvalidOperation -InnerException $_.Exception
    }
    finally {
        Write-Debug "Popping location back to what it was before importing SQLPS module."
        Pop-Location
    }

}

<#
    .SYNOPSIS
        Returns the SQL Server instance name in the way SQLPS Provider expect it.

    .DESCRIPTION
        The SQLPS Provider doesn't use the default instance name of MSSQLSERVER, instead it uses DEFAULT.
        This function make sure the correct default instance name is returned.

    .PARAMETER InstanceName 
        String containing the SQL Server Database Engine instance to validate. 
#>
function Get-SQLPSInstanceName
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    if( $InstanceName -eq "MSSQLSERVER" ) {
        $InstanceName = "DEFAULT"            
    }
    
    return $InstanceName
}

<#
    .SYNOPSIS
        Returns the SQL Server SQLPS provider server object.

    .PARAMETER InstanceName 
        String containing the SQL Server Database Engine instance to connect to. 

    .PARAMETER NodeName 
        String containing the host name of the SQL Server to connect to. 
#>
function Get-SQLPSInstance
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName 
    )

    $InstanceName = Get-SQLPSInstanceName -InstanceName $InstanceName 
    $Path = "SQLSERVER:\SQL\$NodeName\$InstanceName"
    
    New-VerboseMessage -Message "Connecting to $Path as $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"

    Import-SQLPSModule
    $instance = Get-Item $Path
    
    return $instance
}

<#
    .SYNOPSIS
        Returns the SQL Server SQLPS provider endpoint object.

    .PARAMETER Name 
        String containing the name of the endpoint to return. 

    .PARAMETER InstanceName 
        String containing the SQL Server Database Engine instance to connect to. 

    .PARAMETER NodeName 
        String containing the host name of the SQL Server to connect to. 
#>
function Get-SQLAlwaysOnEndpoint
{
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName 
    )

    $instance = Get-SQLPSInstance -InstanceName $InstanceName -NodeName $NodeName
    $Path = "$($instance.PSPath)\Endpoints"

    Write-Debug "Connecting to $Path as $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    
    [String[]] $presentEndpoint = Get-ChildItem $Path
    if( $presentEndpoint.Count -ne 0 -and $presentEndpoint.Contains("[$Name]") ) {
        Write-Debug "Connecting to endpoint $Name as $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
        $endpoint = Get-Item "$Path\$Name"
    } else {
        $endpoint = $null
    }    

    return $endpoint
}

<#
    .SYNOPSIS
        Create a new database in the SQL Server instance provided.

    .PARAMETER SQL 
        An object returned from Connect-SQL function in which the database will be created. 

    .PARAMETER Name 
        String containing the database name to be created. 
#>
function New-SqlDatabase
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $SQL,
        
        [ValidateNotNull()] 
        [System.String]
        $Name
    )
    
    $newDatabase = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $SQL,$Name
    if ($newDatabase)
    {
        New-VerboseMessage -Message "Adding to SQL the database $Name"
        $newDatabase.Create()
    }
    else
    {
        New-VerboseMessage -Message "Failed to adding the database $Name"
    }    
}

<#
    .SYNOPSIS
        Remove a database in the SQL Server instance provided.

    .PARAMETER SQL 
        An object returned from Connect-SQL function in which a database will be removed. 

    .PARAMETER Name 
        String containing the database name to be removed. 
#>
function Remove-SqlDatabase
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $Sql,
        
        [ValidateNotNull()] 
        [System.String]
        $Name
    )
    
    $getDatabase = $Sql.Databases[$Name]
    if ($getDatabase)
    {
        New-VerboseMessage -Message "Deleting to SQL the database $Name"
        $getDatabase.Drop()
    }
    else
    {
        New-VerboseMessage -Message "Failed to deleting the database $Name"
    }    
}

<#
    .SYNOPSIS
        Add a user to a server role in the SQL Server instance provided.

    .PARAMETER Sql
        An object returned from Connect-SQL function. 

    .PARAMETER LoginName 
        String containing the login (user) which should be added as a member to the server role. 

    .PARAMETER ServerRole 
        String containing the name of the server role which the user will be added as a member to. 
#>
function Add-SqlServerRoleMember
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $Sql,
        
        [ValidateNotNull()] 
        [System.String]
        $LoginName,

        [ValidateNotNull()] 
        [System.String[]]
        $ServerRole

    )
    
    $sqlRole = $Sql.Roles
    if ($sqlRole)
    {
        try
        {
            foreach ($currentServerRole in $ServerRole)
            {
                New-VerboseMessage -Message "Adding SQL login $LoginName in role $currentServerRole"
                $sqlRole[$currentServerRole].AddMember($LoginName)
            }
        }
        catch
        {
            New-VerboseMessage -Message "Failed adding SQL login $LoginName in role $currentServerRole"
        }
    }
    else
    {
        New-VerboseMessage -Message "Failed to getting SQL server roles"
    }
}

<#
    .SYNOPSIS
        Remove a user in a server role in the SQL Server instance provided.

    .PARAMETER Sql 
        An object returned from Connect-SQL function. 

    .PARAMETER LoginName 
        String containing the login (user) which should be removed as a member in the server role. 

    .PARAMETER ServerRole 
        String containing the name of the server role for which the user will be removed as a member. 
#>
function Remove-SqlServerRoleMember
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $Sql,
        
        [ValidateNotNull()] 
        [System.String]
        $LoginName,

        [ValidateNotNull()] 
        [System.String[]]
        $ServerRole

    )
    
    $sqlRole = $Sql.Roles
    if ($sqlRole)
    {
        try
        {
            foreach ($currentServerRole in $ServerRole)
            {
                New-VerboseMessage -Message "Deleting SQL login $LoginName in role $currentServerRole"
                $sqlRole[$currentServerRole].DropMember($LoginName)
            }
        }
        catch
        {
            New-VerboseMessage -Message "Failed deleting SQL login $LoginName in role $currentServerRole"
        }
    }
    else
    {
        New-VerboseMessage -Message "Failed to getting SQL server roles"
    }
}

<#
    .SYNOPSIS
        This validates if a user is a member of a server role.
        The function returns $true is the login (user) is a member in the provided server role.
        It will return $false if the user is not member of the provided server role.

    .PARAMETER SQL 
        An object returned from Connect-SQL function. 

    .PARAMETER LoginName 
        String containing the login (user) which should be verified as a member in the server role. 

    .PARAMETER ServerRole 
        String containing the name of the server role which the user will be verified if a member of. 
#>
function Confirm-SqlServerRoleMember
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $Sql,
        
        [ValidateNotNull()] 
        [System.String]
        $LoginName,

        [ValidateNotNull()] 
        [System.String[]]
        $ServerRole

    )
    
    $sqlRole = $Sql.Roles
    if ($sqlRole)
    {
        foreach ($currentServerRole in $ServerRole)
        {
            if ($sqlRole[$currentServerRole])
            {
                $membersInRole = $sqlRole[$currentServerRole].EnumMemberNames()             
                if ($membersInRole.Contains($Name))
                {
                    $confirmServerRole = $true
                    New-VerboseMessage -Message "$Name is present in SQL role name $currentServerRole"
                }
                else
                {
                    New-VerboseMessage -Message "$Name is absent in SQL role name $currentServerRole"
                    $confirmServerRole = $false
                }
            }
            else
            {
                New-VerboseMessage -Message "SQL role name $currentServerRole is absent"
                $confirmServerRole = $false
            }
        }
    }
    else
    {
        New-VerboseMessage -Message "Failed getting SQL roles"
        $confirmServerRole = $false
    }

    return $confirmServerRole
}

<#
    .SYNOPSIS
    This cmdlet is used to return the owner of a SQL database

    .PARAMETER Sql
    This is an object of the SQL server that contains the result of Connect-SQL

    .PARAMETER Database
    This is the SQL database that will be checking
#>
function Get-SqlDatabaseOwner
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $Sql,

        [ValidateNotNull()] 
        [System.String]
        $Database
    )
    
    Write-Verbose -Message 'Getting SQL Databases'
    $sqlDatabase = $Sql.Databases
    if ($sqlDatabase)
    {
        if ($sqlDatabase[$Database])
        {
            $Name = $sqlDatabase[$Database].Owner
        }
        else
        {
            throw New-TerminatingError -ErrorType FailedToGetOwnerDatabase `
                                       -FormatArgs @($Database) `
                                       -ErrorCategory InvalidOperation
        }
    }
    else
    {
        Write-Verbose -Message 'Failed getting SQL databases'
    }

    $Name
}

<#
    .SYNOPSIS
    This cmdlet is used to configure the owner of a SQL database

    .PARAMETER Sql
    This is an object of the SQL server that contains the result of Connect-SQL

    .PARAMETER Name
    This is the name of the desired owner for the SQL database

    .PARAMETER Database
    This is the SQL database that will be setting
#>
function Set-SqlDatabaseOwner
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $Sql,
        
        [ValidateNotNull()] 
        [System.String]
        $Name,

        [ValidateNotNull()] 
        [System.String]
        $Database
    )
    
    Write-Verbose -Message 'Getting SQL Databases'
    $sqlDatabase = $Sql.Databases
    $sqlLogins = $Sql.Logins

    if ($sqlDatabase -and $sqlLogins)
    {
        if ($sqlDatabase[$Database])
        {
            if ($sqlLogins[$Name])
            {
                try
                {
                    $sqlDatabase[$Database].SetOwner($Name)
                    New-VerboseMessage -Message "Owner of SQL Database name $Database is now $Name"
                }
                catch
                {
                    throw New-TerminatingError -ErrorType FailedToSetOwnerDatabase -ErrorCategory InvalidOperation -InnerException $_.Exception
                }
            }
            else
            {
                Write-Error -Message "SQL Login name $Name does not exist" -Category InvalidData
            }
        }
        else
        {
            Write-Error -Message "SQL Database name $Database does not exist" -Category InvalidData
        }
    }
    else
    {
        Write-Verbose -Message 'Failed getting SQL databases and logins'
    }
}

<#
    .SYNOPSIS
    Restarts a SQL Server instance and associated services

    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configued. Default is 'MSSQLSERVER'

    .PARAMETER Timeout
    Timeout value for restarting the SQL services. The default value is 120 seconds.

    .EXAMPLE
    Restart-SqlService -SQLServer localhost

    .EXAMPLE
    Restart-SqlService -SQLServer localhost -SQLInstanceName 'NamedInstance'

    .EXAMPLE
    Restart-SqlService -SQLServer CLU01 -Timeout 300
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter()]
        [String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [Int32]
        $Timeout = 120
    )

    ## Connect to the instance
    $serverObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($serverObject.IsClustered)
    {
        ## Get the cluster resources
        New-VerboseMessage -Message 'Getting cluster resource for SQL Server' 
        $sqlService = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Resource -Filter "Type = 'SQL Server'" | 
                        Where-Object { $_.PrivateProperties.InstanceName -eq $serverObject.ServiceName }

        New-VerboseMessage -Message 'Getting active cluster resource SQL Server Agent'
        $agentService = $sqlService | Get-CimAssociatedInstance -ResultClassName MSCluster_Resource |
                            Where-Object { ($_.Type -eq "SQL Server Agent") -and ($_.State -eq 2) }

        ## Build a listing of resources being acted upon
        $resourceNames = @($sqlService.Name, ($agentService | Select -ExpandProperty Name)) -join ","

        ## Stop the SQL Server and dependent resources
        New-VerboseMessage -Message 'Bringing the SQL Server resources $resourceNames offline.'
        $sqlService | Invoke-CimMethod -MethodName TakeOffline -Arguments @{ Timeout = $Timeout }

        ## Start the SQL server resource
        New-VerboseMessage -Message 'Bringing the SQL Server resource back online.'
        $sqlService | Invoke-CimMethod -MethodName BringOnline -Arguments @{ Timeout = $Timeout }

        ## Start the SQL Agent resource
        if ($agentService)
        {
            New-VerboseMessage -Message 'Bringing the SQL Server Agent resource online.'
            $agentService | Invoke-CimMethod -MethodName BringOnline -Arguments @{ Timeout = $Timeout }
        }
    }
    else
    {
        New-VerboseMessage -Message 'Getting SQL Service information'
        $sqlService = Get-Service -DisplayName "SQL Server ($($serverObject.ServiceName))"

        ## Get all dependent services that are running.
        ## There are scenarios where an automatic service is stopped and should not be restarted automatically.
        $agentService = $sqlService.DependentServices | Where-Object { $_.Status -eq "Running" }

        ## Restart the SQL Server service
        New-VerboseMessage -Message 'SQL Server service restarting'
        $sqlService | Restart-Service -Force

        ## Start dependent services
        $agentService | ForEach-Object {
            New-VerboseMessage -Message "Starting $($_.DisplayName)"
            $_ | Start-Service
        }
    }
}

<#
    .SYNOPSIS
    This cmdlet is used to return the permissions of a SQL database

    .PARAMETER Sql
    This is an object of the SQL server that contains the result of Connect-SQL

    .PARAMETER Name
    This is the name of the desired login for the SQL database

    .PARAMETER Database
    This is the SQL database that will be getting

    .PARAMETER PermissionState
    This is the state of permissions (Grant or Deny) that will be getting
#>
function Get-SqlDatabasePermission
{
    [CmdletBinding()]    
    param
    (   
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.Object]
        $Sql,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $PermissionState
    )

    Write-Verbose -Message "Getting Sql Databases and SQL Logins"
    $sqlDatabase = $Sql.Databases[$Database]
    $sqlLogin = $Sql.Logins[$Name]
    $sqlInstanceName = $Sql.InstanceName
    $sqlServer = $Sql.ComputerNamePhysicalNetBIOS

    # Initialize variable permission
    [System.String[]] $permission = @()

    if ($sqlDatabase)
    {        
        if ($sqlLogin)
        {
            Write-Verbose -Message "Getting Permissions for SQL Login $Name in database $Database"

            $databasePermissionInfo = $sqlDatabase.EnumDatabasePermissions($Name)
            $databasePermissionInfo = $databasePermissionInfo | where { $_.PermissionState -eq $PermissionState }

            foreach ($currentDatabasePermissionInfo in $databasePermissionInfo)
            {
                $permissionProperty = ($currentDatabasePermissionInfo.PermissionType | Get-Member -MemberType Property).Name
                foreach ($currentPermissionProperty in $permissionProperty)
                {
                    if ($currentDatabasePermissionInfo.PermissionType."$currentPermissionProperty")
                    {
                        $permission += $currentPermissionProperty
                    }
                }
            }
        }
        else
        {
            New-TerminatingError -ErrorType LoginNotFound `
                                 -FormatArgs @($Name,$sqlServer,$sqlInstanceName) `
                                 -ErrorCategory ObjectNotFound 
        }
    }
    else
    {
        New-TerminatingError -ErrorType NoDatabase `
                             -FormatArgs @($Database,$sqlServer,$sqlInstanceName) `
                             -ErrorCategory InvalidResult
    }

    $permission
}

<#
    .SYNOPSIS
    This cmdlet is used to add the permissions of a SQL database

    .PARAMETER Sql
    This is an object of the SQL server that contains the result of Connect-SQL

    .PARAMETER Name
    This is the name of the desired login for the SQL database

    .PARAMETER Database
    This is the SQL database that will be setting

    .PARAMETER PermissionState
    This is the state of permissions (Grant or Deny) that will be setting

    .PARAMETER Permissions
    This is the type of permissions (Connect, Update, etc...) that will be setting
#>
function Add-SqlDatabasePermission
{
    [CmdletBinding()]    
    param
    (   
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.Object]
        $Sql,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions
    )

    Write-Verbose -Message "Getting SQL Databases and SQL Logins"
    $sqlDatabase = $Sql.Databases[$Database]
    $sqlLogin = $Sql.Logins[$Name]
    $sqlInstanceName = $Sql.InstanceName
    $sqlServer = $Sql.ComputerNamePhysicalNetBIOS

    if ($sqlDatabase)
    {        
        if ($sqlLogin)
        {
            if (!$sqlDatabase.Users[$Name])
            {
                try
                {
                    Write-Verbose -Message "Adding SQL login $Name as a user of database " + `
                                           "$Database on $sqlServer\$sqlInstanceName"
                    $sqlDatabaseUser = New-Object Microsoft.SqlServer.Management.Smo.User $sqlDatabase,$Name
                    $sqlDatabaseUser.Login = $Name
                    $sqlDatabaseUser.Create()
                }
                catch
                {
                    Write-Verbose -Message "Failed adding SQL login $Name as a user of " + `
                                           "database $Database on $sqlServer\$sqlInstanceName"
                }
            }

            if ($sqlDatabase.Users[$Name])
            {
                try
                {
                    Write-Verbose -Message "$PermissionState - Adding SQL login $Name to permissions $permissions " + `
                                           "on database $Database on $sqlServer\$sqlInstanceName"
                    $permissionSet = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabasePermissionSet
                    foreach ($permission in $permissions)
                    {
                        $permissionSet."$permission" = $true
                    }
                    switch ($PermissionState) 
                    {
                        "Grant" { $sqlDatabase.Grant($permissionSet,$Name) }
                        "Deny" { $sqlDatabase.Deny($permissionSet,$Name) }
                    }                    
                }
                catch
                {
                    Write-Verbose -Message "Failed adding SQL login $Name to permissions $permissions " + `
                                           "on database $Database on $sqlServer\$sqlInstanceName"
                }
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType LoginNotFound `
                                       -FormatArgs @($Name,$sqlServer,$sqlInstanceName) `
                                       -ErrorCategory ObjectNotFound
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NoDatabase `
                                   -FormatArgs @($Database,$sqlServer,$sqlInstanceName) `
                                   -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    This cmdlet is used to remove the permissions of a SQL database

    .PARAMETER Sql
    This is an object of the SQL server that contains the result of Connect-SQL

    .PARAMETER Name
    This is the name of the desired login for the SQL database

    .PARAMETER Database
    This is the SQL database that will be setting

    .PARAMETER PermissionState
    This is the state of permissions (Grant or Deny) that will be setting

    .PARAMETER Permissions
    This is the type of permissions (Connect, Update, etc...) that will be setting
#>
function Remove-SqlDatabasePermission
{
    [CmdletBinding()]    
    param
    (   
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.Object]
        $Sql,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $Name,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        [System.String]
        $PermissionState,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions
    )

    Write-Verbose -Message "Getting SQL Databases and SQL Logins"
    $sqlDatabase = $Sql.Databases[$Database]
    $sqlLogin = $Sql.Logins[$Name]
    $sqlInstanceName = $Sql.InstanceName
    $sqlServer = $Sql.ComputerNamePhysicalNetBIOS

    if ($sqlDatabase)
    {        
        if ($sqlLogin)
        {
            if (!$sqlDatabase.Users[$Name])
            {
                try
                {
                    Write-Verbose -Message "Adding SQL login $Name as a user of database " + `
                                           "$Database on $sqlServer\$sqlInstanceName"
                    $sqlDatabaseUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User `
                                                  -ArgumentList $sqlDatabase,$Name
                    $sqlDatabaseUser.Login = $Name
                    $sqlDatabaseUser.Create()
                }
                catch
                {
                    Write-Verbose -Message "Failed adding SQL login $Name as a user of " + `
                                           "database $Database on $sqlServer\$sqlInstanceName"
                }
            }

            if ($sqlDatabase.Users[$Name])
            {
                try
                {
                    Write-Verbose -Message "$PermissionState - Removing SQL login $Name to permissions $permissions " + `
                                           "on database $Database on $sqlServer\$sqlInstanceName"
                    $permissionSet = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabasePermissionSet
                    foreach ($permission in $permissions)
                    {
                        $permissionSet."$permission" = $false
                    }
                    switch ($PermissionState) 
                    {
                        "Grant" { $sqlDatabase.Grant($permissionSet,$Name) }
                        "Deny" { $sqlDatabase.Deny($permissionSet,$Name) }
                    }                    
                }
                catch
                {
                    Write-Verbose -Message "Failed removing SQL login $Name to permissions $permissions " + `
                                           "on database $Database on $sqlServer\$sqlInstanceName"
                }
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType LoginNotFound `
                                       -FormatArgs @($Name,$sqlServer,$sqlInstanceName) `
                                       -ErrorCategory ObjectNotFound
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NoDatabase `
                                   -FormatArgs @($Database,$sqlServer,$sqlInstanceName) `
                                   -ErrorCategory InvalidResult
    }
}
