# lang-beep — Install guide

## English

**What it does:** detects a keyboard language switch (**Win + Space**) and beeps
according to that language's position in your Windows language list — 1st
language → 1 beep, 2nd → 2 beeps, etc. — plus a popup with the language code
on every screen. Dynamic: reads the real order from the registry, works on
any Windows without touching the code.

**Install:**
1. Download [`install/install.zip`](../install/install.zip) (or `git clone` this repo) and extract it.
2. Double-click **`install.bat`** (or run `./install.ps1` in PowerShell).

`install.ps1` copies the script to `%LocalAppData%\lang-beep` first, then
registers a self-healing Scheduled Task pointing there (starts on login,
restarts itself every minute if it ever dies) and starts the service
immediately. Because it runs from that stable copy, you can delete the
downloaded zip/folder right after installing.

**Verify:** focus any app, press **Win + Space** — you should hear N beeps and
see the popup on every monitor.

**Uninstall:** double-click **`uninstall.bat`** (or run `./uninstall.ps1`). Removes
the Scheduled Task, stops the process, and deletes the `%LocalAppData%\lang-beep` copy.

**Customize:** edit `Beep(880, 120)` in `lang-beep.ps1` (→ `Beep(frequencyHz, durationMs)`)
or `Start-Sleep -Milliseconds 250` (how often the active language is polled),
then re-run `install.ps1` so the change gets copied to `%LocalAppData%\lang-beep`.

**Troubleshooting:** check `lang-beep.log` in `%LocalAppData%\lang-beep`. If the
process died, the Scheduled Task revives it within a minute — confirm with
`Get-ScheduledTask -TaskName 'lang-beep'`.

---

## Español

**Qué hace:** detecta el cambio de idioma de teclado (**Win + Space**) y hace
sonar beeps según la posición de ese idioma en tu lista de Windows — idioma 1
→ 1 beep, idioma 2 → 2 beeps, etc. — además de un popup con el código del
idioma en cada pantalla. Es dinámico: lee el orden real desde el registro,
funciona en cualquier Windows sin tocar el código.

**Instalar:**
1. Descarga [`install/install.zip`](../install/install.zip) (o haz `git clone` de este repo) y descomprímelo.
2. Doble clic en **`install.bat`** (o corre `./install.ps1` en PowerShell).

`install.ps1` primero copia el script a `%LocalAppData%\lang-beep`, y ahí sí
registra una Tarea Programada con auto-reinicio (arranca al iniciar sesión, se
revive sola si muere) y arranca el servicio de inmediato. Como corre desde esa
copia estable, puedes borrar el zip/carpeta descargado apenas termine de instalar.

**Verificar:** pon el foco en cualquier app y pulsa **Win + Space** — deberías
oír N beeps y ver el popup en cada monitor.

**Desinstalar:** doble clic en **`uninstall.bat`** (o corre `./uninstall.ps1`).
Quita la Tarea Programada, detiene el proceso y borra la copia en `%LocalAppData%\lang-beep`.

**Personalizar:** edita `Beep(880, 120)` en `lang-beep.ps1` (→ `Beep(frecuenciaHz, duraciónMs)`)
o `Start-Sleep -Milliseconds 250` (cada cuánto se revisa el idioma activo), y
vuelve a correr `install.ps1` para que el cambio se copie a `%LocalAppData%\lang-beep`.

**Solución de problemas:** revisa `lang-beep.log` en `%LocalAppData%\lang-beep`.
Si el proceso murió, la Tarea Programada lo revive en menos de un minuto —
confirma con `Get-ScheduledTask -TaskName 'lang-beep'`.

---

## Português

**O que faz:** detecta a troca de idioma de teclado (**Win + Space**) e emite
beeps conforme a posição desse idioma na sua lista do Windows — idioma 1 → 1
beep, idioma 2 → 2 beeps, etc. — além de um popup com o código do idioma em
cada tela. É dinâmico: lê a ordem real do registro, funciona em qualquer
Windows sem editar o código.

**Instalar:**
1. Baixe [`install/install.zip`](../install/install.zip) (ou `git clone` deste repo) e extraia.
2. Clique duas vezes em **`install.bat`** (ou rode `./install.ps1` no PowerShell).

`install.ps1` primeiro copia o script para `%LocalAppData%\lang-beep`, e só
então registra uma Tarefa Agendada com auto-reinício (inicia no login, se
revive sozinha se morrer) e inicia o serviço imediatamente. Como roda a partir
dessa cópia estável, você pode apagar o zip/pasta baixado assim que terminar.

**Verificar:** foque qualquer app e pressione **Win + Space** — você deve
ouvir N beeps e ver o popup em cada monitor.

**Desinstalar:** clique duas vezes em **`uninstall.bat`** (ou rode
`./uninstall.ps1`). Remove a Tarefa Agendada, para o processo e apaga a cópia em `%LocalAppData%\lang-beep`.

**Personalizar:** edite `Beep(880, 120)` em `lang-beep.ps1` (→ `Beep(frequênciaHz, duraçãoMs)`)
ou `Start-Sleep -Milliseconds 250` (frequência da checagem do idioma ativo), e
rode `install.ps1` de novo para copiar a mudança para `%LocalAppData%\lang-beep`.

**Solução de problemas:** veja `lang-beep.log` em `%LocalAppData%\lang-beep`. Se o
processo morreu, a Tarefa Agendada o revive em menos de um minuto — confirme
com `Get-ScheduledTask -TaskName 'lang-beep'`.
