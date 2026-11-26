param(
    [switch]$PrintTest,
    [string]$PrinterName = ""
)

$ErrorActionPreference = "Continue"
$passed = 0
$failed = 0

# Recargar PATH en memoria para detectar Node.js recien instalado
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
if (Test-Path "C:\Program Files\nodejs\node.exe") {
    $env:Path = "C:\Program Files\nodejs;$env:Path"
}

# Si no se paso PrinterName, leer del .env del backend
if ([string]::IsNullOrWhiteSpace($PrinterName) -and (Test-Path "C:\ProgramData\kiosk\backend\.env")) {
    $envLines = Get-Content "C:\ProgramData\kiosk\backend\.env"
    foreach ($line in $envLines) {
        if ($line -match "^\s*PRINTER_NAME=(.+)$") {
            $PrinterName = $matches[1].Trim()
            break
        }
    }
}
if ([string]::IsNullOrWhiteSpace($PrinterName)) {
    $PrinterName = "w80"
}

function Check-Result($name, $ok, $detail) {
    if ($ok) {
        Write-Host ("[OK]   {0,-42} {1}" -f $name, $detail) -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host ("[FAIL] {0,-42} {1}" -f $name, $detail) -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTICO Y CERTIFICACION POST-INSTALACION - TOTEM WIT CHILE" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Node.js
$nodeVer = (& node -v 2>$null)
if (-not $nodeVer -and (Test-Path "C:\Program Files\nodejs\node.exe")) {
    $nodeVer = (& "C:\Program Files\nodejs\node.exe" -v 2>$null)
}
Check-Result "Node.js instalado" ([bool]$nodeVer) "Version: $nodeVer (recomendado v14.x)"

# 2. Chrome (buscar en x64, x86 y LocalAppData)
$chromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)
$foundChrome = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
Check-Result "Google Chrome instalado" ([bool]$foundChrome) ($foundChrome)

# 3. Archivos Kiosco
Check-Result "Backend en C:\ProgramData\kiosk\backend" (Test-Path "C:\ProgramData\kiosk\backend\src\server.js") "server.js presente"
$rawPrintOk = (Test-Path "C:\ProgramData\kiosk\backend\bin\rawprint.exe")
$kioskPrintOk = (Test-Path "C:\ProgramData\kiosk\shell.bat")
Check-Result "Motor Impresion w80 (Kiosk/RAW)" ($rawPrintOk -or $kioskPrintOk) "Impresion termica silenciosa configurada"
Check-Result "Script shell.bat" (Test-Path "C:\ProgramData\kiosk\shell.bat") "C:\ProgramData\kiosk\shell.bat"
Check-Result "Archivo .env local" (Test-Path "C:\ProgramData\kiosk\backend\.env") "C:\ProgramData\kiosk\backend\.env"

# 4. Politicas Enterprise Chrome 157+
$p1 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome\LocalNetworkAccessAllowedForUrls" -ErrorAction SilentlyContinue
Check-Result "Politica Chrome LocalNetworkAccess" ([bool]$p1) "Permite HTTPS -> localhost:3000"

# 5. Impresora termica w80
$printer = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
Check-Result "Impresora termica '$PrinterName'" ([bool]$printer) ($printer.PortName + " / " + $printer.DriverName)

# 6. Backend local HTTP 3000
try {
    $health = Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 4
    Check-Result "Backend Local HTTP :3000/health" ($health.status -eq "ok") ("Totem ID=$($health.totemId), Impresora=$($health.printer)")
} catch {
    Check-Result "Backend Local HTTP :3000/health" $false "No responde en puerto 3000 (inicia start-backend.bat)"
}

# 7. POS Transbank
try {
    $pos = Invoke-RestMethod -Uri "http://localhost:3000/api/terminal/status" -TimeoutSec 5
    $posOk = ($pos.connected -eq $true -or $pos.data.connected -eq $true)
    $portInfo = if ($pos.port) { $pos.port } elseif ($pos.data.port) { $pos.data.port } else { "sin puerto" }
    Check-Result "POS Transbank USB-Serial" $posOk ("Conectado=$posOk | Puerto=$portInfo")
} catch {
    Check-Result "POS Transbank USB-Serial" $false "Error consultando /api/terminal/status"
}

# 8. Conectividad Cloud WIT
$endpoints = @(
    @{ Name = "Frontend Netlify"; Url = "https://totem-testing-v3.netlify.app/" },
    @{ Name = "Meta-GDS Global"; Url = "https://gds-global.dev-wit.com/api/v1/health" },
    @{ Name = "Publicidad Chile"; Url = "https://backend-boletos-publicidad-chile.dev-wit.com/" },
    @{ Name = "Convenios Chile"; Url = "https://backend-convenios-boletos-chile.dev-wit.com/api/configuraciones/linea/totem" },
    @{ Name = "Analitica Boletos"; Url = "https://boletos-la-analitica.dev-wit.com/" }
)
foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-WebRequest -Uri $ep.Url -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop
        Check-Result ("Cloud: " + $ep.Name) $true ("HTTP " + $resp.StatusCode)
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        # 401/403/404 confirma red HTTPS operativa hacia el servidor (requiere auth)
        if ($code -in 401, 403, 404) {
            Check-Result ("Cloud: " + $ep.Name) $true ("Alcanzable (HTTP $code auth/ruta)")
        } else {
            Check-Result ("Cloud: " + $ep.Name) $false ("Sin respuesta: " + $_.Exception.Message)
        }
    }
}

# 9. Prueba fisica de impresion RAW (opcional con -PrintTest)
if ($PrintTest) {
    Write-Host ""
    Write-Host "Enviando ticket de prueba RAW a impresora $PrinterName..." -ForegroundColor Yellow
    try {
        $body = @{
            ticketCode = "CERT-WIT"
            items = @(
                @{
                    id = "cert-1"
                    withLogo = $true
                    text = "------- CERTIFICACION TOTEM WIT -------`nINSTALACION VERIFICADA CORRECTAMENTE`nIMPRESORA RAW: $PrinterName`nFECHA: $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')`n- - - - - - - - - - - - - - - - - - - -"
                }
            )
        } | ConvertTo-Json -Depth 4
        $printRes = Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/print" -ContentType "application/json" -Body $body -TimeoutSec 8
        Check-Result "Impresion termica RAW de prueba" ($printRes.success -eq $true) "Ticket emitido en $PrinterName"
    } catch {
        Check-Result "Impresion termica RAW de prueba" $false $_.Exception.Message
    }
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ("  RESUMEN: {0} OK  |  {1} FALLOS" -f $passed, $failed) -ForegroundColor ($(if ($failed -eq 0) { "Green" } else { "Yellow" }))
Write-Host "====================================================================" -ForegroundColor Cyan
if ($failed -gt 0) { exit 1 }
