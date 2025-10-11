# 🏋️ Configuración del Icono de Lingo Gym

## 📱 Icono de la Aplicación

La aplicación "Lingo Gym" usa el icono del gato musculoso.

## ⚙️ Para Configurar el Icono

### Paso 1: Guardar la imagen del icono

1. **Guarda la imagen del gato musculoso** en: `assets/icon/lingo_gym_icon.png`
2. La imagen debe ser **al menos 1024x1024 píxeles** para mejor calidad
3. Formato: PNG con fondo transparente o blanco

### Paso 2: Generar los iconos

Ejecuta estos comandos para generar automáticamente todos los tamaños de iconos:

```bash
flutter pub get
dart run flutter_launcher_icons
```

Esto generará automáticamente los iconos para:
- ✅ Android (todos los tamaños: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- ✅ iOS (todos los tamaños requeridos)
- ✅ Iconos adaptativos para Android 8.0+

### Paso 3: Verificar

Los iconos se generarán en:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## 🎨 Personalización (Opcional)

Si quieres cambiar el icono en el futuro:

1. Reemplaza la imagen en `assets/icon/lingo_gym_icon.png`
2. Ejecuta nuevamente: `dart run flutter_launcher_icons`

## 📝 Configuración Actual

El archivo `pubspec.yaml` ya está configurado con:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/lingo_gym_icon.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/lingo_gym_icon.png"
```

## ⚠️ Importante

- La imagen debe estar en formato PNG
- Tamaño recomendado: 1024x1024 píxeles o superior
- Para mejores resultados, usa una imagen con fondo transparente
- El fondo adaptativo en Android será blanco (#FFFFFF)

## 🚀 Siguiente Paso

Una vez que hayas guardado la imagen del icono, ejecuta:

```bash
flutter pub get
dart run flutter_launcher_icons
```

¡Y listo! Tu app tendrá el icono del gato musculoso de Lingo Gym 🏋️‍♂️
