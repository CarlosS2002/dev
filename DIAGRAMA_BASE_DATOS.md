# Diagrama Entidad-Relación - Base de Datos Lingo Gym

## Esquema Visual de Tablas

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BASE DE DATOS LINGO GYM                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│    USUARIOS      │         │     GRUPOS       │         │   ACTIVIDADES    │
├──────────────────┤         ├──────────────────┤         ├──────────────────┤
│ • id (PK)        │───┐     │ • id (PK)        │───┐     │ • id (PK)        │
│ • nombre         │   │     │ • nombre         │   │     │ • nombre         │
│ • email (UNIQUE) │   │     │ • descripcion    │   │     │ • descripcion    │
│ • password_hash  │   │     │ • entrenador_id  │───┘     │ • grupo_id (FK)  │───┐
│ • rol            │   │     │   (FK)           │         │ • fecha          │   │
│ • fecha_registro │   │     │ • fecha_creacion │         │ • puntos_base    │   │
│ • ultimo_acceso  │   │     │ • activo         │         │ • creado_por(FK) │───┤
│ • activo         │   │     │ • max_miembros   │         │ • tipo_actividad │   │
│ • foto_perfil    │   │     └──────────────────┘         │ • activo         │   │
│ • idioma_pref    │   │              │                   └──────────────────┘   │
└──────────────────┘   │              │                            │             │
         │             │              │                            │             │
         │             │              │                            │             │
         │             │     ┌────────▼──────────┐                │             │
         │             │     │ GRUPOS_MIEMBROS   │                │             │
         │             │     ├───────────────────┤                │             │
         │             └────▶│ • id (PK)         │                │             │
         │                   │ • grupo_id (FK)   │◀───────────────┘             │
         │                   │ • usuario_id (FK) │                              │
         └──────────────────▶│ • fecha_ingreso   │                              │
                             │ • estado          │                              │
                             └───────────────────┘                              │
                                                                                 │
                                      │                                          │
                                      │                                          │
                        ┌─────────────▼──────────────┐                          │
                        │  PROGRESO_ACTIVIDADES      │                          │
                        ├────────────────────────────┤                          │
                        │ • id (PK)                  │                          │
                        │ • actividad_id (FK)        │◀─────────────────────────┘
                        │ • usuario_id (FK)          │◀─────────────────────────┐
                        │ • fecha_completado         │                          │
                        │ • puntos_obtenidos         │                          │
                        │ • calificacion             │                          │
                        │ • comentario               │                          │
                        └────────────────────────────┘                          │
                                      │                                          │
                                      │ (trigger actualiza ranking)              │
                                      ▼                                          │
                        ┌────────────────────────────┐                          │
                        │      RANKING               │                          │
                        ├────────────────────────────┤                          │
                        │ • id (PK)                  │                          │
                        │ • usuario_id (FK)          │◀─────────────────────────┤
                        │ • grupo_id (FK)            │◀─────────────┐           │
                        │ • puntos_totales           │              │           │
                        │ • actividades_completadas  │              │           │
                        │ • racha_actual             │              │           │
                        │ • mejor_racha              │              │           │
                        │ • ultima_actualizacion     │              │           │
                        └────────────────────────────┘              │           │
                                                                    │           │
┌──────────────────┐                                ┌───────────────┴─────┐   │
│ NOTIFICACIONES   │                                │ EVENTOS_CALENDARIO  │   │
├──────────────────┤                                ├─────────────────────┤   │
│ • id (PK)        │                                │ • id (PK)           │   │
│ • usuario_id(FK) │◀───────────────────────────────│ • titulo            │   │
│ • titulo         │                                │ • descripcion       │   │
│ • mensaje        │                                │ • fecha_inicio      │   │
│ • tipo           │                                │ • fecha_fin         │   │
│ • leida          │                                │ • usuario_id (FK)   │───┘
│ • fecha_creacion │                                │ • grupo_id (FK)     │───┐
│ • fecha_lectura  │                                │ • tipo_evento       │   │
│ • datos_extras   │                                │ • ubicacion         │   │
└──────────────────┘                                └─────────────────────┘   │
         ▲                                                                     │
         │ (trigger notifica)                                                  │
         └─────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                          TABLAS DE AUDITORÍA Y BITÁCORA
