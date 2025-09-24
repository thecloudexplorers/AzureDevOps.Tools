<#
.SYNOPSIS
    Setup script for integration test configuration

.DESCRIPTION
    This script helps you configure the required test data for running
    Connect-AzureDevOps integration tests. It creates an IntegrationTestConfig.psd1 file
    with your Azure DevOps and service principal credentials.

.EXAMPLE
    # Create integration test configuration interactively
    .\Setup-IntegrationTestEnvironment.ps1 -Interactive

.EXAMPLE
    # Show current configuration status
    .\Setup-IntegrationTestEnvironment.ps1 -ShowCurrentConfig

.NOTES
    Required configuration for integration tests:
    - OrganizationUri: Your Azure DevOps organization URI
    - TenantId: Azure AD tenant ID
    - ClientId: Service principal client ID
    - ClientSecretPlain: Service principal client secret
    - Project: (Optional) Default project name
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Set to true to display current configuration values")]
    [switch]$ShowCurrentConfig,

    [Parameter(HelpMessage = "Set to true to create configuration interactively")]
    [switch]$Interactive
)

Write-Host "Azure DevOps Integration Test Configuration Setup" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

$ConfigPath = Join-Path $PSScriptRoot "IntegrationTestConfig.psd1"
$ExampleConfigPath = Join-Path $PSScriptRoot "IntegrationTestConfig.example.psd1"

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
Write-Host "`nTo set up integration tests, you need to create a configuration file with your Azure credentials."
Write-Host "`nAvailable options:"
Write-Host "1. Run interactively: " -NoNewline
Write-Host ".\Setup-IntegrationTestEnvironment.ps1 -Interactive" -ForegroundColor Cyan
Write-Host "2. Copy example file: " -NoNewline
Write-Host "Copy-Item $ExampleConfigPath $ConfigPath" -ForegroundColor Cyan
Write-Host "   Then edit: " -NoNewline
Write-Host "$ConfigPath" -ForegroundColor Cyan
Write-Host "3. Check current config: " -NoNewline
Write-Host ".\Setup-IntegrationTestEnvironment.ps1 -ShowCurrentConfig" -ForegroundColor Cyan

Write-Host "`nAfter configuration, run tests with: " -NoNewline
Write-Host "Invoke-Pester ./Tests/Connect-AzureDevOps.Integration.Tests.ps1" -ForegroundColor Cyan

Write-Host "`nNote: Keep your credentials secure and never commit IntegrationTestConfig.psd1 to source control!" -ForegroundColor Red