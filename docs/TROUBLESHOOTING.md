# Guía de Troubleshooting en Terreno — Tótem Boletos.la Chile (WIT)

## 1. Chrome muestra `Failed to fetch` o "Sin conexión al POS / Impresora"
- **Causa 1:** El backend local no está corriendo en puerto `3000`.
  - Verificar con: `Invoke-RestMethod http://localhost:3000/health`
  - Si no responde, probar en vivo:
    ```powershell
    cd C:\ProgramData\kiosk\backend
    & "C:\Program Files\nodejs\node.exe" src/server.js
    ```
  - Si arroja `Cannot find module 'express'`, falta instalar dependencias:
    ```powershell
    & "C:\Program Files\nodejs\npm.cmd" install --production
    ```
- **Causa 2:** Chrome 157+ bloqueó acceso a red local (`LocalNetworkAccess`).
  - Verificar en `chrome://policy` que existan `LocalNetworkAccessAllowedForUrls`, `LoopbackNetworkAllowedForUrls` y `LocalNetworkAllowedForUrls` apuntando al dominio del frontend.
  - Si faltan, volver a ejecutar `scripts\01-instalar-totem.bat` como Administrador y reiniciar Chrome por completo.

## 2. Al reiniciar Windows dice "No se encuentra chrome.exe"
- **Causa:** Chrome se instaló en el perfil de usuario (`C:\Users\wit\AppData\Local\Google\Chrome\Application\chrome.exe`) en lugar de `C:\Program Files\...`.
- **Solución:** Asegúrate de usar la versión actualizada de `C:\ProgramData\kiosk\shell.bat` generada por `scripts\01-instalar-totem.bat`, la cual busca dinámicamente en `Program Files`, `(x86)` y `%LocalAppData%`. Para futuros equipos, se recomienda instalar Google Chrome usando el paquete Offline/Enterprise 64-bit o ejecutar el instalador como Administrador.

## 3. Chrome recarga infinitamente en "INICIANDO SISTEMA / Conectando con el servidor..."
- **Causa:** Un `shell.bat` antiguo usaba `start /wait chrome.exe` que retornaba inmediato si ya existía otro proceso Chrome en memoria, provocando que el bucle relanzara la URL cada 2 segundos; o quedaron dos instancias de `shell.bat` abiertas al mismo tiempo.
- **Solución:**
  1. Cerrar procesos colgados: `taskkill /F /IM chrome.exe; taskkill /F /IM cmd.exe`
  2. Regenerar `shell.bat` con `scripts\01-instalar-totem.bat` (usa `tasklist` para no relanzar si Chrome ya está abierto).

## 4. El Pinpad Transbank aparece desconectado (`connected: false`)
- Verificar que el cable USB del Pinpad esté firme y que aparezca en *Administrador de dispositivos → Puertos (COM y LPT)*.
- Consultar puertos visibles por el backend:
  ```powershell
  Invoke-RestMethod http://localhost:3000/api/terminal/ports
  ```
- **Terminales PAX (`VID_2FB8`):** Exponen múltiples puertos (`COM3`, `COM4`, `COM5`). El backend prioriza automáticamente la interfaz **`MI_00`** (normalmente `COM5`) con +190 puntos en `portScore`.
- **Causa común:** Hay otro `node.exe` o ventana previa reteniendo el puerto `COM`.
  - Solución: ejecutar `taskkill /F /IM node.exe` y relanzar un único backend.
- Si es la primera vez que se usa el Pinpad en el equipo o tras cambio de comercio, cargar llaves:
  ```powershell
  Invoke-RestMethod -Method Post http://localhost:3000/api/terminal/loadKeys
  ```

## 5. La impresora térmica (ej. SPRT 80mm / POS-80) no aparece en `Get-Printer` o no imprime
- En Windows 11 de fábrica, conectar una impresora térmica USB (como `SPRT SC260324  80mm Series`) la registra en clase `USB`, pero **sin cola de impresión**.
- Registrar el driver universal en el Spooler y crear la cola apuntando a `USB001` (respetando su nombre nativo):
  ```powershell
  Add-PrinterDriver -Name "Generic / Text Only"
  Add-Printer -Name "SPRT SC260324  80mm Series" -DriverName "Generic / Text Only" -PortName "USB001"
  ```
  *(Nota: en Windows en español, si el driver se llama `"Genérica / Sólo texto"`, reemplaza ese nombre en ambos comandos).*
- Probar impresión RAW directa sin Chrome:
  ```powershell
  powershell -ExecutionPolicy Bypass -File scripts\02-verificar-totem.ps1 -PrintTest
  ```
- Desde la pantalla del tótem, puedes probar en cualquier momento entrando a **Imprimir Pasaje** e ingresando el código técnico **`PC-TEST`**.

## 6. No aparecen viajes disponibles al buscar rutas
- Verificar conectividad a Meta-GDS Global: `https://gds-global.dev-wit.com/api/v1`.
- Confirmar que la fecha/hora de Windows (`America/Santiago`) esté sincronizada correctamente.
- Confirmar que el frontend publicado esté operando en el canal activo **`B2C_CHILE`**.

## 7. Error en PowerShell: "la ejecución de scripts está deshabilitada en este sistema"
- Ejecutar una sola vez como Administrador:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
  ```

## 8. Error al instalar dependencias `npm install` (`@serialport/bindings`)
- Verificar versión de Node con `& "C:\Program Files\nodejs\node.exe" -v`. Debe ser **`v14.18.2` (x64)**. Si se instaló Node 18/20/22, desinstalar e instalar Node `v14.18.2` manualmente.

## 9. Acceso al Panel Técnico del Tótem
- Tocar **5 veces seguidas** en la esquina superior izquierda de la pantalla (dentro de 2 segundos).
- Ingresar PIN **`1379`**.
- Opciones disponibles: Recargar UI, Tiempo de inactividad del screensaver, Bloqueo manual offline, Limpiar caché de videos y Desvincular Tótem.
