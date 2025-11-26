import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Modelo para notificaciones de asignaciones
class NotificacionAsignacion {
  final String id;
  final String titulo;
  final String mensaje;
  final String grupoId;
  final String grupoNombre;
  final String actividadId;
  final DateTime fecha;
  final bool leida;

  NotificacionAsignacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.grupoId,
    required this.grupoNombre,
    required this.actividadId,
    required this.fecha,
    this.leida = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'mensaje': mensaje,
    'grupoId': grupoId,
    'grupoNombre': grupoNombre,
    'actividadId': actividadId,
    'fecha': fecha.toIso8601String(),
    'leida': leida,
  };

  factory NotificacionAsignacion.fromJson(Map<String, dynamic> json) => NotificacionAsignacion(
    id: json['id'],
    titulo: json['titulo'],
    mensaje: json['mensaje'],
    grupoId: json['grupoId'],
    grupoNombre: json['grupoNombre'],
    actividadId: json['actividadId'],
    fecha: DateTime.parse(json['fecha']),
    leida: json['leida'] ?? false,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'asignaciones_channel',
      'Asignaciones',
      description: 'Notificaciones de nuevas asignaciones de actividades',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Manejar cuando el usuario toca la notificación
    // Aquí se podría navegar a la pantalla de agenda
  }

  // Enviar notificación de nueva asignación
  Future<void> enviarNotificacionAsignacion({
    required String nombreActividad,
    required String grupoNombre,
    required int puntos,
    required DateTime fecha,
    required List<String> atletasEmails,
    required String actividadId,
    required String grupoId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Crear el mensaje de la notificación
    final String titulo = '📋 Nueva Asignación: $nombreActividad';
    final String mensaje = '🏋️ $grupoNombre\n'
        '⭐ $puntos puntos\n'
        '📅 ${_formatearFecha(fecha)}';

    // Mostrar notificación local
    await _mostrarNotificacion(
      id: actividadId.hashCode,
      titulo: titulo,
      mensaje: mensaje,
    );

    // Guardar la notificación para cada atleta
    for (String atletaEmail in atletasEmails) {
      await _guardarNotificacion(
        userEmail: atletaEmail,
        notificacion: NotificacionAsignacion(
          id: '${actividadId}_$atletaEmail',
          titulo: 'Nueva Asignación: $nombreActividad',
          mensaje: '$puntos puntos - ${_formatearFecha(fecha)}',
          grupoId: grupoId,
          grupoNombre: grupoNombre,
          actividadId: actividadId,
          fecha: DateTime.now(),
        ),
      );
    }
  }

  // Mostrar notificación local
  Future<void> _mostrarNotificacion({
    required int id,
    required String titulo,
    required String mensaje,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'asignaciones_channel',
          'Asignaciones',
          channelDescription: 'Notificaciones de nuevas asignaciones de actividades',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      titulo,
      mensaje,
      platformChannelSpecifics,
    );
  }

  // Guardar notificación en SharedPreferences
  Future<void> _guardarNotificacion({
    required String userEmail,
    required NotificacionAsignacion notificacion,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'notificaciones_$userEmail';
      
      // Obtener notificaciones existentes
      final String? existingJson = prefs.getString(key);
      List<NotificacionAsignacion> notificaciones = [];
      
      if (existingJson != null) {
        final List<dynamic> decoded = jsonDecode(existingJson);
        notificaciones = decoded
            .map((json) => NotificacionAsignacion.fromJson(json))
            .toList();
      }
      
      // Agregar nueva notificación al inicio
      notificaciones.insert(0, notificacion);
      
      // Limitar a las últimas 50 notificaciones
      if (notificaciones.length > 50) {
        notificaciones = notificaciones.sublist(0, 50);
      }
      
      // Guardar
      final String encoded = jsonEncode(
        notificaciones.map((n) => n.toJson()).toList()
      );
      await prefs.setString(key, encoded);
    } catch (e) {
      // Ignorar errores de persistencia
    }
  }

  // Obtener notificaciones de un usuario
  Future<List<NotificacionAsignacion>> obtenerNotificaciones(String userEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'notificaciones_$userEmail';
      final String? existingJson = prefs.getString(key);
      
      if (existingJson != null) {
        final List<dynamic> decoded = jsonDecode(existingJson);
        return decoded
            .map((json) => NotificacionAsignacion.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Ignorar errores
    }
    return [];
  }

  // Marcar notificación como leída
  Future<void> marcarComoLeida(String userEmail, String notificacionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'notificaciones_$userEmail';
      final String? existingJson = prefs.getString(key);
      
      if (existingJson != null) {
        final List<dynamic> decoded = jsonDecode(existingJson);
        List<NotificacionAsignacion> notificaciones = decoded
            .map((json) => NotificacionAsignacion.fromJson(json))
            .toList();
        
        // Encontrar y marcar como leída
        final index = notificaciones.indexWhere((n) => n.id == notificacionId);
        if (index != -1) {
          final n = notificaciones[index];
          notificaciones[index] = NotificacionAsignacion(
            id: n.id,
            titulo: n.titulo,
            mensaje: n.mensaje,
            grupoId: n.grupoId,
            grupoNombre: n.grupoNombre,
            actividadId: n.actividadId,
            fecha: n.fecha,
            leida: true,
          );
          
          final String encoded = jsonEncode(
            notificaciones.map((n) => n.toJson()).toList()
          );
          await prefs.setString(key, encoded);
        }
      }
    } catch (e) {
      // Ignorar errores
    }
  }

  // Obtener cantidad de notificaciones no leídas
  Future<int> obtenerContadorNoLeidas(String userEmail) async {
    final notificaciones = await obtenerNotificaciones(userEmail);
    return notificaciones.where((n) => !n.leida).length;
  }

  // Limpiar todas las notificaciones de un usuario
  Future<void> limpiarNotificaciones(String userEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notificaciones_$userEmail');
    } catch (e) {
      // Ignorar errores
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${dias[fecha.weekday - 1]}, ${fecha.day} ${meses[fecha.month - 1]}';
  }
}
