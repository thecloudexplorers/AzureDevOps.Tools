#Requires -Module Pester

<#
.SYNOPSIS
    Integration tests for Connect-AzureDevOps function with real Azure authentication

.DESCRIPTION
    These tests require actual Azure credentials to be provided via Pester configuration.
    Configuration should be provided when invoking Pester with environment variables.

.EXAMPLE
    # Run integration tests with environment variables
    $env:AZURE_DEVOPS_ORGANIZATION = 'https://dev.azure.com/your-org'
    $env:tenantId = 'your-tenant-id-guid'
    $env:servicePrincipalId = 'your-client-id-guid'
    $env:servicePrincipalKey = 'your-client-secret'
    $env:AZURE_DEVOPS_PROJECT = 'your-project' # Optional
    
    $PesterConfig = @{
        OrganizationUri = $env:AZURE_DEVOPS_ORGANIZATION
        TenantId = $env:tenantId
        ClientId = $env:servicePrincipalId
        ClientSecretPlain = $env:servicePrincipalKey
        Project = $env:AZURE_DEVOPS_PROJECT
    }
    
    Invoke-Pester -Path ./Tests/Connect-AzureDevOps.Integration.Tests.ps1 -Tag Integration -Configuration @{ Data = $PesterConfig }

.NOTES
    Run these tests only when you have valid Azure credentials configured.
    These tests will attempt real Azure authentication.
#>

