# ============================================
# SMBIOS GENERATOR
# ============================================

# ============================================
# Generic values
# ============================================

$biosVendorStrings = @(
    "American Megatrends Inc."
    "American Megatrends International, LLC."
)

$familyStrings = @(
    "B550"
    "B550 MB"
    "To Be Filled By O.E.M."
)

$defaultStrings = @(
    "Default string"
    "To Be Filled By O.E.M."
)

$oemStrings = @(
    "To Be Filled By O.E.M."
    "Unknown"
    "Not Specified"
)


function Get-RandomDefaultString {

    return Get-Random -InputObject $defaultStrings
}


function Get-RandomCpuString {

    return Get-Random -InputObject $oemStrings
}


# ============================================
# BIOS date generation
# ============================================

$startDate = Get-Date "01/01/2021"
$endDate   = Get-Date "12/31/2025"

$biosDate = $startDate.AddDays(
    (Get-Random -Minimum 0 -Maximum (($endDate - $startDate).Days + 1))
).ToString("MM/dd/yyyy")


# ============================================
# Gigabyte BIOS
# F1-F20 + FA-FZ
# ============================================

$gigabyteBiosVersions = @()

for ($i = 1; $i -le 20; $i++) {

    $gigabyteBiosVersions += "F$i"
}

for (
    $i = [int][char]'A';
    $i -le [int][char]'Z';
    $i++
) {

    $gigabyteBiosVersions += "F$([char]$i)"
}


function Get-RandomGigabyteBiosVersion {

    return Get-Random -InputObject $gigabyteBiosVersions
}


# ============================================
# ASUS BIOS
# 1000-2600
# ============================================

function Get-RandomAsusBiosVersion {

    return Get-Random -Minimum 1000 -Maximum 2601
}


# ============================================
# MSI BIOS
# 1.00-1.75
# ============================================

function Get-RandomMsiBiosVersion {

    return (
        (Get-Random -Minimum 100 -Maximum 176) / 100
    ).ToString("0.##")
}


# ============================================
# ASUS serial generation
# ============================================

function Get-RandomAsusBoardSerial {

    $digits = -join (
        1..11 | ForEach-Object {
            Get-Random -Minimum 0 -Maximum 10
        }
    )

    return "1904$digits"
}


function Get-RandomAsusChassisSerial {

    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    $suffix = -join (
        1..9 | ForEach-Object {
            $chars[
                (Get-Random -Minimum 0 -Maximum $chars.Length)
            ]
        }
    )

    return "A51$suffix"
}


# ============================================
# MSI model code
# ============================================

function Get-MsiModelCode {

    param (
        [string]$ProductName
    )

    # Example:
    # MEG X870E GODLIKE (MS-7E48)
    #
    # Returns:
    # MS-7E48

    if ($ProductName -match '\((MS-[A-Z0-9]+)\)') {

        return $Matches[1]
    }

    return $null
}


# ============================================
# MSI board serial
# ============================================

function Get-RandomMsiBoardSerial {

    param (
        [string]$ModelCode
    )

    if ([string]::IsNullOrWhiteSpace($ModelCode)) {

        return Get-RandomDefaultString
    }

    # MS-7E48
    #
    # Extract 3 characters after MS-
    #
    # MS-7E48
    #    ^^^
    #    7E4

    $code = $ModelCode.Substring(3, 3)

    $number = Get-Random -Minimum 1 -Maximum 100

    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    $suffix = -join (
        1..10 | ForEach-Object {
            $chars[
                (Get-Random -Minimum 0 -Maximum $chars.Length)
            ]
        }
    )

    return "0${code}X${number}_$suffix"
}


# ============================================
# ASRock serial
# ============================================

function Get-ASRockSerial {

    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    if ((Get-Random -Minimum 0 -Maximum 2) -eq 0) {

        # BR80 + 11 characters = 15 total

        return "BR80" + -join (
            1..11 | ForEach-Object {
                $chars[
                    (Get-Random -Minimum 0 -Maximum $chars.Length)
                ]
            }
        )
    }
    else {

        # M80- + 11 characters = 15 total

        return "M80-" + -join (
            1..11 | ForEach-Object {
                $chars[
                    (Get-Random -Minimum 0 -Maximum $chars.Length)
                ]
            }
        )
    }
}


# ============================================
# Generate SMBIOS profile
# ============================================

