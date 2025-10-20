# Integración de Gemini AI para Generación de Actividades

## 📋 Resumen

Se ha integrado **Google Gemini AI** (modelo gemini-1.5-flash) para generar actividades deportivas personalizadas automáticamente.

## ✨ Características Implementadas

### 1. **Generación Automática de Actividades**
- Actividades personalizadas basadas en el perfil del usuario
- Variedad de categorías: cardio, fuerza, flexibilidad, deportes, bienestar
- Descripciones motivadoras y específicas
- Puntos ajustados según dificultad (30-100 puntos)
- Duración estimada para cada actividad

### 2. **Interfaz de Usuario**
- **Botón flotante "Generar con IA"**: Aparece cuando no hay grupo seleccionado
- **Badge visual "IA"**: Indica las actividades generadas por Gemini
- **Estado de carga**: Muestra "Generando..." mientras la IA trabaja
- **Notificación**: SnackBar confirma cuántas actividades se generaron

### 3. **Dos Modos de Generación**

#### Modo 1: Actividades Diarias Personales
- Para usuarios sin grupo asignado
- Para usuarios que quieren rutinas individuales
- Genera 5 actividades variadas para el día

#### Modo 2: Actividades Alternativas (Futuro)
- Para usuarios que quieren algo diferente al grupo
- Evita duplicar las actividades del grupo
- Ofrece opciones creativas y variadas

## 🏗️ Arquitectura

### Archivos Modificados/Creados

1. **`lib/gemini_service.dart`** (NUEVO)
   - Clase `ActividadGenerada`: Modelo simple para respuestas de IA
   - Clase `GeminiService`: Servicio principal de integración
   - Métodos:
     - `generarActividadesDiarias()`: Genera rutina diaria
     - `generarActividadesAlternativas()`: Genera alternativas (futuro)
     - `_actividadesPorDefecto()`: Fallback en caso de error

2. **`lib/agenda_provider.dart`** (MODIFICADO)
   - Agregado: `GeminiService _geminiService`
   - Agregado: `bool _generandoActividades` (estado de carga)
   - Nuevo método: `generarActividadesConIA()` - Genera y agrega actividades
   - Nuevo método: `getActividadesPersonales()` - Filtra actividades personales

3. **`lib/agenda_screen.dart`** (MODIFICADO)
   - Modificado: `_buildBotonAccion()` - Botón de IA cuando no hay grupo
   - Nuevo método: `_generarActividadesConIA()` - Maneja la generación
   - Modificado: `_buildListaActividades()` - Muestra actividades personales
   - Agregado: Badge visual "IA" en el título de actividades

4. **`pubspec.yaml`** (MODIFICADO)
   - Agregado: `google_generative_ai: ^0.4.6`

## 🔑 API Key

**Ubicación actual**: Hardcodeada en `lib/gemini_service.dart` (línea 20)

```dart
static const String _apiKey = 'AIzaSyDa8gPD4MfEK_3JZ7V4dFGqK8Npy5wRHkQ';
```

### ⚠️ IMPORTANTE - Seguridad
Esta es una API key temporal para desarrollo. Para producción:
1. Mueve la key a un archivo `.env`
2. Agrega `.env` al `.gitignore`
3. Usa `flutter_dotenv` para cargar variables de entorno
4. Considera usar Firebase Remote Config para claves

## 🎯 Prompt Engineering

### Estrategia Utilizada
El prompt está diseñado para:
1. **Contexto claro**: "Eres un entrenador deportivo experto"
2. **Especificaciones precisas**: Cantidad, formato, campos requeridos
3. **Personalización**: Usa datos del usuario (nombre, edad, sexo, nivel)
4. **Formato estructurado**: Solicita JSON específico
5. **Limpieza**: Instrucción explícita de NO agregar texto adicional

### Ejemplo de Prompt
```
Eres un entrenador deportivo experto. Genera exactamente 5 actividades deportivas variadas para hoy.

Información del usuario:
- Nombre: Maria
- Nivel de fitness: intermedio

Instrucciones:
1. Crea actividades VARIADAS (cardio, fuerza, flexibilidad, deportes, etc.)
2. Ajusta la intensidad al nivel del usuario
...

Responde SOLO con un JSON válido.
```

## 💰 Costos

### Tier Gratuito
- **60 requests por minuto**
- **Suficiente para**: ~100 usuarios generando rutinas diarias
- **Modelo usado**: gemini-1.5-flash (más rápido y barato)

### Escalabilidad
Si se necesita más capacidad:
- Considerar tier de pago (muy económico)
- Implementar caché de actividades populares
- Limitar generaciones por usuario (ej: 3 por día)

## 🚀 Flujo de Usuario

### Escenario 1: Usuario Sin Grupo
1. Usuario abre la app → Agenda
2. No selecciona ningún grupo (null)
3. Ve pantalla vacía con mensaje "No tienes actividades personales"
4. Aparece botón flotante morado "Generar con IA"
5. Presiona el botón
6. Ve loading "Generando..."
7. Recibe notificación "¡5 actividades generadas con IA!"
8. Ve las actividades en la lista con badge "IA"
9. Puede completarlas como cualquier otra actividad

### Escenario 2: Usuario Con Grupo (Futuro)
1. Usuario selecciona su grupo
2. Ve las actividades del grupo
3. Presiona botón "Generar Alternativas con IA"
4. IA genera actividades diferentes
5. Usuario puede elegir entre actividades del grupo o de IA

## 📊 Datos de Actividades Generadas