═══════════════════════════════════════════════════════════════════════════════

┌──────────────────────────────────────────────────────────────────────────────┐
│                        BITACORA_SISTEMA (General)                             │
├──────────────────────────────────────────────────────────────────────────────┤
│ • id (PK)                                                                     │
│ • tabla_afectada         ← Registra TODAS las operaciones                    │
│ • operacion (INSERT/UPDATE/DELETE)                                           │
│ • registro_id                                                                 │
│ • usuario_id (FK)                                                             │
│ • fecha_operacion                                                             │
│ • ip_address                                                                  │
│ • user_agent                                                                  │
│ • detalles (JSON)                                                             │
└──────────────────────────────────────────────────────────────────────────────┘
                                      ▲
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
      ┌─────────────▼──────┐  ┌──────▼────────┐  ┌────▼──────────────┐
      │ AUDITORIA_USUARIOS │  │ AUDITORIA_    │  │ AUDITORIA_        │
      ├────────────────────┤  │ GRUPOS        │  │ ACTIVIDADES       │
      │ • id (PK)          │  ├───────────────┤  ├───────────────────┤
      │ • usuario_id       │  │ • id (PK)     │  │ • id (PK)         │
      │ • operacion        │  │ • grupo_id    │  │ • actividad_id    │
      │ • campo_modificado │  │ • operacion   │  │ • operacion       │
      │ • valor_anterior   │  │ • campo_modif │  │ • campo_modificado│
      │ • valor_nuevo      │  │ • valor_ant   │  │ • valor_anterior  │
      │ • fecha_cambio     │  │ • valor_nuevo │  │ • valor_nuevo     │
      │ • modificado_por   │  │ • fecha_cambio│  │ • fecha_cambio    │
      │ • razon_cambio     │  │ • modif_por   │  │ • modificado_por  │
      └────────────────────┘  │ • razon       │  │ • razon_cambio    │
                              └───────────────┘  └───────────────────┘

┌────────────────────────────────────────────────────────────────────────────┐
│                           AUDITORIA_ACCESOS                                 │
├────────────────────────────────────────────────────────────────────────────┤
│ • id (PK)                                                                   │
│ • usuario_id (FK)                                                           │
│ • tipo_acceso (login/logout/intento_fallido)                               │
│ • fecha_acceso                                                              │
│ • ip_address                                                                │
│ • dispositivo                                                               │
│ • navegador                                                                 │
│ • exitoso (1/0)                                                             │
│ • motivo_fallo                                                              │
└────────────────────────────────────────────────────────────────────────────┘
```

## Flujo de Triggers

```
═══════════════════════════════════════════════════════════════════════════════
                              FLUJO DE TRIGGERS
═══════════════════════════════════════════════════════════════════════════════

1. USUARIO SE REGISTRA
   ┌──────────────┐
   │ INSERT INTO  │
   │   usuarios   │
   └──────┬───────┘
          │
          ▼
   ┌─────────────────────────────────┐
   │ TRIGGER: auditoria_usuarios_ins │
   ├─────────────────────────────────┤
   │ • Crea registro en              │
   │   auditoria_usuarios            │
   │ • Crea registro en              │
   │   bitacora_sistema              │
   └─────────────────────────────────┘


