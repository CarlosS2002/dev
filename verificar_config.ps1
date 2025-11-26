# Script de verificación de configuración para Lingo Gym
# Ejecutar con: .\verificar_config.ps1

Write-Host "🔍 Verificando configuración del proyecto Lingo Gym..." -ForegroundColor Cyan
Write-Host ""

# Verificar Flutter
Write-Host "✓ Verificando Flutter..." -ForegroundColor Yellow
flutter --version 2>&1 | Select-Object -First 1

# Verificar api_keys.dart
Write-Host ""
Write-Host "✓ Verificando api_keys.dart..." -ForegroundColor Yellow
if (Test-Path "lib\api_keys.dart") {
    Write-Host "  ✅ lib\api_keys.dart existe" -ForegroundColor Green
    $content = Get-Content "lib\api_keys.dart" -Raw
    if ($content -match "TU_GOOGLE_MAPS_API_KEY") {
        Write-Host "  ⚠️  ADVERTENCIA: Todavía contiene valores de ejemplo" -ForegroundColor Yellow
        Write-Host "     Edita lib\api_keys.dart con tus claves reales"
    } else {
        Write-Host "  ✅ Parece estar configurado" -ForegroundColor Green
    }
} else {
    Write-Host "  ❌ ERROR: lib\api_keys.dart no existe" -ForegroundColor Red
    Write-Host "     Ejecuta: Copy-Item lib\api_keys.example.dart lib\api_keys.dart"
}

# Verificar google-services.json
Write-Host ""
Write-Host "✓ Verificando google-services.json..." -ForegroundColor Yellow
if (Test-Path "android\app\google-services.json") {
    Write-Host "  ✅ android\app\google-services.json existe" -ForegroundColor Green
    $content = Get-Content "android\app\google-services.json" -Raw
    if ($content -match "TU_PROJECT_NUMBER") {
        Write-Host "  ⚠️  ADVERTENCIA: Parece ser el archivo de ejemplo" -ForegroundColor Yellow
        Write-Host "     Descarga el verdadero desde Firebase Console"
    } else {
        Write-Host "  ✅ Parece ser un archivo válido de Firebase" -ForegroundColor Green
    }
} else {
    Write-Host "  ❌ ERROR: android\app\google-services.json no existe" -ForegroundColor Red
    Write-Host "     Descárgalo desde Firebase Console"
    Write-Host "     https://console.firebase.google.com/"
}

# Verificar dependencias
Write-Host ""
Write-Host "✓ Verificando dependencias..." -ForegroundColor Yellow
if (Test-Path ".dart_tool") {
    Write-Host "  ✅ Dependencias descargadas" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Ejecuta: flutter pub get" -ForegroundColor Yellow
}

# Verificar Firebase en pubspec.yaml
Write-Host ""
Write-Host "✓ Verificando Firebase en pubspec.yaml..." -ForegroundColor Yellow
$pubspec = Get-Content "pubspec.yaml" -Raw

if ($pubspec -match "firebase_core:") {
    Write-Host "  ✅ firebase_core encontrado" -ForegroundColor Green
} else {
    Write-Host "  ❌ ERROR: firebase_core no está en pubspec.yaml" -ForegroundColor Red
}

if ($pubspec -match "firebase_auth:") {
    Write-Host "  ✅ firebase_auth encontrado" -ForegroundColor Green
} else {
    Write-Host "  ❌ ERROR: firebase_auth no está en pubspec.yaml" -ForegroundColor Red
}

if ($pubspec -match "cloud_firestore:") {
    Write-Host "  ✅ cloud_firestore encontrado" -ForegroundColor Green
} else {
    Write-Host "  ❌ ERROR: cloud_firestore no está en pubspec.yaml" -ForegroundColor Red
}

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📋 RESUMEN" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Si todos los checks muestran ✅, ejecuta:"
Write-Host "  flutter run" -ForegroundColor Green
Write-Host ""
Write-Host "Si hay ❌ o ⚠️, revisa CONFIGURACION.md"
Write-Host ""
