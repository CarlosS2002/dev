-- ============================================
-- LINGO GYM - SQLite Database Schema
-- Base de datos para la aplicación Lingo Gym
-- ============================================

-- ============================================
-- TABLAS PRINCIPALES
-- ============================================

-- Tabla de Usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    rol TEXT NOT NULL CHECK(rol IN ('atleta', 'entrenador')),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso DATETIME,
    activo INTEGER DEFAULT 1,
    foto_perfil TEXT,
    idioma_preferido TEXT DEFAULT 'es',
    CONSTRAINT chk_email_format CHECK (email LIKE '%_@__%.__%')
);

-- Tabla de Grupos
CREATE TABLE IF NOT EXISTS grupos (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    entrenador_id TEXT NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    activo INTEGER DEFAULT 1,
    max_miembros INTEGER DEFAULT 50,
    FOREIGN KEY (entrenador_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Tabla de Miembros de Grupos (relación muchos a muchos)
CREATE TABLE IF NOT EXISTS grupos_miembros (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    grupo_id TEXT NOT NULL,
    usuario_id TEXT NOT NULL,
    fecha_ingreso DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado TEXT DEFAULT 'activo' CHECK(estado IN ('activo', 'inactivo', 'bloqueado')),
    FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    UNIQUE(grupo_id, usuario_id)
);

-- Tabla de Actividades
CREATE TABLE IF NOT EXISTS actividades (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    grupo_id TEXT NOT NULL,
    fecha_actividad DATETIME NOT NULL,
    puntos_base INTEGER DEFAULT 10,
    creado_por TEXT NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    activo INTEGER DEFAULT 1,
    tipo_actividad TEXT DEFAULT 'ejercicio' CHECK(tipo_actividad IN ('ejercicio', 'tarea', 'examen', 'practica')),
    FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE,
    FOREIGN KEY (creado_por) REFERENCES usuarios(id)
);

-- Tabla de Progreso de Actividades
CREATE TABLE IF NOT EXISTS progreso_actividades (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    actividad_id TEXT NOT NULL,
    usuario_id TEXT NOT NULL,
    fecha_completado DATETIME DEFAULT CURRENT_TIMESTAMP,
    puntos_obtenidos INTEGER NOT NULL,
    calificacion REAL,
    comentario TEXT,
    FOREIGN KEY (actividad_id) REFERENCES actividades(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    UNIQUE(actividad_id, usuario_id)
);

-- Tabla de Ranking
CREATE TABLE IF NOT EXISTS ranking (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id TEXT NOT NULL,
    grupo_id TEXT NOT NULL,
    puntos_totales INTEGER DEFAULT 0,
    actividades_completadas INTEGER DEFAULT 0,
    racha_actual INTEGER DEFAULT 0,
    mejor_racha INTEGER DEFAULT 0,
    ultima_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE,
    UNIQUE(usuario_id, grupo_id)
);

-- Tabla de Eventos de Calendario
CREATE TABLE IF NOT EXISTS eventos_calendario (
    id TEXT PRIMARY KEY,
    titulo TEXT NOT NULL,
    descripcion TEXT,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NOT NULL,
    usuario_id TEXT NOT NULL,
    grupo_id TEXT,
    tipo_evento TEXT DEFAULT 'personal' CHECK(tipo_evento IN ('personal', 'grupal', 'recordatorio')),
    ubicacion TEXT,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE SET NULL
);

-- Tabla de Notificaciones
CREATE TABLE IF NOT EXISTS notificaciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id TEXT NOT NULL,
    titulo TEXT NOT NULL,
    mensaje TEXT NOT NULL,
    tipo TEXT DEFAULT 'info' CHECK(tipo IN ('info', 'alerta', 'exito', 'error')),
    leida INTEGER DEFAULT 0,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_lectura DATETIME,
    datos_adicionales TEXT, -- JSON para datos extra
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- ============================================
-- TABLAS DE AUDITORÍA Y BITÁCORA
-- ============================================

-- Tabla de Bitácora de Actividades del Sistema
CREATE TABLE IF NOT EXISTS bitacora_sistema (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tabla_afectada TEXT NOT NULL,
    operacion TEXT NOT NULL CHECK(operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    registro_id TEXT NOT NULL,
    usuario_id TEXT,
    fecha_operacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    user_agent TEXT,
    detalles TEXT -- JSON con detalles adicionales
);

-- Tabla de Auditoría de Usuarios
CREATE TABLE IF NOT EXISTS auditoria_usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id TEXT NOT NULL,
    operacion TEXT NOT NULL CHECK(operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    campo_modificado TEXT,
    valor_anterior TEXT,
    valor_nuevo TEXT,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    modificado_por TEXT,
    razon_cambio TEXT
);

-- Tabla de Auditoría de Grupos
CREATE TABLE IF NOT EXISTS auditoria_grupos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    grupo_id TEXT NOT NULL,
    operacion TEXT NOT NULL CHECK(operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    campo_modificado TEXT,
    valor_anterior TEXT,
    valor_nuevo TEXT,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    modificado_por TEXT,
    razon_cambio TEXT
);

-- Tabla de Auditoría de Actividades
CREATE TABLE IF NOT EXISTS auditoria_actividades (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    actividad_id TEXT NOT NULL,
    operacion TEXT NOT NULL CHECK(operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    campo_modificado TEXT,
    valor_anterior TEXT,
    valor_nuevo TEXT,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    modificado_por TEXT,
    razon_cambio TEXT
);

-- Tabla de Auditoría de Accesos
CREATE TABLE IF NOT EXISTS auditoria_accesos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id TEXT NOT NULL,
    tipo_acceso TEXT NOT NULL CHECK(tipo_acceso IN ('login', 'logout', 'intento_fallido')),
    fecha_acceso DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    dispositivo TEXT,
    navegador TEXT,
    exitoso INTEGER DEFAULT 1,
    motivo_fallo TEXT
);

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

-- Índices para búsquedas frecuentes
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol);
CREATE INDEX IF NOT EXISTS idx_grupos_entrenador ON grupos(entrenador_id);
CREATE INDEX IF NOT EXISTS idx_grupos_miembros_grupo ON grupos_miembros(grupo_id);
CREATE INDEX IF NOT EXISTS idx_grupos_miembros_usuario ON grupos_miembros(usuario_id);
CREATE INDEX IF NOT EXISTS idx_actividades_grupo ON actividades(grupo_id);
CREATE INDEX IF NOT EXISTS idx_actividades_fecha ON actividades(fecha_actividad);
CREATE INDEX IF NOT EXISTS idx_progreso_actividad ON progreso_actividades(actividad_id);
CREATE INDEX IF NOT EXISTS idx_progreso_usuario ON progreso_actividades(usuario_id);
CREATE INDEX IF NOT EXISTS idx_ranking_grupo ON ranking(grupo_id);
CREATE INDEX IF NOT EXISTS idx_ranking_puntos ON ranking(puntos_totales DESC);
CREATE INDEX IF NOT EXISTS idx_eventos_usuario ON eventos_calendario(usuario_id);
CREATE INDEX IF NOT EXISTS idx_eventos_fecha ON eventos_calendario(fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario ON notificaciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notificaciones_leida ON notificaciones(leida);

-- Índices para auditoría y bitácora
CREATE INDEX IF NOT EXISTS idx_bitacora_tabla ON bitacora_sistema(tabla_afectada);
CREATE INDEX IF NOT EXISTS idx_bitacora_fecha ON bitacora_sistema(fecha_operacion);
CREATE INDEX IF NOT EXISTS idx_bitacora_usuario ON bitacora_sistema(usuario_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_usuarios_id ON auditoria_usuarios(usuario_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_grupos_id ON auditoria_grupos(grupo_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_actividades_id ON auditoria_actividades(actividad_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_accesos_usuario ON auditoria_accesos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_accesos_fecha ON auditoria_accesos(fecha_acceso);

-- ============================================
-- TRIGGERS DE AUDITORÍA - USUARIOS
-- ============================================

-- Trigger para auditar inserciones de usuarios
CREATE TRIGGER IF NOT EXISTS trg_auditoria_usuarios_insert
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_usuarios (usuario_id, operacion, campo_modificado, valor_nuevo, fecha_cambio)
    VALUES (NEW.id, 'INSERT', 'registro_completo', 
            json_object('nombre', NEW.nombre, 'email', NEW.email, 'rol', NEW.rol),
            CURRENT_TIMESTAMP);
    
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('usuarios', 'INSERT', NEW.id, NEW.id, CURRENT_TIMESTAMP);
END;

-- Trigger para auditar actualizaciones de usuarios
CREATE TRIGGER IF NOT EXISTS trg_auditoria_usuarios_update
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
    -- Auditar cambio de nombre
    INSERT INTO auditoria_usuarios (usuario_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio)
    SELECT NEW.id, 'UPDATE', 'nombre', OLD.nombre, NEW.nombre, CURRENT_TIMESTAMP
    WHERE OLD.nombre != NEW.nombre;
    
    -- Auditar cambio de email
    INSERT INTO auditoria_usuarios (usuario_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio)
    SELECT NEW.id, 'UPDATE', 'email', OLD.email, NEW.email, CURRENT_TIMESTAMP
    WHERE OLD.email != NEW.email;
    
    -- Auditar cambio de rol
    INSERT INTO auditoria_usuarios (usuario_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio)
    SELECT NEW.id, 'UPDATE', 'rol', OLD.rol, NEW.rol, CURRENT_TIMESTAMP
    WHERE OLD.rol != NEW.rol;
    
    -- Auditar cambio de estado activo
    INSERT INTO auditoria_usuarios (usuario_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio)
    SELECT NEW.id, 'UPDATE', 'activo', OLD.activo, NEW.activo, CURRENT_TIMESTAMP
    WHERE OLD.activo != NEW.activo;
    
    -- Bitácora general
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('usuarios', 'UPDATE', NEW.id, NEW.id, CURRENT_TIMESTAMP);
END;

-- Trigger para auditar eliminaciones de usuarios
CREATE TRIGGER IF NOT EXISTS trg_auditoria_usuarios_delete
BEFORE DELETE ON usuarios
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_usuarios (usuario_id, operacion, campo_modificado, valor_anterior, fecha_cambio)
    VALUES (OLD.id, 'DELETE', 'registro_completo',
            json_object('nombre', OLD.nombre, 'email', OLD.email, 'rol', OLD.rol),
            CURRENT_TIMESTAMP);
    
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('usuarios', 'DELETE', OLD.id, OLD.id, CURRENT_TIMESTAMP);
END;

-- ============================================
-- TRIGGERS DE AUDITORÍA - GRUPOS
-- ============================================

-- Trigger para auditar inserciones de grupos
CREATE TRIGGER IF NOT EXISTS trg_auditoria_grupos_insert
AFTER INSERT ON grupos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_grupos (grupo_id, operacion, campo_modificado, valor_nuevo, fecha_cambio, modificado_por)
    VALUES (NEW.id, 'INSERT', 'registro_completo',
            json_object('nombre', NEW.nombre, 'descripcion', NEW.descripcion),
            CURRENT_TIMESTAMP, NEW.entrenador_id);
    
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('grupos', 'INSERT', NEW.id, NEW.entrenador_id, CURRENT_TIMESTAMP);
END;

-- Trigger para auditar actualizaciones de grupos
CREATE TRIGGER IF NOT EXISTS trg_auditoria_grupos_update
AFTER UPDATE ON grupos
FOR EACH ROW
BEGIN
    -- Auditar cambio de nombre
    INSERT INTO auditoria_grupos (grupo_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio, modificado_por)
    SELECT NEW.id, 'UPDATE', 'nombre', OLD.nombre, NEW.nombre, CURRENT_TIMESTAMP, NEW.entrenador_id
    WHERE OLD.nombre != NEW.nombre;
    
    -- Auditar cambio de descripción
    INSERT INTO auditoria_grupos (grupo_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio, modificado_por)
    SELECT NEW.id, 'UPDATE', 'descripcion', OLD.descripcion, NEW.descripcion, CURRENT_TIMESTAMP, NEW.entrenador_id
    WHERE OLD.descripcion != NEW.descripcion;
    
    -- Auditar cambio de estado activo
    INSERT INTO auditoria_grupos (grupo_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio, modificado_por)
    SELECT NEW.id, 'UPDATE', 'activo', OLD.activo, NEW.activo, CURRENT_TIMESTAMP, NEW.entrenador_id
    WHERE OLD.activo != NEW.activo;
    
    -- Bitácora general
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('grupos', 'UPDATE', NEW.id, NEW.entrenador_id, CURRENT_TIMESTAMP);
END;

-- Trigger para auditar eliminaciones de grupos
CREATE TRIGGER IF NOT EXISTS trg_auditoria_grupos_delete
BEFORE DELETE ON grupos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_grupos (grupo_id, operacion, campo_modificado, valor_anterior, fecha_cambio, modificado_por)
    VALUES (OLD.id, 'DELETE', 'registro_completo',
            json_object('nombre', OLD.nombre, 'descripcion', OLD.descripcion),
            CURRENT_TIMESTAMP, OLD.entrenador_id);
    
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('grupos', 'DELETE', OLD.id, OLD.entrenador_id, CURRENT_TIMESTAMP);
END;

-- ============================================
-- TRIGGERS DE AUDITORÍA - ACTIVIDADES
-- ============================================

-- Trigger para auditar inserciones de actividades
CREATE TRIGGER IF NOT EXISTS trg_auditoria_actividades_insert
AFTER INSERT ON actividades
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_actividades (actividad_id, operacion, campo_modificado, valor_nuevo, fecha_cambio, modificado_por)
    VALUES (NEW.id, 'INSERT', 'registro_completo',
            json_object('nombre', NEW.nombre, 'puntos_base', NEW.puntos_base),
            CURRENT_TIMESTAMP, NEW.creado_por);
    
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('actividades', 'INSERT', NEW.id, NEW.creado_por, CURRENT_TIMESTAMP);
END;

-- Trigger para auditar actualizaciones de actividades
CREATE TRIGGER IF NOT EXISTS trg_auditoria_actividades_update
AFTER UPDATE ON actividades
FOR EACH ROW
BEGIN
    -- Auditar cambio de nombre
    INSERT INTO auditoria_actividades (actividad_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio, modificado_por)
    SELECT NEW.id, 'UPDATE', 'nombre', OLD.nombre, NEW.nombre, CURRENT_TIMESTAMP, NEW.creado_por
    WHERE OLD.nombre != NEW.nombre;
    
    -- Auditar cambio de puntos
    INSERT INTO auditoria_actividades (actividad_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio, modificado_por)
    SELECT NEW.id, 'UPDATE', 'puntos_base', OLD.puntos_base, NEW.puntos_base, CURRENT_TIMESTAMP, NEW.creado_por
    WHERE OLD.puntos_base != NEW.puntos_base;
    
    -- Auditar cambio de estado activo
    INSERT INTO auditoria_actividades (actividad_id, operacion, campo_modificado, valor_anterior, valor_nuevo, fecha_cambio, modificado_por)
    SELECT NEW.id, 'UPDATE', 'activo', OLD.activo, NEW.activo, CURRENT_TIMESTAMP, NEW.creado_por
    WHERE OLD.activo != NEW.activo;
    
    -- Bitácora general
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('actividades', 'UPDATE', NEW.id, NEW.creado_por, CURRENT_TIMESTAMP);
END;

-- Trigger para auditar eliminaciones de actividades
CREATE TRIGGER IF NOT EXISTS trg_auditoria_actividades_delete
BEFORE DELETE ON actividades
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_actividades (actividad_id, operacion, campo_modificado, valor_anterior, fecha_cambio, modificado_por)
    VALUES (OLD.id, 'DELETE', 'registro_completo',
            json_object('nombre', OLD.nombre, 'puntos_base', OLD.puntos_base),
            CURRENT_TIMESTAMP, OLD.creado_por);
    
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('actividades', 'DELETE', OLD.id, OLD.creado_por, CURRENT_TIMESTAMP);
END;

-- ============================================
-- TRIGGERS DE NEGOCIO - ACTUALIZACIÓN DE RANKING
-- ============================================

-- Trigger para actualizar ranking cuando se completa una actividad
CREATE TRIGGER IF NOT EXISTS trg_actualizar_ranking_insert
AFTER INSERT ON progreso_actividades
FOR EACH ROW
BEGIN
    -- Actualizar o insertar en ranking
    INSERT INTO ranking (usuario_id, grupo_id, puntos_totales, actividades_completadas, ultima_actualizacion)
    SELECT 
        NEW.usuario_id, 
        a.grupo_id, 
        NEW.puntos_obtenidos, 
        1, 
        CURRENT_TIMESTAMP
    FROM actividades a
    WHERE a.id = NEW.actividad_id
    ON CONFLICT(usuario_id, grupo_id) DO UPDATE SET
        puntos_totales = puntos_totales + NEW.puntos_obtenidos,
        actividades_completadas = actividades_completadas + 1,
        ultima_actualizacion = CURRENT_TIMESTAMP;
END;

-- Trigger para registrar en bitácora cuando cambia el ranking
CREATE TRIGGER IF NOT EXISTS trg_bitacora_ranking_update
AFTER UPDATE ON ranking
FOR EACH ROW
BEGIN
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion, detalles)
    VALUES ('ranking', 'UPDATE', NEW.id, NEW.usuario_id, CURRENT_TIMESTAMP,
            json_object('puntos_anteriores', OLD.puntos_totales, 'puntos_nuevos', NEW.puntos_totales));
END;

-- ============================================
-- TRIGGERS DE NOTIFICACIONES
-- ============================================

-- Trigger para crear notificación cuando se asigna una nueva actividad
CREATE TRIGGER IF NOT EXISTS trg_notificar_nueva_actividad
AFTER INSERT ON actividades
FOR EACH ROW
BEGIN
    -- Notificar a todos los miembros del grupo
    INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo, fecha_creacion)
    SELECT 
        gm.usuario_id,
        'Nueva Actividad',
        'Se ha creado la actividad: ' || NEW.nombre,
        'info',
        CURRENT_TIMESTAMP
    FROM grupos_miembros gm
    WHERE gm.grupo_id = NEW.grupo_id AND gm.estado = 'activo';
END;

-- Trigger para marcar notificación como leída en bitácora
CREATE TRIGGER IF NOT EXISTS trg_bitacora_notificacion_leida
AFTER UPDATE OF leida ON notificaciones
FOR EACH ROW
WHEN NEW.leida = 1 AND OLD.leida = 0
BEGIN
    INSERT INTO bitacora_sistema (tabla_afectada, operacion, registro_id, usuario_id, fecha_operacion)
    VALUES ('notificaciones', 'UPDATE', NEW.id, NEW.usuario_id, CURRENT_TIMESTAMP);
END;

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista de ranking completo con información de usuario
CREATE VIEW IF NOT EXISTS v_ranking_completo AS
SELECT 
    r.id,
    r.usuario_id,
    u.nombre as usuario_nombre,
    u.email as usuario_email,
    r.grupo_id,
    g.nombre as grupo_nombre,
    r.puntos_totales,
    r.actividades_completadas,
    r.racha_actual,
    r.mejor_racha,
    r.ultima_actualizacion
FROM ranking r
INNER JOIN usuarios u ON r.usuario_id = u.id
INNER JOIN grupos g ON r.grupo_id = g.id
ORDER BY r.puntos_totales DESC;

-- Vista de actividades pendientes por usuario
CREATE VIEW IF NOT EXISTS v_actividades_pendientes AS
SELECT 
    a.id as actividad_id,
    a.nombre as actividad_nombre,
    a.descripcion,
    a.fecha_actividad,
    a.puntos_base,
    a.grupo_id,
    g.nombre as grupo_nombre,
    gm.usuario_id
FROM actividades a
INNER JOIN grupos g ON a.grupo_id = g.id
INNER JOIN grupos_miembros gm ON g.id = gm.grupo_id
LEFT JOIN progreso_actividades pa ON a.id = pa.actividad_id AND pa.usuario_id = gm.usuario_id
WHERE pa.id IS NULL 
    AND a.activo = 1 
    AND gm.estado = 'activo'
    AND a.fecha_actividad >= date('now');

-- Vista de resumen de auditoría
CREATE VIEW IF NOT EXISTS v_auditoria_resumen AS
SELECT 
    'usuarios' as tabla,
    operacion,
    COUNT(*) as total,
    DATE(fecha_cambio) as fecha
FROM auditoria_usuarios
GROUP BY tabla, operacion, DATE(fecha_cambio)
UNION ALL
SELECT 
    'grupos' as tabla,
    operacion,
    COUNT(*) as total,
    DATE(fecha_cambio) as fecha
FROM auditoria_grupos
GROUP BY tabla, operacion, DATE(fecha_cambio)
UNION ALL
SELECT 
    'actividades' as tabla,
    operacion,
    COUNT(*) as total,
    DATE(fecha_cambio) as fecha
FROM auditoria_actividades
GROUP BY tabla, operacion, DATE(fecha_cambio)
ORDER BY fecha DESC, tabla, operacion;
