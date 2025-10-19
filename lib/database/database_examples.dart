import 'package:flutter/material.dart';
import 'database_helper.dart';

/// Ejemplos de uso de la base de datos SQLite de Lingo Gym
/// 
/// Este archivo contiene ejemplos prácticos de cómo usar el DatabaseHelper
/// en diferentes escenarios de la aplicación.

class DatabaseExamples {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Ejemplo 1: Registro de un nuevo usuario
  Future<void> registrarNuevoUsuario() async {
    try {
      // Generar ID único (en producción usar UUID)
      final String userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      await _dbHelper.insertUsuario({
        'id': userId,
        'nombre': 'Carlos Sánchez',
        'email': 'carlos@example.com',
        'password_hash': 'hash_seguro_aqui', // Usar bcrypt o similar
        'rol': 'atleta',
        'idioma_preferido': 'es',
      });

      // Registrar el acceso
      await _dbHelper.registrarAcceso(
        usuarioId: userId,
        tipoAcceso: 'login',
        dispositivo: 'Android',
        navegador: 'App Mobile',
      );

      print('Usuario registrado exitosamente: $userId');
    } catch (e) {
      print('Error al registrar usuario: $e');
    }
  }

  /// Ejemplo 2: Crear un grupo y agregar miembros
  Future<void> crearGrupoYAgregarMiembros() async {
    try {
      final String grupoId = 'grupo_${DateTime.now().millisecondsSinceEpoch}';
      final String entrenadorId = 'user_entrenador_123';

      // Crear el grupo
      await _dbHelper.insertGrupo({
        'id': grupoId,
        'nombre': 'Francés Intermedio',
        'descripcion': 'Grupo para practicar francés nivel B1',
        'entrenador_id': entrenadorId,
        'max_miembros': 30,
      });

      // Agregar miembros al grupo
      List<String> miembrosIds = [
        'user_atleta_001',
        'user_atleta_002',
        'user_atleta_003',
      ];

      for (String miembroId in miembrosIds) {
        await _dbHelper.addMiembroGrupo(grupoId, miembroId);
      }

      print('Grupo creado con ${miembrosIds.length} miembros');
    } catch (e) {
      print('Error al crear grupo: $e');
    }
  }

  /// Ejemplo 3: Crear actividad y notificar automáticamente
  Future<void> crearActividadYNotificar() async {
    try {
      final String actividadId = 'act_${DateTime.now().millisecondsSinceEpoch}';
      
      // Al insertar la actividad, el trigger automáticamente
      // crea notificaciones para todos los miembros del grupo
      await _dbHelper.insertActividad({
        'id': actividadId,
        'nombre': 'Conversación: Restaurante',
        'descripcion': 'Practicar diálogo en un restaurante',
        'grupo_id': 'grupo_123',
        'fecha_actividad': DateTime.now().add(Duration(days: 2)).toIso8601String(),
        'puntos_base': 15,
        'creado_por': 'user_entrenador_123',
        'tipo_actividad': 'practica',
      });

      print('Actividad creada y notificaciones enviadas automáticamente');
    } catch (e) {
      print('Error al crear actividad: $e');
    }
  }

  /// Ejemplo 4: Completar actividad y actualizar ranking automáticamente
  Future<void> completarActividadYActualizarRanking() async {
    try {
      final String actividadId = 'act_123';
      final String usuarioId = 'user_atleta_001';

      // Al registrar el progreso, el trigger automáticamente
      // actualiza el ranking del usuario en ese grupo
      await _dbHelper.registrarProgreso(
        actividadId: actividadId,
        usuarioId: usuarioId,
        puntosObtenidos: 15,
        calificacion: 9.0,
        comentario: '¡Excelente trabajo!',
      );

      // Obtener el ranking actualizado
      List<Map<String, dynamic>> ranking = 
        await _dbHelper.getRankingCompleto('grupo_123');
      
      print('Ranking actualizado:');
      for (var entry in ranking) {
        print('${entry['usuario_nombre']}: ${entry['puntos_totales']} puntos');
      }
    } catch (e) {
      print('Error al completar actividad: $e');
    }
  }

