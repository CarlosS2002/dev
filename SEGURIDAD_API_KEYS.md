# 🔒 Configuración Segura de API Keys

## ⚠️ IMPORTANTE: Seguridad de las Claves

Tus claves de API están ahora protegidas y **NO se subirán a Git**.

## � CONFIGURACIÓN RÁPIDA (IMPORTANTE)

Para que la aplicación funcione después de clonar el repositorio:

### 1️⃣ Android
Abre `android/app/src/main/AndroidManifest.xml` y reemplaza:
```xml
android:value="YOUR_GOOGLE_MAPS_API_KEY"
```
Con tu clave real:
```xml
android:value="AIzaSyCUwXaUvQGkxZUmx81i1JfLgsSFbCY1o44"
```

### 2️⃣ iOS
Abre `ios/Runner/AppDelegate.swift` y reemplaza:
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```
Con tu clave real:
```swift
GMSServices.provideAPIKey("AIzaSyCUwXaUvQGkxZUmx81i1JfLgsSFbCY1o44")
```

### 3️⃣ Flutter (Opcional)
```bash
cp lib/api_keys.example.dart lib/api_keys.dart
# Edita lib/api_keys.dart y añade tu clave
```

**⚠️ NO HAGAS COMMIT de estos cambios después de añadir tus claves reales**

## 📋 Archivos de Respaldo (Solo Local)

Se han creado archivos de respaldo con tus claves que NO se suben a Git:
- `android/app/src/main/AndroidManifest.local.xml` ✅ Ignorado por Git
- `ios/Runner/AppDelegate.local.swift` ✅ Ignorado por Git

Si pierdes tus claves, puedes copiarlas desde estos archivos.

## �📋 Archivos Protegidos

Los siguientes archivos contienen claves sensibles y están en `.gitignore`:

1. **`.env`** - Variables de entorno
2. **`lib/api_keys.dart`** - Claves para Flutter
3. **`android/local.properties`** - Configuración local de Android
4. **`google-services.json`** - Configuración de Firebase (si la usas)

## 🚀 Para Otros Desarrolladores

Si otro desarrollador clona este repositorio, debe:

1. **Copiar el archivo de ejemplo:**
   ```bash
   cp .env.example .env
   cp lib/api_keys.example.dart lib/api_keys.dart
   ```

2. **Reemplazar las claves** en los archivos copiados con sus propias claves de API

3. **Obtener su propia API Key de Google Maps:**
   - Ve a: https://console.cloud.google.com/
   - Crea un proyecto
   - Habilita "Maps SDK for Android" y "Maps SDK for iOS"
   - Crea una API Key
   - Copia la clave a los archivos correspondientes

## 📍 Ubicación de las Claves

### Para Flutter (Dart)
- Archivo: `lib/api_keys.dart`
- Uso: `ApiKeys.googleMapsApiKey`

### Para Android
- Archivo: `android/app/src/main/AndroidManifest.xml`
- La clave está hardcodeada (considera usar build.gradle para más seguridad)

### Para iOS
- Archivo: `ios/Runner/AppDelegate.swift`
- La clave está hardcodeada (considera usar Info.plist para más seguridad)

## ⚡ Mejora Futura (Opcional)

Para máxima seguridad, considera:

1. **Usar variables de entorno en tiempo de compilación**
2. **Restringir la API Key** en Google Cloud Console por:
   - Paquete de la aplicación (Android)
   - Bundle ID (iOS)
   - Direcciones IP (si es una API web)
3. **Rotar las claves regularmente**
4. **Usar Firebase Remote Config** para claves dinámicas

## 🔄 Si Ya Subiste las Claves

Si ya subiste las claves a Git anteriormente:

1. **Invalida la API Key antigua** en Google Cloud Console
2. **Genera una nueva API Key**
3. **Actualiza** los archivos locales con la nueva clave
4. **Considera** limpiar el historial de Git (avanzado)

## ✅ Verificación

Para verificar que está funcionando:

```bash
# Verifica que .env no se sube
git status

# Deberías ver que .env y api_keys.dart están ignorados
```

## 📝 Nota

Este proyecto usa la API Key directamente en los archivos de configuración nativos.
Para mayor seguridad en producción, considera implementar un backend que gestione las claves.
