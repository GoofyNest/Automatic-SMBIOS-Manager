# ============================================
# UI MODULE
# ============================================

function Show-RandomMotherboard {

    while ($true) {

        $selectedPlatform     = [string]$platformCombo.SelectedItem
        $selectedManufacturer = [string]$manufacturerCombo.SelectedItem
        $selectedMemory       = [string]$memoryCombo.SelectedItem

        Write-Host "Platform selected:     [$selectedPlatform]"
        Write-Host "Manufacturer selected: [$selectedManufacturer]"
        Write-Host "Memory selected:       [$selectedMemory]"

        # Start with all motherboards
        $filteredMobos = @($mobos)

        # ============================================
        # CPU / Platform
        # ============================================

        if ($selectedPlatform -ieq "AM4") {

            $filteredMobos = @(
                $filteredMobos | Where-Object {
                    $_.AMDCPU -eq $true -and
                    $_.Socket -ieq "AM4"
                }
            )
        }
        elseif ($selectedPlatform -ieq "AM5") {

            $filteredMobos = @(
                $filteredMobos | Where-Object {
                    $_.AMDCPU -eq $true -and
                    $_.Socket -ieq "AM5"
                }
            )
        }
        elseif ($selectedPlatform -ieq "Intel") {

            $filteredMobos = @(
                $filteredMobos | Where-Object {
                    $_.IntelCPU -eq $true
                }
            )
        }

        # ============================================
        # Manufacturer
        # ============================================

        if (-not [string]::IsNullOrWhiteSpace($selectedManufacturer) -and
            $selectedManufacturer -ine "Any") {

            $filteredMobos = @(
                $filteredMobos | Where-Object {
                    $_.Manufacturer -ieq $selectedManufacturer
                }
            )
        }

        # ============================================
        # Memory
        # ============================================

        if ($selectedMemory -ieq "DDR4") {

            $filteredMobos = @(
                $filteredMobos | Where-Object {
                    $_.DDR4 -eq $true
                }
            )
        }
        elseif ($selectedMemory -ieq "DDR5") {

            $filteredMobos = @(
                $filteredMobos | Where-Object {
                    $_.DDR5 -eq $true
                }
            )
        }

        # ============================================
        # Check
        # ============================================

        if ($filteredMobos.Count -eq 0) {

            [System.Windows.Forms.MessageBox]::Show(
                "No motherboards found for:`r`n`r`n" +
                "CPU: $selectedPlatform`r`n" +
                "Manufacturer: $selectedManufacturer`r`n" +
                "RAM: $selectedMemory",
                "Generate Profile",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            return
        }

        # ============================================
        # Random selection
        # ============================================

        $mobo = Get-Random -InputObject $filteredMobos

        # ============================================
        # Popup
        # ============================================

        $message = @"
Generated Motherboard

Manufacturer : $($mobo.Manufacturer)
Model        : $($mobo.ProductName)
Socket       : $($mobo.Socket)
Generation   : $($mobo.Generation)

CPU Platform : $selectedPlatform
Memory       : $selectedMemory
"@

        $result = [System.Windows.Forms.MessageBox]::Show(
            $message,
            "Generated Profile",
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        # Yes = use this motherboard
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            return $mobo
        }

        # No = generate another motherboard
        if ($result -eq [System.Windows.Forms.DialogResult]::No) {
            continue
        }

        # Cancel = close generator
        return $null
    }
}


# ============================================
# Main UI
# ============================================

function Show-SMBIOSMainUI {

    $detected = Get-CurrentHardwareDefaults

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "GoofyNest - Automatic SMBIOS Manager"
    $form.Size = New-Object System.Drawing.Size(500, 430)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # ----------------------------------------
    # Action
    # ----------------------------------------

    $actionLabel = New-Object System.Windows.Forms.Label
    $actionLabel.Text = "Action"
    $actionLabel.Location = New-Object System.Drawing.Point(25, 25)
    $actionLabel.Size = New-Object System.Drawing.Size(100, 20)
    $form.Controls.Add($actionLabel)

    $actionCombo = New-Object System.Windows.Forms.ComboBox
    $actionCombo.Location = New-Object System.Drawing.Point(25, 48)
    $actionCombo.Size = New-Object System.Drawing.Size(430, 30)
    $actionCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    [void]$actionCombo.Items.Add("Spoof SMBIOS")
    [void]$actionCombo.Items.Add("Restore SMBIOS")

    $actionCombo.SelectedIndex = 0
    $form.Controls.Add($actionCombo)

    # ----------------------------------------
    # Manufacturer
    # ----------------------------------------

    $manufacturerLabel = New-Object System.Windows.Forms.Label
    $manufacturerLabel.Text = "Manufacturer"
    $manufacturerLabel.Location = New-Object System.Drawing.Point(25, 90)
    $manufacturerLabel.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($manufacturerLabel)

    $manufacturerCombo = New-Object System.Windows.Forms.ComboBox
    $manufacturerCombo.Location = New-Object System.Drawing.Point(25, 113)
    $manufacturerCombo.Size = New-Object System.Drawing.Size(430, 30)
    $manufacturerCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    [void]$manufacturerCombo.Items.Add("Any")
    [void]$manufacturerCombo.Items.Add("Gigabyte")
    [void]$manufacturerCombo.Items.Add("ASUS")
    [void]$manufacturerCombo.Items.Add("MSI")
    [void]$manufacturerCombo.Items.Add("ASRock")

    $manufacturerIndex = $manufacturerCombo.Items.IndexOf(
        $detected.Manufacturer
    )

    if ($manufacturerIndex -ge 0) {
        $manufacturerCombo.SelectedIndex = $manufacturerIndex
    }
    else {
        $manufacturerCombo.SelectedIndex = 0
    }

    $form.Controls.Add($manufacturerCombo)

    # ----------------------------------------
    # Platform
    # ----------------------------------------

    $platformLabel = New-Object System.Windows.Forms.Label
    $platformLabel.Text = "Platform"
    $platformLabel.Location = New-Object System.Drawing.Point(25, 155)
    $platformLabel.Size = New-Object System.Drawing.Size(100, 20)
    $form.Controls.Add($platformLabel)

    $platformCombo = New-Object System.Windows.Forms.ComboBox
    $platformCombo.Location = New-Object System.Drawing.Point(25, 178)
    $platformCombo.Size = New-Object System.Drawing.Size(430, 30)
    $platformCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    [void]$platformCombo.Items.Add("Any")
    [void]$platformCombo.Items.Add("Intel")
    [void]$platformCombo.Items.Add("AM4")
    [void]$platformCombo.Items.Add("AM5")

    $platformIndex = $platformCombo.Items.IndexOf(
        $detected.Platform
    )

    if ($platformIndex -ge 0) {
        $platformCombo.SelectedIndex = $platformIndex
    }
    else {
        $platformCombo.SelectedIndex = 0
    }

    $form.Controls.Add($platformCombo)

    # ----------------------------------------
    # Memory
    # ----------------------------------------

    $memoryLabel = New-Object System.Windows.Forms.Label
    $memoryLabel.Text = "Memory"
    $memoryLabel.Location = New-Object System.Drawing.Point(25, 220)
    $memoryLabel.Size = New-Object System.Drawing.Size(100, 20)
    $form.Controls.Add($memoryLabel)

    $memoryCombo = New-Object System.Windows.Forms.ComboBox
    $memoryCombo.Location = New-Object System.Drawing.Point(25, 243)
    $memoryCombo.Size = New-Object System.Drawing.Size(430, 30)
    $memoryCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    [void]$memoryCombo.Items.Add("DDR4")
    [void]$memoryCombo.Items.Add("DDR5")

    $memoryIndex = $memoryCombo.Items.IndexOf(
        $detected.Memory
    )

    if ($memoryIndex -ge 0) {
        $memoryCombo.SelectedIndex = $memoryIndex
    }
    else {
        $memoryCombo.SelectedIndex = 0
    }

    $form.Controls.Add($memoryCombo)

    # ----------------------------------------
    # Product
    # ----------------------------------------

    $productLabel = New-Object System.Windows.Forms.Label
    $productLabel.Text = "Product (optional)"
    $productLabel.Location = New-Object System.Drawing.Point(25, 285)
    $productLabel.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($productLabel)

    $productText = New-Object System.Windows.Forms.TextBox
    $productText.Location = New-Object System.Drawing.Point(25, 308)
    $productText.Size = New-Object System.Drawing.Size(430, 25)

    # Automatically populate with detected motherboard
    $productText.Text = $detected.Product

    $form.Controls.Add($productText)

    # ----------------------------------------
    # Buttons
    # ----------------------------------------

    $continueButton = New-Object System.Windows.Forms.Button
    $continueButton.Text = "Continue"
    $continueButton.Location = New-Object System.Drawing.Point(255, 350)
    $continueButton.Size = New-Object System.Drawing.Size(95, 35)
    $form.Controls.Add($continueButton)

    $generateButton = New-Object System.Windows.Forms.Button
    $generateButton.Text = "Generate"
    $generateButton.Location = New-Object System.Drawing.Point(150, 350)
    $generateButton.Size = New-Object System.Drawing.Size(95, 35)
    $form.Controls.Add($generateButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(360, 350)
    $cancelButton.Size = New-Object System.Drawing.Size(95, 35)
    $form.Controls.Add($cancelButton)

    $form.CancelButton = $cancelButton

    # ----------------------------------------
    # Generate
    # ----------------------------------------

    $generateButton.Add_Click({

        $mobo = Show-RandomMotherboard

        if ($null -eq $mobo) {
            return
        }

        $manufacturerCombo.SelectedItem = $mobo.Manufacturer

        $model = $mobo.ProductName `
            -replace '\s*\(rev\.[^)]*\)', '' `
            -replace '\s*\(MS-[^)]*\)', ''

        $productText.Text = $model.Trim()
    })

    # ----------------------------------------
    # Action changed
    # ----------------------------------------

    $actionCombo.Add_SelectedIndexChanged({

        $restoreMode = (
            $actionCombo.SelectedItem -eq "Restore SMBIOS"
        )

        $manufacturerCombo.Enabled = -not $restoreMode
        $platformCombo.Enabled = -not $restoreMode
        $memoryCombo.Enabled = -not $restoreMode
        $productText.Enabled = -not $restoreMode
    })

    # ----------------------------------------
    # Cancel
    # ----------------------------------------

    $cancelButton.Add_Click({

        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })

    # ----------------------------------------
    # Continue
    # ----------------------------------------

    $continueButton.Add_Click({

        if ($actionCombo.SelectedItem -eq "Restore SMBIOS") {

            $form.Tag = [PSCustomObject]@{
                Action = "Restore"
            }

        }
        else {

            $backupResult = [System.Windows.Forms.MessageBox]::Show(
                "Do you wish to make a backup of your BIOS/SMBIOS?",
                "BIOS Backup",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($backupResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                $beforeBackup = Invoke-SMBIOSBackup "BEFORE"
            }

            $form.Tag = [PSCustomObject]@{
                Action       = "Spoof"
                Manufacturer = $manufacturerCombo.SelectedItem.ToString()
                Platform     = $platformCombo.SelectedItem.ToString()
                Memory       = $memoryCombo.SelectedItem.ToString()
                Product      = $productText.Text.Trim()
            }
        }

        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })

    # ----------------------------------------
    # Show
    # ----------------------------------------

    $result = $form.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    return $form.Tag
}