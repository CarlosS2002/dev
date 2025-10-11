# ⚠️ CONFIGURACIÓN REQUERIDA ANTES DE EJECUTAR

## 🔑 API Keys de Google Maps

Este proyecto usa Google Maps y requiere configuración de API Keys antes de ejecutar.

### Pasos Rápidos:

1. **Obtén tu API Key de Google Maps:**
   - Ve a: https://console.cloud.google.com/
   - Crea un proyecto o usa uno existente
   - Habilita "Maps SDK for Android" y "Maps SDK for iOS"
   - Crea una API Key en "Credenciales"

2. **Configura en Android:**
   - Abre: `android/app/src/main/AndroidManifest.xml`
   - Busca: `YOUR_GOOGLE_MAPS_API_KEY`
   - Reemplaza con tu clave real

3. **Configura en iOS:**
   - Abre: `ios/Runner/AppDelegate.swift`
   - Busca: `YOUR_GOOGLE_MAPS_API_KEY`
   - Reemplaza con tu clave real

4. **IMPORTANTE:** 
   - ❌ NO hagas commit después de añadir tus claves reales
   - ✅ Los archivos ya están configurados para no subir las claves

### Archivos de Respaldo

Si ya tienes las claves configuradas, revisa estos archivos (solo locales):
- `android/app/src/main/AndroidManifest.local.xml`
- `ios/Runner/AppDelegate.local.swift`

### Documentación Completa

Lee `SEGURIDAD_API_KEYS.md` para más información sobre seguridad.

## 🚀 Ejecutar la App

Una vez configuradas las claves:

```bash
flutter pub get
flutter run
```

## 📖 Más Información

- Ver: `CONFIGURACION_GOOGLE_MAPS.md` para instrucciones detalladas
- Ver: `SEGURIDAD_API_KEYS.md` para información de seguridad
