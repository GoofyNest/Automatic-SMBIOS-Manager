# ============================================
# Automatic SMBIOS Manager
# Main Entry Point
# ============================================

$ErrorActionPreference = "Stop"

# ============================================
# Module directory
# ============================================

$moduleDirectory = Join-Path $PSScriptRoot "Modules"

# ============================================
# Load modules
# ============================================

$modules = @(
    "Config.ps1"
    "HardwareDetection.ps1"
    "UI.ps1"
    "Backup.ps1"
    "Restore.ps1"
    "Generator.ps1"
    "Safety.ps1"
)

foreach ($module in $modules) {

    $modulePath = Join-Path $moduleDirectory $module

    if (-not (Test-Path $modulePath)) {

        Write-Host ""
        Write-Host "[ERROR] Missing module:"
        Write-Host "  $modulePath"
        Write-Host ""

        exit 1
    }

    . $modulePath
}

# ============================================
# Startup
# ============================================

Clear-Host

Write-Host ""
Write-Host "============================================"
Write-Host "       Automatic SMBIOS Manager"
Write-Host "============================================"
Write-Host ""

Write-Host "Modules loaded successfully."
Write-Host ""

if (-not (Test-SMBIOSSafety)) {
    Write-Host ""
    Write-Host "Operation cancelled."
    Write-Host ""
    exit 0
}

# ============================================
# Main UI
# ============================================

$uiResult = Show-SMBIOSMainUI

if (-not $uiResult) {

    Write-Host ""
    Write-Host "Operation cancelled."
    Write-Host ""

    exit 0
}

# ============================================
# Display selected action
# ============================================

Write-Host ""
Write-Host "Selected action:"
Write-Host "  $($uiResult.Action)"
Write-Host ""

# ============================================
# Restore
# ============================================

if ($uiResult.Action -eq "Restore") {

    Write-Host "Restore mode selected."
    Write-Host ""

    $restoreFile = Select-SMBIOSBackup

    if (-not $restoreFile) {

        Write-Host ""
        Write-Host "SMBIOS restore cancelled."
        Write-Host ""

        exit 0
    }

    Invoke-SMBIOSRestore -BackupPath $restoreFile

    Write-Host ""
    Write-Host "WARNING: RESTART YOUR PC AFTER RESTORING SMBIOS!"
    Write-Host ""

    exit 0
}

# ============================================
# Spoof / Generate
# ============================================

