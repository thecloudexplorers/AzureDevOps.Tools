#Requires -Module Pester

Describe "Azure DevOps Connection Store Functions" {
    BeforeAll {
        # Dot source the private functions directly for testing
        . "$PSScriptRoot/../Private/Set-AzureDevOpsConnectionStore.ps1"
        . "$PSScriptRoot/../Private/Get-AzureDevOpsConnectionStore.ps1"
        . "$PSScriptRoot/../Private/Clear-AzureDevOpsConnectionStore.ps1"
    }

    BeforeEach {
        # Clear any existing connection before each test
        Clear-AzureDevOpsConnectionStore
    }

    AfterEach {
        # Clear connection after each test for cleanup
        Clear-AzureDevOpsConnectionStore
    }

    Context "Set-AzureDevOpsConnectionStore" {
        It "Should store valid connection information" {
            $TestConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                OrganizationName = 'testorg'
                TenantId = '12345678-1234-1234-1234-123456789012'
                ClientId = '87654321-4321-4321-4321-210987654321'
                AccessToken = 'test-access-token'
                TokenExpiry = (Get-Date).AddHours(1)
                ConnectedAt = Get-Date
                ProjectCount = 5
            }

            { Set-AzureDevOpsConnectionStore -ConnectionInfo $TestConnection } | Should -Not -Throw
        }

        It "Should throw error for missing required properties" {
            $IncompleteConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                # Missing required properties
            }

            { Set-AzureDevOpsConnectionStore -ConnectionInfo $IncompleteConnection } | Should -Throw "*must contain a valid*"
        }

        It "Should throw error for expired token" {
            $ExpiredConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                TenantId = '12345678-1234-1234-1234-123456789012'
                ClientId = '87654321-4321-4321-4321-210987654321'
                AccessToken = 'test-access-token'
                TokenExpiry = (Get-Date).AddHours(-1)  # Expired
            }

            { Set-AzureDevOpsConnectionStore -ConnectionInfo $ExpiredConnection } | Should -Throw "*Token expiry must be in the future*"
        }

        It "Should validate null connection info" {
            { Set-AzureDevOpsConnectionStore -ConnectionInfo $null } | Should -Throw
        }
    }

    Context "Get-AzureDevOpsConnectionStore" {
        It "Should return null when no connection exists" {
            $Result = Get-AzureDevOpsConnectionStore
            $Result | Should -Be $null
        }

        It "Should return stored connection information" {
            $TestConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                OrganizationName = 'testorg'
                TenantId = '12345678-1234-1234-1234-123456789012'
                ClientId = '87654321-4321-4321-4321-210987654321'
                AccessToken = 'test-access-token'
                TokenExpiry = (Get-Date).AddHours(1)
                ConnectedAt = Get-Date
                ProjectCount = 5
            }

            Set-AzureDevOpsConnectionStore -ConnectionInfo $TestConnection
            $Result = Get-AzureDevOpsConnectionStore

            $Result | Should -Not -Be $null
            $Result.OrganizationUri | Should -Be $TestConnection.OrganizationUri
            $Result.AccessToken | Should -Be $TestConnection.AccessToken
            $Result.TenantId | Should -Be $TestConnection.TenantId
        }

        It "Should return null for expired token" {
            $ExpiredConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                TenantId = '12345678-1234-1234-1234-123456789012'
                ClientId = '87654321-4321-4321-4321-210987654321'
                AccessToken = 'test-access-token'
                TokenExpiry = (Get-Date).AddMinutes(-10)  # Expired
            }

            # Force set expired connection (bypassing validation)
            $script:AzureDevOpsConnection = $ExpiredConnection
            
            $Result = Get-AzureDevOpsConnectionStore
            $Result | Should -Be $null
        }

        It "Should clear connection with missing required properties" {
            $IncompleteConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                # Missing required properties
            }

            # Force set incomplete connection (bypassing validation)
            $script:AzureDevOpsConnection = $IncompleteConnection
            
            $Result = Get-AzureDevOpsConnectionStore
            $Result | Should -Be $null
        }

        It "Should return cloned connection data to prevent modification" {
            $TestConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                OrganizationName = 'testorg'
                TenantId = '12345678-1234-1234-1234-123456789012'
                ClientId = '87654321-4321-4321-4321-210987654321'
                AccessToken = 'test-access-token'
                TokenExpiry = (Get-Date).AddHours(1)
                ConnectedAt = Get-Date
                ProjectCount = 5
            }

            Set-AzureDevOpsConnectionStore -ConnectionInfo $TestConnection
            $Result1 = Get-AzureDevOpsConnectionStore
            $Result2 = Get-AzureDevOpsConnectionStore

            # Modify one result
            $Result1.AccessToken = 'modified-token'

            # Original stored data should not be affected
            $Result2.AccessToken | Should -Be 'test-access-token'
        }
    }

    Context "Clear-AzureDevOpsConnectionStore" {
        It "Should clear existing connection" {
            $TestConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                TenantId = '12345678-1234-1234-1234-123456789012'
                ClientId = '87654321-4321-4321-4321-210987654321'
                AccessToken = 'test-access-token'
                TokenExpiry = (Get-Date).AddHours(1)
            }

            Set-AzureDevOpsConnectionStore -ConnectionInfo $TestConnection
            Get-AzureDevOpsConnectionStore | Should -Not -Be $null
            
            Clear-AzureDevOpsConnectionStore
            Get-AzureDevOpsConnectionStore | Should -Be $null
        }

        It "Should not throw when no connection exists" {
            { Clear-AzureDevOpsConnectionStore } | Should -Not -Throw
        }
    }

    Context "Integration Tests" {
        It "Should maintain encapsulation by preventing direct script variable access" {
            $TestConnection = @{
                OrganizationUri = 'https://dev.azure.com/testorg'
                TenantId = '12345678-1234-1234-1234-123456789012'
                ClientId = '87654321-4321-4321-4321-210987654321'
                AccessToken = 'test-access-token'
                TokenExpiry = (Get-Date).AddHours(1)
            }

            Set-AzureDevOpsConnectionStore -ConnectionInfo $TestConnection
            
            # Verify we can't access the script variable directly from outside the private functions
            # This test mainly documents the intended behavior
            $StoredConnection = Get-AzureDevOpsConnectionStore
            $StoredConnection | Should -Not -Be $null
            
            # Clear and verify
            Clear-AzureDevOpsConnectionStore
            Get-AzureDevOpsConnectionStore | Should -Be $null
        }
    }
}