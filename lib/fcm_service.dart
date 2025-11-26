import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensaje recibido en background: ${message.messageId}');
  // Aquí se pueden procesar los mensajes en background
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _currentUserEmail;
  String? _fcmToken;

  /// Inicializar el servicio de FCM
  Future<void> initialize(String userEmail) async {
    _currentUserEmail = userEmail;
    
    // Configurar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Solicitar permisos
    await _requestPermissions();
    
    // Inicializar notificaciones locales
    await _initializeLocalNotifications();
    
    // Obtener y guardar el token FCM
    await _getAndSaveToken();
    
    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
    
    // Configurar listeners para mensajes
    _setupMessageListeners();
  }

  /// Solicitar permisos de notificación
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permisos de notificación: ${settings.authorizationStatus}');
  }

  /// Inicializar notificaciones locales para mostrar cuando la app está en foreground
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'lingo_gym_activities',
      'Actividades',
      description: 'Notificaciones de nuevas actividades asignadas',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Manejar tap en notificación
  void _onNotificationTapped(NotificationResponse response) {
    print('Notificación tocada: ${response.payload}');
    // Aquí se puede navegar a una pantalla específica
  }

  /// Obtener y guardar el token FCM
  Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null && _currentUserEmail != null) {
        print('FCM Token: $_fcmToken');
        
        // Guardar token en Firestore
        await _firestore.collection('usuarios').doc(_currentUserEmail).set({
          'fcmToken': _fcmToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // También guardar localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
    } catch (e) {
      print('Error obteniendo token FCM: $e');
    }
  }

  /// Manejar actualización de token
  Future<void> _onTokenRefresh(String newToken) async {
    _fcmToken = newToken;
    
    if (_currentUserEmail != null) {
      await _firestore.collection('usuarios').doc(_currentUserEmail).set({
        'fcmToken': newToken,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Configurar listeners para mensajes entrantes
  void _setupMessageListeners() {
    // Mensajes cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en foreground: ${message.notification?.title}');
      _showLocalNotification(message);
      _saveNotificationToFirestore(message);
    });

    // Cuando el usuario toca la notificación y abre la app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App abierta desde notificación: ${message.notification?.title}');
      // Navegar a la pantalla correspondiente
    });
  }

  /// Mostrar notificación local cuando la app está en foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'lingo_gym_activities',
            'Actividades',
            channelDescription: 'Notificaciones de nuevas actividades asignadas',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['actividadId'],
      );
    }
  }

  /// Guardar notificación en Firestore para el usuario
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    if (_currentUserEmail == null) return;
    
    try {
      await _firestore
          .collection('usuarios')
          .doc(_currentUserEmail)
          .collection('notificaciones')
          .add({
        'titulo': message.notification?.title ?? 'Nueva actividad',
        'mensaje': message.notification?.body ?? '',
        'actividadId': message.data['actividadId'],
        'grupoId': message.data['grupoId'],
        'leida': false,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error guardando notificación: $e');
    }
  }

  /// Enviar notificación a un usuario específico
  /// NOTA: Esto normalmente se hace desde un backend/Cloud Functions
  /// Esta función guarda la notificación en Firestore y el usuario la verá
  Future<void> enviarNotificacionAUsuario({
    required String usuarioEmail,
    required String titulo,
    required String mensaje,
    required String actividadId,
    required String grupoId,
  }) async {
    try {
      // Guardar notificación en la colección del usuario
      await _firestore
          .collection('usuarios')
          .doc(usuarioEmail)
          .collection('notificaciones')
          .add({
        'titulo': titulo,
        'mensaje': mensaje,
        'actividadId': actividadId,
        'grupoId': grupoId,
        'leida': false,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
      
      print('Notificación guardada para $usuarioEmail');
      
      // Para enviar push notification real, necesitarías Cloud Functions
      // que escuche cambios en la colección y envíe la notificación FCM
      
    } catch (e) {
      print('Error enviando notificación: $e');
    }
  }

  /// Obtener notificaciones no leídas del usuario actual
  Future<List<Map<String, dynamic>>> getNotificacionesNoLeidas() async {
    if (_currentUserEmail == null) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .doc(_currentUserEmail)
          .collection('notificaciones')
          .where('leida', isEqualTo: false)
          .orderBy('fechaCreacion', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error obteniendo notificaciones: $e');
      return [];
    }
  }

  /// Obtener todas las notificaciones del usuario
  Future<List<Map<String, dynamic>>> getTodasLasNotificaciones() async {
    if (_currentUserEmail == null) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .doc(_currentUserEmail)
          .collection('notificaciones')
          .orderBy('fechaCreacion', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error obteniendo notificaciones: $e');
      return [];
    }
  }

  /// Marcar notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    if (_currentUserEmail == null) return;
    
    try {
      await _firestore
          .collection('usuarios')
          .doc(_currentUserEmail)
          .collection('notificaciones')
          .doc(notificacionId)
          .update({'leida': true});
    } catch (e) {
      print('Error marcando notificación como leída: $e');
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> marcarTodasComoLeidas() async {
    if (_currentUserEmail == null) return;
    
    try {
      final batch = _firestore.batch();
      final notificaciones = await _firestore
          .collection('usuarios')
          .doc(_currentUserEmail)
          .collection('notificaciones')
          .where('leida', isEqualTo: false)
          .get();
      
      for (var doc in notificaciones.docs) {
        batch.update(doc.reference, {'leida': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marcando todas como leídas: $e');
    }
  }

  /// Obtener conteo de notificaciones no leídas
  Future<int> getConteoNoLeidas() async {
    if (_currentUserEmail == null) return 0;
    
    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .doc(_currentUserEmail)
          .collection('notificaciones')
          .where('leida', isEqualTo: false)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      print('Error obteniendo conteo: $e');
      return 0;
    }
  }

  /// Suscribirse a un tema (topic) para recibir notificaciones grupales
  Future<void> suscribirseATema(String tema) async {
    try {
      await _messaging.subscribeToTopic(tema);
      print('Suscrito al tema: $tema');
    } catch (e) {
      print('Error suscribiéndose al tema: $e');
    }
  }

  /// Desuscribirse de un tema
  Future<void> desuscribirseDelTema(String tema) async {
    try {
      await _messaging.unsubscribeFromTopic(tema);
      print('Desuscrito del tema: $tema');
    } catch (e) {
      print('Error desuscribiéndose del tema: $e');
    }
  }

  /// Obtener el token FCM actual
  String? get fcmToken => _fcmToken;
}
