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

        It "Should have correct module information" {
            $Module = Get-Module AzureDevOps.Tools
            $Module.Name | Should -Be "AzureDevOps.Tools"
            $Module.Version | Should -Be "0.2.0"
        }
    }
}
