@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Instalador Oficial Totem Boletos.la Chile (WIT)

:: Asegurar que el directorio de trabajo sea siempre la raiz del repositorio
cd /d "%~dp0\.."

:: 1. Verificar permisos de Administrador (auto-elevacion UAC con ventana persistente)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ====================================================================
    echo   [AVISO] Se requieren permisos de Administrador.
    echo   Abriendo nueva consola con privilegios elevados...
    echo ====================================================================
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs -WorkingDirectory '%~dp0..'"
    exit /b
)

:: Asegurar PATH en memoria con rutas estandar de Node.js, Git y Chrome
set "PATH=%PATH%;C:\Program Files\nodejs\;C:\Program Files\Git\cmd\;C:\Program Files\Google\Chrome\Application\"

echo ====================================================================
echo   CONFIGURADOR OFICIAL - TOTEM BOLETOS.LA CHILE (WIT)
echo   Windows 11 + Backend Local (Puerto 3000) + POS + Impresora RAW
echo ====================================================================
echo.

:: 2. Verificar prerrequisitos instalados manualmente por el usuario (NO autoinstalar)
set "PREREQ_ERROR=0"

:: 2.1 Verificar Git
where git >nul 2>&1
if %errorlevel% equ 0 goto git_ok
if exist "C:\Program Files\Git\cmd\git.exe" goto git_ok
echo [ERROR] Git for Windows NO esta instalado.
echo         Instalalo manualmente antes de continuar: https://git-scm.com/downloads/win
set "PREREQ_ERROR=1"
:git_ok

:: 2.2 Verificar Node.js (preferido v14.18.2 x64)
set "NODE_BIN="
where node >nul 2>&1
if %errorlevel% equ 0 set "NODE_BIN=node"
if exist "C:\Program Files\nodejs\node.exe" set "NODE_BIN=C:\Program Files\nodejs\node.exe"

if defined NODE_BIN goto node_check_ver
echo [ERROR] Node.js NO esta instalado.
echo         Instala manualmente Node.js v14.18.2 (x64):
echo         - Archivo local: installers\node-v14.18.2-x64.msi
echo         - Link oficial:  https://nodejs.org/dist/v14.18.2/node-v14.18.2-x64.msi
set "PREREQ_ERROR=1"
goto chrome_check

:node_check_ver
for /f "tokens=*" %%v in ('"!NODE_BIN!" -v 2^>nul') do set "NODE_VER=%%v"
echo [OK] Node.js detectado: !NODE_VER!
echo !NODE_VER! | findstr /B "v14." >nul
if %errorlevel% neq 0 (
    echo [AVISO] Se recomienda Node.js v14.18.2 para compatibilidad con transbank-pos-sdk y serialport.
    echo         Version actual detectada: !NODE_VER!
)

:chrome_check
:: 2.3 Verificar Google Chrome (Program Files, x86, LocalAppData)
set "CHROME_FOUND="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "CHROME_FOUND=C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "CHROME_FOUND=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME_FOUND=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if exist "C:\Users\wit\AppData\Local\Google\Chrome\Application\chrome.exe" set "CHROME_FOUND=C:\Users\wit\AppData\Local\Google\Chrome\Application\chrome.exe"

if defined CHROME_FOUND goto chrome_ok
where chrome >nul 2>&1
if %errorlevel% equ 0 goto chrome_ok
echo [ERROR] Google Chrome NO esta instalado.
echo         Instalalo manualmente antes de continuar:
echo         - Link oficial Offline x64: https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe
echo         - Archivo local: installers\ChromeSetup.exe
set "PREREQ_ERROR=1"
goto check_summary

:chrome_ok
if defined CHROME_FOUND echo [OK] Google Chrome detectado: !CHROME_FOUND!

:check_summary
if "!PREREQ_ERROR!"=="1" (
    echo.
    echo ====================================================================
    echo   Faltan prerrequisitos obligatorios.
    echo   Instalalos manualmente siguiendo el Paso 1 del README.md y vuelve
    echo   a ejecutar este configurador.
    echo ====================================================================
    pause
    exit /b 1
)

echo.

:: 3. Solicitar parametros del nuevo totem con autodeteccion inteligente
set "TOTEM_ID=101"
set /p "TOTEM_ID=Ingrese ID del Totem [default: 101]: "
if "%TOTEM_ID%"=="" set "TOTEM_ID=101"

