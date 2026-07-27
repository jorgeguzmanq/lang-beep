# install.ps1 - Instala lang-beep para el usuario actual.
# Portable: usa su propia ubicacion, no rutas fijas.
# Crea una Tarea Programada al iniciar sesion (con auto-reinicio si el proceso
# muere) y arranca el script ya mismo, oculto.

$ErrorActionPreference = 'Stop'
$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbs      = Join-Path $here 'lang-beep-hidden.vbs'
$TaskName = 'lang-beep'

if (-not (Test-Path $vbs)) {
    throw "No se encontro lang-beep-hidden.vbs junto a este instalador ($here)."
}

# --- 0) Limpiar instalacion anterior ---
# Acceso directo heredado en la carpeta Inicio (version antigua).
$oldLnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'lang-beep.lnk'
if (Test-Path $oldLnk) {
    Remove-Item $oldLnk -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Eliminado acceso directo heredado: $oldLnk"
}
# Tarea previa con el mismo nombre.
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[OK] Eliminada tarea previa '$TaskName'"
}

# --- 1) Crear la Tarea Programada (al iniciar sesion + repeticion cada minuto) ---
# El auto-reinicio se logra re-lanzando cada minuto: si el script murio, la
# siguiente repeticion lo revive; si esta vivo, la copia nueva se cierra sola
# (mutex de instancia unica dentro de lang-beep.ps1).
$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + $vbs + '"') -WorkingDirectory $here

# Disparador 1: al iniciar sesion (arranque inmediato tras login).
$tLogon = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
# Disparador 2: time-based con hora concreta + repeticion cada minuto. Este SI
# tiene StartBoundary, asi que dispara a mitad de sesion y revive el script si
# murio (auto-reinicio). Base un minuto en el pasado para que arranque enseguida.
$tRepeat = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(-1)) `
        -RepetitionInterval (New-TimeSpan -Minutes 1) `
        -RepetitionDuration (New-TimeSpan -Days 3650)
$trigger = @($tLogon, $tRepeat)

# Ejecuta en la sesion interactiva del usuario actual (necesario para sonido).
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -MultipleInstances Parallel

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings `
    -Description 'Beep al cambiar idioma de teclado (Win+Space). Auto-reinicio cada minuto.' | Out-Null
Write-Host "[OK] Tarea Programada '$TaskName' creada (logon + repeticion 1 min para auto-reinicio)."

# --- 2) Detener instancia previa del script si quedo viva ---
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*-WindowStyle Hidden*-File*lang-beep.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue; Write-Host "[OK] Detenida instancia previa PID $($_.ProcessId)" }

# --- 3) Arrancar ahora (oculto) ---
Start-Process wscript.exe -ArgumentList ('"' + $vbs + '"')
Write-Host "[OK] lang-beep en ejecucion. Prueba con Win+Space."
