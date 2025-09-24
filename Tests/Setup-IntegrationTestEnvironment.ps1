<#
.SYNOPSIS
    Setup script for integration test configuration

.DESCRIPTION
    This script helps you configure the required test data for running
    Connect-AzureDevOps integration tests. It creates an IntegrationTestConfig.psd1 file
    with your Azure DevOps and service principal credentials, or helps set environment
    variables for use with Pester configuration.

.EXAMPLE
    # Create integration test configuration interactively
    .\Setup-IntegrationTestEnvironment.ps1 -Interactive

.EXAMPLE
    # Show current configuration status
    .\Setup-IntegrationTestEnvironment.ps1 -ShowCurrentConfig

.EXAMPLE
    # Show environment variables for Pester configuration
    .\Setup-IntegrationTestEnvironment.ps1 -ShowEnvironmentVariables

.NOTES
    Two ways to configure integration tests:
    
    1. Configuration file approach:
       - OrganizationUri: Your Azure DevOps organization URI
       - TenantId: Azure AD tenant ID
       - ClientId: Service principal client ID
       - ClientSecretPlain: Service principal client secret
       - Project: (Optional) Default project name
    
    2. Environment variables approach (for Pester configuration):
       - AZURE_DEVOPS_ORGANIZATION: Your Azure DevOps organization URI
       - tenantId: Azure AD tenant ID
       - servicePrincipalId: Service principal client ID
       - servicePrincipalKey: Service principal client secret
       - AZURE_DEVOPS_PROJECT: (Optional) Default project name
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Set to true to display current configuration values")]
    [switch]$ShowCurrentConfig,

    [Parameter(HelpMessage = "Set to true to create configuration interactively")]
    [switch]$Interactive,

    [Parameter(HelpMessage = "Set to true to show environment variables for Pester configuration")]
    [switch]$ShowEnvironmentVariables
)

Write-Host "Azure DevOps Integration Test Configuration Setup" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

$ConfigPath = Join-Path $PSScriptRoot "IntegrationTestConfig.psd1"
$ExampleConfigPath = Join-Path $PSScriptRoot "IntegrationTestConfig.example.psd1"

if ($ShowEnvironmentVariables) {
    Write-Host "`nEnvironment Variables for Pester Configuration:" -ForegroundColor Yellow

    $EnvVars = @{
        'AZURE_DEVOPS_ORGANIZATION' = $env:AZURE_DEVOPS_ORGANIZATION
        'tenantId' = $env:tenantId
        'servicePrincipalId' = $env:servicePrincipalId
        'servicePrincipalKey' = if ($env:servicePrincipalKey) { '*' * 8 } else { $null }
        'AZURE_DEVOPS_PROJECT' = $env:AZURE_DEVOPS_PROJECT
    }

    foreach ($var in $EnvVars.GetEnumerator()) {
        $value = if ($var.Value) { $var.Value } else { "(not set)" }
        $status = if ($var.Value) { "✓" } else { "✗" }
        Write-Host "  $status $($var.Key): $value" -ForegroundColor $(if ($var.Value) { "Green" } else { "Red" })
    }

    Write-Host "`nTo run integration tests with environment variables:" -ForegroundColor Cyan
    Write-Host "`$PesterConfig = @{" -ForegroundColor Gray
    Write-Host "    OrganizationUri = `$env:AZURE_DEVOPS_ORGANIZATION" -ForegroundColor Gray
    Write-Host "    TenantId = `$env:tenantId" -ForegroundColor Gray
    Write-Host "    ClientId = `$env:servicePrincipalId" -ForegroundColor Gray
    Write-Host "    ClientSecretPlain = `$env:servicePrincipalKey" -ForegroundColor Gray
    Write-Host "    Project = `$env:AZURE_DEVOPS_PROJECT" -ForegroundColor Gray
    Write-Host "}" -ForegroundColor Gray
    Write-Host "Invoke-Pester -Path ./Tests/Connect-AzureDevOps.Integration.Tests.ps1 -Tag Integration ``" -ForegroundColor Cyan
    Write-Host "              -Configuration @{ Data = `$PesterConfig }" -ForegroundColor Cyan
    return
}

