# Checklist Oficial de Despliegue y Certificación — Tótem Boletos.la (WIT)

Completar y archivar para cada una de las unidades desplegadas (lote de 100 Mini PCs Etorli).

- **Tótem ID asignado:** `____________`
- **Ubicación / Terminal:** `____________________________`
- **Técnico responsable:** `____________________________`
- **Fecha de instalación:** `____ / ____ / 202__`
- **Número de Serie Mini PC:** `____________________________`

---

## 1. Preparación de Windows 11 de Fábrica y Hardware
- [ ] Usuario local Administrador creado como **`wit`** (ej. clave `wit321`).
- [ ] Pantalla conectada en orientación **Vertical (`1080 × 1920`)**, escala **`100%`**.
- [ ] Zona horaria **`(UTC-03:00) Santiago de Chile`** y reloj sincronizado.
- [ ] Pinpad Transbank PAX conectado por USB (puertos `COM3/COM4/COM5` detectados).
- [ ] Impresora térmica 80mm (SPRT / POS-80) conectada por USB, encendida (LED ON) y con rollo cargado.

---

## 2. Prerrequisitos Manuales (Instalados por el Técnico)
- [ ] **Git for Windows** instalado manualmente ([git-scm.com/downloads/win](https://git-scm.com/downloads/win)).
- [ ] **Google Chrome 64-bit Offline** instalado manualmente ([ChromeStandaloneSetup64.exe](https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe) o Enterprise MSI).
- [ ] **Node.js v14.18.2 (x64)** instalado manualmente ([node-v14.18.2-x64.msi](https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi)) — verificado con `node -v`.
- [ ] Nueva ventana de **Terminal / PowerShell como Administrador** abierta (`Windows + X`).
- [ ] Habilitada ejecución de scripts: `Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force`.
- [ ] Autenticación GitHub completada en navegador (`Sign in with your browser`) al ejecutar `git clone`.

---

## 3. Configuración, Backend y Políticas
- [ ] Repositorio `Totem-boletos-win11` clonado en `C:\InstalacionTotem\Totem-boletos-win11`.
- [ ] Ejecutado `.\scripts\01-instalar-totem.bat` ingresando el `TOTEM_ID` correcto.
- [ ] Impresora térmica registrada con su nombre nativo en `USB001` (`Generic / Text Only` o driver fabricante).
- [ ] Backend `backend-pos-boletos` descargado en `C:\ProgramData\kiosk\backend` y con carpeta `node_modules` instalada (`npm install --production`).
- [ ] Archivo `.env` generado (`PORT=3000`, `TBK_PORT_PATH=AUTO`, `PRINTER_NAME=...`).
- [ ] Prueba visual en vivo ejecutada (`node src/server.js`): HTTP `:3000` + POS PAX en `COM5` con llaves cargadas.
- [ ] Políticas Enterprise de Chrome aplicadas (`LocalNetworkAccessAllowedForUrls`).
- [ ] Lanzador `Iniciar_Totem_Kiosk.bat` creado en el menú `Startup` de `wit`.
- [ ] Ejecutado `.\scripts\04-configurar-autologon.ps1 -KioskUser wit` (AutoLogon + energía 24/7 sin suspensión).

---

## 4. Certificación Integral (16 Checks) y Cold Boot
- [ ] Ejecutado `.\scripts\02-verificar-totem.ps1 -PrintTest` con **16 OK y 0 FALLOS**.
- [ ] Ticket térmico de certificación emitido y cortado limpiamente por la impresora.
- [ ] Ejecutado reinicio físico (`shutdown /r /t 5`): inicia sesión solo en `wit`, arranca backend y abre Chrome Kiosk a pantalla completa sin bucles de recarga.
- [ ] Ingresado ID del tótem en la pantalla táctil inicial (*Iniciar Tótem*) y probada 1 venta real / código técnico `PC-TEST`.

---

**Firma Técnico Instalador:** `___________________________` &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; **VoBo Operaciones WIT:** `___________________________`
