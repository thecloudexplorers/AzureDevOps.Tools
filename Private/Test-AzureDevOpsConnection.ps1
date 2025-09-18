function Test-AzureDevOpsConnection {
    <#
    .SYNOPSIS
        Tests connectivity to Azure DevOps REST API

    .DESCRIPTION
        Validates the Azure DevOps connection by making a test API call to retrieve organization information.
        This helps verify that the authentication and organization URI are correct.

    .PARAMETER OrganizationUri
        The Azure DevOps organization URI

    .PARAMETER AccessToken
        The Bearer access token for API authentication

    .OUTPUTS
        PSCustomObject with connection test results

    .NOTES
        Makes a call to the Projects API to validate connectivity
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrganizationUri,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    try {
        # Prepare headers for API call
        $Headers = @{
            'Authorization' = "Bearer $AccessToken"
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }

        # Test API endpoint - get projects (lightweight call)
        $ApiUri = "$($OrganizationUri.TrimEnd('/'))/_apis/projects?api-version=7.1"

        Write-Verbose "Testing connection to: $ApiUri"

        # Make test API call
        $Response = Invoke-RestMethod -Uri $ApiUri -Headers $Headers -Method Get -TimeoutSec 30

        # Parse organization name from URI
        $OrgName = ($OrganizationUri -split '/')[-1]

        $TestResult = [PSCustomObject]@{
            Success = $true
            OrganizationName = $OrgName
            OrganizationUri = $OrganizationUri
            ProjectCount = $Response.count
            ApiVersion = '7.1'
            TestTimestamp = Get-Date
        }

        Write-Verbose "Connection test successful - Organization: $OrgName, Projects: $($Response.count)"
        return $TestResult
    }
    catch {
        $ErrorMessage = "Azure DevOps API connection test failed: $($_.Exception.Message)"

        if ($_.Exception.Response) {
            $StatusCode = $_.Exception.Response.StatusCode
            $ErrorMessage += " (HTTP $StatusCode)"
        }

        Write-Verbose $ErrorMessage

        return [PSCustomObject]@{
            Success = $false
            Error = $ErrorMessage
            OrganizationUri = $OrganizationUri
            TestTimestamp = Get-Date
        }
    }
}