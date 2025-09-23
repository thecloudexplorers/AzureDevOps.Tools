function Set-AzureDevOpsConnectionStore {
    <#
    .SYNOPSIS
        Securely stores Azure DevOps connection information in a private scope

    .DESCRIPTION
        Encapsulates the storage of Azure DevOps connection details including sensitive
        access tokens in a secure, private manner. This function provides a controlled
        interface to store connection information while preventing direct access to
        the underlying storage mechanism.

    .PARAMETER ConnectionInfo
        Hashtable containing the connection information to store

    .NOTES
        This is a private function that encapsulates connection storage for security.
        Direct access to script-scoped variables is prevented through this abstraction.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$ConnectionInfo
    )

    begin {
        Write-Verbose "Storing Azure DevOps connection information securely"
    }

    process {
        try {
            # Validate required connection properties
            $RequiredProperties = @('OrganizationUri', 'AccessToken', 'TokenExpiry', 'TenantId', 'ClientId')
            foreach ($Property in $RequiredProperties) {
                if (-not $ConnectionInfo.ContainsKey($Property) -or [string]::IsNullOrEmpty($ConnectionInfo[$Property])) {
                    throw "Connection information must contain a valid '$Property' property"
                }
            }

            # Validate token expiry is in the future
            if ($ConnectionInfo.TokenExpiry -le (Get-Date)) {
                throw "Token expiry must be in the future"
            }

            # Store connection information in private script scope
            $script:AzureDevOpsConnection = $ConnectionInfo.Clone()
            Write-Verbose "Connection information stored successfully"
        }
        catch {
            Write-Error "Failed to store connection information: $($_.Exception.Message)"
            throw $_
        }
    }

    end {
        Write-Verbose "Connection storage process completed"
    }
}