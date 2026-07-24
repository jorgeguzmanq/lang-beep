# lang-beep

Detecta el cambio de idioma/distribución de teclado en Windows (**Win + Space**)
y te avisa de dos formas a la vez:

- **Sonido**: un beep por cada posición del idioma en tu lista de Windows —
  idioma 1 → 1 beep, idioma 2 → 2 beeps, etc.
- **Visual**: un popup centrado en pantalla (todas las pantallas conectadas)
  con el código del idioma (`ENG`, `SPA`, ...) que aparece y se desvanece en
  menos de un segundo.

Es dinámico: lee el orden real de idiomas desde el registro, así que funciona
en cualquier Windows sin tocar el código.

## Instalación rápida (desde el código fuente)

```powershell
git clone https://github.com/jorgeguzmanq/lang-beep.git
cd lang-beep
./install.ps1
```

Crea una Tarea Programada (auto-reinicio, arranca al iniciar sesión) y lanza
el servicio de inmediato. Para desinstalar: `./uninstall.ps1`.

Guías detalladas: [INSTALL.es.md](INSTALL.es.md) · [INSTALL.en.md](INSTALL.en.md) · [INSTALL.pt.md](INSTALL.pt.md)

## Instalación sin PowerShell (ejecutable)

Si no quieres correr scripts, descarga `lang-beep.exe` +
`lang-beep-popup.exe` desde la sección [Releases](../../releases) de este
repo y sigue las instrucciones incluidas ahí (`dist/README.md` en el código
fuente).

## Estructura

```
lang-beep.ps1          # Script principal: detección + beeps por posición
lang-beep-popup.ps1    # Popup visual del idioma (lo lanza lang-beep.ps1)
lang-beep-hidden.vbs   # Lanzador silencioso (sin ventana de consola)
install.ps1            # Instalador (Tarea Programada + arranque inmediato)
uninstall.ps1          # Desinstalador
dist/                  # Ejecutables compilados (PS2EXE) — no versionado, ver Releases
```
