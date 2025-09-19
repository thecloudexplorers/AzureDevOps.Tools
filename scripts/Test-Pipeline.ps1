#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Local validation script to test CI/CD pipeline components
    
.DESCRIPTION
    This script performs the same validation checks that will run in the CI/CD pipeline,
    allowing developers to test locally before pushing changes.
    
.EXAMPLE
    ./scripts/Test-Pipeline.ps1
    
.NOTES
    This script mimics the validation performed by GitHub Actions workflows
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Skip tests that require external dependencies")]
    [switch]$SkipDependencyTests
)

Write-Host "🔍 Running local CI/CD pipeline validation..." -ForegroundColor Cyan

# Test 1: Module Manifest Validation
Write-Host "`n=== Module Manifest Validation ===" -ForegroundColor Yellow

try {
    $manifest = Test-ModuleManifest -Path './AzureDevOps.Tools.psd1'
    Write-Host "✅ Module manifest is valid: $($manifest.Name) v$($manifest.Version)" -ForegroundColor Green
    
    # Check required fields for PowerShell Gallery
    if (-not $manifest.Description) {
        throw "Module manifest missing Description"
    }
    
    if (-not $manifest.Author) {
        throw "Module manifest missing Author"
    }
    
    Write-Host "✅ PowerShell Gallery required fields present" -ForegroundColor Green
} catch {
    Write-Host "❌ Module manifest validation failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Required Files Check
Write-Host "`n=== Required Files Check ===" -ForegroundColor Yellow

$requiredFiles = @(
    'AzureDevOps.Tools.psd1',
    'AzureDevOps.Tools.psm1', 
    'LICENSE',
    'README.md'
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file (missing)" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing required files: $($missingFiles -join ', ')" -ForegroundColor Red
    exit 1
}

# Test 3: Module Import Test
Write-Host "`n=== Module Import Test ===" -ForegroundColor Yellow

if (-not $SkipDependencyTests) {
    try {
        Import-Module './AzureDevOps.Tools.psd1' -Force
        $commands = Get-Command -Module AzureDevOps.Tools
        Write-Host "✅ Module imported successfully" -ForegroundColor Green
        Write-Host "   Exported commands: $($commands.Name -join ', ')" -ForegroundColor Gray
        Remove-Module AzureDevOps.Tools -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "❌ Module import failed: $_" -ForegroundColor Red
        if ($_.Exception.Message -like "*Az.Accounts*") {
            Write-Host "💡 Install Az.Accounts module: Install-Module Az.Accounts" -ForegroundColor Yellow
        }
        exit 1
    }
} else {
    Write-Host "⏭️ Skipping module import test (requires dependencies)" -ForegroundColor Yellow
}

# Test 4: GitHub Actions Workflow Syntax
Write-Host "`n=== GitHub Actions Workflow Validation ===" -ForegroundColor Yellow

$workflowFiles = Get-ChildItem -Path '.github/workflows' -Filter '*.yml' -ErrorAction SilentlyContinue

if ($workflowFiles.Count -eq 0) {
    Write-Host "❌ No workflow files found in .github/workflows" -ForegroundColor Red
    exit 1
}

foreach ($workflow in $workflowFiles) {
    Write-Host "✅ $($workflow.Name)" -ForegroundColor Green
}

Write-Host "📝 Note: YAML syntax validation requires GitHub CLI or external tools" -ForegroundColor Gray

# Test 5: Documentation Check
Write-Host "`n=== Documentation Check ===" -ForegroundColor Yellow

$docFiles = @(
    @{ Path = 'README.md'; Description = 'Main documentation' },
    @{ Path = 'docs/PUBLISHING.md'; Description = 'Publishing guide' }
)

foreach ($doc in $docFiles) {
    if (Test-Path $doc.Path) {
        $content = Get-Content $doc.Path -Raw
        if ($content.Length -gt 100) {
            Write-Host "✅ $($doc.Path) ($($doc.Description))" -ForegroundColor Green
        } else {
            Write-Host "⚠️ $($doc.Path) exists but appears incomplete" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ $($doc.Path) missing" -ForegroundColor Red
    }
}

# Test 6: .gitignore Check
Write-Host "`n=== .gitignore Validation ===" -ForegroundColor Yellow

if (Test-Path '.gitignore') {
    $gitignoreContent = Get-Content '.gitignore' -Raw
    $importantPatterns = @('TestResults.xml', '*.log', 'node_modules/', '*.nupkg')
    
    $missingPatterns = @()
    foreach ($pattern in $importantPatterns) {
        if ($gitignoreContent -notlike "*$pattern*") {
            $missingPatterns += $pattern
        }
    }
    
    if ($missingPatterns.Count -eq 0) {
        Write-Host "✅ .gitignore contains important patterns" -ForegroundColor Green
    } else {
        Write-Host "⚠️ .gitignore missing patterns: $($missingPatterns -join ', ')" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ .gitignore file missing" -ForegroundColor Red
}

# Test 7: Test Structure (if not skipping dependency tests)
if (-not $SkipDependencyTests) {
    Write-Host "`n=== Test Structure Validation ===" -ForegroundColor Yellow
    
    $testFiles = Get-ChildItem -Path 'Tests' -Filter '*.Tests.ps1' -ErrorAction SilentlyContinue
    
    if ($testFiles.Count -gt 0) {
        Write-Host "✅ Found $($testFiles.Count) test files:" -ForegroundColor Green
        foreach ($test in $testFiles) {
            Write-Host "   - $($test.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️ No test files found in Tests directory" -ForegroundColor Yellow
    }
    
    # Check if Pester configuration is present
    if (Get-Command 'New-PesterConfiguration' -ErrorAction SilentlyContinue) {
        Write-Host "✅ Pester available for testing" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Pester not available (install with: Install-Module Pester)" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n🎉 Local CI/CD pipeline validation completed!" -ForegroundColor Cyan
Write-Host "Ready for GitHub Actions workflows:" -ForegroundColor Green
Write-Host "  • CI: Tests on push/PR" -ForegroundColor Gray
Write-Host "  • PR Validation: Enhanced PR checks" -ForegroundColor Gray  
Write-Host "  • Publish: PowerShell Gallery publishing" -ForegroundColor Gray

Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Configure POWERSHELL_GALLERY_API_KEY secret" -ForegroundColor Gray
Write-Host "  2. Create 'production' environment in GitHub" -ForegroundColor Gray
Write-Host "  3. Test with a release (e.g., v0.1.1)" -ForegroundColor Gray
Write-Host "  4. Monitor Actions tab for workflow execution" -ForegroundColor Gray