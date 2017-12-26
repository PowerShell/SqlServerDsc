Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force

<#
    .SYNOPSIS
        Returns the current state of the database mail configuration.

    .PARAMETER ServerName
        The hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER AccountName
        The name of the database mail account.

    .PARAMETER EmailAddress
        The e-mail address from which mail will originate.

    .PARAMETER MailServerName
        The fully qualified domain name of the mail server name to which e-mail are
        sent.

    .PARAMETER ProfileName
        The profile name of the database mail.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName
    )

    $returnValue = @{
        Ensure         = 'Absent'
        ServerName     = $ServerName
        InstanceName   = $InstanceName
        AccountName    = $null
        EmailAddress   = $null
        MailServerName = $null
        ProfileName    = $null
        DisplayName    = $null
        ReplyToAddress = $null
        Description    = $null
        MailServerType = $null
        TcpPort        = $null
    }

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        if ($sqlServerObject.Configuration.DatabaseMailEnabled.RunValue -eq 1)
        {
            $databaseMail = $sqlServerObject.Mail

            $account = $databaseMail.Accounts | Where-Object -FilterScript {
                $_.Name -eq $AccountName
            }

            if ($account)
            {
                $returnValue['Ensure'] = 'Present'
                $returnValue['AccountName'] = $account.Name
                $returnValue['EmailAddress'] = $account.EmailAddress
                $returnValue['MailServerName'] = $account.MailServers.Name
                $returnValue['ProfileName'] = $account.GetAccountProfileNames()[0]
                $returnValue['DisplayName'] = $account.DisplayName
                $returnValue['ReplyToAddress'] = $account.ReplyToAddress
                $returnValue['Description'] = $account.Description
                $returnValue['MailServerType'] = $account.MailServers.ServerType
                $returnValue['TcpPort'] = $account.MailServers.Port
            }
        }
        else
        {
            throw 'Database mail is not enabled.'
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Creates or removes the database mail configuration.

        Information about the different properties can be found here
        https://docs.microsoft.com/en-us/sql/relational-databases/database-mail/configure-database-mail.

    .PARAMETER Ensure
        Specifies the desired state of the database mail.
        When set to 'Present', the database mail will be created.
        When set to 'Absent', the database mail will be removed.
        Default value is 'Present'.

    .PARAMETER ServerName
        The hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER AccountName
        The name of the database mail account.

    .PARAMETER EmailAddress
        The e-mail address from which mail will originate.

    .PARAMETER MailServerName
        The fully qualified domain name of the mail server name to which e-mail are
        sent.

    .PARAMETER ProfileName
        The profile name of the database mail.

    .PARAMETER DisplayName
        The display name of the database mail. Default value is the same value
        assigned to parameter AccountName.

    .PARAMETER ReplyToAddress
        The e-mail address to which the receiver of e-mails will reply to.
        Default value is the same e-mail address assigned to parameter EmailAddress.

    .PARAMETER Description
        The description of the database mail.

    .PARAMETER LoggingLevel
        The logging level that the database mail will use. If not specified the
        default logging level is 'Extended'. { Normal | *Extended* | Verbose }.

    .PARAMETER TcpPort
        The TCP port used for communication. Default value is port 25.
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

        [Parameter()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [System.String]
        $DisplayName = $AccountName,

        [Parameter()]
        [System.String]
        $ReplyToAddress = $EmailAddress,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        [ValidateSet('SMTP')]
        $MailServerType = 'SMTP',

        [Parameter()]
        [System.String]
        [ValidateSet('Normal','Extended','Verbose')]
        $LoggingLevel,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 25
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message "Configure the SQL Server to enable Database Mail."

        ##Named Pipes had to be enabled, Why??

        $databaseMailEnabled = $sqlServerObject.Configuration.DatabaseMailEnabled.RunValue
        if ($databaseMailEnabled -ne 1)
        {
            Write-Verbose -Message "Database Mail XPs are set to '$($databaseMailEnabled)'. Will try to enabled Database Mail XPs."
            $sqlServerObject.Configuration.DatabaseMailEnabled.ConfigValue = 1
            $sqlServerObject.Configuration.Alter()

            # Set $databaseMailEnabled to the new value.
            $databaseMailEnabled = $sqlServerObject.Configuration.DatabaseMailEnabled.RunValue
            Write-Verbose -Message "Database Mail XPs are set to '$($databaseMailEnabled)'"
        }

        if ($databaseMailEnabled -eq 1)
        {
            $databaseMail = $sqlServerObject.Mail

            if ($PSBoundParameters.ContainsKey('LoggingLevel'))
            {
                $loggingLevelValue = switch ($LoggingLevel)
                {
                    'Normal'
                    {
                        1
                    }

                    'Extended'
                    {
                        2
                    }

                    'Verbose'
                    {
                        3
                    }
                }

                Write-Verbose -Message ('Changing Database Mail logging level to {0}' -f $loggingLevelValue)

                $databaseMail.ConfigurationValues.Item('LoggingLevel').Value = $loggingLevelValue
                $databaseMail.ConfigurationValues.Item('LoggingLevel').Alter()
            }

            #Test
            $loggingLevelValue = $databaseMail.ConfigurationValues.Item('LoggingLevel').Value
            Write-Verbose -Message "Database Mail logging level is '$($loggingLevelValue)'"

            $databaseMailAccount = $databaseMail.Accounts | Where-Object -FilterScript {
                $_.Name -eq $AccountName
            }

            if (-not $databaseMailAccount)
            {
                Write-Verbose -Message "Create the mail account '$($AccountName)'"

                $databaseMailAccount = New-Object Microsoft.SqlServer.Management.SMO.Mail.MailAccount($databaseMail, $AccountName)
                $databaseMailAccount.Description = $Description
                $databaseMailAccount.DisplayName = $ServerName
                $databaseMailAccount.EmailAddress = $EmailAddress
                $databaseMailAccount.ReplyToAddress = $ReplyToAddress
                $databaseMailAccount.Create()

                $mailServer = $databaseMailAccount.MailServers[0]

                if ($mailServer)
                {
                    $mailServer.Rename($MailServerName)

                    if ($PSBoundParameters.ContainsKey('TcpPort'))
                    {
                        $mailServer.Port = $TcpPort
                    }

                    $mailServer.Alter()
                }
            }
            else
            {
                Write-Verbose -Message "DB mail account '$($AccountName)' already exist."
            }

            Write-Verbose -Message "Create a public default profile '$($ProfileName)'"
            if ( -not ($databaseMail.Profiles|Where-Object {$_.Name -eq $ProfileName}))
            {
                $profile = New-Object Microsoft.SqlServer.Management.SMO.Mail.MailProfile($databaseMail, $ProfileName)
                $profile.Description = $Description
                $profile.Create()

                $profile.AddAccount($AccountName, 0)
                $profile.AddPrincipal('public', 1)
                $profile.Alter()
            }
            else
            {
                Write-Verbose -Message "DB mail profile '$($ProfileName)' already exist."
            }

            Write-Verbose -Message "Configure the SQL Agent to use database mail."
            if ($sqlServerObject.JobServer.AgentMailType -ne 'DatabaseMail' -or $sqlServerObject.JobServer.DatabaseMailProfile -ne $profile_name)
            {
                $sqlServerObject.JobServer.AgentMailType = 'DatabaseMail'
                $sqlServerObject.JobServer.DatabaseMailProfile = $ProfileName
                $sqlServerObject.JobServer.Alter()
            }

        }
        else
        {
            throw 'Database Mail XPs are not enabled.'
        }
    }
}

