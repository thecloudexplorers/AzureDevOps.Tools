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
        It "Should import simple JSON file with string values" {
            $JsonPath = Join-Path $TestDir "simple.json"
            @{
                Version = "1.0.0"
                Environment = "Production"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
            $Result.VariableNames | Should -Contain 'Version'
            $Result.VariableNames | Should -Contain 'Environment'
        }

        It "Should import JSON file with numeric values" {
            $JsonPath = Join-Path $TestDir "numeric.json"
            @{
                Port = 8080
                MaxConnections = 100
                Timeout = 30.5
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 3
            $Result.VariableNames | Should -Contain 'Port'
            $Result.VariableNames | Should -Contain 'MaxConnections'
            $Result.VariableNames | Should -Contain 'Timeout'
        }

        It "Should import JSON file with boolean values" {
            $JsonPath = Join-Path $TestDir "boolean.json"
            @{
                EnableFeature = $true
                DebugMode = $false
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
            $Result.VariableNames | Should -Contain 'EnableFeature'
            $Result.VariableNames | Should -Contain 'DebugMode'
        }

        It "Should flatten nested JSON objects with dot notation" {
            $JsonPath = Join-Path $TestDir "nested.json"
            @{
                Application = @{
                    Name = "MyApp"
                    Version = "2.0.0"
                }
                Database = @{
                    Server = "sql.example.com"
                    Port = 1433
                    Credentials = @{
                        Username = "admin"
                    }
                }
            } | ConvertTo-Json -Depth 10 | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 5
            $Result.VariableNames | Should -Contain 'Application.Name'
            $Result.VariableNames | Should -Contain 'Application.Version'
            $Result.VariableNames | Should -Contain 'Database.Server'
            $Result.VariableNames | Should -Contain 'Database.Port'
            $Result.VariableNames | Should -Contain 'Database.Credentials.Username'
        }

        It "Should handle JSON with array values as JSON strings" {
            $JsonPath = Join-Path $TestDir "array.json"
            @{
                Tags = @("production", "web", "api")
                Ports = @(80, 443, 8080)
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
            $Result.VariableNames | Should -Contain 'Tags'
            $Result.VariableNames | Should -Contain 'Ports'
        }

        It "Should apply prefix to variable names when specified" {
            $JsonPath = Join-Path $TestDir "prefix.json"
            @{
                Name = "TestApp"
                Version = "1.0"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath -Prefix "APP_"

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 2
            $Result.VariableNames | Should -Contain 'APP_.Name'
            $Result.VariableNames | Should -Contain 'APP_.Version'
            $Result.Prefix | Should -Be 'APP_'
        }

        It "Should handle JSON with null values" {
            $JsonPath = Join-Path $TestDir "null.json"
            '{"Key1": "value1", "Key2": null, "Key3": "value3"}' | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 3
            $Result.VariableNames | Should -Contain 'Key1'
            $Result.VariableNames | Should -Contain 'Key2'
            $Result.VariableNames | Should -Contain 'Key3'
        }

        It "Should handle JSON with special characters in values" {
            $JsonPath = Join-Path $TestDir "special.json"
            @{
                Message = "Hello, World!"
                Path = "C:\Program Files\App"
                Url = "https://example.com/api?key=value&token=abc123"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            $Result = Import-JsonAsEnvironmentVariable -Path $JsonPath

            $Result.Status | Should -Be 'Success'
            $Result.VariableCount | Should -Be 3
            $Result.VariableNames | Should -Contain 'Message'
            $Result.VariableNames | Should -Contain 'Path'
            $Result.VariableNames | Should -Contain 'Url'
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

    Context "Azure DevOps Variable Output" {
        It "Should output Azure DevOps variable setting commands" {
            $JsonPath = Join-Path $TestDir "ado.json"
            @{
                BuildNumber = "1.2.3"
                Environment = "Staging"
            } | ConvertTo-Json | Set-Content -Path $JsonPath

            # Capture Write-Host output
            $Output = Import-JsonAsEnvironmentVariable -Path $JsonPath *>&1 | Where-Object { $_ -is [string] -or $_.GetType().Name -eq 'InformationRecord' }

            # Check for Azure DevOps variable syntax
            $HostOutput = ($Output | Where-Object { $_ -match '##vso\[task\.setvariable' }) -join "`n"
            $HostOutput | Should -Match '##vso\[task\.setvariable variable=BuildNumber\]1\.2\.3'
            $HostOutput | Should -Match '##vso\[task\.setvariable variable=Environment\]Staging'
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
        It "Should handle deeply nested objects" {
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
            $Result.VariableNames | Should -Contain 'Level1.Level2.Level3.Level4.Value'
        }

        It "Should handle JSON with mixed types" {
            $JsonPath = Join-Path $TestDir "mixed.json"
            @{
                StringValue = "text"
                NumberValue = 42
                BoolValue = $true
                NullValue = $null
                ArrayValue = @(1, 2, 3)
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
