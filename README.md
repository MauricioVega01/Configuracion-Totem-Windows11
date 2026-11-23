# Instalador y Guía de Despliegue — Tótem Boletos.la Chile (Windows 11)

Repositorio oficial de aprovisionamiento, configuración y diagnóstico para instalar el **Tótem de Autoservicio Boletos.la Chile (WIT)** en cualquier equipo Windows 11 nuevo, incorporando todas las correcciones e implicancias resueltas en producción.

---

## Arquitectura Resumida

```text
[Tótem Windows 11 - Usuario: totem1]
 ├── Google Chrome Kiosk (1080x1920 vertical)
 │     ├── Frontend Web (Netlify): https://totem-testing-v3.netlify.app/
 │     ├── Microservicios Cloud WIT (HTTPS / WebSocket):
 │     │     ├── Meta-GDS Global (B2C_CHILE -> Kupos / Pullman Costa / Distribusion)
 │     │     ├── Convenios y Control de Tarifas (/control-tarifa)
 │     │     ├── Publicidad, Playlist, Flags Remotos y Ventas por Tótem
 │     │     ├── Analítica de Boletos (BD Cloud)
 │     │     └── Servicio Mail / PDF con QR
 │     └── Comunicación Local -> http://localhost:3000 (Políticas LocalNetworkAccess)
 └── Backend Local Node.js (C:\ProgramData\kiosk\backend - Puerto 3000, stateless)
       ├── POS Pinpad Transbank (USB-Serial COM autodetectado, 115200 bps)
       └── Impresora Térmica 80mm "w80" (RAW ESC/POS directo vía bin\rawprint.exe)
```

> **Importante:** El equipo del tótem **NO utiliza base de datos local (MySQL)** ni **PM2**. Toda la persistencia vive en los servidores cloud de WIT y el backend local funciona como un puente *stateless* liviano administrado directamente por `shell.bat` y `start-backend.bat`.

---

## Implicancias Críticas Resueltas por Este Instalador

| Problema real en Windows 11 / Chrome | Causa raíz | Cómo lo resuelve este repositorio |
| :--- | :--- | :--- |
| **`Failed to fetch` al llamar a `localhost:3000` desde Netlify HTTPS** | Chrome 157+ bloquea peticiones HTTPS hacia red local (`LocalNetworkAccess` / PNA). | Aplica políticas Enterprise en Registro (`LocalNetworkAccessAllowedForUrls`, `LoopbackNetworkAllowedForUrls`, `LocalNetworkAllowedForUrls`) **y** flags `--disable-features=...` en `shell.bat`. |
| **Diálogo de impresión emergente / bloqueos en Chrome Kiosk** | `window.print()` o cambios de impresora predeterminada en Windows. | Impresión silenciosa directa **RAW ESC/POS** vía `POST http://localhost:3000/api/print` (`bin\rawprint.exe`) + `LegacyDefaultPrinterMode=1` + `w80` fija. |
| **Error compilando `@serialport/bindings` o fallo con `transbank-pos-sdk`** | Versiones modernas de Node (18/20/22) rompen binarios nativos del SDK legacy de Transbank. | Estandarizado sobre **Node.js v14.18.2 (x64)** probado en producción. |
| **Puerto `COM` del Pinpad cambia al reconectar USB** | Windows asigna `COM3`, `COM4`, `COM5` dinámicamente. | `.env` configurado con `TBK_PORT_PATH=AUTO` + escaneo Windows `COM*` + reconexión automática tras 3 fallos de poll. |
| **Conflictos de puertos (`3000` vs `3010`) y procesos duplicados con PM2** | Servicios heredados en sesiones distintas (`Innovapro` vs `totem1`). | Puerto único **`3000`**, sin PM2, con limpieza preventiva (`taskkill`) en `shell.bat`. |
| **Suspensión o apagado automático de pantalla** | Plan de energía estándar de Windows 11. | `scripts/04-configurar-autologon.ps1` desactiva suspensión, hibernación y apagado de monitor vía `powercfg`. |

---

## Requisitos Previos (Antes de Ejecutar Scripts)

### Hardware
- PC Kiosco con **Windows 11** (64-bit) y pantalla táctil en orientación **Vertical (`1080×1920`, escala 100%)**.
- **Pinpad POS Transbank** conectado por USB (verificado como puerto `COMx` en *Administrador de dispositivos → Puertos (COM y LPT)*, ej. `USB\VID_2FB8&PID_225E`).
- **Impresora térmica 80mm** instalada en Windows con el nombre exacto **`w80`** (driver *MSW Printer Driver* o equivalente en `USB001`, cola `RAW`).
- Conexión estable a Internet (Ethernet recomendado).

### Software Base Obligatorio
1. **Node.js `v14.18.2` (x64)** — *Obligatorio usar rama 14.x para compatibilidad binaria con `transbank-pos-sdk` y `@serialport/bindings`.*
   - Descarga oficial: `https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi`
2. **Git for Windows** — `https://git-scm.com/download/win`
3. **Google Chrome (64-bit)** — instalado en `C:\Program Files\Google\Chrome\Application\chrome.exe`

---

## Paso a Paso de Instalación en un Tótem Nuevo

### Paso 1: Crear usuario kiosco y ajustar pantalla
1. Iniciar sesión con un usuario **Administrador** (ej. `Innovapro`).
2. Crear el usuario local estándar **`totem1`** (con contraseña definida para AutoLogon).
3. En **Configuración → Sistema → Pantalla**:
   - Resolución: `1080 × 1920`
   - Orientación: **Vertical**
   - Escala: **100%**
