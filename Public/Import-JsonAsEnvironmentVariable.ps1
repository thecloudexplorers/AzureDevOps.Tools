function Import-JsonAsEnvironmentVariable {
    <#
    .SYNOPSIS
        Imports JSON file content as environment variables

    .DESCRIPTION
        Reads a JSON file and sets each key/value pair as environment variables. Nested objects
        are flattened using dot notation (e.g., parent.child).

        The function automatically detects if it's running in an Azure DevOps environment by
        checking for the System.CollectionUri environment variable:

        - If System.CollectionUri exists: Sets variables as Azure DevOps pipeline variables using
          the ##vso[task.setvariable] logging command. Variables are available to downstream tasks.

        - If System.CollectionUri is not set: Sets variables as standard PowerShell environment
          variables using Set-Item. Variables are available in the current PowerShell session.

    .PARAMETER Path
        The path to the JSON file to import. Must be a valid file path.

    .PARAMETER Prefix
        Optional prefix to add to all variable names. Useful for namespacing variables.

    .EXAMPLE
        Import-JsonAsEnvironmentVariable -Path './config.json'
        # Imports all key/value pairs from config.json as environment variables
        # Sets as Azure DevOps variables if running in a pipeline, otherwise as PowerShell env vars

    .EXAMPLE
        Import-JsonAsEnvironmentVariable -Path './settings.json' -Prefix 'APP_'
        # Imports all key/value pairs with APP_ prefix (e.g., APP_Version, APP_Environment)
        # Automatically detects environment and sets variables accordingly

    .EXAMPLE
        # Sample JSON file content:
        # {
        #   "Version": "1.0.0",
        #   "Environment": "Production",
        #   "Database": {
        #     "Server": "sql.example.com",
        #     "Port": 1433
        #   }
        # }
        #
        # Results in variables:
        # - Version = "1.0.0"
        # - Environment = "Production"
        # - Database.Server = "sql.example.com"
        # - Database.Port = 1433

    .OUTPUTS
        PSCustomObject with import results including variable count and names

    .NOTES
        Author: The Cloud Explorers
        Requires PowerShell 7.0 or later
        Automatically detects Azure DevOps environment via System.CollectionUri
        Version: 1.1.0
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Prefix = ''
    )

    begin {
        Write-Verbose "Starting JSON environment variable import"

        # Detect if running in Azure DevOps environment
        $IsAzureDevOps = -not [string]::IsNullOrEmpty($env:SYSTEM_COLLECTIONURI)

        if ($IsAzureDevOps) {
            Write-Verbose "Detected Azure DevOps environment (System.CollectionUri: $env:SYSTEM_COLLECTIONURI)"
            Write-Verbose "Variables will be set as Azure DevOps pipeline variables"
        }
        else {
            Write-Verbose "Not running in Azure DevOps environment"
            Write-Verbose "Variables will be set as PowerShell environment variables"
        }
    }

    process {
        try {
            # Validate file exists
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                throw "File not found: $Path"
            }

            Write-Verbose "Reading JSON file: $Path"

            # Read and parse JSON file
            $JsonContent = Get-Content -Path $Path -Raw -ErrorAction Stop
            $JsonObject = $JsonContent | ConvertFrom-Json -ErrorAction Stop

            if ($null -eq $JsonObject) {
                throw "JSON file is empty or invalid: $Path"
            }

            Write-Verbose "Successfully parsed JSON file"

            # Flatten JSON object and set environment variables
            $VariableCount = 0
            $VariableNames = @()

            $FlattenedVariables = ConvertTo-FlatHashtable -InputObject $JsonObject -Prefix $Prefix

            foreach ($Key in $FlattenedVariables.Keys) {
                $Value = $FlattenedVariables[$Key]

                # Convert value to string
                $StringValue = if ($null -eq $Value) {
                    ''
                }
                elseif ($Value -is [bool]) {
                    $Value.ToString().ToLower()
                }
                else {
                    $Value.ToString()
                }

                # Set variable based on environment
                if ($IsAzureDevOps) {
                    # Set Azure DevOps pipeline variable
                    Write-Host "##vso[task.setvariable variable=$Key]$StringValue"
                    Write-Verbose "Set Azure DevOps pipeline variable: $Key = $StringValue"
                }
                else {
                    # Set PowerShell environment variable
                    Set-Item -Path "env:$Key" -Value $StringValue -ErrorAction Stop
                    Write-Verbose "Set PowerShell environment variable: $Key = $StringValue"
                }

                $VariableCount++
                $VariableNames += $Key
            }

            # Create result object
            $Result = [PSCustomObject]@{
                Status        = 'Success'
                FilePath      = $Path
                VariableCount = $VariableCount
                VariableNames = $VariableNames
                Prefix        = $Prefix
                ImportedAt    = Get-Date
            }

            Write-Host "Successfully imported $VariableCount variable(s) from JSON file" -ForegroundColor Green

            return $Result
        }
        catch {
            $ErrorMessage = "Failed to import JSON as environment variables: $($_.Exception.Message)"
            Write-Error $ErrorMessage
            throw $_
        }
    }

    end {
        Write-Verbose "JSON environment variable import completed"
    }
}

