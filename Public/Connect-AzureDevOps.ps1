function Connect-AzureDevOps {
    <#
    .SYNOPSIS
        Connects to Azure DevOps using service principal authentication via REST APIs

    .DESCRIPTION
        Establishes a connection to Azure DevOps organization using service principal authentication
        and the Azure DevOps REST API. This function acquires an access token and validates
        connectivity to the specified organization.
        Can use explicit parameters or automatically detect credentials from environment variables.
        Supports both local development and Azure DevOps pipeline execution with service connections.

    .PARAMETER OrganizationUri
        The URI of the Azure DevOps organization (e.g., 'https://dev.azure.com/myorg').
        Can also be read from AZURE_DEVOPS_ORGANIZATION environment variable.

    .PARAMETER TenantId
        The Azure Active Directory tenant ID for authentication.
        Can also be read from tenantId environment variable (Azure DevOps service connection).

    .PARAMETER ClientId
        The service principal (application) client ID.
        Can also be read from servicePrincipalId environment variable (Azure DevOps service connection).

    .PARAMETER ClientSecret
        The service principal client secret for authentication.
        Can also be read from servicePrincipalKey environment variable (Azure DevOps service connection).

    .PARAMETER Project
        The Azure DevOps project name (optional, for scoped operations).
        Can also be read from AZURE_DEVOPS_PROJECT environment variable.

    .PARAMETER Force
        Forces re-authentication even if already connected

    .EXAMPLE
        # Using explicit parameters
        $SecureSecret = ConvertTo-SecureString 'your-client-secret' -AsPlainText -Force
        Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg' -TenantId '00000000-0000-0000-0000-000000000000' -ClientId '00000000-0000-0000-0000-000000000000' -ClientSecret $SecureSecret

    .EXAMPLE
        # Using environment variables (automatically detected in Azure DevOps pipelines with service connections)
        Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg'

    .EXAMPLE
        # Using mix of parameters and environment variables
        Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg' -Force

    .EXAMPLE
        # In Azure DevOps YAML pipeline with service connection named 'MyAzureConnection'
        # - task: AzurePowerShell@5
        #   inputs:
        #     azureSubscription: 'MyAzureConnection'
        #     scriptType: 'inlineScript'
        #     azurePowerShellVersion: 'LatestVersion'
        #     inlineScript: |
        #       # Service connection variables are automatically available
        #       Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg'

    .OUTPUTS
        PSCustomObject with connection status and organization information

    .NOTES
        Author: The Cloud Explorers
        Uses Azure DevOps REST API with OAuth2 client credentials flow
        Follows Microsoft's official OAuth2 authentication documentation
        Version: 2.2.0
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if ([string]::IsNullOrEmpty($_)) { return $true }
            if ($_ -match '^https://dev\.azure\.com/[a-zA-Z0-9\-]+/?$') {
                $true
            } else {
                throw "OrganizationUri must be in format 'https://dev.azure.com/organizationname'"
            }
        })]
        [string]$OrganizationUri,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if ([string]::IsNullOrEmpty($_)) { return $true }
            if ($_ -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
                $true
            } else {
                throw "TenantId must be a valid GUID"
            }
        })]
        [string]$TenantId,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if ([string]::IsNullOrEmpty($_)) { return $true }
            if ($_ -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
                $true
            } else {
                throw "ClientId must be a valid GUID"
            }
        })]
        [string]$ClientId,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$ClientSecret,

        [Parameter(Mandatory = $false)]
        [string]$Project,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    begin {
        Write-Verbose "Starting Azure DevOps connection process using REST API"
    }

    process {
        try {
            # Resolve parameters from environment variables if not provided
            # Priority: ADO_ variables first, then Azure DevOps service connection variables
            $ResolvedOrganizationUri = if ([string]::IsNullOrEmpty($OrganizationUri)) {
                $env:AZURE_DEVOPS_ORGANIZATION
            } else { $OrganizationUri }

            $ResolvedTenantId = if ([string]::IsNullOrEmpty($TenantId)) {
                $env:tenantId
            } else { $TenantId }

            $ResolvedClientId = if ([string]::IsNullOrEmpty($ClientId)) {
                $env:servicePrincipalId
            } else { $ClientId }

            $ResolvedClientSecret = if ($null -eq $ClientSecret) {
                if (-not [string]::IsNullOrEmpty($env:servicePrincipalKey)) {
                    ConvertTo-SecureString $env:servicePrincipalKey -AsPlainText -Force
                } else { $null }
            } else { $ClientSecret }

            $ResolvedProject = if ([string]::IsNullOrEmpty($Project)) {
                $env:AZURE_DEVOPS_PROJECT
            } else { $Project }

            # Validate required parameters are available
            if ([string]::IsNullOrEmpty($ResolvedOrganizationUri)) {
                throw "OrganizationUri must be provided either as parameter or AZURE_DEVOPS_ORGANIZATION environment variable"
            }
            if ([string]::IsNullOrEmpty($ResolvedTenantId)) {
                throw "TenantId must be provided either as parameter or tenantId environment variable"
            }
            if ([string]::IsNullOrEmpty($ResolvedClientId)) {
                throw "ClientId must be provided either as parameter or servicePrincipalId environment variable"
            }
            if ($null -eq $ResolvedClientSecret) {
                throw "ClientSecret must be provided either as parameter or servicePrincipalKey environment variable"
            }

            # Validate OrganizationUri format
            if ($ResolvedOrganizationUri -notmatch '^https://dev\.azure\.com/[a-zA-Z0-9\-]+/?$') {
                throw "OrganizationUri must be in format 'https://dev.azure.com/organizationname'"
            }

            Write-Verbose "Using OrganizationUri: $ResolvedOrganizationUri"
            Write-Verbose "Using TenantId: $ResolvedTenantId"
            Write-Verbose "Using ClientId: $ResolvedClientId"

            # Check if we already have a valid connection (unless Force is specified)
            $ExistingConnection = Get-AzureDevOpsConnectionStore
            if (-not $Force -and $ExistingConnection -and
                $ExistingConnection.OrganizationUri -eq $ResolvedOrganizationUri.TrimEnd('/') -and
                $ExistingConnection.TenantId -eq $ResolvedTenantId -and
                $ExistingConnection.ClientId -eq $ResolvedClientId) {

                Write-Host "Using existing Azure DevOps connection to: $ResolvedOrganizationUri" -ForegroundColor Green
                Write-Verbose "Connection still valid until: $($ExistingConnection.TokenExpiry)"

                return [PSCustomObject]@{
                    Status = 'Connected (Existing)'
                    OrganizationUri = $ExistingConnection.OrganizationUri
                    OrganizationName = $ExistingConnection.OrganizationName
                    Project = $ExistingConnection.Project
                    TenantId = $ExistingConnection.TenantId
                    ClientId = $ExistingConnection.ClientId
                    ProjectCount = $ExistingConnection.ProjectCount
                    ConnectedAt = $ExistingConnection.ConnectedAt
                    TokenExpiry = $ExistingConnection.TokenExpiry
                    ParameterSource = $ExistingConnection.ParameterSource
                }
            }

            Write-Host "Connecting to Azure DevOps organization: $ResolvedOrganizationUri" -ForegroundColor Green

            # Get Azure DevOps access token using service principal
            Write-Verbose "Acquiring Azure DevOps access token..."
            $AccessToken = Get-AzureDevOpsAccessToken -TenantId $ResolvedTenantId -ClientId $ResolvedClientId -ClientSecret $ResolvedClientSecret

            if (-not $AccessToken) {
                throw "Failed to acquire Azure DevOps access token"
            }

            # Test the connection to Azure DevOps
            Write-Verbose "Testing Azure DevOps API connection..."
            $ConnectionTest = Test-AzureDevOpsConnection -OrganizationUri $ResolvedOrganizationUri -AccessToken $AccessToken

            if (-not $ConnectionTest.Success) {
                throw $ConnectionTest.Error
            }

            # Calculate token expiry (Azure AD tokens typically last 1 hour)
            $TokenExpiry = (Get-Date).AddHours(1)

            # Store connection information securely using private function
            $ConnectionData = @{
                OrganizationUri = $ResolvedOrganizationUri.TrimEnd('/')
                OrganizationName = $ConnectionTest.OrganizationName
                Project = $ResolvedProject
                TenantId = $ResolvedTenantId
                ClientId = $ResolvedClientId
                AccessToken = $AccessToken
                TokenExpiry = $TokenExpiry
                ConnectedAt = Get-Date
                ProjectCount = $ConnectionTest.ProjectCount
                ApiVersion = $ConnectionTest.ApiVersion
                ParameterSource = @{
                    OrganizationUri = if ([string]::IsNullOrEmpty($OrganizationUri)) { 'Environment Variable' } else { 'Parameter' }
                    Project = if ([string]::IsNullOrEmpty($Project)) { 'Environment Variable' } else { 'Parameter' }
                    TenantId = if ([string]::IsNullOrEmpty($TenantId)) { 'Environment Variable' } else { 'Parameter' }
                    ClientId = if ([string]::IsNullOrEmpty($ClientId)) { 'Environment Variable' } else { 'Parameter' }
                    ClientSecret = if ($null -eq $ClientSecret) { 'Environment Variable' } else { 'Parameter' }
                }
            }
            Set-AzureDevOpsConnectionStore -ConnectionInfo $ConnectionData

            # Create return object using stored connection data
            $StoredConnection = Get-AzureDevOpsConnectionStore
            $ConnectionInfo = [PSCustomObject]@{
                Status = 'Connected'
                OrganizationUri = $StoredConnection.OrganizationUri
                OrganizationName = $StoredConnection.OrganizationName
                Project = $StoredConnection.Project
                TenantId = $StoredConnection.TenantId
                ClientId = $StoredConnection.ClientId
                ProjectCount = $StoredConnection.ProjectCount
                ConnectedAt = $StoredConnection.ConnectedAt
                TokenExpiry = $StoredConnection.TokenExpiry
                ParameterSource = $StoredConnection.ParameterSource
            }

            Write-Host "Successfully connected to Azure DevOps organization: $($ConnectionTest.OrganizationName)" -ForegroundColor Green
            Write-Verbose "Connection established at: $($ConnectionInfo.ConnectedAt)"
            Write-Verbose "Token expires at: $($ConnectionInfo.TokenExpiry)"
            Write-Verbose "Projects available: $($ConnectionTest.ProjectCount)"

            return $ConnectionInfo
        }
        catch {
            $ErrorMessage = "Failed to connect to Azure DevOps: $($_.Exception.Message)"
            Write-Error $ErrorMessage
            throw $_
        }
    }

    end {
        Write-Verbose "Azure DevOps connection process completed"
    }
}
