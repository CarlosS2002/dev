import 'package:flutter/material.dart';
import 'models.dart';
import 'notification_service.dart';
import 'firebase_service.dart';

class AgendaProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FirebaseService _firebaseService = FirebaseService();
  
  // Mapa para almacenar los roles de los usuarios
  final Map<String, RolUsuario> _rolesUsuarios = {};

  // Lista de grupos (inicialmente vacía, se carga de Firebase)
  final List<Grupo> _grupos = [];

  // Lista de actividades (inicialmente vacía, se carga de Firebase)
  final List<Actividad> _actividades = [];
  
  // Contador de notificaciones no leídas
  int _notificacionesNoLeidas = 0;
  int get notificacionesNoLeidas => _notificacionesNoLeidas;
  
  // Estado de carga
  bool _isLoading = false;
  bool _isInitialized = false;
  
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Obtener notificaciones del usuario
  Future<List<Map<String, dynamic>>> obtenerNotificaciones(String email) async {
    return await _firebaseService.obtenerNotificaciones(email);
  }

  // Actualizar contador de notificaciones no leídas
  Future<void> actualizarContadorNotificaciones(String email) async {
    _notificacionesNoLeidas = await _firebaseService.obtenerContadorNoLeidas(email);
    notifyListeners();
  }

  // Marcar notificación como leída
  Future<void> marcarNotificacionLeida(String email, String notifId) async {
    await _firebaseService.marcarNotificacionLeida(email, notifId);
    await actualizarContadorNotificaciones(email);
  }

  // Inicializar y cargar datos del usuario desde Firebase
  Future<void> inicializarUsuario(String email) async {
    // Si ya está inicializado pero no tiene grupos, forzar recarga
    if (_isInitialized && _grupos.isEmpty) {
      _isInitialized = false;
    }
    
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      print('🔄 Inicializando usuario: $email');
      
      // Cargar rol del usuario solo si no está ya establecido
      if (!_rolesUsuarios.containsKey(email)) {
        final rol = await _firebaseService.cargarRolUsuario(email);
        if (rol != null) {
          _rolesUsuarios[email] = rol;
          print('✅ Rol cargado desde Firebase: $rol');
        } else {
          print('⚠️ Rol no encontrado en Firebase, usando atleta por defecto');
        }
      } else {
        print('✅ Rol ya establecido: ${_rolesUsuarios[email]}');
      }
      
      // Cargar grupos donde el usuario es miembro
      final gruposComoMiembro = await _firebaseService.cargarGruposUsuario(email);
      print('📦 Grupos como miembro: ${gruposComoMiembro.length}');
      for (var grupo in gruposComoMiembro) {
        if (!_grupos.any((g) => g.id == grupo.id)) {
          _grupos.add(grupo);
          print('  ➕ Grupo agregado: ${grupo.nombre} (${grupo.id})');
        }
      }
      
      // Cargar grupos donde el usuario es entrenador
      final gruposComoEntrenador = await _firebaseService.cargarGruposComoEntrenador(email);
      print('📦 Grupos como entrenador: ${gruposComoEntrenador.length}');
      for (var grupo in gruposComoEntrenador) {
        if (!_grupos.any((g) => g.id == grupo.id)) {
          _grupos.add(grupo);
          print('  ➕ Grupo agregado: ${grupo.nombre} (${grupo.id})');
        }
      }
      
      print('📊 Total grupos cargados: ${_grupos.length}');
      
      // Cargar actividades de cada grupo
      for (var grupo in _grupos) {
        final actividades = await _firebaseService.cargarActividadesGrupo(grupo.id);
        print('📋 Actividades de ${grupo.nombre}: ${actividades.length}');
        for (var actividad in actividades) {
          if (!_actividades.any((a) => a.id == actividad.id)) {
            _actividades.add(actividad);
          }
        }
        
        // Cargar nombres de los miembros del grupo
        for (var miembroEmail in grupo.miembrosIds) {
          if (!_nombresCache.containsKey(miembroEmail)) {
            final nombre = await _firebaseService.obtenerNombreUsuario(miembroEmail);
            _nombresCache[miembroEmail] = nombre ?? miembroEmail.split('@')[0];
          }
        }
      }
      
      // Cargar contador de notificaciones no leídas
      await actualizarContadorNotificaciones(email);
      
      _isInitialized = true;
      print('✅ Usuario inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando usuario: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Resetear el estado del provider (para logout)
  void resetear() {
    _grupos.clear();
    _actividades.clear();
    _rolesUsuarios.clear();
    _nombresCache.clear();
    _notificacionesNoLeidas = 0;
    _isInitialized = false;
    _isLoading = false;
    notifyListeners();
  }

  // Obtener rol de un usuario
  RolUsuario getRol(String email) {
    return _rolesUsuarios[email] ?? RolUsuario.atleta;
  }

  // Establecer rol de un usuario
  void setRol(String email, RolUsuario rol) {
    _rolesUsuarios[email] = rol;
    // Guardar en Firebase
    _firebaseService.guardarRolUsuario(email, rol);
    notifyListeners();
  }

  // Obtener grupos donde el usuario es miembro
  List<Grupo> getGruposUsuario(String email) {
    return _grupos.where((grupo) => grupo.miembrosIds.contains(email)).toList();
  }

  // Obtener grupos donde el usuario es entrenador
  List<Grupo> getGruposComoEntrenador(String email) {
    return _grupos.where((grupo) => grupo.entrenadorId == email).toList();
  }

  // Obtener actividades de un grupo (o individuales si grupoId es null o vacío)
  List<Actividad> getActividadesGrupo(String grupoId) {
    if (grupoId.isEmpty) {
      return _actividades.where((act) => act.grupoId.isEmpty).toList();
    }
    return _actividades.where((act) => act.grupoId == grupoId).toList();
  }

  // Recargar actividades de un grupo desde Firebase
  Future<void> recargarActividadesGrupo(String grupoId) async {
    if (grupoId.isEmpty) return;
    
    try {
      final actividades = await _firebaseService.cargarActividadesGrupo(grupoId);
      for (var actividad in actividades) {
        // Remover versión antigua si existe
        _actividades.removeWhere((a) => a.id == actividad.id);
        // Agregar versión actualizada
        _actividades.add(actividad);
      }
      notifyListeners();
    } catch (e) {
      print('Error recargando actividades: $e');
    }
  }

  // Recargar todos los datos del usuario (grupos y actividades) - Fuerza recarga completa
  Future<void> recargarDatos(String email) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('🔄 Recargando datos para: $email');
      
      // Limpiar datos actuales para forzar recarga completa
      _grupos.clear();
      _actividades.clear();
      
      // Recargar grupos donde el usuario es miembro
      final gruposComoMiembro = await _firebaseService.cargarGruposUsuario(email);
      print('📦 Grupos como miembro: ${gruposComoMiembro.length}');
      for (var grupo in gruposComoMiembro) {
        if (!_grupos.any((g) => g.id == grupo.id)) {
          _grupos.add(grupo);
          print('  ➕ Grupo: ${grupo.nombre}');
        }
      }
      
      // Recargar grupos donde el usuario es entrenador
      final gruposComoEntrenador = await _firebaseService.cargarGruposComoEntrenador(email);
      print('📦 Grupos como entrenador: ${gruposComoEntrenador.length}');
      for (var grupo in gruposComoEntrenador) {
        if (!_grupos.any((g) => g.id == grupo.id)) {
          _grupos.add(grupo);
          print('  ➕ Grupo: ${grupo.nombre}');
        }
      }
      
      print('📊 Total grupos: ${_grupos.length}');
      
      // Recargar actividades de cada grupo
      for (var grupo in _grupos) {
        final actividades = await _firebaseService.cargarActividadesGrupo(grupo.id);
        print('📋 Actividades de ${grupo.nombre}: ${actividades.length}');
        for (var actividad in actividades) {
          if (!_actividades.any((a) => a.id == actividad.id)) {
            _actividades.add(actividad);
          }
        }
        
        // Cargar nombres de los miembros
        for (var miembroEmail in grupo.miembrosIds) {
          if (!_nombresCache.containsKey(miembroEmail)) {
            final nombre = await _firebaseService.obtenerNombreUsuario(miembroEmail);
            _nombresCache[miembroEmail] = nombre ?? miembroEmail.split('@')[0];
          }
        }
      }
      
      print('✅ Datos recargados correctamente');
    } catch (e) {
      print('❌ Error recargando datos: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Agregar un nuevo grupo
  Future<void> agregarGrupo(Grupo grupo) async {
    // Registrar el rol de cada miembro al momento de crear el grupo
    final rolesActualizados = Map<String, RolUsuario>.from(grupo.rolesAlUnirse);
    for (var miembroId in grupo.miembrosIds) {
      rolesActualizados[miembroId] = getRol(miembroId);
    }
    
    final grupoActualizado = Grupo(
      id: grupo.id,
      nombre: grupo.nombre,
      descripcion: grupo.descripcion,
      entrenadorId: grupo.entrenadorId,
      entrenadorNombre: grupo.entrenadorNombre,
      miembrosIds: grupo.miembrosIds,
      rolesAlUnirse: rolesActualizados,
      fechaCreacion: grupo.fechaCreacion,
    );
    
    _grupos.add(grupoActualizado);
    
    // Guardar en Firebase (con await para asegurar que se guarde)
    final guardado = await _firebaseService.guardarGrupo(grupoActualizado);
    print('📝 Grupo guardado en Firebase: $guardado - ID: ${grupoActualizado.id}');
    
    notifyListeners();
  }

  // Agregar una nueva actividad
  Future<void> agregarActividad(Actividad actividad) async {
    _actividades.add(actividad);
    
    // Guardar en Firebase (con await)
    final guardado = await _firebaseService.guardarActividad(actividad);
    print('📝 Actividad guardada en Firebase: $guardado - ID: ${actividad.id}');
    
    // Enviar notificación a los atletas del grupo
    _enviarNotificacionesAAtletas(actividad);
    
    notifyListeners();
  }

  // Enviar notificaciones a todos los atletas del grupo cuando se crea una actividad
  Future<void> _enviarNotificacionesAAtletas(Actividad actividad) async {
    if (actividad.grupoId.isEmpty) return;
    
    // Buscar el grupo
    final grupoIndex = _grupos.indexWhere((g) => g.id == actividad.grupoId);
    if (grupoIndex == -1) return;
    
    final grupo = _grupos[grupoIndex];
    
    // Filtrar solo los atletas (excluir al entrenador que creó la actividad)
    final atletasEmails = grupo.miembrosIds.where((email) {
      // Excluir al creador de la actividad
      if (email == actividad.creadoPor) return false;
      // Incluir a todos los demás miembros
      return true;
    }).toList();
    
    if (atletasEmails.isEmpty) return;
    
    // Generar título y mensaje motivacional
    final notificacion = _generarTextoNotificacion(actividad, grupo.nombre);
    
    // Guardar notificación en Firebase para cada atleta
    for (String atletaEmail in atletasEmails) {
      await _firebaseService.guardarNotificacion(
        atletaEmail: atletaEmail,
        titulo: notificacion['titulo']!,
        mensaje: notificacion['mensaje']!,
        actividadId: actividad.id,
        grupoId: grupo.id,
        grupoNombre: grupo.nombre,
      );
    }
    
    // También mostrar notificación local (para el dispositivo actual si hay atletas logueados)
    await _notificationService.initialize();
    await _notificationService.enviarNotificacionAsignacion(
      nombreActividad: actividad.nombre,
      grupoNombre: grupo.nombre,
      puntos: actividad.puntosBase,
      fecha: actividad.fecha,
      atletasEmails: atletasEmails,
      actividadId: actividad.id,
      grupoId: grupo.id,
    );
  }
  
  // Generar texto de notificación según el tipo de actividad
  Map<String, String> _generarTextoNotificacion(Actividad actividad, String grupoNombre) {
    final nombre = actividad.nombre.toLowerCase();
    final puntos = actividad.puntosBase;
    
    // Detectar tipo de actividad y generar mensaje apropiado
    String titulo;
    String mensaje;
    
    if (nombre.contains('cardio') || nombre.contains('correr') || nombre.contains('running')) {
      titulo = '🏃 ¡Hora de correr!';
      mensaje = '${actividad.nombre} te espera en $grupoNombre. ¡$puntos pts te esperan!';
    } else if (nombre.contains('fuerza') || nombre.contains('pesas') || nombre.contains('gym')) {
      titulo = '💪 ¡A dar todo!';
      mensaje = 'Nueva sesión de fuerza: ${actividad.nombre}. ¡Gana $puntos pts!';
    } else if (nombre.contains('flex') || nombre.contains('estir') || nombre.contains('yoga')) {
      titulo = '🧘 Momento de flexibilidad';
      mensaje = '${actividad.nombre} - Relaja y gana $puntos pts en $grupoNombre';
    } else if (nombre.contains('natación') || nombre.contains('nadar') || nombre.contains('piscina')) {
      titulo = '🏊 ¡Al agua!';
      mensaje = '${actividad.nombre} disponible. ¡$puntos pts te esperan!';
    } else if (nombre.contains('ciclismo') || nombre.contains('bici')) {
      titulo = '🚴 ¡A pedalear!';
      mensaje = 'Nueva ruta: ${actividad.nombre}. Consigue $puntos pts';
    } else if (nombre.contains('descanso') || nombre.contains('recuper')) {
      titulo = '😴 Día de recuperación';
      mensaje = '${actividad.nombre} - Tu cuerpo lo agradecerá. $puntos pts';
    } else if (puntos >= 100) {
      titulo = '🔥 ¡Reto especial!';
      mensaje = '${actividad.nombre} en $grupoNombre. ¡$puntos pts en juego!';
    } else if (puntos >= 50) {
      titulo = '⭐ Nueva actividad asignada';
      mensaje = '${actividad.nombre} - $grupoNombre ($puntos pts)';
    } else {
      titulo = '📋 ${actividad.nombre}';
      mensaje = '$grupoNombre te ha asignado una nueva actividad. $puntos pts';
    }
    
    return {'titulo': titulo, 'mensaje': mensaje};
  }

  // Editar una actividad existente
  void editarActividad(String actividadId, String nombre, String descripcion, int puntosBase) {
    final index = _actividades.indexWhere((act) => act.id == actividadId);
    if (index != -1) {
      final actividadAntigua = _actividades[index];
      // Crear nueva actividad con los datos actualizados
      _actividades[index] = Actividad(
        id: actividadAntigua.id,
        nombre: nombre,
        grupoId: actividadAntigua.grupoId,
        fecha: actividadAntigua.fecha,
        descripcion: descripcion,
        puntosBase: puntosBase,
        creadoPor: actividadAntigua.creadoPor,
        completadoPor: actividadAntigua.completadoPor,
      );
      
      // Actualizar en Firebase
      _firebaseService.editarActividad(actividadId, nombre, descripcion, puntosBase);
      
      notifyListeners();
    }
  }

  // Eliminar una actividad
  void eliminarActividad(String actividadId) {
    _actividades.removeWhere((act) => act.id == actividadId);
    
    // Eliminar en Firebase
    _firebaseService.eliminarActividad(actividadId);
    
    notifyListeners();
  }

  // Completar una actividad
  bool completarActividad(String actividadId, String usuarioEmail) {
    final index = _actividades.indexWhere((act) => act.id == actividadId);
    if (index != -1 && !_actividades[index].completadoPor.contains(usuarioEmail)) {
      final actividad = _actividades[index];
      
      // Validar que el usuario pueda participar en este grupo
      if (!puedeParticiparEnGrupo(actividad.grupoId, usuarioEmail)) {
        return false; // No puede completar porque su rol cambió
      }
      
      actividad.completadoPor.add(usuarioEmail);
      
      // Actualizar en Firebase
      _firebaseService.actualizarCompletadoActividad(actividadId, actividad.completadoPor);
      
      notifyListeners();
      return true;
    }
    return false;
  }

  // Desmarcar una actividad completada (para cuando se completa por error)
  void descompletarActividad(String actividadId, String usuarioEmail) {
    final index = _actividades.indexWhere((act) => act.id == actividadId);
    if (index != -1 && _actividades[index].completadoPor.contains(usuarioEmail)) {
      _actividades[index].completadoPor.remove(usuarioEmail);
      
      // Actualizar en Firebase
      _firebaseService.actualizarCompletadoActividad(actividadId, _actividades[index].completadoPor);
      
      notifyListeners();
    }
  }

  // Obtener puntos totales de un usuario en un grupo
  int getPuntosUsuarioEnGrupo(String usuarioEmail, String grupoId) {
    final actividadesGrupo = getActividadesGrupo(grupoId);
    int puntos = 0;
    
    for (var actividad in actividadesGrupo) {
      if (actividad.completadoPor.contains(usuarioEmail)) {
        puntos += actividad.puntosBase;
      }
    }
    
    return puntos;
  }

  // Cache de nombres de usuarios
  final Map<String, String> _nombresCache = {};

  // Obtener nombre de usuario (con cache)
  Future<String> getNombreUsuario(String email) async {
    if (_nombresCache.containsKey(email)) {
      return _nombresCache[email]!;
    }
    
    final nombre = await _firebaseService.obtenerNombreUsuario(email);
    _nombresCache[email] = nombre ?? email.split('@')[0];
    return _nombresCache[email]!;
  }

  // Cargar nombres de usuarios para un grupo
  Future<void> cargarNombresGrupo(String grupoId) async {
    final grupo = _grupos.firstWhere((g) => g.id == grupoId, orElse: () => _grupos.first);
    
    for (var email in grupo.miembrosIds) {
      if (!_nombresCache.containsKey(email)) {
        final nombre = await _firebaseService.obtenerNombreUsuario(email);
        _nombresCache[email] = nombre ?? email.split('@')[0];
      }
    }
    notifyListeners();
  }

  // Obtener nombre de cache (síncrono, devuelve email si no está en cache)
  String getNombreUsuarioSync(String email) {
    return _nombresCache[email] ?? email.split('@')[0];
  }

  // Obtener ranking de un grupo
  List<Map<String, dynamic>> getRankingGrupo(String grupoId) {
    final grupo = _grupos.firstWhere((g) => g.id == grupoId);
    final ranking = <Map<String, dynamic>>[];

    for (var miembroId in grupo.miembrosIds) {
      final puntos = getPuntosUsuarioEnGrupo(miembroId, grupoId);
      final actividadesCompletadas = getActividadesGrupo(grupoId)
          .where((act) => act.completadoPor.contains(miembroId))
          .length;

      ranking.add({
        'usuarioEmail': miembroId,
        'nombre': _nombresCache[miembroId] ?? miembroId.split('@')[0],
        'puntos': puntos,
        'actividades': actividadesCompletadas,
      });
    }

    // Ordenar por puntos (mayor a menor)
    ranking.sort((a, b) => (b['puntos'] as int).compareTo(a['puntos'] as int));

    return ranking;
  }

  // Unirse a un grupo (mediante código o invitación)
  // Ahora es asíncrono porque puede necesitar buscar en Firebase
  Future<bool> unirseAGrupo(String codigo, String usuarioEmail) async {
    // Primero buscar en la lista local
    var index = _grupos.indexWhere((g) => g.id.toLowerCase() == codigo.toLowerCase());
    
    // Si no está en local, buscar en Firebase
    if (index == -1) {
      final grupoFirebase = await _firebaseService.buscarGrupoPorCodigo(codigo);
      if (grupoFirebase != null) {
        // Agregar el grupo a la lista local
        _grupos.add(grupoFirebase);
        index = _grupos.length - 1;
        
        // Cargar las actividades del grupo
        await recargarActividadesGrupo(grupoFirebase.id);
      }
    }
    
    if (index != -1 && !_grupos[index].miembrosIds.contains(usuarioEmail)) {
      _grupos[index].miembrosIds.add(usuarioEmail);
      // Registrar el rol actual del usuario al unirse
      _grupos[index].rolesAlUnirse[usuarioEmail] = getRol(usuarioEmail);
      
      // Actualizar en Firebase (await para asegurar persistencia)
      await _firebaseService.actualizarMiembrosGrupo(
        _grupos[index].id, 
        _grupos[index].miembrosIds,
        rolesAlUnirse: _grupos[index].rolesAlUnirse,
      );
      
      // Cargar nombres de los miembros del grupo
      for (var miembroEmail in _grupos[index].miembrosIds) {
        if (!_nombresCache.containsKey(miembroEmail)) {
          final nombre = await _firebaseService.obtenerNombreUsuario(miembroEmail);
          _nombresCache[miembroEmail] = nombre ?? miembroEmail.split('@')[0];
        }
      }
      
      notifyListeners();
      return true;
    }
    return false;
  }

  // Verificar si un usuario puede participar en actividades del grupo
  bool puedeParticiparEnGrupo(String grupoId, String usuarioEmail) {
    final grupo = _grupos.firstWhere((g) => g.id == grupoId, orElse: () => _grupos[0]);
    if (grupo.id != grupoId) return false;
    
    // Verificar si es miembro
    if (!grupo.miembrosIds.contains(usuarioEmail)) return false;
    
    // Verificar si el rol actual coincide con el rol al unirse
    final rolActual = getRol(usuarioEmail);
    final rolAlUnirse = grupo.rolesAlUnirse[usuarioEmail];
    
    return rolActual == rolAlUnirse;
  }
}
