# Publishing to PowerShell Gallery

This document provides detailed instructions for publishing the AzureDevOps.Tools module to PowerShell Gallery using the automated CI/CD pipeline.

## Prerequisites

### PowerShell Gallery API Key

1. **Create PowerShell Gallery Account**
   - Visit [PowerShell Gallery](https://www.powershellgallery.com/)
   - Sign in with your Microsoft account

2. **Generate API Key**
   - Go to [API Keys](https://www.powershellgallery.com/account/apikeys)
   - Click "Create"
   - Enter a key name (e.g., "AzureDevOps.Tools CI/CD")
   - Select appropriate permissions:
     - ✅ Push new packages and package versions
     - ✅ Push only packages that match these glob patterns: `AzureDevOps.Tools`
   - Set expiration date (recommended: 1 year)
   - Copy the generated API key

3. **Configure GitHub Secret**
   - Go to GitHub repository: Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `POWERSHELL_GALLERY_API_KEY`
   - Value: Your PowerShell Gallery API key
   - Click "Add secret"

### Environment Setup

The publishing workflow requires the `production` environment to be configured:

1. Go to GitHub repository: Settings → Environments
2. Create environment named `production`
3. Configure protection rules (optional but recommended):
   - Required reviewers
   - Deployment branches (e.g., only `main` branch)

## Publishing Methods

### Method 1: Automatic Publishing via Release (Recommended)

This is the recommended approach for production releases.

1. **Prepare Release**
   ```bash
   # Ensure you're on the main branch
   git checkout main
   git pull origin main
   
   # Verify tests pass locally
   pwsh -c "Invoke-Pester ./Tests -ExcludeTag Integration"
   ```

2. **Create Release**
   - Go to GitHub repository → Releases
   - Click "Create a new release"
   - Choose/create a tag: `v1.0.0` (must start with 'v')
   - Release title: `AzureDevOps.Tools v1.0.0`
   - Describe the changes in the release notes
   - Click "Publish release"

3. **Monitor Publishing**
   - Go to Actions tab
   - Watch the "Publish to PowerShell Gallery" workflow
   - Check for successful completion

4. **Verify Publication**
   - Visit: https://www.powershellgallery.com/packages/AzureDevOps.Tools
   - Test installation: `Install-Module AzureDevOps.Tools -Force`

### Method 2: Manual Publishing via Workflow Dispatch

Use this for testing or emergency releases.

1. **Trigger Workflow**
   - Go to Actions → Publish to PowerShell Gallery
   - Click "Run workflow"
   - Select branch (usually `main`)
   - Enter version: `1.0.1` (without 'v' prefix)
   - Optionally check "Force publish" to overwrite existing versions
   - Click "Run workflow"

2. **Monitor and Verify** (same as Method 1)

## Version Management

### Version Format

- Use semantic versioning: `MAJOR.MINOR.PATCH`
- Examples: `1.0.0`, `1.2.3`, `2.0.0-preview`

### Version Update Process

The publishing workflow automatically updates the module version in `AzureDevOps.Tools.psd1`:

- **For releases**: Uses the tag name (e.g., `v1.0.0` → `1.0.0`)
- **For manual dispatch**: Uses the provided version input

### Pre-release Versions

For pre-release versions:

1. Create a pre-release on GitHub with tag like `v1.0.0-preview`
2. The workflow will publish with prerelease suffix

## Quality Gates

Before publishing, the workflow automatically:

1. ✅ **Updates module version** in manifest file
2. ✅ **Runs all unit tests** (must pass 100%)
3. ✅ **Validates module structure** for PowerShell Gallery compatibility
4. ✅ **Publishes to PowerShell Gallery** using secure API key

## Troubleshooting

### Common Issues

1. **API Key Issues**
   ```
   Error: POWERSHELL_GALLERY_API_KEY secret is not set
   ```
   - Verify the secret is correctly configured in GitHub repository settings
   - Ensure the API key hasn't expired

2. **Version Conflicts**
   ```
   Error: Version '1.0.0' already exists
   ```
   - Use a new version number
   - Or enable "Force publish" in manual workflow (use carefully)

3. **Test Failures**
   ```
   Error: Tests failed: X failed, Y passed
   ```
   - Fix failing tests before publishing
   - Run tests locally: `Invoke-Pester ./Tests -ExcludeTag Integration`

4. **Module Validation Issues**
   ```
   Error: Module manifest missing Description
   ```
   - Ensure all required fields are present in `AzureDevOps.Tools.psd1`
   - Run `Test-ModuleManifest -Path './AzureDevOps.Tools.psd1'` locally

### Getting Help

- Check workflow logs in GitHub Actions tab
- Review PowerShell Gallery package page for status
- Verify module can be installed: `Install-Module AzureDevOps.Tools -Force`

## Security Considerations

- ✅ API keys are stored as GitHub secrets (encrypted)
- ✅ Publishing requires the `production` environment
- ✅ Workflow only publishes from protected branches
- ✅ All dependencies are specified and validated
- ✅ No secrets are logged or exposed in workflow output

## Post-Publication Checklist

After successful publication:

1. ✅ Verify module appears on PowerShell Gallery
2. ✅ Test installation: `Install-Module AzureDevOps.Tools`
3. ✅ Test basic functionality: `Import-Module AzureDevOps.Tools; Get-Command -Module AzureDevOps.Tools`
4. ✅ Update documentation if needed
5. ✅ Announce release (if applicable)

## References

- [PowerShell Gallery Publishing Guidelines](https://docs.microsoft.com/en-us/powershell/scripting/gallery/how-to/publishing-packages)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)