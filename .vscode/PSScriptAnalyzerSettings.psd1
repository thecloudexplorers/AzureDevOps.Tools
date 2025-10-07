@{
    # Allow for Azure DevOps logging patterns but enforce other standards
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'        # Allow Write-Host for Azure DevOps logging
        'PSUseSingularNouns'           # Allow 'DevOps' in function names as it's a proper noun
    )

    # Rules configuration for continuous analysis
    Rules = @{
        # Core PowerShell best practices
        "PSAvoidUsingCmdletAliases"        = @{ Enable = $true }
        "PSUseCmdletCorrectCasing"         = @{ Enable = $true }
        "PSUseApprovedVerbs"               = @{ Enable = $true }
        "PSUseCorrectCasing"               = @{ Enable = $true }
        "PSAvoidUsingBackticks"            = @{ Enable = $true }
        "PSAvoidUsingPositionalParameters" = @{ Enable = $true }
        "PSAvoidGlobalVars"                = @{ Enable = $true }

        # Formatting and style
        "PSUseConsistentIndentation"       = @{
            Enable = $true
            Options = @{
                Kind = 'space'
                IndentationSize = 4
                PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            }
        }
        "PSUseConsistentWhitespace"        = @{
            Enable = $true
            Options = @{
                CheckInnerBrace = $true
                CheckOpenBrace = $true
                CheckOpenParen = $true
                CheckOperator = $true
                CheckPipe = $true
                CheckPipeForRedundantWhitespace = $false
                CheckSeparator = $true
                CheckParameter = $false
            }
        }
        "PSAvoidTrailingWhitespace"        = @{ Enable = $true }

        # Line length enforcement
        "PSAvoidLongLines"                 = @{
            Enable = $true
            Options = @{ MaximumLineLength = 120 }
        }

        # Documentation requirements
        "PSProvideCommentHelp"             = @{
            Enable = $true
            Options = @{
                BlockComment = $true
                ExportedOnly = $true
                Placement = 'before'
            }
        }

        # Security and best practices
        "PSAvoidUsingConvertToSecureStringWithPlainText" = @{ Enable = $true }
        "PSUsePSCredentialType"            = @{ Enable = $true }
        "PSAvoidUsingUsernameAndPasswordParams" = @{ Enable = $true }
        "PSAvoidUsingPlainTextForPassword" = @{ Enable = $true }

        # Performance
        "PSUseShouldProcessForStateChangingFunctions" = @{ Enable = $true }
        "PSUseDeclaredVarsMoreThanAssignments" = @{ Enable = $true }
    }

    # Severity levels
    Severity = @('Warning', 'Error', 'Information')
}
