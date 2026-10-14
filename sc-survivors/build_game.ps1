param (
    [string]$SetVersion = "",
    [switch]$NoIncrement = $false
)

# Script de exportación automática para SC: Survivors con Versionado Auto-incremental
$ErrorActionPreference = "Stop"

$ProjectDir = $PSScriptRoot
$DesktopDir = "C:\Users\toffe\Desktop"
$GodotExe = "C:\Users\toffe\Desktop\Godot_v4.5.1-stable_win64.exe"
$VersionFile = Join-Path $ProjectDir "version.txt"

# 1. Determinar y gestionar versión
if (-not (Test-Path $VersionFile)) {
    "0.333" | Out-File -FilePath $VersionFile -Encoding utf8 -NoNewline
}

$CurrentVersion = (Get-Content $VersionFile -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($CurrentVersion)) {
    $CurrentVersion = "0.333"
}

if (-not [string]::IsNullOrWhiteSpace($SetVersion)) {
    $CurrentVersion = $SetVersion.Trim()
    $CurrentVersion | Out-File -FilePath $VersionFile -Encoding utf8 -NoNewline
}

$Version = $CurrentVersion
$DistDir = Join-Path $DesktopDir "SC_Survivors_v$Version"
$ZipFile = Join-Path $DesktopDir "SC_Survivors_v$Version.zip"

Write-Host "=========================================="
Write-Host "  Compilando StarCraft: Survivors v$Version"
Write-Host "=========================================="

Push-Location $ProjectDir
try {
    Write-Host "1. Cerrando instancias previas..."
    Get-Process -Name "*SC_Survivors*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500

    Write-Host "2. Re-importando assets limpios con Godot..."
    & "$GodotExe" --headless --editor --quit

    Write-Host "3. Compilando y exportando proyecto con Godot..."
    $cmd = "`"$GodotExe`" --headless --export-release win SC_Survivors.exe"
    cmd /c $cmd

    if (!(Test-Path "SC_Survivors.exe") -or !(Test-Path "SC_Survivors.pck")) {
        Write-Error "Fallo en la exportación: SC_Survivors.exe o SC_Survivors.pck no se generaron."
        exit 1
    }

    Write-Host "4. Copiando ejecutable limpio al Escritorio..."
    Copy-Item "SC_Survivors.exe" (Join-Path $DesktopDir "SC_Survivors.exe") -Force
    Copy-Item "SC_Survivors.pck" (Join-Path $DesktopDir "SC_Survivors.pck") -Force

    Write-Host "5. Generando carpeta de distribución versionada: $DistDir..."
    if (Test-Path $DistDir) { Remove-Item $DistDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
    Copy-Item "SC_Survivors.exe" (Join-Path $DistDir "SC_Survivors.exe") -Force
    Copy-Item "SC_Survivors.pck" (Join-Path $DistDir "SC_Survivors.pck") -Force

    Write-Host "6. Comprimiendo archivo ZIP de distribución: $ZipFile..."
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    Compress-Archive -Path (Join-Path $DistDir "*") -DestinationPath $ZipFile -Force

    Write-Host "7. Limpiando binarios temporales del repositorio..."
    Remove-Item "SC_Survivors.exe" -Force -ErrorAction SilentlyContinue
    Remove-Item "SC_Survivors.pck" -Force -ErrorAction SilentlyContinue

    # Auto-incremento para la siguiente compilación si no se especificó -NoIncrement
    if (-not $NoIncrement) {
        if ($Version -match "^(\d+)\.(\d+)$") {
            $major = $matches[1]
            $minor = [int]$matches[2] + 1
            $NextVersion = "$major.$minor"
        } else {
            $parts = $Version.Split(".")
            if ($parts.Length -gt 1) {
                $lastIndex = $parts.Length - 1
                $lastVal = [int]$parts[$lastIndex] + 1
                $parts[$lastIndex] = $lastVal.ToString()
                $NextVersion = [string]::Join(".", $parts)
            } else {
                $NextVersion = "$Version.1"
            }
        }
        $NextVersion | Out-File -FilePath $VersionFile -Encoding utf8 -NoNewline
        Write-Host "-> Versión actualizada en $VersionFile para el siguiente build: v$NextVersion"
    }

    Write-Host "Compilación v$Version completada con éxito!"
    Write-Host "-> Ejecutable: $DesktopDir\SC_Survivors.exe"
    Write-Host "-> ZIP de distribución: $ZipFile"
}
finally {
    Pop-Location
}
