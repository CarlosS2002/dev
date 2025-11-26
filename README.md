# 🏋️ LingoGym - Tu Gimnasio de Idiomas

Aplicación móvil Flutter para gestionar actividades deportivas, entrenamientos y grupos con integración de IA.

## ⚠️ CONFIGURACIÓN REQUERIDA

**Este proyecto NO funcionará directamente después de clonar.** Necesitas configurar:

1. 🔑 API Keys (Google Maps, Gemini AI)
2. 🔥 Firebase (Authentication + Firestore)
3. 📱 google-services.json

### 📖 Lee la guía completa de configuración:

👉 **[SETUP.md](./SETUP.md)** 👈

## 🚀 Inicio Rápido

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd dev

# 2. Crear archivo de API keys
cp lib/api_keys.dart.example lib/api_keys.dart
# Edita lib/api_keys.dart con tus claves reales

# 3. Configurar Firebase
# - Descarga google-services.json desde Firebase Console
# - Cópialo a: android/app/google-services.json

# 4. Instalar dependencias
flutter pub get

# 5. Ejecutar
flutter run
```

## 📋 Requisitos

- Flutter SDK 3.9.0+
- Dart 3.9.0+
- Android Studio / Xcode
- Cuenta de Google Cloud Platform
- Proyecto Firebase

## ✨ Características

- 🔐 Autenticación con Firebase (Email/Contraseña)
- 👤 Perfiles de usuario (Atleta/Entrenador)
- 📅 Gestión de actividades deportivas
- 👥 Sistema de grupos y entrenamientos
- 🗺️ Integración con Google Maps
- 🤖 Generación de actividades con Gemini AI
- 🌙 Modo oscuro/claro
- 📱 Diseño responsivo

## 🏗️ Tecnologías

- **Framework:** Flutter 3.9.0
- **Lenguaje:** Dart 3.9.0
- **Backend:** Firebase (Auth + Firestore)
- **Maps:** Google Maps API
- **IA:** Google Gemini AI
- **Estado:** Provider

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  google_maps_flutter: ^2.5.0
  provider: ^6.1.2
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
```

## 🔒 Seguridad

**Archivos protegidos (NO subir a Git):**
- ❌ `lib/api_keys.dart`
- ❌ `android/app/google-services.json`
- ❌ `android/local.properties`

Estos archivos están en `.gitignore` automáticamente.

## 📱 Capturas

[Aquí puedes agregar capturas de pantalla de la app]

## 🤝 Contribuir

1. Fork el proyecto
2. Crea tu rama de features (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add: AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 👨‍💻 Autores

- **CarlosS2002** - Desarrollo inicial
- **CDavid** - Colaborador

## 📄 Licencia

Este proyecto es privado y de uso educativo.

## 🆘 Soporte

Si tienes problemas con la configuración, revisa:
1. [SETUP.md](./SETUP.md) - Guía completa de configuración
2. Issues del repositorio
3. Logs de Flutter: `flutter run -v`

---

**¡Importante!** Lee [SETUP.md](./SETUP.md) antes de intentar ejecutar el proyecto.
