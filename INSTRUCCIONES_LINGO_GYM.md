# 🏋️ INSTRUCCIONES: Configurar Lingo Gym

## ✅ Cambios Realizados

Se han actualizado los siguientes archivos con el nombre "Lingo Gym":

1. ✅ `pubspec.yaml` - Descripción y configuración del icono
2. ✅ `android/app/src/main/AndroidManifest.xml` - Nombre en Android
3. ✅ `ios/Runner/Info.plist` - Nombre en iOS

## 📱 Para Completar la Configuración del Icono

### Opción 1: Si ya tienes la imagen guardada

Si ya guardaste la imagen del gato musculoso en `assets/icon/lingo_gym_icon.png`:

```powershell
flutter pub get
dart run flutter_launcher_icons
```

### Opción 2: Si necesitas guardar la imagen primero

1. **Crea el directorio** (si no existe):
   ```powershell
   New-Item -ItemType Directory -Path "assets/icon" -Force
   ```

2. **Guarda la imagen del gato musculoso** como: `assets/icon/lingo_gym_icon.png`
   - Tamaño recomendado: 1024x1024 px o superior
   - Formato: PNG

3. **Genera los iconos**:
   ```powershell
   flutter pub get
   dart run flutter_launcher_icons
   ```

## 🎯 Verificar los Cambios

Para ver el nuevo nombre de la app:

```powershell
flutter run
```

La aplicación ahora se mostrará como **"Lingo Gym"** en:
- 📱 Launcher de Android
- 📱 Home screen de iOS
- 📱 Lista de aplicaciones

## 🔄 Siguiente Commit

Una vez que hayas configurado el icono, puedes hacer commit de los cambios:

```powershell
git status
git add .
git commit -m "🎨 Cambiar nombre a Lingo Gym y configurar icono"
```

## 📖 Documentación Adicional

- Ver `CONFIGURACION_ICONO.md` para más detalles sobre el icono
- Ver `CONFIGURACION_GOOGLE_MAPS.md` para Google Maps
- Ver `SEGURIDAD_API_KEYS.md` para configuración de claves

---

**¡Lingo Gym está casi listo! 🏋️‍♂️💪**
