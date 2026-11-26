# Checklist de Despliegue y Certificación por Tótem Nuevo (WIT)

Completar para cada unidad desplegada en terminal o punto de venta.

- **Tótem ID asignado:** `____________`
- **Terminal / Ubicación:** `____________________________`
- **Técnico responsable:** `____________________________`
- **Fecha:** `____ / ____ / 202__`

---

## 1. Preparación de Sistema Operativo y Hardware
- [ ] Windows 11 activado y hora sincronizada (`America/Santiago`).
- [ ] Pantalla táctil en orientación **Vertical (`1080×1920`)**, escala `100%`, toque calibrado.
- [ ] Usuario kiosco `wit` creado y configurado con `AutoAdminLogon` (`scripts\04-configurar-autologon.ps1`).
- [ ] Suspensión, hibernación y apagado automático de pantalla desactivados (`powercfg`).
- [ ] **Node.js v14.18.2 (x64)**, **Git** y **Google Chrome x64** instalados.
- [ ] Impresora térmica instalada con nombre exacto **`w80`**, papel 80mm cargado y prueba de corte OK.
- [ ] Pinpad Transbank conectado vía USB y visible como puerto **`COMx`** en Administrador de dispositivos.

## 2. Instalación y Certificación Automática
- [ ] Ejecutado `scripts\01-instalar-totem.bat` con el `TOTEM_ID` correcto.
- [ ] Ejecutado `scripts\02-verificar-totem.ps1 -PrintTest` con **0 fallos (`[FAIL]`)**.
- [ ] Ticket de certificación RAW impreso con logo nítido y corte limpio en menos de 1 segundo.
- [ ] Cold Boot (reinicio físico completo): Windows inicia en `wit`, levanta puerto `3000` + Pinpad + Chrome Kiosk sin intervención humana.

## 3. Pruebas Funcionales End-to-End (E2E)
- [ ] Pantalla inicial vinculada al `TOTEM_ID` y videos de screensaver reproduciendo correctamente.
- [ ] Código técnico **`PC-TEST`** en *Imprimir Pasaje* imprime correctamente.
- [ ] Búsqueda de viajes en vivo desde Meta-GDS Global (Ida y Vuelta) operativa.
- [ ] Validación de convenio con RUT real muestra el mismo precio final en lista de servicios, croquis, pago y boleto.
- [ ] Compra real de prueba con tarjeta (Débito y Crédito) aprobada en Pinpad Transbank productivo.
- [ ] Ticket físico impreso con datos reales de Transbank (1 boleto por pasajero/tramo + 1 voucher por orden).
- [ ] Verificado registro de la compra en: (1) Meta-GDS / `pullman.cl`, (2) BD Analítica (`origen_transaccion = 'totem-XXX'`) y (3) BD Publicidad (`totem_id = XXX`).
- [ ] **`modo_prueba` desactivado (`false`)** en el Mantenedor antes de abrir al público.

**Firma Técnico Instalador:** `____________________` &nbsp;&nbsp; **VoBo Operaciones WIT:** `____________________`
