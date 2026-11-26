# Checklist Oficial de Despliegue y Certificación — Tótem Boletos.la (WIT)

Completar y archivar para cada una de las unidades desplegadas (lote de 100 Mini PCs Etorli).

- **Tótem ID asignado:** `____________`
- **Ubicación / Terminal:** `____________________________`
- **Técnico responsable:** `____________________________`
- **Fecha de instalación:** `____ / ____ / 202__`
- **Número de Serie Mini PC:** `____________________________`

---

## 1. Conexión de Hardware Periférico
- [ ] Mini PC Etorli conectado a corriente eléctrica y red Ethernet / Wi-Fi.
- [ ] Pinpad Transbank PAX conectado por USB (confirmado en Administrador de Dispositivos como puerto COM).
- [ ] Impresora térmica 80mm (SPRT / POS-80) conectada por USB, encendida con LED verde y papel cargado.
- [ ] Pantalla o monitor conectado en orientación vertical (**1080 × 1920**, escala 100%).

---

## 2. Preparación de Windows 11 de Fábrica
- [ ] Usuario local creado como **`wit`** (Administrador).
- [ ] Zona horaria configurada en `(UTC-03:00) Santiago de Chile` y reloj de Windows sincronizado.
- [ ] Consola Terminal ejecutada como Administrador.
- [ ] Ejecutada política: `Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force`.
- [ ] Sesión de Git / GitHub completada a través de la ventana del navegador (`Sign in with your browser`).

---

## 3. Instalación de Software Base y Runtime
- [ ] Repositorio `Configuracion-Totem-Windows11` clonado en `C:\InstalacionTotem`.
- [ ] **Node.js v14.18.2 (x64)** instalado desde `installers/node-v14.18.2-x64.msi` (verificado con `node -v`).
- [ ] **Google Chrome (64-bit)** instalado y verificado en el sistema.
- [ ] Driver de impresora `Generic / Text Only` registrado en Windows Spooler.
- [ ] Cola de impresora creada apuntando al puerto `USB001`.

---

## 4. Instalador Maestro del Tótem
- [ ] Ejecutado `scripts\01-instalar-totem.bat` ingresando el `TOTEM_ID` correspondiente.
- [ ] Repositorio `backend-pos-boletos` descargado en `C:\ProgramData\kiosk\backend`.
- [ ] Dependencias npm instaladas exitosamente (`C:\ProgramData\kiosk\backend\node_modules` presente).
- [ ] Archivo `.env` generado con `PORT=3000`, `TBK_PORT_PATH=AUTO` y nombre de impresora.
- [ ] Políticas Enterprise de Chrome aplicadas (`LocalNetworkAccessAllowedForUrls`).
- [ ] Acceso de inicio automático creado en la carpeta `Startup` del usuario `wit`.
- [ ] Script `scripts\04-configurar-autologon.ps1` ejecutado (AutoLogon `wit` y suspensión 24/7 desactivada).

---

## 5. Certificación Automática de Hardware y Cloud (16 Puntos)
- [ ] Ejecutado `scripts\02-verificar-totem.ps1 -PrintTest` con **16 OK y 0 FALLOS**:
  - [ ] Node.js v14.18.2 detectado.
  - [ ] Google Chrome detectado.
  - [ ] Backend local `server.js` y `node_modules` presentes.
  - [ ] Políticas Enterprise de Chrome aplicadas.
  - [ ] Impresora térmica detectada en Windows Spooler.
  - [ ] Backend respondiendo `HTTP :3000/health`.
  - [ ] Pinpad Transbank PAX conectado (`connected: true` en `COM5`).
  - [ ] Microservicios Cloud alcanzables: Netlify, Meta-GDS, Publicidad, Convenios, Analítica (HTTP 200).
  - [ ] **Ticket térmico de prueba cortado físicamente por la impresora.**

---

## 6. Prueba de Arranque en Producción (Cold Boot)
- [ ] Ejecutado `shutdown /r /t 5`.
- [ ] Windows 11 inicia sesión automáticamente en `wit` sin pedir contraseña.
- [ ] Backend arranca minimizado en segundo plano y enlaza el POS Transbank.
- [ ] Google Chrome abre a pantalla completa en modo Quiosco con el frontend de venta.
- [ ] Compra de prueba completada con tarjeta física (1 boleto + 1 voucher emitidos).

---

**Firma Técnico Instalador:** `___________________________` &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; **VoBo Operaciones WIT:** `___________________________`
