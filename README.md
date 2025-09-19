# AzureDevOps.Tools

A PowerShell module providing utilities and automation tools for Azure DevOps. This module helps streamline common tasks, automate pipeline configurations, and manage Azure DevOps resources efficiently.

## Prerequisites

- PowerShell 7.0 or later (PowerShell Core)
- Az.Accounts module
- Az.DevOps module

## Installation

Install from PowerShell Gallery:

```powershell
# Install the module from PowerShell Gallery
Install-Module -Name AzureDevOps.Tools -Scope CurrentUser

# Import the module
Import-Module AzureDevOps.Tools
```

Or install from source:

```powershell
# Clone the repository
git clone https://github.com/thecloudexplorers/AzureDevOps.Tools.git
cd AzureDevOps.Tools

# Import the module
Import-Module ./AzureDevOps.Tools.psd1
```

## Features

- Pipeline Management
- Azure DevOps Configuration Automation
- Resource Management
- Custom Utility Functions

## Usage

```powershell
# Import the module
Import-Module AzureDevOps.Tools

# Connect to Azure DevOps
Connect-AzureDevOps
```

More detailed usage examples will be added as functions are implemented.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/MyFeature`)
3. Commit your changes (`git commit -am 'Add MyFeature'`)
4. Push to the branch (`git push origin feature/MyFeature`)
5. Create a Pull Request

## Testing

This project uses Pester for testing. Tests are automatically run in CI/CD pipelines.

```powershell
# Install Pester (if not already installed)
Install-Module -Name Pester -Force -Scope CurrentUser

# Run unit tests only
Invoke-Pester ./Tests -ExcludeTag Integration

# Run all tests (requires Azure credentials for integration tests)
Invoke-Pester ./Tests

# Setup integration test environment (interactive)
./Tests/Setup-IntegrationTestEnvironment.ps1 -Interactive

# Validate CI/CD pipeline setup locally
./scripts/Test-Pipeline.ps1 -SkipDependencyTests
```

### Test Types

- **Unit Tests**: Test parameter validation and basic functionality without external dependencies
- **Integration Tests**: Test real Azure DevOps connectivity (requires Azure credentials)

## CI/CD Pipeline

This project uses GitHub Actions for continuous integration and deployment:

### Workflows

1. **CI (`ci.yml`)**: Runs on push to main/develop and pull requests
   - Tests module manifest
   - Runs unit tests
   - Validates PowerShell Gallery readiness

2. **PR Validation (`pr-validation.yml`)**: Runs on pull requests
   - PSScriptAnalyzer code quality checks
   - Module structure validation
   - Unit tests with code coverage
   - Automated PR comments with results

3. **Publish (`publish.yml`)**: Publishes to PowerShell Gallery
   - Triggered on new releases or manual dispatch
   - Updates module version
   - Runs tests before publishing
   - Publishes to PowerShell Gallery

### Publishing Process

#### Automatic Publishing (Recommended)

1. Create a new release on GitHub with a version tag (e.g., `v1.0.0`)
2. The publish workflow will automatically:
   - Update the module version
   - Run tests
   - Publish to PowerShell Gallery

#### Manual Publishing

1. Go to Actions → Publish to PowerShell Gallery
2. Click "Run workflow"
3. Enter the version number (e.g., `1.0.0`)
4. Optionally enable "Force publish" to overwrite existing versions

#### Required Secrets

To enable publishing, configure the following repository secret:

- `POWERSHELL_GALLERY_API_KEY`: Your PowerShell Gallery API key
  - Get your API key from [PowerShell Gallery](https://www.powershellgallery.com/account/apikeys)
  - Add it to GitHub repository secrets: Settings → Secrets and variables → Actions

📚 **For detailed publishing instructions, see [Publishing Guide](docs/PUBLISHING.md)**

### Quality Gates

All code changes must pass:
- ✅ PSScriptAnalyzer (no errors, warnings accepted)
- ✅ Module manifest validation
- ✅ Unit tests (100% pass rate required)
- ✅ PowerShell Gallery readiness validation

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the LICENSE file for details.

## Authors

- The Cloud Explorers
