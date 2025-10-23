import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// DatabaseHelper - Clase para gestionar la base de datos SQLite
/// 
/// Esta clase implementa el patrón Singleton para garantizar una única
/// instancia de la base de datos en toda la aplicación.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Nombre de la base de datos
  static const String _databaseName = 'lingo_gym.db';
  static const int _databaseVersion = 1;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configura la base de datos (habilita foreign keys)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Crea todas las tablas, índices, triggers y vistas
  Future<void> _onCreate(Database db, int version) async {
    // Leer el archivo SQL del esquema
    String schema = await rootBundle.loadString('lib/database/schema.sql');
    
    // Dividir por punto y coma y ejecutar cada sentencia
    List<String> statements = schema.split(';');
    
    for (String statement in statements) {
      String trimmed = statement.trim();
      if (trimmed.isNotEmpty && 
          !trimmed.startsWith('--') && 
          trimmed != '') {
        try {
          await db.execute(trimmed);
        } catch (e) {
          print('Error ejecutando statement: $trimmed');
          print('Error: $e');
        }
      }
    }
  }

  /// Maneja actualizaciones de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí se pueden agregar migraciones cuando sea necesario
    // Por ejemplo:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE usuarios ADD COLUMN nueva_columna TEXT');
    // }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    Database db = await database;
    await db.close();
    _database = null;
  }

  /// Elimina la base de datos (útil para testing)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // ============================================
  // MÉTODOS CRUD PARA USUARIOS
  // ============================================

  /// Inserta un nuevo usuario
  Future<int> insertUsuario(Map<String, dynamic> usuario) async {
    Database db = await database;
    try {
      await db.insert('usuarios', usuario, 
        conflictAlgorithm: ConflictAlgorithm.fail);
      return 1;
    } catch (e) {
      print('Error insertando usuario: $e');
      return 0;
    }
  }

  /// Obtiene un usuario por ID
  Future<Map<String, dynamic>?> getUsuarioById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Obtiene un usuario por email
  Future<Map<String, dynamic>?> getUsuarioByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Actualiza un usuario
  Future<int> updateUsuario(String id, Map<String, dynamic> usuario) async {
    Database db = await database;
    return await db.update(
      'usuarios',
      usuario,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un usuario
  Future<int> deleteUsuario(String id) async {
    Database db = await database;
    return await db.delete(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene todos los usuarios
  Future<List<Map<String, dynamic>>> getAllUsuarios() async {
    Database db = await database;
    return await db.query('usuarios', orderBy: 'nombre ASC');
  }

  /// Registra un acceso de usuario
  Future<int> registrarAcceso({
    required String usuarioId,
    required String tipoAcceso,
    String? ipAddress,
    String? dispositivo,
    String? navegador,
    bool exitoso = true,
    String? motivoFallo,
  }) async {
    Database db = await database;
    return await db.insert('auditoria_accesos', {
      'usuario_id': usuarioId,
      'tipo_acceso': tipoAcceso,
      'ip_address': ipAddress,
      'dispositivo': dispositivo,
      'navegador': navegador,
      'exitoso': exitoso ? 1 : 0,
      'motivo_fallo': motivoFallo,
    });
  }

  // ============================================
  // MÉTODOS CRUD PARA GRUPOS
  // ============================================

  /// Inserta un nuevo grupo
  Future<int> insertGrupo(Map<String, dynamic> grupo) async {
    Database db = await database;
    try {
      await db.insert('grupos', grupo);
      return 1;
    } catch (e) {
      print('Error insertando grupo: $e');
      return 0;
    }
  }

  /// Obtiene un grupo por ID
  Future<Map<String, dynamic>?> getGrupoById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'grupos',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Actualiza un grupo
  Future<int> updateGrupo(String id, Map<String, dynamic> grupo) async {
    Database db = await database;
    return await db.update(
      'grupos',
      grupo,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un grupo
  Future<int> deleteGrupo(String id) async {
    Database db = await database;
    return await db.delete(
      'grupos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene todos los grupos
  Future<List<Map<String, dynamic>>> getAllGrupos() async {
    Database db = await database;
    return await db.query('grupos', orderBy: 'fecha_creacion DESC');
  }

  /// Obtiene grupos de un entrenador
  Future<List<Map<String, dynamic>>> getGruposByEntrenador(
      String entrenadorId) async {
    Database db = await database;
    return await db.query(
      'grupos',
      where: 'entrenador_id = ?',
      whereArgs: [entrenadorId],
      orderBy: 'fecha_creacion DESC',
    );
  }

  /// Agrega un miembro a un grupo
  Future<int> addMiembroGrupo(String grupoId, String usuarioId) async {
    Database db = await database;
    try {
      return await db.insert('grupos_miembros', {
        'grupo_id': grupoId,
        'usuario_id': usuarioId,
      });
    } catch (e) {
      print('Error agregando miembro: $e');
      return 0;
    }
  }

  /// Elimina un miembro de un grupo
  Future<int> removeMiembroGrupo(String grupoId, String usuarioId) async {
    Database db = await database;
    return await db.delete(
      'grupos_miembros',
      where: 'grupo_id = ? AND usuario_id = ?',
      whereArgs: [grupoId, usuarioId],
    );
  }

  /// Obtiene miembros de un grupo
  Future<List<Map<String, dynamic>>> getMiembrosGrupo(String grupoId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT u.* FROM usuarios u
      INNER JOIN grupos_miembros gm ON u.id = gm.usuario_id
      WHERE gm.grupo_id = ? AND gm.estado = 'activo'
      ORDER BY u.nombre ASC
    ''', [grupoId]);
  }

  // ============================================
  // MÉTODOS CRUD PARA ACTIVIDADES
  // ============================================

  /// Inserta una nueva actividad
  Future<int> insertActividad(Map<String, dynamic> actividad) async {
    Database db = await database;
    try {
      await db.insert('actividades', actividad);
      return 1;
    } catch (e) {
      print('Error insertando actividad: $e');
      return 0;
    }
  }

  /// Obtiene una actividad por ID
  Future<Map<String, dynamic>?> getActividadById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'actividades',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Actualiza una actividad
  Future<int> updateActividad(String id, Map<String, dynamic> actividad) async {
    Database db = await database;
    return await db.update(
      'actividades',
      actividad,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina una actividad
  Future<int> deleteActividad(String id) async {
    Database db = await database;
    return await db.delete(
      'actividades',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene actividades de un grupo
  Future<List<Map<String, dynamic>>> getActividadesByGrupo(
      String grupoId) async {
    Database db = await database;
    return await db.query(
      'actividades',
      where: 'grupo_id = ? AND activo = 1',
      whereArgs: [grupoId],
      orderBy: 'fecha_actividad DESC',
    );
  }

  /// Registra progreso de una actividad
  Future<int> registrarProgreso({
    required String actividadId,
    required String usuarioId,
    required int puntosObtenidos,
    double? calificacion,
    String? comentario,
  }) async {
    Database db = await database;
    try {
      return await db.insert('progreso_actividades', {
        'actividad_id': actividadId,
        'usuario_id': usuarioId,
        'puntos_obtenidos': puntosObtenidos,
        'calificacion': calificacion,
        'comentario': comentario,
      });
    } catch (e) {
      print('Error registrando progreso: $e');
      return 0;
    }
  }

  /// Obtiene actividades pendientes de un usuario en un grupo
  Future<List<Map<String, dynamic>>> getActividadesPendientes(
      String usuarioId, String grupoId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT * FROM v_actividades_pendientes
      WHERE usuario_id = ? AND grupo_id = ?
      ORDER BY fecha_actividad ASC
    ''', [usuarioId, grupoId]);
  }

  // ============================================
  // MÉTODOS PARA RANKING
  // ============================================

  /// Obtiene el ranking de un grupo
  Future<List<Map<String, dynamic>>> getRankingGrupo(String grupoId) async {
    Database db = await database;
    return await db.query(
      'ranking',
      where: 'grupo_id = ?',
      whereArgs: [grupoId],
      orderBy: 'puntos_totales DESC, actividades_completadas DESC',
    );
  }

  /// Obtiene el ranking completo con información de usuarios
  Future<List<Map<String, dynamic>>> getRankingCompleto(String grupoId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT * FROM v_ranking_completo
      WHERE grupo_id = ?
      ORDER BY puntos_totales DESC
    ''', [grupoId]);
  }

  // ============================================
  // MÉTODOS PARA NOTIFICACIONES
  // ============================================

  /// Obtiene notificaciones de un usuario
  Future<List<Map<String, dynamic>>> getNotificacionesUsuario(
      String usuarioId, {bool soloNoLeidas = false}) async {
    Database db = await database;
    String where = 'usuario_id = ?';
    if (soloNoLeidas) {
      where += ' AND leida = 0';
    }
    return await db.query(
      'notificaciones',
      where: where,
      whereArgs: [usuarioId],
      orderBy: 'fecha_creacion DESC',
    );
  }

  /// Marca una notificación como leída
  Future<int> marcarNotificacionLeida(int notificacionId) async {
    Database db = await database;
    return await db.update(
      'notificaciones',
      {'leida': 1, 'fecha_lectura': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [notificacionId],
    );
  }

  /// Marca todas las notificaciones como leídas
  Future<int> marcarTodasNotificacionesLeidas(String usuarioId) async {
    Database db = await database;
    return await db.update(
      'notificaciones',
      {'leida': 1, 'fecha_lectura': DateTime.now().toIso8601String()},
      where: 'usuario_id = ? AND leida = 0',
      whereArgs: [usuarioId],
    );
  }

  // ============================================
  // MÉTODOS PARA EVENTOS DE CALENDARIO
  // ============================================

  /// Inserta un nuevo evento
  Future<int> insertEvento(Map<String, dynamic> evento) async {
    Database db = await database;
    try {
      await db.insert('eventos_calendario', evento);
      return 1;
    } catch (e) {
      print('Error insertando evento: $e');
      return 0;
    }
  }

  /// Obtiene eventos de un usuario
  Future<List<Map<String, dynamic>>> getEventosUsuario(
      String usuarioId, {DateTime? desde, DateTime? hasta}) async {
    Database db = await database;
    
    String where = 'usuario_id = ?';
    List<dynamic> whereArgs = [usuarioId];
    
    if (desde != null) {
      where += ' AND fecha_inicio >= ?';
      whereArgs.add(desde.toIso8601String());
    }
    if (hasta != null) {
      where += ' AND fecha_fin <= ?';
      whereArgs.add(hasta.toIso8601String());
    }
    
    return await db.query(
      'eventos_calendario',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'fecha_inicio ASC',
    );
  }

  /// Elimina un evento
  Future<int> deleteEvento(String id) async {
    Database db = await database;
    return await db.delete(
      'eventos_calendario',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================
  // MÉTODOS PARA AUDITORÍA Y BITÁCORA
  // ============================================

  /// Obtiene entradas de bitácora
  Future<List<Map<String, dynamic>>> getBitacoraSistema({
    String? tabla,
    String? operacion,
    DateTime? desde,
    DateTime? hasta,
    int limit = 100,
  }) async {
    Database db = await database;
    
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (tabla != null) {
      where += 'tabla_afectada = ?';
      whereArgs.add(tabla);
    }
    if (operacion != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'operacion = ?';
      whereArgs.add(operacion);
    }
    if (desde != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'fecha_operacion >= ?';
      whereArgs.add(desde.toIso8601String());
    }
    if (hasta != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'fecha_operacion <= ?';
      whereArgs.add(hasta.toIso8601String());
    }
    
    return await db.query(
      'bitacora_sistema',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'fecha_operacion DESC',
      limit: limit,
    );
  }

  /// Obtiene auditoría de usuarios
  Future<List<Map<String, dynamic>>> getAuditoriaUsuarios({
    String? usuarioId,
    String? operacion,
    int limit = 100,
  }) async {
    Database db = await database;
    
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (usuarioId != null) {
      where = 'usuario_id = ?';
      whereArgs.add(usuarioId);
    }
    if (operacion != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'operacion = ?';
      whereArgs.add(operacion);
    }
    
    return await db.query(
      'auditoria_usuarios',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'fecha_cambio DESC',
      limit: limit,
    );
  }

  /// Obtiene resumen de auditoría
  Future<List<Map<String, dynamic>>> getResumenAuditoria() async {
    Database db = await database;
    return await db.rawQuery('SELECT * FROM v_auditoria_resumen');
  }

  // ============================================
  // MÉTODOS DE UTILIDAD
  // ============================================

  /// Ejecuta una consulta SQL personalizada
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    Database db = await database;
    return await db.rawQuery(sql, args);
  }

  /// Ejecuta una sentencia SQL personalizada
  Future<void> execute(String sql, [List<dynamic>? args]) async {
    Database db = await database;
    await db.execute(sql, args);
  }

  /// Ejecuta múltiples operaciones en una transacción
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    Database db = await database;
    return await db.transaction(action);
  }
}
