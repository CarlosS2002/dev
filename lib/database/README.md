# Base de Datos SQLite - Lingo Gym

## Descripción General

Este directorio contiene la implementación de la base de datos SQLite para la aplicación Lingo Gym. La base de datos está diseñada para gestionar usuarios, grupos, actividades, ranking, notificaciones y un sistema completo de auditoría y bitácora.

## Archivos

- **schema.sql**: Contiene el esquema completo de la base de datos incluyendo:
  - Definición de tablas
  - Índices para optimización
  - Triggers de auditoría
  - Triggers de negocio
  - Vistas útiles

- **database_helper.dart**: Clase helper en Dart que proporciona:
  - Inicialización de la base de datos
  - Métodos CRUD para todas las entidades
  - Métodos de consulta especializados
  - Gestión de transacciones

## Estructura de la Base de Datos

### Tablas Principales

#### 1. usuarios
Almacena información de los usuarios de la aplicación.

**Campos:**
- `id` (TEXT, PK): Identificador único del usuario
- `nombre` (TEXT): Nombre completo
- `email` (TEXT, UNIQUE): Correo electrónico
- `password_hash` (TEXT): Hash de la contraseña
- `rol` (TEXT): 'atleta' o 'entrenador'
- `fecha_registro` (DATETIME): Fecha de registro
- `ultimo_acceso` (DATETIME): Última vez que ingresó
- `activo` (INTEGER): 1 = activo, 0 = inactivo
- `foto_perfil` (TEXT): URL o ruta de la foto
- `idioma_preferido` (TEXT): Código de idioma (ej: 'es', 'en')

#### 2. grupos
Almacena información de los grupos de estudio.

**Campos:**
- `id` (TEXT, PK): Identificador único del grupo
- `nombre` (TEXT): Nombre del grupo
- `descripcion` (TEXT): Descripción del grupo
- `entrenador_id` (TEXT, FK): ID del entrenador
- `fecha_creacion` (DATETIME): Fecha de creación
- `activo` (INTEGER): Estado del grupo
- `max_miembros` (INTEGER): Número máximo de miembros (default: 50)

#### 3. grupos_miembros
Tabla de relación muchos a muchos entre usuarios y grupos.

**Campos:**
- `id` (INTEGER, PK, AUTOINCREMENT): ID único
- `grupo_id` (TEXT, FK): ID del grupo
- `usuario_id` (TEXT, FK): ID del usuario
- `fecha_ingreso` (DATETIME): Fecha de ingreso al grupo
- `estado` (TEXT): 'activo', 'inactivo', 'bloqueado'

#### 4. actividades
Almacena las actividades/tareas asignadas a los grupos.

**Campos:**
- `id` (TEXT, PK): Identificador único
- `nombre` (TEXT): Nombre de la actividad
- `descripcion` (TEXT): Descripción detallada
- `grupo_id` (TEXT, FK): Grupo al que pertenece
- `fecha_actividad` (DATETIME): Fecha de la actividad
- `puntos_base` (INTEGER): Puntos que otorga (default: 10)
- `creado_por` (TEXT, FK): Usuario que la creó
- `fecha_creacion` (DATETIME): Fecha de creación
- `activo` (INTEGER): Estado de la actividad
- `tipo_actividad` (TEXT): 'ejercicio', 'tarea', 'examen', 'practica'

#### 5. progreso_actividades
Registra el progreso de los usuarios en las actividades.

**Campos:**
- `id` (INTEGER, PK, AUTOINCREMENT): ID único
- `actividad_id` (TEXT, FK): ID de la actividad
- `usuario_id` (TEXT, FK): ID del usuario
- `fecha_completado` (DATETIME): Fecha de completación
- `puntos_obtenidos` (INTEGER): Puntos ganados
- `calificacion` (REAL): Calificación numérica
- `comentario` (TEXT): Comentarios adicionales

#### 6. ranking
Almacena el ranking de usuarios por grupo.

**Campos:**
- `id` (INTEGER, PK, AUTOINCREMENT): ID único
- `usuario_id` (TEXT, FK): ID del usuario
- `grupo_id` (TEXT, FK): ID del grupo
- `puntos_totales` (INTEGER): Puntos acumulados
- `actividades_completadas` (INTEGER): Número de actividades completadas
- `racha_actual` (INTEGER): Racha actual de días
- `mejor_racha` (INTEGER): Mejor racha alcanzada
- `ultima_actualizacion` (DATETIME): Última actualización

