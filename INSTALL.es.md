# lang-beep — Guía de instalación (Español)

> **Qué hace:** detecta el cambio de idioma/distribución de teclado en Windows
> (el atajo **Win + Space**) y emite *beeps* según la **posición del idioma en la
> lista de idiomas** de ese Windows: idioma 1 → **1 beep**, idioma 2 → **2 beeps**,
> idioma 3 → **3 beeps**, etc.
>
> Es **dinámico y universal**: lee el orden real de idiomas del equipo, así que
> funciona en cualquier Windows **sin editar el código**.

Instrucciones para un **agente/LLM** con acceso a una terminal **PowerShell** en
Windows. Sigue los pasos en orden.

---

## 0. Supuestos
- **SO:** Windows 10 u 11. **Shell:** PowerShell 5.1 o 7.
- **Permisos:** usuario normal (no requiere admin). Instalación por-usuario.
- **Portable:** funciona desde cualquier carpeta; los scripts calculan su ruta.

## 1. Archivos del paquete
```
lang-beep/
├─ lang-beep.ps1          # Script principal (detección + beeps por posición)
├─ lang-beep-hidden.vbs   # Lanzador silencioso (sin ventana de consola)
├─ install.ps1            # Instalador (autoarranque + arranque inmediato)
├─ uninstall.ps1          # Desinstalador
└─ INSTALL.es.md          # Este archivo (también INSTALL.pt.md / INSTALL.en.md)
```
Verifica que los archivos estén en la misma carpeta antes de continuar.

## 2. (Opcional) Ver el orden de idiomas del usuario
El número de beeps = posición del idioma. Para ver/confirmar el orden:
```powershell
$preload = Get-ItemProperty 'HKCU:\Keyboard Layout\Preload'
$preload.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } |
  Sort-Object { [int]$_.Name } | ForEach-Object {
    $lcid = [Convert]::ToInt64($_.Value,16) -band 0xFFFF
    "Posicion {0} -> LCID 0x{1:X4} ({0} beeps)" -f [int]$_.Name, $lcid
  }
```
> El usuario puede **reordenar** los idiomas en *Configuración → Hora e idioma →
> Idioma*. El script respeta ese orden automáticamente (no hay que editar nada).

## 3. (Opcional) Probar la detección
```powershell
$sig=@'
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr pid);
[DllImport("user32.dll")] public static extern IntPtr GetKeyboardLayout(uint t);
'@
$w=Add-Type -MemberDefinition $sig -Name T -Namespace N -PassThru
$h=$w::GetForegroundWindow(); $th=$w::GetWindowThreadProcessId($h,[IntPtr]::Zero); $hkl=$w::GetKeyboardLayout($th)
"LangId=0x{0:X4}" -f ([int64]$hkl -band 0xFFFF)
```
Debe imprimir el LCID del idioma actual (p. ej. `LangId=0x0409`).

## 4. Instalar
Desde la carpeta del paquete:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\install.ps1"
```
El instalador: (1) crea una **Tarea Programada** llamada `lang-beep` que arranca
al iniciar sesión **y se repite cada minuto** (auto-reinicio: si el proceso muere,
la siguiente repetición lo revive; si está vivo, la copia nueva se cierra sola por
un *mutex* de instancia única); (2) detiene instancias previas y elimina el
acceso directo heredado de la carpeta Inicio si existe; (3) arranca el script
**ya mismo**, oculto.

## 5. Verificar
- Pon el foco en cualquier app y pulsa **Win + Space** para rotar idiomas.
- Debes oír N beeps según la posición del idioma.
- Confirmar que el proceso vive:
```powershell
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*lang-beep.ps1*' } |
  Select-Object ProcessId
```

## 6. Desinstalar
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\uninstall.ps1"
```
Quita la Tarea Programada (y el acceso directo heredado) y detiene el proceso
(no borra los archivos de la carpeta).

---

## Personalización
- **Tono/duración:** en `lang-beep.ps1`, `[Console]::Beep(880, 120)` →
  `Beep(frecuenciaHz, duraciónMs)`.
- **Velocidad de reacción:** `Start-Sleep -Milliseconds 250` (cada cuánto se
  comprueba el idioma).

## Cómo funciona
No engancha la tecla Win+Space; **sondea** el idioma de la ventana en primer plano
(`GetForegroundWindow` → `GetWindowThreadProcessId` → `GetKeyboardLayout`; la
palabra baja del `HKL` es el LCID). El beep usa la API `Beep` de **kernel32**
(funciona aunque el proceso esté oculto, a diferencia de `[Console]::Beep`). Lee
el orden de idiomas desde `HKCU\Keyboard Layout\Preload` y el número de beeps es
la posición (1-based) del idioma activo. El bucle es **a prueba de fallos**:
cualquier error se registra en `lang-beep.log` y continúa, nunca termina el script.
Corre en la sesión del usuario (no como servicio).

## Solución de problemas
- **No suena:** revisa el volumen y que el idioma esté en la lista (paso 2).
- **Dejó de sonar:** revisa `lang-beep.log` (en la carpeta del script) por si hay
  errores, y confirma que la tarea está activa y el proceso vivo:
  ```powershell
  Get-ScheduledTask -TaskName 'lang-beep' | Select-Object State
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*-File*lang-beep.ps1*' -and $_.CommandLine -notlike '*CimInstance*' }
  ```
  Aunque el proceso muera, la tarea lo revive en ≤1 min.
- **No arranca tras reiniciar:** confirma la tarea con
  `Get-ScheduledTask -TaskName 'lang-beep'`. Si no existe, reejecuta `install.ps1`.
- **ExecutionPolicy:** los comandos usan `-ExecutionPolicy Bypass`; no cambies la
  política global.
