# AzureDevOps.Tools

# AzureDevOps.Tools

A PowerShell module providing utilities and automation tools for Azure DevOps. This module helps streamline authentication and Azure DevOps resource management using REST APIs and OAuth2 client credentials flow.

## Prerequisites

- PowerShell 7.0 or later (PowerShell Core)
- Azure DevOps organization with appropriate permissions
- Azure AD service principal with Azure DevOps access

## Installation

```powershell
# Installation instructions will be added once the module is published to PowerShell Gallery
```

## Features

- **Connect-AzureDevOps**: Authenticate to Azure DevOps using service principal credentials
- OAuth2 client credentials flow implementation
- Direct REST API communication (no Az.Accounts dependency)
- Comprehensive parameter validation

## Usage

### Authentication

All parameters must be provided explicitly:

```powershell
# Import the module
Import-Module AzureDevOps.Tools

# Connect to Azure DevOps with explicit parameters
$SecureSecret = ConvertTo-SecureString 'your-client-secret' -AsPlainText -Force
Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg' `
                    -TenantId 'your-tenant-id-guid' `
                    -ClientId 'your-client-id-guid' `
                    -ClientSecret $SecureSecret

# Optional: Connect with project scope
Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg' `
                    -TenantId 'your-tenant-id-guid' `
                    -ClientId 'your-client-id-guid' `
                    -ClientSecret $SecureSecret `
                    -Project 'MyProject'
```

### Required Parameters

- **OrganizationUri**: Your Azure DevOps organization URI (e.g., 'https://dev.azure.com/myorg')
- **TenantId**: Azure AD tenant ID where your service principal is registered
- **ClientId**: Service principal (application) client ID
- **ClientSecret**: Service principal client secret (as SecureString)
- **Project** (Optional): Default project name for scoped operations

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/MyFeature`)
3. Commit your changes (`git commit -am 'Add MyFeature'`)
4. Push to the branch (`git push origin feature/MyFeature`)
5. Create a Pull Request

## Testing

```powershell
# Run unit tests
Invoke-Pester ./Tests -ExcludeTag Integration

# Run integration tests (requires real Azure credentials)
# Option 1: Configuration file approach
./Tests/Setup-IntegrationTestEnvironment.ps1 -Interactive
Invoke-Pester ./Tests/Connect-AzureDevOps.Integration.Tests.ps1

# Option 2: Environment variables with Pester configuration
$PesterConfig = @{
    OrganizationUri = $env:AZURE_DEVOPS_ORGANIZATION
    TenantId = $env:tenantId
    ClientId = $env:servicePrincipalId
    ClientSecretPlain = $env:servicePrincipalKey
}
Invoke-Pester ./Tests/Connect-AzureDevOps.Integration.Tests.ps1 -Configuration @{ Data = $PesterConfig }

# Run all tests
Invoke-Pester ./Tests
```

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the LICENSE file for details.

## Authors

- The Cloud Explorers
