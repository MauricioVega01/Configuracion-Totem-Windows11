# Instalador y Guía de Despliegue Oficial — Tótem Boletos.la Chile (Windows 11)

Repositorio oficial de aprovisionamiento, configuración y diagnóstico para instalar el **Tótem de Autoservicio Boletos.la Chile (WIT)** en cualquier equipo Windows 11 nuevo (ej. mini PC Etorli AMD Ryzen 5, 16GB RAM, 512GB SSD), incorporando todas las correcciones de arquitectura y conectividad resueltas en producción.

> **¡Baterías incluidas!** Este repositorio **ya incluye los instaladores oficiales** en la carpeta [`installers/`](installers/):
> * `installers/node-v14.18.2-x64.msi` (Runtime exacto obligatorio para Transbank POS C++ bindings).
> * `installers/ChromeSetup.exe` (Navegador oficial para modo Kiosk vertical 1080x1920).

---

## 🏛️ Arquitectura del Tótem en Producción

```text
[Tótem Windows 11 - Usuario: totem1]
 ├── Google Chrome Kiosk (1080x1920 vertical)
 │     ├── Frontend Web Kiosco: https://totem-testing-v3.netlify.app/
 │     ├── Microservicios Cloud WIT (HTTPS / WebSocket):
 │     │     ├── Meta-GDS Global (Kupos / Pullman Costa / Distribusion)
 │     │     ├── Convenios y Control de Tarifas (/control-tarifa)
 │     │     ├── Publicidad, Screensaver y Monitoreo de Tótems
 │     │     ├── Analítica de Boletos (Cloud WIT)
 │     │     └── Servicio Mail / PDF con QR
 │     └── Comunicación Local -> http://localhost:3000 (Políticas Enterprise LocalNetworkAccess)
 └── Backend Local Node.js (C:\ProgramData\kiosk\backend - Puerto 3000, stateless)
       ├── POS Pinpad Transbank (USB-Serial COM autodetectado, 115200 bps)
       └── Impresora Térmica 80mm "w80" (Silent printing directo vía Chrome --kiosk-printing)
```

> **Nota de Arquitectura:** El PC del tótem **NO requiere base de datos local (MySQL/PostgreSQL)**. Toda la persistencia vive en la nube de WIT y el backend local (`backend-pos-boletos`) actúa como puente liviano de hardware administrado por `shell.bat` y `start-backend.bat`.

---

## 🚀 Guía de Despliegue Paso a Paso (Desde el Primer Encendido)

### 🔹 Paso 0: Primer Encendido del Hardware (Etorli)
1. Conecta el equipo a corriente, mouse, teclado y cable de red (o Wi-Fi).
2. Enciende el equipo. Si estás en la configuración inicial de Windows 11 (OOBE):
   * Selecciona idioma: **Español (Chile)**.
   * Crea una cuenta local de Administrador (ej: `Admin` o `Innovapro`).
3. **¿Aún no tienes la pantalla táctil?**
   * **No hay problema:** El ratón/mouse simula el 100% de los toques táctiles. Puedes instalar y probar todo el flujo con un monitor estándar.
   * En **Configuración → Sistema → Pantalla**:
     * Resolución: `1080 × 1920` (o `1920 × 1080` horizontal provisional si tu monitor de prueba no gira).
     * Escala: **100%**.
   * En **Configuración → Hora e idioma → Fecha y hora**:
     * Zona horaria: `(UTC-03:00) Santiago de Chile` y sincronizar reloj.

---

### 🔹 Paso 1: Clonar el Repositorio de Despliegue
Abre **PowerShell como Administrador** (clic derecho en Inicio → *Terminal (Administrador)* o *Windows PowerShell (Administrador)*) y ejecuta:

```powershell
mkdir C:\InstalacionTotem -Force
cd C:\InstalacionTotem
git clone https://github.com/MauricioVega01/Configuracion-Totem-Windows11.git
cd Configuracion-Totem-Windows11
```

---

### 🔹 Paso 2: Instalación de Prerrequisitos (1 Solo Clic)
Ejecuta el instalador silencioso de prerrequisitos incluido en el repositorio:

```cmd
scripts\00-instalar-prerrequisitos.bat
```

> **¿Qué hace?**
> * Instala silenciosamente **Node.js v14.18.2 (x64)** desde `installers/node-v14.18.2-x64.msi`.
> * Instala silenciosamente **Google Chrome (64-bit)** desde `installers/ChromeSetup.exe`.
> * Refresca las variables de entorno de Windows para que `node` y `npm` queden disponibles de inmediato sin reiniciar.

---

### 🔹 Paso 3: Ejecutar el Instalador Maestro del Tótem
Haz doble clic o ejecuta en consola como Administrador:

```cmd
scripts\01-instalar-totem.bat
```

El script te solicitará 4 parámetros interactivos sencillos:
1. **ID del Tótem:** Ingresa el ID asignado (ej: `101`, `102` — predeterminado: `101`).
2. **Nombre de la impresora térmica:** Presiona *Enter* (toma `w80` por defecto).
3. **URL del Frontend Kiosco:** Presiona *Enter* (toma `https://totem-testing-v3.netlify.app/` por defecto).
4. **Usuario Windows del Kiosco:** Presiona *Enter* (toma `totem1` por defecto).

