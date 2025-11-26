#!/bin/bash

echo "🔍 Verificando configuración del proyecto Lingo Gym..."
echo ""

# Verificar Flutter
echo "✓ Verificando Flutter..."
flutter --version | head -n 1

# Verificar api_keys.dart
echo ""
echo "✓ Verificando api_keys.dart..."
if [ -f "lib/api_keys.dart" ]; then
    echo "  ✅ lib/api_keys.dart existe"
    if grep -q "TU_GOOGLE_MAPS_API_KEY" lib/api_keys.dart; then
        echo "  ⚠️  ADVERTENCIA: Todavía contiene valores de ejemplo"
        echo "     Edita lib/api_keys.dart con tus claves reales"
    else
        echo "  ✅ Parece estar configurado"
    fi
else
    echo "  ❌ ERROR: lib/api_keys.dart no existe"
    echo "     Ejecuta: cp lib/api_keys.example.dart lib/api_keys.dart"
fi

# Verificar google-services.json
echo ""
echo "✓ Verificando google-services.json..."
if [ -f "android/app/google-services.json" ]; then
    echo "  ✅ android/app/google-services.json existe"
    if grep -q "TU_PROJECT_NUMBER" android/app/google-services.json; then
        echo "  ⚠️  ADVERTENCIA: Parece ser el archivo de ejemplo"
        echo "     Descarga el verdadero desde Firebase Console"
    else
        echo "  ✅ Parece ser un archivo válido de Firebase"
    fi
else
    echo "  ❌ ERROR: android/app/google-services.json no existe"
    echo "     Descárgalo desde Firebase Console"
fi

# Verificar dependencias
echo ""
echo "✓ Verificando dependencias..."
if [ -d ".dart_tool" ]; then
    echo "  ✅ Dependencias descargadas"
else
    echo "  ⚠️  Ejecuta: flutter pub get"
fi

# Verificar Firebase en pubspec.yaml
echo ""
echo "✓ Verificando Firebase en pubspec.yaml..."
if grep -q "firebase_core:" pubspec.yaml; then
    echo "  ✅ firebase_core encontrado"
else
    echo "  ❌ ERROR: firebase_core no está en pubspec.yaml"
fi

if grep -q "firebase_auth:" pubspec.yaml; then
    echo "  ✅ firebase_auth encontrado"
else
    echo "  ❌ ERROR: firebase_auth no está en pubspec.yaml"
fi

if grep -q "cloud_firestore:" pubspec.yaml; then
    echo "  ✅ cloud_firestore encontrado"
else
    echo "  ❌ ERROR: cloud_firestore no está en pubspec.yaml"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "📋 RESUMEN"
echo "════════════════════════════════════════════════"
echo ""
echo "Si todos los checks muestran ✅, ejecuta:"
echo "  flutter run"
echo ""
echo "Si hay ❌ o ⚠️, revisa CONFIGURACION.md"
echo ""