function ConvertTo-FlatHashtable {
    <#
    .SYNOPSIS
        Flattens a nested object into a hashtable with dot notation keys

    .DESCRIPTION
        Recursively flattens a PSCustomObject or hashtable into a flat hashtable where
        nested properties are represented using dot notation (e.g., parent.child).

    .PARAMETER InputObject
        The object to flatten (PSCustomObject, Hashtable, or primitive value)

    .PARAMETER Prefix
        The current key prefix for nested properties

    .OUTPUTS
        Hashtable with flattened key/value pairs
    #>

    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [string]$Prefix = ''
    )

    $Result = @{}

    if ($null -eq $InputObject) {
        return $Result
    }

    # Handle different input types
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        # Convert PSCustomObject to hashtable
        $Properties = $InputObject.PSObject.Properties

        foreach ($Property in $Properties) {
            $Key = if ($Prefix) { "$Prefix.$($Property.Name)" } else { $Property.Name }
            $Value = $Property.Value

            if ($null -eq $Value) {
                $Result[$Key] = $null
            }
            elseif ($Value -is [System.Management.Automation.PSCustomObject] -or $Value -is [hashtable]) {
                # Recursively flatten nested objects
                $Nested = ConvertTo-FlatHashtable -InputObject $Value -Prefix $Key
                foreach ($NestedKey in $Nested.Keys) {
                    $Result[$NestedKey] = $Nested[$NestedKey]
                }
            }
            elseif ($Value -is [array]) {
                # Arrays are converted to JSON string representation
                $Result[$Key] = ($Value | ConvertTo-Json -Compress -Depth 10)
            }
            else {
                # Primitive value
                $Result[$Key] = $Value
            }
        }
    }
    elseif ($InputObject -is [hashtable]) {
        # Handle hashtable input
        foreach ($Key in $InputObject.Keys) {
            $FullKey = if ($Prefix) { "$Prefix.$Key" } else { $Key }
            $Value = $InputObject[$Key]

            if ($null -eq $Value) {
                $Result[$FullKey] = $null
            }
            elseif ($Value -is [System.Management.Automation.PSCustomObject] -or $Value -is [hashtable]) {
                # Recursively flatten nested objects
                $Nested = ConvertTo-FlatHashtable -InputObject $Value -Prefix $FullKey
                foreach ($NestedKey in $Nested.Keys) {
                    $Result[$NestedKey] = $Nested[$NestedKey]
                }
            }
            elseif ($Value -is [array]) {
                # Arrays are converted to JSON string representation
                $Result[$FullKey] = ($Value | ConvertTo-Json -Compress -Depth 10)
            }
            else {
                # Primitive value
                $Result[$FullKey] = $Value
            }
        }
    }
    else {
        # Single primitive value
        $Result[$Prefix] = $InputObject
    }

    return $Result
}
