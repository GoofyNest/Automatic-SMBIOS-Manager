# ============================================
# SMBIOS RESTORE
# ============================================

function Get-SMBIOSBackupEntries {

    param (
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )

    if (-not (Test-Path $BackupPath -PathType Leaf)) {

        Write-Host "[ERROR] Backup file not found:"
        Write-Host $BackupPath

        return $null
    }

    $entries = @()

    $osIndex = 0
    $scoIndex = 0

    foreach ($line in Get-Content -LiteralPath $BackupPath) {

        # Match:
        # (/OS)OEM string         #1   R    Done   "Default string"
        # (/SCO)System Conf. Op.  #1   R    Done   "To Be Filled By O.E.M."

        if ($line -match '^\s*\(/([A-Z0-9]+)\).*?"([^"]*)"') {

            $command = $matches[1].Trim().ToUpperInvariant()
            $value   = $matches[2]

            if ($command -eq "OS") {

                $osIndex++

                $entries += [PSCustomObject]@{
                    Command = "OS"
                    Index   = $osIndex
                    Value   = $value
                }

                continue
            }

            if ($command -eq "SCO") {

                $scoIndex++

                $entries += [PSCustomObject]@{
                    Command = "SCO"
                    Index   = $scoIndex
                    Value   = $value
                }

                continue
            }

            # Normal non-indexed SMBIOS field

            $entries += [PSCustomObject]@{
                Command = $command
                Index   = $null
                Value   = $value
            }
        }
    }

    return $entries
}


# ============================================
# Restore SMBIOS
# ============================================

