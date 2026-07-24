# lang-beep.ps1
# Detecta el cambio de distribucion/idioma de teclado (Win + Space) y emite
# beeps segun la POSICION del idioma en la lista de idiomas de Windows:
#   idioma 1 -> 1 beep, idioma 2 -> 2 beeps, idioma 3 -> 3 beeps, ...
#
# Es dinamico: lee el orden real desde el registro (HKCU\Keyboard Layout\Preload),
# por lo que funciona en cualquier Windows sin editar codigo.
#
# Diseno a prueba de fallos: el bucle principal NUNCA muere por un error puntual;
# cualquier excepcion se registra en lang-beep.log y se continua.

# Solo el arranque inicial usa Stop; el bucle se protege con try/catch propio.
$ErrorActionPreference = 'Continue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogPath   = Join-Path $ScriptDir 'lang-beep.log'
$MaxLogBytes = 256KB

# --- Instancia unica (mutex) ---
# La tarea programada re-lanza el script cada minuto para auto-reiniciarlo si
# murio. Si ya hay una instancia viva, esta copia se cierra de inmediato para no
# apilar procesos ni duplicar beeps.
$global:LangBeepMutex = New-Object System.Threading.Mutex($false, 'Local\lang-beep-singleton')
$haveMutex = $false
try { $haveMutex = $global:LangBeepMutex.WaitOne(0) }
catch [System.Threading.AbandonedMutexException] { $haveMutex = $true }  # la anterior murio: tomamos el relevo
if (-not $haveMutex) { exit }

function Write-Log([string]$msg) {
    try {
        # Recortar el log si crece demasiado.
        if ((Test-Path $LogPath) -and ((Get-Item $LogPath).Length -gt $MaxLogBytes)) {
            Remove-Item $LogPath -Force -ErrorAction SilentlyContinue
        }
        $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Add-Content -Path $LogPath -Value "[$stamp] $msg" -ErrorAction SilentlyContinue
    } catch { }
}

# --- API de Windows: layout de teclado activo + beep por kernel32 ---
# kernel32 Beep no requiere handle de consola -> funciona aunque el proceso
# corra oculto (a diferencia de [Console]::Beep, que puede lanzar excepcion).
$signature = @'
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();

[DllImport("user32.dll")]
public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr ProcessId);

[DllImport("user32.dll")]
public static extern IntPtr GetKeyboardLayout(uint idThread);

[DllImport("kernel32.dll")]
public static extern bool Beep(uint dwFreq, uint dwDuration);
'@

$Win = Add-Type -MemberDefinition $signature -Name 'WinLayout' -Namespace 'Native' -PassThru

# Devuelve el LCID activo, o 0 si no hay ventana en primer plano (bloqueo, etc.).
function Get-ActiveLangId {
    $hWnd = $Win::GetForegroundWindow()
    if ($hWnd -eq [IntPtr]::Zero) { return 0 }
    $thread = $Win::GetWindowThreadProcessId($hWnd, [IntPtr]::Zero)
    $hkl    = $Win::GetKeyboardLayout($thread)
    # El LCID (idioma) esta en la palabra baja del HKL.
    return ([int64]$hkl -band 0xFFFF)
}

# Lee la lista ordenada de LCIDs desde el registro (orden del selector de idioma).
function Get-OrderedLangIds {
    $preload = Get-ItemProperty 'HKCU:\Keyboard Layout\Preload'
    $entries = $preload.PSObject.Properties |
        Where-Object { $_.Name -match '^\d+$' } |
        Sort-Object { [int]$_.Name }
    $ids = @()
    foreach ($e in $entries) {
        $lcid = [Convert]::ToInt64($e.Value, 16) -band 0xFFFF
        $ids += [int]$lcid
    }
    return $ids
}

# Numero de beeps = posicion (1-based) del idioma en la lista. 0 si no se halla.
function Get-BeepCount([int]$langId, [ref]$orderRef) {
    $idx = [array]::IndexOf($orderRef.Value, $langId)
    if ($idx -lt 0) {
        # Idioma no conocido: refrescar la lista (pudo agregarse en caliente).
        $orderRef.Value = Get-OrderedLangIds
        $idx = [array]::IndexOf($orderRef.Value, $langId)
    }
    if ($idx -lt 0) { return 0 }
    return $idx + 1
}

function Play-Beeps([int]$count) {
    for ($i = 0; $i -lt $count; $i++) {
        [void]$Win::Beep(880, 120)
        if ($i -lt $count - 1) { Start-Sleep -Milliseconds 80 }
    }
}

# Codigo ISO de 3 letras del idioma (ENG, SPA, POR, ...) para mostrar en el popup.
function Get-LangLabel([int]$langId) {
    try {
        $ci = New-Object System.Globalization.CultureInfo($langId)
        return $ci.ThreeLetterISOLanguageName.ToUpper()
    } catch {
        return '??'
    }
}

$PopupExe    = Join-Path $ScriptDir 'lang-beep-popup.exe'
$PopupScript = Join-Path $ScriptDir 'lang-beep-popup.ps1'

# Lanza el popup como proceso independiente (no bloquea el bucle de deteccion).
# Usa el ejecutable compilado si esta presente (distribucion sin PowerShell
# visible); si no, cae al .ps1 (uso en desarrollo).
function Show-LangPopup([string]$text) {
    try {
        if (Test-Path $PopupExe) {
            Start-Process -FilePath $PopupExe -ArgumentList $text
        } else {
            Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PopupScript`"", $text
            )
        }
    } catch {
        Write-Log "Error mostrando popup: $($_.Exception.Message)"
    }
}

# --- Bucle principal (a prueba de fallos) ---
Write-Log "lang-beep iniciado (PID $PID)"
$order = @()
try { $order = Get-OrderedLangIds } catch { Write-Log "Error leyendo Preload al inicio: $($_.Exception.Message)" }
$last  = 0
try { $last = Get-ActiveLangId } catch { }

while ($true) {
    Start-Sleep -Milliseconds 250
    try {
        $current = Get-ActiveLangId
        # 0 = sin ventana valida (bloqueo/escritorio seguro): no tocar $last.
        if ($current -eq 0) { continue }
        if ($current -ne $last) {
            $last = $current
            $beeps = Get-BeepCount $current ([ref]$order)
            if ($beeps -gt 0) {
                Show-LangPopup (Get-LangLabel $current)
                Play-Beeps $beeps
            }
        }
    } catch {
        # Ningun error puede matar el script: registrar y continuar.
        Write-Log "Error en bucle: $($_.Exception.Message)"
        Start-Sleep -Seconds 1
        continue
    }
}
