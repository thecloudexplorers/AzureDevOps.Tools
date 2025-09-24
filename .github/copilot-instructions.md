# AzureDevOps.Tools AI Coding Guide

This document provides essential knowledge for AI coding agents working with the AzureDevOps.Tools PowerShell module.

## Project Architecture

AzureDevOps.Tools is a PowerShell module (PowerShell 7.0+) that provides automation tools for Azure DevOps. The module structure follows standard PowerShell practices:

- **Public/**: Exported functions accessible to module users
- **Private/**: Internal helper functions used by public functions
- **Tests/**: Pester test files, including both unit and integration tests

The module uses a core authentication pattern based on OAuth2 client credentials flow with Microsoft Entra ID (Azure AD) for Azure DevOps REST API authentication.

## Authentication Flow

1. `Connect-AzureDevOps` (Public) handles parameter validation and explicit authentication
2. `Get-AzureDevOpsAccessToken` (Private) manages the OAuth2 token acquisition
3. `Test-AzureDevOpsConnection` (Private) validates the connection by making a test API call

The module uses explicit parameter authentication:

- All parameters must be provided explicitly: organization URI, tenant ID, client ID, and client secret
- No environment variable fallback - all authentication data must be passed as parameters

## Development Workflows

### Setting Up for Development

```powershell
# Import the module for development (from repo root)
Import-Module ./AzureDevOps.Tools.psd1 -Force

# Setup integration test environment with real credentials
./Tests/Setup-IntegrationTestEnvironment.ps1 -Interactive
```

### Running Tests

```powershell
# Unit tests only (parameter validation, mocks)
Invoke-Pester ./Tests -ExcludeTag Integration

# Integration tests (requires real Azure credentials via configuration)
# Option 1: Using configuration file
./Tests/Setup-IntegrationTestEnvironment.ps1 -Interactive
Invoke-Pester ./Tests/Connect-AzureDevOps.Integration.Tests.ps1

# Option 2: Using environment variables with Pester configuration
$PesterConfig = @{
    OrganizationUri = $env:AZURE_DEVOPS_ORGANIZATION
    TenantId = $env:tenantId
    ClientId = $env:servicePrincipalId
    ClientSecretPlain = $env:servicePrincipalKey
}
Invoke-Pester ./Tests/Connect-AzureDevOps.Integration.Tests.ps1 -Configuration @{ Data = $PesterConfig }

# All tests
Invoke-Pester ./Tests
```

## PowerShell Coding Standards

_A concise guide outlining required conventions for PowerShell scripts within this repository._

### 1. Function Structure

1. **1.1** Always write an advanced function, not inline code.
   _Note:_ Use the `function` keyword with `[CmdletBinding()]` so your code supports common parameters.

   ```powershell
   function Get-Example {
       [CmdletBinding()]
       param()
       process { "Hello" }
   }
   ```

2. **1.2** Use CmdletBinding() at top.
   _Note:_ Placing `[CmdletBinding()]` enables `-Verbose`, `-ErrorAction`, etc., without extra code.

3. **1.3** Split into Begin, Process, and End blocks—even if empty.
   _Note:_ Structure your logic so initialization goes in `Begin {}`, main work in `Process {}`, cleanup in `End {}`.

### 2. Comment-Based Help

1. **2.1** Include a `<# .SYNOPSIS … .DESCRIPTION … .PARAMETER … .EXAMPLE … #>` block above the function.
   _Note:_ A proper help block allows users to run `Get-Help` with full context.

2. **2.2** Document every parameter with `.PARAMETER Name` and a clear description.
   _Note:_ Ensures each `param()` entry is self-explanatory when viewed via help.

3. **2.3** Use the universal placeholder GUID format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` in example blocks instead of fake or real GUIDs.
   _Note:_ Prevents security-linting tools from flagging example GUIDs.

### 3. Parameter Block

1. **3.1** One attribute per line.
   _Note:_ Improves readability and diff tracking.

2. **3.2** Always start with `[Parameter(...)]`.
   _Note:_ Every parameter declaration must begin with its attribute.

3. **3.3** Use `[ValidateNotNullOrEmpty()]` immediately after if mandatory.
   _Note:_ Ensures required parameters always have a value.

4. **3.4** Mandatory parameters: `[Parameter(Mandatory=$true)]`.
   _Note:_ Prompts the user if they forget to supply that argument.

5. **3.5** Optional parameters: `[Parameter()]` and default value immediately after the name.
   _Note:_ Makes it explicit which parameters are optional and their defaults.

6. **3.7** Parameter names must use PascalCase.
   _Note:_ Ensures consistency with PowerShell parameter naming conventions.

### 4. Naming

1. **4.1** Function names use PascalCase with a verb-noun pair (e.g. `Initialize-ArtifactFeed`).
   _Note:_ Follows PowerShell's Verb-Noun convention for discoverability.

2. **4.2** Use approved verbs in function names. Note: Use `Get-Verb` to select an approved verb (e.g., Get-UserAccount).
   _Note:_ Ensures consistency with PowerShell's built-in cmdlets.

3. **4.3** Ensure function names clearly describe the action and the target. Note: Use specific PascalCase nouns (e.g., `Get-User` vs `Get-Users`).
   _Note:_ Improves clarity for users and maintainers.

4. **4.4** Use singular nouns for cmdlet names unless returning multiple items.
   _Note:_ Prefer singular noun for commands returning a single object.

### 5. Module Imports

1. **5.1** Load required modules in the Begin block.
   _Note:_ Guarantees dependencies are available before processing.

2. **5.2** Use `Import-Module @params` splatting when three or more parameters.
   _Note:_ Keeps commands tidy when specifying multiple options.

3. **5.3** Fail fast: `-ErrorAction Stop` and catch with try/catch, rethrow on failure.
   _Note:_ Ensures module loading errors halt execution immediately.

### 6. TLS Enforcement

1. **6.1** In Process, set `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`.
   _Note:_ Forces use of TLS 1.2 for all outbound web requests.

   ```powershell
   Write-Verbose "Enforcing TLS 1.2"
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   ```

2. **6.2** Wrap in Write-Verbose description.
   _Note:_ Signals to the user that security settings are being applied.

### 7. Azure DevOps Logging

1. **7.1** Surround logical sections with `Write-Host "##[group]…"` and `Write-Host "##[endgroup]"`.
   _Note:_ Collapses output in Azure Pipelines for clarity.

2. **7.2** Use clear section titles (e.g. "Prepare variables", "Set secret vault and secret store").
   _Note:_ Helps operators quickly find relevant log segments.

### 8. Variable Initialization

1. **8.1** Static defaults declared in Begin.
   _Note:_ Centralizes constant values for easy maintenance.

2. **8.2** Automatic values (like random passwords) generated in Begin, with inline comments explaining each step.
   _Note:_ Ensures reproducible randomness and documents how values are derived.

### 9. Secure Strings & Credentials

1. **9.1** Always convert PAT or passwords via `ConvertTo-SecureString -AsPlainText -Force`.
   _Note:_ Ensures secrets are handled as secure strings.

2. **9.2** Create PSCredential with `New-Object System.Management.Automation.PSCredential($user, $secureString)`.
   _Note:_ Standard PSCredential objects work with cmdlets expecting credentials.

### 13. Error Handling

1. **13.1** Every critical call uses `-ErrorAction Stop`.
   _Note:_ Forces exceptions on failures rather than silent errors.

2. **13.2** Wrap module imports in try/catch and rethrow to fail the pipeline.
   _Note:_ Ensures upstream errors propagate correctly.

3. **13.3** Set `$ErrorActionPreference = 'Stop'` at script start and wrap code in `try/catch` blocks to handle exceptions explicitly.
   _Note:_ Ensures all errors trigger catch logic.

4. **13.4** Use `Write-Error` for non-terminating error messages and reserve `throw` for truly terminating exceptions.
   _Note:_ Ensures errors are emitted on the correct stream and avoids unintended pipeline breaks.

5. **13.5** Never throw string literals; instead throw exception objects or rethrow the original exception.
   _Note:_ Preserves the stack trace and full exception context for accurate debugging.

### 14. Splatting

1. **14.1** For any call with more than two parameters, build a hashtable `$params = @{…}` then call `Cmdlet @params`.
   _Note:_ Improves readability for cmdlets with many options.

2. **14.2** Never use backtick line continuation—always use splatting or a single line.
   _Note:_ Avoids fragile and hard-to-read backtick breaks.

### 15. Inline Comments

1. **15.1** Comment any complex logic (password generation, URL composition, splatting blocks).
   _Note:_ Helps future maintainers understand nontrivial code.

2. **15.2** Keep comments concise and above the line they describe.
   _Note:_ Maintains a clean association between comment and code.

### 16. String Formatting

1. **16.1** Use double-quoted strings when interpolation is needed.
   _Note:_ Ensures variable values are expanded inside strings.

2. **16.2** Break long URLs into concatenations or variables with inline comments.
   _Note:_ Prevents overly long lines and clarifies URL segments.

### 17. Output Verbosity

1. **17.1** Use `Write-Verbose` for non-critical status messages.
   _Note:_ Users can enable verbose mode for detailed output.

2. **17.2** Use `Write-Host` inside pipeline groups for high-level progress.
   _Note:_ Ensures key milestones are always visible.

### 20. General Style

1. **20.1** Indent four spaces.
   _Note:_ Consistent indentation improves readability.

2. **20.2** No trailing commas or semicolons.
   _Note:_ Avoids syntax issues and lint warnings.

3. **20.3** Keep line length under \~120 characters.
   _Note:_ Ensures code fits typical editor windows.

4. **20.4** One statement per line.
   _Note:_ Simplifies debugging and version control diffs.

5. **20.6** Remove any commented-out code blocks before committing.
   _Note:_ Keeps codebase clean and relies on version control history instead of commented code.

### 21. Script Prerequisites

1. **21.1** Use `#Requires` statements at the top to define environment prerequisites.
   _Note:_ Use `#Requires -PSEdition Core` and `#Requires -Modules Az` to fail fast when conditions aren't met.

## Design Principles

This module follows these key design principles:

1. **YAGNI (You Aren't Gonna Need It)**:

   - Implement only what's needed now, not speculative features
   - Example: Authentication focused on core OAuth2 flow without additional complex options
   - Functions have specific purposes rather than trying to be overly generic

2. **KISS (Keep It Simple, Stupid)**:

   - Clear, straightforward function names (e.g., `Connect-AzureDevOps`)
   - Consistent parameter patterns across functions
   - Avoid complex inheritance or unnecessary abstraction

3. **DRY (Don't Repeat Yourself)**:

   - Common code extracted to private functions (e.g., `Get-AzureDevOpsAccessToken`)
   - Parameter validation logic centralized in public functions
   - Consistent parameter patterns across functions

4. **SOLID**:
   - **Single Responsibility**: Each function does one thing well (connect, get token, test)
   - **Open/Closed**: Add new features by creating new functions, not modifying existing ones
   - **Interface Segregation**: Public functions expose only necessary parameters
   - **Dependency Inversion**: Functions receive dependencies rather than creating them

## Key Integration Points

- **Azure DevOps REST API**: The module uses REST APIs with OAuth2 authentication
- **Azure DevOps Pipelines**: Designed to work seamlessly in pipeline environments
- **PowerShell 7.0+**: Required for the module's core functionality
- **Pester 5+**: Used for all testing scenarios

When adding new functionality, follow the established pattern of Public/Private function separation and include both unit and integration tests.
