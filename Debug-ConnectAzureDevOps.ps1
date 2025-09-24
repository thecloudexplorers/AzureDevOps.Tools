#Requires -Version 7.0

<#
.SYNOPSIS
    Debug script for Connect-AzureDevOps function

.DESCRIPTION
    This script provides a way to debug and test the Connect-AzureDevOps function
    with explicit parameters. Update the variables below with your test credentials.

.NOTES
    This script is for debugging purposes only. Do not commit real credentials.
#>

# Import the module
$ModulePath = Join-Path $PSScriptRoot "AzureDevOps.Tools.psd1"
Import-Module $ModulePath -Force

Write-Host "Connect-AzureDevOps Debug Session" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Debug configuration - UPDATE THESE VALUES FOR TESTING
$DebugConfig = @{
    OrganizationUri = 'https://dev.azure.com/your-org-here'
    TenantId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    ClientId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    ClientSecretPlain = 'your-client-secret-here'
    Project = 'your-project-name'  # Optional
}

Write-Host "`nCurrent debug configuration:" -ForegroundColor Yellow
Write-Host "  OrganizationUri: $($DebugConfig.OrganizationUri)"
Write-Host "  TenantId: $($DebugConfig.TenantId)"
Write-Host "  ClientId: $($DebugConfig.ClientId)"
Write-Host "  ClientSecret: $(if ($DebugConfig.ClientSecretPlain -ne 'your-client-secret-here') { '*' * 8 } else { 'NOT SET' })"
Write-Host "  Project: $($DebugConfig.Project)"

# Check if configuration is set
$IsConfigured = $DebugConfig.OrganizationUri -ne 'https://dev.azure.com/your-org-here' -and
                $DebugConfig.TenantId -ne 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -and
                $DebugConfig.ClientId -ne 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -and
                $DebugConfig.ClientSecretPlain -ne 'your-client-secret-here'

if (-not $IsConfigured) {
    Write-Host "`nConfiguration not set up for debugging." -ForegroundColor Red
    Write-Host "Please edit this script and update the `$DebugConfig hashtable with your test credentials." -ForegroundColor Yellow
    Write-Host "`nAlternatively, you can use the integration test configuration:" -ForegroundColor Yellow
    Write-Host "  .\Tests\Setup-IntegrationTestEnvironment.ps1 -Interactive" -ForegroundColor Cyan
    return
}

Write-Host "`nTesting Connect-AzureDevOps function..." -ForegroundColor Cyan

try {
    # Convert plain text secret to SecureString
    $SecureSecret = ConvertTo-SecureString $DebugConfig.ClientSecretPlain -AsPlainText -Force
    
    # Test the connection
    $Result = Connect-AzureDevOps -OrganizationUri $DebugConfig.OrganizationUri -TenantId $DebugConfig.TenantId -ClientId $DebugConfig.ClientId -ClientSecret $SecureSecret -Project $DebugConfig.Project -Verbose
    
    Write-Host "`nConnection successful!" -ForegroundColor Green
    Write-Host "Result:" -ForegroundColor Yellow
    $Result | Format-List
}
catch {
    Write-Host "`nConnection failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nFull error details:" -ForegroundColor Yellow
    $_ | Format-List * -Force
}

Write-Host "`nDebug session completed." -ForegroundColor Green