  /// Ejemplo 5: Consultar notificaciones no leídas
  Future<void> obtenerNotificacionesNoLeidas(String usuarioId) async {
    try {
      List<Map<String, dynamic>> notificaciones = 
        await _dbHelper.getNotificacionesUsuario(
          usuarioId, 
          soloNoLeidas: true,
        );

      print('Tienes ${notificaciones.length} notificaciones sin leer:');
      for (var notif in notificaciones) {
        print('- ${notif['titulo']}: ${notif['mensaje']}');
      }

      // Marcar todas como leídas
      if (notificaciones.isNotEmpty) {
        await _dbHelper.marcarTodasNotificacionesLeidas(usuarioId);
        print('Todas las notificaciones marcadas como leídas');
      }
    } catch (e) {
      print('Error al consultar notificaciones: $e');
    }
  }

  /// Ejemplo 6: Obtener actividades pendientes de un usuario
  Future<void> obtenerActividadesPendientes(
      String usuarioId, String grupoId) async {
    try {
      List<Map<String, dynamic>> pendientes = 
        await _dbHelper.getActividadesPendientes(usuarioId, grupoId);

      print('Actividades pendientes:');
      for (var actividad in pendientes) {
        print('- ${actividad['actividad_nombre']} (${actividad['puntos_base']} puntos)');
        print('  Fecha: ${actividad['fecha_actividad']}');
      }
    } catch (e) {
      print('Error al obtener actividades pendientes: $e');
    }
  }

  /// Ejemplo 7: Crear evento en el calendario
  Future<void> crearEventoCalendario() async {
    try {
      final String eventoId = 'evento_${DateTime.now().millisecondsSinceEpoch}';
      final DateTime inicio = DateTime.now().add(Duration(days: 3));
      final DateTime fin = inicio.add(Duration(hours: 2));

      await _dbHelper.insertEvento({
        'id': eventoId,
        'titulo': 'Clase de conversación',
        'descripcion': 'Práctica de conversación grupal',
        'fecha_inicio': inicio.toIso8601String(),
        'fecha_fin': fin.toIso8601String(),
        'usuario_id': 'user_123',
        'grupo_id': 'grupo_123',
        'tipo_evento': 'grupal',
        'ubicacion': 'Sala Virtual 1',
      });

      print('Evento creado exitosamente');
    } catch (e) {
      print('Error al crear evento: $e');
    }
  }

  /// Ejemplo 8: Consultar auditoría de un usuario
  Future<void> consultarAuditoriaUsuario(String usuarioId) async {
    try {
      List<Map<String, dynamic>> auditoria = 
        await _dbHelper.getAuditoriaUsuarios(usuarioId: usuarioId);

      print('Historial de cambios del usuario:');
      for (var registro in auditoria) {
        print('${registro['fecha_cambio']}: ${registro['operacion']} - '
              '${registro['campo_modificado']}');
        if (registro['valor_anterior'] != null) {
          print('  Antes: ${registro['valor_anterior']}');
        }
        if (registro['valor_nuevo'] != null) {
          print('  Después: ${registro['valor_nuevo']}');
        }
      }
    } catch (e) {
      print('Error al consultar auditoría: $e');
    }
  }

  /// Ejemplo 9: Consultar bitácora del sistema
  Future<void> consultarBitacoraSistema() async {
    try {
      // Obtener últimas 50 operaciones
      List<Map<String, dynamic>> bitacora = 
        await _dbHelper.getBitacoraSistema(limit: 50);

      print('Últimas operaciones del sistema:');
      for (var registro in bitacora) {
        print('${registro['fecha_operacion']}: '
              '${registro['operacion']} en ${registro['tabla_afectada']}');
      }

      // Obtener resumen de auditoría
      List<Map<String, dynamic>> resumen = 
        await _dbHelper.getResumenAuditoria();
      
      print('\nResumen de auditoría:');
      for (var item in resumen) {
        print('${item['tabla']} - ${item['operacion']}: ${item['total']} operaciones');
      }
    } catch (e) {
      print('Error al consultar bitácora: $e');
    }
  }

