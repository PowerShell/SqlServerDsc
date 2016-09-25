# Set Global Module Verbose
$VerbosePreference = 'Continue' 

# Load Localization Data 
Import-LocalizedData LocalizedData -filename xSQLServer.strings.psd1 -ErrorAction SilentlyContinue 
Import-LocalizedData USLocalizedData -filename xSQLServer.strings.psd1 -UICulture en-US -ErrorAction SilentlyContinue

function Connect-SQL
{
[CmdletBinding()]
    param
    (   [ValidateNotNull()] 
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
    
    if($SQLInstanceName -eq "MSSQLSERVER")
    {
        $ConnectSQL = $SQLServer
    }
    else
    {
        $ConnectSQL = "$SQLServer\$SQLInstanceName"
    }
    if ($SetupCredential)
    {
        $SQL = New-Object Microsoft.SqlServer.Management.Smo.Server
        $SQL.ConnectionContext.ConnectAsUser = $true
        $SQL.ConnectionContext.ConnectAsUserPassword = $SetupCredential.GetNetworkCredential().Password
        $SQL.ConnectionContext.ConnectAsUserName = $SetupCredential.GetNetworkCredential().UserName 
        $SQL.ConnectionContext.ServerInstance = $ConnectSQL
        $SQL.ConnectionContext.connect()
    }
    else
    {
        $SQL = New-Object Microsoft.SqlServer.Management.Smo.Server $ConnectSQL
    }
    if($SQL)
    {
        New-VerboseMessage -Message "Connected to SQL $ConnectSQL"
        $SQL
    }
    else
    {
        Throw -Message "Failed connecting to SQL $ConnectSQL"
        Exit
    }
}

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

function Remove-SqlDatabase
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
    
    $getDatabase = $SQL.Databases[$Name]
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

function Add-SqlServerRole
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $SQL,
        
        [ValidateNotNull()] 
        [System.String]
        $LoginName,

        [ValidateNotNull()] 
        [System.String[]]
        $ServerRole

    )
    
    $sqlRole = $SQL.Roles
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

function Remove-SqlServerRole
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $SQL,
        
        [ValidateNotNull()] 
        [System.String]
        $LoginName,

        [ValidateNotNull()] 
        [System.String[]]
        $ServerRole

    )
    
    $sqlRole = $SQL.Roles
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

function Confirm-SqlServerRole
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $SQL,
        
        [ValidateNotNull()] 
        [System.String]
        $LoginName,

        [ValidateNotNull()] 
        [System.String[]]
        $ServerRole

    )
    
    $sqlRole = $SQL.Roles
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

function Get-SqlDatabasePermission
{
    [CmdletBinding()]    
    param
    (   
        [ValidateNotNull()] 
        [System.Object]
        $SQL,
        
        [ValidateNotNull()] 
        [System.String]
        $Name,

        [ValidateNotNull()] 
        [System.String]
        $Database
    )
    # Check if database and login exist
    Write-Verbose 'Getting SQL Databases and SQL Logins'
    $sqlDatabase = $SQL.Databases[$Database]
    $sqlLogin = $SQL.Logins[$Name]

    # Initialize variables
    $permissions = @()

    if ($sqlDatabase)
    {        
        if ($sqlLogin)
        {
            Write-Verbose "Getting Permissions for SQL Login $Name in database $Database"
            $permissionSet = $sqlDatabase.EnumDatabasePermissions($Name)
            foreach ($permission in $permissionSet)
            {
                $properties = ($permission.PermissionType | Get-Member -MemberType Property).Name
                foreach ($property in $properties)
                {
                    if ($permission.PermissionType."$property")
                    {
                        $permissions += $property
                    }
                }
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType LoginNotFound -FormatArgs @($Name,$SQL.ComputerNamePhysicalNetBIOS,$SQL.InstanceName) -ErrorCategory ObjectNotFound
            $null = $permissions   
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType NoDatabase -FormatArgs @($Database,$SQL.ComputerNamePhysicalNetBIOS,$SQL.InstanceName) -ErrorCategory InvalidResult
        $null = $permissions
    }

    $permissions
}