2. SE CREA UNA ACTIVIDAD
   ┌──────────────┐
   │ INSERT INTO  │
   │ actividades  │
   └──────┬───────┘
          │
          ├──────────────────────────────┐
          │                              │
          ▼                              ▼
   ┌─────────────────┐         ┌──────────────────────┐
   │ TRIGGER:        │         │ TRIGGER:             │
   │ auditoria_      │         │ notificar_nueva_     │
   │ actividades_ins │         │ actividad            │
   ├─────────────────┤         ├──────────────────────┤
   │ • Registra en   │         │ • INSERT INTO        │
   │   auditoria     │         │   notificaciones     │
   │ • Registra en   │         │   para TODOS los     │
   │   bitácora      │         │   miembros activos   │
   └─────────────────┘         │   del grupo          │
                               └──────────────────────┘


3. USUARIO COMPLETA UNA ACTIVIDAD
   ┌──────────────┐
   │ INSERT INTO  │
   │ progreso_    │
   │ actividades  │
   └──────┬───────┘
          │
          ▼
   ┌─────────────────────────────────┐
   │ TRIGGER: actualizar_ranking_ins │
   ├─────────────────────────────────┤
   │ • Busca el grupo de la actividad│
   │ • UPSERT en tabla ranking:      │
   │   - Si existe: suma puntos      │
   │   - Si no existe: crea registro │
   │ • Incrementa contador de        │
   │   actividades completadas       │
   └─────────────┬───────────────────┘
                 │
                 ▼
   ┌─────────────────────────────────┐
   │ TRIGGER: bitacora_ranking_upd   │
   ├─────────────────────────────────┤
   │ • Registra cambio en bitácora   │
   │ • Incluye puntos antes/después  │
   └─────────────────────────────────┘


4. USUARIO LEE UNA NOTIFICACIÓN
   ┌──────────────┐
   │ UPDATE       │
   │ notificacion │
   │ SET leida=1  │
   └──────┬───────┘
          │
          ▼
   ┌─────────────────────────────────┐
   │ TRIGGER: bitacora_notif_leida   │
   ├─────────────────────────────────┤
   │ • Solo si cambió de 0 a 1       │
   │ • Registra en bitácora_sistema  │
   └─────────────────────────────────┘


5. SE ACTUALIZA UN USUARIO
   ┌──────────────┐
   │ UPDATE       │
   │ usuarios     │
   └──────┬───────┘
          │
          ▼
   ┌─────────────────────────────────┐
   │ TRIGGER: auditoria_usuarios_upd │
   ├─────────────────────────────────┤
   │ • Detecta QUÉ campos cambiaron  │
   │ • Crea registro individual por  │
   │   cada campo modificado         │
   │ • Guarda valor anterior y nuevo │
   │ • Registra en bitácora general  │
   └─────────────────────────────────┘
```

## Vistas Simplificadas

```
═══════════════════════════════════════════════════════════════════════════════
                                    VISTAS
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│                         v_ranking_completo                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  Combina: ranking + usuarios + grupos                                        │
│                                                                               │
│  SELECT:                                                                      │
│    • usuario_nombre, usuario_email                                           │
│    • grupo_nombre                                                            │
│    • puntos_totales, actividades_completadas                                 │
│    • racha_actual, mejor_racha                                               │
│                                                                               │
│  ORDER BY: puntos_totales DESC                                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                      v_actividades_pendientes                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  Combina: actividades + grupos + grupos_miembros                             │
│  LEFT JOIN: progreso_actividades (para detectar pendientes)                  │
│                                                                               │
│  Muestra solo actividades:                                                   │
│    • Sin progreso del usuario (pendientes)                                   │
│    • Activas                                                                 │
│    • Del grupo donde el usuario es miembro activo                            │
│    • Con fecha >= hoy                                                        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        v_auditoria_resumen                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  UNION de todas las tablas de auditoría                                      │
│                                                                               │
│  Agrupa por:                                                                 │
│    • tabla (usuarios/grupos/actividades)                                     │
│    • operacion (INSERT/UPDATE/DELETE)                                        │
│    • fecha (solo la fecha, sin hora)                                         │
│                                                                               │
│  Retorna: Conteo total de operaciones                                        │
│  ORDER BY: fecha DESC                                                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Índices y Optimización

