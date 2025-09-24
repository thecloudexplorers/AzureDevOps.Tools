#Requires -Module Pester

Describe "Connect-AzureDevOps Function Tests" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot ".." "AzureDevOps.Tools.psd1"
        Import-Module $ModulePath -Force
        
        # Load test data
        $TestDataPath = Join-Path $PSScriptRoot "TestData.psd1"
        $script:TestData = Import-PowerShellDataFile -Path $TestDataPath
        $script:UnitTestData = $script:TestData.UnitTests
    }

    AfterAll {
        Remove-Module AzureDevOps.Tools -Force -ErrorAction SilentlyContinue
    }

    Context "Parameter Validation" {
        BeforeAll {
            $TestSecureString = ConvertTo-SecureString $script:UnitTestData.ClientSecretPlain -AsPlainText -Force
            $AltTestSecureString = ConvertTo-SecureString $script:UnitTestData.AltClientSecretPlain -AsPlainText -Force
        }

        It "Should have OrganizationUri as mandatory parameter" {
            $Command = Get-Command Connect-AzureDevOps
            $OrganizationUriParam = $Command.Parameters['OrganizationUri']
            $OrganizationUriParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.Mandatory } | Should -Contain $true
        }

        It "Should have TenantId as mandatory parameter" {
            $Command = Get-Command Connect-AzureDevOps
            $TenantIdParam = $Command.Parameters['TenantId']
            $TenantIdParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.Mandatory } | Should -Contain $true
        }

        It "Should have ClientId as mandatory parameter" {
            $Command = Get-Command Connect-AzureDevOps
            $ClientIdParam = $Command.Parameters['ClientId']
            $ClientIdParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.Mandatory } | Should -Contain $true
        }

        It "Should have ClientSecret as mandatory parameter" {
            $Command = Get-Command Connect-AzureDevOps
            $ClientSecretParam = $Command.Parameters['ClientSecret']
            $ClientSecretParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.Mandatory } | Should -Contain $true
        }


        It "Should validate OrganizationUri format" {
            { Connect-AzureDevOps -OrganizationUri $script:UnitTestData.InvalidUri -TenantId $script:UnitTestData.TenantId -ClientId $script:UnitTestData.ClientId -ClientSecret $TestSecureString -ErrorAction SilentlyContinue } | Should -Throw "*OrganizationUri must be in format*"
        }

        It "Should validate TenantId GUID format" {
            { Connect-AzureDevOps -OrganizationUri $script:UnitTestData.OrganizationUri -TenantId $script:UnitTestData.InvalidGuid -ClientId $script:UnitTestData.ClientId -ClientSecret $TestSecureString -ErrorAction SilentlyContinue } | Should -Throw "*TenantId must be a valid GUID*"
        }

        It "Should validate ClientId GUID format" {
            { Connect-AzureDevOps -OrganizationUri $script:UnitTestData.OrganizationUri -TenantId $script:UnitTestData.TenantId -ClientId $script:UnitTestData.InvalidGuid -ClientSecret $TestSecureString -ErrorAction SilentlyContinue } | Should -Throw "*ClientId must be a valid GUID*"
        }


        It "Should accept valid parameters and fail at OAuth2 authentication level" {
            # This test validates parameter parsing works correctly with all required parameters
            { Connect-AzureDevOps -OrganizationUri $script:UnitTestData.OrganizationUri -TenantId $script:UnitTestData.TenantId -ClientId $script:UnitTestData.ClientId -ClientSecret $TestSecureString -ErrorAction SilentlyContinue } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }

        It "Should accept Force parameter and fail at OAuth2 authentication level" {
            # This test validates Force parameter works with all required parameters
            { Connect-AzureDevOps -OrganizationUri $script:UnitTestData.OrganizationUri -TenantId $script:UnitTestData.TenantId -ClientId $script:UnitTestData.ClientId -ClientSecret $TestSecureString -Force -ErrorAction SilentlyContinue } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }

        It "Should accept Project parameter and fail at OAuth2 authentication level" {
            # This test validates Project parameter works with all required parameters
            { Connect-AzureDevOps -OrganizationUri $script:UnitTestData.OrganizationUri -TenantId $script:UnitTestData.TenantId -ClientId $script:UnitTestData.ClientId -ClientSecret $TestSecureString -Project $script:UnitTestData.Project -ErrorAction SilentlyContinue } | Should -Throw "*Failed to acquire Azure DevOps access token*"
        }

        It "Should require SecureString for ClientSecret parameter" {
            { Connect-AzureDevOps -OrganizationUri $script:UnitTestData.OrganizationUri -TenantId $script:UnitTestData.TenantId -ClientId $script:UnitTestData.ClientId -ClientSecret "plain-text-secret" } | Should -Throw
        }
    }

    Context "Function Behavior" {
        It "Should have proper help documentation" {
            $Help = Get-Help Connect-AzureDevOps
            $Help.Synopsis | Should -Not -BeNullOrEmpty
            $Help.Description | Should -Not -BeNullOrEmpty
            $Help.Examples.Count | Should -BeGreaterThan 0
        }

        It "Should support -Verbose parameter" {
            (Get-Command Connect-AzureDevOps).Parameters.ContainsKey('Verbose') | Should -Be $true
        }
    }
}
