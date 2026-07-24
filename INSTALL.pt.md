# lang-beep — Guia de instalação (Português)

> **O que faz:** detecta a troca de idioma/layout de teclado no Windows
> (o atalho **Win + Space**) e emite *beeps* conforme a **posição do idioma na
> lista de idiomas** daquele Windows: idioma 1 → **1 beep**, idioma 2 → **2 beeps**,
> idioma 3 → **3 beeps**, etc.
>
> É **dinâmico e universal**: lê a ordem real de idiomas da máquina, então
> funciona em qualquer Windows **sem editar o código**.

Instruções para um **agente/LLM** com acesso a um terminal **PowerShell** no
Windows. Siga os passos em ordem.

---

## 0. Pressupostos
- **SO:** Windows 10 ou 11. **Shell:** PowerShell 5.1 ou 7.
- **Permissões:** usuário comum (não exige admin). Instalação por-usuário.
- **Portátil:** funciona de qualquer pasta; os scripts calculam seu próprio caminho.

## 1. Arquivos do pacote
```
lang-beep/
├─ lang-beep.ps1          # Script principal (detecção + beeps por posição)
├─ lang-beep-hidden.vbs   # Lançador silencioso (sem janela de console)
├─ install.ps1            # Instalador (autostart + início imediato)
├─ uninstall.ps1          # Desinstalador
└─ INSTALL.pt.md          # Este arquivo (também INSTALL.es.md / INSTALL.en.md)
```
Verifique que os arquivos estejam na mesma pasta antes de continuar.

## 2. (Opcional) Ver a ordem de idiomas do usuário
O número de beeps = posição do idioma. Para ver/confirmar a ordem:
```powershell
$preload = Get-ItemProperty 'HKCU:\Keyboard Layout\Preload'
$preload.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } |
  Sort-Object { [int]$_.Name } | ForEach-Object {
    $lcid = [Convert]::ToInt64($_.Value,16) -band 0xFFFF
    "Posicao {0} -> LCID 0x{1:X4} ({0} beeps)" -f [int]$_.Name, $lcid
  }
```
> O usuário pode **reordenar** os idiomas em *Configurações → Hora e idioma →
> Idioma*. O script respeita essa ordem automaticamente (nada a editar).

## 3. (Opcional) Testar a detecção
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
Deve imprimir o LCID do idioma atual (ex.: `LangId=0x0409`).

## 4. Instalar
Da pasta do pacote:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\install.ps1"
```
O instalador: (1) cria uma **Tarefa Agendada** chamada `lang-beep` que inicia no
logon **e se repete a cada minuto** (auto-reinício: se o processo morrer, a
repetição seguinte o revive; se estiver vivo, a nova cópia se fecha sozinha por um
*mutex* de instância única); (2) encerra instâncias anteriores e remove o atalho
herdado da pasta Inicializar, se existir; (3) inicia o script **agora**, oculto.

## 5. Verificar
- Foque qualquer app e pressione **Win + Space** para alternar idiomas.
- Você deve ouvir N beeps conforme a posição do idioma.
- Confirmar que o processo está ativo:
```powershell
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*lang-beep.ps1*' } |
  Select-Object ProcessId
```

## 6. Desinstalar
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\uninstall.ps1"
```
Remove a Tarefa Agendada (e o atalho herdado) e encerra o processo (não apaga os
arquivos da pasta).

---

## Personalização
- **Tom/duração:** em `lang-beep.ps1`, `[Console]::Beep(880, 120)` →
  `Beep(frequênciaHz, duraçãoMs)`.
- **Velocidade de reação:** `Start-Sleep -Milliseconds 250` (intervalo de checagem).

## Como funciona
Não captura a tecla Win+Space; faz **polling** do idioma da janela em primeiro
plano (`GetForegroundWindow` → `GetWindowThreadProcessId` → `GetKeyboardLayout`;
a palavra baixa do `HKL` é o LCID). O beep usa a API `Beep` do **kernel32**
(funciona mesmo com o processo oculto, ao contrário de `[Console]::Beep`). Lê a
ordem de idiomas em `HKCU\Keyboard Layout\Preload` e o número de beeps é a posição
(base 1) do idioma ativo. O laço é **à prova de falhas**: qualquer erro é
registrado em `lang-beep.log` e ele continua, nunca encerra o script. Roda na
sessão do usuário (não como serviço).

## Solução de problemas
- **Não toca:** verifique o volume e se o idioma está na lista (passo 2).
- **Parou de tocar:** verifique `lang-beep.log` (na pasta do script) por erros e
  confirme que a tarefa está ativa e o processo vivo:
  ```powershell
  Get-ScheduledTask -TaskName 'lang-beep' | Select-Object State
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*-File*lang-beep.ps1*' -and $_.CommandLine -notlike '*CimInstance*' }
  ```
  Mesmo que o processo morra, a tarefa o revive em ≤1 min.
- **Não inicia após reiniciar:** confirme a tarefa com
  `Get-ScheduledTask -TaskName 'lang-beep'`. Se não existir, reexecute `install.ps1`.
- **ExecutionPolicy:** os comandos usam `-ExecutionPolicy Bypass`; não altere a
  política global.
