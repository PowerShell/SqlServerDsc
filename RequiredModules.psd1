@{
    PSDependOptions             = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = ''
        }
    }

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    Pester                      = '4.10.1'
    Plaster                     = 'latest'
    ModuleBuilder               = 'latest'
    ChangelogManagement         = 'latest'
    Sampler                     = 'latest'
    MarkdownLinkCheck           = 'latest'
    'DscResource.Test'          = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    xDscResourceDesigner        = 'latest'
    'DscResource.DocGenerator'  = 'latest'
    'DscResource.Common'        = 'latest'

    # Dependency for integration tests
    LoopbackAdapter             = 'latest'
    PSPKI                       = 'latest'

    # Prerequisites modules needed for examples or integration tests
    PSDscResources              = '2.12.0.0'
    StorageDsc                  = '4.9.0.0'
    NetworkingDsc               = '7.4.0.0'
}

