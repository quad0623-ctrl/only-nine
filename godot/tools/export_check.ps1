# Export Windows + Android and report results.
$ErrorActionPreference = "Continue"
$Godot = "C:\Users\sian\AppData\Local\Godot\bin\godot.cmd"
$Project = "C:\Users\sian\only-nine\godot"
$WinOut = Join-Path $Project "export\windows\OnlyNine.exe"
$AabOut = Join-Path $Project "export\android\OnlyNine.aab"
$ApkOut = Join-Path $Project "export\android\OnlyNine.apk"
$Cfg = Join-Path $Project "export_presets.cfg"

New-Item -ItemType Directory -Force -Path (Split-Path $WinOut) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $AabOut) | Out-Null

Write-Output "=== GODOT VERSION ==="
& $Godot --version 2>&1

Write-Output "`n=== WINDOWS EXPORT ==="
& $Godot --path $Project --headless --export-release "Windows Steam" $WinOut 2>&1 | Out-Host
Write-Output "WIN_EXIT=$LASTEXITCODE"
if (Test-Path $WinOut) {
  $wi = Get-Item $WinOut
  Write-Output ("WIN_OK size={0} mtime={1}" -f $wi.Length, $wi.LastWriteTime)
} else { Write-Output "WIN_MISSING" }

Write-Output "`n=== ANDROID AAB EXPORT ==="
& $Godot --path $Project --headless --export-release "Android" $AabOut 2>&1 | Out-Host
Write-Output "AAB_EXIT=$LASTEXITCODE"
if (Test-Path $AabOut) {
  $ai = Get-Item $AabOut
  Write-Output ("AAB_OK size={0} mtime={1}" -f $ai.Length, $ai.LastWriteTime)
} else { Write-Output "AAB_MISSING" }

Write-Output "`n=== ANDROID APK EXPORT ==="
$raw = Get-Content $Cfg -Raw
$raw2 = $raw -replace 'gradle_build/export_format=1','gradle_build/export_format=0' -replace 'export_path="export/android/OnlyNine.aab"','export_path="export/android/OnlyNine.apk"'
Set-Content $Cfg -Value $raw2 -NoNewline
& $Godot --path $Project --headless --export-debug "Android" $ApkOut 2>&1 | Out-Host
Write-Output "APK_EXIT=$LASTEXITCODE"
Set-Content $Cfg -Value $raw -NoNewline
if (Test-Path $ApkOut) {
  $pi = Get-Item $ApkOut
  Write-Output ("APK_OK size={0} mtime={1}" -f $pi.Length, $pi.LastWriteTime)
} else { Write-Output "APK_MISSING" }
