function Clear-AzureDevOpsConnectionStore {
    <#
    .SYNOPSIS
        Securely clears stored Azure DevOps connection information

    .DESCRIPTION
        Provides a controlled way to clear stored connection information,
        including sensitive tokens. This function ensures proper cleanup
        of connection data when needed.

    .NOTES
        This is a private function that encapsulates connection cleanup for security.
        Helps prevent token leakage by providing explicit cleanup mechanism.
    #>

    [CmdletBinding()]
    param()

    begin {
        Write-Verbose "Clearing Azure DevOps connection information from secure storage"
    }

    process {
        try {
            if ($null -ne $script:AzureDevOpsConnection) {
                # Clear the connection information
                $script:AzureDevOpsConnection = $null
                Write-Verbose "Connection information cleared successfully"
            } else {
                Write-Verbose "No connection information to clear"
            }
        }
        catch {
            Write-Error "Failed to clear connection information: $($_.Exception.Message)"
            # Force clear even if there was an error
            $script:AzureDevOpsConnection = $null
            throw $_
        }
    }

    end {
        Write-Verbose "Connection cleanup process completed"
    }
}