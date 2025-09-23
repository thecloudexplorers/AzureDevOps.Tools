function Get-AzureDevOpsConnectionStore {
    <#
    .SYNOPSIS
        Securely retrieves Azure DevOps connection information from private storage

    .DESCRIPTION
        Provides controlled access to stored Azure DevOps connection details.
        This function encapsulates the retrieval mechanism and prevents direct
        access to the underlying storage, enhancing security and maintainability.

    .OUTPUTS
        Hashtable containing connection information, or $null if no connection exists

    .NOTES
        This is a private function that encapsulates connection retrieval for security.
        Direct access to script-scoped variables is prevented through this abstraction.
    #>

    [CmdletBinding()]
    param()

    begin {
        Write-Verbose "Retrieving Azure DevOps connection information from secure storage"
    }

    process {
        try {
            # Check if connection information exists
            if ($null -eq $script:AzureDevOpsConnection) {
                Write-Verbose "No existing connection found"
                return $null
            }

            # Validate stored connection has required properties
            $RequiredProperties = @('OrganizationUri', 'AccessToken', 'TokenExpiry', 'TenantId', 'ClientId')
            foreach ($Property in $RequiredProperties) {
                if (-not $script:AzureDevOpsConnection.ContainsKey($Property)) {
                    Write-Warning "Stored connection is missing required property '$Property'. Clearing connection."
                    $script:AzureDevOpsConnection = $null
                    return $null
                }
            }

            # Check if token is still valid (allow 5 minute buffer)
            if ($script:AzureDevOpsConnection.TokenExpiry -le (Get-Date).AddMinutes(5)) {
                Write-Verbose "Stored connection has expired token. Connection needs refresh."
                $script:AzureDevOpsConnection = $null
                return $null
            }

            # Return a defensive copy to prevent external modification of stored data
            $ClonedConnection = @{}
            foreach ($Key in $script:AzureDevOpsConnection.Keys) {
                if ($Key -eq 'ParameterSource' -and $script:AzureDevOpsConnection[$Key] -is [hashtable]) {
                    # Clone nested hashtable
                    $ClonedConnection[$Key] = $script:AzureDevOpsConnection[$Key].Clone()
                } else {
                    $ClonedConnection[$Key] = $script:AzureDevOpsConnection[$Key]
                }
            }

            Write-Verbose "Retrieved valid connection information"
            return $ClonedConnection
        }
        catch {
            Write-Error "Failed to retrieve connection information: $($_.Exception.Message)"
            # Clear potentially corrupted connection
            $script:AzureDevOpsConnection = $null
            return $null
        }
    }

    end {
        Write-Verbose "Connection retrieval process completed"
    }
}