#### 7. eventos_calendario
Almacena eventos del calendario de usuarios.

**Campos:**
- `id` (TEXT, PK): Identificador único
- `titulo` (TEXT): Título del evento
- `descripcion` (TEXT): Descripción
- `fecha_inicio` (DATETIME): Fecha y hora de inicio
- `fecha_fin` (DATETIME): Fecha y hora de fin
- `usuario_id` (TEXT, FK): Propietario del evento
- `grupo_id` (TEXT, FK): Grupo relacionado (opcional)
- `tipo_evento` (TEXT): 'personal', 'grupal', 'recordatorio'
- `ubicacion` (TEXT): Ubicación del evento
- `fecha_creacion` (DATETIME): Fecha de creación

#### 8. notificaciones
Almacena las notificaciones para los usuarios.

**Campos:**
- `id` (INTEGER, PK, AUTOINCREMENT): ID único
- `usuario_id` (TEXT, FK): Destinatario
- `titulo` (TEXT): Título de la notificación
- `mensaje` (TEXT): Contenido del mensaje
- `tipo` (TEXT): 'info', 'alerta', 'exito', 'error'
- `leida` (INTEGER): 0 = no leída, 1 = leída
- `fecha_creacion` (DATETIME): Fecha de creación
- `fecha_lectura` (DATETIME): Fecha de lectura
- `datos_adicionales` (TEXT): JSON con datos extra

### Tablas de Auditoría y Bitácora

#### 9. bitacora_sistema
Registra todas las operaciones realizadas en el sistema.

**Campos:**
- `id` (INTEGER, PK, AUTOINCREMENT): ID único
- `tabla_afectada` (TEXT): Nombre de la tabla
- `operacion` (TEXT): 'INSERT', 'UPDATE', 'DELETE'
- `registro_id` (TEXT): ID del registro afectado
- `usuario_id` (TEXT): Usuario que realizó la operación
- `fecha_operacion` (DATETIME): Timestamp de la operación
- `ip_address` (TEXT): Dirección IP
- `user_agent` (TEXT): Información del navegador/dispositivo
- `detalles` (TEXT): JSON con detalles adicionales

#### 10. auditoria_usuarios
Auditoría específica de cambios en usuarios.

**Campos:**
- `id` (INTEGER, PK, AUTOINCREMENT): ID único
- `usuario_id` (TEXT): ID del usuario auditado
- `operacion` (TEXT): Tipo de operación
- `campo_modificado` (TEXT): Campo que cambió
- `valor_anterior` (TEXT): Valor antes del cambio
- `valor_nuevo` (TEXT): Valor después del cambio
- `fecha_cambio` (DATETIME): Timestamp del cambio
- `modificado_por` (TEXT): Quién realizó el cambio
- `razon_cambio` (TEXT): Motivo del cambio

#### 11. auditoria_grupos
Auditoría específica de cambios en grupos.

**Campos:** Similar a auditoria_usuarios pero para grupos.

#### 12. auditoria_actividades
Auditoría específica de cambios en actividades.

**Campos:** Similar a auditoria_usuarios pero para actividades.

#### 13. auditoria_accesos
Registra todos los accesos al sistema.

**Campos:**
- `id` (INTEGER, PK, AUTOINCREMENT): ID único
- `usuario_id` (TEXT): Usuario que accede
- `tipo_acceso` (TEXT): 'login', 'logout', 'intento_fallido'
- `fecha_acceso` (DATETIME): Timestamp del acceso
- `ip_address` (TEXT): Dirección IP
- `dispositivo` (TEXT): Tipo de dispositivo
- `navegador` (TEXT): Navegador utilizado
- `exitoso` (INTEGER): 1 = exitoso, 0 = fallido
- `motivo_fallo` (TEXT): Razón del fallo

## Triggers Implementados

### Triggers de Auditoría

1. **Usuarios:**
   - `trg_auditoria_usuarios_insert`: Registra nuevos usuarios
   - `trg_auditoria_usuarios_update`: Registra cambios en usuarios
   - `trg_auditoria_usuarios_delete`: Registra eliminaciones

