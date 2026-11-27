# Instalador y Guía Maestra de Despliegue — Tótem Boletos.la Chile (Windows 11)

Repositorio oficial y estandarizado para aprovisionar, configurar y certificar el **Tótem de Autoservicio Boletos.la Chile (WIT)** en lotes de computadoras de fábrica (ej. **Mini PC Etorli: AMD Ryzen 5 3500U, 16 GB RAM, 512 GB SSD, Windows 11 Pro 64-bit en Español**).

> 💡 **Política Cero Inconsistencias (Prerrequisitos Manuales):**
> Los scripts de este repositorio **NO instalan Git, Node.js ni Google Chrome de forma automática**. En equipos de fábrica, los instaladores desatendidos/silenciosos suelen colgarse o fallar en silencio con SmartScreen/Windows Update o alterar rutas del `PATH`.
> Por eso el técnico instala manualmente los 3 prerrequisitos base siguiendo el **Paso 1** (con sus enlaces directos oficiales), y los scripts se encargan únicamente de **validar** que estén bien instalados y configurar toda la infraestructura del tótem.

---

## 🔗 Enlaces Oficiales de Descarga (Prerrequisitos Base)

| Software | Versión Obligatoria | Enlace Oficial Directo | Archivo de Respaldo en Repo | Notas Técnicas |
|---|---|---|---|---|
| **1. Git for Windows** | Última estable x64 | [git-scm.com/downloads/win](https://git-scm.com/downloads/win) | — | Necesario **antes** de poder ejecutar `git clone`. |
| **2. Google Chrome Offline** | 64-bit Standalone | [ChromeStandaloneSetup64.exe](https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe) *(o [Enterprise MSI](https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi))* | `installers\ChromeSetup.exe` *(stub online)* | **Preferir el enlace Standalone/Enterprise Offline** (no se congela). |
| **3. Node.js (x64)** | **v14.18.2 exacta** | [node-v14.18.2-x64.msi](https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi) | `installers\node-v14.18.2-x64.msi` | Obligatorio por bindings nativos C++ de `transbank-pos-sdk` y `serialport`. |

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
        ├── POS Pinpad Transbank PAX (VID_2FB8 / Canal MI_00 -> COM5 autodetectado, 115200 bps)
        └── Impresora Térmica 80mm USB (ej. SPRT SC260324 80mm Series en USB001, Generic / Text Only)
```

---

## 🚀 Guía Maestra de Despliegue Paso a Paso (Replicable en 100 PCs)

### 🔹 Paso 0: Primer Encendido del Hardware de Fábrica
1. Conecta el Mini PC Etorli a corriente, cable de red Ethernet (o Wi-Fi), monitor (o pantalla táctil), teclado y ratón.
2. En la configuración inicial de Windows 11 (OOBE):
   * Región / Idioma: **Chile / Español**.
   * Usuario Administrador local: **`wit`** (Contraseña recomendada: **`wit321`**).
3. Ajuste de pantalla (**Configuración → Sistema → Pantalla**):
   * Orientación: **Vertical** (`1080 × 1920`, o provisional `1920 × 1080` en monitor de escritorio).
   * Escala: **100%**.
   * Zona horaria (**Configuración → Hora e idioma**): `(UTC-03:00) Santiago de Chile` y presionar **Sincronizar ahora**.
4. Conecta el hardware del tótem vía USB:
   * **POS Transbank PAX:** Conectar por USB (Windows asignará puertos virtuales como `COM3`, `COM4`, `COM5`).
   * **Impresora Térmica 80mm (ej. SPRT / POS-80):** Conectar a corriente, encender (switch en **ON**), cargar rollo de papel térmico 80mm y conectar el cable USB.

---

### 🔹 Paso 1: Instalación Manual de Git, Chrome y Node.js v14.18.2

> ⚠️ **Realizar manualmente en cada equipo usando el navegador Microsoft Edge que trae Windows 11 (tarda ~2 minutos en total):**

1. **Instalar Git for Windows:**
   * Descarga desde [https://git-scm.com/downloads/win](https://git-scm.com/downloads/win) y ejecuta el instalador (*Next → Next → Install*).
2. **Instalar Google Chrome (64-bit Offline):**
   * Descarga [https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe](https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe) (o [Enterprise MSI](https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi)) y ejecútalo.
   * *Nota:* Si usas el `.msi`, instala directo en `C:\Program Files\Google\Chrome\Application\chrome.exe`. Si se instala en `AppData\Local`, los scripts del tótem también lo detectan automáticamente.
3. **Instalar Node.js v14.18.2 (x64):**
   * Descarga [https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi](https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi) y ejecútalo (*Next → Accept → Next → Install*).
   * *(Si ya descargaste este repo en ZIP o en USB, también puedes usar el archivo incluido `installers\node-v14.18.2-x64.msi`).*

---

### 🔹 Paso 2: Abrir PowerShell como Administrador, Iniciar Sesión en Git y Clonar el Repo

1. Presiona **`Windows + X`** → selecciona **Terminal (Administrador)** o **Windows PowerShell (Administrador)** *(es fundamental abrir una ventana NUEVA después de instalar Git y Node para que cargue el `PATH`)*.
2. Verifica las versiones instaladas manualmente:
   ```powershell
   git --version
   node -v
   npm -v
   ```
   *(Confirma que `node -v` responda exactamente **`v14.18.2`**).*

3. Habilita ejecución de scripts PowerShell en Windows 11 de fábrica y clona el repositorio:
   ```powershell
   # 1. Permitir scripts locales de PowerShell en este PC
   Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

   # 2. Crear carpeta base y clonar repositorio
   mkdir C:\InstalacionTotem -Force
   cd C:\InstalacionTotem
   git clone https://github.com/MauricioVega01/Configuracion-Totem-Windows11.git
   cd Configuracion-Totem-Windows11
   ```

> 🔐 **IMPORTANTE — Autenticación en GitHub desde PowerShell:**
> Al clonar repositorios privados o durante el despliegue con `git clone`, aparecerá en PowerShell:
> ```text
> info: please complete authentication in your browser...
> ```
> Se abrirá una ventana emergente del navegador pidiendo iniciar sesión en GitHub (**Sign in with your browser**). Inicia sesión con la cuenta técnica autorizada para guardar el token de Git Credential Manager en Windows.

---

### 🔹 Paso 3: Ejecutar el Configurador Oficial del Tótem

Desde la consola de **Administrador** dentro de `C:\InstalacionTotem\Configuracion-Totem-Windows11`:

```powershell
.\scripts\01-instalar-totem.bat
```

1. Primero validará que **Git, Node.js (`v14.18.2`) y Google Chrome** ya estén instalados (si falta alguno, detendrá la ejecución indicándote el enlace oficial para instalarlo manualmente).
2. Luego solicitará confirmar 4 parámetros:
   * **ID del Tótem:** Ingresa el ID asignado al equipo (ej: `101`, `102` — predeterminado: `101`).
   * **Nombre de impresora térmica:** El script consulta Windows; si la impresora térmica USB (ej. **`SPRT SC260324  80mm Series`**) ya está conectada pero aún sin cola de impresión, registra el driver `Generic / Text Only` y crea la cola en `USB001` conservando su **nombre nativo de Windows**. Solo presiona **`Enter`** para confirmar. *(Si aún no conectas la impresora, quedará en modo `AUTO`).*
   * **URL del Frontend Kiosco:** Presiona **`Enter`** (predeterminado: `https://totem-testing-v3.netlify.app/`).
   * **Usuario Windows:** Presiona **`Enter`** (predeterminado: `wit`).

> **¿Qué configura automáticamente `01-instalar-totem.bat`?**
> * Clona o actualiza [`backend-pos-boletos`](https://github.com/MauricioVega01/backend-pos-boletos.git) en `C:\ProgramData\kiosk\backend` *(puede volver a pedir auth si es la primera vez con ese repo)*.
> * Ejecuta `npm install --production` en el backend verificando que `node_modules\express` quede instalado correctamente.
> * Genera `C:\ProgramData\kiosk\backend\.env` (`PORT=3000`, `TBK_PORT_PATH=AUTO`, `PRINTER_NAME=...`).
> * Genera `start-backend.bat` y `shell.bat` en `C:\ProgramData\kiosk` (con resolución dinámica de Chrome y protección contra recargas repetitivas).
> * Aplica las **Políticas Enterprise de Chrome 157+** en el Registro (`LocalNetworkAccessAllowedForUrls`, `LoopbackNetworkAllowedForUrls`, `PrintPreviewUseSystemDefaultPrinter=1`).
> * Crea el lanzador de arranque en `C:\Users\wit\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Iniciar_Totem_Kiosk.bat`.

---

### 🔹 Paso 4: Verificar `npm install` y Probar el Backend en Vivo (`node src/server.js`)

Para inspeccionar visualmente que Node.js, las dependencias npm, el POS PAX y la impresora responden sin errores antes de cerrar la consola:

```powershell
# 1. Confirmar dependencias (opcional si el Paso 3 ya las instaló)
cd C:\ProgramData\kiosk\backend
npm install --production

# 2. Arrancar servidor en vivo en pantalla
node src/server.js
```

Debes ver en la consola exactamente esta secuencia:
```text
=============================================
[SERVER]   TOTEM ID:       102
[SERVER]   HTTP LISTENING: http://localhost:3000
[SERVER]   IP RED LOCAL:   192.168.8.x
[SERVER]   PRINTER RAW:    SPRT SC260324  80mm Series
=============================================
[SERVER]   HTTPS LISTENING: https://localhost:3001

[POS]      Puertos detectados en el sistema: COM3, COM4, COM5
[POS]      Puertos a probar en orden (autodeteccion): COM5, COM3, COM4
[POS]      Conectando a COM5 (Intento 1/3)
[POS]      Conexión exitosa en COM5
[POS]      Llaves cargadas exitosamente
[POS]      POS listo para operar
```
Presiona **`Ctrl + C`** para detener esta prueba en vivo y volver al prompt.

---

### 🔹 Paso 5: Configurar AutoLogon y Plan de Energía 24/7

Para que al encenderse el equipo entre solo al escritorio de **`wit`** (sin pedir contraseña) y nunca apague la pantalla ni entre en suspensión:

```powershell
cd C:\InstalacionTotem\Configuracion-Totem-Windows11
.\scripts\04-configurar-autologon.ps1 -KioskUser wit
```
*(Cuando te lo pida, escribe la contraseña del usuario `wit`, por ejemplo `wit321`).*

---

### 🔹 Paso 6: Certificación Integral (16 Checks) y Corte de Ticket de Prueba

Inicia el backend minimizado en segundo plano y ejecuta el script de certificación física:

```powershell
Start-Process "C:\ProgramData\kiosk\start-backend.bat" -WindowStyle Minimized
Start-Sleep -Seconds 4
.\scripts\02-verificar-totem.ps1 -PrintTest
```

Verifica que la salida final muestre **`RESUMEN: 16 OK | 0 FALLOS`** y que la impresora térmica imprima y corte el voucher de certificación de WIT.

---

### 🔹 Paso 7: Reinicio en Frío (Cold Boot) y Primer Ingreso de ID en Pantalla

Reinicia físicamente el Mini PC:

```powershell
shutdown /r /t 5
```

1. Windows 11 arrancará directo en la sesión `wit` sin solicitar clave.
2. En pocos segundos se abrirá el backend minimizado y **Google Chrome en modo Quiosco a pantalla completa** (`https://totem-testing-v3.netlify.app/`).
3. En la pantalla táctil de bienvenida (*"Configuración — Ingrese el identificador único del tótem"*), marca el ID asignado (ej. **`102`**) y toca **`Iniciar Tótem ➔`**.
4. El sistema pasará al menú principal (**"Comprar Pasaje"** / **"Imprimir Pasaje"**) listo para operar 24/7.

---

## 🛠️ Panel Técnico y Mantenimiento

* **Abrir Panel Técnico oculto en pantalla:** Presiona **5 toques rápidos** en la esquina superior izquierda (`100×100 px`) e ingresa el PIN **`1379`**.
* **Actualizar el backend local desde GitHub sin reinstalar:** Ejecutar `scripts\03-actualizar-backend.bat` como Administrador.
* **Volver a verificar todo o imprimir ticket RAW:** `powershell -ExecutionPolicy Bypass -File scripts\02-verificar-totem.ps1 -PrintTest`.
* **Solución de fallas comunes en terreno:** Ver [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).
* **Checklist firmable por unidad (lote 100 PCs):** Ver [`docs/CHECKLIST_INSTALACION.md`](docs/CHECKLIST_INSTALACION.md).

---

## 📦 Repositorios Oficiales del Ecosistema

| Componente | Repositorio Oficial en GitHub | Rama |
| :--- | :--- | :--- |
| **Configurador y Políticas Windows 11** | `https://github.com/MauricioVega01/Configuracion-Totem-Windows11.git` | `main` |
| **Backend Local Hardware (POS PAX + Impresora RAW)** | `https://github.com/MauricioVega01/backend-pos-boletos.git` | `master` |
| **Frontend Web Tótem Kiosco** | `https://github.com/dorian-cesar/front-totem-boletos-la.git` | `totem-boletos-chile-dev` |
