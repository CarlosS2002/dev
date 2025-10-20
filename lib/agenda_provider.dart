import 'package:flutter/material.dart';
import 'models.dart';
import 'gemini_service.dart';

class AgendaProvider extends ChangeNotifier {
  // Mapa para almacenar los roles de los usuarios
  final Map<String, RolUsuario> _rolesUsuarios = {
    'carlos@test.com': RolUsuario.entrenador,
    'maria@test.com': RolUsuario.atleta,
    'pedro@test.com': RolUsuario.atleta,
  };

  // Lista de grupos
  final List<Grupo> _grupos = [
    Grupo(
      id: 'grupo1',
      nombre: 'Equipo Alpha',
      descripcion: 'Grupo de entrenamiento intensivo',
      entrenadorId: 'carlos@test.com',
      entrenadorNombre: 'Carlos',
      miembrosIds: ['carlos@test.com', 'maria@test.com', 'pedro@test.com'],
      rolesAlUnirse: {
        'carlos@test.com': RolUsuario.entrenador,
        'maria@test.com': RolUsuario.atleta,
        'pedro@test.com': RolUsuario.atleta,
      },
      fechaCreacion: DateTime.now(),
    ),
  ];

  // Lista de actividades
  final List<Actividad> _actividades = [
    // Actividades de HOY - 19 de octubre de 2025
    Actividad(
      id: 'act1',
      nombre: 'Cardio Intenso',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 19),
      descripcion: 'Correr 8km a ritmo moderado-alto',
      puntosBase: 60,
      creadoPor: 'carlos@test.com',
      completadoPor: ['pedro@test.com'], // Pedro completó
    ),
    Actividad(
      id: 'act2',
      nombre: 'Entrenamiento de Fuerza',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 19),
      descripcion: 'Rutina de pecho y tríceps - 4 series de 12 reps',
      puntosBase: 70,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act3',
      nombre: 'Yoga y Flexibilidad',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 19),
      descripcion: 'Sesión de yoga de 45 minutos + estiramientos',
      puntosBase: 50,
      creadoPor: 'carlos@test.com',
      completadoPor: ['pedro@test.com'], // Pedro completó
    ),
    Actividad(
      id: 'act4',
      nombre: 'Natación',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 19),
      descripcion: 'Nadar 1000 metros estilo libre',
      puntosBase: 65,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act5',
      nombre: 'Ciclismo',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 19),
      descripcion: 'Recorrido en bicicleta de 20km en ruta mixta',
      puntosBase: 75,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    
    // Actividades de MAÑANA - 20 de octubre de 2025
    Actividad(
      id: 'act6',
      nombre: 'HIIT Matutino',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 20),
      descripcion: 'Entrenamiento de intervalos de alta intensidad - 30 min',
      puntosBase: 80,
      creadoPor: 'carlos@test.com',
      completadoPor: ['pedro@test.com'], // Pedro completó
    ),
    Actividad(
      id: 'act7',
      nombre: 'Pesas - Espalda y Bíceps',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 20),
      descripcion: 'Rutina de espalda completa + curl de bíceps - 5 series',
      puntosBase: 75,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act8',
      nombre: 'Boxeo',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 20),
      descripcion: 'Entrenamiento de boxeo con saco - 45 minutos',
      puntosBase: 70,
      creadoPor: 'carlos@test.com',
      completadoPor: ['pedro@test.com'], // Pedro completó
    ),
    Actividad(
      id: 'act9',
      nombre: 'Pilates Core',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 20),
      descripcion: 'Ejercicios de pilates enfocados en abdominales y core',
      puntosBase: 55,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act10',
      nombre: 'Entrenamiento Funcional',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 20),
      descripcion: 'Circuito funcional: burpees, saltos, planchas - 30 min',
      puntosBase: 65,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act11',
      nombre: 'Caminata Activa',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 20),
      descripcion: 'Caminata rápida de 10km en parque con elevaciones',
      puntosBase: 60,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
  ];

  // Obtener rol de un usuario
  RolUsuario getRol(String email) {
    return _rolesUsuarios[email] ?? RolUsuario.atleta;
  }

  // Establecer rol de un usuario
  void setRol(String email, RolUsuario rol) {
    _rolesUsuarios[email] = rol;
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

  // Agregar un nuevo grupo
  void agregarGrupo(Grupo grupo) {
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
    notifyListeners();
  }

  // Agregar una nueva actividad
  void agregarActividad(Actividad actividad) {
    _actividades.add(actividad);
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
        'puntos': puntos,
        'actividades': actividadesCompletadas,
      });
    }

    // Ordenar por puntos (mayor a menor)
    ranking.sort((a, b) => (b['puntos'] as int).compareTo(a['puntos'] as int));

    return ranking;
  }

  // Unirse a un grupo (mediante código o invitación)
  bool unirseAGrupo(String grupoId, String usuarioEmail) {
    final index = _grupos.indexWhere((g) => g.id == grupoId);
    if (index != -1 && !_grupos[index].miembrosIds.contains(usuarioEmail)) {
      _grupos[index].miembrosIds.add(usuarioEmail);
      // Registrar el rol actual del usuario al unirse
      _grupos[index].rolesAlUnirse[usuarioEmail] = getRol(usuarioEmail);
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

  // ============= INTEGRACIÓN CON GEMINI AI =============
  
  final GeminiService _geminiService = GeminiService();
  bool _generandoActividades = false;

  bool get generandoActividades => _generandoActividades;

  /// Genera actividades diarias con IA para un usuario sin grupo o que quiere alternativas
  Future<List<Actividad>> generarActividadesConIA({
    required String usuarioEmail,
    String? grupoId,
    bool esAlternativa = false,
  }) async {
    _generandoActividades = true;
    notifyListeners();

    try {
      // Obtener información del usuario (aquí puedes agregar más datos del perfil)
      final usuario = usuarioEmail.split('@')[0];
      
      List<ActividadGenerada> actividadesGeneradas;
      
      if (esAlternativa && grupoId != null) {
        // Generar alternativas a las actividades existentes
        final actividadesExistentes = getActividadesGrupo(grupoId)
            .where((act) => act.fecha.day == DateTime.now().day)
            .map((act) => act.nombre)
            .toList();
        
        actividadesGeneradas = await _geminiService.generarActividadesAlternativas(
          nombreUsuario: usuario,
          actividadesExistentes: actividadesExistentes,
        );
      } else {
        // Generar actividades nuevas para el día
        actividadesGeneradas = await _geminiService.generarActividadesDiarias(
          nombreUsuario: usuario,
        );
      }

      // Convertir ActividadGenerada a Actividad del modelo
      final actividades = <Actividad>[];
      for (int i = 0; i < actividadesGeneradas.length; i++) {
        final actGen = actividadesGeneradas[i];
        final actividad = Actividad(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}_$i',
          nombre: actGen.nombre,
          grupoId: grupoId ?? 'personal_$usuarioEmail', // Grupo personal si no hay grupo
          fecha: DateTime.now(),
          descripcion: actGen.descripcion,
          puntosBase: actGen.puntosBase,
          creadoPor: 'Gemini AI',
          completadoPor: [],
        );
        
        // Agregar a la lista de actividades
        _actividades.add(actividad);
        actividades.add(actividad);
      }

      _generandoActividades = false;
      notifyListeners();
      return actividades;
    } catch (e) {
      print('Error al generar actividades con IA: $e');
      _generandoActividades = false;
      notifyListeners();
      return [];
    }
  }

  /// Obtiene las actividades personales generadas por IA para un usuario
  List<Actividad> getActividadesPersonales(String usuarioEmail) {
    final grupoPersonal = 'personal_$usuarioEmail';
    return _actividades
        .where((act) => 
            act.grupoId == grupoPersonal && 
            act.fecha.day == DateTime.now().day &&
            act.fecha.month == DateTime.now().month &&
            act.fecha.year == DateTime.now().year)
        .toList();
  }
}
