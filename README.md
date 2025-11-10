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

Import JSON file content as Azure DevOps pipeline environment variables that can be used by downstream tasks.

**Features:**
- Parses JSON files and exports each key/value pair as an environment variable
- Flattens nested objects using dot notation (e.g., `Database.Server`)
- Supports arrays (converted to JSON string format)
- Optional prefix for namespacing variables
- Compatible with Azure DevOps pipelines

**Examples:**

```powershell
# Import simple JSON configuration
Import-JsonAsEnvironmentVariable -Path './settings.json'

# Import with variable prefix
Import-JsonAsEnvironmentVariable -Path './app-config.json' -Prefix 'APP_'

# Sample JSON file (config.json):
# {
#   "Version": "1.0.0",
#   "Environment": "Production",
#   "Database": {
#     "Server": "sql.example.com",
#     "Port": 1433
#   }
# }
#
# Results in these environment variables:
# - Version = "1.0.0"
# - Environment = "Production"
# - Database.Server = "sql.example.com"
# - Database.Port = 1433
```

**Azure DevOps Pipeline Usage:**

```yaml
steps:
  - pwsh: |
      Import-Module AzureDevOps.Tools
      Import-JsonAsEnvironmentVariable -Path './pipeline-config.json'
    displayName: 'Import JSON Configuration'

  - pwsh: |
      Write-Host "Version: $(Version)"
      Write-Host "Environment: $(Environment)"
      Write-Host "Database Server: $(Database.Server)"
    displayName: 'Use Imported Variables'
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/MyFeature`)
3. Commit your changes (`git commit -am 'Add MyFeature'`)
4. Push to the branch (`git push origin feature/MyFeature`)
5. Create a Pull Request

## Testing

```powershell
# Run tests (to be implemented)
Invoke-Pester ./tests
```

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the LICENSE file for details.

## Authors

- The Cloud Explorers
