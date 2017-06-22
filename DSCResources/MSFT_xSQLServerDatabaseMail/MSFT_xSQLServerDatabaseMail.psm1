function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [parameter(Mandatory = $true)]
        [System.String]
        $ProfileName
    )

    Get-SQLPSModule

    if($sqlServer)
    {
        Write-Verbose "Load the SMO assembly and create the server object, connecting to server '$($sqlServer)'"
        $null   = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
        $server = New-Object Microsoft.SqlServer.Management.SMO.Server ($sqlServer)
    }

    if($server.Configuration.DatabaseMailEnabled.ConfigValue -eq 1)
    {
        $dBmail  = $server.Mail
        $account = $dBmail.Accounts|Where-Object {$_.Name -eq $account_name}
        $returnValue        = @{
            sqlServer       = $env:COMPUTERNAME
            account_name    = $account.Name
            email_address   = $account.EmailAddress
            mailserver_name = $account.MailServers.Name
            profile_name    = $account.GetAccountProfileNames()[0]
            display_name    = $account.DisplayName
            replyto_address = $account.ReplyToAddress
            description     = $account.Description
            mailserver_type = $account.MailServers.ServerType
            port            = $account.MailServers.Port
        }
    }
    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [System.String]
        $DisplayName = $SQLServer,

        [System.String]
        $ReplyToAddress = $EmailAddress,

        [System.String]
        $Description = "Mail account to send alerts for the DBAs",

        [System.String]
        $MailServerType = "SMTP",

        [System.UInt16]
        $Port = 25
    )

    Get-SQLPSModule

    if($sqlServer)
    {
        Write-Verbose "Load the SMO assembly and create the server object, connecting to server '$($sqlServer)'"
        $null   = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
        $server = New-Object Microsoft.SqlServer.Management.SMO.Server ($sqlServer)
    }

    if($server)
    {
        Write-Verbose "Configure the SQL Server to enable Database Mail."
        ##Named Pipes had to be enabled, Why??
        if($server.Configuration.DatabaseMailEnabled.ConfigValue -ne 1)
        {
            $server.Configuration.DatabaseMailEnabled.ConfigValue = 1
            $server.Configuration.Alter()
            ##Test
            $dbMailXPs = $server.Configuration.DatabaseMailEnabled.ConfigValue
            Write-Verbose "Database Mail XPs is '$($dbMailXPs)'"
        }
        else {$dbMailXPs = 1}

        if($dbMailXPs -eq 1)
        {
            Write-Verbose "Alter mail system parameters if desired, this is an optional step."
            $dBmail = $server.Mail
            $dBmail.ConfigurationValues.Item('LoggingLevel').Value = 1
            $dBmail.ConfigurationValues.Item('LoggingLevel').Alter()
            #Test
            $LoggingLevel = $dBmail.ConfigurationValues.Item('LoggingLevel').Value
            Write-Verbose "Database Mail Logging Level is '$($LoggingLevel)'"

            Write-Verbose "Create the mail account '$($account_name)'"
            if(!($dBmail.Accounts|Where-Object {$_.Name -eq $account_name}))
            {
                $account = New-Object Microsoft.SqlServer.Management.SMO.Mail.MailAccount($dBmail,$account_name) -ErrorAction SilentlyContinue
                $account.Description    = $description
                $account.DisplayName    = $sqlServer
                $account.EmailAddress   = $email_address
                $account.ReplyToAddress = $replyto_address
                $account.Create()

                $account.MailServers.Item($sqlServer).Rename($mailserver_name)
                $account.Alter()
            }
            else {Write-Verbose "DB mail account '$($account_name)' already esists"}

            Write-Verbose "Create a public default profile '$($profile_name)'"
            if(!($dBmail.Profiles|Where-Object {$_.Name -eq $profile_name}))
            {
                $profile = New-Object Microsoft.SqlServer.Management.SMO.Mail.MailProfile($dBmail,$profile_name)
                $profile.Description    = $description
                $profile.Create()

                $profile.AddAccount($account_name, 0)
                $profile.AddPrincipal('public', 1)
                $profile.Alter()
            }
            else {Write-Verbose "DB mail profile '$($profile_name)' already esists"}

            Write-Verbose "Configure the SQL Agent to use dbMail."
            if($server.JobServer.AgentMailType -ne 'DatabaseMail' -or $server.JobServer.DatabaseMailProfile -ne $profile_name)
            {
                $server.JobServer.AgentMailType = 'DatabaseMail'
                $server.JobServer.DatabaseMailProfile = $profile_name
                $server.JobServer.Alter()
            }

        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [System.String]
        $DisplayName = $SQLServer,

        [System.String]
        $ReplyToAddress = $EmailAddress,

        [System.String]
        $Description = "Mail account to send alerts for the DBAs",

        [System.String]
        $MailServerType = "SMTP",

        [System.UInt16]
        $Port = 25
    )

    Get-SQLPSModule

    $state = Get-TargetResource -account_name $account_name -sqlServer $sqlServer `
        -email_address $email_address -mailserver_name $mailserver_name `
        -profile_name $profile_name -ErrorAction SilentlyContinue

    return ($state.account_name       -eq $account_name) -and
     ($state.sqlServer          -eq $sqlServer) -and
     ($state.email_address      -eq $email_address) -and
     ($state.mailserver_name    -eq $mailserver_name) -and
     ($state.profile_name       -eq $profile_name) -and
     ($state.replyto_address    -eq $replyto_address) -and
     ($state.mailserver_type    -eq $mailserver_type) -and
     ($state.port               -eq $port)

}

#region helper functions
Function Get-SQLPSModule
{   if (-not(Get-Module -name 'SQLPS'))
    {   if (Get-Module  -ListAvailable|Where-Object {$_.Name -eq 'SQLPS' })
        {   Push-Location
            Import-Module -Name 'SQLPS' -DisableNameChecking
            Pop-Location
        }
    }
}

Export-ModuleMember -Function *-TargetResource