function New-SMBIOSProfile {

    param (
        [string]$Platform,
        [string]$MoboManufacturer,
        [string]$Memory,
        [string]$ProductName
    )

    # ========================================
    # Filter motherboard database
    # ========================================

    $filteredMobos = @($mobos)

    if (-not $filteredMobos -or $filteredMobos.Count -eq 0) {

        Write-Host ""
        Write-Host "[ERROR] Motherboard database is empty."
        Write-Host ""

        return $null
    }

    # ========================================
    # Manufacturer
    # ========================================

    if (-not [string]::IsNullOrWhiteSpace($MoboManufacturer)) {

        $filteredMobos = @(
            $filteredMobos | Where-Object {
                $_.Manufacturer -ieq $MoboManufacturer
            }
        )

        if ($filteredMobos.Count -eq 0) {

            Write-Host ""
            Write-Host "[ERROR] No motherboards found for manufacturer '$MoboManufacturer'."
            Write-Host ""

            return $null
        }
    }


    # ========================================
    # Platform / CPU
    # ========================================

    if (-not [string]::IsNullOrWhiteSpace($Platform)) {

        switch ($Platform.ToLower()) {

            "intel" {

                $filteredMobos = @(
                    $filteredMobos | Where-Object {
                        $_.IntelCPU -eq $true
                    }
                )
            }

            "am4" {

                $filteredMobos = @(
                    $filteredMobos | Where-Object {
                        $_.AMDCPU -eq $true -and
                        (
                            $_.Socket -ieq "AM4" -or
                            $_.Socket -ieq "Unknown"
                        )
                    }
                )
            }

            "am5" {

                $filteredMobos = @(
                    $filteredMobos | Where-Object {
                        $_.AMDCPU -eq $true -and
                        (
                            $_.Socket -ieq "AM5" -or
                            $_.Socket -ieq "Unknown"
                        )
                    }
                )
            }

            default {

                Write-Host ""
                Write-Host "[ERROR] Unknown platform '$Platform'."
                Write-Host ""

                return $null
            }
        }

        if ($filteredMobos.Count -eq 0) {

            Write-Host ""
            Write-Host "[ERROR] No motherboards matched platform '$Platform'."
            Write-Host ""

            return $null
        }
    }


    # ========================================
    # Memory
    # ========================================

    switch ($Memory.ToLower()) {

        "ddr4" {

            $filteredMobos = @(
                $filteredMobos | Where-Object {
                    $_.DDR4 -eq $true
                }
            )
        }

        "ddr5" {

            $filteredMobos = @(
                $filteredMobos | Where-Object {
                    $_.DDR5 -eq $true
                }
            )
        }

        default {

            Write-Host ""
            Write-Host "[ERROR] Unknown memory type '$Memory'."
            Write-Host ""

            return $null
        }
    }

    if ($filteredMobos.Count -eq 0) {

        Write-Host ""
        Write-Host "[ERROR] No motherboards matched $Memory."
        Write-Host ""

        return $null
    }


    # ========================================
    # Optional ProductName
    # ========================================

    if (-not [string]::IsNullOrWhiteSpace($ProductName)) {

        $filteredMobos = @(
            $filteredMobos | Where-Object {
                $_.ProductName -like "*$ProductName*"
            }
        )

        if ($filteredMobos.Count -eq 0) {

            Write-Host ""
            Write-Host "[ERROR] No motherboard matched ProductName:"
            Write-Host "  $ProductName"
            Write-Host ""

            return $null
        }
    }


    # ========================================
    # Select motherboard
    # ========================================

    $mobo = Get-Random -InputObject $filteredMobos

    $SelectedManufacturer =
        $mobo.Manufacturer.ToLower()


    # ========================================
    # Base profile
    # ========================================

    $board = @{

        GayBoard = $mobo.Manufacturer

        biosVendor  = $null
        biosVersion = $null
        biosDate    = $biosDate

        SystemManufacturer = $null
        SystemProductName  = $null
        SystemVersion      = $null
        SystemSerial       = $null
        SystemUUID         = "AUTO"
        SystemSKU          = $null
        SystemFamily       = $null

        BaseBoardManufacturer = $null
        BaseBoardProduct      = $null
        BaseBoardVersion      = $null
        BaseBoardSerial       = $null
        BaseBoardAssetTag     = $null
        BaseBoardLocation     = $null

        SEManufacturer = $null
        SEVersion      = $null
        SESerial       = $null
        SEAssetTag     = $null
        SESKU          = $null

        ProcessorSerial =
            Get-RandomCpuString

        ProcessorAssetTag =
            Get-RandomCpuString

        ProcessorPartNumber =
            Get-RandomCpuString

        OEMString1 =
            Get-RandomDefaultString

        SCOString1 =
            Get-RandomDefaultString
    }


    # ========================================
    # Gigabyte
    # ========================================

    if ($SelectedManufacturer -ieq "gigabyte") {

        $board.biosVendor =
            Get-Random -InputObject $biosVendorStrings

        $board.biosVersion =
            Get-RandomGigabyteBiosVersion

        $board.SystemManufacturer =
            "Gigabyte Technology Co., Ltd."

        $board.SystemProductName =
            $mobo.ProductName `
                -replace '\s*\(rev\.[^)]*\)', ''

        if (
            (
                $board.SystemProductName.ToCharArray() |
                Where-Object { $_ -eq '-' }
            ).Count -gt 1
        ) {

            $board.SystemProductName =
                $board.SystemProductName -replace '-', ' '
        }

        $board.SystemVersion =
            Get-RandomDefaultString

        $board.SystemSerial =
            Get-RandomDefaultString

        $board.SystemSKU =
            Get-RandomDefaultString

        $familyPrefix =
            (
                $mobo.ProductName -split '\s+', 2
            )[0] -replace 'M$', ''

        $board.SystemFamily =
            Get-Random -InputObject @(
                $familyPrefix
                "$familyPrefix MB"
            )

        $board.BaseBoardManufacturer =
            "Gigabyte Technology Co., Ltd."

        # Gigabyte:
        # SystemProductName == BaseBoardProduct

        $board.BaseBoardProduct =
            $board.SystemProductName

        $board.BaseBoardVersion =
            "x.x"

        $board.BaseBoardSerial =
            Get-RandomDefaultString

        $board.BaseBoardAssetTag =
            Get-RandomDefaultString

        $board.BaseBoardLocation =
            Get-RandomDefaultString

        $board.SEManufacturer =
            Get-RandomDefaultString

        $board.SEVersion =
            Get-RandomDefaultString

        $board.SESerial =
            Get-RandomDefaultString

        $board.SEAssetTag =
            Get-RandomDefaultString

        $board.SESKU =
            Get-RandomDefaultString
    }


    # ========================================
    # ASUS
    # ========================================

    elseif ($SelectedManufacturer -ieq "asus") {

        $asusChassisSerial =
            Get-RandomAsusChassisSerial

        $board.biosVendor =
            "American Megatrends Inc."

        $board.biosVersion =
            Get-RandomAsusBiosVersion

        $board.SystemManufacturer =
            "ASUS"

        $board.SystemProductName =
            "System Product Name"

        $board.SystemVersion =
            "System Version"

        $board.SystemSerial =
            "System Serial Number"

        $board.SystemSKU =
            "ASUS_MB_CNL"

        $board.SystemFamily =
            Get-RandomDefaultString

        $board.BaseBoardManufacturer =
            "ASUSTeK COMPUTER INC."

        # ASUS:
        # SystemProductName is intentionally generic.
        # BaseBoardProduct contains the actual board model.

        $board.BaseBoardProduct =
            $mobo.ProductName `
                -replace '\s*\(rev\.[^)]*\)', ''

        if (
            (
                $board.BaseBoardProduct.ToCharArray() |
                Where-Object { $_ -eq '-' }
            ).Count -gt 1
        ) {

            $board.BaseBoardProduct =
                $board.BaseBoardProduct -replace '-', ' '
        }

        $board.BaseBoardVersion =
            "Rev 1.xx"

        $board.BaseBoardSerial =
            Get-RandomAsusBoardSerial

        $board.BaseBoardAssetTag =
            Get-RandomDefaultString

        $board.BaseBoardLocation =
            Get-RandomDefaultString

        $board.SEManufacturer =
            Get-RandomDefaultString

        $board.SEVersion =
            Get-RandomDefaultString

        $board.SESerial =
            $asusChassisSerial

        $board.SEAssetTag =
            $asusChassisSerial

        $board.SESKU =
            $asusChassisSerial
    }


    # ========================================
    # MSI
    # ========================================

    elseif ($SelectedManufacturer -ieq "msi") {

        $modelCode =
            Get-MsiModelCode `
                -ProductName $mobo.ProductName

        $board.biosVendor =
            "American Megatrends International, LLC."

        $board.biosVersion =
            Get-RandomMsiBiosVersion

        $board.SystemManufacturer =
            "Micro-Star International Co., Ltd."

        # SystemProductName = MS-XXXX

        if ($modelCode) {

            $board.SystemProductName =
                $modelCode
        }
        else {

            $board.SystemProductName =
                $mobo.ProductName `
                    -replace '\s*\(rev\.[^)]*\)', ''
        }

        if (
            (
                $board.SystemProductName.ToCharArray() |
                Where-Object { $_ -eq '-' }
            ).Count -gt 1
        ) {

            $board.SystemProductName =
                $board.SystemProductName -replace '-', ' '
        }

        $board.SystemVersion =
            "1.0"

        $board.SystemSerial =
            Get-RandomDefaultString

        $board.SystemSKU =
            Get-RandomDefaultString

        $board.SystemFamily =
            Get-RandomDefaultString

        $board.BaseBoardManufacturer =
            "Micro-Star International Co., Ltd."

        $board.BaseBoardProduct =
            $mobo.ProductName `
                -replace '\s*\(rev\.[^)]*\)', ''

        $board.BaseBoardVersion =
            "1.0"

        $board.BaseBoardSerial =
            Get-RandomMsiBoardSerial `
                -ModelCode $modelCode

        $board.BaseBoardAssetTag =
            "To be filled by O.E.M."

        $board.BaseBoardLocation =
            "To be filled by O.E.M."

        $board.SEManufacturer =
            "Micro-Star International Co., Ltd."

        $board.SEVersion =
            "1.0"

        $board.SESerial =
            Get-RandomDefaultString

        $board.SEAssetTag =
            Get-RandomDefaultString

        $board.SESKU =
            Get-RandomDefaultString
    }


    # ========================================
    # ASRock
    # ========================================

    elseif ($SelectedManufacturer -ieq "asrock") {

        $board.biosVendor =
            Get-Random -InputObject $biosVendorStrings

        $board.biosVersion =
            Get-RandomDefaultString

        $board.SystemManufacturer =
            "ASRock"

        $board.SystemProductName =
            $mobo.ProductName `
                -replace '\s*\(rev\.[^)]*\)', ''

        if (
            (
                $board.SystemProductName.ToCharArray() |
                Where-Object { $_ -eq '-' }
            ).Count -gt 1
        ) {

            $board.SystemProductName =
                $board.SystemProductName -replace '-', ' '
        }

        $board.SystemVersion =
            Get-RandomDefaultString

        $board.SystemSerial =
            Get-RandomDefaultString

        $board.SystemSKU =
            Get-RandomDefaultString

        $board.SystemFamily =
            Get-RandomDefaultString

        $board.BaseBoardManufacturer =
            "ASRock"

        $board.BaseBoardProduct =
            $board.SystemProductName

        $board.BaseBoardVersion =
            Get-RandomDefaultString

        $board.BaseBoardSerial =
            Get-ASRockSerial

        $board.BaseBoardAssetTag =
            Get-RandomDefaultString

        $board.BaseBoardLocation =
            Get-RandomDefaultString

        $board.SEManufacturer =
            Get-RandomDefaultString

        $board.SEVersion =
            Get-RandomDefaultString

        $board.SESerial =
            Get-RandomDefaultString

        $board.SEAssetTag =
            Get-RandomDefaultString

        $board.SESKU =
            Get-RandomDefaultString
    }


    # ========================================
    # Unknown manufacturer
    # ========================================

    else {

        Write-Host ""
        Write-Host "[ERROR] Unsupported motherboard manufacturer:"
        Write-Host "  $($mobo.Manufacturer)"
        Write-Host ""

        return $null
    }


    # ========================================
    # Return generated profile
    # ========================================

    return [PSCustomObject]@{

        Mobo = $mobo

        Board = $board

        Platform =
            $Platform

        Memory =
            $Memory

        ProductName =
            $ProductName

        SelectedManufacturer =
            $SelectedManufacturer
    }
}


# ============================================
# Generate SMBIOS commands
# ============================================

function New-SMBIOSCommands {

    param (
        [Parameter(Mandatory = $true)]
        [object]$Profile,

        [Parameter(Mandatory = $false)]
        [object]$Backup = $null
    )

    if (-not $Profile) {

        Write-Host "[ERROR] Profile is null."
        return @()
    }

    $board = $Profile.Board
    $commands = @()


    # ========================================
    # BIOS
    # ========================================

    $commands += "AMIDEWINx64.exe /IVN `"$($board.biosVendor)`""
    $commands += "AMIDEWINx64.exe /IV `"$($board.biosVersion)`""
    $commands += "AMIDEWINx64.exe /ID `"$($board.biosDate)`""


    # ========================================
    # System
    # ========================================

    $commands += "AMIDEWINx64.exe /SM `"$($board.SystemManufacturer)`""
    $commands += "AMIDEWINx64.exe /SP `"$($board.SystemProductName)`""
    $commands += "AMIDEWINx64.exe /SV `"$($board.SystemVersion)`""
    $commands += "AMIDEWINx64.exe /SS `"$($board.SystemSerial)`""
    $commands += "AMIDEWINx64.exe /SU $($board.SystemUUID)"
    $commands += "AMIDEWINx64.exe /SK `"$($board.SystemSKU)`""
    $commands += "AMIDEWINx64.exe /SF `"$($board.SystemFamily)`""


    # ========================================
    # BaseBoard
    # ========================================

    $commands += "AMIDEWINx64.exe /BM `"$($board.BaseBoardManufacturer)`""
    $commands += "AMIDEWINx64.exe /BP `"$($board.BaseBoardProduct)`""
    $commands += "AMIDEWINx64.exe /BV `"$($board.BaseBoardVersion)`""
    $commands += "AMIDEWINx64.exe /BS `"$($board.BaseBoardSerial)`""
    $commands += "AMIDEWINx64.exe /BT `"$($board.BaseBoardAssetTag)`""
    $commands += "AMIDEWINx64.exe /BLC `"$($board.BaseBoardLocation)`""


    # ========================================
    # System Enclosure
    # ========================================

    $commands += "AMIDEWINx64.exe /CM `"$($board.SEManufacturer)`""
    $commands += "AMIDEWINx64.exe /CV `"$($board.SEVersion)`""
    $commands += "AMIDEWINx64.exe /CS `"$($board.SESerial)`""
    $commands += "AMIDEWINx64.exe /CA `"$($board.SEAssetTag)`""

    if ($null -ne $board.SESKU) {

        $commands += "AMIDEWINx64.exe /CSK `"$($board.SESKU)`""
    }


    # ========================================
    # Processor
    # ========================================

    $commands += "AMIDEWINx64.exe /PSN `"$($board.ProcessorSerial)`""
    $commands += "AMIDEWINx64.exe /PAT `"$($board.ProcessorAssetTag)`""
    $commands += "AMIDEWINx64.exe /PPN `"$($board.ProcessorPartNumber)`""


    # ========================================
    # OEM strings
    # ========================================

    $commands += "AMIDEWINx64.exe /OS 1 `"$($board.OEMString1)`""
    $commands += "AMIDEWINx64.exe /SCO 1 `"$($board.SCOString1)`""


    # ========================================
    # Backup-dependent strings
    # ========================================

    if ($null -ne $Backup) {

        if ($Backup.PSObject.Properties.Name -contains "OSCount") {

            for ($i = 1; $i -le $Backup.OSCount; $i++) {

                if ($i -eq 1) {
                    continue
                }

                $commands += "AMIDEWINx64.exe /OS $i `"$(
                    Get-RandomDefaultString
                )`""
            }
        }

        if ($Backup.PSObject.Properties.Name -contains "SCOCount") {

            for ($i = 1; $i -le $Backup.SCOCount; $i++) {

                if ($i -eq 1) {
                    continue
                }

                $commands += "AMIDEWINx64.exe /SCO $i `"$(
                    Get-RandomDefaultString
                )`""
            }
        }
    }


    return $commands
}


# ============================================
# Execute SMBIOS commands
# ============================================

function Invoke-SMBIOSCommands {

    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Commands
    )

    Write-Host ""
    Write-Host "============================================"
    Write-Host "          SMBIOS COMMAND EXECUTION"
    Write-Host "============================================"
    Write-Host ""

    if (-not $Commands -or $Commands.Count -eq 0) {

        Write-Host "[ERROR] No commands to execute."
        Write-Host ""

        return
    }

    foreach ($command in $Commands) {

        Write-Host "Executing:"
        Write-Host "  $command"
        Write-Host ""

        if ($command -match 'AMIDEWINx64\.exe\s+(.*)$') {

            $arguments = $Matches[1]

            $psi = [System.Diagnostics.ProcessStartInfo]::new()

            $psi.FileName =
                $amidewinPath

            $psi.Arguments =
                $arguments

            $psi.WorkingDirectory =
                $amidewinWorkingDirectory

            $psi.UseShellExecute =
                $true

            $psi.Verb =
                "runas"

            $process =
                [System.Diagnostics.Process]::new()

            $process.StartInfo =
                $psi

            try {

                [void]$process.Start()

                $process.WaitForExit()

                if ($process.ExitCode -eq 0) {

                    Write-Host "Done"
                }
                else {

                    Write-Host "AMIDEWIN exited with code: $($process.ExitCode)"
                }
            }
            catch {

                Write-Host "FAILED: $($_.Exception.Message)"
            }
        }
        else {

            Write-Host "[ERROR] Invalid AMIDEWIN command:"
            Write-Host "  $command"
        }

        Write-Host ""
    }
}