4. En **Configuración → Personalización → Pantalla de bloqueo**: desactivar protector de pantalla de Windows (el screensaver lo gestiona el software del tótem).

### Paso 2: Instalar impresora térmica y Pinpad Transbank
1. Instalar el driver de la impresora térmica de 80mm y renombrarla exactamente como **`w80`**.
2. Imprimir una página de prueba desde Windows para confirmar comunicación y corte de guillotina.
3. Conectar el Pinpad Transbank por USB, instalar su driver USB-Serial si Windows no lo reconoce automáticamente y verificar que aparezca un puerto **`COMx`** en el Administrador de dispositivos.

### Paso 3: Clonar este repositorio de instalación
Abrir PowerShell como **Administrador** y ejecutar:

```powershell
mkdir C:\InstalacionTotem -Force
cd C:\InstalacionTotem
git clone https://github.com/MauricioVega01/Configuracion-Totem-Windows11.git
cd Configuracion-Totem-Windows11
```

### Paso 4: Ejecutar el instalador automático maestro
Hacer doble clic (o ejecutar desde consola como Administrador) en:

```bat
scripts\01-instalar-totem.bat
```

El instalador solicitará interactivamente:
- **ID del Tótem** (ej. `101`, `102`, `103` — debe existir previamente en el Mantenedor de Publicidad).
- **Nombre de la impresora térmica** (por defecto: `w80`).
- **URL del Frontend Kiosco** (por defecto: `https://totem-testing-v3.netlify.app/`).
- **Usuario Windows Kiosco** (por defecto: `totem1`).

Automáticamente realizará:
1. Clonado del backend local (`new-backen-local-costa`) en `C:\ProgramData\kiosk\backend`.
2. Generación de `C:\ProgramData\kiosk\backend\.env` en puerto `3000` con `TBK_PORT_PATH=AUTO`.
3. Generación de `C:\ProgramData\kiosk\start-backend.bat` y `C:\ProgramData\kiosk\shell.bat`.
4. Aplicación de políticas Enterprise de Google Chrome (`LocalNetworkAccessAllowedForUrls`, `LoopbackNetworkAllowedForUrls`, `LocalNetworkAllowedForUrls`, `PrintPreviewUseSystemDefaultPrinter=1`).
5. Fijación de la impresora predeterminada `w80` y bloqueo de cambio automático (`LegacyDefaultPrinterMode=1`).
6. Creación del lanzador de inicio automático en `C:\Users\totem1\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Iniciar_Totem_Kiosk.bat` (eliminando lanzadores legacy conflictivos de Edge).

### Paso 5: Configurar AutoLogon y Plan de Energía 24/7
En PowerShell como **Administrador**:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\04-configurar-autologon.ps1
```

Esto desactiva la suspensión/hibernación/apagado de pantalla y configura el inicio de sesión automático en `totem1`.

### Paso 6: Certificar la instalación antes de entregar
Reiniciar el equipo (o levantar el backend) y ejecutar el script de verificación completa:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\02-verificar-totem.ps1 -PrintTest
```

El script valida en verde (`[OK]`):
- Versión de Node.js (`v14.x`) y Chrome instalado.
- Políticas Enterprise de Chrome aplicadas en Registro.
- Impresora `w80` instalada y predeterminada.
- Backend local respondiendo en `http://localhost:3000/health`.
- Pinpad Transbank detectado en `http://localhost:3000/api/terminal/status`.
- Impresión térmica RAW de prueba en `w80` (con `-PrintTest`).
- Conectividad HTTPS a los 5 microservicios Cloud WIT (Meta-GDS Global, Publicidad, Convenios, Analítica y Mail/PDF).

### Paso 7: Activación inicial en pantalla del Tótem
1. Al reiniciar Windows, entrará automáticamente al usuario `totem1` y abrirá Chrome Kiosk en pantalla completa.
2. En la pantalla de configuración inicial (`TotemSetupScreen`), ingresar el **ID del Tótem** asignado (ej. `102`).
3. Ejecutar prueba de impresión desde **Imprimir Pasaje** ingresando el código técnico **`PC-TEST`** (habilitado permanentemente).
4. Ejecutar prueba de búsqueda de viajes (ej. Santiago → Viña del Mar), croquis, convenio y 1 compra real de bajo monto con POS Transbank.
5. Verificar en el Mantenedor que `modo_prueba` esté en **`false`** antes de habilitar al público.

---

## Operación y Mantenimiento

- **Abrir Panel Técnico oculto:** 5 toques rápidos en la esquina superior izquierda (`100×100 px`) → PIN **`1379`**.
- **Actualizar el backend local sin reinstalar:** ejecutar `scripts\03-actualizar-backend.bat` como Administrador.
- **Guía de diagnóstico en terreno:** ver [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).
- **Checklist firmable por equipo desplegado:** ver [docs/CHECKLIST_INSTALACION.md](docs/CHECKLIST_INSTALACION.md).

---

## Repositorios Relacionados (WIT)

| Componente | Repositorio | Rama |
| :--- | :--- | :--- |
| Frontend Kiosco (Netlify) | `https://github.com/dorian-cesar/front-totem-boletos-la.git` | `totem-boletos-chile-dev` |
| Backend Local Hardware (POS + Print) | `https://github.com/MauricioVega01/new-backen-local-costa.git` | `master` |
