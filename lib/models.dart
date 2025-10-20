// Modelo para representar un Grupo
class Grupo {
  final String id;
  final String nombre;
  final String descripcion;
  final String entrenadorId;
  final String entrenadorNombre;
  final List<String> miembrosIds;
  final Map<String, RolUsuario> rolesAlUnirse; // Rol que tenía cada miembro al unirse
  final DateTime fechaCreacion;

  Grupo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.entrenadorId,
    required this.entrenadorNombre,
    required this.miembrosIds,
    Map<String, RolUsuario>? rolesAlUnirse,
    required this.fechaCreacion,
  }) : rolesAlUnirse = rolesAlUnirse ?? {};
}

// Modelo para representar una Actividad
class Actividad {
  final String id;
  final String nombre;
  final String grupoId;
  final DateTime fecha;
  final String descripcion;
  final int puntosBase;
  final String creadoPor;
  final List<String> completadoPor; // IDs de usuarios que completaron

  Actividad({
    required this.id,
    required this.nombre,
    required this.grupoId,
    required this.fecha,
    required this.descripcion,
    required this.puntosBase,
    required this.creadoPor,
    required this.completadoPor,
  });
}

// Modelo para el Progreso del Usuario
class ProgresoUsuario {
  final String usuarioId;
  final String grupoId;
  final int puntosTotal;
  final int actividadesCompletadas;

  ProgresoUsuario({
    required this.usuarioId,
    required this.grupoId,
    required this.puntosTotal,
    required this.actividadesCompletadas,
  });
}

// Enumeración para los Roles
enum RolUsuario {
  atleta,
  entrenador,
}

extension RolUsuarioExtension on RolUsuario {
  String get nombre {
    switch (this) {
      case RolUsuario.atleta:
        return 'Atleta';
      case RolUsuario.entrenador:
        return 'Entrenador';
    }
  }

  String get icono {
    switch (this) {
      case RolUsuario.atleta:
        return '🏃';
      case RolUsuario.entrenador:
        return '👨‍🏫';
    }
  }
}
