# ============================================

# SMBIOS Manager - Safety Checks

# ============================================

function Test-SMBIOSSafety {

$blockedProcesses = @{
    "Easy Anti-Cheat" = @(
        "EasyAntiCheat"
        "EasyAntiCheat_EOS"
    )

    "BattlEye" = @(
        "BEService"
        "BEService_x64"
    )

    "Vanguard" = @(
        "vgc"
        "vgtray"
    )

    "FACEIT Anti-Cheat" = @(
        "faceit"
        "faceitservice"
    )

    "Steam" = @(
        "steam"
    )

    "BState Game Launcher" = @(
        "BStateGameLauncher"
        "BStateGame"
        "BsgLauncher"
    )
}

$detected = @()

foreach ($category in $blockedProcesses.Keys) {

    foreach ($processName in $blockedProcesses[$category]) {

        try {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

            if ($processes) {

                $detected += [PSCustomObject]@{
                    Category = $category
                    Process  = $processName
                }
            }
        }
        catch {
            # Ignore processes that disappear during the check.
        }
    }
}

if ($detected.Count -eq 0) {
    return $true
}

Write-Host ""
Write-Host "============================================"
Write-Host "             SAFETY CHECK FAILED"
Write-Host "============================================"
Write-Host ""
Write-Host "The following applications are currently running:"
Write-Host ""

foreach ($item in $detected) {
    Write-Host "  [$($item.Category)] $($item.Process)"
}

Write-Host ""
Write-Host "Please close the detected applications before"
Write-Host "continuing with the SMBIOS operation."
Write-Host ""

return $false

}
