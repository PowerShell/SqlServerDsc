<#
    .SYNOPSIS
        Ensure the correct module stubs are loaded.

    .PARAMETER SQLVersion
        The major version of the SQL instance.

    .PARAMETER ModuleName
        The name of the module to load the stubs for. Default is 'SQLServer'.
#>
function Import-SQLModuleStub
{
    [CmdletBinding(DefaultParameterSetName = 'Module')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [UInt32]
        $SQLVersion,

        [Parameter(Mandatory = $false, ParameterSetName = 'Module')]
        [ValidateSet('SQLPS','SQLServer')]
        [String]
        $ModuleName = 'SQLServer'
    )

    # Translate the module names to their appropriate stub name
    $modulesAndStubs = @{
        SQLPS = 'SQLPSStub'
        SQLServer = 'SQLServerStub'
    }

    # Determine which module to ensure is loaded based on the parameters passed
    if ( $PsCmdlet.ParameterSetName -eq 'Version' )
    {
        if ( $SQLVersion -le 12 )
        {
            $ModuleName = 'SQLPS'
        }
        elseif ( $SQLVersion -ge 13 )
        {
            $ModuleName = 'SQLServer'
        }
    }

    # Get the stub name
    $stubModuleName = $modulesAndStubs.$ModuleName

    # Ensure none of the other stub modules are loaded
    [array]$otherStubModules = $modulesAndStubs.Values | Where-Object -FilterScript { $_ -ne $stubModuleName }

    $otherStubModules | Foreach-Object -Process {
        if ( Get-Module -Name $_ )
        {
            Remove-Module -Name $_
        }
    }

    # If the desired module is not loaded, load it now
    if ( -not ( Get-Module -Name $stubModuleName ) )
    {
        # Build the path to the module stub
        $moduleStubPath = Join-Path -Path ( Join-Path -Path ( Join-Path -Path ( Split-Path -Path $PSScriptRoot -Parent ) -ChildPath Unit ) -ChildPath Stubs ) -ChildPath "$($stubModuleName).psm1"

        Import-Module -Name $moduleStubPath -Force -Global
    }
}
