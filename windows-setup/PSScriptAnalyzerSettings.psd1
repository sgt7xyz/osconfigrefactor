# ---------------------------------------------------------------
# File:     PSScriptAnalyzerSettings.psd1
# Purpose:  PSScriptAnalyzer rules, including Windows PowerShell 5.1 compatibility checks
# Project:  windows-setup-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

@{
    # Windows 11 ships Windows PowerShell 5.1, so every script must parse and run there.
    # The win-48 profile (Windows 10 1809 desktop, 5.1) is the newest 5.1 profile PSScriptAnalyzer
    # ships, and Windows 11 uses the same 5.1 build line.
    Rules        = @{
        PSUseCompatibleSyntax   = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
        PSUseCompatibleCommands = @{
            Enable         = $true
            TargetProfiles = @('win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework')
            # NOTE: -Type on Set-ItemProperty is a dynamic parameter added by the Registry provider.
            # It works in 5.1, but the analyzer only sees static parameters and flags every use.
            IgnoreCommands = @('Set-ItemProperty')
        }
        PSUseCompatibleTypes    = @{
            Enable         = $true
            TargetProfiles = @('win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework')
        }
    }

    ExcludeRules = @(
        # These are interactive menu scripts. Colored console output is the point, not pipeline data.
        'PSAvoidUsingWriteHost',
        # Function names are the menu's public names and appear in the docs and the maintenance script.
        'PSUseSingularNouns',
        # Every state change is confirmed through the menu, so -WhatIf and -Confirm add nothing here.
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
