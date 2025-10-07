#Requires -PSEdition Core

function Get-AzureDevOpsAccessToken {
    <#
    .SYNOPSIS
        Gets an access token for Azure DevOps REST API using OAuth2 client credentials flow

    .DESCRIPTION
        Acquires an Azure AD access token for the Azure DevOps API scope using the official
        OAuth2 client credentials flow as documented by Microsoft. This token can be used
        to authenticate with Azure DevOps REST APIs.

    .PARAMETER TenantId
        The Azure Active Directory tenant ID

    .PARAMETER ClientId
        The service principal (application) client ID

    .PARAMETER ClientSecret
        The service principal client secret

    .OUTPUTS
        String containing the access token

    .NOTES
        Uses the Azure DevOps specific scope: https://app.vssps.visualstudio.com/.default
        Follows Microsoft's official OAuth2 client credentials flow documentation
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Security.SecureString]$ClientSecret
    )

    begin {
        Write-Verbose "Initializing Azure DevOps access token acquisition process"
    }

    process {
        try {
            Write-Verbose "Acquiring Azure DevOps access token using OAuth2 client credentials flow"
            Write-Verbose "TenantId: $TenantId"
            Write-Verbose "ClientId: $ClientId"

        # Convert SecureString to plain text for the API call
        $PlainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
        )

        # OAuth2 v2.0 token endpoint
        $TokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

        # Azure DevOps specific scope
        $Scope = "https://app.vssps.visualstudio.com/.default"

        Write-Verbose "Token endpoint: $TokenUri"
        Write-Verbose "Scope: $Scope"

        # Prepare request body according to Microsoft OAuth2 client credentials flow specification
        # Format: application/x-www-form-urlencoded
        $Body = @{
            'client_id' = $ClientId
            'scope' = $Scope
            'client_secret' = $PlainSecret
            'grant_type' = 'client_credentials'
        }

        Write-Verbose "Making token request to Microsoft identity platform"

        # Make the token request
        $Response = Invoke-RestMethod -Uri $TokenUri -Method Post -Body $Body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop

        # Validate response
        $ValidationErrors = @()
        if (-not $Response) {
            $ValidationErrors += "No response received from token endpoint."
        }
        elseif (-not $Response.access_token) {
            $ValidationErrors += "No access_token in response from Microsoft identity platform."
        }
        elseif ($Response.token_type -ne "Bearer") {
            $ValidationErrors += "Unexpected token type: $($Response.token_type). Expected 'Bearer'."
        }
        if ($ValidationErrors.Count -gt 0) {
            $ResponseContent = ""
            try {
                $ResponseContent = $Response | ConvertTo-Json -Depth 5
            }
            catch {
                $ResponseContent = $Response
            }
            $ErrorMsg = "Token response validation failed: " + ($ValidationErrors -join " ") + " Response content: $ResponseContent"
            throw $ErrorMsg
        }

        Write-Verbose "Successfully acquired access token"
        Write-Verbose "Token type: $($Response.token_type)"
        Write-Verbose "Expires in: $($Response.expires_in) seconds"

        return $Response.access_token
    }
    catch {
        # Enhanced error handling
        $ErrorMessage = "Failed to acquire Azure DevOps access token: $($_.Exception.Message)"

        if ($_.Exception -is [System.Net.WebException]) {
            $Response = $_.Exception.Response
            if ($Response) {
                try {
                    $StreamReader = New-Object System.IO.StreamReader($Response.GetResponseStream())
                    $ErrorContent = $StreamReader.ReadToEnd()
                    $StreamReader.Close()

                    Write-Verbose "HTTP Error Response: $ErrorContent"

                    # Try to parse JSON error response
                    try {
                        $ErrorJson = $ErrorContent | ConvertFrom-Json
                        if ($ErrorJson.error_description) {
                            $ErrorMessage += " - $($ErrorJson.error_description)"
                        } elseif ($ErrorJson.error) {
                            $ErrorMessage += " - $($ErrorJson.error)"
                        }
                    }
                    catch {
                        # If JSON parsing fails, include raw content
                        $ErrorMessage += " - $ErrorContent"
                    }
                }
                catch {
                    Write-Verbose "Could not read error response stream"
                }
            }
        }

        Write-Verbose $ErrorMessage
        throw $ErrorMessage
    }
        finally {
            # Clear the plain text secret from memory
            if ($PlainSecret) {
                $PlainSecret = $null
            }
        }
    }

    end {
        Write-Verbose "Azure DevOps access token acquisition process completed"
    }
}