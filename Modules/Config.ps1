# ============================================
# Configuration
# ============================================

Add-Type -AssemblyName System.Windows.Forms

# ============================================
# Root directory
# ============================================

$rootDirectory = Split-Path $PSScriptRoot -Parent

# ============================================
# Load configuration
# ============================================

$configFile = Join-Path $rootDirectory "config.json"

if (-not (Test-Path $configFile)) {

    $config = @{
        AMIDEWINVersion = "OTHER"
    }

    $config | ConvertTo-Json |
        Set-Content -Path $configFile -Encoding UTF8
}
else {

    $config = Get-Content $configFile -Raw |
        ConvertFrom-Json
}

# ============================================
# AMIDEWIN configuration
# ============================================

$amidewinVersion = [string]$config.AMIDEWINVersion
$amidewinVersion = $amidewinVersion.Trim()

# ============================================
# Build AMIDEWIN directory
# ============================================

$amidewinDirectory = Join-Path `
    $rootDirectory `
    "AMIDEWINx64\$amidewinVersion"

# ============================================
# Build executable path
# ============================================

$amidewinPath = Join-Path `
    $amidewinDirectory `
    "AMIDEWINx64.exe"

# ============================================
# Working directory
# ============================================

$amidewinWorkingDirectory = $amidewinDirectory

# ============================================
# Validate AMIDEWIN
# ============================================

if (-not (Test-Path $amidewinPath -PathType Leaf)) {

    Write-Host "[ERROR] AMIDEWINx64.exe was not found:"
    Write-Host $amidewinPath
    Write-Host ""

    Write-Host "Expected structure:"
    Write-Host "$rootDirectory\AMIDEWINx64\$amidewinVersion\AMIDEWINx64.exe"

    exit 1
}

Write-Host "AMIDEWIN version: $amidewinVersion"
Write-Host "AMIDEWIN path:    $amidewinPath"
Write-Host "Working directory: $amidewinWorkingDirectory"

# ============================================
# Load motherboard database
# ============================================

$moboFile = Join-Path $rootDirectory "Mobo.json"

if (-not (Test-Path $moboFile)) {

    Write-Host "[ERROR] Mobo.json was not found:"
    Write-Host $moboFile

    exit 1
}

try {

    $mobos = Get-Content $moboFile -Raw |
        ConvertFrom-Json
}
catch {

    Write-Host "[ERROR] Failed to parse Mobo.json"
    Write-Host $_.Exception.Message

    exit 1
}