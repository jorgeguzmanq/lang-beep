# lang-beep

**Stop losing three words every time Windows silently switches your keyboard language.**

If you type in more than one language, you know the drill: hit **Win + Space**, keep typing, and only notice you're still on the wrong layout after `ñ` shows up as `;` (or your accents just vanish). macOS nails this with a clean on-screen indicator. Windows... doesn't, really — its built-in language flag is easy to miss and most people turn it off.

`lang-beep` fixes that with two dead-simple signals, fired the instant you switch:

- 🔊 **A beep** — one tone per language, counted by its position in your Windows language list (1st language → 1 beep, 2nd → 2 beeps, ...). You learn to recognize it without looking up.
- 🪟 **A popup** — the language code (`ENG`, `SPA`, `POR`, ...) in a small rounded card, centered on **every monitor**, gone in under a second. Just enough to confirm with a glance.

No settings UI, no background bloat — it's a ~250-line PowerShell script that watches your active keyboard layout and reacts.

## Install

There's no compiled `.exe` — it's a plain PowerShell script, so there's nothing for Windows Defender or SmartScreen to be suspicious about.

1. Download this repo: click **Code → Download ZIP** on GitHub (or `git clone https://github.com/jorgeguzmanq/lang-beep.git`), then extract it.
2. Double-click **`install.bat`**.

That's it. It registers a self-healing Scheduled Task (starts on login, restarts itself every minute if it ever dies) and launches the service immediately. Double-click **`uninstall.bat`** anytime to remove it.

Prefer the terminal?

```powershell
git clone https://github.com/jorgeguzmanq/lang-beep.git
cd lang-beep
./install.ps1
```

Full guides: [INSTALL.en.md](INSTALL.en.md) · [INSTALL.es.md](INSTALL.es.md) · [INSTALL.pt.md](INSTALL.pt.md)

## Why it just works

- **Dynamic, zero config** — reads the real language order straight from the registry, so it works on any Windows setup without touching the code.
- **Any language** — beep count comes from list *position*, not a hardcoded map; the popup label comes from `CultureInfo`, so it covers whatever languages Windows itself supports.
- **Never in your way** — the popup can't steal focus, ignores whatever app is on top (even GPU-composited windows like Chrome/Electron), and disappears on its own.
- **Fast** — the popup runs in-process on its own thread, not a spawned process, so it's essentially instant after the beep.
- **Crash-proof** — a single mutex keeps one instance alive; the main loop never dies on a stray error, it just logs and keeps going.

## Structure

```
lang-beep.ps1          # Main script: detection + beeps by position + popup
lang-beep-hidden.vbs   # Silent launcher (no console window)
install.ps1 / .bat     # Installer (Scheduled Task + immediate start)
uninstall.ps1 / .bat   # Uninstaller
```

## Contributing

This is deliberately small and hackable. Want to add a language mapping, swap the sound, add a settings UI? PRs welcome — it's built for exactly that.
