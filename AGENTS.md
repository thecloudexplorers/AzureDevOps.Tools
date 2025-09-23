# 🤖 Agent Implementation Guide

This repository captures engineering standards for DevOps, PowerShell automation, and CI/CD workflows. Use this guide whenever you modify or add content so updates stay aligned with the documented practices.

## Scope

- These instructions apply to the entire repository unless a more specific guideline is added in a subdirectory.
- Follow all applicable sections when editing or creating Markdown, PowerShell, or supporting automation assets.

## PowerShell Guidance

- Prefer advanced functions with `[CmdletBinding()]` and explicit `Begin`, `Process`, and `End` blocks.
- Provide full comment-based help for every parameter and example, using placeholder GUIDs.
- Declare one attribute per line in `param()` blocks, enforce PascalCase parameter names, and distinguish mandatory vs. optional parameters clearly.
- Adopt verb-noun, PascalCase naming that relies on approved PowerShell verbs.
- Load modules in the `Begin` block, fail fast with `-ErrorAction Stop`, and surface meaningful errors.
- Enforce TLS 1.2 for outbound calls, wrap logging with Azure DevOps groups, and standardize on splatting for commands with more than two parameters.
- Favor `Write-Verbose` for detailed progress, keep output free from unnecessary square brackets, and finish scripts quietly after logging completion.
- Guard direct script execution with `$PSCommandPath` checks and require four-space indentation, <120 character lines, and no trailing whitespace.

## Tooling & Enforcement

- Mirror the recommended VS Code workspace settings (indentation, rulers, Script Analyzer integration, formatting on save) when contributing editor configuration.
- Reuse the provided `PSScriptAnalyzerSettings.psd1` profile and ensure any automation honors the enabled rules.
- If Git hooks are added, make them executable and run Script Analyzer against staged PowerShell files.

## Secrets, Modules, and Pipelines

- Handle secrets through secure stores (e.g., Azure Key Vault) and avoid embedding real credentials or GUIDs in docs or examples.
- Design reusable module structures, pin PSResource versions, and script repeatable installation flows with verbose logging.
- Structure CI/CD pipelines with clear stages, artifact management, and branching discipline; group log output for readability.

## Documentation Updates

- Keep standards documentation concise, actionable, and consistent with existing tone (direct, prescriptive bullet lists).
- Cross-reference related standards when adding new guidance and note whether enforcement is automated or manual.

## Quality Checks

- No automated test suite is defined. Manually review changes for alignment with the standards above before submitting.
