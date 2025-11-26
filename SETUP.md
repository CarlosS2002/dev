# 🚀 Configuración del Proyecto - LingoGym

Este proyecto requiere configuración adicional antes de ejecutarse. Sigue estos pasos:

## 📋 Requisitos Previos

- Flutter SDK 3.9.0 o superior
- Dart 3.9.0 o superior
- Android Studio / Xcode (para desarrollo móvil)
- Cuenta de Google Cloud Platform
- Proyecto de Firebase

## 🔑 Paso 1: Configurar API Keys

### 1.1 Crear archivo de API Keys

```bash
# En la carpeta lib/, crea el archivo api_keys.dart
cp lib/api_keys.dart.example lib/api_keys.dart
```

### 1.2 Obtener Google Maps API Key

1. Ve a [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Crea o selecciona un proyecto
3. Habilita "Maps SDK for Android"
4. Crea credenciales > API Key
5. Copia la clave y pégala en `api_keys.dart`

### 1.3 Obtener Gemini AI API Key

1. Ve a [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Crea una API Key
3. Copia la clave y pégala en `api_keys.dart`

**Archivo final `lib/api_keys.dart`:**
```dart
class ApiKeys {
  static const String googleMapsApiKey = 'AIza...'; // Tu clave real
  static const String geminiApiKey = 'AIza...';      // Tu clave real
}
```

## 🔥 Paso 2: Configurar Firebase

### 2.1 Crear proyecto Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o usa uno existente
3. Registra tu aplicación Android con el package name: `com.company.LingoGym`

### 2.2 Configurar Firebase Authentication

1. En Firebase Console, ve a **Authentication**
2. Habilita el método de inicio de sesión: **Email/Password**
3. Haz clic en "Comenzar"

### 2.3 Configurar Cloud Firestore

1. En Firebase Console, ve a **Firestore Database**
2. Crea una base de datos en modo **producción** o **prueba**
3. Selecciona la ubicación más cercana a tus usuarios

### 2.4 Descargar google-services.json

1. En la configuración del proyecto Firebase
2. Ve a la configuración de tu app Android
3. Descarga el archivo `google-services.json`
4. Cópialo a: `android/app/google-services.json`

```bash
# Debería estar aquí:
android/
  └── app/
      └── google-services.json  ← Aquí
```

**⚠️ IMPORTANTE:** Asegúrate que el `package_name` en `google-services.json` sea: `com.company.LingoGym`

## 📦 Paso 3: Instalar Dependencias

```bash
flutter pub get
```

## 🏃 Paso 4: Ejecutar la Aplicación

### En dispositivo Android:
```bash
flutter run
```

### En emulador:
```bash
flutter emulators --launch <emulator_id>
flutter run
```

## 🔒 Seguridad

**NUNCA subas a Git:**
- ❌ `lib/api_keys.dart` (contiene claves privadas)
- ❌ `android/app/google-services.json` (contiene configuración Firebase)
- ❌ `android/local.properties` (rutas locales)

Estos archivos ya están en `.gitignore` para protegerlos.

## 🐛 Solución de Problemas

### Error: "google-services.json not found"
- Verifica que el archivo esté en `android/app/google-services.json`
- Verifica que el package_name sea `com.company.LingoGym`

### Error: "API key not found"
- Crea el archivo `lib/api_keys.dart` desde el ejemplo
- Verifica que las claves sean válidas

### Error de compilación Gradle
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Firebase Authentication no funciona
- Verifica que Email/Password esté habilitado en Firebase Console
- Verifica que el `google-services.json` sea del proyecto correcto

## 📱 Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada
├── api_keys.dart          # ⚠️ NO SUBIR - Claves API
├── auth_screen.dart       # Pantalla de login
├── register_screen.dart   # Pantalla de registro
├── menu_screen.dart       # Menú principal
├── agenda_screen.dart     # Gestión de actividades
└── ...

android/
└── app/
    └── google-services.json  # ⚠️ NO SUBIR - Config Firebase
```

## 📞 Soporte

Si tienes problemas con la configuración:
1. Revisa que todos los pasos se hayan completado
2. Verifica los logs de Flutter: `flutter run -v`
3. Verifica la consola de Firebase para errores de Authentication/Firestore

## 🎯 Funcionalidades

- ✅ Registro de usuarios con Firebase Auth
- ✅ Login con email/contraseña
- ✅ Perfil de usuario (nombre, rol, fecha nacimiento)
- ✅ Gestión de actividades deportivas
- ✅ Sistema de grupos y entrenamientos
- ✅ Integración con Google Maps
- ✅ Generación de actividades con IA (Gemini)

---

**¡Listo para comenzar!** 🎉
