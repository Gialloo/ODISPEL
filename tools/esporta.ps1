# Crea la versione per Windows di ODISPEL in build\ODISPEL-<versione>\ e la comprime in .zip.
# Uso (PowerShell, dalla cartella del progetto):   .\tools\esporta.ps1
# Serve Godot 4.7.x con i "modelli di esportazione" installati (Editor > Gestisci modelli di esportazione).
param(
    [string]$Godot = "godot",
    [string]$Versione = ""
)

$ErrorActionPreference = "Stop"
$radice = Split-Path -Parent $PSScriptRoot
Set-Location $radice

if ($Versione -eq "") {
    $riga = Select-String -Path "scripts\config\game_config.gd" -Pattern 'VERSION: String = "(.+)"'
    $Versione = $riga.Matches[0].Groups[1].Value
}

$cartella = "build\ODISPEL-$Versione"
if (Test-Path $cartella) { Remove-Item $cartella -Recurse -Force }
New-Item -ItemType Directory -Path $cartella | Out-Null

Write-Host "1/4  Importo le risorse..."
& $Godot --headless --path . --import | Out-Null

Write-Host "2/4  Esporto l'eseguibile..."
& $Godot --headless --path . --export-release "Windows Desktop" "$cartella\ODISPEL.exe"
if (-not (Test-Path "$cartella\ODISPEL.exe")) {
    throw "Esportazione non riuscita: controlla i modelli di esportazione (Editor > Gestisci modelli di esportazione)."
}

Write-Host "3/4  Aggiungo cartelle per grafiche e dialoghi..."
New-Item -ItemType Directory -Path "$cartella\art" | Out-Null
New-Item -ItemType Directory -Path "$cartella\dialogues" | Out-Null
Copy-Item "docs\GUIDA_ARTE.md" "$cartella\art\LEGGIMI.md"
if (Test-Path "art") { Copy-Item "art\*" "$cartella\art" -Recurse -Force }
Copy-Item "docs\PROVA_ONLINE.md" "$cartella\LEGGIMI.md"

Write-Host "4/4  Comprimo..."
$zip = "build\ODISPEL-$Versione.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$cartella\*" -DestinationPath $zip

Write-Host ""
Write-Host "Fatto: $zip"
Write-Host "Mandalo agli amici: basta decomprimere e aprire ODISPEL.exe."
