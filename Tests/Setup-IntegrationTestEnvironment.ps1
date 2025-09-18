<#
.SYNOPSIS
    Setup script for integration test environment variables

.DESCRIPTION
    This script helps you configure the required environment variables for running
    Connect-AzureDevOps integration tests. You can either set them in your PowerShell
    profile or run this script before running integration tests.

.EXAMPLE
    # Set environment variables for current session
    .\Setup-IntegrationTestEnvironment.ps1

.EXAMPLE
    # Add to your PowerShell profile for persistent settings
    # Edit: $PROFILE (or $PROFILE.AllUsersAllHosts for all users)
    # Add the contents of this script

.NOTES
    Required environment variables for integration tests:
    - AZURE_DEVOPS_ORGANIZATION
    - tenantId
    - servicePrincipalId
    - servicePrincipalKey
    - AZURE_DEVOPS_PROJECT (optional)
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Set to true to display current environment variable values")]
    [switch]$ShowCurrentValues,

    [Parameter(HelpMessage = "Set to true to prompt for values interactively")]
    [switch]$Interactive
)

Write-Host "Azure DevOps Integration Test Environment Setup" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

if ($ShowCurrentValues) {
    Write-Host "`nCurrent Environment Variables:" -ForegroundColor Yellow

    $EnvVars = @{
        'AZURE_DEVOPS_ORGANIZATION' = $env:AZURE_DEVOPS_ORGANIZATION
        'AZURE_DEVOPS_PROJECT' = $env:AZURE_DEVOPS_PROJECT
        'tenantId' = $env:tenantId
        'servicePrincipalId' = $env:servicePrincipalId
        'servicePrincipalKey' = if ($env:servicePrincipalKey) { '*' * 8 } else { $null }
    }

    foreach ($var in $EnvVars.GetEnumerator()) {
        $value = if ($var.Value) { $var.Value } else { "(not set)" }
        Write-Host "  $($var.Key): $value" -ForegroundColor Cyan
    }
    return
}

if ($Interactive) {
    Write-Host "`nInteractive Setup:" -ForegroundColor Yellow
    Write-Host "Please provide the following values (press Enter to skip):`n"

    $org = Read-Host "Azure DevOps Organization URI (https://dev.azure.com/yourorg)"
    if ($org) { $env:AZURE_DEVOPS_ORGANIZATION = $org }

    $project = Read-Host "Azure DevOps Project Name (optional)"
    if ($project) { $env:AZURE_DEVOPS_PROJECT = $project }

    $tenantId = Read-Host "Azure Tenant ID (GUID)"
    if ($tenantId) { $env:tenantId = $tenantId }

    $clientId = Read-Host "Service Principal Client ID (GUID)"
    if ($clientId) { $env:servicePrincipalId = $clientId }

    $clientSecret = Read-Host "Service Principal Client Secret" -AsSecureString
    if ($clientSecret -and $clientSecret.Length -gt 0) {
        $env:servicePrincipalKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret))
    }

    $subscriptionId = Read-Host "Azure Subscription ID (GUID)"
    if ($subscriptionId) { $env:ARM_SUBSCRIPTION_ID = $subscriptionId }

    Write-Host "`nEnvironment variables set for current session." -ForegroundColor Green
    return
}

# Example/Template values - REPLACE WITH YOUR ACTUAL VALUES
Write-Host "`nTo set up integration test environment, configure these variables:" -ForegroundColor Yellow

Write-Host @"

# Azure DevOps Environment Variables
`$env:AZURE_DEVOPS_ORGANIZATION = 'https://dev.azure.com/yourorg'
`$env:AZURE_DEVOPS_PROJECT = 'YourProject'                    # Optional
`$env:tenantId = 'your-tenant-id-guid'
`$env:servicePrincipalId = 'your-client-id-guid'
`$env:servicePrincipalKey = 'your-client-secret'
`$env:ARM_SUBSCRIPTION_ID = 'your-subscription-id-guid'

"@ -ForegroundColor Cyan

Write-Host "How to use:" -ForegroundColor Yellow
Write-Host "1. Copy the variables above to your PowerShell profile: " -NoNewline
Write-Host "`$PROFILE" -ForegroundColor Cyan
Write-Host "2. Or run: " -NoNewline
Write-Host ".\Setup-IntegrationTestEnvironment.ps1 -Interactive" -ForegroundColor Cyan
Write-Host "3. Or set them manually in your current session"
Write-Host "4. Then run: " -NoNewline
Write-Host "Invoke-Pester ./Tests/Connect-AzureDevOps.Integration.Tests.ps1" -ForegroundColor Cyan

Write-Host "`nTo check current values: " -NoNewline
Write-Host ".\Setup-IntegrationTestEnvironment.ps1 -ShowCurrentValues" -ForegroundColor Cyan

Write-Host "`nNote: Keep your client secrets secure and never commit them to source control!" -ForegroundColor Red
