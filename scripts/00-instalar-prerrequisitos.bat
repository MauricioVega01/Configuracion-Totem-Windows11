@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Instalador de Prerrequisitos - Totem Boletos.la Chile

:: 1. Auto-elevación a Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permisos de Administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ====================================================================
echo   INSTALADOR DE PRERREQUISITOS - TOTEM BOLETOS.LA (WINDOWS 11)
echo ====================================================================
echo.

set "INSTALLERS_DIR=%~dp0..\installers"

:: 2. Instalar Google Chrome si no existe
set "CHROME_EXE="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%LocalAppData%\Google\Chrome\Application\chrome.exe"

if defined CHROME_EXE (
    echo [OK] Google Chrome ya instalado en: !CHROME_EXE!
) else (
    echo [INFO] Instalando Google Chrome...
    :: Intentar primero con winget (metodo oficial nativo de Windows 11, no se congela)
    where winget >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] Descargando e instalando via Windows Package Manager (winget)...
        winget install Google.Chrome --silent --accept-package-agreements --accept-source-agreements
    )
    
    :: Si winget no lo instalo o no existe, usar el instalador local con interfaz visible
    if not exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
        if exist "%INSTALLERS_DIR%\ChromeSetup.exe" (
            echo [INFO] Ejecutando ChromeSetup.exe desde carpeta installers...
            start "" "%INSTALLERS_DIR%\ChromeSetup.exe"
            echo [INFO] Esperando a que finalice la instalacion de Google Chrome...
            timeout /t 10 /nobreak >nul
        )
    )
)

:: 3. Instalar Node.js v14.18.2 (x64) si no existe
where node >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%v in ('node -v') do set NODE_VER=%%v
    echo [OK] Node.js detectado: !NODE_VER!
) else (
    echo [INFO] Instalando Node.js v14.18.2 x64 de forma silenciosa...
    if exist "%INSTALLERS_DIR%\node-v14.18.2-x64.msi" (
        start /wait msiexec /i "%INSTALLERS_DIR%\node-v14.18.2-x64.msi" /qn /norestart
        echo [OK] Node.js v14.18.2 instalado exitosamente.
    ) else (
        echo [ERROR] No se encontro installers\node-v14.18.2-x64.msi
    )
)

:: 4. Actualizar PATH en la sesion actual
set "PATH=%PATH%;C:\Program Files\nodejs\;C:\Program Files\Git\cmd\;C:\Program Files\Google\Chrome\Application\"

echo.
echo ====================================================================
echo   PRERREQUISITOS COMPLETADOS
echo   Ya puedes ejecutar scripts\01-instalar-totem.bat
echo ====================================================================
echo.
pause