2. **Grupos:**
   - `trg_auditoria_grupos_insert`: Registra nuevos grupos
   - `trg_auditoria_grupos_update`: Registra cambios en grupos
   - `trg_auditoria_grupos_delete`: Registra eliminaciones

3. **Actividades:**
   - `trg_auditoria_actividades_insert`: Registra nuevas actividades
   - `trg_auditoria_actividades_update`: Registra cambios
   - `trg_auditoria_actividades_delete`: Registra eliminaciones

### Triggers de Negocio

1. **Ranking:**
   - `trg_actualizar_ranking_insert`: Actualiza automáticamente el ranking cuando se completa una actividad
   - `trg_bitacora_ranking_update`: Registra cambios en el ranking

2. **Notificaciones:**
   - `trg_notificar_nueva_actividad`: Crea notificaciones para miembros cuando se asigna una actividad
   - `trg_bitacora_notificacion_leida`: Registra cuando se leen notificaciones

## Vistas Útiles

### v_ranking_completo
Combina información de ranking, usuarios y grupos para mostrar un ranking completo.

**Columnas:**
- id, usuario_id, usuario_nombre, usuario_email
- grupo_id, grupo_nombre
- puntos_totales, actividades_completadas
- racha_actual, mejor_racha, ultima_actualizacion

### v_actividades_pendientes
Muestra todas las actividades pendientes por usuario y grupo.

**Columnas:**
- actividad_id, actividad_nombre, descripcion
- fecha_actividad, puntos_base
- grupo_id, grupo_nombre, usuario_id

### v_auditoria_resumen
Proporciona un resumen de todas las operaciones de auditoría.

**Columnas:**
- tabla, operacion, total, fecha

## Índices

Se han creado índices en los siguientes campos para optimizar consultas:

- Búsquedas de usuarios por email y rol
- Búsquedas de grupos por entrenador
- Relaciones de grupos_miembros
- Actividades por grupo y fecha
- Progreso por actividad y usuario
- Ranking por grupo y puntos
- Eventos por usuario y fecha
- Notificaciones por usuario y estado
- Auditoría por fecha, tabla y usuario

## Uso en Flutter

### Inicialización

```dart
import 'package:dev/database/database_helper.dart';

// Obtener instancia del helper
final dbHelper = DatabaseHelper();

// La base de datos se inicializa automáticamente en el primer acceso
final db = await dbHelper.database;
```

### Ejemplos de Uso

#### Crear un usuario

```dart
await dbHelper.insertUsuario({
  'id': 'user_123',
  'nombre': 'Juan Pérez',
  'email': 'juan@example.com',
  'password_hash': 'hash_aqui',
  'rol': 'atleta',
});
```

#### Obtener ranking de un grupo

```dart
List<Map<String, dynamic>> ranking = 
  await dbHelper.getRankingCompleto('grupo_123');
```

#### Registrar progreso de actividad

```dart
await dbHelper.registrarProgreso(
  actividadId: 'act_123',
  usuarioId: 'user_123',
  puntosObtenidos: 10,
  calificacion: 9.5,
);
```

#### Consultar auditoría

```dart
List<Map<String, dynamic>> auditoria = 
  await dbHelper.getAuditoriaUsuarios(usuarioId: 'user_123');
```

## Consideraciones de Seguridad

1. **Contraseñas**: Nunca almacenar contraseñas en texto plano, usar `password_hash`
2. **Foreign Keys**: Habilitadas para mantener integridad referencial
3. **Auditoría**: Todos los cambios importantes se registran automáticamente
4. **Validación**: Usar constraints de CHECK para validar datos
5. **Transacciones**: Usar el método `transaction()` para operaciones complejas

## Mantenimiento

### Actualización de Esquema

Para actualizar el esquema en futuras versiones, modificar el método `_onUpgrade` en `database_helper.dart`:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE usuarios ADD COLUMN nueva_columna TEXT');
  }
}
```

### Backup

Para realizar backup de la base de datos:

```dart
// Obtener ruta de la base de datos
String path = join(await getDatabasesPath(), 'lingo_gym.db');

// Copiar archivo a ubicación segura
File dbFile = File(path);
await dbFile.copy('/ruta/destino/backup.db');
```

### Limpiar datos (solo para desarrollo)

```dart
await dbHelper.deleteDatabase();
```

## Licencia

Este código es parte del proyecto Lingo Gym.
