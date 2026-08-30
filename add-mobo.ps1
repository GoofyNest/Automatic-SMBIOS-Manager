# add-mobo.ps1

$board = Get-CimInstance Win32_BaseBoard
$cpu   = Get-CimInstance Win32_Processor
$ram   = Get-CimInstance Win32_PhysicalMemory

$manufacturer = $board.Manufacturer
$productName  = $board.Product

$isIntel = $cpu.Manufacturer -match "Intel"
$isAMD   = $cpu.Manufacturer -match "AMD"

$memoryTypes = @($ram | ForEach-Object {
    switch ($_.SMBIOSMemoryType) {
        26 { "DDR4" }
        34 { "DDR5" }
    }
})

$isDDR4 = $memoryTypes -contains "DDR4"
$isDDR5 = $memoryTypes -contains "DDR5"

$socket = "Unknown"

if ($cpu.SocketDesignation) {
    $socket = $cpu.SocketDesignation
}

$entry = [ordered]@{
    Manufacturer = $manufacturer
    ProductName  = $productName
    IntelCPU     = $isIntel
    AMDCPU       = $isAMD
    DDR4         = $isDDR4
    DDR5         = $isDDR5
    RaidSupport  = $false
    Socket       = $socket
    Generation   = "Unknown"
}

$json = $entry | ConvertTo-Json

Set-Clipboard -Value $json

Write-Host ""
Write-Host "============================================"
Write-Host "       MOTHERBOARD ENTRY GENERATED"
Write-Host "============================================"
Write-Host ""
Write-Host $json
Write-Host ""
Write-Host "============================================"
Write-Host "JSON copied to clipboard."
Write-Host "Paste it into Mobo.json."
Write-Host "============================================"
Write-Host ""
