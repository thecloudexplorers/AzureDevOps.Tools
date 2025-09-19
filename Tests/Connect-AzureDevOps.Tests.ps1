#Requires -Module Pester

Describe "Connect-AzureDevOps Function Tests" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot ".." "AzureDevOps.Tools.psd1"
        Import-Module $ModulePath -Force
    }

    AfterAll {
        Remove-Module AzureDevOps.Tools -Force -ErrorAction SilentlyContinue
    }

    Context "Parameter Validation" {
        BeforeAll {
            $TestSecureString = ConvertTo-SecureString 'test-secret' -AsPlainText -Force

            # Store original environment variables
            $OriginalEnv = @{
                AZURE_DEVOPS_ORGANIZATION = $env:AZURE_DEVOPS_ORGANIZATION
                AZURE_DEVOPS_PROJECT = $env:AZURE_DEVOPS_PROJECT
                tenantId = $env:tenantId
                servicePrincipalId = $env:servicePrincipalId
                servicePrincipalKey = $env:servicePrincipalKey
            }
        }

        AfterAll {
            # Restore original environment variables
            $env:AZURE_DEVOPS_ORGANIZATION = $OriginalEnv.AZURE_DEVOPS_ORGANIZATION
            $env:AZURE_DEVOPS_PROJECT = $OriginalEnv.AZURE_DEVOPS_PROJECT
            $env:tenantId = $OriginalEnv.tenantId
            $env:servicePrincipalId = $OriginalEnv.servicePrincipalId
            $env:servicePrincipalKey = $OriginalEnv.servicePrincipalKey
        }

        BeforeEach {
            # Clear environment variables before each test
            $env:AZURE_DEVOPS_ORGANIZATION = $null
            $env:AZURE_DEVOPS_PROJECT = $null
            $env:tenantId = $null
            $env:servicePrincipalId = $null
            $env:servicePrincipalKey = $null
        }

        It "Should require OrganizationUri from parameter or environment variable" {
            { Connect-AzureDevOps -ErrorAction SilentlyContinue } | Should -Throw "*OrganizationUri must be provided*"
        }

        It "Should require TenantId from parameter or environment variable" {
            $env:AZURE_DEVOPS_ORGANIZATION = 'https://dev.azure.com/test'
            { Connect-AzureDevOps -ErrorAction SilentlyContinue } | Should -Throw "*TenantId must be provided*"
        }

        It "Should require ClientId from parameter or environment variable" {
            $env:AZURE_DEVOPS_ORGANIZATION = 'https://dev.azure.com/test'
            $env:tenantId = '12345678-1234-1234-1234-123456789012'
            { Connect-AzureDevOps -ErrorAction SilentlyContinue } | Should -Throw "*ClientId must be provided*"
        }

        It "Should require ClientSecret from parameter or environment variable" {
            $env:AZURE_DEVOPS_ORGANIZATION = 'https://dev.azure.com/test'
            $env:tenantId = '12345678-1234-1234-1234-123456789012'
            $env:servicePrincipalId = '87654321-4321-4321-4321-210987654321'
            { Connect-AzureDevOps -ErrorAction SilentlyContinue } | Should -Throw "*ClientSecret must be provided*"
        }


        It "Should validate OrganizationUri format from parameter" {
            { Connect-AzureDevOps -OrganizationUri 'invalid-uri' -TenantId '12345678-1234-1234-1234-123456789012' -ClientId '87654321-4321-4321-4321-210987654321' -ClientSecret $TestSecureString -ErrorAction SilentlyContinue } | Should -Throw "*OrganizationUri must be in format*"
        }

        It "Should validate OrganizationUri format from environment variable" {
            $env:AZURE_DEVOPS_ORGANIZATION = 'invalid-uri'
            $env:tenantId = '12345678-1234-1234-1234-123456789012'
            $env:servicePrincipalId = '87654321-4321-4321-4321-210987654321'
            $env:servicePrincipalKey = 'test-secret'
            { Connect-AzureDevOps -ErrorAction SilentlyContinue } | Should -Throw "*OrganizationUri must be in format*"
        }

        It "Should validate TenantId GUID format from parameter" {
            { Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/test' -TenantId 'invalid-guid' -ClientId '87654321-4321-4321-4321-210987654321' -ClientSecret $TestSecureString -ErrorAction SilentlyContinue } | Should -Throw "*TenantId must be a valid GUID*"
        }

        It "Should validate ClientId GUID format from parameter" {
            { Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/test' -TenantId '12345678-1234-1234-1234-123456789012' -ClientId 'invalid-guid' -ClientSecret $TestSecureString -ErrorAction SilentlyContinue } | Should -Throw "*ClientId must be a valid GUID*"
        }


        It "Should accept valid parameters and fail at OAuth2 authentication level" {
            # This test validates parameter parsing works correctly
            { Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/test' -TenantId '12345678-1234-1234-1234-123456789012' -ClientId '87654321-4321-4321-4321-210987654321' -ClientSecret $TestSecureString -ErrorAction SilentlyContinue } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }

        It "Should accept valid environment variables and fail at OAuth2 authentication level" {
            # This test validates environment variable resolution works correctly
            $env:AZURE_DEVOPS_ORGANIZATION = 'https://dev.azure.com/test'
            $env:tenantId = '12345678-1234-1234-1234-123456789012'
            $env:servicePrincipalId = '87654321-4321-4321-4321-210987654321'
            $env:servicePrincipalKey = 'test-secret'
            { Connect-AzureDevOps -ErrorAction SilentlyContinue } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }

        It "Should accept valid Azure DevOps service connection environment variables as fallback" {
            # This test validates fallback environment variable resolution works correctly
            $env:AZURE_DEVOPS_ORGANIZATION = 'https://dev.azure.com/test'
            $env:tenantId = '12345678-1234-1234-1234-123456789012'
            $env:servicePrincipalId = '87654321-4321-4321-4321-210987654321'
            $env:servicePrincipalKey = 'test-secret'
            { Connect-AzureDevOps -ErrorAction SilentlyContinue } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }

        It "Should use standard service principal variables" {
            # Set service principal variables
            $env:AZURE_DEVOPS_ORGANIZATION = 'https://dev.azure.com/azure-org'
            $env:tenantId = '11111111-2222-3333-4444-555555555555'
            $env:servicePrincipalId = '99999999-8888-7777-6666-555555555555'
            $env:servicePrincipalKey = 'azure-secret'

            # This should use standard service principal variables (not ADO variables) and fail at OAuth2 authentication level
            { Connect-AzureDevOps -ErrorAction SilentlyContinue } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }

        It "Should accept Force parameter and fail at OAuth2 authentication level" {
            { Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/test' -TenantId '12345678-1234-1234-1234-123456789012' -ClientId '87654321-4321-4321-4321-210987654321' -ClientSecret $TestSecureString -Force -ErrorAction SilentlyContinue } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }

        It "Should require SecureString for ClientSecret parameter" {
            { Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/test' -TenantId '12345678-1234-1234-1234-123456789012' -ClientId '87654321-4321-4321-4321-210987654321' -ClientSecret 'plain-text-secret' } | Should -Throw
        }
    }

    Context "Function Behavior" {
        It "Should have proper help documentation" {
            $Help = Get-Help Connect-AzureDevOps -Full
            $Help.Synopsis | Should -Not -BeNullOrEmpty
            $Help.Description | Should -Not -BeNullOrEmpty
            $Help.Examples.Count | Should -BeGreaterThan 0
        }

        It "Should not support -WhatIf parameter (connection functions don't modify resources)" {
            (Get-Command Connect-AzureDevOps).Parameters.ContainsKey('WhatIf') | Should -Be $false
        }

        It "Should support -Verbose parameter" {
            (Get-Command Connect-AzureDevOps).Parameters.ContainsKey('Verbose') | Should -Be $true
        }
    }
}
