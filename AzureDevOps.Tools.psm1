#Requires -PSEdition Core
#Requires -Version 7.0

<#
.SYNOPSIS
    AzureDevOps.Tools PowerShell Module
.DESCRIPTION
    A PowerShell module providing utilities and automation tools for Azure DevOps
.NOTES
    Author: The Cloud Explorers
    Version: 0.1.0
#>

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
