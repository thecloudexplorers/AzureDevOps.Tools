#Requires -Version 7.0
# Az.Accounts requirement handled conditionally below

<#
.SYNOPSIS
    AzureDevOps.Tools PowerShell Module
.DESCRIPTION
    A PowerShell module providing utilities and automation tools for Azure DevOps
.NOTES
    Author: The Cloud Explorers
    Version: 0.1.0
#>

# Check for Az.Accounts availability (required for production use)
$isCI = $env:CI -eq 'true' -or $env:GITHUB_ACTIONS -eq 'true'
if (-not $isCI) {
    try {
        Import-Module Az.Accounts -ErrorAction Stop
    }
    catch {
        Write-Warning "Az.Accounts module is required for production use. Install it with: Install-Module Az.Accounts"
        Write-Warning "Continuing in test mode without Azure authentication capabilities."
    }
}

# Get public and private function definition files
$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$PrivateFunctions = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($Function in @($PublicFunctions + $PrivateFunctions)) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Function.FullName): $_"
    }
}

# Export only the public functions
Export-ModuleMember -Function $PublicFunctions.BaseName