# Configuración de Google Maps para Flutter

## ✅ Integración Completada

Se ha integrado Google Maps en el botón **home4** del menú principal. La pantalla muestra:
- 📍 Marcador en la Universidad Autónoma de Bucaramanga (UNAB)
- 🗺️ Mapa interactivo de Google Maps
- 📱 Botones flotantes para centrar la cámara y ver información
- 🔍 Coordenadas: Lat: 7.116816, Lng: -73.105240

## ⚙️ Configuración Requerida

Para que Google Maps funcione correctamente, necesitas configurar las API Keys:

### 📱 Android

1. **Obtener API Key de Google Cloud Console:**
   - Ve a: https://console.cloud.google.com/
   - Crea un proyecto o selecciona uno existente
   - Habilita "Maps SDK for Android"
   - Ve a "Credenciales" y crea una API Key

2. **Configurar en Android:**
   - Abre: `android/app/src/main/AndroidManifest.xml`
   - Dentro de la etiqueta `<application>`, agrega:

```xml
<application>
    <!-- ... otras configuraciones ... -->
    
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="TU_API_KEY_AQUI"/>
</application>
```

3. **Permisos (ya incluidos en el AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 🍎 iOS

1. **Obtener API Key de Google Cloud Console:**
   - La misma del paso anterior o crea una nueva
   - Habilita "Maps SDK for iOS"

2. **Configurar en iOS:**
   - Abre: `ios/Runner/AppDelegate.swift`
   - Importa Google Maps y configura la API Key:

```swift
import UIKit
import Flutter
import GoogleMaps  // Agregar esta línea

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("TU_API_KEY_AQUI")  // Agregar esta línea
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

3. **Actualizar el Podfile:**
   - Abre: `ios/Podfile`
   - Asegúrate de que tenga la plataforma correcta:

```ruby
platform :ios, '14.0'
```

4. **Instalar pods:**
```bash
cd ios
pod install
cd ..
```

### 🔧 Configuración de Permisos iOS

Edita `ios/Runner/Info.plist` y agrega:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta app necesita acceso a tu ubicación para mostrarla en el mapa</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Esta app necesita acceso a tu ubicación para mostrarla en el mapa</string>
```

## 🚀 Cómo Usar

1. **Iniciar la app:** `flutter run`
2. **Navegar:** Desde el menú principal, presiona el botón **home4** (cuarto botón)
3. **Interactuar:**
   - 👆 Arrastra para mover el mapa
   - 🤏 Pellizca para hacer zoom
   - 📍 Toca el marcador para ver información
   - 🎯 Usa el botón flotante azul para centrar
   - ℹ️ Usa el botón flotante verde para ver detalles

## 📦 Dependencias Instaladas

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
```

## 🎨 Características Implementadas

- ✅ Mapa interactivo de Google Maps
- ✅ Marcador personalizado en UNAB Bucaramanga
- ✅ Ventana de información al tocar el marcador
- ✅ Botón para centrar la cámara
- ✅ Botón de información con diálogo
- ✅ Controles de zoom habilitados
- ✅ Botón de ubicación actual habilitado
- ✅ Brújula habilitada
- ✅ AppBar con título y botón de regreso
- ✅ Integración con el sistema de navegación de la app

## 🔍 Solución de Problemas

### Si el mapa no se muestra:
1. Verifica que la API Key esté configurada correctamente
2. Asegúrate de que las APIs estén habilitadas en Google Cloud Console
3. Revisa que no haya restricciones en la API Key
4. Ejecuta `flutter clean` y `flutter pub get`

### Si hay error de compilación en Android:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Si hay error en iOS:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

## 📝 Notas Importantes

- 🆓 Google Maps tiene un plan gratuito con límite de uso mensual
- 💳 Se recomienda configurar alertas de facturación en Google Cloud Console
- 🔒 Considera restringir la API Key por aplicación para mayor seguridad
- 🌍 El mapa requiere conexión a internet para funcionar

## 🎯 Próximos Pasos (Opcional)

Puedes mejorar la funcionalidad agregando:
- 📍 Múltiples marcadores
- 🗺️ Rutas entre ubicaciones
- 🎨 Marcadores personalizados con imágenes
- 📏 Medición de distancias
- 🔍 Búsqueda de lugares
- 🌙 Temas de mapa (normal, satélite, híbrido, terreno)
