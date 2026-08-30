# ============================================
# Hardware Detection
# ============================================

function Get-CurrentHardwareDefaults {

    $result = [PSCustomObject]@{
        Manufacturer = "Any"
        Platform     = "Any"
        Memory       = "DDR4"
        Product      = ""
    }

    # ========================================
    # Motherboard
    # ========================================

    try {

        $baseboard = Get-CimInstance `
            Win32_BaseBoard `
            -ErrorAction Stop |
            Select-Object -First 1

        $manufacturer = [string]$baseboard.Manufacturer
        $product = [string]$baseboard.Product

        if ($manufacturer -match "Gigabyte") {

            $result.Manufacturer = "Gigabyte"
        }
        elseif ($manufacturer -match "ASUSTeK|ASUS") {

            $result.Manufacturer = "ASUS"
        }
        elseif ($manufacturer -match "Micro-Star|MSI") {

            $result.Manufacturer = "MSI"
        }
        elseif ($manufacturer -match "ASRock") {

            $result.Manufacturer = "ASRock"
        }

        $result.Product = $product
    }
    catch {

        # Keep defaults if motherboard detection fails.
    }

    # ========================================
    # Memory
    # ========================================

    try {

        $memoryModules = @(
            Get-CimInstance `
                Win32_PhysicalMemory `
                -ErrorAction Stop
        )

        foreach ($module in $memoryModules) {

            switch ([int]$module.SMBIOSMemoryType) {

                26 {

                    $result.Memory = "DDR4"
                    break
                }

                34 {

                    $result.Memory = "DDR5"
                    break
                }
            }

            if ($result.Memory -eq "DDR5") {
                break
            }
        }
    }
    catch {

        # Keep DDR4 fallback.
    }

    # ========================================
    # CPU / Platform
    # ========================================

    try {

        $cpu = Get-CimInstance `
            Win32_Processor `
            -ErrorAction Stop |
            Select-Object -First 1

        $cpuName = [string]$cpu.Name

        if ($cpuName -match "Intel") {

            $result.Platform = "Intel"
        }
        elseif ($cpuName -match "AMD|Ryzen") {

            # Try to determine AM4 vs AM5
            # from the motherboard product.

            if ($product -match `
                "X870|X870E|X670|X670E|B650|B650E|B850|B850E|A620|A620A") {

                $result.Platform = "AM5"
            }
            elseif ($product -match `
                "X570|X470|X370|B550|B450|B350|A520|A320|B450M|B550M") {

                $result.Platform = "AM4"
            }
        }
    }
    catch {

        # Leave platform as Any if detection fails.
    }

    return $result
}