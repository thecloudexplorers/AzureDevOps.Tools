#Requires -Module Pester

Describe "AzureDevOps.Tools Module Tests" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot ".." "AzureDevOps.Tools.psd1"
        Import-Module $ModulePath -Force
    }

    AfterAll {
        Remove-Module AzureDevOps.Tools -Force -ErrorAction SilentlyContinue
    }

    Context "Module Import" {
        It "Should import without errors" {
            { Import-Module $ModulePath -Force } | Should -Not -Throw
        }
    }
}
