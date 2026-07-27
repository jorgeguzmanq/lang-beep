# lang-beep — version compilada (portable)

Un solo ejecutable, sin necesidad de tener PowerShell visible ni permisos de
ejecucion de scripts:

- `lang-beep.exe` — detecta el cambio de idioma de teclado (Win+Space), hace sonar los beeps y muestra el popup visual con el codigo de idioma (todo en el mismo proceso).

## Instalar en otro equipo

1. Copia `lang-beep.exe` a una carpeta (por ejemplo `C:\Tools\lang-beep\`).
2. Crea una Tarea Programada que lo arranque al iniciar sesion:

   ```powershell
   $exe = 'C:\Tools\lang-beep\lang-beep.exe'
   $action = New-ScheduledTaskAction -Execute $exe -WorkingDirectory (Split-Path $exe)
   $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
   $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
   Register-ScheduledTask -TaskName 'lang-beep' -Action $action -Trigger $trigger -Principal $principal
   ```

3. Arranca ahora mismo sin reiniciar sesion:

   ```powershell
   Start-Process 'C:\Tools\lang-beep\lang-beep.exe'
   ```

Prueba con Win+Space: deberia sonar y mostrar el popup con el codigo de idioma en el centro de cada pantalla.

## Notas

- No requiere `-ExecutionPolicy Bypass` ni que el usuario tenga PowerShell habilitado para scripts: son ejecutables nativos generados con PS2EXE.
- El log de actividad (`lang-beep.log`) se escribe junto al `.exe`.
- Para desinstalar: `Unregister-ScheduledTask -TaskName 'lang-beep' -Confirm:$false` y borrar la carpeta.
