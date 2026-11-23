# Guía de Troubleshooting en Terreno — Tótem Boletos.la Chile (WIT)

## 1. Chrome muestra `Failed to fetch` o "Sin conexión al POS / Impresora"
- **Causa 1:** El backend local no está corriendo en puerto `3000`.
  - Verificar con: `Invoke-RestMethod http://localhost:3000/health`
  - Si no responde, iniciar `C:\ProgramData\kiosk\start-backend.bat`.
- **Causa 2:** Chrome 157+ bloqueó acceso a red local (`LocalNetworkAccess`).
  - Verificar en `chrome://policy` que existan `LocalNetworkAccessAllowedForUrls`, `LoopbackNetworkAllowedForUrls` y `LocalNetworkAllowedForUrls` apuntando al dominio del frontend.
  - Si faltan, volver a ejecutar `scripts\01-instalar-totem.bat` como Administrador y reiniciar Chrome por completo.

## 2. El Pinpad Transbank aparece desconectado (`connected: false`)
- Verificar que el cable USB del Pinpad esté firme y que aparezca en *Administrador de dispositivos → Puertos (COM y LPT)*.
- Consultar puertos visibles por el backend:
  ```powershell
  Invoke-RestMethod http://localhost:3000/api/terminal/ports
  ```
- **Causa común:** Hay otra sesión de Windows abierta (ej. `Innovapro` y `totem1` al mismo tiempo) corriendo otro `node.exe` que retiene el puerto `COM5`.
  - Solución: cerrar sesiones duplicadas o ejecutar `taskkill /F /IM node.exe` y relanzar un único backend.
- Si es la primera vez que se usa el Pinpad en el equipo o tras cambio de comercio, cargar llaves:
  ```powershell
  Invoke-RestMethod -Method Post http://localhost:3000/api/terminal/loadKeys
  ```

## 3. La impresora `w80` no imprime o abre ventana emergente
- Confirmar nombre exacto `w80` en Windows: `Get-Printer -Name w80`.
- Probar impresión RAW directa sin Chrome:
  ```powershell
  powershell -ExecutionPolicy Bypass -File scripts\02-verificar-totem.ps1 -PrintTest
  ```
- Si imprime desde PowerShell pero no desde Chrome, revisar políticas de Chrome (`LocalNetworkAccess`) para que llegue a `POST http://localhost:3000/api/print`.
- Desde la pantalla del tótem, puedes probar en cualquier momento entrando a **Imprimir Pasaje** e ingresando el código técnico **`PC-TEST`**.

## 4. No aparecen viajes disponibles al buscar rutas
- Verificar conectividad a Meta-GDS Global: `https://gds-global.dev-wit.com/api/v1`.
- Confirmar que la fecha/hora de Windows (`America/Santiago`) esté sincronizada correctamente.
- Confirmar que el frontend publicado esté operando en el canal activo **`B2C_CHILE`** (no `TOTEM_AUTOSERVICIO` mientras ese canal no tenga operadores habilitados en Meta-GDS).

## 5. Error al instalar dependencias `npm install` (`@serialport/bindings`)
- Verificar versión de Node con `node -v`. Debe ser **`v14.18.2` (x64)**. Si se instaló Node 18/20/22, desinstalar e instalar Node `v14.18.2`.

## 6. Acceso al Panel Técnico del Tótem
- Tocar **5 veces seguidas** en la esquina superior izquierda de la pantalla (dentro de 2 segundos).
- Ingresar PIN **`1379`**.
- Opciones disponibles: Recargar UI, Tiempo de inactividad del screensaver, Bloqueo manual offline, Limpiar caché de videos y Desvincular Tótem.
