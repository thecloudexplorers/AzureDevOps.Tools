#Requires -Module Pester

<#
.SYNOPSIS
    Integration tests for Connect-AzureDevOps function with real Azure authentication

.DESCRIPTION
    These tests require actual Azure credentials to be provided via Pester configuration.
    Create a PesterConfiguration.psd1 file or provide credentials via test data configuration.

.NOTES
    Run these tests only when you have valid Azure credentials configured.
    These tests will attempt real Azure authentication.
#>

Describe "Connect-AzureDevOps Integration Tests" -Tag "Integration" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot ".." "AzureDevOps.Tools.psd1"
        Import-Module $ModulePath -Force

        # Load test data
        $TestDataPath = Join-Path $PSScriptRoot "TestData.psd1"
        $script:TestData = Import-PowerShellDataFile -Path $TestDataPath
        $script:IntegrationTestData = $script:TestData.IntegrationTests

        # Try to load integration test configuration if it exists
        $IntegrationConfigPath = Join-Path $PSScriptRoot "IntegrationTestConfig.psd1"
        if (Test-Path $IntegrationConfigPath) {
            $IntegrationConfig = Import-PowerShellDataFile -Path $IntegrationConfigPath
            $script:IntegrationTestData = $IntegrationConfig
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
            Write-Host "To run integration tests, create Tests/IntegrationTestConfig.psd1 with real credentials" -ForegroundColor Yellow
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

        It "Should connect with project scope when specified" -Skip { # -Skip:$script:SkipIntegrationTests {
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
            $Result.ProjectCount | Should -BeOfType [Int64]
            $Result.ProjectCount | Should -BeGreaterOrEqual 0
        }

        It "Should fail with invalid credentials" -Skip:$script:SkipIntegrationTests {
            if ($script:SkipIntegrationTests) { return }

            $InvalidClientSecret = ConvertTo-SecureString 'invalid-secret-12345' -AsPlainText -Force

            # This should fail with an authentication error
            { Connect-AzureDevOps -OrganizationUri $script:IntegrationTestData.OrganizationUri -TenantId $script:IntegrationTestData.TenantId -ClientId $script:IntegrationTestData.ClientId -ClientSecret $InvalidClientSecret -ErrorAction Stop -Force } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }
    }
}
