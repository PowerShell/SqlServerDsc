<#
    .SYNOPSIS
        Ensure the correct module stubs are loaded.

    .PARAMETER SQLVersion
        The major version of the SQL instance.

    .PARAMETER ModuleName
        The name of the module to load the stubs for. Default is 'SqlServer'.
#>
function Import-SQLModuleStub
{
    [CmdletBinding(DefaultParameterSetName = 'Module')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [System.UInt32]
        $SQLVersion,

        [Parameter(ParameterSetName = 'Module')]
        [ValidateSet('SQLPS','SqlServer')]
        [System.String]
        $ModuleName = 'SqlServer'
    )

    # Translate the module names to their appropriate stub name
    $modulesAndStubs = @{
        SQLPS = 'SQLPSStub'
        SqlServer = 'SqlServerStub'
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
            $ModuleName = 'SqlServer'
        }
    }

    # Get the stub name
    $stubModuleName = $modulesAndStubs.$ModuleName

    # Ensure none of the other stub modules are loaded
    [System.Array] $otherStubModules = $modulesAndStubs.Values | Where-Object -FilterScript {
        $_ -ne $stubModuleName
    }

    if ( Get-Module -Name $otherStubModules )
    {
        Remove-Module -Name $otherStubModules
    }

    # If the desired module is not loaded, load it now
    if ( -not ( Get-Module -Name $stubModuleName ) )
    {
        # Build the path to the module stub
        $moduleStubPath = Join-Path -Path ( Join-Path -Path ( Join-Path -Path ( Split-Path -Path $PSScriptRoot -Parent ) -ChildPath Unit ) -ChildPath Stubs ) -ChildPath "$($stubModuleName).psm1"

        Import-Module -Name $moduleStubPath -Force -Global
    }
}
