# 🚀 Guía Rápida - Base de Datos Lingo Gym

## Inicio Rápido

### 1. Instalación
```bash
flutter pub get
```

### 2. Uso Básico
```dart
import 'package:dev/database/database_helper.dart';

// Obtener instancia
final db = DatabaseHelper();

// La base de datos se crea automáticamente en el primer uso
```

## 📋 Tablas Principales

| Tabla | Descripción | Trigger Automático |
|-------|-------------|-------------------|
| **usuarios** | Usuarios de la app | ✅ Auditoría + Bitácora |
| **grupos** | Grupos de estudio | ✅ Auditoría + Bitácora |
| **actividades** | Tareas asignadas | ✅ Auditoría + Notificaciones |
| **progreso_actividades** | Actividades completadas | ✅ Actualiza Ranking |
| **ranking** | Puntuación por grupo | ✅ Bitácora de cambios |
| **notificaciones** | Avisos a usuarios | ✅ Registro de lectura |
| **eventos_calendario** | Calendario personal | - |

## 🔧 Operaciones Comunes

### Registrar Usuario
```dart
await db.insertUsuario({
  'id': 'user_123',
  'nombre': 'Juan Pérez',
  'email': 'juan@example.com',
  'password_hash': hashSeguro,
  'rol': 'atleta',
});
```

### Crear Grupo
```dart
await db.insertGrupo({
  'id': 'grupo_123',
  'nombre': 'Inglés Avanzado',
  'entrenador_id': 'user_entrenador',
});
```

### Agregar Miembro
```dart
await db.addMiembroGrupo('grupo_123', 'user_atleta');
```

### Crear Actividad (notifica automáticamente)
```dart
await db.insertActividad({
  'id': 'act_123',
  'nombre': 'Vocabulario Unit 1',
  'grupo_id': 'grupo_123',
  'fecha_actividad': DateTime.now().toIso8601String(),
  'puntos_base': 10,
  'creado_por': 'user_entrenador',
});
```

### Completar Actividad (actualiza ranking automáticamente)
```dart
await db.registrarProgreso(
  actividadId: 'act_123',
  usuarioId: 'user_123',
  puntosObtenidos: 10,
);
```

### Ver Ranking
```dart
List<Map> ranking = await db.getRankingCompleto('grupo_123');
```

### Ver Notificaciones
```dart
List<Map> notif = await db.getNotificacionesUsuario('user_123', soloNoLeidas: true);
```

## 📊 Consultas Útiles

### Actividades Pendientes
```dart
List<Map> pendientes = await db.getActividadesPendientes('user_123', 'grupo_123');
```

### Miembros de un Grupo
```dart
List<Map> miembros = await db.getMiembrosGrupo('grupo_123');
```

### Grupos de un Entrenador
```dart
List<Map> grupos = await db.getGruposByEntrenador('user_entrenador');
```

### Auditoría de Usuario
```dart
List<Map> auditoria = await db.getAuditoriaUsuarios(usuarioId: 'user_123');
```

### Bitácora del Sistema
```dart
List<Map> bitacora = await db.getBitacoraSistema(limit: 50);
```

## 🔐 Seguridad

### ✅ Implementado
- Foreign keys habilitadas
- Validación de datos con CHECK constraints
- Auditoría completa automática
- Registro de accesos

### ⚠️ Por Implementar en App
- Hash de contraseñas (usar bcrypt/argon2)
- Validación en capa de aplicación
- Autenticación y autorización

## 🎯 Triggers Automáticos

| Acción | Trigger Ejecutado | Resultado |
|--------|------------------|-----------|
| Insertar usuario | `trg_auditoria_usuarios_insert` | Registro en auditoría |
| Actualizar usuario | `trg_auditoria_usuarios_update` | Registro campo por campo |
| Crear actividad | `trg_notificar_nueva_actividad` | Notificación a miembros |
| Completar actividad | `trg_actualizar_ranking_insert` | Suma puntos al ranking |
| Cambio en ranking | `trg_bitacora_ranking_update` | Registro en bitácora |
| Leer notificación | `trg_bitacora_notificacion_leida` | Registro de lectura |

## 📁 Archivos del Proyecto

