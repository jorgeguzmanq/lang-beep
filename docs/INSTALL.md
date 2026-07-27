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

This registers a self-healing Scheduled Task (starts on login, restarts itself
every minute if it ever dies) and starts the service immediately.

**Verify:** focus any app, press **Win + Space** — you should hear N beeps and
see the popup on every monitor.

**Uninstall:** double-click **`uninstall.bat`** (or run `./uninstall.ps1`). Removes
the Scheduled Task and stops the process; does not delete the folder.

**Customize:** in `lang-beep.ps1`, `Beep(880, 120)` is `Beep(frequencyHz, durationMs)`;
`Start-Sleep -Milliseconds 250` controls how often the active language is polled.

**Troubleshooting:** check `lang-beep.log` next to the script. If the process
died, the Scheduled Task revives it within a minute — confirm with
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

Esto registra una Tarea Programada con auto-reinicio (arranca al iniciar
sesión, se revive sola si muere) y arranca el servicio de inmediato.

**Verificar:** pon el foco en cualquier app y pulsa **Win + Space** — deberías
oír N beeps y ver el popup en cada monitor.

**Desinstalar:** doble clic en **`uninstall.bat`** (o corre `./uninstall.ps1`).
Quita la Tarea Programada y detiene el proceso; no borra la carpeta.

**Personalizar:** en `lang-beep.ps1`, `Beep(880, 120)` es `Beep(frecuenciaHz, duraciónMs)`;
`Start-Sleep -Milliseconds 250` controla cada cuánto se revisa el idioma activo.

**Solución de problemas:** revisa `lang-beep.log` junto al script. Si el
proceso murió, la Tarea Programada lo revive en menos de un minuto — confirma
con `Get-ScheduledTask -TaskName 'lang-beep'`.

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

Isso registra uma Tarefa Agendada com auto-reinício (inicia no login, se
revive sozinha se morrer) e inicia o serviço imediatamente.

**Verificar:** foque qualquer app e pressione **Win + Space** — você deve
ouvir N beeps e ver o popup em cada monitor.

**Desinstalar:** clique duas vezes em **`uninstall.bat`** (ou rode
`./uninstall.ps1`). Remove a Tarefa Agendada e para o processo; não apaga a pasta.

**Personalizar:** em `lang-beep.ps1`, `Beep(880, 120)` é `Beep(frequênciaHz, duraçãoMs)`;
`Start-Sleep -Milliseconds 250` controla a frequência da checagem do idioma ativo.

**Solução de problemas:** veja `lang-beep.log` ao lado do script. Se o
processo morreu, a Tarefa Agendada o revive em menos de um minuto — confirme
com `Get-ScheduledTask -TaskName 'lang-beep'`.
