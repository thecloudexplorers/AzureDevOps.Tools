@{
    # Test data configuration for Connect-AzureDevOps tests
    # This file provides consistent test values for unit tests
    # Real credentials for integration tests should be provided via Pester configuration
    
    UnitTests = @{
        # Test organization and authentication values for unit tests (fake credentials)
        OrganizationUri = 'https://dev.azure.com/testorg'
        TenantId = '12345678-1234-1234-1234-123456789012'
        ClientId = '87654321-4321-4321-4321-210987654321'
        ClientSecretPlain = 'test-secret'
        Project = 'TestProject'
        
        # Alternative test values for validation tests
        AltOrganizationUri = 'https://dev.azure.com/altorg'
        AltTenantId = '11111111-2222-3333-4444-555555555555'
        AltClientId = '99999999-8888-7777-6666-555555555555'
        AltClientSecretPlain = 'alt-secret'
        
        # Invalid test values for negative testing
        InvalidUri = 'invalid-uri'
        InvalidGuid = 'invalid-guid'
    }
    
    IntegrationTests = @{
        # Integration test configuration
        # Real values should be provided via Pester configuration or external config file
        # These are placeholders showing the expected structure
        OrganizationUri = '' # Should be provided via configuration
        TenantId = ''        # Should be provided via configuration  
        ClientId = ''        # Should be provided via configuration
        ClientSecretPlain = '' # Should be provided via configuration
        Project = ''         # Optional, should be provided via configuration
    }
}