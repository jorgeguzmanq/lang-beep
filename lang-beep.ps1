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

[DllImport("user32.dll")]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

[DllImport("user32.dll")]
public static extern bool AllowSetForegroundWindow(int dwProcessId);
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

# Cuerpo del popup: corre en su propio Runspace STA (mismo proceso) en vez de
# un proceso nuevo, para no pagar arranque de CLR en cada cambio de idioma
# (eso era la causa del retraso frente al beep, que es casi instantaneo).
$PopupScriptBlock = {
    param($Text)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    function Get-RoundedRegion([int]$width, [int]$height, [int]$radius) {
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $d = $radius * 2
        $path.AddArc(0, 0, $d, $d, 180, 90)
        $path.AddArc($width - $d, 0, $d, $d, 270, 90)
        $path.AddArc($width - $d, $height - $d, $d, $d, 0, 90)
        $path.AddArc(0, $height - $d, $d, $d, 90, 90)
        $path.CloseFigure()
        return New-Object System.Drawing.Region($path)
    }

    # Levanta el bloqueo de "foreground lock" de Windows para que este proceso
    # (que corre en segundo plano, sin ser la app activa) pueda de verdad
    # colocar sus ventanas por encima de la app en foco.
    try { [void][Native.WinLayout]::AllowSetForegroundWindow(-1) } catch { }

    $allScreens = [System.Windows.Forms.Screen]::AllScreens

    $forms = @()
    $w = 160; $h = 100
    $SWP_NOMOVE = 0x0002; $SWP_NOSIZE = 0x0001; $SWP_NOACTIVATE = 0x0010; $SWP_SHOWWINDOW = 0x0040

    foreach ($screen in $allScreens) {
        $form = New-Object System.Windows.Forms.Form
        $form.FormBorderStyle = 'None'
        $form.StartPosition   = 'Manual'
        $form.TopMost         = $true
        $form.ShowInTaskbar   = $false
        $form.BackColor       = [System.Drawing.Color]::White
        $form.Size            = New-Object System.Drawing.Size($w, $h)
        $form.Opacity         = 0.92
        $form.Region          = Get-RoundedRegion $w $h 40

        $bounds = $screen.Bounds
        $x = $bounds.X + [int](($bounds.Width - $w) / 2)
        $y = $bounds.Y + [int](($bounds.Height - $h) / 2)
        $form.Location = New-Object System.Drawing.Point($x, $y)

        $label = New-Object System.Windows.Forms.Label
        $label.Text      = $Text
        $label.Font      = New-Object System.Drawing.Font('Segoe UI', 28, [System.Drawing.FontStyle]::Bold)
        $label.ForeColor = [System.Drawing.Color]::Black
        $label.TextAlign = 'MiddleCenter'
        $label.Dock      = 'Fill'
        $form.Controls.Add($label)

        $forms += $form
        $form.Show()

        # Refuerzo Win32: HWND_TOPMOST (-1) explicito, por encima de lo que hace
        # la propiedad TopMost de WinForms, para ganarle a apps con superficies
        # compuestas por GPU (Chrome/Electron) que a veces ignoran el orden Z.
        [void][Native.WinLayout]::SetWindowPos($form.Handle, [IntPtr]-1, 0, 0, 0, 0, ($SWP_NOMOVE -bor $SWP_NOSIZE -bor $SWP_NOACTIVATE -bor $SWP_SHOWWINDOW))
    }

    # ApplicationContext.ExitThread() termina SOLO el bucle de mensajes de este
    # hilo. Application.Exit() (lo que se usaba antes) termina el bucle de
    # mensajes de TODOS los hilos del proceso -> si dos popups se disparaban
    # cerca uno del otro, el primero en cerrar cortaba a medias al segundo
    # (por eso a veces se veia en todas las pantallas y a veces en una sola).
    $ctx = New-Object System.Windows.Forms.ApplicationContext
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 800
    $timer.Add_Tick({
        $timer.Stop()
        foreach ($f in $forms) { $f.Close() }
        $ctx.ExitThread()
    })
    $timer.Start()
    [System.Windows.Forms.Application]::Run($ctx)
}

$global:PendingPopups = New-Object System.Collections.Generic.List[object]

# Lanza el popup en un Runspace STA nuevo (no bloquea el bucle de deteccion,
# no crea un proceso nuevo).
function Show-LangPopup([string]$text) {
    try {
        $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $rs.ApartmentState = 'STA'
        $rs.ThreadOptions  = 'UseNewThread'
        $rs.Open()
        $psi = [System.Management.Automation.PowerShell]::Create()
        $psi.Runspace = $rs
        [void]$psi.AddScript($PopupScriptBlock).AddArgument($text)
        $async = $psi.BeginInvoke()
        $global:PendingPopups.Add([PSCustomObject]@{ PS = $psi; RS = $rs; Async = $async })
    } catch {
        Write-Log "Error mostrando popup: $($_.Exception.Message)"
    }
}

# Libera los Runspaces de popups que ya terminaron (evita fugas de memoria).
function Clear-CompletedPopups {
    if ($global:PendingPopups.Count -eq 0) { return }
    $still = New-Object System.Collections.Generic.List[object]
    foreach ($p in $global:PendingPopups) {
        if ($p.Async.IsCompleted) {
            try { $p.PS.EndInvoke($p.Async) } catch { }
            try { $p.PS.Dispose() } catch { }
            try { $p.RS.Close(); $p.RS.Dispose() } catch { }
        } else {
            $still.Add($p)
        }
    }
    $global:PendingPopups = $still
}

# --- Bucle principal (a prueba de fallos) ---
Write-Log "lang-beep iniciado (PID $PID)"
# Precarga los ensamblados de WinForms en el proceso para que ni el primer
# popup pague el costo de carga (queda compartido para todos los Runspaces).
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { }
$order = @()
try { $order = Get-OrderedLangIds } catch { Write-Log "Error leyendo Preload al inicio: $($_.Exception.Message)" }
$last  = 0
try { $last = Get-ActiveLangId } catch { }

while ($true) {
    Start-Sleep -Milliseconds 250
    try {
        Clear-CompletedPopups
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
