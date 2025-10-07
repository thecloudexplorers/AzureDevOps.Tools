@{
    # Integration test configuration for Connect-AzureDevOps
    # Copy this file to IntegrationTestConfig.psd1 and fill in your real credentials
    # DO NOT commit IntegrationTestConfig.psd1 to source control!

    # Required: Your Azure DevOps organization URI
    OrganizationUri = 'https://dev.azure.com/your-org-name'

    # Required: Azure AD tenant ID where your service principal is registered
    TenantId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

    # Required: Service principal (application) client ID
    ClientId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

    # Required: Service principal client secret (plain text - will be converted to SecureString)
    ClientSecretPlain = 'your-client-secret-here'

    # Optional: Default project name for scoped operations
    Project = 'your-project-name'
}