<#
    .SYNOPSIS
        Determines if the database mail is in the desired state.

    .PARAMETER Ensure
        Specifies the desired state of the database mail.
        When set to 'Present', the database mail will be created.
        When set to 'Absent', the database mail will be removed.
        Default value is 'Present'.

    .PARAMETER ServerName
        The hostname of the SQL Server to be configured.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER AccountName
        The name of the database mail account.

    .PARAMETER EmailAddress
        The e-mail address from which mail will originate.

    .PARAMETER MailServerName
        The fully qualified domain name of the mail server name to which e-mail are
        sent.

    .PARAMETER ProfileName
        The profile name of the database mail.

    .PARAMETER DisplayName
        The display name of the database mail. Default value is the same value
        assigned to parameter AccountName.

    .PARAMETER ReplyToAddress
        The e-mail address to which the receiver of e-mails will reply to.
        Default value is the same e-mail address assigned to parameter EmailAddress.

    .PARAMETER Description
        The description of the database mail.

    .PARAMETER LoggingLevel
        The logging level that the database mail will use. If not specified the
        default logging level is 'Extended'. { Normal | *Extended* | Verbose }.

    .PARAMETER TcpPort
        The TCP port used for communication. Default value is port 25.
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
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [Parameter()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [System.String]
        $DisplayName = $AccountName,

        [Parameter()]
        [System.String]
        $ReplyToAddress = $EmailAddress,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        [ValidateSet('SMTP')]
        $MailServerType = 'SMTP',

        [Parameter()]
        [System.String]
        [ValidateSet('Normal','Extended','Verbose')]
        $LoggingLevel,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 25
    )

    $getTargetResourceParameters = @{
        AccountName = $AccountName
        ServerName = $ServerName
        EmailAddress = $EmailAddress
        MailServerName = $MailServerName
        ProfileName = $ProfileName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    return ($getTargetResourceResult.AccountName -eq $AccountName) -and
    ($getTargetResourceResult.ServerName -eq $ServerName) -and
    ($getTargetResourceResult.EmailAddress -eq $email_address) -and
    ($getTargetResourceResult.MailServerName -eq $MailServerName) -and
    ($getTargetResourceResult.ProfileName -eq $ProfileName) -and
    ($getTargetResourceResult.ReplyToAddress -eq $ReplyToAddress) -and
    ($getTargetResourceResult.MailServerType -eq $MailServerType) -and
    ($getTargetResourceResult.TcpPort -eq $TcpPort)

}

Export-ModuleMember -Function *-TargetResource
