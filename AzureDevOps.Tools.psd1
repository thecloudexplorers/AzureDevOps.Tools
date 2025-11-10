@{
    # Script module or binary module file associated with this manifest
    RootModule        = 'AzureDevOps.Tools.psm1'

    # Version number of this module
    ModuleVersion     = '0.3.0'

    # ID used to uniquely identify this module
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author            = 'The Cloud Explorers'

    # Company or vendor of this module
    CompanyName       = 'The Cloud Explorers'

    # Copyright statement for this module
    Copyright         = '(c) 2025 The Cloud Explorers. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'A PowerShell module providing utilities and automation tools for Azure DevOps'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @()

    # Functions to export from this module
    FunctionsToExport = @('Connect-AzureDevOps', 'Import-JsonAsEnvironmentVariable')

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData       = @{
        PSData = @{

            # Prerelease version of this module
            Prerelease = 'alpha'

            # Tags applied to this module
            Tags       = @('Azure', 'DevOps', 'Automation', 'CI/CD', 'Pipeline')

            # A URL to the license for this module
            LicenseUri = 'https://github.com/thecloudexplorers/AzureDevOps.Tools/blob/main/LICENSE'

            # A URL to the main website for this project
            ProjectUri = 'https://github.com/thecloudexplorers/AzureDevOps.Tools'
        }
    }
}
