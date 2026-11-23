#Requires -RunAsAdministrator
param(
    [string]$KioskUser = "totem1"
)

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  CONFIGURACION DE ENERGIA 24/7 Y AUTOLOGON WINDOWS 11 (WIT)" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan

# 1. Plan de energia 24/7 (sin suspension ni apagado de pantalla)
Write-Host "[1/3] Desactivando suspension, hibernacion y apagado de pantalla..." -ForegroundColor Yellow
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
powercfg /hibernate off

# 2. Verificar que exista el usuario kiosco
$userObj = Get-LocalUser -Name $KioskUser -ErrorAction SilentlyContinue
if (-not $userObj) {
    Write-Host "[AVISO] El usuario '$KioskUser' no existe todavia." -ForegroundColor Yellow
    $create = Read-Host "¿Deseas crear el usuario local '$KioskUser' ahora? (S/N)"
    if ($create -match '^[sS]') {
        $secPass = Read-Host "Ingresa contraseña para '$KioskUser'" -AsSecureString
        New-LocalUser -Name $KioskUser -Password $secPass -FullName "Totem Boletos.la" -PasswordNeverExpires -UserMayNotChangePassword
        Add-LocalGroupMember -Group "Users" -Member $KioskUser -ErrorAction SilentlyContinue
        Write-Host "[OK] Usuario '$KioskUser' creado." -ForegroundColor Green
    } else {
        Write-Host "Cancelado. Crea el usuario manualmente y vuelve a ejecutar."
        exit 1
    }
}

# 3. Configurar AutoAdminLogon en Winlogon
Write-Host "[2/3] Configurando inicio de sesion automatico para '$KioskUser'..." -ForegroundColor Yellow
$passPlain = Read-Host "Confirma la contraseña de '$KioskUser' para AutoLogon"
$winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $winlogon -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path $winlogon -Name "DefaultUserName" -Value $KioskUser
Set-ItemProperty -Path $winlogon -Name "DefaultPassword" -Value $passPlain
Set-ItemProperty -Path $winlogon -Name "DefaultDomainName" -Value $env:COMPUTERNAME

Write-Host "[3/3] Desactivando actualizaciones/notificaciones intrusivas de pantalla de bloqueo..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value 1 -Type DWord

Write-Host ""
Write-Host "[OK] Energia 24/7 y AutoLogon configurados para '$KioskUser'." -ForegroundColor Green
Write-Host "     Al reiniciar Windows iniciara sesion automaticamente en '$KioskUser'." -ForegroundColor Green
