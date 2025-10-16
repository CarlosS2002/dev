import 'package:flutter/material.dart';
import 'models.dart';

class AgendaProvider extends ChangeNotifier {
  // Mapa para almacenar los roles de los usuarios
  final Map<String, RolUsuario> _rolesUsuarios = {
    'carlos@test.com': RolUsuario.entrenador,
    'maria@test.com': RolUsuario.atleta,
  };

  // Lista de grupos
  final List<Grupo> _grupos = [
    Grupo(
      id: 'grupo1',
      nombre: 'Equipo Alpha',
      descripcion: 'Grupo de entrenamiento intensivo',
      entrenadorId: 'carlos@test.com',
      entrenadorNombre: 'Carlos',
      miembrosIds: ['carlos@test.com', 'maria@test.com'],
      fechaCreacion: DateTime.now(),
    ),
  ];

  // Lista de actividades
  final List<Actividad> _actividades = [
    // Actividades del 8 de octubre
    Actividad(
      id: 'act1',
      nombre: 'Cardio matutino',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 8),
      descripcion: 'Correr 5km a ritmo moderado',
      puntosBase: 50,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act2',
      nombre: 'Pesas',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 8),
      descripcion: 'Rutina de piernas y glúteos',
      puntosBase: 75,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    
    // Actividades de HOY - 15 de octubre de 2025
    Actividad(
      id: 'act3',
      nombre: 'Cardio Intenso',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 15),
      descripcion: 'Correr 8km a ritmo moderado-alto',
      puntosBase: 60,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act4',
      nombre: 'Entrenamiento de Fuerza',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 15),
      descripcion: 'Rutina de pecho y tríceps - 4 series de 12 reps',
      puntosBase: 70,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act5',
      nombre: 'Yoga y Flexibilidad',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 15),
      descripcion: 'Sesión de yoga de 45 minutos + estiramientos',
      puntosBase: 50,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act6',
      nombre: 'Natación',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 15),
      descripcion: 'Nadar 1000 metros estilo libre',
      puntosBase: 65,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act7',
      nombre: 'Ciclismo',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 15),
      descripcion: 'Recorrido en bicicleta de 20km en ruta mixta',
      puntosBase: 75,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    
    // Actividades de MAÑANA - 16 de octubre de 2025
    Actividad(
      id: 'act8',
      nombre: 'HIIT Matutino',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 16),
      descripcion: 'Entrenamiento de intervalos de alta intensidad - 30 min',
      puntosBase: 80,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act9',
      nombre: 'Pesas - Espalda y Bíceps',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 16),
      descripcion: 'Rutina de espalda completa + curl de bíceps - 5 series',
      puntosBase: 75,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act10',
      nombre: 'Boxeo',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 16),
      descripcion: 'Entrenamiento de boxeo con saco - 45 minutos',
      puntosBase: 70,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act11',
      nombre: 'Pilates Core',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 16),
      descripcion: 'Ejercicios de pilates enfocados en abdominales y core',
      puntosBase: 55,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act12',
      nombre: 'Entrenamiento Funcional',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 16),
      descripcion: 'Circuito funcional: burpees, saltos, planchas - 30 min',
      puntosBase: 65,
      creadoPor: 'carlos@test.com',
      completadoPor: [],
    ),
    Actividad(
      id: 'act13',
      nombre: 'Caminata Activa',
      grupoId: 'grupo1',
      fecha: DateTime(2025, 10, 16),
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
    _grupos.add(grupo);
    notifyListeners();
  }

  // Agregar una nueva actividad
  void agregarActividad(Actividad actividad) {
    _actividades.add(actividad);
    notifyListeners();
  }

  // Completar una actividad
  void completarActividad(String actividadId, String usuarioEmail) {
    final index = _actividades.indexWhere((act) => act.id == actividadId);
    if (index != -1 && !_actividades[index].completadoPor.contains(usuarioEmail)) {
      _actividades[index].completadoPor.add(usuarioEmail);
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
      notifyListeners();
      return true;
    }
    return false;
  }
}
