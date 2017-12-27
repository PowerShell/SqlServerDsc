Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') `
    -Force

<#
    .SYNOPSIS
        Returns the current state of the database mail configuration.

    .PARAMETER ServerName
        The hostname of the SQL Server to be configured.
        Defaults to $env:COMPUTERNAME.

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
        $ServerName = $env:COMPUTERNAME,

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
        LoggingLevel   = $null
        ProfileName    = $null
        DisplayName    = $null
        ReplyToAddress = $null
        Description    = $null
        TcpPort        = $null
    }

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        if ($sqlServerObject.Configuration.DatabaseMailEnabled.RunValue -eq 1)
        {
            $databaseMail = $sqlServerObject.Mail

            $databaseMailAccount = $databaseMail.Accounts | Where-Object -FilterScript {
                $_.Name -eq $AccountName
            }

            if ($databaseMailAccount)
            {
                $loggingLevelText = switch ($databaseMail.ConfigurationValues['LoggingLevel'].Value)
                {
                    1
                    {
                        'Normal'
                    }

                    2
                    {
                        'Extended'
                    }

                    3
                    {
                        'Verbose'
                    }
                }

                <#
                    AccountName exist so we set this as 'Present' regardless if
                    other properties are in desired state, the Test-TargetResource
                    function must handle that.
                #>
                $returnValue['Ensure'] = 'Present'
                $returnValue['LoggingLevel'] = $loggingLevelText
                $returnValue['AccountName'] = $databaseMailAccount.Name
                $returnValue['EmailAddress'] = $databaseMailAccount.EmailAddress
                $returnValue['DisplayName'] = $databaseMailAccount.DisplayName
                $returnValue['ReplyToAddress'] = $databaseMailAccount.ReplyToAddress

                # Currently only the first mail server is handled.
                $mailServer = $databaseMailAccount.MailServers | Select-Object -First 1

                $returnValue['MailServerName'] = $mailServer.Name
                $returnValue['TcpPort'] = $mailServer.Port

                # Currently only one profile is handled, so this make sure only the first string (profile name) is returned.
                $returnValue['ProfileName'] = $databaseMail.Profiles | Select -First 1 -ExpandProperty Name

                # SQL Server returns '' for Description property when value is not set.
                if ($databaseMailAccount.Description -eq '')
                {
                    # Convert empty value to $null
                    $returnValue['Description'] = $null
                }
                else
                {
                    $returnValue['Description'] = $databaseMailAccount.Description
                }
            }
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
        Defaults to $env:COMPUTERNAME.

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
        The display name of the outgoing mail server. Default value is the same
        value assigned to parameter MailServerName.

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
        $ServerName = $env:COMPUTERNAME,

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
        $DisplayName = $MailServerName,

        [Parameter()]
        [System.String]
        $ReplyToAddress = $EmailAddress,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        [ValidateSet('Normal', 'Extended', 'Verbose')]
        $LoggingLevel,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 25
    )

    $sqlServerObject = Connect-SQL -SQLServer $ServerName -SQLInstanceName $InstanceName

    if ($sqlServerObject)
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message "Configure the SQL Server to enable Database Mail."

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

                    $currentLoggingLevelValue = $databaseMail.ConfigurationValues['LoggingLevel'].Value
                    if ($loggingLevelValue -ne $currentLoggingLevelValue)
                    {
                        Write-Verbose -Message ('Changing Database Mail logging level to ''{0}''' -f $LoggingLevel)

                        $databaseMail.ConfigurationValues['LoggingLevel'].Value = $loggingLevelValue
                        $databaseMail.ConfigurationValues['LoggingLevel'].Alter()
                    }
                    else
                    {
                        $loggingLevelValue = $databaseMail.ConfigurationValues['LoggingLevel'].Value
                        Write-Verbose -Message "Database Mail logging level is '$($loggingLevelValue)'"
                    }
                }

                $databaseMailAccount = $databaseMail.Accounts | Where-Object -FilterScript {
                    $_.Name -eq $AccountName
                }

                if (-not $databaseMailAccount)
                {
                    Write-Verbose -Message "Create the mail account '$($AccountName)'"

                    $databaseMailAccount = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Mail.MailAccount -ArgumentList @($databaseMail, $AccountName)
                    $databaseMailAccount.Description = $Description
                    $databaseMailAccount.DisplayName = $DisplayName
                    $databaseMailAccount.EmailAddress = $EmailAddress
                    $databaseMailAccount.ReplyToAddress = $ReplyToAddress
                    $databaseMailAccount.Create()

                    # The previous Create() method will always create a first mail server.
                    $mailServer = $databaseMailAccount.MailServers | Select-Object -First 1

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
                    Write-Verbose -Message "Database Mail mail account '$($AccountName)' already exist."

                    $currentDisplayName = $databaseMailAccount.DisplayName
                    if ($currentDisplayName -ne $DisplayName)
                    {
                        Write-Verbose -Message ('Updating display name of outgoing mail server. Current value is {0}, expected {1}.' -f $currentDisplayName, $DisplayName)
                        $databaseMailAccount.DisplayName = $DisplayName
                        $databaseMailAccount.Alter()
                    }

                    $currentDescription = $databaseMailAccount.Description
                    if ($currentDescription -ne $Description)
                    {
                        Write-Verbose -Message ('Updating description of outgoing mail server. Current value is {0}, expected {1}.' -f $currentDescription, $Description)
                        $databaseMailAccount.Description = $Description
                        $databaseMailAccount.Alter()
                    }

                    $currentEmailAddress = $databaseMailAccount.EmailAddress
                    if ($currentEmailAddress -ne $EmailAddress)
                    {
                        Write-Verbose -Message ('Updating e-mail address of outgoing mail server. Current value is {0}, expected {1}.' -f $currentEmailAddress, $EmailAddress)
                        $databaseMailAccount.EmailAddress = $EmailAddress
                        $databaseMailAccount.Alter()
                    }

                    $currentReplyToAddress = $databaseMailAccount.ReplyToAddress
                    if ($currentReplyToAddress -ne $ReplyToAddress)
                    {
                        Write-Verbose -Message ('Updating reply to e-mail address of outgoing mail server. Current value is {0}, expected {1}.' -f $currentReplyToAddress, $ReplyToAddress)
                        $databaseMailAccount.ReplyToAddress = $ReplyToAddress
                        $databaseMailAccount.Alter()
                    }

                    $mailServer = $databaseMailAccount.MailServers | Select-Object -First 1

                    $currentMailServerName = $mailServer.Name
                    if ($currentMailServerName -ne $MailServerName)
                    {
                        Write-Verbose -Message ('Updating server name of outgoing mail server. Current value is {0}, expected {1}.' -f $currentMailServerName, $MailServerName)
                        $mailServer.Rename($MailServerName)
                        $mailServer.Alter()
                    }

                    $currentTcpPort = $mailServer.Port
                    if ($currentTcpPort -ne $TcpPort)
                    {
                        Write-Verbose -Message ('Updating reply to tcp port of outgoing mail server. Current value is {0}, expected {1}.' -f $currentTcpPort, $TcpPort)
                        $mailServer.Port = $TcpPort
                        $mailServer.Alter()
                    }
                }

                $databaseMailProfile = $databaseMail.Profiles | Where-Object -FilterScript {
                    $_.Name -eq $ProfileName
                }

                if (-not $databaseMailProfile)
                {
                    Write-Verbose -Message "Create a public default profile '$($ProfileName)'"

                    $databaseMailProfile = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Mail.MailProfile -ArgumentList @($databaseMail, $ProfileName)
                    $databaseMailProfile.Description = $Description
                    $databaseMailProfile.Create()

                    <#
                        A principal refers to a database user, a database role or
                        server role, an application role, or a SQL Server login.
                        You can add these types of users to the mail profile.
                        https://msdn.microsoft.com/en-us/library/ms208094.aspx
                    #>
                    $databaseMailProfile.AddPrincipal('public', $true)
                    $databaseMailProfile.AddAccount($AccountName, 0) # Sequence number zero (0).
                    $databaseMailProfile.Alter()
                }
                else
                {
                    Write-Verbose -Message "DB mail profile '$($ProfileName)' already exist."
                }

                Write-Verbose -Message 'Configure the SQL Agent to use database mail.'
                if ($sqlServerObject.JobServer.AgentMailType -ne 'DatabaseMail' -or $sqlServerObject.JobServer.DatabaseMailProfile -ne $ProfileName)
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
        else
        {
            # Absent
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
        Defaults to $env:COMPUTERNAME.

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
        The display name of the outgoing mail server. Default value is the same
        value assigned to parameter MailServerName.

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
        $ServerName = $env:COMPUTERNAME,

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
        $DisplayName = $MailServerName,

        [Parameter()]
        [System.String]
        $ReplyToAddress = $EmailAddress,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        [ValidateSet('Normal', 'Extended', 'Verbose')]
        $LoggingLevel,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 25
    )

    $getTargetResourceParameters = @{
        ServerName     = $ServerName
        InstanceName   = $InstanceName
        AccountName    = $AccountName
        EmailAddress   = $EmailAddress
        MailServerName = $MailServerName
        ProfileName    = $ProfileName
    }

    $returnValue = $false

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    if ($Ensure -eq 'Present')
    {
        $returnValue = Test-SQLDscParameterState `
            -CurrentValues $getTargetResourceResult `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @(
            'AccountName'
            'EmailAddress'
            'MailServerName'
            'ProfileName'
            'Ensure'
            'ReplyToAddress'
            'TcpPort'
            'DisplayName'
            'Description'
            'LoggingLevel'
        )
    }
    else
    {
        if ($Ensure -eq $getTargetResourceResult.Ensure)
        {
            $returnValue = $true
        }
    }

    return $returnValue
}