:: Autodetectar impresora fisica / termica en Windows (ignorar virtuales Microsoft/PDF/OneNote/Fax/XPS)
set "AUTO_PRINTER="
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "(Get-Printer | Where-Object { $_.Name -notmatch 'PDF|OneNote|Fax|XPS|Microsoft' } | Select-Object -First 1).Name"`) do set "AUTO_PRINTER=%%p"

if defined AUTO_PRINTER goto printer_detected

:: Si no hay cola registrada, buscar dispositivo USB fisico conectado (ej: SPRT, POS, Xprinter) y registrarlo automaticamente
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "Add-PrinterDriver -Name 'Generic / Text Only' -ErrorAction SilentlyContinue; Add-PrinterDriver -Name 'Genérica / Sólo texto' -ErrorAction SilentlyContinue; $dev = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB*' -and $_.FriendlyName -match '80mm|58mm|SPRT|\bPOS\b|Xprint|Receipt|Thermal Printer' } | Select-Object -First 1; if ($dev) { $pName = $dev.FriendlyName.Trim(); $drv = (Get-PrinterDriver | Where-Object { $_.Name -match 'Generic|Generica' } | Select-Object -First 1).Name; $pPort = (Get-PrinterPort | Where-Object { $_.Name -like 'USB*' } | Select-Object -First 1).Name; if (-not $pPort) { $pPort = 'USB001' }; if ($drv) { try { Add-Printer -Name $pName -DriverName $drv -PortName $pPort -ErrorAction SilentlyContinue } catch {} }; Write-Output $pName }"`) do set "AUTO_PRINTER=%%p"

:printer_detected
if not defined AUTO_PRINTER set "AUTO_PRINTER=AUTO"

echo [INFO] Impresora termica detectada: !AUTO_PRINTER!
set "PRINTER_NAME=!AUTO_PRINTER!"
set /p "PRINTER_NAME=Confirma el nombre de la impresora termica [default: !AUTO_PRINTER!]: "
if "%PRINTER_NAME%"=="" set "PRINTER_NAME=!AUTO_PRINTER!"

set "KIOSK_URL=https://totem-testing-v3.netlify.app/"
set /p "KIOSK_URL=Ingrese URL del Frontend Kiosco [default: https://totem-testing-v3.netlify.app/]: "
if "%KIOSK_URL%"=="" set "KIOSK_URL=https://totem-testing-v3.netlify.app/"

set "KIOSK_USER=wit"
set /p "KIOSK_USER=Ingrese usuario Windows del Kiosco [default: wit]: "
if "%KIOSK_USER%"=="" set "KIOSK_USER=wit"

set "BACKEND_REPO=https://github.com/MauricioVega01/backend-pos-boletos.git"
set "KIOSK_DIR=C:\ProgramData\kiosk"
set "BACKEND_DIR=%KIOSK_DIR%\backend"

echo.
echo [1/7] Deteniendo instancias previas de Chrome y Node...
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1

echo [2/7] Creando estructura en %KIOSK_DIR%...
if not exist "%KIOSK_DIR%" mkdir "%KIOSK_DIR%"
if not exist "%KIOSK_DIR%\chrome_session" mkdir "%KIOSK_DIR%\chrome_session"

echo [3/7] Descargando / actualizando backend local en %BACKEND_DIR%...
if exist "%BACKEND_DIR%\.git" goto update_backend
if exist "%BACKEND_DIR%" (
    echo [INFO] Respaldando carpeta previa a %BACKEND_DIR%_backup...
    if exist "%BACKEND_DIR%_backup" rmdir /S /Q "%BACKEND_DIR%_backup"
    move "%BACKEND_DIR%" "%BACKEND_DIR%_backup" >nul
)
git clone "%BACKEND_REPO%" "%BACKEND_DIR%"
if %errorlevel% neq 0 (
    echo [ERROR] Fallo el git clone del backend local. Verifica tu red y autenticacion GitHub.
    pause
    exit /b 1
)
goto check_npm

:update_backend
git -C "%BACKEND_DIR%" fetch origin
git -C "%BACKEND_DIR%" checkout master
git -C "%BACKEND_DIR%" pull origin master