function Invoke-SMBIOSRestore {

    param (
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )

    # ========================================
    # Safety backup before restore
    # ========================================

    $beforeRevertBackup = Invoke-SMBIOSBackup "BEFORE-REVERT"

    if (
        -not $beforeRevertBackup -or
        -not (Test-Path $beforeRevertBackup)
    ) {

        Write-Host "[ERROR] Failed to create BEFORE-REVERT backup."
        Write-Host "Restore cancelled for safety."

        return $false
    }

    Write-Host "Current SMBIOS backed up to:"
    Write-Host $beforeRevertBackup
    Write-Host ""

    # ========================================
    # Read backup
    # ========================================

    $entries = Get-SMBIOSBackupEntries `
        -BackupPath $BackupPath

    if (-not $entries) {

        Write-Host "[ERROR] No SMBIOS entries could be read from the backup."

        return $false
    }

    Write-Host ""
    Write-Host "============================================"
    Write-Host "             SMBIOS RESTORE"
    Write-Host "============================================"
    Write-Host ""

    Write-Host "Backup: $([System.IO.Path]::GetFileName($BackupPath))"
    Write-Host "Entries: $($entries.Count)"
    Write-Host ""

    # ========================================
    # Excluded commands
    # ========================================

    $excludedCommands = @(
        "IVN",
        "IV",
        "ID"
    )

    $commands = @()

    foreach ($entry in $entries) {

        $command = $entry.Command
        $value   = $entry.Value
        $index   = $entry.Index

        # Skip read-only / informational fields

        if ($excludedCommands -contains $command) {
            continue
        }

        # Skip automatically generated handle fields

        if ($command -match 'H$') {
            continue
        }

        # Skip empty values

        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        # Preserve Index for OS/SCO

        $commands += [PSCustomObject]@{
            Command = $command
            Index   = $index
            Value   = $value
        }
    }

    if ($commands.Count -eq 0) {

        Write-Host "[ERROR] No restorable SMBIOS fields found."

        return $false
    }

    # ========================================
    # Display restore commands
    # ========================================

    Write-Host "The following SMBIOS fields will be restored:"
    Write-Host ""

    foreach ($entry in $commands) {

        if (
            $entry.Command -eq "OS" -or
            $entry.Command -eq "SCO"
        ) {

            Write-Host `
                "  /$($entry.Command) $($entry.Index) `"$($entry.Value)`""
        }
        else {

            Write-Host `
                "  /$($entry.Command) `"$($entry.Value)`""
        }
    }

    Write-Host ""

    # ========================================
    # Confirmation
    # ========================================

    $result = [System.Windows.Forms.MessageBox]::Show(
        "Restore SMBIOS values from:`r`n`r`n" +
        "$([System.IO.Path]::GetFileName($BackupPath))`r`n`r`n" +
        "Do you wish to continue?",
        "SMBIOS Restore",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if (
        $result -ne
        [System.Windows.Forms.DialogResult]::Yes
    ) {

        Write-Host ""
        Write-Host "============================================"
        Write-Host "         SMBIOS RESTORE CANCELLED"
        Write-Host "============================================"
        Write-Host ""

        return $false
    }

    # ========================================
    # Execute restore
    # ========================================

    Write-Host ""
    Write-Host "============================================"
    Write-Host "       EXECUTING SMBIOS RESTORE"
    Write-Host "============================================"
    Write-Host ""

    # Debug information for indexed commands

    foreach (
        $entry in (
            $commands | Where-Object {
                $_.Command -eq "OS" -or
                $_.Command -eq "SCO"
            }
        )
    ) {

        Write-Host `
            "Command=$($entry.Command) Index=$($entry.Index) Value=$($entry.Value)"
    }

    Write-Host ""

    foreach ($entry in $commands) {

        # OS and SCO require an index:
        #
        # /OS 1 "value"
        # /SCO 1 "value"

        if (
            $entry.Command -eq "OS" -or
            $entry.Command -eq "SCO"
        ) {

            $arguments =
                "/$($entry.Command) $($entry.Index) `"$($entry.Value)`""
        }
        else {

            $arguments =
                "/$($entry.Command) `"$($entry.Value)`""
        }

        Write-Host `
            "Executing: AMIDEWINx64.exe $arguments"

        $psi = [System.Diagnostics.ProcessStartInfo]::new()

        $psi.FileName = $amidewinPath
        $psi.Arguments = $arguments
        $psi.WorkingDirectory = $amidewinWorkingDirectory
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"

        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $psi

        try {

            [void]$process.Start()
            $process.WaitForExit()

            Write-Host "Done"
        }
        catch {

            Write-Host "FAILED: $($_.Exception.Message)"
        }

        Write-Host ""
    }

    # ========================================
    # Restore complete
    # ========================================

    Write-Host "============================================"
    Write-Host "          SMBIOS RESTORE COMPLETE"
    Write-Host "============================================"
    Write-Host ""

    # ========================================
    # Safety backup after restore
    # ========================================

    $afterRevertBackup = Invoke-SMBIOSBackup "AFTER-REVERT"

    if (
        -not $afterRevertBackup -or
        -not (Test-Path $afterRevertBackup)
    ) {

        Write-Host "[ERROR] Failed to create AFTER-REVERT backup."
        Write-Host "Restore cancelled for safety."

        return $false
    }

    Write-Host "Current SMBIOS backed up to:"
    Write-Host $afterRevertBackup
    Write-Host ""

    return $true
}


# ============================================
# Select SMBIOS backup
# ============================================

function Select-SMBIOSBackup {

    $backupDirectory = Join-Path `
        $rootDirectory `
        "backups"

    if (-not (Test-Path $backupDirectory)) {

        [System.Windows.Forms.MessageBox]::Show(
            "No SMBIOS backup files were found.",
            "SMBIOS Restore",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )

        return $null
    }

    $restoreFiles = @(
        Get-ChildItem `
            -Path $backupDirectory `
            -Filter "*.txt" `
            -File |
            Sort-Object LastWriteTime -Descending
    )

    if ($restoreFiles.Count -eq 0) {

        [System.Windows.Forms.MessageBox]::Show(
            "No SMBIOS backup files were found.",
            "SMBIOS Restore",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )

        return $null
    }

    # ========================================
    # Restore selection window
    # ========================================

    $form = New-Object System.Windows.Forms.Form

    $form.Text = "Select SMBIOS Backup"
    $form.Size = New-Object System.Drawing.Size(600, 450)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # ========================================
    # Label
    # ========================================

    $label = New-Object System.Windows.Forms.Label

    $label.Text =
        "Select the SMBIOS backup you wish to restore:"

    $label.Location =
        New-Object System.Drawing.Point(20, 20)

    $label.Size =
        New-Object System.Drawing.Size(540, 30)

    $form.Controls.Add($label)

    # ========================================
    # List
    # ========================================

    $listBox = New-Object System.Windows.Forms.ListBox

    $listBox.Location =
        New-Object System.Drawing.Point(20, 55)

    $listBox.Size =
        New-Object System.Drawing.Size(540, 280)

    foreach ($file in $restoreFiles) {

        [void]$listBox.Items.Add($file.Name)
    }

    $listBox.SelectedIndex = 0

    $form.Controls.Add($listBox)

    # ========================================
    # Restore button
    # ========================================

    $restoreButton = New-Object System.Windows.Forms.Button

    $restoreButton.Text = "Restore"

    $restoreButton.Location =
        New-Object System.Drawing.Point(365, 350)

    $restoreButton.Size =
        New-Object System.Drawing.Size(95, 35)

    $restoreButton.DialogResult =
        [System.Windows.Forms.DialogResult]::OK

    $form.Controls.Add($restoreButton)

    # ========================================
    # Cancel button
    # ========================================

    $cancelButton = New-Object System.Windows.Forms.Button

    $cancelButton.Text = "Cancel"

    $cancelButton.Location =
        New-Object System.Drawing.Point(465, 350)

    $cancelButton.Size =
        New-Object System.Drawing.Size(95, 35)

    $cancelButton.DialogResult =
        [System.Windows.Forms.DialogResult]::Cancel

    $form.Controls.Add($cancelButton)

    $form.AcceptButton = $restoreButton
    $form.CancelButton = $cancelButton

    # ========================================
    # Double click
    # ========================================

    $listBox.Add_DoubleClick({

        $form.DialogResult =
            [System.Windows.Forms.DialogResult]::OK

        $form.Close()
    })

    # ========================================
    # Show
    # ========================================

    $result = $form.ShowDialog()

    if (
        $result -ne
        [System.Windows.Forms.DialogResult]::OK
    ) {

        return $null
    }

    return $restoreFiles[$listBox.SelectedIndex].FullName
}