if ($uiResult.Action -eq "Spoof") {

    Write-Host "Spoof mode selected."
    Write-Host ""

    Write-Host "Manufacturer: $($uiResult.Manufacturer)"
    Write-Host "Platform:     $($uiResult.Platform)"
    Write-Host "Memory:       $($uiResult.Memory)"
    Write-Host "Product:      $($uiResult.Product)"
    Write-Host ""

    # ========================================
    # Convert UI values
    # ========================================

    $Platform = $null
    $MoboManufacturer = $null
    $Memory = $null
    $ProductName = $null

    if (
        -not [string]::IsNullOrWhiteSpace($uiResult.Manufacturer) -and
        $uiResult.Manufacturer -ne "Any"
    ) {

        $MoboManufacturer =
            $uiResult.Manufacturer.ToLower()
    }

    if (
        -not [string]::IsNullOrWhiteSpace($uiResult.Platform) -and
        $uiResult.Platform -ne "Any"
    ) {

        $Platform =
            $uiResult.Platform.ToLower()
    }

    if (-not [string]::IsNullOrWhiteSpace($uiResult.Memory)) {

        $Memory =
            $uiResult.Memory.ToLower()
    }

    if (-not [string]::IsNullOrWhiteSpace($uiResult.Product)) {

        $ProductName =
            $uiResult.Product
    }

    # ========================================
    # Generate SMBIOS profile
    # ========================================

    if (-not (Get-Command New-SMBIOSProfile -ErrorAction SilentlyContinue)) {

        Write-Host ""
        Write-Host "[ERROR] New-SMBIOSProfile was not loaded."
        Write-Host ""
        Write-Host "Make sure Generator.ps1 contains:"
        Write-Host "  function New-SMBIOSProfile"
        Write-Host ""

        exit 1
    }

    $profile = New-SMBIOSProfile `
        -Platform $Platform `
        -MoboManufacturer $MoboManufacturer `
        -Memory $Memory `
        -ProductName $ProductName

    if (-not $profile) {

        Write-Host ""
        Write-Host "[ERROR] Failed to generate SMBIOS profile."
        Write-Host ""

        exit 1
    }

    $board = $profile.Board

    # ========================================
    # Display generated profile
    # ========================================

    Write-Host ""
    Write-Host "============================================"
    Write-Host "          GENERATED SMBIOS PROFILE"
    Write-Host "============================================"
    Write-Host ""

    Write-Host "Motherboard:"
    Write-Host "  Manufacturer : $($profile.Mobo.Manufacturer)"
    Write-Host "  Product      : $($profile.Mobo.ProductName)"
    Write-Host "  Socket       : $($profile.Mobo.Socket)"
    Write-Host "  Generation   : $($profile.Mobo.Generation)"
    Write-Host ""

    Write-Host "BIOS:"
    Write-Host "  Vendor       : $($board.biosVendor)"
    Write-Host "  Version      : $($board.biosVersion)"
    Write-Host "  Date         : $($board.biosDate)"
    Write-Host ""

    Write-Host "System:"
    Write-Host "  Manufacturer : $($board.SystemManufacturer)"
    Write-Host "  Product      : $($board.SystemProductName)"
    Write-Host "  Version      : $($board.SystemVersion)"
    Write-Host "  Serial       : $($board.SystemSerial)"
    Write-Host "  UUID         : $($board.SystemUUID)"
    Write-Host "  SKU          : $($board.SystemSKU)"
    Write-Host "  Family       : $($board.SystemFamily)"
    Write-Host ""

    Write-Host "BaseBoard:"
    Write-Host "  Manufacturer : $($board.BaseBoardManufacturer)"
    Write-Host "  Product      : $($board.BaseBoardProduct)"
    Write-Host "  Version      : $($board.BaseBoardVersion)"
    Write-Host "  Serial       : $($board.BaseBoardSerial)"
    Write-Host "  Asset Tag    : $($board.BaseBoardAssetTag)"
    Write-Host "  Location     : $($board.BaseBoardLocation)"
    Write-Host ""

    Write-Host "Processor:"
    Write-Host "  Serial       : $($board.ProcessorSerial)"
    Write-Host "  Asset Tag    : $($board.ProcessorAssetTag)"
    Write-Host "  Part Number  : $($board.ProcessorPartNumber)"
    Write-Host ""

    # ========================================
    # Generate commands
    # ========================================

    if (-not (Get-Command New-SMBIOSCommands -ErrorAction SilentlyContinue)) {

        Write-Host ""
        Write-Host "[ERROR] New-SMBIOSCommands was not loaded."
        Write-Host ""

        exit 1
    }

    # Do NOT pass -Backup $null.
    # The parameter is optional in the current Generator.ps1.

    $commands = New-SMBIOSCommands `
        -Profile $profile

    if (-not $commands -or $commands.Count -eq 0) {

        Write-Host ""
        Write-Host "[ERROR] No SMBIOS commands were generated."
        Write-Host ""

        exit 1
    }

    # ========================================
    # Display commands
    # ========================================

    Write-Host ""
    Write-Host "============================================"
    Write-Host "          GENERATED SMBIOS COMMANDS"
    Write-Host "============================================"
    Write-Host ""

    foreach ($command in $commands) {

        Write-Host $command
    }

    Write-Host ""

    # ========================================
    # Confirmation
    # ========================================

    Write-Host "============================================"
    Write-Host "                 WARNING"
    Write-Host "============================================"
    Write-Host ""
    Write-Host "The generated commands would modify SMBIOS"
    Write-Host "information using AMIDEWIN."
    Write-Host ""

# ============================================
# SMBIOS confirmation UI
# ============================================

$commandPreview = $commands -join "`r`n"

$confirmationMessage = @"
The following SMBIOS changes have been generated:

$commandPreview

Do you want to continue?
"@

$confirmationForm = New-Object System.Windows.Forms.Form
$confirmationForm.Text = "SMBIOS Manager - Confirmation"
$confirmationForm.Size = New-Object System.Drawing.Size(700, 600)
$confirmationForm.StartPosition = "CenterScreen"
$confirmationForm.FormBorderStyle = "FixedDialog"
$confirmationForm.MaximizeBox = $false
$confirmationForm.MinimizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "Review the generated SMBIOS profile:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(620, 25)
$confirmationForm.Controls.Add($label)

$preview = New-Object System.Windows.Forms.TextBox
$preview.Location = New-Object System.Drawing.Point(20, 50)
$preview.Size = New-Object System.Drawing.Size(640, 430)
$preview.Multiline = $true
$preview.ReadOnly = $true
$preview.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
$preview.WordWrap = $false
$preview.Font = New-Object System.Drawing.Font("Consolas", 9)
$preview.Text = $commandPreview
$confirmationForm.Controls.Add($preview)

$continueButton = New-Object System.Windows.Forms.Button
$continueButton.Text = "Continue"
$continueButton.Location = New-Object System.Drawing.Point(455, 500)
$continueButton.Size = New-Object System.Drawing.Size(95, 35)
$confirmationForm.Controls.Add($continueButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Point(565, 500)
$cancelButton.Size = New-Object System.Drawing.Size(95, 35)
$confirmationForm.Controls.Add($cancelButton)

$confirmationForm.AcceptButton = $continueButton
$confirmationForm.CancelButton = $cancelButton

$continueButton.Add_Click({
    $confirmationForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $confirmationForm.Close()
})

$cancelButton.Add_Click({
    $confirmationForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $confirmationForm.Close()
})

$result = $confirmationForm.ShowDialog()

if ($result -ne [System.Windows.Forms.DialogResult]::OK) {

    [System.Windows.Forms.MessageBox]::Show(
        "Operation cancelled.`r`n`r`nNo SMBIOS changes were made.",
        "SMBIOS Manager",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )

    exit 0
}

    Invoke-SMBIOSCommands ` -Commands $commands

    $afterBackup = Invoke-SMBIOSBackup "AFTER"

    if ($afterBackup) {
        Write-Host ""
        Write-Host "After-backup saved to:"
        Write-Host "  $afterBackup"
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "[ERROR] Failed to create AFTER backup."
        Write-Host ""
    }

    exit 0
}

# ============================================
# Unknown action
# ============================================

Write-Host ""
Write-Host "[ERROR] Unknown action:"
Write-Host "  $($uiResult.Action)"
Write-Host ""

exit 1