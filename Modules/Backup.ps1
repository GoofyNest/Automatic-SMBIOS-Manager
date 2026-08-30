# ============================================
# SMBIOS BACKUP
# ============================================

function Invoke-SMBIOSBackup {

    param (
        [ValidateSet("BEFORE", "AFTER", "BEFORE-REVERT", "AFTER-REVERT")]
        [string]$Type
    )

    # ========================================
    # Backup directories
    # ========================================

    $backupDirectory = Join-Path $rootDirectory "backups"

    if (-not (Test-Path $backupDirectory)) {

        New-Item `
            -ItemType Directory `
            -Path $backupDirectory `
            -Force |
            Out-Null
    }

    # ========================================
    # Backup filename
    # ========================================

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

    $backupFileName = "$($Type.ToLower())-$timestamp.txt"

    # AMIDEWIN creates the file in its
    # own working directory.

    $temporaryBackupFile = Join-Path `
        $amidewinWorkingDirectory `
        $backupFileName

    # Final destination inside backups\

    $finalBackupFile = Join-Path `
        $backupDirectory `
        $backupFileName

    # ========================================
    # Remove stale file
    # ========================================

    if (Test-Path $temporaryBackupFile -PathType Leaf) {

        Remove-Item `
            $temporaryBackupFile `
            -Force `
            -ErrorAction SilentlyContinue
    }

    # ========================================
    # Run AMIDEWIN
    # ========================================

    Write-Host ""
    Write-Host "============================================"
    Write-Host "              SMBIOS BACKUP"
    Write-Host "============================================"
    Write-Host ""

    Write-Host "AMIDEWIN:"
    Write-Host "  $amidewinPath"

    Write-Host "Working directory:"
    Write-Host "  $amidewinWorkingDirectory"

    Write-Host "Output:"
    Write-Host "  $backupFileName"

    Write-Host ""

    $psi = [System.Diagnostics.ProcessStartInfo]::new()

    $psi.FileName = $amidewinPath

    # IMPORTANT:
    # /ALL receives only the filename.
    # AMIDEWIN creates it in its working directory.

    $psi.Arguments = "/ALL `"$backupFileName`""

    # IMPORTANT:
    # This must be the directory containing
    # AMIDEWIN.exe and its required .sys files.

    $psi.WorkingDirectory = $amidewinWorkingDirectory

    $psi.UseShellExecute = $true
    $psi.Verb = "runas"

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi

    try {

        [void]$process.Start()
        $process.WaitForExit()
    }
    catch {

        Write-Host "[ERROR] Failed to start AMIDEWIN:"
        Write-Host $_.Exception.Message

        return $null
    }

    # ========================================
    # Check AMIDEWIN output
    # ========================================

    if (-not (Test-Path $temporaryBackupFile -PathType Leaf)) {

        Write-Host ""
        Write-Host "[ERROR] AMIDEWIN did not create the backup:"
        Write-Host $temporaryBackupFile
        Write-Host ""

        return $null
    }

    # ========================================
    # Reject empty files
    # ========================================

    $fileInfo = Get-Item `
        $temporaryBackupFile `
        -ErrorAction SilentlyContinue

    if (-not $fileInfo -or $fileInfo.Length -eq 0) {

        Write-Host ""
        Write-Host "[ERROR] AMIDEWIN created an empty backup."
        Write-Host $temporaryBackupFile
        Write-Host ""

        Remove-Item `
            $temporaryBackupFile `
            -Force `
            -ErrorAction SilentlyContinue

        return $null
    }

    # ========================================
    # Reject broken backups
    # ========================================

    $invalid = Select-String `
        -Path $temporaryBackupFile `
        -Pattern "INVALID" `
        -SimpleMatch `
        -Quiet

    if ($invalid) {

        Write-Host ""
        Write-Host "[ERROR] SMBIOS backup contains INVALID entries."
        Write-Host "The selected AMIDEWIN version may not work with this system."
        Write-Host ""

        Remove-Item `
            $temporaryBackupFile `
            -Force `
            -ErrorAction SilentlyContinue

        return $null
    }

    # ========================================
    # Move completed backup
    # ========================================

    try {

        Move-Item `
            -LiteralPath $temporaryBackupFile `
            -Destination $finalBackupFile `
            -Force `
            -ErrorAction Stop
    }
    catch {

        Write-Host ""
        Write-Host "[ERROR] Failed to move SMBIOS backup:"
        Write-Host $_.Exception.Message
        Write-Host ""

        return $null
    }

    # ========================================
    # Verify final backup
    # ========================================

    if (-not (Test-Path $finalBackupFile -PathType Leaf)) {

        Write-Host ""
        Write-Host "[ERROR] Backup was not found at final location:"
        Write-Host $finalBackupFile
        Write-Host ""

        return $null
    }

    # ========================================
    # Success
    # ========================================

    Write-Host ""
    Write-Host "SMBIOS backup completed successfully."
    Write-Host ""

    Write-Host "Saved to:"
    Write-Host $finalBackupFile
    Write-Host ""

    return $finalBackupFile
}


# ============================================
# Get latest BEFORE backup
# ============================================

function Get-LatestSMBIOSBackup {

    $backupDirectory = Join-Path $rootDirectory "backups"

    if (-not (Test-Path $backupDirectory)) {
        return $null
    }

    $backup = Get-ChildItem `
        -Path $backupDirectory `
        -Filter "before-*.txt" `
        -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $backup) {
        return $null
    }

    $result = @{}

    $osCount = 0
    $scoCount = 0

    foreach ($line in Get-Content $backup.FullName) {

        if ($line -match '^\s*\(/\s*([A-Z0-9]+)\)\s*.*?"([^"]*)"') {

            $field = $matches[1]
            $value = $matches[2]

            $result[$field] = $value

            if ($field -eq "OS") {

                $osCount++
            }
            elseif ($field -eq "SCO") {

                $scoCount++
            }
        }
    }

    return [PSCustomObject]@{

        BackupFile = $backup.Name

        BIOSVendor     = $result["IVN"]
        BIOSVersion    = $result["IV"]
        BIOSReleaseDate = $result["ID"]

        SystemManufacturer = $result["SM"]
        SystemProductName  = $result["SP"]
        SystemVersion      = $result["SV"]
        SystemSerial       = $result["SS"]
        SystemUUID         = $result["SU"]
        SystemSKU          = $result["SK"]
        SystemFamily      = $result["SF"]

        BaseBoardManufacturer = $result["BM"]
        BaseBoardProduct      = $result["BP"]
        BaseBoardVersion      = $result["BV"]
        BaseBoardSerial       = $result["BS"]
        BaseBoardAssetTag     = $result["BT"]
        BaseBoardLocation     = $result["BLC"]

        ChassisManufacturer = $result["CM"]
        ChassisType         = $result["CT"]
        ChassisVersion      = $result["CV"]
        ChassisSerial       = $result["CS"]
        ChassisTag          = $result["CA"]
        ChassisOEM          = $result["CO"]
        ChassisPowerCords   = $result["CPC"]
        ChassisSKU          = $result["CSK"]

        ProcessorSerial     = $result["PSN"]
        ProcessorAssetTag   = $result["PAT"]
        ProcessorPartNumber = $result["PPN"]

        OEMString           = $result["OS"]
        SystemConfiguration = $result["SCO"]

        OSCount  = $osCount
        SCOCount = $scoCount
    }
}