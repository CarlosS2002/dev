import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'theme_provider.dart';

// Plugin de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Modelo para guardar actividades
class ActividadFisica {
  final String id;
  final String tipo; // 'caminar' o 'correr'
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double distanciaKm;
  final Duration duracion;
  final double caloriasQuemadas;
  final int pasos;
  final double velocidadPromedio; // km/h
  final double velocidadMaxima; // km/h
  final List<LatLng> ruta;
  final double ritmoPromedio; // min/km

  ActividadFisica({
    required this.id,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.distanciaKm,
    required this.duracion,
    required this.caloriasQuemadas,
    required this.pasos,
    required this.velocidadPromedio,
    this.velocidadMaxima = 0,
    required this.ruta,
    this.ritmoPromedio = 0,
  });

  // Convertir a JSON para guardar
  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaFin': fechaFin.toIso8601String(),
    'distanciaKm': distanciaKm,
    'duracion': duracion.inSeconds,
    'caloriasQuemadas': caloriasQuemadas,
    'pasos': pasos,
    'velocidadPromedio': velocidadPromedio,
    'velocidadMaxima': velocidadMaxima,
    'ritmoPromedio': ritmoPromedio,
    'ruta': ruta.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
  };

  // Crear desde JSON
  factory ActividadFisica.fromJson(Map<String, dynamic> json) => ActividadFisica(
    id: json['id'],
    tipo: json['tipo'],
    fechaInicio: DateTime.parse(json['fechaInicio']),
    fechaFin: DateTime.parse(json['fechaFin']),
    distanciaKm: (json['distanciaKm'] as num).toDouble(),
    duracion: Duration(seconds: json['duracion']),
    caloriasQuemadas: (json['caloriasQuemadas'] as num).toDouble(),
    pasos: json['pasos'],
    velocidadPromedio: (json['velocidadPromedio'] as num).toDouble(),
    velocidadMaxima: (json['velocidadMaxima'] as num?)?.toDouble() ?? 0,
    ritmoPromedio: (json['ritmoPromedio'] as num?)?.toDouble() ?? 0,
    ruta: (json['ruta'] as List)
        .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
        .toList(),
  );
}

class MapaScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onOpenDrawer;

  const MapaScreen({super.key, required this.userEmail, this.onOpenDrawer});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  GoogleMapController? mapController;
  
  // Ubicación
  final LatLng _defaultCenter = const LatLng(7.116816, -73.105240);
  LatLng? _currentPosition;
  bool _isLoadingLocation = false;
  
  // Tracking de actividad
  bool _isTracking = false;
  bool _isPaused = false;
  String _tipoActividad = 'caminar'; // 'caminar' o 'correr'
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  
  // Datos de la actividad
  double _distanciaTotal = 0.0; // en metros
  int _pasos = 0;
  double _velocidadActual = 0.0; // km/h
  double _velocidadMaxima = 0.0; // km/h
  double _caloriasQuemadas = 0.0;
  List<LatLng> _rutaRecorrida = [];
  
  // Para cálculo de velocidad más preciso
  List<Position> _posicionesRecientes = [];
  DateTime? _lastPositionTime;
  Position? _lastValidPosition;
  
  // Sensores
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastStepTime;
  
  // Stream de ubicación
  StreamSubscription<Position>? _positionStream;
  
  // Marcadores y líneas
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Historial de actividades
  List<ActividadFisica> _historialActividades = [];
  
  // Animación
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Notificaciones
  bool _notificationsInitialized = false;
  
  // Actividad expandida
  int? _expandedActivityIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _initNotifications();
    _loadActividades();
    _getCurrentLocation();
  }
  
  // Detectar cuando la app está en segundo plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isTracking && !_isPaused) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        // App en segundo plano - mostrar notificación
        _showTrackingNotification();
      } else if (state == AppLifecycleState.resumed) {
        // App volvió al frente - cancelar notificación
        _cancelTrackingNotification();
      }
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: false,
        );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _notificationsInitialized = true;
  }

  Future<void> _showTrackingNotification() async {
    if (!_notificationsInitialized) return;
    
    String distancia = _distanciaTotal >= 1000 
        ? '${(_distanciaTotal / 1000).toStringAsFixed(2)} km'
        : '${_distanciaTotal.toStringAsFixed(0)} m';
    
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'activity_tracking',
          'Seguimiento de Actividad',
          channelDescription: 'Notificaciones de actividad física en progreso',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          showWhen: false,
          styleInformation: BigTextStyleInformation(
            '📏 Distancia: $distancia\n⏱️ Tiempo: ${_formatDuration(_elapsedTime)}\n👣 Pasos: $_pasos\n🔥 Calorías: ${_caloriasQuemadas.toStringAsFixed(0)} kcal',
          ),
        );
    
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      0,
      '${_tipoActividad == 'correr' ? '🏃 Corriendo' : '🚶 Caminando'} - ${_formatDuration(_elapsedTime)}',
      '📏 $distancia | 👣 $_pasos pasos | 🔥 ${_caloriasQuemadas.toStringAsFixed(0)} kcal',
      platformChannelSpecifics,
    );
  }

  Future<void> _cancelTrackingNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  // ==================== PERSISTENCIA DE ACTIVIDADES ====================
  
  Future<void> _loadActividades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? actividadesJson = prefs.getString('actividades_${widget.userEmail}');
      
      if (actividadesJson != null) {
        final List<dynamic> decoded = jsonDecode(actividadesJson);
        setState(() {
          _historialActividades = decoded
              .map((json) => ActividadFisica.fromJson(json))
              .toList();
          // Ordenar por fecha más reciente
          _historialActividades.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
        });
      }
    } catch (e) {
      debugPrint('Error cargando actividades: $e');
    }
  }

  Future<void> _saveActividades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _historialActividades.map((a) => a.toJson()).toList()
      );
      await prefs.setString('actividades_${widget.userEmail}', encoded);
    } catch (e) {
      debugPrint('Error guardando actividades: $e');
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _accelerometerSubscription?.cancel();
    _positionStream?.cancel();
    _pulseController.dispose();
    mapController?.dispose();
    _cancelTrackingNotification();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<bool> _checkAndRequestPermissions() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }

    // También solicitar permiso de actividad física para sensores
    if (await Permission.activityRecognition.isDenied) {
      await Permission.activityRecognition.request();
    }

    return status.isGranted;
  }

  Future<bool> _checkGPSEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (!serviceEnabled) {
      _showGPSDisabledDialog();
      return false;
    }
    
    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      bool gpsEnabled = await _checkGPSEnabled();
      if (!gpsEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _updateCurrentLocationMarker();

      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 17.0,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showError('Error al obtener ubicación: $e');
    }
  }

  void _updateCurrentLocationMarker() {
    if (_currentPosition == null) return;
    
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _isTracking ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: _isTracking ? 'En actividad' : 'Mi ubicación',
            snippet: _isTracking 
                ? '${_distanciaTotal.toStringAsFixed(0)}m - ${_formatDuration(_elapsedTime)}'
                : 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}',
          ),
        ),
      );
    });
  }

  // ==================== TRACKING DE ACTIVIDAD ====================

  void _startTracking() async {
    bool hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) return;

    bool gpsEnabled = await _checkGPSEnabled();
    if (!gpsEnabled) return;

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _distanciaTotal = 0.0;
      _pasos = 0;
      _velocidadActual = 0.0;
      _velocidadMaxima = 0.0;
      _caloriasQuemadas = 0.0;
      _rutaRecorrida = [];
      _elapsedTime = Duration.zero;
      _polylines.clear();
      _lastValidPosition = null;
      _lastPositionTime = null;
      _posicionesRecientes.clear();
    });

    // Agregar marcador de inicio
    if (_currentPosition != null) {
      _rutaRecorrida.add(_currentPosition!);
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: '🚀 Inicio'),
        ),
      );
    }

    // Iniciar timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
          _calcularCalorias();
        });
        
        // Actualizar notificación cada 5 segundos cuando está en segundo plano
        if (_elapsedTime.inSeconds % 5 == 0) {
          _showTrackingNotification();
        }
      }
    });

    // Iniciar tracking de ubicación
    _startLocationTracking();
    
    // Iniciar contador de pasos con acelerómetro
    _startStepCounter();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.play_arrow, color: Colors.white),
              const SizedBox(width: 8),
              Text('¡Actividad iniciada! ${_tipoActividad == 'correr' ? '🏃' : '🚶'}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Máxima precisión
      distanceFilter: 2, // Actualizar cada 2 metros
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_isPaused) return;
      
      // Validar precisión del GPS
      if (position.accuracy > 50) return; // Ignorar lecturas muy imprecisas
      
      final newPosition = LatLng(position.latitude, position.longitude);
      final now = DateTime.now();
      
      if (_rutaRecorrida.isNotEmpty) {
        final lastPosition = _rutaRecorrida.last;
        final distance = _calculateDistance(
          lastPosition.latitude,
          lastPosition.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        
        // Solo agregar si se movió más de 2 metros y menos de 100m (evitar ruido y saltos GPS)
        if (distance > 2 && distance < 100) {
          setState(() {
            _distanciaTotal += distance;
            _rutaRecorrida.add(newPosition);
            _currentPosition = newPosition;
            
            // Calcular velocidad usando múltiples métodos
            if (_lastValidPosition != null && _lastPositionTime != null) {
              final timeDiff = now.difference(_lastPositionTime!).inMilliseconds / 1000.0;
              if (timeDiff > 0.5) { // Al menos 0.5 segundos entre mediciones
                final distFromLast = _calculateDistance(
                  _lastValidPosition!.latitude,
                  _lastValidPosition!.longitude,
                  position.latitude,
                  position.longitude,
                );
                // Velocidad en km/h
                double calculatedSpeed = (distFromLast / timeDiff) * 3.6;
                
                // También considerar la velocidad del GPS si está disponible
                double gpsSpeed = position.speed >= 0 ? position.speed * 3.6 : 0;
                
                // Usar promedio ponderado si ambas son razonables
                if (gpsSpeed > 0 && gpsSpeed < 30 && calculatedSpeed > 0 && calculatedSpeed < 30) {
                  _velocidadActual = (gpsSpeed * 0.7 + calculatedSpeed * 0.3);
                } else if (calculatedSpeed > 0 && calculatedSpeed < 30) {
                  _velocidadActual = calculatedSpeed;
                } else if (gpsSpeed > 0 && gpsSpeed < 30) {
                  _velocidadActual = gpsSpeed;
                }
                
                // Actualizar velocidad máxima
                if (_velocidadActual > _velocidadMaxima && _velocidadActual < 30) {
                  _velocidadMaxima = _velocidadActual;
                }
              }
            }
            
            _lastValidPosition = position;
            _lastPositionTime = now;
            
            _updatePolyline();
            _updateCurrentLocationMarker();
          });
        }
      } else {
        setState(() {
          _rutaRecorrida.add(newPosition);
          _currentPosition = newPosition;
          _lastValidPosition = position;
          _lastPositionTime = now;
        });
      }
    });
  }

  void _startStepCounter() {
    // Variables para el filtro de paso bajo
    double filteredMagnitude = 0;
    const double alpha = 0.8; // Factor de suavizado
    bool wasAboveThreshold = false;
    
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_isPaused) return;
      
      // Calcular magnitud de la aceleración
      double magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      // Aplicar filtro de paso bajo para suavizar
      filteredMagnitude = alpha * filteredMagnitude + (1 - alpha) * magnitude;
      
      // Umbral dinámico basado en gravedad (~9.8) + movimiento
      double threshold = _tipoActividad == 'correr' ? 11.5 : 10.5;
      
      // Detectar paso cuando cruza el umbral de abajo hacia arriba
      bool isAboveThreshold = filteredMagnitude > threshold;
      
      if (isAboveThreshold && !wasAboveThreshold) {
        DateTime now = DateTime.now();
        // Tiempo mínimo entre pasos: 200ms para correr, 300ms para caminar
        int minInterval = _tipoActividad == 'correr' ? 200 : 300;
        
        if (_lastStepTime == null || 
            now.difference(_lastStepTime!).inMilliseconds > minInterval) {
          setState(() {
            _pasos++;
            _lastStepTime = now;
          });
        }
      }
      
      wasAboveThreshold = isAboveThreshold;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPaused ? '⏸️ Actividad pausada' : '▶️ Actividad reanudada'),
          backgroundColor: _isPaused ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _stopTracking() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.stop_circle, color: Colors.red),
            SizedBox(width: 8),
            Text('Finalizar Actividad'),
          ],
        ),
        content: const Text('¿Deseas finalizar y guardar esta actividad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _cancelTracking();
            },
            child: const Text('Descartar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _saveAndStopTracking();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveAndStopTracking() {
    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerSubscription?.cancel();
    _cancelTrackingNotification();

    // Agregar marcador de fin
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: '🏁 Fin'),
        ),
      );
    }

    // Calcular velocidad promedio y ritmo
    double velocidadProm = _elapsedTime.inSeconds > 0 
        ? (_distanciaTotal / 1000) / (_elapsedTime.inSeconds / 3600)
        : 0;
    
    // Ritmo en min/km
    double ritmoProm = (_distanciaTotal > 0 && _elapsedTime.inSeconds > 0)
        ? (_elapsedTime.inMinutes) / (_distanciaTotal / 1000)
        : 0;

    // Crear actividad con todos los campos
    final actividad = ActividadFisica(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: _tipoActividad,
      fechaInicio: _startTime!,
      fechaFin: DateTime.now(),
      distanciaKm: _distanciaTotal / 1000,
      duracion: _elapsedTime,
      caloriasQuemadas: _caloriasQuemadas,
      pasos: _pasos,
      velocidadPromedio: velocidadProm,
      velocidadMaxima: _velocidadMaxima,
      ritmoPromedio: ritmoProm,
      ruta: List.from(_rutaRecorrida),
    );

    setState(() {
      _historialActividades.insert(0, actividad);
      // Ordenar por fecha más reciente
      _historialActividades.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
      _isTracking = false;
      _isPaused = false;
    });

    // Guardar en SharedPreferences
    _saveActividades();

    _showActivitySummary(actividad);
  }

  void _cancelTracking() {
    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerSubscription?.cancel();

    setState(() {
      _isTracking = false;
      _isPaused = false;
      _rutaRecorrida.clear();
      _polylines.clear();
      _markers.removeWhere((m) => 
        m.markerId.value == 'start' || m.markerId.value == 'end'
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actividad descartada'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _calcularCalorias() {
    // Fórmula simplificada: MET * peso(kg) * tiempo(horas)
    // MET caminar: 3.5, correr: 8.0
    double met = _tipoActividad == 'correr' ? 8.0 : 3.5;
    double pesoKg = 70; // Peso promedio
    double tiempoHoras = _elapsedTime.inSeconds / 3600;
    
    _caloriasQuemadas = met * pesoKg * tiempoHoras;
  }

  void _updatePolyline() {
    if (_rutaRecorrida.length < 2) return;
    
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _rutaRecorrida,
          color: _tipoActividad == 'correr' ? Colors.orange : Colors.blue,
          width: 5,
        ),
      );
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metros
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // ==================== DIÁLOGOS ====================

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Permisos Requeridos'),
          ],
        ),
        content: const Text(
          'Esta aplicación necesita acceso a tu ubicación para rastrear tu actividad física.\n\n'
          'Por favor, ve a Configuración y activa los permisos de ubicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }

  void _showGPSDisabledDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gps_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('GPS Desactivado'),
          ],
        ),
        content: const Text(
          'El GPS de tu dispositivo está desactivado.\n\n'
          'Por favor, activa la ubicación para rastrear tu actividad física.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Geolocator.openLocationSettings();
            },
            child: const Text('Activar GPS'),
          ),
        ],
      ),
    );
  }

  void _showActivitySummary(ActividadFisica actividad) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              actividad.tipo == 'correr' ? Icons.directions_run : Icons.directions_walk,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡Actividad Completada!',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryCard(icon: Icons.straighten, label: 'Distancia', 
                  value: '${actividad.distanciaKm.toStringAsFixed(2)} km', color: Colors.blue),
              _buildSummaryCard(icon: Icons.timer, label: 'Duración', 
                  value: _formatDuration(actividad.duracion), color: Colors.purple),
              _buildSummaryCard(icon: Icons.local_fire_department, label: 'Calorías', 
                  value: '${actividad.caloriasQuemadas.toStringAsFixed(0)} kcal', color: Colors.orange),
              _buildSummaryCard(icon: Icons.directions_walk, label: 'Pasos', 
                  value: '${actividad.pasos}', color: Colors.teal),
              _buildSummaryCard(icon: Icons.speed, label: 'Velocidad Promedio', 
                  value: '${actividad.velocidadPromedio.toStringAsFixed(1)} km/h', color: Colors.red),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showHistorial();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ver Historial', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  void _showHistorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.blue, size: 28),
                      const SizedBox(width: 8),
                      const Text('Historial de Actividades',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${_historialActividades.length} registros',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _historialActividades.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_run, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No hay actividades registradas',
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              const Text('¡Inicia tu primera actividad!',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _historialActividades.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) => _buildExpandableHistorialCard(
                            _historialActividades[index], 
                            index,
                            setModalState,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableHistorialCard(ActividadFisica actividad, int index, StateSetter setModalState) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isCorrer = actividad.tipo == 'correr';
    final isExpanded = _expandedActivityIndex == index;
    final color = isCorrer ? Colors.orange : Colors.blue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isExpanded ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isExpanded ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Column(
        children: [
          // Header - siempre visible
          InkWell(
            onTap: () {
              setModalState(() {
                setState(() {
                  _expandedActivityIndex = isExpanded ? null : index;
                });
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCorrer ? Icons.directions_run : Icons.directions_walk,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isCorrer ? 'Carrera' : 'Caminata',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(_formatDateFull(actividad.fechaInicio),
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${actividad.distanciaKm.toStringAsFixed(2)} km',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          )),
                      Text(_formatDuration(actividad.duracion),
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          )),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(actividad, color, themeProvider),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ActividadFisica actividad, Color color, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          
          // Estadísticas principales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildExpandedStat(Icons.straighten, 'Distancia', 
                  '${actividad.distanciaKm.toStringAsFixed(2)} km', Colors.blue),
              _buildExpandedStat(Icons.timer, 'Duración', 
                  _formatDuration(actividad.duracion), Colors.purple),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildExpandedStat(Icons.local_fire_department, 'Calorías', 
                  '${actividad.caloriasQuemadas.toStringAsFixed(0)} kcal', Colors.orange),
              _buildExpandedStat(Icons.directions_walk, 'Pasos', 
                  '${actividad.pasos}', Colors.teal),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildExpandedStat(Icons.speed, 'Vel. Promedio', 
                  '${actividad.velocidadPromedio.toStringAsFixed(1)} km/h', Colors.red),
              _buildExpandedStat(Icons.speed_outlined, 'Vel. Máxima', 
                  '${actividad.velocidadMaxima.toStringAsFixed(1)} km/h', Colors.pink),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildExpandedStat(Icons.timer_outlined, 'Ritmo', 
                  _formatRitmo(actividad.ritmoPromedio), Colors.indigo),
              _buildExpandedStat(Icons.map, 'Puntos GPS', 
                  '${actividad.ruta.length}', Colors.cyan),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Información adicional
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode 
                  ? Colors.grey.shade800 
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_today, 'Fecha', 
                    _formatDateFull(actividad.fechaInicio)),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, 'Hora inicio', 
                    _formatTime(actividad.fechaInicio)),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time_filled, 'Hora fin', 
                    _formatTime(actividad.fechaFin)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showActivityOnMap(actividad);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Ver Ruta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDeleteActivity(actividad),
                  icon: const Icon(Icons.delete, size: 20),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedStat(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  String _formatRitmo(double ritmo) {
    if (ritmo <= 0 || ritmo.isInfinite || ritmo.isNaN) return '--:--';
    int minutos = ritmo.floor();
    int segundos = ((ritmo - minutos) * 60).round();
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')} /km';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  String _formatDateFull(DateTime date) {
    final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${dias[date.weekday - 1]}, ${date.day} ${meses[date.month - 1]} ${date.year}';
  }

  void _showActivityOnMap(ActividadFisica actividad) {
    setState(() {
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value == 'start' || m.markerId.value == 'end');
      
      if (actividad.ruta.length >= 2) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('historyRoute'),
            points: actividad.ruta,
            color: actividad.tipo == 'correr' ? Colors.orange : Colors.blue,
            width: 5,
          ),
        );
        
        _markers.add(Marker(
          markerId: const MarkerId('start'),
          position: actividad.ruta.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: '🚀 Inicio'),
        ));
        _markers.add(Marker(
          markerId: const MarkerId('end'),
          position: actividad.ruta.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: '🏁 Fin'),
        ));
        
        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFromLatLngList(actividad.ruta), 50),
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${actividad.tipo == 'correr' ? '🏃 Carrera' : '🚶 Caminata'} - ${_formatDateFull(actividad.fechaInicio)}'),
        backgroundColor: actividad.tipo == 'correr' ? Colors.orange : Colors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Limpiar',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _polylines.clear();
              _markers.removeWhere((m) => m.markerId.value == 'start' || m.markerId.value == 'end');
            });
          },
        ),
      ),
    );
  }

  void _confirmDeleteActivity(ActividadFisica actividad) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Actividad'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar esta ${actividad.tipo == 'correr' ? 'carrera' : 'caminata'} '
          'del ${_formatDateFull(actividad.fechaInicio)}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Cerrar dialog
              Navigator.pop(context); // Cerrar bottom sheet
              _deleteActivity(actividad);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteActivity(ActividadFisica actividad) {
    setState(() {
      _historialActividades.removeWhere((a) => a.id == actividad.id);
      _expandedActivityIndex = null;
    });
    _saveActividades();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Actividad eliminada'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (final latLng in list) {
      if (minLat == null || latLng.latitude < minLat) minLat = latLng.latitude;
      if (maxLat == null || latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (minLng == null || latLng.longitude < minLng) minLng = latLng.longitude;
      if (maxLng == null || latLng.longitude > maxLng) maxLng = latLng.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isTracking 
                ? '${_tipoActividad == 'correr' ? '🏃 Corriendo' : '🚶 Caminando'}' 
                : 'Actividad Física'),
            backgroundColor: _isTracking 
                ? (_tipoActividad == 'correr' ? Colors.orange : Colors.green)
                : Colors.blue.shade600,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.onOpenDrawer,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _showHistorial,
                tooltip: 'Historial',
              ),
            ],
          ),
          body: Stack(
            children: [
              // Mapa
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? _defaultCenter,
                  zoom: 16.0,
                ),
                markers: _markers,
                polylines: _polylines,
                mapType: MapType.normal,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
              ),
              
              // Panel de estadísticas durante tracking
              if (_isTracking)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTrackingPanel(themeProvider),
                ),
              
              // Panel inferior con controles
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildControlPanel(themeProvider),
              ),
              
              // Botón de ubicación
              Positioned(
                right: 16,
                bottom: _isTracking ? 220 : 200,
                child: FloatingActionButton(
                  heroTag: 'location',
                  mini: true,
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: _isLoadingLocation
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.my_location, color: Colors.blue.shade600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackingPanel(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode 
            ? Colors.grey.shade900.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer grande
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPaused ? 1.0 : (_pulseAnimation.value * 0.05 + 0.95),
                child: Text(
                  _formatDuration(_elapsedTime),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _isPaused ? Colors.grey : (_tipoActividad == 'correr' ? Colors.orange : Colors.green),
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
          if (_isPaused)
            const Text('PAUSADO', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Estadísticas en fila
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(Icons.straighten,
                  _distanciaTotal >= 1000 ? '${(_distanciaTotal / 1000).toStringAsFixed(2)} km' : '${_distanciaTotal.toStringAsFixed(0)} m',
                  'Distancia', Colors.blue),
              _buildStatColumn(Icons.local_fire_department, '${_caloriasQuemadas.toStringAsFixed(0)}', 'Calorías', Colors.orange),
              _buildStatColumn(Icons.directions_walk, '$_pasos', 'Pasos', Colors.teal),
              _buildStatColumn(Icons.speed, '${_velocidadActual.toStringAsFixed(1)}', 'km/h', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildControlPanel(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isTracking) ...[
            const Text('Selecciona tu actividad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActivityTypeButton(icon: Icons.directions_walk, label: 'Caminar', type: 'caminar', color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildActivityTypeButton(icon: Icons.directions_run, label: 'Correr', type: 'correr', color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startTracking,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text('INICIAR ACTIVIDAD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tipoActividad == 'correr' ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'pause',
                  onPressed: _togglePause,
                  backgroundColor: Colors.orange,
                  child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 32),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: FloatingActionButton(
                    heroTag: 'stop',
                    onPressed: _stopTracking,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.stop, size: 40),
                  ),
                ),
                FloatingActionButton(
                  heroTag: 'center',
                  onPressed: () {
                    if (_currentPosition != null) {
                      mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
                    }
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.center_focus_strong, size: 28),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTypeButton({required IconData icon, required String label, required String type, required Color color}) {
    final isSelected = _tipoActividad == type;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return InkWell(
      onTap: () => setState(() => _tipoActividad = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : (themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
