# AzureDevOps.Tools

A PowerShell module providing utilities and automation tools for Azure DevOps. This module helps streamline common tasks, automate pipeline configurations, and manage Azure DevOps resources efficiently.

## Prerequisites

- PowerShell 7.0 or later (PowerShell Core)
- Az.Accounts module
- Az.DevOps module

## Installation

```powershell
# Installation instructions will be added once the module is published to PowerShell Gallery
```

## Features

- Pipeline Management
- Azure DevOps Configuration Automation
- Environment Variable Management
- Resource Management
- Custom Utility Functions

## Usage

```powershell
# Import the module
Import-Module AzureDevOps.Tools

# Connect to Azure DevOps
Connect-AzureDevOps

# Import JSON configuration as Azure DevOps environment variables
Import-JsonAsEnvironmentVariable -Path './config.json'
```

### Import-JsonAsEnvironmentVariable

Import JSON/JSONC file content as environment variables with automatic POSIX naming convention conversion.

**Features:**

- Parses JSON and JSONC (JSON with Comments) files
- Exports each key/value pair as an environment variable
- Flattens nested objects and converts to POSIX convention (uppercase with underscores)
- Supports arrays (converted to JSON string format)
- Optional prefix for namespacing variables
- Auto-detects Azure DevOps environment and sets variables accordingly
- Compatible with both Azure DevOps pipelines and PowerShell sessions

**JSONC Support:**

- Single-line comments (`//`)
- Multi-line comments (`/* */`)
- Trailing commas

**POSIX Variable Naming Convention:**

All variable names are automatically converted to POSIX convention:

- Converted to UPPERCASE
- Dots (`.`) replaced with underscores (`_`)
- Hyphens (`-`) replaced with underscores (`_`)
- Invalid characters removed
- Variables starting with numbers are prefixed with underscore

| JSON Key | Environment Variable |
|----------|---------------------|
| `version` | `VERSION` |
| `Database.Server` | `DATABASE_SERVER` |
| `app-name` | `APP_NAME` |
| `api.endpoint.url` | `API_ENDPOINT_URL` |

**Examples:**

```powershell
# Import simple JSON configuration
Import-JsonAsEnvironmentVariable -Path './settings.json'

# Import JSONC file with comments
Import-JsonAsEnvironmentVariable -Path './config.jsonc'

# Import with variable prefix
Import-JsonAsEnvironmentVariable -Path './app-config.json' -Prefix 'APP_'

# Sample JSON file (config.json):
# {
#   "version": "1.0.0",
#   "environment": "Production",
#   "database": {
#     "server": "sql.example.com",
#     "port": 1433
#   }
# }
#
# Results in these POSIX environment variables:
# - VERSION = "1.0.0"
# - ENVIRONMENT = "Production"
# - DATABASE_SERVER = "sql.example.com"
# - DATABASE_PORT = "1433"

# Sample JSONC file (config.jsonc) with comments:
# {
#   // Application settings
#   "app": {
#     "name": "MyApp",
#     "version": "2.0.0"
#   },
#   /* Database configuration
#      with multi-line comment */
#   "database": {
#     "host": "localhost",
#     "ssl-enabled": true,  // Trailing comma supported
#   }
# }
#
# Results in POSIX variables:
# - APP_NAME = "MyApp"
# - APP_VERSION = "2.0.0"
# - DATABASE_HOST = "localhost"
# - DATABASE_SSL_ENABLED = "true"
```

**Azure DevOps Pipeline Usage:**

```yaml
steps:
  - pwsh: |
      Import-Module AzureDevOps.Tools
      Import-JsonAsEnvironmentVariable -Path './pipeline-config.json'
    displayName: 'Import JSON Configuration'

  - pwsh: |
      Write-Host "Version: $(VERSION)"
      Write-Host "Environment: $(ENVIRONMENT)"
      Write-Host "Database Server: $(DATABASE_SERVER)"
    displayName: 'Use Imported Variables'
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/MyFeature`)
3. Commit your changes (`git commit -am 'Add MyFeature'`)
4. Push to the branch (`git push origin feature/MyFeature`)
5. Create a Pull Request with appropriate labels (see Version Bumping below)

### Version Bumping

This repository uses automatic semantic versioning based on PR labels. When your PR is merged to `main`, the version is automatically bumped and published.

**Version Bump Rules:**

The workflow determines version bumps based on PR labels with the following priority:

1. **Major Version Bump (X.0.0)**
   - Label Required: `major`
   - Use for: Breaking changes, major new features
   - Example: `v1.2.3` → `v2.0.0`

2. **Minor Version Bump (0.X.0)** - DEFAULT
   - Labels: `minor` OR no version/bug label
   - Use for: New features, enhancements
   - Example: `v1.2.3` → `v1.3.0`
   - **Note:** This is the default if no version or bug label is found

3. **Patch Version Bump (0.0.X)**
   - Labels: `patch` OR `bug`
   - Use for: Bug fixes, small changes
   - Example: `v1.2.3` → `v1.2.4`

**Label Priority:**

If multiple labels are present, the workflow checks in this order:

1. `major` (highest priority)
2. `minor`
3. `patch`
4. `bug` (same as patch)

**Example:**

```bash
# For a bug fix PR
gh pr create --title "Fix authentication issue" --label bug

# For a new feature PR
gh pr create --title "Add new export function" --label minor

# For a breaking change PR
gh pr create --title "Redesign API interface" --label major
```

## Testing

```powershell
# Run tests (to be implemented)
Invoke-Pester ./tests
```

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the LICENSE file for details.

## Authors

- The Cloud Explorers
