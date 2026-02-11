param(
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"
$APP_ID = "com.eva.br"
$FLUTTER = "D:\flutter\bin\flutter.bat"
$ADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "`n=============================" -ForegroundColor Cyan
Write-Host "  EVA Mobile - Deploy" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# 1. Verificar ADB e dispositivo
Write-Host "`n[1/5] Verificando dispositivo..." -ForegroundColor Yellow
if (-not (Test-Path $ADB)) {
    Write-Host "ADB nao encontrado em: $ADB" -ForegroundColor Red
    exit 1
}

$devices = & $ADB devices 2>&1 | Select-String "device$"
if (-not $devices) {
    Write-Host "NENHUM celular conectado!" -ForegroundColor Red
    Write-Host "  1. Ative 'Opcoes do Desenvolvedor' no celular" -ForegroundColor Gray
    Write-Host "  2. Ative 'Depuracao USB'" -ForegroundColor Gray
    Write-Host "  3. Conecte o cabo USB" -ForegroundColor Gray
    Write-Host "  4. Aceite o prompt no celular" -ForegroundColor Gray
    exit 1
}
Write-Host "Dispositivo encontrado!" -ForegroundColor Green

# 2. Desinstalar versao antiga (se existir)
Write-Host "`n[2/5] Desinstalando versao antiga ($APP_ID)..." -ForegroundColor Yellow
$uninstall = & $ADB uninstall $APP_ID 2>&1
if ($uninstall -match "Success") {
    Write-Host "Versao antiga removida!" -ForegroundColor Green
} else {
    Write-Host "Nenhuma versao anterior instalada (OK)" -ForegroundColor Gray
}

# 3. Build (se nao usar -NoBuild)
if (-not $NoBuild) {
    Write-Host "`n[3/5] Limpando build anterior..." -ForegroundColor Yellow
    & $FLUTTER clean 2>&1 | Out-Null
    & $FLUTTER pub get 2>&1 | Out-Null

    Write-Host "`n[4/5] Compilando APK release..." -ForegroundColor Yellow
    & $FLUTTER build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FALHA na compilacao!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Build OK!" -ForegroundColor Green
} else {
    Write-Host "`n[3/5] Build pulado (-NoBuild)" -ForegroundColor Gray
    Write-Host "[4/5] Build pulado (-NoBuild)" -ForegroundColor Gray
}

# 5. Instalar no celular
Write-Host "`n[5/5] Instalando no celular..." -ForegroundColor Yellow

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    $apkPath = "build\app\outputs\apk\release\BETA0001.apk"
}
if (-not (Test-Path $apkPath)) {
    Write-Host "APK nao encontrado! Rode sem -NoBuild" -ForegroundColor Red
    exit 1
}

$apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
Write-Host "APK: $apkPath ($apkSize MB)" -ForegroundColor Gray

& $ADB install -r -d $apkPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "Falha na instalacao! Tentando force install..." -ForegroundColor Yellow
    & $ADB install -r -d -g $apkPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FALHA TOTAL na instalacao!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n=============================" -ForegroundColor Green
Write-Host "  INSTALADO COM SUCESSO!" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Abrir o app automaticamente
Write-Host "`nAbrindo EVA no celular..." -ForegroundColor Yellow
& $ADB shell am start -n "$APP_ID/.MainActivity"
Write-Host "Done!" -ForegroundColor Green