Las actividades incluyen:
- **ID único**: `ai_{timestamp}_{index}`
- **Nombre**: Corto y atractivo (máx 20 caracteres)
- **Descripción**: Motivadora y específica (2-3 líneas)
- **Puntos**: 30-100 según dificultad
- **Duración**: Tiempo estimado en minutos
- **Categoría**: cardio, fuerza, flexibilidad, deportes, bienestar
- **Fecha**: Hoy
- **GrupoId**: `personal_{email}` para actividades personales
- **CreadoPor**: "Gemini AI" (para identificación visual)

## 🎨 Diseño Visual

### Badge de IA
```
┌────────────────────┐
│  ⭐ Cardio HIIT   │ [✨ IA]
│  45 puntos         │
└────────────────────┘
```

- Gradiente púrpura: `Colors.deepPurple` → `Colors.purple.shade300`
- Icono: `auto_awesome` (✨)
- Texto: "IA" en blanco, bold
- Posición: Trailing del título

### Botón Flotante
- **Color**: `Colors.deepPurple` (diferente del botón normal)
- **Icono normal**: `auto_awesome` (✨)
- **Icono loading**: `CircularProgressIndicator`
- **Texto normal**: "Generar con IA"
- **Texto loading**: "Generando..."

## 🔄 Manejo de Errores

### Niveles de Fallback
1. **Nivel 1**: Si la API falla, usa actividades por defecto
2. **Nivel 2**: Si el JSON es inválido, limpia markdown y reintenta
3. **Nivel 3**: Si todo falla, devuelve 3 actividades hardcodeadas

### Actividades por Defecto
```dart
[
  'Caminata 30min' (40 pts),
  'Flexiones x20' (35 pts),
  'Estiramiento' (30 pts)
]
```

## 🧪 Testing

### Casos de Prueba
1. ✅ Generación exitosa con respuesta válida
2. ✅ Manejo de error de API
3. ✅ JSON con markdown (```json)
4. ✅ Usuario sin grupo ve botón de IA
5. ✅ Usuario con grupo NO ve botón de IA (ve botón crear)
6. ✅ Badge "IA" aparece en actividades generadas
7. ✅ Actividades completables como normales

### Próximos Tests
- [ ] Diferentes perfiles de usuario (edad, nivel)
- [ ] Generación de alternativas
- [ ] Caché de respuestas
- [ ] Rate limiting

## 📈 Métricas de Éxito

### KPIs a Monitorear
1. **Tasa de uso**: % de usuarios que generan actividades
2. **Completación**: % de actividades de IA completadas vs manuales
3. **Satisfacción**: Feedback sobre calidad de actividades
4. **Performance**: Tiempo de respuesta de la API
5. **Errores**: Tasa de fallos en generación

## 🔮 Mejoras Futuras

### Fase 2: Personalización Avanzada
- [ ] Leer edad desde perfil de usuario
- [ ] Leer sexo desde perfil
- [ ] Considerar historial de actividades
- [ ] Detectar preferencias automáticamente

### Fase 3: Inteligencia Adaptativa
- [ ] Progresión automática de dificultad
- [ ] Basado en tasa de completación
- [ ] Evitar actividades repetidas
- [ ] Variedad por día de la semana

### Fase 4: Actividades Alternativas
- [ ] Botón en vista de grupo
- [ ] Generar alternativas a actividades del grupo
- [ ] Permitir elegir entre ambas opciones

### Fase 5: Analytics
- [ ] Tracking de uso de IA
- [ ] A/B testing de prompts
- [ ] Optimización de calidad

## 📝 Notas Técnicas

### Limitaciones Actuales
- API key hardcodeada (no seguro para producción)
- No hay caché de respuestas
- No hay rate limiting por usuario
- No lee datos completos del perfil (solo email)
- No hay persistencia de actividades entre sesiones

### Dependencias
```yaml
google_generative_ai: ^0.4.6  # Google Gemini AI SDK
```

### Compatibilidad
- ✅ Android
- ✅ iOS
- ✅ Web (requiere configuración CORS)
- ⚠️ Requiere conexión a internet

## 🎓 Aprendizajes

### Lo que Funcionó Bien
1. Modelo gemini-1.5-flash es rápido y efectivo
2. Prompt estructurado genera JSON consistente
3. Fallback con actividades por defecto previene crashes
4. Badge visual comunica claramente origen IA

### Desafíos Encontrados
1. Gemini a veces devuelve JSON envuelto en markdown
2. Necesidad de limpiar respuesta antes de parsear
3. Modelo Actividad requería campos que IA no debe conocer
4. Solución: Modelo intermedio `ActividadGenerada`

## 👥 Créditos

**Modelo de IA**: Google Gemini 1.5 Flash  
**Integración**: Implementada en sesión de desarrollo  
**Fecha**: 19 de Octubre, 2025  

---

## 🚀 Cómo Usar

### Para Usuarios
1. Abre la app
2. Ve a "Agenda"
3. No selecciones ningún grupo (deja en "Todas las actividades")
4. Presiona el botón morado "Generar con IA"
5. Espera unos segundos
6. ¡Disfruta tus actividades personalizadas!

### Para Desarrolladores
```dart
// Generar actividades
final actividades = await agendaProvider.generarActividadesConIA(
  usuarioEmail: userEmail,
);

// Obtener actividades personales
final personales = agendaProvider.getActividadesPersonales(userEmail);
```

---

**Estado**: ✅ Implementado y Funcional  
**Versión**: 1.0  
**Última actualización**: 19 Oct 2025
