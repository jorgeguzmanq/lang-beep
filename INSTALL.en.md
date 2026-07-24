# lang-beep — Installation guide (English)

> **What it does:** detects keyboard language/layout switches on Windows
> (the **Win + Space** shortcut) and emits *beeps* based on the **position of the
> language in that PC's language list**: language 1 → **1 beep**, language 2 →
> **2 beeps**, language 3 → **3 beeps**, etc.
>
> It is **dynamic and universal**: it reads the machine's real language order, so
> it works on any Windows **without editing the code**.

Instructions for an **agent/LLM** with access to a **PowerShell** terminal on
Windows. Follow the steps in order.

---

## 0. Assumptions
- **OS:** Windows 10 or 11. **Shell:** PowerShell 5.1 or 7.
- **Permissions:** standard user (no admin needed). Per-user install.
- **Portable:** runs from any folder; scripts resolve their own path.

## 1. Package files
```
lang-beep/
├─ lang-beep.ps1          # Main script (detection + position-based beeps)
├─ lang-beep-hidden.vbs   # Silent launcher (no console window)
├─ install.ps1            # Installer (autostart + immediate start)
├─ uninstall.ps1          # Uninstaller
└─ INSTALL.en.md          # This file (also INSTALL.es.md / INSTALL.pt.md)
```
Confirm all files are in the same folder before continuing.

## 2. (Optional) Inspect the user's language order
Beep count = the language's position. To view/confirm the order:
```powershell
$preload = Get-ItemProperty 'HKCU:\Keyboard Layout\Preload'
$preload.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } |
  Sort-Object { [int]$_.Name } | ForEach-Object {
    $lcid = [Convert]::ToInt64($_.Value,16) -band 0xFFFF
    "Position {0} -> LCID 0x{1:X4} ({0} beeps)" -f [int]$_.Name, $lcid
  }
```
> The user can **reorder** languages in *Settings → Time & language → Language*.
> The script honors that order automatically (nothing to edit).

## 3. (Optional) Test detection
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
It should print the current language's LCID (e.g. `LangId=0x0409`).

## 4. Install
From the package folder:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\install.ps1"
```
The installer: (1) creates a **Scheduled Task** named `lang-beep` that starts at
sign-in **and repeats every minute** (auto-restart: if the process dies, the next
repetition revives it; if it is alive, the new copy exits on its own via a
single-instance *mutex*); (2) stops any previous instance and removes the legacy
Startup-folder shortcut if present; (3) starts the script **right now**, hidden.

## 5. Verify
- Focus any app and press **Win + Space** to cycle languages.
- You should hear N beeps according to the language's position.
- Confirm the process is alive:
```powershell
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*lang-beep.ps1*' } |
  Select-Object ProcessId
```

## 6. Uninstall
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\uninstall.ps1"
```
Removes the Scheduled Task (and the legacy shortcut) and stops the process (does
not delete the folder's files).

---

## Customization
- **Tone/duration:** in `lang-beep.ps1`, `[Console]::Beep(880, 120)` →
  `Beep(frequencyHz, durationMs)`.
- **Reaction speed:** `Start-Sleep -Milliseconds 250` (how often the language is
  polled).

## How it works
It does not hook the Win+Space key; it **polls** the foreground window's language
(`GetForegroundWindow` → `GetWindowThreadProcessId` → `GetKeyboardLayout`; the low
word of the `HKL` is the LCID). The beep uses the **kernel32** `Beep` API (works
even when the process is hidden, unlike `[Console]::Beep`). It reads the language
order from `HKCU\Keyboard Layout\Preload`, and the beep count is the active
language's 1-based position. The loop is **fail-safe**: any error is logged to
`lang-beep.log` and it keeps going, never terminating the script. It runs in the
user session (not as a service).

## Troubleshooting
- **No sound:** check the volume and that the language is in the list (step 2).
- **Stopped beeping:** check `lang-beep.log` (in the script folder) for errors,
  and confirm the task is active and the process alive:
  ```powershell
  Get-ScheduledTask -TaskName 'lang-beep' | Select-Object State
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*-File*lang-beep.ps1*' -and $_.CommandLine -notlike '*CimInstance*' }
  ```
  Even if the process dies, the task revives it within ≤1 min.
- **Doesn't start after reboot:** confirm the task with
  `Get-ScheduledTask -TaskName 'lang-beep'`. If missing, re-run `install.ps1`.
- **ExecutionPolicy:** the commands use `-ExecutionPolicy Bypass`; do not change
  the global policy.
