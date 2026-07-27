# uninstall.ps1 - Desinstala lang-beep para el usuario actual.
# Quita la Tarea Programada (y el acceso directo heredado si existe), detiene
# el proceso en ejecucion y borra la copia instalada en %LocalAppData%\lang-beep
# (install.ps1 copia ahi los archivos; no es una carpeta que el usuario gestione).

$ErrorActionPreference = 'Stop'
$TaskName   = 'lang-beep'
$InstallDir = Join-Path $env:LOCALAPPDATA 'lang-beep'

# 1) Quitar la Tarea Programada
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[OK] Tarea Programada '$TaskName' eliminada."
} else {
    Write-Host "[i] No habia Tarea Programada '$TaskName'."
}

# 2) Quitar acceso directo heredado de la carpeta Inicio (version antigua)
$oldLnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'lang-beep.lnk'
if (Test-Path $oldLnk) {
    Remove-Item $oldLnk -Force
    Write-Host "[OK] Acceso directo heredado eliminado: $oldLnk"
}

# 3) Detener el proceso en ejecucion
$found = $false
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*-WindowStyle Hidden*-File*lang-beep.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force; $script:found = $true; Write-Host "[OK] Detenido PID $($_.ProcessId)" }
if (-not $found) { Write-Host "[i] No habia proceso en ejecucion." }

# 4) Borrar la copia instalada (la carpeta desde donde corriste esto NO se toca)
if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Eliminado $InstallDir"
}

Write-Host "[OK] lang-beep desinstalado."