:check_npm
if exist "%BACKEND_DIR%\node_modules\express" goto npm_ok
echo [INFO] Instalando dependencias npm del backend local...
pushd "%BACKEND_DIR%"
if exist "C:\Program Files\nodejs\npm.cmd" (
    call "C:\Program Files\nodejs\npm.cmd" install --production
) else (
    call npm install --production
)
set "NPM_ERR=%errorlevel%"
popd
if not exist "%BACKEND_DIR%\node_modules\express" (
    echo [ERROR] Fallo npm install ^(codigo %NPM_ERR%^). Ejecuta manualmente en %BACKEND_DIR%:
    echo         npm install --production
    pause
    exit /b 1
)
:npm_ok

echo [4/7] Generando archivo .env en %BACKEND_DIR%\.env...
(
echo # ========================================================
echo # CONFIGURACION AMBIENTAL - BACKEND TOTEM LOCAL ^(BOLETOS.LA CHILE^)
echo # ========================================================
echo NODE_ENV=production
echo PORT=3000
echo TOTEM_ID=%TOTEM_ID%
echo PRINTER_NAME=%PRINTER_NAME%
echo FORCE_HARDWARE_CONNECTION=true
echo ALLOWED_ORIGINS=*
echo TBK_PORT_PATH=AUTO
echo TBK_BAUD_RATE=115200
echo TBK_TIMEOUT=30000
) > "%BACKEND_DIR%\.env"

echo [5/7] Generando scripts de ejecucion ^(start-backend.bat y shell.bat^)...
(
echo @echo off
echo title Backend Local Totem %TOTEM_ID% ^(Puerto 3000^)
echo set "PATH=%%PATH%%;C:\Program Files\nodejs\;C:\Program Files\Git\cmd\"
echo cd /d "C:\ProgramData\kiosk\backend"
echo :loop
echo if exist "C:\Program Files\nodejs\node.exe" goto run_full_node
echo node src/server.js
echo goto wait_restart
echo :run_full_node
echo "C:\Program Files\nodejs\node.exe" src/server.js
echo :wait_restart
echo echo [KIOSK] Backend detenido. Reiniciando en 2 segundos...
echo timeout /t 2 /nobreak ^>nul
echo goto loop
) > "%KIOSK_DIR%\start-backend.bat"

(
echo @echo off
echo title Totem Runtime Boletos.la ^(ID %TOTEM_ID%^)
echo.
echo reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v LegacyDefaultPrinterMode /t REG_DWORD /d 1 /f ^>nul 2^>^&1
echo set "TARGET_PRINTER=%PRINTER_NAME%"
echo if /I "%%TARGET_PRINTER%%"=="AUTO" for /f "usebackq delims=" %%%%p in ^(`powershell -NoProfile -Command "(Get-Printer | Where-Object { $_.Name -notmatch 'PDF|OneNote|Fax|XPS|Microsoft' } | Select-Object -First 1).Name"`^) do set "TARGET_PRINTER=%%%%p"
echo if not "%%TARGET_PRINTER%%"=="" if /I not "%%TARGET_PRINTER%%"=="AUTO" powershell -NoProfile -Command "(New-Object -ComObject WScript.Network).SetDefaultPrinter('%%TARGET_PRINTER%%')" ^>nul 2^>^&1
echo.
echo taskkill /F /IM node.exe ^>nul 2^>^&1
echo taskkill /F /IM chrome.exe ^>nul 2^>^&1
echo timeout /t 1 /nobreak ^>nul
echo.
echo start /min "POS_BACKEND" cmd /c "C:\ProgramData\kiosk\start-backend.bat"
echo timeout /t 3 /nobreak ^>nul
echo.
echo set "CHROME_EXE="
echo if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
echo if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
echo if exist "%%LocalAppData%%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%%LocalAppData%%\Google\Chrome\Application\chrome.exe"
echo if exist "C:\Users\%KIOSK_USER%\AppData\Local\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=C:\Users\%KIOSK_USER%\AppData\Local\Google\Chrome\Application\chrome.exe"
echo if not defined CHROME_EXE set "CHROME_EXE=chrome.exe"
echo.
echo :kiosk_loop
echo tasklist /FI "IMAGENAME eq chrome.exe" 2^>nul ^| find /I /N "chrome.exe" ^>nul
echo if errorlevel 1 start "" "%%CHROME_EXE%%" --kiosk --kiosk-printing %KIOSK_URL% --disable-web-security --user-data-dir="C:\ProgramData\kiosk\chrome_session" --allow-running-insecure-content --disable-features=BlockInsecurePrivateNetworkRequests,LocalNetworkAccessChecks,LocalNetworkAccessChecksWebSockets --unsafely-treat-insecure-origin-as-secure=http://localhost:3000 --no-first-run --no-default-browser-check --disable-session-crashed-bubble --overscroll-history-navigation=0 --disable-pinch
echo timeout /t 5 /nobreak ^>nul
echo goto kiosk_loop
) > "%KIOSK_DIR%\shell.bat"

