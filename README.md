# Instalador y Guía Maestra de Despliegue — Tótem Boletos.la Chile (Windows 11)

Repositorio oficial y estandarizado para aprovisionar, configurar y certificar el **Tótem de Autoservicio Boletos.la Chile (WIT)** en lotes de computadoras de fábrica (ej. **Mini PC Etorli: AMD Ryzen 5 3500U, 16 GB RAM, 512 GB SSD, Windows 11 Pro 64-bit en Español**).

> **¡Baterías incluidas y Enlaces Oficiales!**
> Los binarios exactos ya están en la carpeta [`installers/`](installers/), pero también dispones de los enlaces directos oficiales del fabricante:
> * **Node.js v14.18.2 (x64) MSI:** [`installers/node-v14.18.2-x64.msi`](installers/node-v14.18.2-x64.msi) o [Descarga Directa nodejs.org](https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi) *(Obligatorio para compatibilidad nativa C++ con `transbank-pos-sdk` y `serialport`)*.
> * **Google Chrome 64-bit:** [`installers/ChromeSetup.exe`](installers/ChromeSetup.exe) o [Descarga Oficial Chrome Standalone x64](https://dl.google.com/chrome/install/standalone/service/ChromeStandaloneSetup64.exe) *(Instalador sin conexión que no se cuelga)*.

---

## 🏛️ Arquitectura del Tótem en Producción

```text
====================================================================
  TÓTEM BOLETOS.LA CHILE (WINDOWS 11 - USUARIO: wit)
====================================================================
  ├── Google Chrome Kiosk Mode (1080x1920 vertical / Silent Printing)
  │     ├── Frontend Web Kiosco: https://totem-testing-v3.netlify.app/
  │     ├── Microservicios Cloud WIT (HTTPS / WebSockets):
  │     │     ├── Meta-GDS Global (Kupos / Pullman Costa / Distribusion)
  │     │     ├── Convenios y Control de Tarifas (/control-tarifa)
  │     │     ├── Publicidad, Screensaver y Monitoreo de Tótems
  │     │     ├── Analítica de Boletos (Cloud WIT)
  │     │     └── Servicio Mail / Voucher con QR
  │     └── Comunicación Local -> http://localhost:3000 (Políticas Enterprise Chrome 157+)
  └── Backend Local Node.js v14.18.2 (C:\ProgramData\kiosk\backend - Puerto 3000, Stateless)
        ├── POS Pinpad Transbank PAX (USB-Serial COM autodetectado, Canal MI_00, 115200 bps)
        └── Impresora Térmica 80mm USB (SPRT / POS-80 en USB001, corte automático y RAW printing)
```

---

## 🚀 Guía Maestra de Despliegue Paso a Paso (Para Replicar en 100 PCs)

### 🔹 Paso 0: Primer Encendido del Hardware de Fábrica
1. Conecta el Mini PC Etorli a corriente, cable de red Ethernet (o Wi-Fi), monitor (o pantalla táctil), teclado y ratón.
2. Conecta el hardware periférico en los puertos USB del Mini PC:
   * **POS Transbank PAX:** Conectar cable USB. (Windows creará puertos `COM3`, `COM4` y `COM5`).
   * **Impresora Térmica 80mm (SPRT / POS-80):** Conectar cable USB a corriente y encender (switch en **ON** y rollo de papel cargado).
3. En la configuración inicial de Windows 11 (OOBE):
   * Región: **Chile**.
   * Teclado: **Español**.
   * Usuario Administrador local: **`wit`** (Contraseña recomendada: **`wit321`**).
4. Ajuste de pantalla (Configuración → Sistema → Pantalla):
   * Orientación: **Vertical** (Resolución `1080 × 1920`).
   * Escala: **100%**.
   * Zona horaria: `(UTC-03:00) Santiago de Chile` con reloj sincronizado.

---

### 🔹 Paso 1: Habilitar Consola Administrador y Clonar Repositorio
Abre **PowerShell como Administrador** (presiona `Windows + X` → selecciona **Terminal (Administrador)** o **Windows PowerShell (Administrador)**).

Ejecuta el bloque para habilitar scripts de PowerShell y clonar el instalador:

```powershell
# 1. Habilitar ejecucion de scripts en Windows 11 de fabrica
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# 2. Crear carpeta base y clonar el repositorio
mkdir C:\InstalacionTotem -Force
cd C:\InstalacionTotem
git clone https://github.com/MauricioVega01/Configuracion-Totem-Windows11.git
cd Configuracion-Totem-Windows11
```

> ⚠️ **IMPORTANTE — Autenticación en Git por PowerShell:**
> Al clonar o actualizar, Git puede mostrar:
> `info: please complete authentication in your browser...`
> Se abrirá automáticamente una ventana de navegador solicitando iniciar sesión en GitHub (**Sign in with your browser**). Inicia sesión con la cuenta técnica para que Git guarde las credenciales en Windows Credential Manager.

---

### 🔹 Paso 2: Instalación de Node.js v14.18.2 y Google Chrome

> 💡 **¿Por qué es mejor la instalación con barra `/qb` o doble clic en vez de scripts 100% invisibles?**
> En computadoras de fábrica, los instaladores "silenciosos" (`/silent` o `/qn`) pueden colgarse o bloquearse en segundo plano si SmartScreen o Windows Update están activos, sin avisarle al técnico. La instalación semi-asistida con `/qb` o doble clic muestra la barra de progreso real, tarda solo **10 segundos** y garantiza al 100% que los archivos queden registrados.

#### 1. Instalar Node.js v14.18.2 (x64)
* **Opción A (Recomendada desde PowerShell):**
  ```powershell
  Start-Process msiexec.exe -ArgumentList "/i installers\node-v14.18.2-x64.msi /qb" -Wait
  ```
* **Opción B (Doble clic manual):**
  Abre la carpeta `C:\InstalacionTotem\Configuracion-Totem-Windows11\installers` y haz doble clic en `node-v14.18.2-x64.msi` → *Next, Next, Install*.
* **Descarga directa si falta el archivo:** [https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi](https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi)
* **Verificación:** Ejecuta `& "C:\Program Files\nodejs\node.exe" -v` y confirma que diga `v14.18.2`.

#### 2. Instalar Google Chrome (64-bit)
* **Opción A (Vía winget en PowerShell):**
  ```powershell
  winget install Google.Chrome --silent --accept-package-agreements --accept-source-agreements
  ```
* **Opción B (Doble clic manual):**
  Doble clic en `installers\ChromeSetup.exe` o descarga el instalador offline completo:
  [https://dl.google.com/chrome/install/standalone/service/ChromeStandaloneSetup64.exe](https://dl.google.com/chrome/install/standalone/service/ChromeStandaloneSetup64.exe).

---

### 🔹 Paso 3: Ejecutar el Instalador Maestro del Tótem

Ejecuta el script principal desde la consola de Administrador:

```cmd
.\scripts\01-instalar-totem.bat
```

El script solicitará 4 datos interactivos con valores por defecto inteligentes:
1. **ID del Tótem:** Ingresa el número asignado (ej. `101`, `102` — predeterminado: `101`).
2. **Nombre de la impresora térmica:** El script consulta a Windows por dispositivos USB térmicos, detecta automáticamente tu impresora (ej. **`SPRT SC260324  80mm Series`**), registra el driver `Generic / Text Only` en el Spooler y la asigna a `USB001`. **Solo presiona `Enter` para confirmar.**
3. **URL del Frontend Kiosco:** Presiona `Enter` (predeterminado: `https://totem-testing-v3.netlify.app/`).
4. **Usuario Windows:** Presiona `Enter` (predeterminado: `wit`).

> **¿Qué hace automáticamente `01-instalar-totem.bat`?**
> * Clona / actualiza el repositorio [`backend-pos-boletos`](https://github.com/MauricioVega01/backend-pos-boletos.git) en `C:\ProgramData\kiosk\backend`.
> * Ejecuta `"C:\Program Files\nodejs\npm.cmd" install --production` para instalar los paquetes de Node.
> * Genera `C:\ProgramData\kiosk\backend\.env` configurado con `PORT=3000`, `TBK_PORT_PATH=AUTO` y la impresora detectada.
> * Aplica las **Políticas Enterprise de Google Chrome** en el Registro de Windows (`LocalNetworkAccessAllowedForUrls`) para permitir la comunicación segura HTTPS (Netlify) → HTTP `http://localhost:3000`.
> * Genera `start-backend.bat` y `shell.bat` en `C:\ProgramData\kiosk`.
> * Registra el lanzador de inicio automático en la carpeta `Startup` del usuario `wit`.

---

### 🔹 Paso 4: Asegurar Dependencias del Backend (`npm install`)

Si por alguna razón Node se instaló después o quieres asegurar al 100% las dependencias del backend:

```powershell
cd C:\ProgramData\kiosk\backend
& "C:\Program Files\nodejs\npm.cmd" install --production
```
*(Confirma que exista la carpeta `C:\ProgramData\kiosk\backend\node_modules`).*

---

### 🔹 Paso 5: Prueba de Arranque en Vivo del Backend (Inspección Visual)

Para certificar visualmente en tu propia pantalla que el backend reconoce el hardware:

```powershell
cd C:\ProgramData\kiosk\backend
& "C:\Program Files\nodejs\node.exe" src/server.js
```

Debes observar en la consola:
```text
=============================================
[SERVER]   TOTEM ID:       102
[SERVER]   HTTP LISTENING: http://localhost:3000
[SERVER]   IP RED LOCAL:   192.168.8.x
[SERVER]   PRINTER RAW:    SPRT SC260324  80mm Series
=============================================
[POS]      Puertos detectados en el sistema: COM3, COM4, COM5
[POS]      Conexión exitosa en COM5
[POS]      Llaves cargadas exitosamente
[POS]      POS listo para operar
```
*(Presiona `Ctrl + C` para cerrar la prueba en vivo).*

---

### 🔹 Paso 6: Configurar AutoLogon y Plan de Energía 24/7

Para que el Mini PC inicie sesión solo al encenderse (sin pedir contraseña) y nunca entre en suspensión de pantalla:

```powershell
powershell -ExecutionPolicy Bypass -File C:\InstalacionTotem\Configuracion-Totem-Windows11\scripts\04-configurar-autologon.ps1 -KioskUser wit
```
*(Confirma la contraseña del usuario `wit`, ej: `wit321`).*

> **Efecto en el sistema:**
> * Configura `AutoAdminLogon = 1` en el Registro de Windows.
> * Desactiva la pantalla de bloqueo (`NoLockScreen = 1`).
> * Desactiva el apagado de pantalla, suspensión e hibernación (`powercfg /change standby-timeout-ac 0`).

---

### 🔹 Paso 7: Diagnóstico Integral y Certificación (16 OK / 0 Fallos)

Inicia el backend en modo servicio minimizado y corre el certificador con impresión de prueba:

```powershell
cd C:\InstalacionTotem\Configuracion-Totem-Windows11
Start-Process "C:\ProgramData\kiosk\start-backend.bat" -WindowStyle Minimized
Start-Sleep -Seconds 4
.\scripts\02-verificar-totem.ps1 -PrintTest
```

**Resultado esperado:**
```text
====================================================================
  DIAGNOSTICO Y CERTIFICACION POST-INSTALACION - TOTEM WIT CHILE
====================================================================
[OK]   Node.js instalado                          Version: v14.18.2
[OK]   Google Chrome instalado                    C:\Users\wit\AppData\Local\Google\Chrome\Application\chrome.exe
[OK]   Backend en C:\ProgramData\kiosk\backend    server.js presente
[OK]   Dependencias npm (node_modules)            Paquetes npm instalados
[OK]   Motor Impresion w80 (Kiosk/RAW)            Impresion termica silenciosa configurada
[OK]   Script shell.bat                           C:\ProgramData\kiosk\shell.bat
[OK]   Archivo .env local                         C:\ProgramData\kiosk\backend\.env
[OK]   Politica Chrome LocalNetworkAccess         Permite HTTPS -> localhost:3000
[OK]   Impresora termica 'SPRT SC260324  80mm Series' USB001 / Generic / Text Only
[OK]   Backend Local HTTP :3000/health            Totem ID=102, Impresora=SPRT SC260324  80mm Series
[OK]   POS Transbank USB-Serial                   Conectado=True | Puerto=COM5
[OK]   Cloud: Frontend Netlify                    HTTP 200
[OK]   Cloud: Meta-GDS Global                     HTTP 200
[OK]   Cloud: Publicidad Chile                    HTTP 200
[OK]   Cloud: Convenios Chile                     HTTP 200
[OK]   Cloud: Analitica Boletos                   HTTP 200

Enviando ticket de prueba RAW a impresora SPRT SC260324  80mm Series...
[OK]   Impresion termica RAW de prueba            Ticket emitido en SPRT SC260324  80mm Series

====================================================================
  RESUMEN: 16 OK  |  0 FALLOS
====================================================================
```
La impresora térmica cortará físicamente el voucher de certificación de WIT.

---

### 🔹 Paso 8: Reinicio en Frío y Configuración Inicial del ID en Pantalla

Reinicia el equipo para verificar el ciclo de producción desatendido:

```powershell
shutdown /r /t 5
```

**Comportamiento en producción:**
1. Windows 11 inicia sesión automáticamente con el usuario `wit`.
2. Se ejecuta en segundo plano `C:\ProgramData\kiosk\start-backend.bat`, conectándose al POS en `COM5` y preparando la impresora.
3. Se abre Google Chrome a pantalla completa vertical en `https://totem-testing-v3.netlify.app/` en modo quiosco (`--kiosk --kiosk-printing`) sin barras, menús ni diálogos de confirmación de impresión.
4. **Pantalla de Configuración Inicial:** Aparecerá la ventana de bienvenida solicitando el ID del tótem. Con el teclado táctil numérico en pantalla, ingresa el ID asignado (ej. **`102`**) y presiona **`Iniciar Tótem ➔`**.
5. El sistema guardará la configuración, pasará a la pantalla principal (**"Comprar Pasaje" / "Imprimir Pasaje"**) y quedará 100% listo para venta al público 24/7.

---

## 🛠️ Comandos de Mantenimiento y Recuperación Rápida

| Tarea | Comando / Acción |
|---|---|
| **Verificar estado de componentes** | `powershell -ExecutionPolicy Bypass -File C:\InstalacionTotem\Configuracion-Totem-Windows11\scripts\02-verificar-totem.ps1 -PrintTest` |
| **Actualizar backend desde GitHub** | `C:\InstalacionTotem\Configuracion-Totem-Windows11\scripts\03-actualizar-backend.bat` |
| **Consultar estado del POS Transbank** | `Invoke-RestMethod http://localhost:3000/api/terminal/status` |
| **Revisar puertos USB conectados** | `Get-PnpDevice -PresentOnly \| Where-Object { $_.FriendlyName -match 'SPRT\|POS\|COM\|USB' }` |
| **Abrir Panel Técnico en pantalla** | Presionar 5 toques rápidos en la esquina superior izquierda (`100x100 px`) e ingresar PIN **`1379`**. |

---

## 📦 Repositorios Oficiales del Ecosistema

| Componente | Repositorio Oficial en GitHub | Rama |
| :--- | :--- | :--- |
| **Instalador y Políticas Windows 11** | `https://github.com/MauricioVega01/Configuracion-Totem-Windows11.git` | `main` |
| **Backend Local Hardware (POS + SPRT)** | `https://github.com/MauricioVega01/backend-pos-boletos.git` | `master` |
| **Frontend Web Tótem Kiosco** | `https://github.com/dorian-cesar/front-totem-boletos-la.git` | `totem-boletos-chile-dev` |