  /// Ejemplo 10: Usar transacciones para operaciones complejas
  Future<void> operacionCompleja() async {
    try {
      await _dbHelper.transaction((txn) async {
        // Crear un grupo
        await txn.insert('grupos', {
          'id': 'grupo_nuevo',
          'nombre': 'Alemán Básico',
          'descripcion': 'Grupo para principiantes',
          'entrenador_id': 'user_entrenador_123',
        });

        // Agregar varios miembros
        List<String> miembros = ['user_001', 'user_002', 'user_003'];
        for (String miembro in miembros) {
          await txn.insert('grupos_miembros', {
            'grupo_id': 'grupo_nuevo',
            'usuario_id': miembro,
          });
        }

        // Crear actividades iniciales
        for (int i = 1; i <= 3; i++) {
          await txn.insert('actividades', {
            'id': 'act_inicial_$i',
            'nombre': 'Lección $i',
            'descripcion': 'Actividad inicial $i',
            'grupo_id': 'grupo_nuevo',
            'fecha_actividad': DateTime.now()
                .add(Duration(days: i * 7))
                .toIso8601String(),
            'puntos_base': 10,
            'creado_por': 'user_entrenador_123',
            'tipo_actividad': 'ejercicio',
          });
        }
      });

      print('Operación compleja completada exitosamente');
    } catch (e) {
      print('Error en operación compleja (rollback automático): $e');
    }
  }

  /// Ejemplo 11: Obtener estadísticas de un grupo
  Future<void> obtenerEstadisticasGrupo(String grupoId) async {
    try {
      // Total de miembros
      List<Map<String, dynamic>> miembros = 
        await _dbHelper.getMiembrosGrupo(grupoId);
      
      // Total de actividades
      List<Map<String, dynamic>> actividades = 
        await _dbHelper.getActividadesByGrupo(grupoId);
      
      // Ranking del grupo
      List<Map<String, dynamic>> ranking = 
        await _dbHelper.getRankingGrupo(grupoId);

      print('Estadísticas del grupo:');
      print('- Miembros: ${miembros.length}');
      print('- Actividades: ${actividades.length}');
      print('- Usuarios en ranking: ${ranking.length}');
      
      if (ranking.isNotEmpty) {
        var mejor = ranking.first;
        print('- Líder: ${mejor['usuario_id']} con ${mejor['puntos_totales']} puntos');
      }
    } catch (e) {
      print('Error al obtener estadísticas: $e');
    }
  }

  /// Ejemplo 12: Buscar usuarios por rol
  Future<void> buscarUsuariosPorRol(String rol) async {
    try {
      List<Map<String, dynamic>> usuarios = 
        await _dbHelper.rawQuery(
          'SELECT * FROM usuarios WHERE rol = ? AND activo = 1 ORDER BY nombre',
          [rol],
        );

      print('Usuarios con rol $rol:');
      for (var usuario in usuarios) {
        print('- ${usuario['nombre']} (${usuario['email']})');
      }
    } catch (e) {
      print('Error al buscar usuarios: $e');
    }
  }

  /// Ejemplo 13: Limpiar base de datos (solo para testing)
  Future<void> limpiarBaseDatos() async {
    try {
      await _dbHelper.deleteDatabase();
      print('Base de datos eliminada');
    } catch (e) {
      print('Error al eliminar base de datos: $e');
    }
  }
}

/// Widget de ejemplo que demuestra el uso de la base de datos
class DatabaseExampleWidget extends StatefulWidget {
  @override
  _DatabaseExampleWidgetState createState() => _DatabaseExampleWidgetState();
}

class _DatabaseExampleWidgetState extends State<DatabaseExampleWidget> {
  final DatabaseExamples _examples = DatabaseExamples();
  String _resultado = 'Esperando acción...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ejemplos de Base de Datos'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _resultado,
              style: TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _examples.registrarNuevoUsuario();
                setState(() {
                  _resultado = 'Usuario registrado';
                });
              },
              child: Text('Registrar Usuario'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _examples.crearGrupoYAgregarMiembros();
                setState(() {
                  _resultado = 'Grupo creado con miembros';
                });
              },
              child: Text('Crear Grupo'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _examples.crearActividadYNotificar();
                setState(() {
                  _resultado = 'Actividad creada y notificada';
                });
              },
              child: Text('Crear Actividad'),
            ),
          ],
        ),
      ),
    );
  }
}