Describe "Connect-AzureDevOps Integration Tests" -Tag "Integration" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot ".." "AzureDevOps.Tools.psd1"
        Import-Module $ModulePath -Force
        
        # Get integration test configuration from Pester Data or environment variables
        $script:IntegrationTestData = @{}
        
        # Check if configuration was provided via Pester Data parameter
        if ($PesterPreference.Data -and $PesterPreference.Data.GetType() -eq [hashtable]) {
            $script:IntegrationTestData = $PesterPreference.Data
            Write-Host "Using integration test configuration from Pester Data parameter" -ForegroundColor Green
        }
        # Fallback to environment variables if no Pester Data provided
        else {
            $script:IntegrationTestData = @{
                OrganizationUri = $env:AZURE_DEVOPS_ORGANIZATION
                TenantId = $env:tenantId
                ClientId = $env:servicePrincipalId
                ClientSecretPlain = $env:servicePrincipalKey
                Project = $env:AZURE_DEVOPS_PROJECT
            }
            
            if ($env:AZURE_DEVOPS_ORGANIZATION -or $env:tenantId -or $env:servicePrincipalId -or $env:servicePrincipalKey) {
                Write-Host "Using integration test configuration from environment variables" -ForegroundColor Green
            }
        }

        # Check if required credentials are available
        $RequiredFields = @()
        $HasOrgUri = (-not [string]::IsNullOrEmpty($script:IntegrationTestData.OrganizationUri))
        $HasTenantId = (-not [string]::IsNullOrEmpty($script:IntegrationTestData.TenantId))
        $HasClientId = (-not [string]::IsNullOrEmpty($script:IntegrationTestData.ClientId))
        $HasClientSecret = (-not [string]::IsNullOrEmpty($script:IntegrationTestData.ClientSecretPlain))

        if (-not $HasOrgUri) { $RequiredFields += "OrganizationUri" }
        if (-not $HasTenantId) { $RequiredFields += "TenantId" }
        if (-not $HasClientId) { $RequiredFields += "ClientId" }
        if (-not $HasClientSecret) { $RequiredFields += "ClientSecretPlain" }

        $script:SkipIntegrationTests = $RequiredFields.Count -gt 0

        if ($script:SkipIntegrationTests) {
            Write-Host "Skipping integration tests. Missing configuration fields: $($RequiredFields -join ', ')" -ForegroundColor Yellow
            Write-Host "To run integration tests:" -ForegroundColor Yellow
            Write-Host "1. Set environment variables (AZURE_DEVOPS_ORGANIZATION, tenantId, servicePrincipalId, servicePrincipalKey)" -ForegroundColor Cyan
            Write-Host "2. Or provide configuration via Pester Data parameter" -ForegroundColor Cyan
        }
        else {
            Write-Host "Integration test configuration is ready!" -ForegroundColor Green
            $script:TestSecureSecret = ConvertTo-SecureString $script:IntegrationTestData.ClientSecretPlain -AsPlainText -Force
        }
    }

    AfterAll {
        Remove-Module AzureDevOps.Tools -Force -ErrorAction SilentlyContinue
    }

    Context "Real Azure Authentication" {

        It "Should successfully connect using explicit parameters" -Skip:$script:SkipIntegrationTests {
            if ($script:SkipIntegrationTests) { return }
            
            $Result = Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $script:TestSecureSecret

            $Result | Should -Not -BeNullOrEmpty
            $Result.Status | Should -Match 'Connected.*'
            $Result.OrganizationUri | Should -Be $script:IntegrationTestData.OrganizationUri.TrimEnd('/')
            $Result.TenantId | Should -Be $script:IntegrationTestData.TenantId
            $Result.ClientId | Should -Be $script:IntegrationTestData.ClientId
            $Result.ConnectedAt | Should -BeOfType [DateTime]
            $Result.ParameterSource | Should -Not -BeNullOrEmpty
            # All parameters should be marked as coming from Parameter source
            $Result.ParameterSource.OrganizationUri | Should -Be 'Parameter'
            $Result.ParameterSource.TenantId | Should -Be 'Parameter'
            $Result.ParameterSource.ClientId | Should -Be 'Parameter'
            $Result.ParameterSource.ClientSecret | Should -Be 'Parameter'
        }

        It "Should store connection information in script scope" -Skip:$script:SkipIntegrationTests {
            if ($script:SkipIntegrationTests) { return }
            
            Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $script:TestSecureSecret | Out-Null

            # The connection should be stored in script scope (we can't directly test this without exposing it)
            # But we can test that subsequent connections reuse the existing connection
            $FirstConnection = Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $script:TestSecureSecret
            $FirstConnection.Status | Should -Match 'Connected.*'
        }

        It "Should force re-authentication when -Force is specified" -Skip:$script:SkipIntegrationTests {
            if ($script:SkipIntegrationTests) { return }
            
            # Establish initial connection
            $InitialConnection = Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $script:TestSecureSecret

            # Force a new connection
            $ForcedConnection = Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $script:TestSecureSecret -Force

            # Both should be connected
            $InitialConnection.Status | Should -Match 'Connected.*'
            $ForcedConnection.Status | Should -Match 'Connected.*'

            # Forced connection should have a new timestamp (same or later)
            $ForcedConnection.ConnectedAt | Should -BeGreaterOrEqual $InitialConnection.ConnectedAt
        }

        It "Should connect with project scope when specified" -Skip:$script:SkipIntegrationTests {
            if ($script:SkipIntegrationTests) { return }
            
            $ProjectName = if (-not [string]::IsNullOrEmpty($script:IntegrationTestData.Project)) { 
                $script:IntegrationTestData.Project 
            } else { 
                "TestProject" 
            }
            
            $Result = Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $script:TestSecureSecret -Project $ProjectName

            $Result.Status | Should -Match 'Connected.*'
            $Result.Project | Should -Be $ProjectName
        }

        It "Should have valid Azure DevOps connection after authentication" -Skip:$script:SkipIntegrationTests {
            if ($script:SkipIntegrationTests) { return }
            
            $Result = Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $script:TestSecureSecret

            $Result | Should -Not -BeNullOrEmpty
            $Result.Status | Should -Match 'Connected.*'
            $Result.TenantId | Should -Be $script:IntegrationTestData.TenantId
            $Result.ClientId | Should -Be $script:IntegrationTestData.ClientId
            $Result.ProjectCount | Should -BeOfType [int]
            $Result.ProjectCount | Should -BeGreaterOrEqual 0
        }

        It "Should fail with invalid credentials" -Skip:$script:SkipIntegrationTests {
            if ($script:SkipIntegrationTests) { return }
            
            $InvalidClientSecret = ConvertTo-SecureString 'invalid-secret-12345' -AsPlainText -Force

            # This should fail with an authentication error
            { Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $InvalidClientSecret -ErrorAction Stop } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }
    }
}