if ($ShowCurrentConfig) {
    Write-Host "`nCurrent Configuration Status:" -ForegroundColor Yellow

    if (Test-Path $ConfigPath) {
        try {
            $Config = Import-PowerShellDataFile -Path $ConfigPath
            
            $ConfigStatus = @{
                'OrganizationUri' = $Config.OrganizationUri
                'TenantId' = $Config.TenantId
                'ClientId' = $Config.ClientId
                'ClientSecretPlain' = if ($Config.ClientSecretPlain) { '*' * 8 } else { $null }
                'Project' = $Config.Project
            }

            foreach ($item in $ConfigStatus.GetEnumerator()) {
                $value = if ($item.Value) { $item.Value } else { "(not set)" }
                $status = if ($item.Value) { "✓" } else { "✗" }
                Write-Host "  $status $($item.Key): $value" -ForegroundColor $(if ($item.Value) { "Green" } else { "Red" })
            }
        }
        catch {
            Write-Host "  Error reading configuration file: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  No configuration file found at: $ConfigPath" -ForegroundColor Red
    }
    return
}

if ($Interactive) {
    Write-Host "`nInteractive Configuration Setup:" -ForegroundColor Yellow
    
    Write-Host "`nThis will create a configuration file with your Azure DevOps credentials."
    Write-Host "The file will be saved as: $ConfigPath"
    Write-Host "Make sure this file is not committed to source control!" -ForegroundColor Red
    
    $Continue = Read-Host "`nDo you want to continue? (y/N)"
    if ($Continue -notmatch '^[yY]') {
        Write-Host "Configuration setup cancelled." -ForegroundColor Yellow
        return
    }

    # Collect configuration values
    $OrgUri = Read-Host "`nEnter your Azure DevOps organization URI (e.g., https://dev.azure.com/myorg)"
    $TenantId = Read-Host "Enter your Azure AD tenant ID (GUID)"
    $ClientId = Read-Host "Enter your service principal client ID (GUID)"
    $ClientSecret = Read-Host "Enter your service principal client secret" -MaskInput
    $Project = Read-Host "Enter default project name (optional, press Enter to skip)"

    # Validate required fields
    if ([string]::IsNullOrWhiteSpace($OrgUri) -or 
        [string]::IsNullOrWhiteSpace($TenantId) -or 
        [string]::IsNullOrWhiteSpace($ClientId) -or 
        [string]::IsNullOrWhiteSpace($ClientSecret)) {
        Write-Host "`nError: All required fields must be provided." -ForegroundColor Red
        return
    }

    # Create configuration hashtable
    $ConfigContent = @"
@{
    # Integration test configuration for Connect-AzureDevOps
    # DO NOT commit this file to source control!
    
    # Your Azure DevOps organization URI
    OrganizationUri = '$OrgUri'
    
    # Azure AD tenant ID where your service principal is registered
    TenantId = '$TenantId'
    
    # Service principal (application) client ID
    ClientId = '$ClientId'
    
    # Service principal client secret (plain text - will be converted to SecureString)
    ClientSecretPlain = '$ClientSecret'
    
    # Optional: Default project name for scoped operations
    Project = '$Project'
}
"@

    try {
        $ConfigContent | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-Host "`nConfiguration saved successfully to: $ConfigPath" -ForegroundColor Green
        Write-Host "You can now run integration tests with: Invoke-Pester ./Tests/Connect-AzureDevOps.Integration.Tests.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "`nError saving configuration: $_" -ForegroundColor Red
    }
    return
}

# Default behavior - show instructions
Write-Host "`nTo set up integration tests, choose one of these approaches:"

Write-Host "`nOption 1 - Configuration File Approach:"
Write-Host "1. Run interactively: " -NoNewline
Write-Host ".\Setup-IntegrationTestEnvironment.ps1 -Interactive" -ForegroundColor Cyan
Write-Host "2. Copy example file: " -NoNewline
Write-Host "Copy-Item $ExampleConfigPath $ConfigPath" -ForegroundColor Cyan
Write-Host "   Then edit: " -NoNewline
Write-Host "$ConfigPath" -ForegroundColor Cyan
Write-Host "3. Check current config: " -NoNewline
Write-Host ".\Setup-IntegrationTestEnvironment.ps1 -ShowCurrentConfig" -ForegroundColor Cyan

Write-Host "`nOption 2 - Environment Variables Approach (Pester Configuration):"
Write-Host "1. Set environment variables in your session" -ForegroundColor Cyan
Write-Host "2. Check variables: " -NoNewline
Write-Host ".\Setup-IntegrationTestEnvironment.ps1 -ShowEnvironmentVariables" -ForegroundColor Cyan
Write-Host "3. Run tests with Pester configuration (see -ShowEnvironmentVariables for details)" -ForegroundColor Cyan

Write-Host "`nAfter configuration, run tests with: " -NoNewline
Write-Host "Invoke-Pester ./Tests/Connect-AzureDevOps.Integration.Tests.ps1" -ForegroundColor Cyan

Write-Host "`nNote: Keep your credentials secure and never commit IntegrationTestConfig.psd1 to source control!" -ForegroundColor Red