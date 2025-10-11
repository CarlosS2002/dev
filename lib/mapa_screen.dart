import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapaScreen extends StatefulWidget {
  final String userEmail;

  const MapaScreen({super.key, required this.userEmail});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(7.116816, -73.105240);
  
  LatLng? _currentPosition;
  bool _isLoadingLocation = false;

  Set<Marker> _markers = {};

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
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      bool gpsEnabled = await _checkGPSEnabled();
      if (!gpsEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        
        _markers.add(
          Marker(
            markerId: MarkerId("myLocation"),
            position: _currentPosition!,
            infoWindow: InfoWindow(
              title: "Mi ubicación",
              snippet: "Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        
        _isLoadingLocation = false;
      });

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 17.0,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ubicación actual encontrada'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Permisos Requeridos'),
          ],
        ),
        content: Text(
          'Esta aplicación necesita acceso a tu ubicación para mostrarla en el mapa.\n\n'
          'Por favor, ve a Configuración y activa los permisos de ubicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
            ),
            child: Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }

  void _showGPSDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gps_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('GPS Desactivado'),
          ],
        ),
        content: Text(
          'El GPS de tu dispositivo está desactivado.\n\n'
          'Por favor, activa la ubicación en la configuración de tu dispositivo para usar esta función.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: Text('Activar GPS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicación en el Mapa'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 15.0,
        ),
        markers: _markers,
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        compassEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        child: _isLoadingLocation
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.my_location),
        backgroundColor: _isLoadingLocation 
            ? Colors.grey 
            : Colors.blue.shade600,
        tooltip: 'Mi ubicación',
      ),
    );
  }
}
