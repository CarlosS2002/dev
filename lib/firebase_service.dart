import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== NOTIFICACIONES ====================

  /// Guardar notificación para un atleta en Firebase
  Future<bool> guardarNotificacion({
    required String atletaEmail,
    required String titulo,
    required String mensaje,
    required String actividadId,
    required String grupoId,
    required String grupoNombre,
  }) async {
    try {
      final notifId = '${actividadId}_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore
          .collection('notificaciones')
          .doc(atletaEmail)
          .collection('lista')
          .doc(notifId)
          .set({
        'id': notifId,
        'titulo': titulo,
        'mensaje': mensaje,
        'actividadId': actividadId,
        'grupoId': grupoId,
        'grupoNombre': grupoNombre,
        'fecha': FieldValue.serverTimestamp(),
        'leida': false,
      });
      return true;
    } catch (e) {
      print('Error guardando notificación: $e');
      return false;
    }
  }

  /// Obtener notificaciones de un usuario desde Firebase
  Future<List<Map<String, dynamic>>> obtenerNotificaciones(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('notificaciones')
          .doc(email)
          .collection('lista')
          .orderBy('fecha', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error obteniendo notificaciones: $e');
      return [];
    }
  }

  /// Obtener cantidad de notificaciones no leídas
  Future<int> obtenerContadorNoLeidas(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('notificaciones')
          .doc(email)
          .collection('lista')
          .where('leida', isEqualTo: false)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error contando notificaciones: $e');
      return 0;
    }
  }

  /// Marcar notificación como leída
  Future<void> marcarNotificacionLeida(String email, String notifId) async {
    try {
      await _firestore
          .collection('notificaciones')
          .doc(email)
          .collection('lista')
          .doc(notifId)
          .update({'leida': true});
    } catch (e) {
      print('Error marcando notificación: $e');
    }
  }

  // ==================== PERFIL DE USUARIO ====================

  /// Guardar perfil de usuario en Firebase
  Future<bool> guardarPerfil({
    required String email,
    required String nombre,
    required DateTime fechaNacimiento,
    required String sexo,
    required RolUsuario rol,
  }) async {
    try {
      await _firestore.collection('perfiles').doc(email).set({
        'email': email,
        'nombre': nombre,
        'fechaNacimiento': fechaNacimiento.toIso8601String(),
        'sexo': sexo,
        'rol': rol.toString().split('.').last,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // También guardar localmente como backup
      await _guardarPerfilLocal(email, nombre, fechaNacimiento, sexo);
      
      return true;
    } catch (e) {
      print('Error guardando perfil en Firebase: $e');
      // Si falla Firebase, guardar solo localmente
      await _guardarPerfilLocal(email, nombre, fechaNacimiento, sexo);
      return false;
    }
  }

  /// Cargar perfil de usuario desde Firebase
  Future<Map<String, dynamic>?> cargarPerfil(String email) async {
    try {
      final doc = await _firestore.collection('perfiles').doc(email).get();
      
      if (doc.exists) {
        return doc.data();
      }
      
      // Si no existe en Firebase, intentar cargar de local
      return await _cargarPerfilLocal(email);
    } catch (e) {
      print('Error cargando perfil desde Firebase: $e');
      // Si falla Firebase, cargar de local
      return await _cargarPerfilLocal(email);
    }
  }

  /// Cargar datos del registro (desde colección usuarios por UID)
  /// Busca en todos los documentos de usuarios el que tenga el email
  Future<Map<String, dynamic>?> cargarDatosRegistro(String email) async {
    try {
      // Buscar en la colección usuarios por email
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        
        // Convertir Timestamp a DateTime si es necesario
        DateTime? fechaNacimiento;
        if (data['fechaNacimiento'] != null) {
          if (data['fechaNacimiento'] is Timestamp) {
            fechaNacimiento = (data['fechaNacimiento'] as Timestamp).toDate();
          } else if (data['fechaNacimiento'] is String) {
            fechaNacimiento = DateTime.tryParse(data['fechaNacimiento']);
          }
        }
        
        return {
          'nombre': data['nombre'],
          'fechaNacimiento': fechaNacimiento,
          'sexo': data['sexo'],
          'rol': data['rol'],
        };
      }
      
      return null;
    } catch (e) {
      print('Error cargando datos de registro: $e');
      return null;
    }
  }

  Future<void> _guardarPerfilLocal(String email, String nombre, DateTime fechaNacimiento, String sexo) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'perfil_$email';
    await prefs.setString('${key}_nombre', nombre);
    await prefs.setString('${key}_fecha_nacimiento', fechaNacimiento.toIso8601String());
    await prefs.setString('${key}_sexo', sexo);
  }

  Future<Map<String, dynamic>?> _cargarPerfilLocal(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'perfil_$email';
    
    final nombre = prefs.getString('${key}_nombre');
    final fechaStr = prefs.getString('${key}_fecha_nacimiento');
    final sexo = prefs.getString('${key}_sexo');
    
    if (nombre != null || fechaStr != null || sexo != null) {
      return {
        'nombre': nombre,
        'fechaNacimiento': fechaStr,
        'sexo': sexo,
      };
    }
    return null;
  }

  // ==================== GRUPOS ====================

  /// Guardar grupo en Firebase
  Future<bool> guardarGrupo(Grupo grupo) async {
    try {
      print('🔵 Intentando guardar grupo: ${grupo.id} - ${grupo.nombre}');
      print('🔵 Entrenador: ${grupo.entrenadorId}');
      print('🔵 Miembros: ${grupo.miembrosIds}');
      
      final data = {
        'id': grupo.id,
        'nombre': grupo.nombre,
        'descripcion': grupo.descripcion,
        'entrenadorId': grupo.entrenadorId,
        'entrenadorNombre': grupo.entrenadorNombre,
        'miembrosIds': grupo.miembrosIds,
        'rolesAlUnirse': grupo.rolesAlUnirse.map((key, value) => 
            MapEntry(key, value.toString().split('.').last)),
        'fechaCreacion': grupo.fechaCreacion.toIso8601String(),
        'creadoEn': FieldValue.serverTimestamp(),
      };
      
      print('🔵 Datos a guardar: $data');
      
      await _firestore.collection('grupos').doc(grupo.id).set(data);
      
      print('✅ Grupo guardado exitosamente en Firebase: ${grupo.id}');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error guardando grupo en Firebase: $e');
      print('❌ StackTrace: $stackTrace');
      return false;
    }
  }

  /// Cargar todos los grupos de un usuario
  Future<List<Grupo>> cargarGruposUsuario(String email) async {
    try {
      // Buscar grupos donde el usuario es miembro
      final querySnapshot = await _firestore
          .collection('grupos')
          .where('miembrosIds', arrayContains: email)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _grupoFromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error cargando grupos desde Firebase: $e');
      return [];
    }
  }

  /// Cargar grupos donde el usuario es entrenador
  Future<List<Grupo>> cargarGruposComoEntrenador(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('grupos')
          .where('entrenadorId', isEqualTo: email)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _grupoFromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error cargando grupos como entrenador: $e');
      return [];
    }
  }

  /// Buscar grupo por código (case-insensitive)
  Future<Grupo?> buscarGrupoPorCodigo(String codigo) async {
    try {
      // Primero intentar búsqueda exacta (más eficiente)
      var doc = await _firestore.collection('grupos').doc(codigo).get();
      
      if (doc.exists) {
        return _grupoFromFirestore(doc.data()!);
      }
      
      // Si no encuentra, intentar con mayúsculas
      doc = await _firestore.collection('grupos').doc(codigo.toUpperCase()).get();
      
      if (doc.exists) {
        return _grupoFromFirestore(doc.data()!);
      }
      
      // Intentar con minúsculas
      doc = await _firestore.collection('grupos').doc(codigo.toLowerCase()).get();
      
      if (doc.exists) {
        return _grupoFromFirestore(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('Error buscando grupo: $e');
      return null;
    }
  }

  /// Unirse a un grupo
  Future<bool> unirseAGrupo(String grupoId, String email, RolUsuario rol) async {
    try {
      await _firestore.collection('grupos').doc(grupoId).update({
        'miembrosIds': FieldValue.arrayUnion([email]),
        'rolesAlUnirse.$email': rol.toString().split('.').last,
      });
      return true;
    } catch (e) {
      print('Error uniéndose al grupo: $e');
      return false;
    }
  }

  /// Actualizar miembros del grupo
  Future<bool> actualizarMiembrosGrupo(String grupoId, List<String> miembrosIds, {Map<String, RolUsuario>? rolesAlUnirse}) async {
    try {
      final Map<String, dynamic> updateData = {
        'miembrosIds': miembrosIds,
      };
      
      if (rolesAlUnirse != null) {
        updateData['rolesAlUnirse'] = rolesAlUnirse.map((key, value) => 
            MapEntry(key, value.toString().split('.').last));
      }
      
      await _firestore.collection('grupos').doc(grupoId).update(updateData);
      return true;
    } catch (e) {
      print('Error actualizando miembros del grupo: $e');
      return false;
    }
  }

  /// Actualizar lista de completados de una actividad
  Future<bool> actualizarCompletadoActividad(String actividadId, List<String> completadoPor) async {
    try {
      await _firestore.collection('actividades').doc(actividadId).update({
        'completadoPor': completadoPor,
      });
      return true;
    } catch (e) {
      print('Error actualizando completados: $e');
      return false;
    }
  }

  Grupo _grupoFromFirestore(Map<String, dynamic> data) {
    final rolesMap = <String, RolUsuario>{};
    if (data['rolesAlUnirse'] != null) {
      (data['rolesAlUnirse'] as Map<String, dynamic>).forEach((key, value) {
        rolesMap[key] = value == 'entrenador' ? RolUsuario.entrenador : RolUsuario.atleta;
      });
    }
    
    return Grupo(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      entrenadorId: data['entrenadorId'] ?? '',
      entrenadorNombre: data['entrenadorNombre'] ?? '',
      miembrosIds: List<String>.from(data['miembrosIds'] ?? []),
      rolesAlUnirse: rolesMap,
      fechaCreacion: data['fechaCreacion'] != null 
          ? DateTime.parse(data['fechaCreacion']) 
          : DateTime.now(),
    );
  }

  // ==================== ACTIVIDADES ====================

  /// Guardar actividad en Firebase
  Future<bool> guardarActividad(Actividad actividad) async {
    try {
      await _firestore.collection('actividades').doc(actividad.id).set({
        'id': actividad.id,
        'nombre': actividad.nombre,
        'grupoId': actividad.grupoId,
        'fecha': actividad.fecha.toIso8601String(),
        'descripcion': actividad.descripcion,
        'puntosBase': actividad.puntosBase,
        'creadoPor': actividad.creadoPor,
        'completadoPor': actividad.completadoPor,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error guardando actividad en Firebase: $e');
      return false;
    }
  }

  /// Cargar actividades de un grupo
  Future<List<Actividad>> cargarActividadesGrupo(String grupoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('actividades')
          .where('grupoId', isEqualTo: grupoId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _actividadFromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error cargando actividades: $e');
      return [];
    }
  }

  /// Cargar actividades personales del usuario (sin grupo)
  Future<List<Actividad>> cargarActividadesPersonales(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('actividades')
          .where('grupoId', isEqualTo: '')
          .where('creadoPor', isEqualTo: email)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _actividadFromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error cargando actividades personales: $e');
      return [];
    }
  }

  /// Editar actividad
  Future<bool> editarActividad(String actividadId, String nombre, String descripcion, int puntosBase) async {
    try {
      await _firestore.collection('actividades').doc(actividadId).update({
        'nombre': nombre,
        'descripcion': descripcion,
        'puntosBase': puntosBase,
      });
      return true;
    } catch (e) {
      print('Error editando actividad: $e');
      return false;
    }
  }

  /// Eliminar actividad
  Future<bool> eliminarActividad(String actividadId) async {
    try {
      await _firestore.collection('actividades').doc(actividadId).delete();
      return true;
    } catch (e) {
      print('Error eliminando actividad: $e');
      return false;
    }
  }

  Actividad _actividadFromFirestore(Map<String, dynamic> data) {
    return Actividad(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      grupoId: data['grupoId'] ?? '',
      fecha: data['fecha'] != null 
          ? DateTime.parse(data['fecha']) 
          : DateTime.now(),
      descripcion: data['descripcion'] ?? '',
      puntosBase: data['puntosBase'] ?? 0,
      creadoPor: data['creadoPor'] ?? '',
      completadoPor: List<String>.from(data['completadoPor'] ?? []),
    );
  }

  // ==================== ROL DE USUARIO ====================

  /// Obtener nombre de un usuario por su email
  Future<String?> obtenerNombreUsuario(String email) async {
    try {
      // Primero buscar en perfiles
      final perfilDoc = await _firestore.collection('perfiles').doc(email).get();
      if (perfilDoc.exists && perfilDoc.data()?['nombre'] != null) {
        return perfilDoc.data()!['nombre'] as String;
      }
      
      // Si no está en perfiles, buscar en usuarios por email
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        if (data['nombre'] != null) {
          return data['nombre'] as String;
        }
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo nombre de usuario: $e');
      return null;
    }
  }

  /// Obtener nombres de múltiples usuarios
  Future<Map<String, String>> obtenerNombresUsuarios(List<String> emails) async {
    final nombres = <String, String>{};
    
    for (final email in emails) {
      final nombre = await obtenerNombreUsuario(email);
      nombres[email] = nombre ?? email.split('@')[0];
    }
    
    return nombres;
  }

  /// Guardar rol de usuario
  Future<bool> guardarRolUsuario(String email, RolUsuario rol) async {
    try {
      await _firestore.collection('usuarios').doc(email).set({
        'email': email,
        'rol': rol.toString().split('.').last,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error guardando rol: $e');
      return false;
    }
  }

  /// Cargar rol de usuario
  Future<RolUsuario?> cargarRolUsuario(String email) async {
    try {
      // Primero buscar por email como documento ID
      var doc = await _firestore.collection('usuarios').doc(email).get();
      
      if (doc.exists && doc.data()?['rol'] != null) {
        final rolStr = doc.data()!['rol'] as String;
        print('📋 Rol encontrado en usuarios/{email}: $rolStr');
        return rolStr == 'entrenador' ? RolUsuario.entrenador : RolUsuario.atleta;
      }
      
      // Si no existe, buscar en la colección usuarios por campo email (para registros por UID)
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        if (data['rol'] != null) {
          final rolStr = data['rol'] as String;
          print('📋 Rol encontrado en usuarios (query): $rolStr');
          
          // Guardar también en usuarios/{email} para futuras consultas
          await _firestore.collection('usuarios').doc(email).set({
            'email': email,
            'rol': rolStr,
            'actualizadoEn': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          return rolStr == 'entrenador' ? RolUsuario.entrenador : RolUsuario.atleta;
        }
      }
      
      print('⚠️ Rol no encontrado para $email');
      return null;
    } catch (e) {
      print('Error cargando rol: $e');
      return null;
    }
  }

  // ==================== ACTIVIDADES FÍSICAS (MAPA) ====================

  /// Guardar actividad física del mapa
  Future<bool> guardarActividadFisica(String email, Map<String, dynamic> actividad) async {
    try {
      await _firestore
          .collection('actividades_fisicas')
          .doc(email)
          .collection('historial')
          .doc(actividad['id'])
          .set(actividad);
      return true;
    } catch (e) {
      print('Error guardando actividad física: $e');
      return false;
    }
  }

  /// Cargar historial de actividades físicas
  Future<List<Map<String, dynamic>>> cargarActividadesFisicas(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('actividades_fisicas')
          .doc(email)
          .collection('historial')
          .orderBy('fechaInicio', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error cargando actividades físicas: $e');
      return [];
    }
  }

  /// Eliminar actividad física
  Future<bool> eliminarActividadFisica(String email, String actividadId) async {
    try {
      await _firestore
          .collection('actividades_fisicas')
          .doc(email)
          .collection('historial')
          .doc(actividadId)
          .delete();
      return true;
    } catch (e) {
      print('Error eliminando actividad física: $e');
      return false;
    }
  }
}
