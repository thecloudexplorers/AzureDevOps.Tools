#Requires -Module Pester

Describe "Import-JsonAsEnvironmentVariable Function Tests" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot ".." "AzureDevOps.Tools.psd1"
        Import-Module $ModulePath -Force

        # Create temporary directory for test files
        $TestDir = Join-Path $TestDrive "JsonTests"
        New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        Remove-Module AzureDevOps.Tools -Force -ErrorAction SilentlyContinue
    }

    Context "Parameter Validation" {
        It "Should require Path parameter" {
            (Get-Command Import-JsonAsEnvironmentVariable).Parameters['Path'].Attributes.Mandatory | Should -Be $true
        }

        It "Should not accept null or empty Path" {
            { Import-JsonAsEnvironmentVariable -Path $null -ErrorAction Stop } | Should -Throw
            { Import-JsonAsEnvironmentVariable -Path '' -ErrorAction Stop } | Should -Throw
        }

        It "Should throw error if file does not exist" {
            $NonExistentPath = Join-Path $TestDir "nonexistent.json"
            { Import-JsonAsEnvironmentVariable -Path $NonExistentPath -ErrorAction Stop } | Should -Throw "*File not found*"
        }
    }

    Context "Valid JSON File Processing" {
        It "Should import simple JSON file with string values in POSIX convention" {
            $JsonPath = Join-Path $TestDir "simple.json"
            @{
                Version     = "1.0.0"
                Environment = "Production"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
            $Result.VariableNames | Should -Contain 'VERSION'
            $Result.VariableNames | Should -Contain 'ENVIRONMENT'
        }

        It "Should import JSON file with numeric values in POSIX convention" {
            $JsonPath = Join-Path $TestDir "numeric.json"
            @{
                Port           = 8080
                MaxConnections = 100
                Timeout        = 30.5
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 3
            $Result.VariableNames | Should -Contain 'PORT'
            $Result.VariableNames | Should -Contain 'MAXCONNECTIONS'
            $Result.VariableNames | Should -Contain 'TIMEOUT'
        }

        It "Should import JSON file with boolean values in POSIX convention" {
            $JsonPath = Join-Path $TestDir "boolean.json"
            @{
                EnableFeature = $true
                DebugMode     = $false
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
            $Result.VariableNames | Should -Contain 'ENABLEFEATURE'
            $Result.VariableNames | Should -Contain 'DEBUGMODE'
        }

        It "Should flatten nested JSON objects and convert to POSIX convention" {
            $JsonPath = Join-Path $TestDir "nested.json"
            @{
                Application = @{
                    Name    = "MyApp"
                    Version = "2.0.0"
                }
                Database    = @{
                    Server      = "sql.example.com"
                    Port        = 1433
                    Credentials = @{
                        Username = "admin"
                    }
                }
            } | ConvertTo-Json -Depth 10 | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 5
            $Result.VariableNames | Should -Contain 'APPLICATION_NAME'
            $Result.VariableNames | Should -Contain 'APPLICATION_VERSION'
            $Result.VariableNames | Should -Contain 'DATABASE_SERVER'
            $Result.VariableNames | Should -Contain 'DATABASE_PORT'
            $Result.VariableNames | Should -Contain 'DATABASE_CREDENTIALS_USERNAME'
        }

        It "Should handle JSON with array values as JSON strings in POSIX convention" {
            $JsonPath = Join-Path $TestDir "array.json"
            @{
                Tags  = @("production", "web", "api")
                Ports = @(80, 443, 8080)
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
            $Result.VariableNames | Should -Contain 'TAGS'
            $Result.VariableNames | Should -Contain 'PORTS'
        }

        It "Should apply prefix to variable names when specified in POSIX convention" {
            $JsonPath = Join-Path $TestDir "prefix.json"
            @{
                Name    = "TestApp"
                Version = "1.0"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath -Prefix "APP_"

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
            # Prefix "APP_" + "Name" becomes "APP_.Name" which converts to "APP__NAME"
            $Result.VariableNames | Should -Contain 'APP__NAME'
            $Result.VariableNames | Should -Contain 'APP__VERSION'
            $Result.Prefix | Should -Be 'APP_'
        }

        It "Should handle JSON with null values in POSIX convention" {
            $JsonPath = Join-Path $TestDir "null.json"
            '{"Key1": "value1", "Key2": null, "Key3": "value3"}' | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 3
            $Result.VariableNames | Should -Contain 'KEY1'
            $Result.VariableNames | Should -Contain 'KEY2'
            $Result.VariableNames | Should -Contain 'KEY3'
        }

        It "Should handle JSON with special characters in values in POSIX convention" {
            $JsonPath = Join-Path $TestDir "special.json"
            @{
                Message = "Hello, World!"
                Path    = "C:\Program Files\App"
                Url     = "https://example.com/api?key=value&token=abc123"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 3
            $Result.VariableNames | Should -Contain 'MESSAGE'
            $Result.VariableNames | Should -Contain 'PATH'
            $Result.VariableNames | Should -Contain 'URL'
        }
    }

    Context "Invalid JSON File Handling" {
        It "Should throw error for invalid JSON syntax" {
            $JsonPath = Join-Path $TestDir "invalid.json"
            '{ "key": "value", invalid }' | Set-Content -Path $JsonPath

            { Import-JsonAsEnvironmentVariable -Path $JsonPath -ErrorAction Stop } | Should -Throw
        }

        It "Should throw error for empty file" {
            $JsonPath = Join-Path $TestDir "empty.json"
            '' | Set-Content -Path $JsonPath

            { Import-JsonAsEnvironmentVariable -Path $JsonPath -ErrorAction Stop } | Should -Throw
        }

        It "Should handle empty JSON object" {
            $JsonPath = Join-Path $TestDir "emptyobject.json"
            '{}' | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 0
        }
    }

    Context "Environment Detection and Variable Setting" {
        BeforeEach {
            # Store original SYSTEM_COLLECTIONURI value
            $script:OriginalCollectionUri = $env:SYSTEM_COLLECTIONURI
        }

        AfterEach {
            # Restore original SYSTEM_COLLECTIONURI value
            if ($null -ne $script:OriginalCollectionUri) {
                $env:SYSTEM_COLLECTIONURI = $script:OriginalCollectionUri
            }
            else {
                Remove-Item Env:\SYSTEM_COLLECTIONURI -ErrorAction SilentlyContinue
            }

            # Clean up test environment variables
            Remove-Item Env:\BuildNumber -ErrorAction SilentlyContinue
            Remove-Item Env:\Environment -ErrorAction SilentlyContinue
            Remove-Item Env:\TestVar1 -ErrorAction SilentlyContinue
            Remove-Item Env:\TestVar2 -ErrorAction SilentlyContinue
        }

        It "Should detect Azure DevOps environment when SYSTEM_COLLECTIONURI is set" {
            $JsonPath = Join-Path $TestDir "ado-detection.json"
            @{ TestVar = "TestValue" } | ConvertTo-Json | Set-Content -Path $JsonPath

            # Simulate Azure DevOps environment
            $env:SYSTEM_COLLECTIONURI = "https://dev.azure.com/myorg/"

            # Capture verbose output
            $VerboseOutput = Import-JsonAsEnvironmentVariable -Path $JsonPath -Verbose 4>&1

            $VerboseMessages = $VerboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | ForEach-Object { $_.Message }
            $VerboseMessages -join "`n" | Should -Match "Detected Azure DevOps environment"
            $VerboseMessages -join "`n" | Should -Match "Variables will be set as Azure DevOps pipeline variables"
        }

        It "Should detect non-Azure DevOps environment when SYSTEM_COLLECTIONURI is not set" {
            $JsonPath = Join-Path $TestDir "local-detection.json"
            @{ TestVar = "TestValue" } | ConvertTo-Json | Set-Content -Path $JsonPath

            # Ensure SYSTEM_COLLECTIONURI is not set
            Remove-Item Env:\SYSTEM_COLLECTIONURI -ErrorAction SilentlyContinue

            # Capture verbose output
            $VerboseOutput = Import-JsonAsEnvironmentVariable -Path $JsonPath -Verbose 4>&1

            $VerboseMessages = $VerboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | ForEach-Object { $_.Message }
            $VerboseMessages -join "`n" | Should -Match "Not running in Azure DevOps environment"
            $VerboseMessages -join "`n" | Should -Match "Variables will be set as PowerShell environment variables"
        }

        It "Should output Azure DevOps variable commands when in Azure DevOps environment" {
            $JsonPath = Join-Path $TestDir "ado-output.json"
            @{
                BuildNumber = "1.2.3"
                Environment = "Staging"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            # Simulate Azure DevOps environment
            $env:SYSTEM_COLLECTIONURI = "https://dev.azure.com/myorg/"

            # Capture Write-Host output
            $Output = Import-JsonAsEnvironmentVariable -Path $JsonPath *>&1 | Where-Object { $_ -is [string] -or $_.GetType().Name -eq 'InformationRecord' }

            # Check for Azure DevOps variable syntax
            $HostOutput = ($Output | Where-Object { $_ -match '##vso\[task\.setvariable' }) -join "`n"
            $HostOutput | Should -Match '##vso\[task\.setvariable variable=BuildNumber\]1\.2\.3'
            $HostOutput | Should -Match '##vso\[task\.setvariable variable=Environment\]Staging'
        }

        It "Should set PowerShell environment variables when not in Azure DevOps environment" {
            $JsonPath = Join-Path $TestDir "powershell-vars.json"
            @{
                TestVar1 = "Value1"
                TestVar2 = "Value2"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            # Ensure SYSTEM_COLLECTIONURI is not set
            Remove-Item Env:\SYSTEM_COLLECTIONURI -ErrorAction SilentlyContinue

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            # Verify variables were set in PowerShell environment
            $env:TestVar1 | Should -Be "Value1"
            $env:TestVar2 | Should -Be "Value2"
            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
        }

        It "Should not set PowerShell environment variables when in Azure DevOps environment" {
            $JsonPath = Join-Path $TestDir "ado-no-env.json"
            @{
                TestVar1 = "Value1"
                TestVar2 = "Value2"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            # Simulate Azure DevOps environment
            $env:SYSTEM_COLLECTIONURI = "https://dev.azure.com/myorg/"

            # Clear any existing test variables
            Remove-Item Env:\TestVar1 -ErrorAction SilentlyContinue
            Remove-Item Env:\TestVar2 -ErrorAction SilentlyContinue

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            # Verify variables were NOT set in PowerShell environment (only Azure DevOps output)
            $env:TestVar1 | Should -BeNullOrEmpty
            $env:TestVar2 | Should -BeNullOrEmpty
            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
        }

        It "Should include correct verbose messages for Azure DevOps variable setting" {
            $JsonPath = Join-Path $TestDir "ado-verbose.json"
            @{ TestKey = "TestValue" } | ConvertTo-Json | Set-Content -Path $JsonPath

            # Simulate Azure DevOps environment
            $env:SYSTEM_COLLECTIONURI = "https://dev.azure.com/myorg/"

            # Capture verbose output
            $VerboseOutput = Import-JsonAsEnvironmentVariable -Path $JsonPath -Verbose 4>&1

            $VerboseMessages = $VerboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | ForEach-Object { $_.Message }
            $VerboseMessages -join "`n" | Should -Match "Set Azure DevOps pipeline variable: TestKey"
        }

        It "Should include correct verbose messages for PowerShell variable setting" {
            $JsonPath = Join-Path $TestDir "ps-verbose.json"
            @{ TestKey = "TestValue" } | ConvertTo-Json | Set-Content -Path $JsonPath

            # Ensure SYSTEM_COLLECTIONURI is not set
            Remove-Item Env:\SYSTEM_COLLECTIONURI -ErrorAction SilentlyContinue

            # Capture verbose output
            $VerboseOutput = Import-JsonAsEnvironmentVariable -Path $JsonPath -Verbose 4>&1

            $VerboseMessages = $VerboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | ForEach-Object { $_.Message }
            $VerboseMessages -join "`n" | Should -Match "Set PowerShell environment variable: TestKey"
        }
    }

    Context "Function Behavior" {
        It "Should have proper help documentation" {
            $Help = Get-Help Import-JsonAsEnvironmentVariable -Full
            $Help.Synopsis | Should -Not -BeNullOrEmpty
            $Help.Description | Should -Not -BeNullOrEmpty
            $Help.Examples.Count | Should -BeGreaterThan 0
        }

        It "Should support -Verbose parameter" {
            (Get-Command Import-JsonAsEnvironmentVariable).Parameters.ContainsKey('Verbose') | Should -Be $true
        }

        It "Should return ImportedAt timestamp" {
            $JsonPath = Join-Path $TestDir "timestamp.json"
            @{ Key = "Value" } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.ImportedAt | Should -Not -BeNullOrEmpty
            $Result.ImportedAt | Should -BeOfType [DateTime]
        }

        It "Should include file path in result" {
            $JsonPath = Join-Path $TestDir "filepath.json"
            @{ Key = "Value" } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.FilePath | Should -Be $JsonPath
        }
    }

    Context "Edge Cases" {
        It "Should handle deeply nested objects in POSIX convention" {
            $JsonPath = Join-Path $TestDir "deep.json"
            @{
                Level1 = @{
                    Level2 = @{
                        Level3 = @{
                            Level4 = @{
                                Value = "DeepValue"
                            }
                        }
                    }
                }
            } | ConvertTo-Json -Depth 10 | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableNames | Should -Contain 'LEVEL1_LEVEL2_LEVEL3_LEVEL4_VALUE'
        }

        It "Should handle JSON with mixed types" {
            $JsonPath = Join-Path $TestDir "mixed.json"
            @{
                StringValue = "text"
                NumberValue = 42
                BoolValue   = $true
                NullValue   = $null
                ArrayValue  = @(1, 2, 3)
                ObjectValue = @{ Nested = "value" }
            } | ConvertTo-Json -Depth 10 | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 6
        }

        It "Should handle large JSON files" {
            $JsonPath = Join-Path $TestDir "large.json"
            $LargeObject = @{}
            for ($i = 1; $i -le 100; $i++) {
                $LargeObject["Key$i"] = "Value$i"
            }
            $LargeObject | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 100
        }
    }
}
