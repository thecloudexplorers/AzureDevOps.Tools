function Connect-AzureDevOps {
    <#
    .SYNOPSIS
        Connects to Azure DevOps using service principal authentication via REST APIs

    .DESCRIPTION
        Establishes a connection to Azure DevOps organization using service principal authentication
        and the Azure DevOps REST API. This function acquires an access token and validates
        connectivity to the specified organization.
        All authentication parameters must be provided explicitly.

    .PARAMETER OrganizationUri
        The URI of the Azure DevOps organization (e.g., 'https://dev.azure.com/myorg').

    .PARAMETER TenantId
        The Azure Active Directory tenant ID for authentication.

    .PARAMETER ClientId
        The service principal (application) client ID.

    .PARAMETER ClientSecret
        The service principal client secret for authentication.

    .PARAMETER Project
        The Azure DevOps project name (optional, for scoped operations).

    .PARAMETER Force
        Forces re-authentication even if already connected

    .EXAMPLE
        # Using explicit parameters
        $SecureSecret = ConvertTo-SecureString 'your-client-secret' -AsPlainText -Force
        Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg' -TenantId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -ClientId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -ClientSecret $SecureSecret

    .EXAMPLE
        # Using explicit parameters with project scope
        $SecureSecret = ConvertTo-SecureString 'your-client-secret' -AsPlainText -Force
        Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg' -TenantId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -ClientId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -ClientSecret $SecureSecret -Project 'MyProject'

    .EXAMPLE
        # Force re-authentication
        $SecureSecret = ConvertTo-SecureString 'your-client-secret' -AsPlainText -Force
        Connect-AzureDevOps -OrganizationUri 'https://dev.azure.com/myorg' -TenantId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -ClientId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -ClientSecret $SecureSecret -Force

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
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ($_ -match '^https://dev\.azure\.com/[a-zA-Z0-9\-]+/?$') {
                $true
            } else {
                throw "OrganizationUri must be in format 'https://dev.azure.com/organizationname'"
            }
        })]
        [string]$OrganizationUri,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ($_ -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
                $true
            } else {
                throw "TenantId must be a valid GUID"
            }
        })]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ($_ -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
                $true
            } else {
                throw "ClientId must be a valid GUID"
            }
        })]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
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
            # Validate OrganizationUri format
            if ($OrganizationUri -notmatch '^https://dev\.azure\.com/[a-zA-Z0-9\-]+/?$') {
                throw "OrganizationUri must be in format 'https://dev.azure.com/organizationname'"
            }

            Write-Verbose "Using OrganizationUri: $OrganizationUri"
            Write-Verbose "Using TenantId: $TenantId"
            Write-Verbose "Using ClientId: $ClientId"

            # Check if we already have a valid connection (unless Force is specified)
            $ExistingConnection = $script:AzureDevOpsConnection
            if (-not $Force -and $ExistingConnection -and
                $ExistingConnection.OrganizationUri -eq $OrganizationUri.TrimEnd('/') -and
                $ExistingConnection.TenantId -eq $TenantId -and
                $ExistingConnection.ClientId -eq $ClientId -and
                $ExistingConnection.AccessToken -and
                $ExistingConnection.TokenExpiry -gt (Get-Date).AddMinutes(5)) {

                Write-Host "Using existing Azure DevOps connection to: $OrganizationUri" -ForegroundColor Green
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

            Write-Host "Connecting to Azure DevOps organization: $OrganizationUri" -ForegroundColor Green

            # Get Azure DevOps access token using service principal
            Write-Verbose "Acquiring Azure DevOps access token..."
            $AccessToken = Get-AzureDevOpsAccessToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret

            if (-not $AccessToken) {
                throw "Failed to acquire Azure DevOps access token"
            }

            # Test the connection to Azure DevOps
            Write-Verbose "Testing Azure DevOps API connection..."
            $ConnectionTest = Test-AzureDevOpsConnection -OrganizationUri $OrganizationUri -AccessToken $AccessToken

            if (-not $ConnectionTest.Success) {
                throw $ConnectionTest.Error
            }

            # Calculate token expiry (Azure AD tokens typically last 1 hour)
            $TokenExpiry = (Get-Date).AddHours(1)

            # Store connection information in script scope for other functions to use
            $script:AzureDevOpsConnection = @{
                OrganizationUri = $OrganizationUri.TrimEnd('/')
                OrganizationName = $ConnectionTest.OrganizationName
                Project = $Project
                TenantId = $TenantId
                ClientId = $ClientId
                AccessToken = $AccessToken
                TokenExpiry = $TokenExpiry
                ConnectedAt = Get-Date
                ProjectCount = $ConnectionTest.ProjectCount
                ApiVersion = $ConnectionTest.ApiVersion
                ParameterSource = @{
                    OrganizationUri = 'Parameter'
                    Project = 'Parameter'
                    TenantId = 'Parameter'
                    ClientId = 'Parameter'
                    ClientSecret = 'Parameter'
                }
            }

            # Create return object
            $ConnectionInfo = [PSCustomObject]@{
                Status = 'Connected'
                OrganizationUri = $script:AzureDevOpsConnection.OrganizationUri
                OrganizationName = $script:AzureDevOpsConnection.OrganizationName
                Project = $script:AzureDevOpsConnection.Project
                TenantId = $script:AzureDevOpsConnection.TenantId
                ClientId = $script:AzureDevOpsConnection.ClientId
                ProjectCount = $script:AzureDevOpsConnection.ProjectCount
                ConnectedAt = $script:AzureDevOpsConnection.ConnectedAt
                TokenExpiry = $script:AzureDevOpsConnection.TokenExpiry
                ParameterSource = $script:AzureDevOpsConnection.ParameterSource
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