:: Otorgar permisos completos al usuario kiosco sobre C:\ProgramData\kiosk
icacls "%KIOSK_DIR%" /grant "%KIOSK_USER%:(OI)(CI)F" /T >nul 2>&1
icacls "%KIOSK_DIR%" /grant "Users:(OI)(CI)M" /T >nul 2>&1

echo [6/7] Aplicando politicas Enterprise de Google Chrome 157+ e impresion silenciosa...
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome" /v PrintPreviewDisabled /f /reg:64 >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome" /v PrintPreviewDisabled /f /reg:32 >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v PrintPreviewUseSystemDefaultPrinter /t REG_DWORD /d 1 /f /reg:64 >nul

:: Permitir HTTPS -> http://localhost:3000 en Chrome 157+ (LocalNetworkAccess)
for /f "tokens=1,2 delims=/" %%a in ("%KIOSK_URL%") do set "KIOSK_ORIGIN=%%a//%%b"
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\LocalNetworkAccessAllowedForUrls" /v 1 /t REG_SZ /d "%KIOSK_ORIGIN%" /f /reg:64 >nul
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\LocalNetworkAccessAllowedForUrls" /v 2 /t REG_SZ /d "https://[*.]boletos.la" /f /reg:64 >nul
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\LoopbackNetworkAllowedForUrls" /v 1 /t REG_SZ /d "%KIOSK_ORIGIN%" /f /reg:64 >nul
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\LoopbackNetworkAllowedForUrls" /v 2 /t REG_SZ /d "https://[*.]boletos.la" /f /reg:64 >nul
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\LocalNetworkAllowedForUrls" /v 1 /t REG_SZ /d "%KIOSK_ORIGIN%" /f /reg:64 >nul
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\LocalNetworkAllowedForUrls" /v 2 /t REG_SZ /d "https://[*.]boletos.la" /f /reg:64 >nul

:: Fijar impresora predeterminada
reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v LegacyDefaultPrinterMode /t REG_DWORD /d 1 /f >nul 2>&1
if /I not "%PRINTER_NAME%"=="AUTO" powershell -NoProfile -Command "(New-Object -ComObject WScript.Network).SetDefaultPrinter('%PRINTER_NAME%')" >nul 2>&1

echo [7/7] Configurando inicio automatico en usuario %KIOSK_USER%...
set "USER_STARTUP=C:\Users\%KIOSK_USER%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "%USER_STARTUP%" (
    if exist "%USER_STARTUP%\Iniciar_Totem.bat" del /F /Q "%USER_STARTUP%\Iniciar_Totem.bat" >nul 2>&1
    (
    echo @echo off
    echo start "" /min cmd /c "C:\ProgramData\kiosk\shell.bat"
    ) > "%USER_STARTUP%\Iniciar_Totem_Kiosk.bat"
    echo [OK] Lanzador creado en: %USER_STARTUP%\Iniciar_Totem_Kiosk.bat
) else (
    echo [AVISO] No existe el perfil %USER_STARTUP% aun.
    echo         Inicia sesion una vez con '%KIOSK_USER%' y vuelve a ejecutar este instalador,
    echo         o copia manualmente un acceso a C:\ProgramData\kiosk\shell.bat en su carpeta Startup.
)

echo.
echo ====================================================================
echo   INSTALACION COMPLETADA CON EXITO (TOTEM ID %TOTEM_ID%)
echo ====================================================================
echo   1) Ejecuta scripts\04-configurar-autologon.ps1 para AutoLogon y energia 24/7.
echo   2) Prueba el backend en vivo: cd C:\ProgramData\kiosk\backend ^&^& node src/server.js
echo   3) Certifica todo con: powershell -ExecutionPolicy Bypass -File scripts\02-verificar-totem.ps1 -PrintTest
echo ====================================================================
pause
