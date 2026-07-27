# uninstall.ps1 - Desinstala lang-beep para el usuario actual.
# Quita la Tarea Programada (y el acceso directo heredado si existe) y detiene
# el proceso en ejecucion.

$ErrorActionPreference = 'Stop'
$TaskName = 'lang-beep'

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

Write-Host "[OK] lang-beep desinstalado. Los archivos de la carpeta NO se borran."