> **¿Qué tareas ejecuta automáticamente `01-instalar-totem.bat`?**
> 1. Detiene procesos previos conflictivos de Chrome y Node.js.
> 2. Clona el backend de hardware [`backend-pos-boletos`](https://github.com/MauricioVega01/backend-pos-boletos.git) en `C:\ProgramData\kiosk\backend`.
> 3. Instala sus dependencias npm en Node 14 (`npm install --production`).
> 4. Genera el archivo `C:\ProgramData\kiosk\backend\.env` configurado con `PORT=3000` y `TBK_PORT_PATH=AUTO`.
> 5. Genera `C:\ProgramData\kiosk\start-backend.bat` (loop con auto-recuperación ante caídas).
> 6. Aplica las **Políticas Enterprise de Chrome** en el Registro (`LocalNetworkAccessAllowedForUrls`, `LoopbackNetworkAllowedForUrls`, `LocalNetworkAllowedForUrls`, `PrintPreviewUseSystemDefaultPrinter=1`) para permitir la comunicación HTTPS → `http://localhost:3000`.
> 7. Configura `C:\ProgramData\kiosk\shell.bat` fijando la impresora `w80` y lanzando Chrome Kiosk sin barras de navegación ni menús.
> 8. Registra el lanzador de inicio automático en la carpeta `Startup` del usuario `totem1`.

---

### 🔹 Paso 4: Configurar AutoLogon y Plan de Energía 24/7
En PowerShell como Administrador ejecuta:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\04-configurar-autologon.ps1
```

> **¿Qué hace?**
> * Crea el usuario local `totem1` (si no existe) y solicita una contraseña.
> * Configura `AutoAdminLogon` en el Registro para que Windows inicie sesión automáticamente en `totem1` sin pedir clave al prenderse el equipo.
> * Desactiva la pantalla de bloqueo (`NoLockScreen = 1`).
> * Desactiva la suspensión, hibernación y apagado de monitor mediante `powercfg` para operación continua 24/7.

---

### 🔹 Paso 5: Conectar Hardware y Certificar la Instalación
1. Conecta el **Pinpad POS Transbank** vía USB. Verifica en *Administrador de dispositivos → Puertos (COM y LPT)* que figure como `COMx` (ej: `COM3`).
2. Conecta la **Impresora Térmica 80mm** vía USB, instala su driver y cámbiale el nombre en Windows exactamente a **`w80`**.
3. Ejecuta el script de certificación integral:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\02-verificar-totem.ps1 -PrintTest
```

Deberás ver todos los checks en **verde `[OK]`**:
* ✅ `Node.js instalado` (v14.18.2).
* ✅ `Google Chrome x64` instalado.
* ✅ `Backend en C:\ProgramData\kiosk\backend` presente.
* ✅ `Politica Chrome LocalNetworkAccess` aplicada en Registro.
* ✅ `Impresora termica 'w80'` detectada.
* ✅ `Backend Local HTTP :3000/health` respondiendo OK.
* ✅ `POS Transbank USB-Serial` conectado y listo.
* ✅ `Cloud: Meta-GDS Global`, `Publicidad`, `Convenios` y `Analítica` alcanzables por HTTPS.
* ✅ Ticket térmico de prueba emitido en la impresora `w80`.

---

### 🔹 Paso 6: Prueba de Arranque en Frío (Reinicio Físico)
1. Reinicia el PC Etorli.
2. Windows iniciará sesión automáticamente en el usuario `totem1`.
3. Se levantará el backend del POS en segundo plano y Chrome Kiosk se abrirá a pantalla completa vertical en menos de 25 segundos.
4. Vincula el ID de Tótem asignado y ejecuta 1 compra real de bajo monto con tarjeta física para certificar la entrega.

---

## 🛠️ Panel Técnico y Mantenimiento

* **Abrir Panel Técnico oculto:** En la pantalla del tótem, presiona 5 toques rápidos en la esquina superior izquierda (`100×100 px`) e ingresa el PIN **`1379`**.
* **Actualizar el backend de hardware sin reinstalar:** Ejecutar `scripts\03-actualizar-backend.bat` como Administrador.
* **Guía de diagnóstico ante fallas en terreno:** Ver [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).
* **Checklist técnico imprimible/firmable:** Ver [docs/CHECKLIST_INSTALACION.md](docs/CHECKLIST_INSTALACION.md).

---

## 📦 Repositorios Oficiales del Ecosistema

| Componente | Repositorio Oficial | Rama |
| :--- | :--- | :--- |
| **Instalador y Políticas Windows 11** | `https://github.com/MauricioVega01/Configuracion-Totem-Windows11.git` | `main` |
| **Backend Local Hardware (POS + w80)** | `https://github.com/MauricioVega01/backend-pos-boletos.git` | `master` |
| **Frontend Web Tótem Kiosco** | `https://github.com/dorian-cesar/front-totem-boletos-la.git` | `totem-boletos-chile-dev` |