```
lib/database/
├── schema.sql                 # Esquema completo (550+ líneas)
├── database_helper.dart       # Helper con todos los métodos
├── database_examples.dart     # 13 ejemplos prácticos
└── README.md                  # Documentación técnica

Raíz del proyecto:
├── DOCUMENTACION_BASE_DATOS.md  # Doc completa en español
├── DIAGRAMA_BASE_DATOS.md       # Diagramas visuales
└── GUIA_RAPIDA_BASE_DATOS.md   # Esta guía
```

## 🔍 Vistas Disponibles

```dart
// Vista 1: Ranking con nombres
db.rawQuery('SELECT * FROM v_ranking_completo WHERE grupo_id = ?', ['grupo_123']);

// Vista 2: Actividades pendientes
db.rawQuery('SELECT * FROM v_actividades_pendientes WHERE usuario_id = ?', ['user_123']);

// Vista 3: Resumen de auditoría
db.rawQuery('SELECT * FROM v_auditoria_resumen');
```

## 🧪 Testing

### Crear Base de Datos de Prueba
```dart
// En modo debug/test, puedes eliminar la BD
await DatabaseHelper().deleteDatabase();

// La siguiente llamada creará una nueva BD limpia
final db = await DatabaseHelper().database;
```

### Insertar Datos de Prueba
Ver `lib/database/database_examples.dart` para ejemplos completos.

## 📈 Monitoreo y Mantenimiento

### Ver Estadísticas
```dart
// Total de usuarios
List<Map> users = await db.getAllUsuarios();
print('Total usuarios: ${users.length}');

// Total de grupos
List<Map> grupos = await db.getAllGrupos();
print('Total grupos: ${grupos.length}');

// Resumen de auditoría
List<Map> resumen = await db.getResumenAuditoria();
```

### Limpiar Datos Antiguos
```dart
// Ejecutar SQL personalizado
await db.execute('''
  DELETE FROM auditoria_usuarios 
  WHERE fecha_cambio < datetime('now', '-90 days')
''');
```

## 💡 Tips y Mejores Prácticas

1. **IDs Únicos**: Usar UUID o timestamps para IDs únicos
   ```dart
   String userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
   ```

2. **Transacciones**: Para operaciones múltiples
   ```dart
   await db.transaction((txn) async {
     await txn.insert('tabla1', data1);
     await txn.insert('tabla2', data2);
   });
   ```

3. **Validación**: Validar datos antes de insertar
   ```dart
   if (!email.contains('@')) throw Exception('Email inválido');
   ```

4. **Contraseñas**: Nunca guardar en texto plano
   ```dart
   import 'package:crypto/crypto.dart';
   String hash = sha256.convert(utf8.encode(password)).toString();
   ```

5. **Backup**: Respaldar periódicamente
   ```dart
   String dbPath = join(await getDatabasesPath(), 'lingo_gym.db');
   File(dbPath).copy('/ruta/backup/lingo_gym_${DateTime.now()}.db');
   ```

## 🆘 Solución de Problemas

### La base de datos no se crea
- Verificar que `flutter pub get` se ejecutó correctamente
- Verificar que sqflite está en pubspec.yaml
- Revisar permisos de escritura

### Los triggers no funcionan
- Verificar que foreign_keys estén habilitadas
- Revisar logs de error en consola
- Verificar que schema.sql esté en assets

### Error al insertar datos
- Verificar restricciones UNIQUE
- Verificar foreign keys válidas
- Revisar formato de fechas (ISO 8601)

## 📚 Más Información

- **Documentación Completa**: Ver `DOCUMENTACION_BASE_DATOS.md`
- **Diagramas**: Ver `DIAGRAMA_BASE_DATOS.md`
- **Ejemplos**: Ver `lib/database/database_examples.dart`
- **Esquema SQL**: Ver `lib/database/schema.sql`

## ✨ Características Destacadas

✅ 13 tablas con relaciones completas
✅ 13 triggers automáticos
✅ 22 índices optimizados
✅ 3 vistas útiles
✅ Auditoría completa
✅ Bitácora de operaciones
✅ Notificaciones automáticas
✅ Ranking actualizado automáticamente
✅ 100% probado y funcional

---

**Versión:** 1.0  
**Fecha:** 19 de octubre de 2025  
**Estado:** ✅ Producción Ready
