import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_screen.dart';
import 'theme_provider.dart';
import 'agenda_provider.dart';
import 'firebase_service.dart';
import 'models.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isRegistered = false;
  bool isLoggedIn = false;
  bool _isLoading = true; // Para mostrar carga mientras verifica sesión
  String? registeredEmail;
  String? registeredPassword;
  String? currentUserEmail; // Para pasar al MenuScreen
  bool _obscurePassword = true; // Para controlar la visibilidad de la contraseña

  // Usuarios de prueba pre-cargados
  final Map<String, String> testUsers = {
    'carlos@test.com': '123456',  // Usuario hombre
    'maria@test.com': '123456',    // Usuario mujer
  };

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  // Verificar si hay una sesión guardada
  Future<void> _checkSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email');
      final isSessionActive = prefs.getBool('session_active') ?? false;
      
      if (savedEmail != null && savedEmail.isNotEmpty && isSessionActive) {
        // Resetear el provider para asegurar estado limpio
        if (mounted) {
          Provider.of<AgendaProvider>(context, listen: false).resetear();
        }
        
        // Verificar si es usuario de prueba
        if (testUsers.containsKey(savedEmail)) {
          setState(() {
            isLoggedIn = true;
            currentUserEmail = savedEmail;
            _isLoading = false;
          });
          return;
        }
        
        // Para usuarios de Firebase, cargar el rol guardado
        final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
        
        // Cargar rol desde Firebase
        final firebaseService = FirebaseService();
        final rolGuardado = await firebaseService.cargarRolUsuario(savedEmail);
        if (rolGuardado != null) {
          agendaProvider.setRol(savedEmail, rolGuardado);
          print('🔄 Sesión restaurada - Rol: $rolGuardado');
        }
        
        setState(() {
          isLoggedIn = true;
          currentUserEmail = savedEmail;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Error verificando sesión: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  // Guardar sesión
  Future<void> _saveSession(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setBool('session_active', true);
    } catch (e) {
      print('Error guardando sesión: $e');
    }
  }

  // Limpiar sesión
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.setBool('session_active', false);
    } catch (e) {
      print('Error limpiando sesión: $e');
    }
  }

  void register() async {
    final result = await Navigator.pushNamed(context, '/register');
    if (result == true) {
      setState(() {
        isRegistered = true;
      });
    }
  }

  Future<void> login() async {
    final enteredEmail = emailController.text.trim();
    final enteredPassword = passwordController.text;

    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      _mostrarError('Por favor ingresa correo y contraseña');
      return;
    }

    // Verificar usuarios de prueba primero (modo sin Firebase)
    if (testUsers.containsKey(enteredEmail) && testUsers[enteredEmail] == enteredPassword) {
      // Resetear el provider antes de inicializar
      Provider.of<AgendaProvider>(context, listen: false).resetear();
      
      await _saveSession(enteredEmail); // Guardar sesión
      setState(() {
        isLoggedIn = true;
        currentUserEmail = enteredEmail;
      });
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Center(child: CircularProgressIndicator()),
      );

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: enteredEmail,
        password: enteredPassword,
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      // Cerrar el diálogo de carga primero
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        final rolString = userData['rol'] as String;
        final rol = RolUsuario.values.firstWhere(
          (e) => e.toString().split('.').last == rolString,
          orElse: () => RolUsuario.atleta,
        );

        print('🔐 Login exitoso - Email: $enteredEmail, Rol: $rol');

        final agendaProvider = Provider.of<AgendaProvider>(context, listen: false);
        
        // Resetear el provider antes de inicializar con el nuevo usuario
        agendaProvider.resetear();
        
        // Establecer el rol (esto también lo guarda en Firebase usuarios/{email})
        agendaProvider.setRol(enteredEmail, rol);
        
        // Asegurar que el rol se guarde en usuarios/{email} para futuras restauraciones de sesión
        final firebaseService = FirebaseService();
        await firebaseService.guardarRolUsuario(enteredEmail, rol);
        print('💾 Rol guardado en usuarios/{email}: $rol');

        await _saveSession(enteredEmail); // Guardar sesión
        
        setState(() {
          isLoggedIn = true;
          currentUserEmail = enteredEmail;
        });
      } else {
        _mostrarError('No se encontraron datos del usuario');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      String errorMessage = switch (e.code) {
        'user-not-found' => 'No existe una cuenta con este correo',
        'wrong-password' => 'Contraseña incorrecta',
        'invalid-email' => 'El correo no es válido',
        'user-disabled' => 'Esta cuenta ha sido deshabilitada',
        'invalid-credential' => 'Correo o contraseña incorrectos',
        _ => 'Error: ${e.message}'
      };
      
      _mostrarError(errorMessage);
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _mostrarError('Error inesperado: $e');
    }
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error de inicio de sesión'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void logout() async {
    await _clearSession(); // Limpiar sesión guardada
    
    // Resetear el AgendaProvider
    if (mounted) {
      Provider.of<AgendaProvider>(context, listen: false).resetear();
    }
    
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Ignorar errores de Firebase signOut
    }
    setState(() {
      isLoggedIn = false;
      currentUserEmail = null;
      emailController.clear();
      passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Mostrar loading mientras verifica sesión
        if (_isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando...'),
                ],
              ),
            ),
          );
        }
        
        if (isLoggedIn) {
          return MenuScreen(
            userEmail: currentUserEmail ?? '',
            onLogout: logout,
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Inicio de Sesión o Registro'),
            ),
            body: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  // Logo usando Image.asset
                  Container(
                    margin: EdgeInsets.only(bottom: 40),
                    child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'assets/images/Icon.jpg',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade600,
                              Colors.green.shade400,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Groww',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              Container(
                margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextField(
                  controller: emailController,
                  style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ),
              ),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextField(
                  controller: passwordController,
                  style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white38 : Colors.black38),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
              ),
              
              Container(
                margin: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              TextButton(
                onPressed: register,
                child: Text(
                  '¿No tienes una cuenta? Regístrate aquí.',
                  style: TextStyle(color: Colors.blue.shade600),
                ),
              ),
            ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
