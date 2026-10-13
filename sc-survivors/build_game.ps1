# Script de exportación automática para SC: Survivors
$ErrorActionPreference = "Stop"

$ProjectDir = $PSScriptRoot
$DesktopDir = "C:\Users\toffe\Desktop"
$GodotExe = "C:\Users\toffe\Desktop\Godot_v4.5.1-stable_win64.exe"
$DistDir = Join-Path $DesktopDir "SC_Survivors_Alpha_v1.0"
$ZipFile = Join-Path $DesktopDir "SC_Survivors_Alpha_v1.0.zip"

Write-Host "1. Cerrando instancias previas..."
Get-Process -Name "*SC_Survivors*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

Write-Host "2. Re-importando assets limpios con Godot..."
& "$GodotExe" --headless --editor --quit

Write-Host "3. Compilando y exportando proyecto con Godot..."
$cmd = "`"$GodotExe`" --headless --export-release win SC_Survivors.exe"
cmd /c $cmd

if (!(Test-Path (Join-Path $ProjectDir "SC_Survivors.exe")) -or !(Test-Path (Join-Path $ProjectDir "SC_Survivors.pck"))) {
    Write-Error "Fallo en la exportación: SC_Survivors.exe o SC_Survivors.pck no se generaron."
    exit 1
}

Write-Host "3. Copiando al Escritorio..."
Copy-Item (Join-Path $ProjectDir "SC_Survivors.exe") (Join-Path $DesktopDir "SC_Survivors.exe") -Force
Copy-Item (Join-Path $ProjectDir "SC_Survivors.pck") (Join-Path $DesktopDir "SC_Survivors.pck") -Force

Write-Host "4. Copiando a carpeta de distribución..."
if (!(Test-Path $DistDir)) { New-Item -ItemType Directory -Path $DistDir -Force }
Copy-Item (Join-Path $ProjectDir "SC_Survivors.exe") (Join-Path $DistDir "SC_Survivors.exe") -Force
Copy-Item (Join-Path $ProjectDir "SC_Survivors.pck") (Join-Path $DistDir "SC_Survivors.pck") -Force

Write-Host "5. Comprimiendo archivo ZIP..."
Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $DistDir "*") -DestinationPath $ZipFile -Force

Write-Host "6. Limpiando binarios temporales del repositorio..."
Remove-Item (Join-Path $ProjectDir "SC_Survivors.exe") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ProjectDir "SC_Survivors.pck") -Force -ErrorAction SilentlyContinue

Write-Host "Compilación completada exitosamente! Ejecutable limpio en: $DesktopDir\SC_Survivors.exe"
