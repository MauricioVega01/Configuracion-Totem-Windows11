@echo off
chcp 65001 >nul
title Actualizar Backend Local Totem (WIT)

:: Asegurar que el directorio de trabajo sea la raiz del repositorio
cd /d "%~dp0\.."

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permisos de Administrador...
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs -WorkingDirectory '%~dp0..'"
    exit /b
)

:: Asegurar PATH con Node.js, Git y Chrome en la sesion actual
set "PATH=%PATH%;C:\Program Files\nodejs\;C:\Program Files\Git\cmd\;C:\Program Files\Google\Chrome\Application\"

set "BACKEND_DIR=C:\ProgramData\kiosk\backend"
if not exist "%BACKEND_DIR%\.git" (
    echo [ERROR] No se encontro repositorio Git en %BACKEND_DIR%.
    echo         Ejecuta primero scripts\01-instalar-totem.bat
    pause
    exit /b 1
)

echo [1/4] Respaldando .env actual...
copy /Y "%BACKEND_DIR%\.env" "%TEMP%\totem_env_backup.env" >nul 2>&1

echo [2/4] Deteniendo backend local en puerto 3000...
taskkill /F /IM node.exe >nul 2>&1
timeout /t 1 /nobreak >nul

echo [3/4] Descargando ultima version desde GitHub (origin/master)...
git -C "%BACKEND_DIR%" fetch origin
git -C "%BACKEND_DIR%" checkout master
git -C "%BACKEND_DIR%" pull origin master

copy /Y "%TEMP%\totem_env_backup.env" "%BACKEND_DIR%\.env" >nul 2>&1

echo [4/4] Verificando sintaxis de archivos JS...
powershell -NoProfile -Command "Get-ChildItem '%BACKEND_DIR%\src' -Recurse -Filter '*.js' | ForEach-Object { node --check $_.FullName; if ($LASTEXITCODE -ne 0) { throw $_.FullName } }; Write-Host '[OK] Sintaxis verificada sin errores.'"

echo.
echo [LISTO] Backend actualizado. Reinicia el equipo o inicia C:\ProgramData\kiosk\start-backend.bat
pause