```
═══════════════════════════════════════════════════════════════════════════════
                              ESTRATEGIA DE ÍNDICES
═══════════════════════════════════════════════════════════════════════════════

BÚSQUEDAS PRINCIPALES:
┌────────────────────────────────────┬──────────────────────────────────────┐
│ Consulta Común                     │ Índice Utilizado                     │
├────────────────────────────────────┼──────────────────────────────────────┤
│ Login (email)                      │ idx_usuarios_email                   │
│ Filtrar por rol                    │ idx_usuarios_rol                     │
│ Grupos de un entrenador            │ idx_grupos_entrenador                │
│ Miembros de un grupo               │ idx_grupos_miembros_grupo            │
│ Grupos de un usuario               │ idx_grupos_miembros_usuario          │
│ Actividades de un grupo            │ idx_actividades_grupo                │
│ Actividades por fecha              │ idx_actividades_fecha                │
│ Progreso de una actividad          │ idx_progreso_actividad               │
│ Progreso de un usuario             │ idx_progreso_usuario                 │
│ Ranking de un grupo                │ idx_ranking_grupo                    │
│ Top ranking (ordenado)             │ idx_ranking_puntos                   │
│ Eventos de un usuario              │ idx_eventos_usuario                  │
│ Eventos por fecha                  │ idx_eventos_fecha                    │
│ Notificaciones de usuario          │ idx_notificaciones_usuario           │
│ Notificaciones no leídas           │ idx_notificaciones_leida             │
└────────────────────────────────────┴──────────────────────────────────────┘

AUDITORÍA Y BITÁCORA:
┌────────────────────────────────────┬──────────────────────────────────────┐
│ Consulta de Auditoría              │ Índice Utilizado                     │
├────────────────────────────────────┼──────────────────────────────────────┤
│ Bitácora por tabla                 │ idx_bitacora_tabla                   │
│ Bitácora por fecha                 │ idx_bitacora_fecha                   │
│ Operaciones de un usuario          │ idx_bitacora_usuario                 │
│ Auditoría de un usuario            │ idx_auditoria_usuarios_id            │
│ Auditoría de un grupo              │ idx_auditoria_grupos_id              │
│ Auditoría de una actividad         │ idx_auditoria_actividades_id         │
│ Accesos de un usuario              │ idx_auditoria_accesos_usuario        │
│ Accesos por fecha                  │ idx_auditoria_accesos_fecha          │
└────────────────────────────────────┴──────────────────────────────────────┘
```

## Leyenda

```
═══════════════════════════════════════════════════════════════════════════════
                                  LEYENDA
═══════════════════════════════════════════════════════════════════════════════

SÍMBOLOS:
  • PK    = Primary Key (Clave Primaria)
  • FK    = Foreign Key (Clave Foránea)
  • ─── = Relación entre tablas
  • ◀── = Dirección de la relación
  • ▼    = Flujo de ejecución
  • │    = Conexión vertical
  • └── = Conexión final

OPERACIONES DE TRIGGER:
  INSERT  = Inserción de nuevo registro
  UPDATE  = Actualización de registro existente
  DELETE  = Eliminación de registro
  UPSERT  = Update o Insert (ON CONFLICT DO UPDATE)

TIPOS DE RELACIONES:
  1:N   = Uno a muchos (ej: un grupo tiene muchos miembros)
  N:M   = Muchos a muchos (ej: usuarios y grupos via grupos_miembros)
  1:1   = Uno a uno (ej: usuario y su perfil)

CONVENCIONES:
  • Las tablas principales están en mayúsculas
  • Las claves foráneas terminan con _id
  • Los triggers comienzan con trg_
  • Las vistas comienzan con v_
  • Los índices comienzan con idx_
```

---

**Última actualización:** 19 de octubre de 2025
**Versión del esquema:** 1.0
